## Azure Infrastructure as Code
ARM Templete を使った Azure resource の deploy 方法を確認します。


### 01. install powershell for mac
以下のコマンドで Mac に PowerShell をインストールできます。
```
$ brew install openssl
$ brew install curl
$ brew install --cask powershell
$ brew upgrade powershell --cask
```

### 02. Set PSRepository
レポジトリを登録します。
```
PS > Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
PS > Get-PSRepository

Name                      InstallationPolicy   SourceLocation
----                      ------------------   --------------
PSGallery                 Untrusted            https://www.powershellgallery.com/api/v2
```

### 03. Install Az Modules
Azure を操作するための Module をインストールします。
```
PS > Install-Module -Name Az -Scope CurrentUser
```

### 04. login
Azure にログインします。
```
PS > Connect-AzAccount
```

### 05. Set ownerName
全てのリソース名を決定する環境変数を定義します。<br>
[deployment.ps1]の以下の項目を編集してください。
```
$ownerName         = "atsushi.koizumi"
```

この "$ownerName" は、リソースグループ名の prefix となり、各種リソースの Owner タグの値となります。

### 06. Before deploy
デプロイ前に下記のネーミングルールを確認ください。
| serviceName | Environment | resouceGroupName |
| ----------- | ----------- | ---------------- |
| psg | dev | $ownerName.psg.dev |
| psg | stg | $ownerName.psg.stg |
| psg | prd | $ownerName.psg.prd |
| sql | dev | $ownerName.sql.dev |
| sql | stg | $ownerName.sql.stg |
| sql | prd | $ownerName.sql.prd |

デプロイ対象のテンプレートの内容を確認してください。<br>
併せて、serviceName のディレクトリ配下にテンプレートとその概要を説明した README がありますので参照ください。
| serviceName | detail |
| ----------- | ------ |
| psg         | CentOS8, PostgreSQL11, StorageAccount,...etc |
| sql         | WindowsServer2019, SQLVm,SQL Database, StorageAccount,...etc |

### 07. Deploy Command
下記のスクリプトを実行してデプロイすることができます。
```
PS> .¥deployment.ps1

Service    : sql psg      select: psg
Environment: dev stg prd  select: dev

Template File: /Users/atsushi/github/azure_arm_v1\psg\azuredeploy.json
Parameter File: /Users/atsushi/github/azure_arm_v1\psg\dev.parameters.json

Test the template "/Users/atsushi/github/azure_arm_v1\psg\azuredeploy.json" ? 
yes or no :yes

...
...
...

Resource changes: 2 to create, 11 to modify, 10 no change, 1 to ignore.

Deploy the template "/Users/atsushi/github/azure_arm_v1\psg\azuredeploy.json" ?
yes or no : yes
```

### 08. Check the deployment result.
デプロイ完了後にログファイル「deployment.log」が生成されていますので、結果を確認ください。

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