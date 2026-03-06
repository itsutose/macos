#!/bin/bash

# macOS システム設定スクリプト
# 新しいMacで実行して旧Macと同じ設定を適用する

set -e

echo "=== macOS 設定を適用 ==="

# ---------------------
# キーボード
# ---------------------
echo "キーボード設定..."
# キーリピート速度（小さいほど速い、最速=1）
defaults write NSGlobalDomain KeyRepeat -int 2
# リピート開始までの時間（小さいほど速い、デフォルト=25）
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# ---------------------
# Dock
# ---------------------
echo "Dock設定..."
# 自動的に隠す
defaults write com.apple.dock autohide -bool true
# アイコンサイズ
defaults write com.apple.dock tilesize -int 55

# ---------------------
# トラックパッド
# ---------------------
echo "トラックパッド設定..."
# 軌跡の速さ（デフォルト=1.0）
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 1.5

# ---------------------
# Mission Control: デスクトップ切り替えショートカット
# ---------------------
# Ctrl+Shift+Cmd+Option+Left/Right でデスクトップ移動
# Karabiner で right_cmd+u/p → このコンボを送信する設定と組み合わせて使う
echo "Mission Control ショートカット設定..."

# ID 79: 左のデスクトップへ移動 → Ctrl+Shift+Cmd+Option+Left
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 "
<dict>
  <key>enabled</key><true/>
  <key>value</key>
  <dict>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>123</integer>
      <integer>10354688</integer>
    </array>
    <key>type</key><string>standard</string>
  </dict>
</dict>"

# ID 80: 左のデスクトップへ移動（副）→ 無効化
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 80 "
<dict>
  <key>enabled</key><false/>
  <key>value</key>
  <dict>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>123</integer>
      <integer>8781824</integer>
    </array>
    <key>type</key><string>standard</string>
  </dict>
</dict>"

# ID 81: 右のデスクトップへ移動 → Ctrl+Shift+Cmd+Option+Right
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 "
<dict>
  <key>enabled</key><true/>
  <key>value</key>
  <dict>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>124</integer>
      <integer>10354688</integer>
    </array>
    <key>type</key><string>standard</string>
  </dict>
</dict>"

# ID 82: 右のデスクトップへ移動（副）→ 無効化
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 82 "
<dict>
  <key>enabled</key><false/>
  <key>value</key>
  <dict>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>124</integer>
      <integer>8781824</integer>
    </array>
    <key>type</key><string>standard</string>
  </dict>
</dict>"

# ---------------------
# 設定を反映
# ---------------------
echo "設定を反映中..."
killall Dock 2>/dev/null || true

echo ""
echo "=== 完了 ==="
echo "注意:"
echo "  - キーボードとMission Controlの設定はログアウト/再起動後に反映"
echo "  - Karabiner-Elements のインストールと設定適用も別途必要:"
echo "    ~/dotfiles/karabiner-element/sync.sh apply"
