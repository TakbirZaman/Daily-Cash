# Daily Cash: one command setup.
#
#   setup.bat
#
# Creates the Supabase project and database (or uses the one you give it), stores the keys as GitHub secrets, pushes the code,
# builds the APK on GitHub, downloads it, and publishes the download page.
# Safe to run again: it reuses what already exists.

param(
    [string]$Repo = 'TakbirZaman/Daily-Cash',
    [string]$ProjectName = 'daily-cash',
    [string]$Region = 'ap-south-1',      # Mumbai, the closest region to Dhaka
    [string]$SupabaseUrl = '',           # give both to skip creating the Supabase project
    [string]$SupabaseKey = '',
    [string]$ContactEmail = '',          # for the privacy and terms pages
    [string]$OwnerName = '',
    [switch]$NoPrompt                    # never ask questions (for scripts and agents)
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-Location (Split-Path -Parent $PSScriptRoot)

function Step([string]$text) { Write-Host ''; Write-Host "==> $text" -ForegroundColor Cyan }
function Ok([string]$text) { Write-Host "    $text" -ForegroundColor Green }
function Warn([string]$text) { Write-Host "    $text" -ForegroundColor Yellow }

# Runs a native program without PowerShell 5.1 treating its progress output as an error.
function Native {
    param([scriptblock]$Cmd)
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Cmd 2>&1 | ForEach-Object { Write-Host "    $_" } }
    finally { $ErrorActionPreference = $old }
}

function NativeText {
    param([scriptblock]$Cmd)
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { return ((& $Cmd 2>$null) | Out-String).Trim() }
    finally { $ErrorActionPreference = $old }
}

function Invoke-Sb {
    param([string]$Method, [string]$Path, $Body = $null)
    $req = @{
        Method      = $Method
        Uri         = "https://api.supabase.com$Path"
        Headers     = $script:SbHeaders
        ContentType = 'application/json'
    }
    if ($null -ne $Body) {
        $json = $Body | ConvertTo-Json -Depth 6 -Compress
        $req.Body = [System.Text.Encoding]::UTF8.GetBytes($json)
    }
    try { return Invoke-RestMethod @req }
    catch {
        $detail = ''
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $detail = $_.ErrorDetails.Message }
        throw "Supabase API $Method $Path failed. $($_.Exception.Message) $detail"
    }
}

# ---------------------------------------------------------------- 1. tools
Step '1/9 Checking tools'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed. Install it from https://git-scm.com and run setup.bat again.'
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Warn 'GitHub CLI not found. Installing it with winget...'
    Native { winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements }
    $ghDir = 'C:\Program Files\GitHub CLI'
    if (Test-Path $ghDir) { $env:Path += ";$ghDir" }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI was installed. Close this window, open a new one, and run setup.bat again.'
    }
}
Ok 'git and gh are ready'

# ---------------------------------------------------------------- 2. github login
Step '2/9 Signing in to GitHub'
$status = NativeText { gh auth status }
if ($status -notmatch 'Logged in') {
    if ($NoPrompt) { throw 'Run this once yourself first: gh auth login --hostname github.com --git-protocol https --web --scopes "repo,workflow"' }
    Native { gh auth login --hostname github.com --git-protocol https --web --scopes 'repo,workflow' }
}
elseif ($status -notmatch 'workflow') {
    Native { gh auth refresh --hostname github.com --scopes workflow }
}
Native { gh auth setup-git }
$status = NativeText { gh auth status }
if ($status -notmatch 'Logged in') { throw 'GitHub login did not finish. Run setup.bat again.' }
Ok 'GitHub is connected'

$haveKeys = [bool]($SupabaseUrl -and $SupabaseKey)
if ($haveKeys) {
    Step '3-6/9 Using the Supabase project you gave (skipping project creation)'
    Ok $SupabaseUrl
}
else {
    # ---------------------------------------------------------------- 3. supabase token
    Step '3/9 Connecting to Supabase'
    $token = $env:SUPABASE_ACCESS_TOKEN
    if (-not $token) {
        if ($NoPrompt) { throw 'Set SUPABASE_ACCESS_TOKEN first (create it at https://supabase.com/dashboard/account/tokens).' }
        Write-Host '    Create a token at https://supabase.com/dashboard/account/tokens (any name), then paste it here.'
        $secure = Read-Host '    Supabase access token (hidden)' -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    if (-not $token) { throw 'No Supabase token given.' }
    $script:SbHeaders = @{ Authorization = "Bearer $token" }

    $orgs = @(Invoke-Sb 'GET' '/v1/organizations')
    if ($orgs.Count -eq 0) { throw 'No Supabase organization found. Create one at supabase.com first.' }
    $org = $orgs[0]
    $orgSlug = $org.slug
    if (-not $orgSlug) { $orgSlug = $org.id }
    Ok "Organization: $($org.name)"

    # ---------------------------------------------------------------- 4. project
    Step '4/9 Creating the Supabase project'
    $projects = @(Invoke-Sb 'GET' '/v1/projects')
    $project = $projects | Where-Object { $_.name -eq $ProjectName } | Select-Object -First 1
    $dbPass = ''
    if ($project) {
        Ok "Using the existing project '$ProjectName' ($($project.id))"
    }
    else {
        $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $bytes = New-Object byte[] 36
        $rng.GetBytes($bytes)
        $clean = ([Convert]::ToBase64String($bytes) -replace '[^A-Za-z0-9]', '')
        $dbPass = $clean.Substring(0, [Math]::Min(24, $clean.Length))
        $body = @{ name = $ProjectName; organization_slug = $orgSlug; db_pass = $dbPass; region = $Region }
        try { $project = Invoke-Sb 'POST' '/v1/projects' $body }
        catch {
            Warn 'Retrying with the older organization field name...'
            $body.Remove('organization_slug')
            $body['organization_id'] = $orgSlug
            $project = Invoke-Sb 'POST' '/v1/projects' $body
        }
        Ok "Created project '$ProjectName'"
    }
    $ref = $project.id
    if (-not $ref) { $ref = $project.ref }
    if (-not $ref) { throw 'Could not read the project reference from the Supabase reply.' }

    Write-Host '    Waiting for the database to start (about 2 minutes)...'
    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
        $p = Invoke-Sb 'GET' "/v1/projects/$ref"
        if ($p.status -eq 'ACTIVE_HEALTHY') { $ready = $true; break }
        Start-Sleep -Seconds 10
    }
    if (-not $ready) { throw 'The project did not become ready in 10 minutes. Wait, then run setup.bat again.' }
    Ok 'Database is running'

    # ---------------------------------------------------------------- 5. database
    Step '5/9 Creating the tables and security rules'
    $sql = Get-Content -Raw -Encoding UTF8 'supabase\setup_all.sql'
    $null = Invoke-Sb 'POST' "/v1/projects/$ref/database/query" @{ query = $sql }
    Ok 'Table and row security are in place'

    # ---------------------------------------------------------------- 6. auth settings
    Step '6/9 Setting login options'
    $template = '<h2>Reset your password</h2><p>Enter this code in the Daily Cash app:</p><h1>{{ .Token }}</h1><p>If you did not ask for this, ignore this email.</p>'
    $null = Invoke-Sb 'PATCH' "/v1/projects/$ref/config/auth" @{
        mailer_autoconfirm                = $true
        mailer_subjects_recovery          = 'Your Daily Cash code'
        mailer_templates_recovery_content = $template
    }
    Ok 'Email confirmation is off and the reset email shows the code'
}

# ---------------------------------------------------------------- 7. keys + secrets
Step '7/9 Saving the keys as GitHub secrets'
if ($haveKeys) {
    $url = $SupabaseUrl.TrimEnd('/')
    $anonKey = $SupabaseKey
    $ref = ($url -replace '^https://', '') -replace '\.supabase\.co.*$', ''
    $dbPass = ''
}
else {
    $keys = @(Invoke-Sb 'GET' "/v1/projects/$ref/api-keys")
    $anon = $keys | Where-Object { $_.type -eq 'publishable' } | Select-Object -First 1
    if (-not $anon) { $anon = $keys | Where-Object { $_.name -eq 'anon' } | Select-Object -First 1 }
    if (-not $anon -or -not $anon.api_key) {
        throw "Could not read the public key. Copy it from https://supabase.com/dashboard/project/$ref/settings/api-keys and run: setup.bat -SupabaseUrl https://$ref.supabase.co -SupabaseKey THE_KEY"
    }
    $url = "https://$ref.supabase.co"
    $anonKey = $anon.api_key
}
Native { gh secret set SUPABASE_URL --repo $Repo --body $url }
Native { gh secret set SUPABASE_ANON_KEY --repo $Repo --body $anonKey }
$lines = @("Project: $ref", "URL: $url")
if ($dbPass) { $lines += "Database password: $dbPass" }
Set-Content -Path '.dailycash-secrets.txt' -Value $lines -Encoding UTF8
Ok "Secrets saved on GitHub. Details are in .dailycash-secrets.txt (kept off GitHub)"

# ---------------------------------------------------------------- 8. push + build
Step '8/9 Pushing the code and building the APK'
Native { git remote remove origin }
Native { git remote add origin "https://github.com/$Repo.git" }
Native { git push -u origin main --force }
if ($LASTEXITCODE -ne 0) { throw 'git push failed. Paste the message above and I will help.' }

Write-Host '    Waiting for the build to start...'
$runId = ''
for ($i = 0; $i -lt 12 -and -not $runId; $i++) {
    Start-Sleep -Seconds 5
    $runId = NativeText { gh run list --repo $Repo --workflow build-apk.yml --limit 1 --json databaseId --jq '.[0].databaseId' }
}
if (-not $runId) { throw "The build did not start. Open https://github.com/$Repo/actions and click Run workflow." }
Write-Host "    Build $runId is running. This takes about 10 minutes."
Native { gh run watch $runId --repo $Repo --exit-status }
if ($LASTEXITCODE -ne 0) {
    $log = NativeText { gh run view $runId --repo $Repo --log-failed }
    $tail = ($log -split "`n" | Select-Object -Last 80) -join "`n"
    Set-Content -Path 'build-error.txt' -Value $tail -Encoding UTF8
    Write-Host ''
    Write-Host 'The build failed. The last lines of the error were saved to build-error.txt.' -ForegroundColor Red
    Write-Host 'Paste that file here and I will fix it. Nothing else was lost.'
    exit 1
}
Ok 'Build finished'

Native { gh release download --repo $Repo --pattern 'daily-cash.apk' --dir . --clobber }
$releaseUrl = NativeText { gh release view --repo $Repo --json url --jq '.url' }
if (Test-Path 'daily-cash.apk') { Ok "APK saved: $(Resolve-Path 'daily-cash.apk')" }

if (Get-Command adb -ErrorAction SilentlyContinue) {
    $devices = NativeText { adb devices }
    if ($devices -match "`tdevice") {
        Write-Host '    Phone found. Installing...'
        Native { adb install -r daily-cash.apk }
    }
}

# ---------------------------------------------------------------- 9. download page
Step '9/9 Publishing the download page'
$email = $ContactEmail
$owner = $OwnerName
if (-not $NoPrompt) {
    if (-not $email) { $email = Read-Host '    Contact email for the privacy page (Enter to skip)' }
    if (-not $owner) { $owner = Read-Host '    Your name or business name for the terms page (Enter to skip)' }
}
$apkLink = "https://github.com/$Repo/releases/latest/download/daily-cash.apk"

$cfg = Get-Content -Raw -Encoding UTF8 'docs\config.js'
$cfg = [regex]::Replace($cfg, 'apkUrl:\s*"[^"]*"', "apkUrl: `"$apkLink`"")
Set-Content -Path 'docs\config.js' -Value $cfg -Encoding UTF8 -NoNewline

if ($email) {
    foreach ($f in 'docs\privacy.html', 'docs\terms.html') {
        (Get-Content -Raw -Encoding UTF8 $f).Replace('{{contact_email}}', $email) | Set-Content -Path $f -Encoding UTF8 -NoNewline
    }
}
if ($owner) {
    (Get-Content -Raw -Encoding UTF8 'docs\terms.html').Replace('{{owner_name}}', $owner) | Set-Content -Path 'docs\terms.html' -Encoding UTF8 -NoNewline
}

Native { git add docs }
Native { git commit -m 'Publish download page settings' }
Native { git push origin main }
Native { gh api -X POST "repos/$Repo/pages" -f 'source[branch]=main' -f 'source[path]=/docs' }
$pagesUrl = "https://$($Repo.Split('/')[0].ToLower()).github.io/$($Repo.Split('/')[1])/"

Write-Host ''
Write-Host '================ ALL DONE ================' -ForegroundColor Green
Write-Host "APK on your phone:  open $releaseUrl and tap daily-cash.apk"
Write-Host "Download page:      $pagesUrl   (live in a minute or two)"
Write-Host "Supabase project:   https://supabase.com/dashboard/project/$ref"
if (-not $email) { Warn 'Fill {{contact_email}} in docs\privacy.html and docs\terms.html before sharing the page.' }
