# Guia de Estudo - Introducao a Containers

Fonte analisada em 2026-07-17: `tech-challenge-02/docs/Material aulas/2 - Introducao a containers`.

## Resumo para leigos

Container e uma forma de empacotar uma aplicacao para ela rodar do mesmo jeito em lugares diferentes. Em vez de dizer "na minha maquina funciona", a equipe passa a dizer "a imagem Docker define exatamente como roda".

Uma imagem e como uma receita pronta. O container e a receita sendo executada. O Dockerfile e o arquivo que ensina como montar essa receita.

## Explicacao tecnica

Docker cria imagens imutaveis com sistema de arquivos em camadas. Essas imagens sao executadas como containers isolados por recursos do kernel, como namespaces e cgroups. Para projetos com varios servicos, Docker Compose descreve varios containers em um arquivo YAML.

Para producao, o modulo reforca imagens menores, builds em multiplos estagios, usuarios nao root, analise de vulnerabilidades, volumes, redes e troubleshooting.

## Aulas

### Aula 1 - Introducao a Containers

Simples: explica o problema de ambientes diferentes e como containers resolvem isso.

Tecnico: compara maquinas fisicas, maquinas virtuais e containers. Docker aparece como ferramenta central para criar, executar e distribuir containers.

No projeto: cada microsservico do ToggleMaster precisa ter imagem Docker confiavel para o pipeline publicar no ECR.

### Aula 2 - Imagens e Containers

Simples: imagem e modelo; container e a imagem rodando.

Tecnico: trabalha comandos como `docker pull`, `docker run`, `docker ps`, `docker stop` e ciclo de vida de containers.

No projeto: o pipeline vai criar uma imagem por servico e versionar por hash de commit.

### Aula 3 - Dockerfile e Build de Imagens

Simples: Dockerfile e o passo a passo para construir a imagem.

Tecnico: aborda imagens base como `alpine`, `slim` e `distroless`, `.dockerignore`, cache, multistage builds e ferramentas como Dive e Snyk.

No projeto: imagens pequenas e seguras reduzem custo, tempo de build e vulnerabilidades nos scans.

### Aula 4 - Volumes e Redes

Simples: volumes guardam dados; redes permitem containers conversarem.

Tecnico: diferencia volumes nomeados, bind mounts, `tmpfs`, redes `bridge`, `host` e `none`.

No projeto: no ambiente local, Docker Compose usa redes e volumes. Na AWS, a persistencia principal deve ir para RDS, Redis, DynamoDB e SQS, nao para dados soltos dentro do container.

### Aula 5 - Docker Compose

Simples: Compose sobe varios containers com um comando.

Tecnico: usa `docker-compose.yml` para declarar servicos, redes, volumes, variaveis e dependencias.

No projeto: Compose e util para desenvolvimento local do ToggleMaster, mas a entrega de producao vai para Kubernetes/EKS.

### Aula 6 - Boas Praticas, Seguranca e Troubleshooting

Simples: fazer rodar nao basta; precisa rodar leve, seguro e facil de diagnosticar.

Tecnico: cobre logs, inspecao, usuarios nao root, reducao de superficie de ataque, scanners, namespaces, capabilities e seccomp.

No projeto: esses conceitos alimentam o pipeline DevSecOps: SCA, SAST e scan de imagem Docker.

## Glossario

- Docker: ferramenta para criar e executar containers.
- Imagem: pacote imutavel usado para iniciar containers.
- Container: instancia em execucao de uma imagem.
- Dockerfile: arquivo com instrucoes de build da imagem.
- Layer: camada da imagem Docker.
- Volume: armazenamento persistente usado por containers.
- Network: rede virtual para comunicacao entre containers.
- Docker Compose: orquestracao local de multiplos containers.
- Multistage build: build em etapas para reduzir tamanho final da imagem.
- Seccomp: mecanismo de restricao de chamadas ao kernel.

## Caso de uso no ToggleMaster

- `auth-service` e `evaluation-service` em Go podem usar multistage build: compila em uma imagem e roda binario pequeno em outra.
- Servicos Python podem usar imagem `python:slim`, `.dockerignore` e usuario nao root.
- O pipeline da Fase 3 deve escanear filesystem e imagem antes de publicar no ECR.
- Docker Compose continua sendo bom para teste local, mas nao substitui EKS.

## Checklist de estudo

- [ ] Explicar diferenca entre imagem e container.
- [ ] Ler e escrever um Dockerfile simples.
- [ ] Entender por que multistage build reduz risco e tamanho.
- [ ] Saber quando usar volume e quando usar banco gerenciado.
- [ ] Saber diagnosticar container com logs, inspect e exec.
