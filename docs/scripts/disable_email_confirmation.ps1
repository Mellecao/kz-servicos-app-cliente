# Desabilitar confirmação de email e aumentar rate limit via Supabase Management API
# 1. Gere um access token em: https://supabase.com/dashboard/account/tokens
# 2. Substitua <SEU_TOKEN> abaixo pelo token gerado
# 3. Rode o comando no terminal

# PowerShell:
$headers = @{
    "Authorization" = "Bearer <SEU_TOKEN>"
    "Content-Type" = "application/json"
}

$body = @{
    MAILER_AUTOCONFIRM = $true
    RATE_LIMIT_EMAIL_SENT = 3600
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.supabase.com/v1/projects/wmlsiwjrgjygqdjtsayt/config/auth" -Method Patch -Headers $headers -Body $body

# Ou via curl (Git Bash / Linux / Mac):
# curl -X PATCH \
#   'https://api.supabase.com/v1/projects/wmlsiwjrgjygqdjtsayt/config/auth' \
#   -H 'Authorization: Bearer <SEU_TOKEN>' \
#   -H 'Content-Type: application/json' \
#   -d '{"MAILER_AUTOCONFIRM": true, "RATE_LIMIT_EMAIL_SENT": 3600}'
