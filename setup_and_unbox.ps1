#Requires -Version 5.1
Write-Output "PowerShell: $($PSVersionTable.PSVersion)"

function Write-InstallInfo {
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $String,
        [Parameter(Mandatory = $False, Position = 1)]
        [System.ConsoleColor] $ForegroundColor = $host.UI.RawUI.ForegroundColor
    )

    $backup = $host.UI.RawUI.ForegroundColor

    if ($ForegroundColor -ne $host.UI.RawUI.ForegroundColor) {
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    Write-Output "$String"

    $host.UI.RawUI.ForegroundColor = $backup
}

function Get-Downloader {
    $downloadSession = New-Object System.Net.WebClient

    # Set proxy to null if NoProxy is specificed
    if ($NoProxy) {
        $downloadSession.Proxy = $null
    }
    elseif ($Proxy) {
        # Prepend protocol if not provided
        if (!$Proxy.IsAbsoluteUri) {
            $Proxy = New-Object System.Uri("http://" + $Proxy.OriginalString)
        }

        $Proxy = New-Object System.Net.WebProxy($Proxy)

        if ($null -ne $ProxyCredential) {
            $Proxy.Credentials = $ProxyCredential.GetNetworkCredential()
        }
        elseif ($ProxyUseDefaultCredentials) {
            $Proxy.UseDefaultCredentials = $true
        }

        $downloadSession.Proxy = $Proxy
    }

    return $downloadSession
}

function Install-Environment {
    Write-InstallInfo "Installing web3 environment..."
    if (!(Test-Path $DEV_CONTAINER_DIR)) {
        New-Item -Type Directory $DEV_CONTAINER_DIR | Out-Null
        Write-InstallInfo "$DEV_CONTAINER_DIR has been created"
    }

    $downloader = Get-Downloader
    $configJsonfile = "$DEV_CONTAINER_DIR\devcontainer.json"
    Write-InstallInfo "Downloading devcontainer.json"
    $downloader.downloadFile($CONFIG_JSON_REPO, $configJsonfile)

    # Write-InstallInfo "Starting Docker Desktop"
    # Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    Write-InstallInfo "From mcr.microsoft.com/vscode/devcontainers/base"
    Write-InstallInfo "Components: nodejs truffle ganache lite-server"

    Write-InstallInfo "Openning vs code"
    $enc = [System.Text.Encoding]::UTF8

    $project_path = (Get-Location).Path
    $project_name = $project_path.Split("\")[-1]
    $hex_path = ($enc.GetBytes($project_path) | ForEach-Object ToString X2) -join ''

    $cmd = "code --folder-uri=vscode-remote://dev-container%2b" + `
        $hex_path + "/workspaces/" + $project_name
    # Write-InstallInfo $cmd
    cmd /c $cmd

    Write-InstallInfo "All done"
}

$DEV_CONTAINER_DIR = ".\.devcontainer"
#$CONFIG_JSON_REPO = "https://github.com/yongxin-ms/web3-env-setup/releases/download/latest/devcontainer.json"
$CONFIG_JSON_REPO = "https://github.com/yongxin-ms/web3-env-setup/releases/download/latest/devcontainer_unbox.json"
Install-Environment
