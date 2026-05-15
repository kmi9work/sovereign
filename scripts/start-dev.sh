#!/bin/bash
# Development startup script for sovereign project
# Launches backend (Rails) and mobile (React Native) in tmux sessions

set -e

# Get the directory where this script is located
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the project root directory (one level up)
PROJECT_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Sovereign Development Startup ===${NC}\n"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}ERROR: tmux is not installed${NC}"
    echo "Please install tmux: sudo apt-get install tmux"
    exit 1
fi

# Detect IP address
echo -e "${YELLOW}Detecting system IP address...${NC}"
source "$SCRIPTS_DIR/get-ip.sh"
if [ -z "$DEV_IP" ]; then
    echo -e "${RED}Failed to detect IP address${NC}"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set default ports if not already set
export BACKEND_PORT=${BACKEND_PORT:-3000}
export BACKEND_URL="http://${DEV_IP}:${BACKEND_PORT}"

echo -e "\n${GREEN}Configuration:${NC}"
echo -e "  IP Address:   ${DEV_IP}"
echo -e "  Backend URL:  ${BACKEND_URL}"
echo ""

# Function to detect Android devices
detect_android_devices() {
    echo -e "${YELLOW}Обнаружение Android устройств...${NC}"

    # Check if adb is available
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}ADB не найден. Установите Android SDK Platform Tools${NC}"
        return 1
    fi

    # Get list of devices
    adb devices -l | grep -v "List of devices" | grep -v "^$" > /tmp/adb_devices.txt

    if [ ! -s /tmp/adb_devices.txt ]; then
        echo -e "${RED}Устройства не найдены${NC}"
        return 1
    fi

    echo -e "${GREEN}Найденные устройства:${NC}"
    echo ""

    # Parse and display devices
    local i=1
    declare -g -A DEVICES
    while IFS= read -r line; do
        if [[ $line =~ ^([a-zA-Z0-9]+)[[:space:]]+device ]]; then
            device_id="${BASH_REMATCH[1]}"
            # Extract model name if available
            if [[ $line =~ model:([^[:space:]]+) ]]; then
                model="${BASH_REMATCH[1]}"
            else
                model="Unknown"
            fi
            # Extract product if available
            if [[ $line =~ product:([^[:space:]]+) ]]; then
                product="${BASH_REMATCH[1]}"
            else
                product="Unknown"
            fi

            DEVICES[$i]="$device_id"
            echo -e "  ${i}) ${GREEN}${device_id}${NC} - ${model} (${product})"
            ((i++))
        fi
    done < /tmp/adb_devices.txt

    echo ""
    return 0
}

# Function to check if emulator command is available
check_emulator_available() {
    if command -v emulator &> /dev/null; then
        return 0
    fi

    # Try to find emulator in common Android SDK locations
    local possible_paths=(
        "$HOME/Android/Sdk/emulator/emulator"
        "$ANDROID_HOME/emulator/emulator"
        "$ANDROID_SDK_ROOT/emulator/emulator"
    )

    for path in "${possible_paths[@]}"; do
        if [ -f "$path" ]; then
            export PATH="$(dirname "$path"):$PATH"
            return 0
        fi
    done

    return 1
}

# Function to list available AVDs
list_avds() {
    if ! check_emulator_available; then
        return 1
    fi

    emulator -list-avds 2>/dev/null
}

# Function to start an emulator
start_emulator() {
    local avd_name="$1"

    if ! check_emulator_available; then
        echo -e "${RED}Команда emulator не найдена${NC}"
        echo -e "${YELLOW}Убедитесь, что Android SDK установлен и emulator доступен${NC}"
        return 1
    fi

    echo -e "${YELLOW}Запуск эмулятора: ${GREEN}${avd_name}${NC}${YELLOW}...${NC}"
    echo -e "${BLUE}Это может занять некоторое время...${NC}"
    echo ""

    # Start emulator in background
    emulator -avd "$avd_name" > /dev/null 2>&1 &
    local emulator_pid=$!

    echo -e "${YELLOW}Ожидание готовности эмулятора...${NC}"

    # Wait for emulator to be ready (check every 2 seconds, max 120 seconds)
    local max_wait=60
    local waited=0

    while [ $waited -lt $max_wait ]; do
        if adb devices | grep -q "emulator.*device$"; then
            echo ""
            echo -e "${GREEN}✓ Эмулятор готов!${NC}"
            sleep 2  # Give it a moment to fully initialize
            return 0
        fi
        echo -n "."
        sleep 2
        waited=$((waited + 2))
    done

    echo ""
    echo -e "${YELLOW}Эмулятор запускается слишком долго. Проверьте его состояние вручную.${NC}"
    return 1
}

# Ask user about mobile app startup mode
echo -e "\n${YELLOW}Запустить мобильное приложение (native)?${NC}"
echo "  1) Да, запустить Metro bundler"
echo "  2) Нет, пропустить"
echo ""
read -p "Выбор [1-2]: " MOBILE_CHOICE

MOBILE_CMD=""
MOBILE_DESC="Skipped"
RUN_ANDROID=""
SELECTED_DEVICE=""

if [ "$MOBILE_CHOICE" = "1" ]; then
    MOBILE_CMD="npx react-native start --reset-cache"
    MOBILE_DESC="React Native (Metro)"

    echo ""
    echo -e "${YELLOW}Хотите также запустить сборку на Android устройство?${NC}"
    echo -e "${BLUE}(Команда: npx react-native run-android)${NC}"
    echo "  1) Да, запустить сборку на устройство"
    echo "  2) Нет, только Metro bundler"
    echo ""
    read -p "Выбор [1-2]: " ANDROID_CHOICE

    if [ "$ANDROID_CHOICE" = "1" ]; then
        RUN_ANDROID="yes"

        # Detect and select Android device
        echo ""
        if ! detect_android_devices; then
            # No devices found - ask about emulator
            echo -e "${YELLOW}Убедитесь что:${NC}"
            echo "  - Устройство подключено по USB"
            echo "  - Отладка по USB включена на устройстве"
            echo "  - Драйверы установлены (для Windows)"
            echo ""

            # Check if emulator is available
            if check_emulator_available; then
                echo -e "${YELLOW}Запустить Android эмулятор?${NC}"
                echo "  1) Да, запустить эмулятор"
                echo "  2) Нет, продолжить без устройства"
                echo ""
                read -p "Выбор [1-2]: " EMULATOR_CHOICE

                if [ "$EMULATOR_CHOICE" = "1" ]; then
                    # List available AVDs
                    echo ""
                    echo -e "${YELLOW}Доступные эмуляторы:${NC}"

                    # Read AVDs into array (handles names with spaces)
                    avds=()
                    while IFS= read -r avd_name; do
                        [ -n "$avd_name" ] && avds+=("$avd_name")
                    done < <(list_avds)

                    if [ ${#avds[@]} -eq 0 ]; then
                        echo -e "${RED}Эмуляторы не найдены${NC}"
                        echo -e "${YELLOW}Создайте AVD через Android Studio или командную строку${NC}"
                        echo -e "${YELLOW}Продолжаем без выбора конкретного устройства${NC}"
                    elif [ ${#avds[@]} -eq 1 ]; then
                        # Only one AVD available
                        selected_avd="${avds[0]}"
                        echo -e "  ${GREEN}${selected_avd}${NC} (автоматически выбрано)"
                        echo ""

                        if start_emulator "$selected_avd"; then
                            # Re-detect devices after emulator started
                            if detect_android_devices; then
                                device_count=${#DEVICES[@]}
                                if [ $device_count -ge 1 ]; then
                                    # Find the emulator device
                                    for key in "${!DEVICES[@]}"; do
                                        dev_id="${DEVICES[$key]}"
                                        if [[ $dev_id == emulator-* ]]; then
                                            SELECTED_DEVICE="$dev_id"
                                            echo -e "${GREEN}Эмулятор обнаружен: ${SELECTED_DEVICE}${NC}"
                                            break
                                        fi
                                    done
                                    # If not found by pattern, use first device
                                    if [ -z "$SELECTED_DEVICE" ] && [ ${#DEVICES[@]} -ge 1 ]; then
                                        SELECTED_DEVICE="${DEVICES[1]}"
                                        echo -e "${GREEN}Выбрано устройство: ${SELECTED_DEVICE}${NC}"
                                    fi
                                fi
                            fi
                        fi
                    else
                        # Multiple AVDs - let user choose
                        i=1
                        for avd in "${avds[@]}"; do
                            echo -e "  ${i}) ${GREEN}${avd}${NC}"
                            ((i++))
                        done
                        echo ""
                        read -p "Выберите эмулятор [1-${#avds[@]}]: " AVD_CHOICE

                        if [ -n "$AVD_CHOICE" ] && [ "$AVD_CHOICE" -ge 1 ] && [ "$AVD_CHOICE" -le ${#avds[@]} ]; then
                            selected_avd="${avds[$((AVD_CHOICE - 1))]}"
                            echo ""

                            if start_emulator "$selected_avd"; then
                                # Re-detect devices after emulator started
                                if detect_android_devices; then
                                    device_count=${#DEVICES[@]}
                                    if [ $device_count -ge 1 ]; then
                                        # Find the emulator device
                                        for key in "${!DEVICES[@]}"; do
                                            dev_id="${DEVICES[$key]}"
                                            if [[ $dev_id == emulator-* ]]; then
                                                SELECTED_DEVICE="$dev_id"
                                                echo -e "${GREEN}Эмулятор обнаружен: ${SELECTED_DEVICE}${NC}"
                                                break
                                            fi
                                        done
                                        # If not found by pattern, use first device
                                        if [ -z "$SELECTED_DEVICE" ] && [ ${#DEVICES[@]} -ge 1 ]; then
                                            SELECTED_DEVICE="${DEVICES[1]}"
                                            echo -e "${GREEN}Выбрано устройство: ${SELECTED_DEVICE}${NC}"
                                        fi
                                    fi
                                fi
                            fi
                        else
                            echo -e "${RED}Неверный выбор. Продолжаем без устройства${NC}"
                        fi
                    fi
                else
                    echo -e "${YELLOW}Продолжаем без выбора конкретного устройства${NC}"
                fi
            else
                echo -e "${YELLOW}Эмулятор недоступен. Продолжаем без выбора конкретного устройства${NC}"
            fi
        else
            # Devices found
            device_count=${#DEVICES[@]}

            if [ $device_count -eq 1 ]; then
                SELECTED_DEVICE="${DEVICES[1]}"
                echo -e "${GREEN}Автоматически выбрано единственное устройство: ${SELECTED_DEVICE}${NC}"
            else
                echo -e "${YELLOW}Выберите устройство для установки:${NC}"
                read -p "Номер устройства [1-${device_count}]: " DEVICE_CHOICE

                if [ -n "${DEVICES[$DEVICE_CHOICE]}" ]; then
                    SELECTED_DEVICE="${DEVICES[$DEVICE_CHOICE]}"
                    echo -e "${GREEN}Выбрано устройство: ${SELECTED_DEVICE}${NC}"
                else
                    echo -e "${RED}Неверный выбор. Будет использовано устройство по умолчанию${NC}"
                fi
            fi
        fi
    fi
fi

# Generate config.ts with the detected backend IP (so the app connects over WiFi)
if [ "$MOBILE_CHOICE" = "1" ]; then
    echo -e "${YELLOW}Обновление конфигурации приложения...${NC}"
    cat > "$PROJECT_DIR/native/src/config.ts" <<EOF
// Auto-generated by start-dev.sh on $(date)
import { Platform } from 'react-native';

const DEV_HOST = Platform.OS === 'android' ? '${DEV_IP}' : 'localhost';

const ENV = {
  development: {
    API_BASE_URL: \`http://\${DEV_HOST}:3000\`,
  },
  production: {
    API_BASE_URL: 'https://sovereign-back.igroteh.su',
  },
};

const currentEnv = __DEV__ ? 'development' : 'production';

export const CONFIG = ENV[currentEnv];
EOF
    echo -e "${GREEN}✓ config.ts обновлён (backend: ${DEV_IP}:3000)${NC}"
fi

# Session name
SESSION_NAME="sovereign-dev"

# Kill existing session if it exists
tmux has-session -t $SESSION_NAME 2>/dev/null && tmux kill-session -t $SESSION_NAME

echo -e "\n${GREEN}Starting tmux session: ${SESSION_NAME}${NC}\n"

# Create new tmux session with backend
tmux new-session -d -s $SESSION_NAME -n "Sovereign Development"

# Style pane borders with green lines for visibility
tmux setw -t $SESSION_NAME pane-border-style "fg=green"
tmux setw -t $SESSION_NAME pane-active-border-style "fg=brightgreen"

# Setup backend pane (top)
tmux send-keys -t $SESSION_NAME "cd '$PROJECT_DIR/back'" C-m
tmux send-keys -t $SESSION_NAME "clear" C-m
tmux send-keys -t $SESSION_NAME "echo -e '${BLUE}=== Backend (Rails) ===${NC}'" C-m
tmux send-keys -t $SESSION_NAME "echo 'Starting Rails server on ${BACKEND_URL}...'" C-m
tmux send-keys -t $SESSION_NAME "echo ''" C-m
tmux send-keys -t $SESSION_NAME "rvm use" C-m
tmux send-keys -t $SESSION_NAME "export DEV_IP='${DEV_IP}'" C-m
tmux send-keys -t $SESSION_NAME "export BACKEND_PORT='${BACKEND_PORT}'" C-m
tmux send-keys -t $SESSION_NAME "export PORT='${BACKEND_PORT}'" C-m
tmux send-keys -t $SESSION_NAME "export RAILS_ENV='development'" C-m
tmux send-keys -t $SESSION_NAME "export RACK_ENV='development'" C-m
tmux send-keys -t $SESSION_NAME "rails s -b ${DEV_IP} -p ${BACKEND_PORT}" C-m

# Split window horizontally for mobile (bottom)
if [ -n "$MOBILE_CMD" ]; then
    tmux split-window -v -l 40% -t $SESSION_NAME
    tmux send-keys -t $SESSION_NAME "cd '$PROJECT_DIR/native'" C-m
    tmux send-keys -t $SESSION_NAME "clear" C-m
    tmux send-keys -t $SESSION_NAME "echo -e '${BLUE}=== Mobile (React Native) ===${NC}'" C-m
    tmux send-keys -t $SESSION_NAME "echo 'Backend URL: ${BACKEND_URL}'" C-m

    if [ "$RUN_ANDROID" = "yes" ]; then
        # Setup adb reverse
        tmux send-keys -t $SESSION_NAME "adb reverse tcp:8081 tcp:8081 2>/dev/null; adb reverse tcp:3000 tcp:3000 2>/dev/null" C-m
        # Build and install, then start Metro — all in one send-keys so stdin
        # from subsequent send-keys doesn't get consumed by run-android
        if [ -n "$SELECTED_DEVICE" ]; then
            tmux send-keys -t $SESSION_NAME "echo 'Device: ${SELECTED_DEVICE}' && npx react-native run-android --device ${SELECTED_DEVICE} --mode debug; echo ''; echo '${GREEN}Starting Metro bundler...${NC}'; ${MOBILE_CMD}" C-m
        else
            tmux send-keys -t $SESSION_NAME "npx react-native run-android --mode debug; echo ''; echo '${GREEN}Starting Metro bundler...${NC}'; ${MOBILE_CMD}" C-m
        fi
    else
        tmux send-keys -t $SESSION_NAME "echo 'Starting Metro bundler...'" C-m
        tmux send-keys -t $SESSION_NAME "echo ''" C-m
        tmux send-keys -t $SESSION_NAME "echo -e '${YELLOW}Reminder: run on device with:${NC}'" C-m
        tmux send-keys -t $SESSION_NAME "echo -e '${GREEN}npx react-native run-android${NC}'" C-m
        tmux send-keys -t $SESSION_NAME "echo ''" C-m
        tmux send-keys -t $SESSION_NAME "sleep 3" C-m
        tmux send-keys -t $SESSION_NAME "${MOBILE_CMD}" C-m
    fi
fi

# main-horizontal layout: backend on top, mobile below
tmux select-layout -t $SESSION_NAME main-horizontal

# Select the backend pane
tmux select-pane -t $SESSION_NAME:0.0

echo -e "${GREEN}✓ Tmux session created successfully!${NC}\n"
echo -e "${YELLOW}Commands:${NC}"
echo -e "  Attach to session:    ${GREEN}tmux attach -t ${SESSION_NAME}${NC}"
echo -e "  Detach from session:  ${GREEN}Ctrl+B, then D${NC}"
echo -e "  Switch panes:         ${GREEN}Ctrl+B, then arrow keys${NC}"
echo -e "  Kill session:         ${GREEN}tmux kill-session -t ${SESSION_NAME}${NC}"
echo ""
echo -e "${YELLOW}Services:${NC}"
echo -e "  Backend:     ${BACKEND_URL}"
if [ -n "$MOBILE_CMD" ]; then
    echo -e "  Mobile:      ${MOBILE_DESC}"
fi
echo ""
echo -e "${GREEN}Attaching to session...${NC}"
echo ""

# Give services a moment to start before attaching
sleep 1

# Attach to the session
tmux attach -t $SESSION_NAME
