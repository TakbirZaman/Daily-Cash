# Daily Cash: every command, in order (Windows, cmd.exe)

## 0. One time, done by you (these ask for a browser login)
```bat
winget install --id GitHub.cli -e
gh auth login --hostname github.com --git-protocol https --web --scopes "repo,workflow"
gh auth setup-git
set SUPABASE_ACCESS_TOKEN=PASTE_TOKEN_FROM_supabase.com/dashboard/account/tokens
```

## 1. Everything in one command
```bat
cd /d D:\daily_cash
setup.bat -NoPrompt -ContactEmail you@example.com -OwnerName "Your Name"
```
If the Supabase project already exists, add: `-SupabaseUrl https://YOUR_ID.supabase.co -SupabaseKey YOUR_KEY`

## 2. Or step by step (after Supabase is ready)
```bat
cd /d D:\daily_cash
gh secret set SUPABASE_URL --repo TakbirZaman/Daily-Cash --body "https://YOUR_ID.supabase.co"
gh secret set SUPABASE_ANON_KEY --repo TakbirZaman/Daily-Cash --body "YOUR_KEY"
git remote set-url origin https://github.com/TakbirZaman/Daily-Cash.git
git push -u origin main --force
gh run list --repo TakbirZaman/Daily-Cash --workflow build-apk.yml --limit 1
gh run watch RUN_ID --repo TakbirZaman/Daily-Cash --exit-status
gh run view RUN_ID --repo TakbirZaman/Daily-Cash --log-failed
gh release download --repo TakbirZaman/Daily-Cash --pattern daily-cash.apk --clobber
gh api -X POST repos/TakbirZaman/Daily-Cash/pages -f "source[branch]=main" -f "source[path]=/docs"
adb install -r daily-cash.apk
```
The push starts the build by itself. Use `gh workflow run build-apk.yml --repo TakbirZaman/Daily-Cash` only if no run started.
