# IBM Verify Terraform デプロイメント

## IBM Verifyについて

[IBM Verify](https://www.ibm.com/products/verify)は、クラウドネイティブのアイデンティティおよびアクセス管理（IAM）ソリューションで、以下を提供します：

- **シングルサインオン（SSO）** - アプリケーション間の統一されたアクセス
- **多要素認証（MFA）** - SMS、TOTP、生体認証による強化されたセキュリティ
- **パスワードレス認証** - FIDO2 WebAuthnサポート
- **適応型アクセス** - AI駆動のリスクベース認証
- **ユーザーライフサイクル管理** - 自動化されたオンボーディングとアクセス制御
- **REST API** - 自動化と統合のためのプログラマティックアクセス

## このTerraform設定について

このリポジトリは、IBM VerifyのIBM Cloudへのデプロイを自動化するインフラストラクチャアズコードを提供します。Terraformを使用することで、手動セットアップが不要になり、以下を実現します：

- **自動プロビジョニング** - 単一のコマンドでIBM Verifyインスタンスをデプロイ
- **一貫性のある設定** - 環境全体で再現可能なデプロイメント
- **インフラストラクチャアズコード** - バージョン管理されたインフラストラクチャ
- **自動認証情報管理** - サービス認証情報と.envファイルの生成
- **リソースグループ統合** - 簡素化されたリソース組織化
- **ホスト名自動化** - ダッシュボードURLの自動設定

**使用する公式IBMモジュール:**
- [terraform-ibm-modules/security-verify/ibm](https://registry.terraform.io/modules/terraform-ibm-modules/security-verify/ibm/latest) v1.1.1
- [terraform-ibm-modules/resource-group/ibm](https://registry.terraform.io/modules/terraform-ibm-modules/resource-group/ibm/latest) v1.1.6

## 前提条件

始める前に、以下をご用意ください：

1. **Terraform** がインストールされていること（バージョン1.0以上）
   - ダウンロード: https://www.terraform.io/downloads

2. **IBM Cloudアカウント**
   - サインアップ: https://cloud.ibm.com/registration

3. **IBM Cloud APIキー**
   - 作成: https://cloud.ibm.com/iam/apikeys
   - このキーを安全に保管し、バージョン管理にコミットしないでください

## アーキテクチャ概要

```mermaid
graph TB
    subgraph "ローカル環境"
        User[ユーザー]
        TFVars[terraform.tfvars<br/>設定変数]
        Scripts[デプロイメントスクリプト<br/>update_env.sh/ps1]
        EnvFile[.envファイル<br/>生成された認証情報]
        
        subgraph "Terraform設定"
            Providers[providers.tf<br/>IBM Cloudプロバイダー]
            Variables[variables.tf<br/>入力変数]
            Main[main.tf<br/>モジュール定義]
            Outputs[outputs.tf<br/>出力値]
            Template[templates/env.tpl<br/>環境変数テンプレート]
        end
    end
    
    subgraph "IBM Cloud - eu-deリージョン"
        IAM[IBM Cloud IAM<br/>認証]
        
        subgraph "リソースグループモジュール"
            RGModule[リソースグループモジュール<br/>名前からIDへ変換]
        end
        
        subgraph "IBM Verifyサービス"
            ISVModule[Verifyモジュール<br/>インスタンス作成]
            VerifyInstance[IBM Verifyインスタンス]
            Credentials[サービス認証情報<br/>Administrator権限]
            AccessTags[アクセスタグ]
        end
    end
    
    User -->|1. 設定| TFVars
    User -->|2. 実行| Scripts
    Scripts -->|3. 初期化| Providers
    
    Providers -->|4. 認証| IAM
    
    Main -->|5. グループ解決| RGModule
    RGModule -->|6. IDを提供| ISVModule
    
    ISVModule -->|7. 作成| VerifyInstance
    ISVModule -->|8. 適用| AccessTags
    
    Main -->|9. 生成| Credentials
    Credentials -->|10. データ抽出| Template
    Template -->|11. 書き込み| EnvFile
    
    Outputs -->|12. 表示| User
    
    EnvFile -.->|13. アプリで読み込み| User
    
    Variables --> Main
    TFVars --> Variables
```

## プロジェクト構成

```
.
├── providers.tf              # プロバイダー設定
├── variables.tf              # 変数定義
├── main.tf                   # メインのTerraform設定
├── outputs.tf                # 出力定義
├── templates/
│   └── env.tpl              # .envファイルのテンプレート
├── scripts/
│   ├── update_env.sh        # デプロイメントスクリプト（Linux/Mac）
│   ├── update_env.ps1       # デプロイメントスクリプト（Windows）
│   ├── destroy.sh           # 削除スクリプト（Linux/Mac）
│   └── destroy.ps1          # 削除スクリプト（Windows）
├── terraform.tfvars.example # 変数ファイルの例
├── .gitignore              # Gitの除外ルール
├── README.md               # 英語版README
└── README.ja.md            # 日本語版README（このファイル）
```

### コンポーネントのワークフロー

1. **ユーザー設定**: `terraform.tfvars`に必要なパラメータを設定
2. **スクリプト実行**: デプロイメントスクリプトを実行してTerraformを操作
3. **プロバイダー初期化**: TerraformがIBM Cloudプロバイダーを初期化
4. **認証**: プロバイダーがIBM Cloud IAMで認証
5. **リソースグループ解決**: モジュールがリソースグループ名をIDに変換
6. **モジュールプロビジョニング**: VerifyモジュールがリソースグループIDを受け取る
7. **インスタンス作成**: eu-deリージョンにIBM Verifyインスタンスを作成
8. **アクセスタグ適用**: インスタンスにアクセスタグを適用
9. **認証情報生成**: Administratorロールでサービス認証情報を生成
10. **データ抽出**: ホスト名、URL、認証情報を抽出
11. **環境ファイル生成**: すべての設定で`.env`ファイルを書き込み
12. **出力表示**: デプロイメント結果をユーザーに表示
13. **アプリケーション統合**: アプリケーションで`.env`の認証情報を読み込み

## セットアップ手順

### ステップ1: 変数の設定

1. 例の変数ファイルをコピーします：
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. `terraform.tfvars`を編集して必須パラメータを設定します：
   ```hcl
   # 必須パラメータ
   ibmcloud_api_key = "your-ibm-cloud-api-key"
   resource_group   = "Default"  # またはリソースグループ名
   instance_name    = "my-verify-instance"
   hostname         = "mycompany"  # Verifyサブドメイン
   
   # オプションパラメータ
   # prefix = "verify"         # 新しいリソースグループ作成時に使用
   # region = "eu-de"          # デフォルト、IBM Verifyはeu-deのみ利用可能
   # resource_tags = ["env:dev", "project:myapp"]
   # access_tags = ["env:dev"]
   ```
   
   **注意:** `hostname`はダッシュボードURLの構築に使用されます：`https://<hostname>.verify.ibm.com/ui/admin/`

3. リソースグループ名を取得します（既存のものを使用する場合）：
   ```bash
   # 利用可能なリソースグループを一覧表示
   ibmcloud resource groups
   ```
   
   または`resource_group = null`に設定して自動的に新しいものを作成できます！

### ステップ2: IBM Verifyインスタンスのデプロイ

#### オプションA: デプロイメントスクリプトの使用（推奨）

**Linux/Mac:**
```bash
chmod +x scripts/update_env.sh
./scripts/update_env.sh
```

**Windows（PowerShell）:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\update_env.ps1
```

#### オプションB: 手動でTerraformコマンドを実行

1. Terraformを初期化します：
   ```bash
   terraform init
   ```

2. デプロイメントを計画します：
   ```bash
   terraform plan
   ```

3. 設定を適用します：
   ```bash
   terraform apply
   ```

### ステップ3: .envファイルの確認

デプロイメントが成功したら、プロジェクトルートの`.env`ファイルを確認してください。以下の内容が含まれているはずです：

```env
IBM_VERIFY_HOSTNAME=mycompany.verify.ibm.com
IBM_VERIFY_DASHBOARD_URL=https://mycompany.verify.ibm.com/ui/admin/
IBM_VERIFY_ACCOUNT_URL=https://mycompany.verify.ibm.com
IBM_VERIFY_INSTANCE_ID=<instance-guid>
```

### ステップ4: REST APIアクセスを有効化（オプション）

REST API自動化のために、管理コンソールでAPIクライアントを作成します：

1. `https://<hostname>.verify.ibm.com/ui/admin/security/api-access` にアクセス
2. 必要な権限で新しいAPIクライアントを作成
3. クライアントIDとクライアントシークレットを保存
4. 認証情報を `.env` ファイルに追加


## 使用方法

### 出力の表示

すべての出力を表示するには：
```bash
terraform output
```

特定の出力を表示するには：
```bash
terraform output verify_hostname
```

機密性の高い出力を表示するには：
```bash
terraform output verify_tenant_id
```

### 設定の更新

1. `terraform.tfvars`の変数を変更します
2. `terraform apply`を実行してインフラストラクチャを更新します

### インフラストラクチャの削除

IBM Verifyインスタンスが不要になった場合：

**Linux/Mac:**
```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh
```

**Windows（PowerShell）:**
```powershell
.\scripts\destroy.ps1
```

または手動で：
```bash
terraform destroy
```

## 利用可能な変数

> 📋 **詳細なパラメータドキュメント、例、トラブルシューティングは [PARAMETERS.md](PARAMETERS.md) を参照してください**（英語）

| 変数 | 説明 | デフォルト | 必須 |
|----------|-------------|---------|----------|
| `ibmcloud_api_key` | IBM Cloud APIキー | - | ✅ はい |
| `resource_group` | リソースグループ名（nullで新規作成） | null | ✅ はい |
| `instance_name` | IBM Verifyインスタンス名 | - | ✅ はい |
| `hostname` | ダッシュボードURL用ホスト名（`<hostname>.verify.ibm.com`） | - | ✅ はい |
| `prefix` | 新規リソースグループ作成時のプレフィックス | verify | いいえ |
| `region` | IBM Cloudリージョン（eu-deのみ） | eu-de | いいえ |
| `resource_tags` | リソースタグ | [] | いいえ |
| `access_tags` | アクセス制御用アクセスタグ | [] | いいえ |
| `env_file_path` | .envファイルへのパス | .env | いいえ |

## 重要: リージョンの利用可能性

**IBM Verifyは`eu-de`（フランクフルト）リージョンでのみ利用可能です。**

IBM Verifyは具体的に以下のリージョンへのデプロイが必要です：
- `eu-de` - フランクフルト、ドイツ

他のリージョンへのデプロイを試みると、デプロイメントは失敗します。

## サービスプラン

サービスプランはIBM Verifyモジュールによって`verify-lite`に設定されます。これは現在IBM Verifyで利用可能な唯一のプランです。

## 出力

デプロイ後、以下の出力が利用可能です：

- `verify_instance_id`: IBM Verifyインスタンスのリソースフル ID
- `verify_instance_guid`: IBM VerifyインスタンスのGUID
- `verify_hostname`: IBM Verifyインスタンスのホスト名
- `verify_dashboard_url`: ダッシュボードURL
- `verify_tenant_id`: テナントID（機密情報）
- `verify_oauth_url`: OAuthサーバーURL
- `verify_management_url`: 管理API URL

## トラブルシューティング

### 認証エラー

認証エラーが発生した場合：
1. APIキーが正しいことを確認してください
2. APIキーに必要な権限があることを確認してください
3. アカウントが指定されたリージョンにアクセスできることを確認してください

### リソースグループが見つからない

指定されたリソースグループが存在しない場合：
1. リソースグループを一覧表示します：`ibmcloud resource groups`
2. `terraform.tfvars`の`resource_group`を更新します
3. またはIBM Cloudで新しいリソースグループを作成します


## 環境ファイルの生成

Terraform設定は、アプリケーションに必要なすべての設定を含む`.env`ファイルを自動的に生成します：

```env
IBM_VERIFY_HOSTNAME=mycompany.verify.ibm.com
IBM_VERIFY_DASHBOARD_URL=https://mycompany.verify.ibm.com/ui/admin/
IBM_VERIFY_ACCOUNT_URL=https://mycompany.verify.ibm.com
IBM_VERIFY_API_ACCESS_URL=https://mycompany.verify.ibm.com/ui/admin/security/api-access
IBM_VERIFY_INSTANCE_ID=761a3384-06b8-4cde-ac4d-91bd0d535f7c
```

ファイルには、APIクライアント認証情報用のプレースホルダーコメントが含まれています（コンソールでAPIクライアントを作成後に追加）。`.env`ファイルは`terraform apply`を実行するたびに再生成されます。

## その他のリソース

### ドキュメント
- [IBM Cloud Terraformプロバイダー ドキュメント](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [IBM Verify ドキュメント](https://www.ibm.com/docs/en/security-verify)
- [IBM Verify APIリファレンス](https://www.ibm.com/docs/en/security-verify?topic=apis-overview)
- [Terraform ドキュメント](https://www.terraform.io/docs)
- [IBM Cloud CLI](https://cloud.ibm.com/docs/cli)

### プロジェクトガイド
- [QUICKSTART.ja.md](QUICKSTART.ja.md) - 5分デプロイメントガイド
- [GETTING_STARTED.md](GETTING_STARTED.md) - 詳細なウォークスルー（英語）
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - プロジェクト概要（英語）

## クイックスタート

より簡単な手順については、[QUICKSTART.md](QUICKSTART.md)をご覧ください（英語）。

