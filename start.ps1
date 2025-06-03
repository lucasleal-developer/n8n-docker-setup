# Script de Inicialização do n8n
# Execute este script no PowerShell como Administrador

Write-Host "=== n8n Docker Setup Script ===" -ForegroundColor Green
Write-Host ""

# Verificar se Docker está instalado
Write-Host "Verificando se Docker está instalado..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker encontrado: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker não encontrado. Por favor, instale o Docker Desktop primeiro." -ForegroundColor Red
    Write-Host "Download: https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
    exit 1
}

# Verificar se Docker Compose está disponível
Write-Host "Verificando Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker compose version
    Write-Host "✓ Docker Compose encontrado: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose não encontrado." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== IMPORTANTE: Configuração Necessária ===" -ForegroundColor Red
Write-Host "Antes de continuar, você DEVE editar o arquivo .env e alterar:" -ForegroundColor Yellow
Write-Host "1. POSTGRES_PASSWORD" -ForegroundColor White
Write-Host "2. POSTGRES_NON_ROOT_PASSWORD" -ForegroundColor White
Write-Host "3. N8N_ENCRYPTION_KEY (32 caracteres)" -ForegroundColor White
Write-Host "4. N8N_BASIC_AUTH_USER" -ForegroundColor White
Write-Host "5. N8N_BASIC_AUTH_PASSWORD" -ForegroundColor White
Write-Host ""

# Gerar chave de criptografia
Write-Host "Gerando chave de criptografia de exemplo..." -ForegroundColor Yellow
$encryptionKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
Write-Host "Chave de criptografia sugerida: $encryptionKey" -ForegroundColor Cyan
Write-Host "Copie esta chave para o arquivo .env na variável N8N_ENCRYPTION_KEY" -ForegroundColor Yellow
Write-Host ""

$continue = Read-Host "Você já editou o arquivo .env? (s/N)"
if ($continue -ne "s" -and $continue -ne "S") {
    Write-Host "Por favor, edite o arquivo .env primeiro e execute este script novamente." -ForegroundColor Yellow
    exit 0
}

# Verificar se as portas estão disponíveis
Write-Host "Verificando portas necessárias..." -ForegroundColor Yellow
$ports = @(5678, 5679, 5432, 6379)
foreach ($port in $ports) {
    $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
    if ($connection.TcpTestSucceeded) {
        Write-Host "✗ Porta $port está em uso. Por favor, libere esta porta." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✓ Porta $port disponível" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Iniciando containers do n8n..." -ForegroundColor Green

# Iniciar containers
try {
    docker compose up -d
    Write-Host "✓ Containers iniciados com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "✗ Erro ao iniciar containers. Verifique os logs." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Aguardando serviços ficarem prontos..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Verificar status dos containers
Write-Host "Verificando status dos containers..." -ForegroundColor Yellow
$containers = docker compose ps --format "table {{.Name}}\t{{.Status}}"
Write-Host $containers

Write-Host ""
Write-Host "=== Instalação Concluída! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Acesse o n8n em:" -ForegroundColor Cyan
Write-Host "• Interface Principal: http://localhost:5678" -ForegroundColor White
Write-Host "• Webhook Endpoint: http://localhost:5679" -ForegroundColor White
Write-Host ""
Write-Host "Comandos úteis:" -ForegroundColor Cyan
Write-Host "• Ver logs: docker compose logs -f" -ForegroundColor White
Write-Host "• Parar: docker compose stop" -ForegroundColor White
Write-Host "• Reiniciar: docker compose restart" -ForegroundColor White
Write-Host ""
Write-Host "Consulte o README.md para mais informações." -ForegroundColor Yellow