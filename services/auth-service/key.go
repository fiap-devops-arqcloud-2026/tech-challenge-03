package main

import (
	"crypto/rand"   // gerador de números aleatórios criptograficamente seguro
	"crypto/sha256" // hash usado para armazenar a chave sem expor o valor original
	"encoding/hex"  // converte bytes para texto hexadecimal legível
)

// generateAPIKey cria uma string aleatória segura de 32 bytes
func generateAPIKey() (string, error) {
	bytes := make([]byte, 32) // 32 bytes = 256 bits de entropia
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	// Prefixo para facilitar a identificação da chave
	return "tm_key_" + hex.EncodeToString(bytes), nil
}

// hashAPIKey calcula o hash SHA-256 de uma chave para armazenamento seguro
func hashAPIKey(key string) string {
	hash := sha256.Sum256([]byte(key))
	// Retorna o hash como uma string hexadecimal de 64 caracteres
	return hex.EncodeToString(hash[:])
}
