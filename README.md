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

以上です。