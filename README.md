# Azure Infrastructure as Code
ARM Templete を使った Azure resource の deploy 方法を確認します。


# 01. install powershell for mac
以下のコマンドで Mac に PowerShell をインストールできます。
```
$ brew install openssl
$ brew install curl
$ brew install --cask powershell
$ brew upgrade powershell --cask
```

# 02. Set PSRepository
レポジトリを登録します。
```
PS > Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
PS > Get-PSRepository

Name                      InstallationPolicy   SourceLocation
----                      ------------------   --------------
PSGallery                 Untrusted            https://www.powershellgallery.com/api/v2
```

# 03. Install Az Modules
Azure を操作するための Module をインストールします。
```
PS > Install-Module -Name Az -Scope CurrentUser
```

# 04. login
Azure にログインします。
```
PS > Connect-AzAccount
```

# 05. Create Resource Group
テスト用のリソースグループを作成します。
```
PS > New-AzResourceGroup -Name sample-rg01 -Location "East US"
```

# 05. Test ARM Templete
作成したテンプレートをテストします。
```
PS > New-AzResourceGroupDeploymentWhatIfResult `
  -Name ExampleDeployment `
  -ResourceGroupName sample-rg01 `
  -TemplateFile sample.json
```

# 06. ARM Templete Deploy
テンプレートをデプロイします。
```
PS > New-AzResourceGroupDeployment `
  -Name ExampleDeployment `
  -ResourceGroupName sample-rg01 `
  -TemplateFile sample.json
```

# 07. Get-AzResourceGroupDeployment
デプロイ履歴を確認します。
```
PS > Get-AzResourceGroupDeployment `
  -ResourceGroupName sample-rg01 
```

# 08. Get-AzResourceGroupDeploymentOperation
デプロイ履歴の詳細を確認します。
```
Get-AzResourceGroupDeploymentOperation `
  -ResourceGroupName sample-rg01 `
  -DeploymentName ExampleDeployment-2
```

# 09. allow data access priv to vm01 for storage account "armtemplatedrive"
vm01 に対して armtemplatedrive への "Storage Blob Data Contributor" 権限を付与します。
```
$rgname = ”atsushi.koizumi.sql.dev”
$vmname = ”sql-dev-vm01”
$vmInfo = Get-AzVM -ResourceGroupName $rgname -Name $vmname
$strage = Get-AzStorageAccount -ResourceGroupName "atsushi.koizumi.data" -StorageAccountName "armtemplatedrive"
New-AzRoleAssignment `
  -ObjectId $vmInfo.Identity.PrincipalId `
  -Scope $strage.id `
  -RoleDefinitionName "Storage Blob Data Contributor"
```

# 10. get exe-items from "armtemplatedrive" in vm01
vm01 にログインして PowerShell で以下のコマンドを実行します。
```
Install-Module -Name Az -Scope CurrentUser
Add-AzAccount -identity
$contxt = New-AzStorageContext -StorageAccountName "armtemplatedrive"
$contxt | Get-AzStorageBlob -Container "windows" | `
ForEach-Object {$contxt | Get-AzStorageBlobContent -Blob $_.Name -Container "windows" -Destination "L:\work\"}
```

以上です。