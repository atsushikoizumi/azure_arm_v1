# version 2.1.0

<#
.SYNOPSIS
ARM Template Deploy Script

.DESCRIPTION
This Script executes in the following order
1. Set Environments
2. Create ResouceGroup if it does not exist
3. Test Template File
4. Deploy Template File

.POLICY
Operate as follows
1. One TemplateFile, One ResouceGroup
2. ResouceGroup Name is "$ownerName.$serviceName.$environmentName"
3. Tags are Owner=$ownerName, Service=$serviceName, Env=$environmentName
4. Deploy mode is Complete

.READY
Do the following.
[windows] install Az Module
    Install-Module -Name PowerShellGet -Force
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
[mac] install PowerShell & Az Module
    brew install --cask powershell
    pwsh
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
[common] Connect to Azure with a browser sign in
    PS > Connect-AzAccount

#>

# Environments
$location          = "eastus"
$ownerName         = "atsushi.koizumi"
$serviceName       = Read-Host "list: sql/psg    select"  # Define service name
$environmentName   = Read-Host "list: dev/stg/prd  select"  # Define environment name
$templateFile      = "$PSScriptRoot\$serviceName\azuredeploy.json"
$prametersFile     = "$PSScriptRoot\$serviceName\$environmentName.parameters.json"
$logfile           = "deployment.log"
$azKeyVaultName    = "armtemplatekey"
$resourceGroupName = "$ownerName.$serviceName.$environmentName"

################
# Script Start #
################

# error handling
$ErrorActionPreference = "Stop"

# get datetime
$Datetime = Get-date -format "yyyyMMddHHmmss"

# check $templateFile
Write-Host ""
if (Test-Path -Path $templateFile ) {
    Write-Host "Template File: $templateFile"
} else {
    Write-Host """Template File: $templateFile"" does not exist."
    exit
}

# check $prametersFile
if (Test-Path -Path $prametersFile ) {
    Write-Host "Parameter File: $prametersFile"
} else {
    Write-Host """Parameter File: $prametersFile"" does not exist."
    exit
}
Write-Host ""

# deploy start
# update my mobile ip address
$request = Invoke-WebRequest https://www.cman.jp/network/support/go_access.cgi
foreach( $line in $request.Content -split "`n" ){
    if ($line.Contains("keyHostName=")){
        $nowip = $line -split "'"
    }
}
$Secret = ConvertTo-SecureString -String $nowip[1] -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $azKeyVaultName -Name mymobileip -SecretValue $Secret | Out-File -Append $logfile

# create resource group
try {
    $rgstate = Get-AzResourceGroup -Name $resourceGroupName
    if ($rgstate.ProvisioningState -eq "Succeeded") {
    } else {
        Write-Host "Resource Group Exists. But State is not Succeeded."
        exit
    }
}
catch {
    New-AzResourceGroup `
        -Name $resourceGroupName `
        -location $location `
        -Tag @{Owner=$ownerName; Service=$serviceName; Env=$environmentName} | `
        Out-File -Append $logfile
}

# gain permission to test
Write-Host "Test the template ""$templateFile"" ?"
$YesNo = Read-Host "yes or no "
while (($YesNo -ne "yes") -And ($YesNo -ne "no")) {
    $YesNo = Read-Host "yes or no "
}
Write-Host ""

# test template
if ($YesNo -eq "yes") {
    New-AzResourceGroupDeployment `
        -Name "$serviceName-$environmentName-$Datetime" `
        -ResourceGroupName $resourceGroupName `
        -WhatIf `
        -TemplateFile $templateFile `
        -TemplateParameterFile $prametersFile
} elseif ($YesNo -eq "no") {
    Write-Host "Skip test the template ""$templateFile""."
    Write-Host "End."
    Write-Host ""
    exit
}

# gain permission to deploy
Write-Host "Deploy the template ""$templateFile"" ?"
$YesNo = Read-Host "yes or no "
while (($YesNo -ne "yes") -And ($YesNo -ne "no")) {
    $YesNo = Read-Host "yes or no "
}
Write-Host ""

# deploy start
if ($YesNo -eq "yes") {
    New-AzResourceGroupDeployment `
        -Name "$serviceName-$environmentName-$Datetime" `
        -ResourceGroupName $resourceGroupName `
        -Mode Incremental `
        -Force `
        -TemplateFile $templateFile `
        -TemplateParameterFile $prametersFile | `
        Out-File -Append $logfile

    # get deployment operetion
    #Get-AzResourceGroupDeploymentOperation `
    #    -ResourceGroupName $resourceGroupName `
    #    -DeploymentName "$serviceName-$environmentName-$Datetime" | `
    #    Out-File -Append $logfile

    Write-Host ""
} elseif ($YesNo -eq "no") {
    Write-Host "Skip deploy the template ""$templateFile""."
}
