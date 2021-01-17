# version 1.0.0

<#
.SYNOPSIS
ARM Template �� Deploy ����ɂ������āA�{�X�N���v�g�����s���܂��B

.DESCRIPTION
�ȉ��̏��ŏ��������s����܂��B
1. ���\�[�X�O���[�v�̍쐬
2. $TemplateList�ɋL�q�����e���v���[�g�ɑ΂��ď������{�i�X�L�b�v�j
  2-1. �e���v���[�g�̃e�X�g
  2-2. �e���v���[�g�̃f�v���C
3. �f�v���C���ʂ����O�ɕۑ�

.PARAMETER
�f�v���C�ΏۂƂȂ�̂� $TemplateList �ɋL�q�����e���v���[�g�݂̂ł��B
�p�����[�^�t�@�C���� $PrametersFile �ŌŒ�ł��B
#>

# Environments
$Location         = "eastus"
$ResouceGroupName = "atsushi.koizumi"
$TemplateList     = ("network","virtualmachine")  # �z��
$PrametersFile    = "dev.parameters.json"
$Logfile          = "mydeployments.log"

# error handling
$ErrorActionPreference = "Stop"


################
# Script Start #
################

# get datetime
$Datetime = Get-date -format "yyyyMMddHHmmss"

# deploy
foreach ($item in $TemplateList) {
    
    # create resource group
    try {
        $rgstate = Get-AzResourceGroup -Name "$ResouceGroupName.$item"
        if ($rgstate.ProvisioningState -eq "Succeeded") {
            Write-Output "Resource Group Exists. Start ARM Templete Deploy."
        } else {
            Write-Output "Resource Group Exists. But State is not Succeeded."
        }
    }
    catch {
        New-AzResourceGroup `
            -Name "$ResouceGroupName.$item" `
            -Location $Location `
            -Tag @{Owner=$OwnerName; Service=$ServiceName; Env=$EnvName} `
            | Out-File -Append $Logfile
    }

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
                -ResourceGroupName "$ResouceGroupName.$item" `
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
                -ResourceGroupName "$ResouceGroupName.$item" `
                -Mode Incremental `
                -TemplateFile "$item.json" `
                -TemplateParameterFile $PrametersFile `
            | Out-File -Append $Logfile
        } elseif ($YesNo -eq "no") {
            Write-Host "Skip ""$item.json"""
        }
        Write-Host ""

    } else {
        Write-Host "[Warning] ""$PSScriptRoot\$item"" does not exist."
    }
}