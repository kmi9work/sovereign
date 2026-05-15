#!/bin/bash
# Production build script for sovereign native app
# Builds the app with production backend URL

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

echo -e "${BLUE}=== Sovereign Production Build ===${NC}\n"

# Generate app icons from source
echo -e "${GREEN}Generating app icons...${NC}"
"$SCRIPTS_DIR/generate-icons.sh"
echo ""

# Production configuration
PROD_BACKEND_URL="https://sovereign-back.igroteh.su"

echo -e "${GREEN}Production Configuration:${NC}"
echo -e "  Backend URL: ${PROD_BACKEND_URL}"
echo ""

# Ask user what to build
echo -e "${YELLOW}Что хотите собрать?${NC}"
echo "  1) Android APK/AAB"
echo "  2) iOS (требуется Mac)"
echo "  3) Только обновить конфигурацию (без сборки)"
echo ""
read -p "Выбор [1-3]: " BUILD_CHOICE

case "$BUILD_CHOICE" in
    1)
        echo ""
        echo -e "${YELLOW}=== Android Build ===${NC}"
        echo -e "${BLUE}Выберите тип сборки:${NC}"
        echo "  1) APK (debug/release)"
        echo "  2) AAB (release для Google Play)"
        echo ""
        read -p "Выбор [1-2]: " ANDROID_TYPE

        cd "$PROJECT_DIR/native"

        if [ "$ANDROID_TYPE" = "1" ]; then
            echo ""
            echo -e "${YELLOW}Создание APK...${NC}"
            echo -e "${BLUE}Выберите вариант:${NC}"
            echo "  1) Debug APK"
            echo "  2) Release APK"
            echo ""
            read -p "Выбор [1-2]: " APK_TYPE

            if [ "$APK_TYPE" = "1" ]; then
                echo -e "${GREEN}Сборка Debug APK...${NC}"
                cd android
                ./gradlew assembleDebug
                echo ""
                echo -e "${GREEN}✓ Debug APK создан${NC}"
                echo -e "${BLUE}Путь: native/android/app/build/outputs/apk/debug/${NC}"
            else
                echo -e "${GREEN}Сборка Release APK...${NC}"
                echo -e "${YELLOW}Примечание: требуется настроенный keystore${NC}"
                cd android
                ./gradlew assembleRelease
                echo ""
                echo -e "${GREEN}✓ Release APK создан${NC}"
                echo -e "${BLUE}Путь: native/android/app/build/outputs/apk/release/${NC}"
            fi
        else
            echo ""
            echo -e "${GREEN}Сборка AAB для Google Play...${NC}"
            echo -e "${YELLOW}Примечание: требуется настроенный keystore${NC}"
            cd android
            ./gradlew bundleRelease
            echo ""
            echo -e "${GREEN}✓ AAB создан${NC}"
            echo -e "${BLUE}Путь: native/android/app/build/outputs/bundle/release/${NC}"
        fi

        cd "$PROJECT_DIR"
        ;;
    2)
        echo ""
        echo -e "${YELLOW}=== iOS Build ===${NC}"
        echo -e "${RED}Внимание: iOS сборка требует Mac и настроенный Xcode${NC}"

        cd "$PROJECT_DIR/native/ios"

        echo -e "${GREEN}Установка Pods...${NC}"
        pod install

        echo ""
        echo -e "${YELLOW}Откройте native/ios/native.xcworkspace в Xcode для сборки${NC}"
        echo -e "${BLUE}Или выполните: xcodebuild -workspace native.xcworkspace -scheme native -configuration Release${NC}"

        cd "$PROJECT_DIR"
        ;;
    3)
        echo ""
        echo -e "${GREEN}✓ Конфигурация не требует изменений для продакшн${NC}"
        ;;
    *)
        echo -e "${YELLOW}Неверный выбор.${NC}"
        ;;
esac

echo ""
echo -e "${GREEN}=== Готово ===${NC}"
echo -e "${BLUE}Для возврата к dev-режиму запустите ./scripts/start-dev.sh${NC}"
echo ""
