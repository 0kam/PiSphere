#!/bin/bash

# =========================================
# Initial Setup Script - Cron-based Scheduling
# Created on: 2024-12-09
# =========================================

# エラーハンドリング
set -e

# カラーコードの定義（オプション）
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数（カラー付き）
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# PiSphereのロゴをカラー付きで表示する関数
display_logo() {
    echo -e "${GREEN}"
    cat << "EOF"
        ______   _   ______         _
       (_____ \ (_) / _____)       | |
        _____) ) _ ( (____   ____  | |__   _____   ____  _____
       |  ____/ | | \____ \ |  _ \ |  _ \ | ___ | / ___)| ___ |
       | |      | | _____) )| |_| || | | || ____|| |    | ____|
       |_|      |_|(______/ |  __/ |_| |_||_____)|_|    |_____)
                            |_|
EOF
    echo -e "${NC}"
    echo
}

# ウェルカムメッセージをカラー付きで表示する関数
display_welcome_message() {
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}   Welcome to the PiSphere Setup Script!${NC}"
    echo -e "${GREEN}   This script will automate the necessary${NC}"
    echo -e "${GREEN}   configurations for PiSphere.${NC}"
    echo -e "${GREEN}   Please follow the prompts and provide${NC}"
    echo -e "${GREEN}   the required information.${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo
}

# スクリプト所有者のユーザー名を取得する関数
get_script_owner() {
    # スクリプトの絶対パスを取得
    SCRIPT_PATH="$(readlink -f "$0")"

    # スクリプトファイルの所有者を取得
    EXEC_USER="$(stat -c '%U' "$SCRIPT_PATH")"

    log "The script is located in the home directory of user: $EXEC_USER"
}

# run.sh をテンプレートから作成する関数
create_run_script() {
    # スクリプトの場所に基づいて scripts ディレクトリを定義
    SCRIPTS_DIR="$(dirname "$SCRIPT_PATH")/shs"

    # テンプレートファイルと新しい run.sh ファイルのパス
    TEMPLATE_FILE="$SCRIPTS_DIR/run.sh.template"
    RUN_SCRIPT="$SCRIPTS_DIR/run.sh"

    # テンプレートファイルが存在するか確認
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log "Template file $TEMPLATE_FILE does not exist. Exiting."
        exit 1
    fi

    # run.sh ファイルが既に存在する場合は削除
    if [ -f "$RUN_SCRIPT" ]; then
        log "Run script $RUN_SCRIPT already exists. Deleting it."
        rm "$RUN_SCRIPT"
    fi

    # テンプレートを run.sh にコピー
    cp "$TEMPLATE_FILE" "$RUN_SCRIPT"
    log "Copied $TEMPLATE_FILE to $RUN_SCRIPT"

    # プレースホルダーを実際の値で置換
    sed -i "s/__USER__/$EXEC_USER/g" "$RUN_SCRIPT"
    sed -i "s/__START_TIME__/$START_TIME/g" "$RUN_SCRIPT"
    sed -i "s/__END_TIME__/$END_TIME/g" "$RUN_SCRIPT"
    sed -i "s/__INTERVAL_MINUTES__/$INTERVAL_MINUTES/g" "$RUN_SCRIPT"
    log "Replaced placeholders in $RUN_SCRIPT"

    # run.sh に実行権限を付与
    chmod +x "$RUN_SCRIPT"
    log "Set execute permission for $RUN_SCRIPT"
}

# cron ジョブを作成する関数
create_cron_jobs() {
    # スクリプトの場所に基づいて scripts ディレクトリを定義
    SCRIPTS_DIR="$(dirname "$SCRIPT_PATH")/shs"

    RUN_SCRIPT="$SCRIPTS_DIR/run.sh"
    LOG_FILE="$SCRIPTS_DIR/cron.log"

    # run.sh スクリプトが存在し、実行可能であることを確認
    if [ ! -x "$RUN_SCRIPT" ]; then
        log "Run script $RUN_SCRIPT does not exist or is not executable. Exiting."
        exit 1
    fi

    # ログファイルの存在を確認し、存在しない場合は作成
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        log "Created log file at $LOG_FILE"
    fi

    # 現在の crontab をバックアップ
    crontab -l > mycron_backup 2>/dev/null || true

    # 既存の PiSphere cron ジョブを削除して重複を防ぐ
    grep -v 'PiSphere_Run_Script' mycron_backup > mycron_temp || true
    mv mycron_temp mycron_backup

    # start_time と end_time を分単位に変換
    IFS=':' read -r START_HOUR START_MIN <<< "$START_TIME"
    IFS=':' read -r END_HOUR END_MIN <<< "$END_TIME"

    START_TOTAL_MIN=$((10#$START_HOUR * 60 + 10#$START_MIN))
    END_TOTAL_MIN=$((10#$END_HOUR * 60 + 10#$END_MIN))

    # 撮影ウィンドウが日付をまたぐ場合の処理
    if [ "$START_TOTAL_MIN" -gt "$END_TOTAL_MIN" ]; then
        END_TOTAL_MIN=$((END_TOTAL_MIN + 1440)) # 24*60 分を追加
    fi

    current_min=$START_TOTAL_MIN

    # 指定されたインターバルに基づいて cron ジョブを追加
    while [ "$current_min" -le "$END_TOTAL_MIN" ]; do
        # 1440 分を超える場合は翌日の時間に調整
        adjusted_min=$((current_min % 1440))

        hour=$((adjusted_min / 60))
        minute=$((adjusted_min % 60))

        # 時と分をゼロ埋めでフォーマット
        hour_fmt=$(printf "%02d" "$hour")
        minute_fmt=$(printf "%02d" "$minute")

        # cron ジョブを追加（ログファイルへのリダイレクトを追加）
        echo "$minute_fmt $hour_fmt * * * $RUN_SCRIPT >> $LOG_FILE 2>&1 # PiSphere_Run_Script" >> mycron_backup

        # インターバル分を加算
        current_min=$((current_min + INTERVAL_MINUTES))
    done

    # 新しい crontab をインストール
    crontab mycron_backup
    rm mycron_backup mycron_temp 2>/dev/null || true
    log "Added cron jobs for PiSphere_Run_Script with logging to $LOG_FILE."
}

# ユーザー入力を取得する関数
get_user_settings() {
    echo "Please enter the capture start time (HH:MM, 24-hour format, e.g., 07:00):"
    read START_TIME_INPUT
    # 入力形式を検証
    while ! [[ "$START_TIME_INPUT" =~ ^([01][0-9]|2[0-3]):([0-5][0-9])$ ]]; do
        echo "Invalid format. Please enter time as HH:MM (24-hour format, e.g., 07:00):"
        read START_TIME_INPUT
    done
    START_TIME="$START_TIME_INPUT"

    echo "Please enter the capture end time (HH:MM, 24-hour format, e.g., 18:00):"
    read END_TIME_INPUT
    # 入力形式を検証
    while ! [[ "$END_TIME_INPUT" =~ ^([01][0-9]|2[0-3]):([0-5][0-9])$ ]]; do
        echo "Invalid format. Please enter time as HH:MM (24-hour format, e.g., 18:00):"
        read END_TIME_INPUT
    done
    END_TIME="$END_TIME_INPUT"

    echo "Please enter the capture interval in minutes (e.g., 30):"
    read INTERVAL_MINUTES_INPUT
    # 正の整数であることを検証
    while ! [[ "$INTERVAL_MINUTES_INPUT" =~ ^[1-9][0-9]*$ ]]; do
        echo "Invalid input. Please enter a positive integer for minutes (e.g., 30):"
        read INTERVAL_MINUTES_INPUT
    done
    INTERVAL_MINUTES="$INTERVAL_MINUTES_INPUT"

    log "User settings - Start Time: $START_TIME, End Time: $END_TIME, Interval: $INTERVAL_MINUTES minutes"
}

# メイン実行フロー

# スクリプトが root で実行されている場合、ユーザーとして実行するように促す
if [ "$(id -u)" -eq 0 ]; then
    echo "Please run this script as the target user, not with sudo."
    exit 1
fi

# ロゴとウェルカムメッセージを表示
display_logo
display_welcome_message

# スクリプト所有者のユーザー名を取得
get_script_owner

# ユーザーからの設定を取得
get_user_settings

# 実行ユーザーをログに記録
log "The script is being executed for user: $EXEC_USER"

# run.sh をテンプレートから作成
create_run_script

# cron ジョブを作成
create_cron_jobs

log "PiSphere setup completed successfully."

# 初回の run.sh を手動で実行するよう案内
echo "Please run the run.sh script once to initialize the capture process:"
echo "/home/$EXEC_USER/PiSphere/shs/run.sh"
