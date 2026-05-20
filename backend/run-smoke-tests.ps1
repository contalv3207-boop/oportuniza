# Smoke tests para a API do backend Oportuniza
# Executa: register -> login -> profile -> favorites -> applications -> messages

$Base = 'http://localhost:4000/api'
$timestamp = (Get-Date).ToString('yyyyMMddHHmmss')
$name = "TestUser_$timestamp"
$email = "test_$timestamp@example.com"
$password = '1234'

Write-Host "Base URL: $Base"

function Invoke-Api($Method, $Path, $Body = $null, $UserId = $null) {
    $uri = "$Base$Path"
    $headers = @{}
    if ($UserId) { $headers['x-user-id'] = $UserId }

    if ($Body -ne $null) {
        $json = $Body | ConvertTo-Json -Depth 5
        return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -ContentType 'application/json' -Body $json
    } else {
        return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
    }
}

# 1) Register
try {
    Write-Host "[1] Registrando usuário $email..."
    $reg = Invoke-Api -Method 'POST' -Path '/register' -Body @{ name = $name; email = $email; password = $password }
    $userId = $reg.id
    Write-Host "-> Registrado com id: $userId`n"
} catch {
    Write-Host "Registro falhou: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2) Login (verify)
try {
    Write-Host "[2] Fazendo login..."
    $login = Invoke-Api -Method 'POST' -Path '/login' -Body @{ email = $email; password = $password }
    if ($login.id -ne $userId) { Write-Host "Aviso: id de login ($($login.id)) diferente do id de registro ($userId)" -ForegroundColor Yellow }
    Write-Host "-> Login OK, id: $($login.id)`n"
} catch {
    Write-Host "Login falhou: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3) Profile POST
try {
    Write-Host "[3] Salvando perfil..."
    Invoke-Api -Method 'POST' -Path '/profile' -Body @{ profession = 'Developer'; experience = '3'; city = 'São Paulo'; bio = 'Perfil de teste'; skills = 'JS,Node'; photo = '' } -UserId $userId
    $profile = Invoke-Api -Method 'GET' -Path '/profile' -UserId $userId
    Write-Host "-> Perfil obtido: " -NoNewline; $profile | ConvertTo-Json | Write-Host
    Write-Host ""
} catch {
    Write-Host "Profile API falhou: $($_.Exception.Message)" -ForegroundColor Red
}

# 4) Favorites
try {
    Write-Host "[4] Testando favorites..."
    Invoke-Api -Method 'POST' -Path '/favorites' -Body @{ type = 'job'; itemId = 99999; title = 'Vaga Teste' } -UserId $userId
    $favs = Invoke-Api -Method 'GET' -Path '/favorites' -UserId $userId
    Write-Host "-> Favorites: " -NoNewline; $favs | ConvertTo-Json | Write-Host
    # cleanup delete
    Invoke-Api -Method 'DELETE' -Path "/favorites/job/99999" -UserId $userId
    Write-Host "-> Favorite deletado`n"
} catch {
    Write-Host "Favorites API falhou: $($_.Exception.Message)" -ForegroundColor Red
}

# 5) Applications
try {
    Write-Host "[5] Testando applications..."
    Invoke-Api -Method 'POST' -Path '/applications' -Body @{ jobId = 99999; title = 'Vaga Teste'; company = 'ACME' } -UserId $userId
    $apps = Invoke-Api -Method 'GET' -Path '/applications' -UserId $userId
    Write-Host "-> Applications: " -NoNewline; $apps | ConvertTo-Json | Write-Host
    if ($apps.Length -gt 0) {
        $appId = $apps[0].id
        Invoke-Api -Method 'DELETE' -Path "/applications/$appId" -UserId $userId
        Write-Host "-> Application $appId deletada"
    }
    Write-Host ""
} catch {
    Write-Host "Applications API falhou: $($_.Exception.Message)" -ForegroundColor Red
}

# 6) Messages
try {
    Write-Host "[6] Enviando mensagem de usuário..."
    Invoke-Api -Method 'POST' -Path '/messages' -Body @{ sender = 'user'; context = 'general'; title = 'Teste'; body = 'Olá do smoke test'; time = 'Agora'; read = $false } -UserId $userId
    $msgs = Invoke-Api -Method 'GET' -Path '/messages' -UserId $userId
    Write-Host "-> Messages: " -NoNewline; $msgs | ConvertTo-Json | Write-Host

    # tenta marcar a primeira mensagem do bot como lida (se existir)
    $botUnread = $msgs | Where-Object { $_.sender -eq 'bot' -and ($_.read -eq 0 -or $_.read -eq $false) } | Select-Object -First 1
    if ($botUnread) {
        Write-Host "-> Marcando mensagem bot id $($botUnread.id) como lida..."
        Invoke-Api -Method 'PATCH' -Path "/messages/$($botUnread.id)/read" -UserId $userId
        Write-Host "-> Marcada como lida"
    } else {
        Write-Host "-> Nenhuma mensagem do bot não-lida encontrada"
    }
    Write-Host ""
} catch {
    Write-Host "Messages API falhou: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Smoke tests finalizados. Verifique o log acima para detalhes."
