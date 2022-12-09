#Requires -Version 5.1
Write-Output "PowerShell: $($PSVersionTable.PSVersion)"
Set-StrictMode -Off

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

function Install-Environment {
    Write-InstallInfo "Installing web3 environment..."
    if (!(Test-Path $DEV_CONTAINER_DIR)) {
        New-Item -Type Directory $DEV_CONTAINER_DIR | Out-Null
        Write-InstallInfo "$DEV_CONTAINER_DIR has been created"
    }

    $configJsonfile = "$DEV_CONTAINER_DIR\devcontainer.json"
    Write-InstallInfo "Downloading devcontainer.json"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $CONFIG_JSON_REPO -OutFile $configJsonfile

    # Write-InstallInfo "Starting Docker Desktop"
    # Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    Write-InstallInfo "From mcr.microsoft.com/vscode/devcontainers/base"
    Write-InstallInfo "Components: nodejs truffle ganache lite-server"

    $total_extensions = cmd /c code --list-extensions
    $remote_extension_exist = ""
    foreach ($item in $total_extensions) {
        if ($item -eq "ms-vscode-remote.remote-containers") {
            $remote_extension_exist = $item
            break
        }
    }

    if ($remote_extension_exist -eq "") {
        cmd /c code --install-extension ms-vscode-remote.remote-containers
    }

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
$CONFIG_JSON_REPO = "https://github.com/yongxin-ms/web3-env-setup/releases/download/latest/devcontainer.json"
#$CONFIG_JSON_REPO = "https://github.com/yongxin-ms/web3-env-setup/releases/download/latest/devcontainer_unbox.json"
Install-Environment
