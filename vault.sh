#!/bin/bash

# 設定対象のバージョン
VAULT_VERSION="9.6"

# リポジトリファイルのディレクトリ
REPO_DIR="/etc/yum.repos.d"
BACKUP_DIR="${REPO_DIR}/backup_$(date +%Y%m%d_%H%M%S)"

echo "=== AlmaLinux リポジトリ Vault ($VAULT_VERSION) 切り替えスクリプト ==="

# 1. バックアップの作成
echo "1. 現在のリポジトリ設定をバックアップしています: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp "$REPO_DIR"/almalinux-*.repo "$BACKUP_DIR/"

# 2. リポジトリ設定の書き換え
# 対象: BaseOS, AppStream, Extras, CRB (必要であれば)
# メインの .repo ファイルを対象とします
echo "2. リポジトリの参照先を vault.almalinux.org/$VAULT_VERSION に変更しています..."

for file in "$REPO_DIR"/almalinux-{baseos,appstream,extras,crb}.repo; do
    if [ -f "$file" ]; then
        echo "   Processing: $file"
        
        # mirrorlist をコメントアウト
        sed -i 's/^mirrorlist/#mirrorlist/g' "$file"
        
        # baseurl のコメントアウトを解除（もしされていれば）
        sed -i 's/^# baseurl/baseurl/g' "$file"
        
        # baseurl のドメインとパスを Vault 向けに書き換え
        # パターン: repo.almalinux.org/almalinux/$releasever -> vault.almalinux.org/9.6
        # 注意: $releasever が使われている箇所を固定バージョンに置換します
        sed -i "s|repo.almalinux.org/almalinux/\$releasever|vault.almalinux.org/$VAULT_VERSION|g" "$file"
        
        # 一部の環境で $releasever ではなく数字(9)が直書きされている場合の対応
        sed -i "s|repo.almalinux.org/almalinux/9/|vault.almalinux.org/$VAULT_VERSION/|g" "$file"
    fi
done

# 3. キャッシュのクリアと確認
echo "3. DNF キャッシュをクリアしています..."
dnf clean all

echo "=== 完了しました ==="
