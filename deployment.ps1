# version 1.1.2

<#
.SYNOPSIS
ARM Template を Deploy するにあたって、本スクリプトを実行します。

.DESCRIPTION
以下の順で処理が実行されます。
1. リソースグループの作成
2. $TemplateListに記述したテンプレートに対して順次実施（スキップ可）
  2-1. テンプレートのテスト
  2-2. テンプレートのデプロイ
3. デプロイ結果をログに保存

.PARAMETER
デプロイ対象となるのは $TemplateList に記述したテンプレートのみです。
パラメータファイルは $PrametersFile で固定です。
#>

# Environments
$Location         = "eastus"
$ResouceGroupName = "atsushi.koizumi"
$TemplateList     = ("network","virtualmachine")  # 配列
$EnvCode          = "dev"   # --> $EnvCode.parametrs.json
$Logfile          = "deployment.log"

# error handling
$ErrorActionPreference = "Stop"


################
# Script Start #
################

# get datetime
$Datetime = Get-date -format "yyyyMMddHHmmss"

# check parameters.json
$PrametersFile    = "$EnvCode.parameters.json"
if (Test-Path -Path $PrametersFile ) {
    Write-Host "Parameter File: $EnvCode.parameters.json"
} else {
    Write-Host """Parameter File: $EnvCode.parameters.json"" does not exist." -ForegroundColor white -BackgroundColor Red
}

# deploy
$CurrentFiles = Get-ChildItem $PSScriptRoot -Name
foreach ($item in $TemplateList) {
    
    # create resource group
    try {
        $rgstate = Get-AzResourceGroup -Name "$ResouceGroupName.$item.$EnvCode"
        if ($rgstate.ProvisioningState -eq "Succeeded") {
            Write-Output "Resource Group Exists. Start ARM Templete Deploy."
        } else {
            Write-Output "Resource Group Exists. But State is not Succeeded."
        }
    }
    catch {
        New-AzResourceGroup `
            -Name "$ResouceGroupName.$item.$EnvCode" `
            -Location $Location `
            | Out-File -Append $Logfile
    }

    # filecheck
    if($CurrentFiles -ccontains "$item.json") {

        # gain permission to test
        Write-Host "Test the templete ""$item.json"" ?"
        $YesNo = Read-Host "yes or no "
        while (($YesNo -ne "yes") -And ($YesNo -ne "no")) {
            $YesNo = Read-Host "yes or no "
        }
        Write-Host ""

        # test templete
        if ($YesNo -eq "yes") {
            New-AzResourceGroupDeployment `
                -Name "$item-$Datetime" `
                -ResourceGroupName "$ResouceGroupName.$item.$EnvCode" `
                -WhatIf `
                -TemplateFile "$item.json" `
                -TemplateParameterFile $PrametersFile
        } elseif ($YesNo -eq "no") {
            Write-Host "Skip ""$item.json"""
            Continue
        }

        # gain permission to deploy
        Write-Host "Deploy the templete ""$item.json"" ?"
        $YesNo = Read-Host "yes or no "
        while (($YesNo -ne "yes") -And ($YesNo -ne "no")) {
            $YesNo = Read-Host "yes or no "
        }
        Write-Host ""

        # deeploy start
        if ($YesNo -eq "yes") {
            New-AzResourceGroupDeployment `
                -Name "$item-$Datetime" `
                -ResourceGroupName "$ResouceGroupName.$item.$EnvCode" `
                -Mode Complete `
                -Force `
                -TemplateFile "$item.json" `
                -TemplateParameterFile $PrametersFile `
            | Out-File -Append $Logfile
        } elseif ($YesNo -eq "no") {
            Write-Host "Skip ""$item.json"""
        }
        Write-Host ""

        # get deployment operation
        <#
        try {
            Get-AzResourceGroupDeploymentOperation `
            -ResourceGroupName "$ResouceGroupName.$item.$EnvCode" `
            -DeploymentName "$item-$Datetime" `
            | Format-List -Property StatusCode,ProvisioningState,TargetResource
            | Out-File -Append $Logfile           
        }
        catch {
            Write-Host ""
        }
        #>
    
    } else {
        Write-Host "[Warning] ""$PSScriptRoot\$item.json"" does not exist."
    }
}
