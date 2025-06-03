# n8n Docker Installation - Configuração Completa

Esta é uma instalação completa do n8n com Docker incluindo todos os componentes necessários para produção:

## Componentes Incluídos

- **n8n Primary**: Instância principal que gerencia triggers, webhooks e interface web
- **n8n Workers (2x)**: Instâncias worker para processamento de workflows em paralelo
- **n8n Webhook**: Processador dedicado para webhooks
- **PostgreSQL 16**: Banco de dados para armazenar workflows, credenciais e execuções
- **Redis 7**: Message broker para queue de execuções

## Pré-requisitos

- Docker Desktop instalado
- Docker Compose instalado
- Pelo menos 4GB de RAM disponível
- Portas 5678, 5679, 5432 e 6379 disponíveis

## Configuração Inicial

### 1. Editar Variáveis de Ambiente

Antes de iniciar, **OBRIGATORIAMENTE** edite o arquivo `.env` e altere as seguintes variáveis:

```bash
# Senhas do PostgreSQL (ALTERE ESTAS SENHAS!)
POSTGRES_PASSWORD=sua_senha_forte_postgres_aqui
POSTGRES_NON_ROOT_PASSWORD=sua_senha_forte_n8n_aqui

# Chave de criptografia do n8n (32 caracteres)
N8N_ENCRYPTION_KEY=sua_chave_de_32_caracteres_aqui

# Credenciais de acesso ao n8n
N8N_BASIC_AUTH_USER=seu_usuario_admin
N8N_BASIC_AUTH_PASSWORD=sua_senha_admin_aqui

# URL do webhook (ajuste conforme necessário)
WEBHOOK_URL=http://localhost:5679
```

### 2. Gerar Chave de Criptografia

Para gerar uma chave de criptografia segura de 32 caracteres:

```bash
# No Windows (PowerShell)
[System.Web.Security.Membership]::GeneratePassword(32, 0)

# Ou use um gerador online confiável
```

## Instalação

### 1. Iniciar os Serviços

```bash
# Navegar para o diretório
cd l:\n8n

# Iniciar todos os serviços
docker-compose up -d
```

### 2. Verificar Status dos Serviços

```bash
# Verificar se todos os containers estão rodando
docker-compose ps

# Verificar logs
docker-compose logs -f
```

### 3. Acessar o n8n

- **Interface Principal**: http://localhost:5678
- **Webhook Endpoint**: http://localhost:5679

## Arquitetura da Solução

### Fluxo de Execução

1. **n8n Primary** recebe triggers e webhooks
2. Execuções são enfileiradas no **Redis**
3. **Workers** processam as execuções da fila
4. **PostgreSQL** armazena dados persistentes
5. **Webhook Processor** lida com webhooks externos

### Portas Utilizadas

- `5678`: n8n Interface Principal
- `5679`: n8n Webhook Processor
- `5432`: PostgreSQL
- `6379`: Redis

## Comandos Úteis

### Gerenciamento dos Serviços

```bash
# Parar todos os serviços
docker-compose stop

# Reiniciar todos os serviços
docker-compose restart

# Parar e remover containers
docker-compose down

# Parar e remover containers + volumes (CUIDADO: apaga dados!)
docker-compose down -v
```

### Logs e Monitoramento

```bash
# Ver logs de todos os serviços
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f n8n
docker-compose logs -f n8n-worker-1
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Backup e Restore

```bash
# Backup do PostgreSQL
docker-compose exec postgres pg_dump -U postgres n8n > backup_n8n.sql

# Restore do PostgreSQL
docker-compose exec -T postgres psql -U postgres n8n < backup_n8n.sql
```

## Escalabilidade

### Adicionar Mais Workers

Para adicionar mais workers, edite o `docker-compose.yml` e adicione:

```yaml
n8n-worker-3:
  <<: *shared
  container_name: n8n-worker-3
  command: worker
  environment:
    # ... mesmas configurações dos outros workers
  depends_on:
    - n8n
```

### Monitoramento de Performance

```bash
# Verificar uso de recursos
docker stats

# Verificar fila do Redis
docker-compose exec redis redis-cli
> LLEN bull:jobs:waiting
> LLEN bull:jobs:active
```

## Segurança

### Recomendações de Produção

1. **Altere todas as senhas padrão**
2. **Use HTTPS em produção**
3. **Configure firewall adequadamente**
4. **Mantenha backups regulares**
5. **Monitore logs de segurança**

### Configuração de SSL/HTTPS

Para produção, adicione um reverse proxy (nginx/traefik) com SSL:

```yaml
# Exemplo com nginx
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
    - ./ssl:/etc/ssl
```

## Troubleshooting

### Problemas Comuns

1. **Containers não iniciam**:
   - Verifique se as portas estão disponíveis
   - Verifique logs: `docker-compose logs`

2. **n8n não conecta ao PostgreSQL**:
   - Verifique credenciais no `.env`
   - Aguarde o PostgreSQL estar healthy

3. **Workers não processam execuções**:
   - Verifique conexão com Redis
   - Verifique logs dos workers

4. **Webhooks não funcionam**:
   - Verifique se o webhook processor está rodando
   - Verifique a URL configurada

### Verificação de Saúde

```bash
# Verificar saúde do PostgreSQL
docker-compose exec postgres pg_isready -U postgres

# Verificar saúde do Redis
docker-compose exec redis redis-cli ping

# Verificar conectividade n8n -> PostgreSQL
docker-compose exec n8n nc -zv postgres 5432

# Verificar conectividade n8n -> Redis
docker-compose exec n8n nc -zv redis 6379
```

## Atualizações

### Atualizar n8n

```bash
# Parar serviços
docker-compose stop

# Atualizar imagens
docker-compose pull

# Reiniciar serviços
docker-compose up -d
```

## Suporte

Para mais informações:
- [Documentação Oficial n8n](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)

---

**Importante**: Esta configuração está pronta para desenvolvimento e testes. Para produção, implemente as medidas de segurança adicionais mencionadas acima.