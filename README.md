## Azure Infrastructure as Code
PowerShell スクリプト「deployment.ps1」により Azure resource をデプロイします。

### 01. インストール
以下のコマンドで Mac に PowerShell をインストールできます。
```
$ brew install openssl
$ brew install curl
$ brew install --cask powershell
$ brew upgrade powershell --cask
```

### 02. レポジトリ "PSGallery" の登録
レポジトリを登録します。
```
PS > Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
PS > Get-PSRepository

Name                      InstallationPolicy   SourceLocation
----                      ------------------   --------------
PSGallery                 Untrusted            https://www.powershellgallery.com/api/v2
```

### 03. Az Module をインストール
Azure を操作するための Module をインストールします。
```
PS > Install-Module -Name Az -Scope CurrentUser
```

### 04. ログイン
Azure にログインします。
```
PS > Connect-AzAccount
```

### 05. サービス名を定義
全てのリソース名を決定する環境変数を定義します。<br>
「deployment.ps1」の以下の項目を編集してください。
```
[deployment.ps1]
$ownerName         = "atsushi.koizumi"
```

この "$ownerName" は、リソースグループ名の prefix となり、各種リソースの Owner タグの値となります。

### 06. デプロイ前の確認事項
デプロイ前に下記のネーミングルールを確認ください。
| serviceName | Environment | resouceGroupName |
| ----------- | ----------- | ---------------- |
| psg | dev | $ownerName.psg.dev |
| psg | stg | $ownerName.psg.stg |
| psg | prd | $ownerName.psg.prd |
| sql | dev | $ownerName.sql.dev |
| sql | stg | $ownerName.sql.stg |
| sql | prd | $ownerName.sql.prd |

併せて、serviceName のディレクトリ配下にテンプレートとその概要を説明した README がありますので参照ください。
| serviceName | detail |
| ----------- | ------ |
| psg         | CentOS8, PostgreSQL11, StorageAccount,...etc |
| sql         | WindowsServer2019, SQLVm,SQL Database, StorageAccount,...etc |

### 07. デプロイ用スクリプト実行
下記のスクリプトを実行してデプロイすることができます。
```
PS> .¥deployment.ps1

[1] 最初に Service と Environment を選択します。
Service    : sql psg      select: psg
Environment: dev stg prd  select: dev

# 上記で選択した内容に応じてテンプレートファイルとパラメータファイルが選択されます。
# 対象のファイルが存在しない場合、スクリプトは終了します。
Template File: /Users/atsushi/github/azure_arm_v1\psg\azuredeploy.json
Parameter File: /Users/atsushi/github/azure_arm_v1\psg\dev.parameters.json

[2] テンプレートのテストを実施します。no を選択するとスクリプトは終了します。
Test the template "/Users/atsushi/github/azure_arm_v1\psg\azuredeploy.json" ? 
yes or no :yes

...
...
...

Resource changes: 2 to create, 11 to modify, 10 no change, 1 to ignore.

[3] テンプレートのテスト結果が問題なければ、デプロイを実行します。
Deploy the template "/Users/atsushi/github/azure_arm_v1\psg\azuredeploy.json" ?
yes or no : yes
```

### 08. デプロイ結果の確認
デプロイスクリプト実行後にログファイル「deployment.log」が生成されていますので、結果を確認ください。

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