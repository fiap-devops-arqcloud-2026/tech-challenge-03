package main

import (
	"context"         // contexto exigido pelas operações do cliente Redis
	"crypto/sha1"     // hash usado no cálculo determinístico do "bucket" do usuário
	"encoding/binary" // converte bytes do hash em número inteiro
	"encoding/json"   // serializa/desserializa as respostas dos serviços e o cache
	"fmt"
	"io/ioutil" // leitura do corpo das respostas HTTP
	"log"
	"net/http"
	"os"   // leitura da SERVICE_API_KEY do ambiente
	"sync" // WaitGroup para buscar flag e regra em paralelo
	"time"
)

const (
	// Tempo de vida de cada entrada no cache Redis.
	// 30s é um equilíbrio: respostas rápidas no hot path, mas mudanças de flag
	// demoram no máximo 30s para serem percebidas.
	CACHE_TTL = 30 * time.Second
)

// getDecision é o ponto de entrada da avaliação: junta as duas etapas
// (buscar os dados da flag e aplicar a regra) e devolve o veredito true/false.
func (a *App) getDecision(userID, flagName string) (bool, error) {
	// 1. Obter os dados da flag (do cache ou dos serviços)
	info, err := a.getCombinedFlagInfo(flagName)
	if err != nil {
		return false, err
	}

	// 2. Executar a lógica de avaliação
	return a.runEvaluationLogic(info, userID), nil
}

// getCombinedFlagInfo busca os dados no Redis, com fallback para os microsserviços
func (a *App) getCombinedFlagInfo(flagName string) (*CombinedFlagInfo, error) {
	cacheKey := fmt.Sprintf("flag_info:%s", flagName)

	// Contexto exigido pela API do cliente Redis (sem prazo/cancelamento aqui)
	ctx := context.Background()

	// 1. Tentar buscar do Cache (Redis)
	val, err := a.RedisClient.Get(ctx, cacheKey).Result()
	if err == nil {
		// Cache HIT
		var info CombinedFlagInfo
		if err := json.Unmarshal([]byte(val), &info); err == nil {
			log.Printf("Cache HIT para flag '%s'", flagName)
			return &info, nil
		}
		// Se o unmarshal falhar, trata como cache miss
		log.Printf("Erro ao desserializar cache para flag '%s': %v", flagName, err)
	}

	log.Printf("Cache MISS para flag '%s'", flagName)
	// 2. Cache MISS - Buscar dos serviços
	info, err := a.fetchFromServices(flagName)
	if err != nil {
		return nil, err
	}

	// 3. Salvar no Cache para as próximas consultas (expira em CACHE_TTL)
	jsonData, err := json.Marshal(info)
	if err == nil {
		a.RedisClient.Set(ctx, cacheKey, jsonData, CACHE_TTL).Err()
	}

	return info, nil
}

// fetchFromServices busca dados do flag-service e targeting-service concorrentemente
func (a *App) fetchFromServices(flagName string) (*CombinedFlagInfo, error) {
	var wg sync.WaitGroup
	wg.Add(2)

	var flagInfo *Flag
	var ruleInfo *TargetingRule
	var flagErr, ruleErr error

	// Goroutine 1: Buscar do flag-service
	go func() {
		defer wg.Done()
		flagInfo, flagErr = a.fetchFlag(flagName)
	}()

	// Goroutine 2: Buscar do targeting-service
	go func() {
		defer wg.Done()
		ruleInfo, ruleErr = a.fetchRule(flagName)
	}()

	wg.Wait()

	if flagErr != nil {
		return nil, flagErr
	}
	if ruleErr != nil {
		log.Printf("Aviso: Nenhuma regra de segmentação encontrada para '%s'. Usando padrão.", flagName)
	}

	return &CombinedFlagInfo{
		Flag: flagInfo,
		Rule: ruleInfo,
	}, nil
}

// fetchFlag consulta o flag-service via HTTP e devolve a definição da flag
// (nome, descrição e se está ligada). Autentica com a SERVICE_API_KEY.
func (a *App) fetchFlag(flagName string) (*Flag, error) {
	url := fmt.Sprintf("%s/flags/%s", a.FlagServiceURL, flagName)

	apiKey := os.Getenv("SERVICE_API_KEY")
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Authorization", "Bearer "+apiKey)

	resp, err := a.HttpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("erro ao chamar flag-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, &NotFoundError{flagName}
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("flag-service retornou status %d", resp.StatusCode)
	}

	body, _ := ioutil.ReadAll(resp.Body)
	var flag Flag
	if err := json.Unmarshal(body, &flag); err != nil {
		return nil, fmt.Errorf("erro ao desserializar resposta do flag-service: %w", err)
	}
	return &flag, nil
}

// fetchRule consulta o targeting-service via HTTP e devolve a regra de
// segmentação da flag (ex.: "50% dos usuários"). Uma flag pode não ter regra —
// nesse caso o retorno é NotFoundError, tratado como "sem segmentação".
func (a *App) fetchRule(flagName string) (*TargetingRule, error) {
	url := fmt.Sprintf("%s/rules/%s", a.TargetingServiceURL, flagName)
	apiKey := os.Getenv("SERVICE_API_KEY") // mesma chave usada no fetchFlag
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Authorization", "Bearer "+apiKey)

	resp, err := a.HttpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("erro ao chamar targeting-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, &NotFoundError{flagName} // Não é um erro fatal
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("targeting-service retornou status %d", resp.StatusCode)
	}

	body, _ := ioutil.ReadAll(resp.Body)
	var rule TargetingRule
	if err := json.Unmarshal(body, &rule); err != nil {
		return nil, fmt.Errorf("erro ao desserializar resposta do targeting-service: %w", err)
	}
	return &rule, nil
}

// runEvaluationLogic é onde a decisão é tomada, em 3 degraus:
//  1. flag desligada (kill switch global) → false para todos;
//  2. flag ligada e SEM regra de segmentação → true para todos;
//  3. flag ligada COM regra → aplica a regra (ex.: porcentagem de usuários).
func (a *App) runEvaluationLogic(info *CombinedFlagInfo, userID string) bool {
	// Degrau 1: sem flag ou flag desligada → nega para todo mundo
	if info.Flag == nil || !info.Flag.IsEnabled {
		return false
	}

	// Degrau 2: sem regra (ou regra desativada) → libera para todo mundo
	if info.Rule == nil || !info.Rule.IsEnabled {
		return true
	}

	// Degrau 3: processa a regra (só temos o tipo "PERCENTAGE" por enquanto)
	rule := info.Rule.Rules
	if rule.Type == "PERCENTAGE" {
		// O 'value' chega como interface{} (JSON genérico); números JSON viram float64
		percentage, ok := rule.Value.(float64)
		if !ok {
			log.Printf("Erro: valor da regra de porcentagem não é um número para a flag '%s'", info.Flag.Name)
			return false
		}

		// Sorteia o usuário em um "balde" fixo de 0 a 99.
		// Ex.: regra de 50% → usuários nos baldes 0–49 recebem true.
		userBucket := getDeterministicBucket(userID + info.Flag.Name)

		if float64(userBucket) < percentage {
			return true
		}
	}

	// Tipo de regra desconhecido ou usuário fora da porcentagem → false
	return false
}

// getDeterministicBucket transforma uma string (userID + flagName) em um número
// de 0 a 99 SEMPRE IGUAL para a mesma entrada. É isso que garante que o mesmo
// usuário receba sempre a mesma resposta para a mesma flag (sem sorteio aleatório).
func getDeterministicBucket(input string) int {
	// SHA-1 é usado só como "espalhador" rápido e uniforme (não é uso criptográfico)
	hasher := sha1.New()
	hasher.Write([]byte(input))
	hash := hasher.Sum(nil)

	// Converte os 4 primeiros bytes do hash em um número inteiro
	val := binary.BigEndian.Uint32(hash[:4])

	// Módulo 100 → resultado sempre entre 0 e 99
	return int(val % 100)
}
