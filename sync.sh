#!/bin/bash

# macOS システム設定の同期スクリプト
# save: 現在のmacOS設定をdotfilesに保存
# apply: dotfilesの設定をmacOSに適用

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/settings.conf"

# 管理対象の設定キー
KEYS=(
  "NSGlobalDomain:KeyRepeat"
  "NSGlobalDomain:InitialKeyRepeat"
  "com.apple.dock:autohide"
  "com.apple.dock:tilesize"
  "NSGlobalDomain:com.apple.trackpad.scaling"
)

# Mission Control のショートカットID
MISSION_CONTROL_IDS=(79 80 81 82)

# macOS → dotfilesへ保存
save() {
  echo "現在のmacOS設定を保存中..."
  > "$CONFIG_FILE"

  # defaults 値を保存
  for entry in "${KEYS[@]}"; do
    domain="${entry%%:*}"
    key="${entry#*:}"
    value=$(defaults read "$domain" "$key" 2>/dev/null || echo "__NOT_SET__")
    if [ "$value" != "__NOT_SET__" ]; then
      echo "${domain}:${key}=${value}" >> "$CONFIG_FILE"
      echo "  $domain $key = $value"
    fi
  done

  # Mission Control ショートカットを保存
  echo "" >> "$CONFIG_FILE"
  echo "# Mission Control shortcuts" >> "$CONFIG_FILE"
  for id in "${MISSION_CONTROL_IDS[@]}"; do
    enabled=$(defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null | \
      perl -0777 -ne "print \$1 if /\"?${id}\"?\s*=\s*\{[^}]*enabled\s*=\s*(\d)/s")
    params=$(defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null | \
      perl -0777 -ne "if (/\"?${id}\"?\s*=\s*\{.*?parameters\s*=\s*\(([^)]+)\)/s) { \$p=\$1; \$p=~s/[\s\n]//g; print \$p }")
    if [ -n "$enabled" ] && [ -n "$params" ]; then
      echo "symbolic:${id}:enabled=${enabled}" >> "$CONFIG_FILE"
      echo "symbolic:${id}:params=${params}" >> "$CONFIG_FILE"
      echo "  Mission Control ID $id: enabled=$enabled params=$params"
    fi
  done

  echo ""
  echo "保存完了: $CONFIG_FILE"
  echo ""
  echo "コミットするには:"
  echo "  cd ~/dotfiles && git add macos/ && git commit -m 'macOS設定を更新'"
}

# dotfiles → macOSへ適用
apply() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    return 1
  fi

  echo "dotfilesの設定をmacOSに適用中..."

  # defaults 値を適用
  while IFS= read -r line; do
    # コメント・空行をスキップ
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    # symbolic hotkeys は別処理
    [[ "$line" =~ ^symbolic: ]] && continue

    domain_key="${line%%=*}"
    value="${line#*=}"
    domain="${domain_key%%:*}"
    key="${domain_key#*:}"

    # 型を判定して適切に書き込む
    if [ "$value" = "1" ] || [ "$value" = "0" ]; then
      # autohideなどbool値の可能性があるキーを判定
      if [[ "$key" == "autohide" ]]; then
        defaults write "$domain" "$key" -bool "$([ "$value" = "1" ] && echo true || echo false)"
      else
        defaults write "$domain" "$key" -int "$value"
      fi
    elif [[ "$value" =~ ^[0-9]+$ ]]; then
      defaults write "$domain" "$key" -int "$value"
    elif [[ "$value" =~ ^[0-9]*\.[0-9]+$ ]]; then
      defaults write "$domain" "$key" -float "$value"
    else
      defaults write "$domain" "$key" "$value"
    fi
    echo "  $domain $key = $value"
  done < "$CONFIG_FILE"

  # Mission Control ショートカットを適用
  while IFS= read -r line; do
    [[ "$line" =~ ^symbolic: ]] || continue
    if [[ "$line" =~ ^symbolic:([0-9]+):enabled=(.+)$ ]]; then
      local id="${BASH_REMATCH[1]}"
      local enabled="${BASH_REMATCH[2]}"
      # params行を探す
      local params_line
      params_line=$(grep "^symbolic:${id}:params=" "$CONFIG_FILE")
      if [ -n "$params_line" ]; then
        local params="${params_line#*=}"
        IFS=',' read -ra p <<< "$params"
        local enabled_str
        [ "$enabled" = "1" ] && enabled_str="<true/>" || enabled_str="<false/>"
        defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" "
<dict>
  <key>enabled</key>${enabled_str}
  <key>value</key>
  <dict>
    <key>parameters</key>
    <array>
      <integer>${p[0]}</integer>
      <integer>${p[1]}</integer>
      <integer>${p[2]}</integer>
    </array>
    <key>type</key><string>standard</string>
  </dict>
</dict>"
        echo "  Mission Control ID $id: enabled=$enabled"
      fi
    fi
  done < "$CONFIG_FILE"

  # Dock を再起動
  killall Dock 2>/dev/null || true

  echo ""
  echo "=== 適用完了 ==="
  echo "注意: キーボードとMission Controlの設定はログアウト/再起動後に反映"
}

# 使い方を表示
usage() {
  echo "Usage: $0 {save|apply}"
  echo ""
  echo "Commands:"
  echo "  save   - 現在のmacOS設定をdotfilesに保存"
  echo "  apply  - dotfilesの設定をmacOSに適用"
}

# コマンド実行
case "$1" in
  save)
    save
    ;;
  apply)
    apply
    ;;
  *)
    usage
    exit 1
    ;;
esac
