# クイックスタートガイド

5分でIBM Verifyをデプロイし、ホスト名を`.env`ファイルに自動的に書き込みます。

**重要:** IBM Verifyは`eu-de`（フランクフルト）リージョンでのみ利用可能です。

## 1. IBM Cloud APIキーの取得

1. https://cloud.ibm.com/iam/apikeys にアクセスします
2. 「IBM Cloud APIキーの作成」をクリックします
3. 名前を付けます（例：「terraform-verify」）
4. APIキーをコピーします（二度と表示されません！）

## 2. Terraformの設定

```bash
# サンプル設定をコピー
cp terraform.tfvars.example terraform.tfvars

# ファイルを編集して必須値を追加
# Windowsの場合: notepad terraform.tfvars
# Mac/Linuxの場合: nano terraform.tfvars
```

**必須値（4つ）:**
```hcl
ibmcloud_api_key = "your-api-key"
resource_group   = "Default"           # またはリソースグループ名
instance_name    = "my-verify-instance"
hostname         = "mycompany"         # https://mycompany.verify.ibm.com を作成
```

**オプション値（デフォルト値あり）:**
- `prefix` - 新しいリソースグループのプレフィックス（`resource_group = null`の場合）
- `region` - デフォルトは `eu-de`（唯一サポートされているリージョン）
- `resource_tags` - リソース整理用のタグ
- `access_tags` - 細かいアクセス制御用のアクセスタグ

## 3. デプロイ

### Windows（PowerShell）
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\update_env.ps1
```

### Mac/Linux
```bash
chmod +x scripts/update_env.sh
./scripts/update_env.sh
```

## 4. 認証情報の使用

`.env`ファイルにIBM Verifyの認証情報が含まれるようになりました：
- ホスト名
- OAuth URL
- 管理URL
- クライアントIDとシークレット
- テナントID

これらをアプリケーションで読み込むことができます！

## 次のステップ

### ダッシュボードにアクセス

ダッシュボードURL（出力に表示）を開きます：
```
https://<your-hostname>.verify.ibm.com/ui/admin/
```

### REST API自動化を有効化（オプション）

REST APIを使用するには：
1. APIアクセスページにアクセス（URLは`.env`ファイルの`IBM_VERIFY_API_ACCESS_URL`）
2. APIクライアントを作成して認証情報を保存
3. 認証情報を`.env`ファイルに追加


### 詳細情報

- [README.ja.md](README.ja.md) - 完全なドキュメント
- [IBM Verify ドキュメント](https://www.ibm.com/docs/en/security-verify) - 公式ドキュメント
- `terraform output` を実行してすべての利用可能な値を確認

## クリーンアップが必要ですか？

### Windows
```powershell
.\scripts\destroy.ps1
```

### Mac/Linux
```bash
./scripts/destroy.sh
```

---

**注意:** `terraform.tfvars`と`.env`ファイルは安全に保管してください。バージョン管理にコミットしないでください！

## よくある質問

### Q: なぜeu-deリージョンだけなのですか？

A: IBM Verifyサービスは現在フランクフルト（eu-de）リージョンでのみ提供されています。

### Q: 無料で使えますか？

A: はい！「lite」プランは無料で利用でき、開発やテスト目的に最適です。本番環境での使用には「graduated-tier」プランをご検討ください。

### Q: .envファイルはどのように使用しますか？

A: アプリケーションで環境変数として読み込むことができます：

**Node.js (dotenv使用):**
```javascript
require('dotenv').config();
const hostname = process.env.IBM_VERIFY_HOSTNAME;
```

**Python (python-dotenv使用):**
```python
from dotenv import load_dotenv
import os

load_dotenv()
hostname = os.getenv('IBM_VERIFY_HOSTNAME')
```

**Java (Spring Boot):**
```java
@Value("${IBM_VERIFY_HOSTNAME}")
private String hostname;
```

### Q: 既存のIBM Verifyインスタンスをインポートできますか？

A: はい、Terraformの`import`コマンドを使用できます：
```bash
terraform import ibm_resource_instance.verify_instance <instance-id>
```

### Q: 複数のインスタンスを作成できますか？

A: はい、`service_name`変数を変更するか、Terraformワークスペースを使用して複数のインスタンスを管理できます。

## トラブルシューティング

### エラー: 「Unauthorized」

- APIキーが正しいことを確認してください
- APIキーに「Manager」または「Administrator」の役割があることを確認してください

### エラー: 「Resource group not found」

- IBM Cloudコンソールでリソースグループ名を確認してください
- 正しい名前を`terraform.tfvars`に設定してください

### エラー: 「Service not available in region」

- `region = "eu-de"`が設定されていることを確認してください
- 組み込みの検証により、このエラーは早期に検出されるはずです

## サポート

問題が解決しない場合：
1. IBM Cloudのステータスページを確認: https://cloud.ibm.com/status
2. Terraformのログを確認: `TF_LOG=DEBUG terraform apply`
3. IBM Cloudサポートに問い合わせ: https://cloud.ibm.com/unifiedsupport/supportcenter

---

**準備完了です！** 🚀 IBM Verifyを使った開発をお楽しみください！

