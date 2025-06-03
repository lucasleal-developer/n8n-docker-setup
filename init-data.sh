#!/bin/bash
set -e

echo "Iniciando configuração do banco de dados..."
echo "Database: $POSTGRES_DB"
echo "User: $POSTGRES_USER"
echo "Non-root user: $POSTGRES_NON_ROOT_USER"

# Aguardar o PostgreSQL estar pronto
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
  echo "Aguardando PostgreSQL ficar pronto..."
  sleep 2
done

echo "PostgreSQL está pronto. Executando scripts de inicialização..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	-- Verificar se o usuário já existe
	DO \$\$
	BEGIN
		IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_NON_ROOT_USER') THEN
			CREATE USER $POSTGRES_NON_ROOT_USER WITH PASSWORD '$POSTGRES_NON_ROOT_PASSWORD';
			RAISE NOTICE 'Usuário $POSTGRES_NON_ROOT_USER criado com sucesso';
		ELSE
			RAISE NOTICE 'Usuário $POSTGRES_NON_ROOT_USER já existe';
		END IF;
	END
	\$\$;
	
	-- Conceder privilégios ao usuário
	GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_NON_ROOT_USER;
	
	-- Conceder privilégios no schema public
	GRANT ALL ON SCHEMA public TO $POSTGRES_NON_ROOT_USER;
	
	-- Conceder privilégios em todas as tabelas existentes e futuras
	GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $POSTGRES_NON_ROOT_USER;
	GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $POSTGRES_NON_ROOT_USER;
	GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $POSTGRES_NON_ROOT_USER;
	
	-- Definir privilégios padrão para objetos futuros
	ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $POSTGRES_NON_ROOT_USER;
	ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $POSTGRES_NON_ROOT_USER;
	ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $POSTGRES_NON_ROOT_USER;
	
	-- Verificar se o usuário foi configurado corretamente
	\\echo 'Verificando configuração do usuário:';
	\\du $POSTGRES_NON_ROOT_USER;
EOSQL

echo "Configuração do banco de dados concluída com sucesso!"