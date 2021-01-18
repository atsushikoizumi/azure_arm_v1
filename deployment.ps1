# version 2.0.0

<#
.SYNOPSIS
ARM Template を Deploy するにあたって、本スクリプトを実行します。

.DESCRIPTION
以下の順で処理が実行されます。
1. リソースグループの作成
2. $templateListに記述したテンプレートに対して順次実施（スキップ可）
  2-1. テンプレートのテスト
  2-2. テンプレートのデプロイ
3. デプロイ結果をログに保存

.OPERATION
以下の方針で運用します。
1. １環境：１テンプレートファイル
2. リソースグループ名は $ownerName.$serviceName.$environmentName
3. タグを付与 Owner=$ownerName,Service=$serviceName,Env=$environmentName
4. デプロイモードは Complete

#>

# Environments
$location          = "eastus"
$ownerName         = "atsushi.koizumi"
$serviceName       = Read-Host "dba"  # 選択させたいサービス名を記載
$environmentName   = Read-Host "dev/stg/prd"  # 選択させたい環境名を記載
$templateFile      = "$PSScriptRoot\$serviceName\azuredeploy.json"
$prametersFile     = "$PSScriptRoot\$serviceName\$environmentName.parameters.json"
$logfile           = "deployment.log"
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
# create resource group
try {
    $rgstate = Get-AzResourceGroup -Name "$resourceGroupName"
    if ($rgstate.ProvisioningState -eq "Succeeded") {
    } else {
        Write-Host "Resource Group Exists. But State is not Succeeded."
        exit
    }
}
catch {
    New-AzResourceGroup `
        -Name "$resourceGroupName" `
        -location $location `
        -Tag @{Owner=$ownerName; Service=$serviceName; Env=$environmentName} `
        | Out-File -Append $logfile
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
        -ResourceGroupName "$resourceGroupName" `
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

# deeploy start
if ($YesNo -eq "yes") {
    New-AzResourceGroupDeployment `
        -Name "$serviceName-$environmentName-$Datetime" `
        -ResourceGroupName "$resourceGroupName" `
        -Mode Complete `
        -Force `
        -TemplateFile $templateFile `
        -TemplateParameterFile $prametersFile `
    | Out-File -Append $logfile
    Write-Host ""
} elseif ($YesNo -eq "no") {
    Write-Host "Skip deploy the template ""$templateFile""."
}
