# version 1.0.0

<#
.SYNOPSIS
ARM Template を Deploy するにあたって、本スクリプトを実行します。

.DESCRIPTION
以下の順で処理が実行されます。
  1. リソースグループの作成
  2. $TemplateListに記述したテンプレートに対して順次実施（スキップ可）
    2-1. テンプレートのテスト
    2-2. テンプレートのデプロイ

.PARAMETER
  デプロイ対象となるのは $TemplateList に記述したテンプレートのみです。
  パラメータファイルは $PrametersFile で固定です。
#>

# Environments
$ResouceGroupName = "atsushi.koizumi.arm"
$location         = "eastus"
$Owner_tag        = "atsushi.koizumi"
$Env_tag          = "arm.templete"
$TemplateList     = ("network","virtualmachine")  # 配列
$PrametersFile    = "arm.parameters.json"

# error handling
$ErrorActionPreference = "Stop"


################
# Script Start #
################


# create resource group
try {
    $rgstate = Get-AzResourceGroup -Name $ResouceGroupName
    if ($rgstate.ProvisioningState -eq "Succeeded") {
        Write-Output "Resource Group Exists. Start ARM Templete Deploy."
    } else {
        Write-Output "Resource Group Exists. But State is not Succeeded."
    }
}
catch {
    New-AzResourceGroup `
        -Name $ResouceGroupName `
        -Location $location `
        -Tag @{Owner=$Owner_tag; Env=$Env_tag}
}

# get datetime
$Datetime = Get-date -format "yyyyMMddHHmmss"

# deploy
foreach ($item in $TemplateList) {
    
    $CurrentFiles = Get-ChildItem $PSScriptRoot -Name
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
                -ResourceGroupName $ResouceGroupName `
                -WhatIf `
                -TemplateFile "$item.json" `
                -TemplateParameterFile $PrametersFile
        } elseif ($YesNo -eq "no") {
            Write-Host "Skip ""$item.json"""
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
                -ResourceGroupName $ResouceGroupName `
                -Mode Incremental `
                -TemplateFile "$item.json" `
                -TemplateParameterFile $PrametersFile
        } elseif ($YesNo -eq "no") {
            Write-Host "Skip ""$item.json"""
        }
        Write-Host ""

    } else {
        Write-Host "[Warning] ""$PSScriptRoot\$item"" does not exist."
    }
}
