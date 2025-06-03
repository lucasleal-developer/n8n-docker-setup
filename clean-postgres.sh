#!/bin/bash

# Script para limpar dados do PostgreSQL antes do deploy
# Isso força a execução dos scripts de inicialização

echo "Limpando dados do PostgreSQL..."

# Remove o diretório de dados do PostgreSQL se existir
if [ -d "./postgres_data" ]; then
    echo "Removendo diretório postgres_data existente..."
    rm -rf ./postgres_data
fi

# Cria o diretório novamente
echo "Criando novo diretório postgres_data..."
mkdir -p ./postgres_data

# Define permissões corretas (PostgreSQL precisa de 700)
chmod 700 ./postgres_data

echo "Limpeza concluída. O PostgreSQL será inicializado com dados limpos no próximo deploy."