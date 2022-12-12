#Requires -Version 5.1
Write-Output "PowerShell: $($PSVersionTable.PSVersion)"
Set-StrictMode -Off

function Write-InstallInfo([String] $String, [System.ConsoleColor] $ForegroundColor = $host.UI.RawUI.ForegroundColor) {
    $backup = $host.UI.RawUI.ForegroundColor
    if ($ForegroundColor -ne $host.UI.RawUI.ForegroundColor) {
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    Write-Output "$String"
    $host.UI.RawUI.ForegroundColor = $backup
}

function CheckAndInstallVsCodeExtension([String] $extension_name) {
    $total_extensions = cmd /c code --list-extensions
    $remote_extension_exist = $false
    foreach ($item in $total_extensions) {
        if ($item -eq $extension_name) {
            $remote_extension_exist = $true
            break
        }
    }

    if (!$remote_extension_exist) {
        Write-InstallInfo "vs code extension $extension_name not exist, installing"
        cmd /c code --install-extension $extension_name
    }
}

function CheckProcessExist([String] $process_name) {
    $process = Get-Process -Name $process_name
    foreach ($item in $process) {
        return $true
    }
    return $false
}

function Install-Environment([String] $config_json_repo) {
    Write-InstallInfo("Installing web3 environment...")
    $docker_exist = CheckProcessExist("Docker Desktop")
    if (!$docker_exist) {
        exit 1
    }

    CheckAndInstallVsCodeExtension("ms-vscode-remote.remote-containers")

    if (!(Test-Path $DEV_CONTAINER_DIR)) {
        New-Item -Type Directory $DEV_CONTAINER_DIR | Out-Null
        Write-InstallInfo "$DEV_CONTAINER_DIR has been created"
    }

    $configJsonfile = "$DEV_CONTAINER_DIR\devcontainer.json"
    Write-InstallInfo("Downloading devcontainer.json")

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $config_json_repo -OutFile $configJsonfile

    Write-InstallInfo("From mcr.microsoft.com/vscode/devcontainers/base")
    Write-InstallInfo("Components: nodejs truffle ganache lite-server")

    Write-InstallInfo("Openning vs code")
    $enc = [System.Text.Encoding]::UTF8
    $project_path = (Get-Location).Path
    $project_name = $project_path.Split("\")[-1]
    $hex_path = ($enc.GetBytes($project_path) | ForEach-Object ToString X2) -join ''
    $cmd = "code --folder-uri=vscode-remote://dev-container%2b" + `
        $hex_path + "/workspaces/" + $project_name
    # Write-InstallInfo $cmd
    cmd /c $cmd

    Write-InstallInfo("All done")
}

$DEV_CONTAINER_DIR = ".\.devcontainer"
Install-Environment("https://github.com/yongxin-ms/web3-env-setup/releases/download/latest/devcontainer.json")
#Install-Environment("https://github.com/yongxin-ms/web3-env-setup/releases/download/latest/devcontainer_unbox.json")
