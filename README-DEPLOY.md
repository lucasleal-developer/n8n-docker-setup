# Guia de Deploy - N8N com PostgreSQL

## Problema Identificado

O container `n8n-n8n-oftpgb-postgres-1` estava ficando unhealthy devido a um problema comum com deploys automáticos do PostgreSQL em Docker:

**Scripts de inicialização do PostgreSQL só executam quando o diretório de dados está vazio.** Como o Dokploy faz deploys automáticos e o volume persiste entre deploys, os scripts `init-data.sh` não eram executados, causando problemas de configuração.

## Soluções Implementadas

### 1. Configuração de Volume Bind Mount
- Alterado o volume `db_storage` para usar bind mount local
- Dados agora ficam em `./postgres_data` no host
- Permite controle manual sobre quando limpar os dados

### 2. Melhorias no Health Check
- Health check mais específico: `pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}`
- Timeouts ajustados para dar mais tempo de inicialização
- Start period aumentado para 60s

### 3. Script de Limpeza
- Criado `clean-postgres.sh` para limpar dados antes do deploy
- Força a execução dos scripts de inicialização

### 4. Script de Inicialização Robusto
- `init-data.sh` melhorado com verificações e logs
- Aguarda PostgreSQL ficar pronto antes de executar
- Verificações de usuário existente

## Como Fazer Deploy Corretamente

### Opção 1: Deploy com Dados Limpos (Recomendado para primeira vez)

1. **No servidor Dokploy, execute o script de limpeza:**
   ```bash
   # Navegue até o diretório do projeto
   cd /caminho/para/projeto/n8n
   
   # Execute o script de limpeza
   chmod +x clean-postgres.sh
   ./clean-postgres.sh
   ```

2. **Faça o deploy no Dokploy**
   - O PostgreSQL iniciará com dados limpos
   - Scripts de inicialização serão executados
   - Usuário não-root será criado corretamente

### Opção 2: Deploy Preservando Dados

1. **Se você quer manter os dados existentes:**
   - Simplesmente faça o deploy normalmente
   - O PostgreSQL usará os dados existentes em `./postgres_data`
   - Scripts de inicialização não serão executados (comportamento normal)

## Verificação de Funcionamento

### 1. Verificar Status dos Containers
```bash
docker ps
docker logs n8n-n8n-oftpgb-postgres-1
```

### 2. Verificar Health Checks
```bash
docker inspect n8n-n8n-oftpgb-postgres-1 | grep -A 10 Health
```

### 3. Testar Conexão com Banco
```bash
docker exec -it n8n-n8n-oftpgb-postgres-1 psql -U postgres -d n8n
```

### 4. Verificar Usuário Não-Root
```sql
-- Dentro do psql
\du
-- Deve mostrar o usuário n8n_user com privilégios
```

## Troubleshooting

### Se o PostgreSQL ainda ficar unhealthy:

1. **Verifique os logs:**
   ```bash
   docker logs n8n-n8n-oftpgb-postgres-1
   ```

2. **Limpe os dados e tente novamente:**
   ```bash
   ./clean-postgres.sh
   # Depois faça novo deploy no Dokploy
   ```

3. **Verifique permissões do diretório:**
   ```bash
   ls -la postgres_data/
   # Deve ter permissões 700 e owner postgres
   ```

### Se o N8N não conseguir conectar:

1. **Verifique as variáveis de ambiente no .env**
2. **Confirme que o usuário não-root foi criado:**
   ```bash
   docker exec -it n8n-n8n-oftpgb-postgres-1 psql -U postgres -d n8n -c "\du"
   ```

## Arquivos Importantes

- `docker-compose.dokploy.yml` - Configuração principal
- `.env` - Variáveis de ambiente
- `init-data.sh` - Script de inicialização do PostgreSQL
- `clean-postgres.sh` - Script para limpar dados
- `.dockerignore` - Arquivos ignorados no build

## Notas Importantes

1. **Backup**: Sempre faça backup dos dados antes de executar `clean-postgres.sh`
2. **Primeira execução**: Use sempre dados limpos na primeira vez
3. **Deploys subsequentes**: Só limpe dados se houver problemas
4. **Monitoramento**: Acompanhe os logs durante o deploy

## Variáveis de Ambiente Necessárias

Certifique-se de que estas variáveis estão definidas no `.env`:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=sua_senha_postgres
POSTGRES_DB=n8n
POSTGRES_NON_ROOT_USER=n8n_user
POSTGRES_NON_ROOT_PASSWORD=sua_senha_n8n_user
N8N_ENCRYPTION_KEY=sua_chave_encriptacao
N8N_BASIC_AUTH_USER=seu_usuario_n8n
N8N_BASIC_AUTH_PASSWORD=sua_senha_n8n
GENERIC_TIMEZONE=America/Sao_Paulo
```