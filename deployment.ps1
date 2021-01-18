# version 2.0.0

<#
.SYNOPSIS
ARM Template �� Deploy ����ɂ������āA�{�X�N���v�g�����s���܂��B

.DESCRIPTION
�ȉ��̏��ŏ��������s����܂��B
1. ���\�[�X�O���[�v�̍쐬
2. $templateList�ɋL�q�����e���v���[�g�ɑ΂��ď������{�i�X�L�b�v�j
  2-1. �e���v���[�g�̃e�X�g
  2-2. �e���v���[�g�̃f�v���C
3. �f�v���C���ʂ����O�ɕۑ�

.OPERATION
�ȉ��̕��j�ŉ^�p���܂��B
1. �P���F�P�e���v���[�g�t�@�C��
2. ���\�[�X�O���[�v���� $ownerName.$serviceName.$environmentName
3. �^�O��t�^ Owner=$ownerName,Service=$serviceName,Env=$environmentName
4. �f�v���C���[�h�� Complete

#>

# Environments
$location          = "eastus"
$ownerName         = "atsushi.koizumi"
$serviceName       = Read-Host "dba"  # �I�����������T�[�r�X�����L��
$environmentName   = Read-Host "dev/stg/prd"  # �I�����������������L��
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
        -Mode Complete `
        -Force `
        -TemplateFile $templateFile `
        -TemplateParameterFile $prametersFile | `
        Out-File -Append $logfile

    # get deployment operetion
    Get-AzResourceGroupDeploymentOperation `
        -ResourceGroupName $resourceGroupName `
        -DeploymentName "$serviceName-$environmentName-$Datetime" | `
        Out-File -Append $logfile

    Write-Host ""
} elseif ($YesNo -eq "no") {
    Write-Host "Skip deploy the template ""$templateFile""."
}
