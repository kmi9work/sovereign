#!/bin/bash
# deploy-backend.sh - Деплой бэкенда sovereign на production сервер

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

# Parse optional command-line arguments for automated answers
# Usage: ./deploy-backend.sh [PROD_RESET] [LOAD_SEEDS]
# Examples:
#   ./deploy-backend.sh y y      # reset=y, seeds=y
#   ./deploy-backend.sh n y      # reset=no, seeds=yes
# If no arguments provided, script prompts interactively as usual

ANSWER_RESET=""
ANSWER_SEEDS=""

if [ $# -gt 0 ]; then
    ARG1="$1"
    if [ $# -eq 1 ] && [ ${#ARG1} -ge 2 ]; then
        ANSWER_RESET="${ARG1:0:1}"
        ANSWER_SEEDS="${ARG1:1:1}"
    else
        ANSWER_RESET="$1"
        ANSWER_SEEDS="$2"
    fi
    echo -e "${YELLOW}Automated mode: RESET=$ANSWER_RESET, SEEDS=$ANSWER_SEEDS${NC}\n"
fi

echo -e "${BLUE}=== Sovereign Backend Deployment ===${NC}\n"

# Configuration
SERVER="${BACKEND_DEPLOY_SERVER:-62.173.148.168}"
USER="deploy"
DEPLOY_PATH="/opt/sovereign"
REPO_URL="git@github.com:kmi9work/sovereign.git"
BRANCH="master"
RBENV_RUBY="3.2.2"
PASSENGER_RUBY="/home/deploy/.rbenv/shims/ruby"
KEEP_RELEASES=3

# Check if master.key exists locally (for database password)
if [ ! -f "$PROJECT_DIR/back/config/master.key" ]; then
    echo -e "${YELLOW}Предупреждение: back/config/master.key не найден локально${NC}"
    echo -e "${YELLOW}Убедитесь, что файл существует на сервере в shared/config/${NC}"
fi

# Step 1: Connect to server and deploy
echo -e "${BLUE}=== Шаг 1: Подключение к серверу ===${NC}"
echo -e "${YELLOW}Сервер: ${USER}@${SERVER}${NC}"
echo -e "${YELLOW}Путь: ${DEPLOY_PATH}${NC}\n"

# Create timestamp for release
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RELEASE_DIR="${DEPLOY_PATH}/releases/${TIMESTAMP}"
SHARED_DIR="${DEPLOY_PATH}/shared"
CURRENT_DIR="${DEPLOY_PATH}/current"

echo -e "${YELLOW}Создание директорий на сервере...${NC}"
ssh "${USER}@${SERVER}" "
    # Create directory structure
    mkdir -p ${DEPLOY_PATH}/releases
    mkdir -p ${SHARED_DIR}/config
    mkdir -p ${SHARED_DIR}/tmp/sockets
    mkdir -p ${SHARED_DIR}/tmp/pids
    mkdir -p ${SHARED_DIR}/tmp/cache
    mkdir -p ${SHARED_DIR}/public/uploads
    mkdir -p ${SHARED_DIR}/log
    mkdir -p ${SHARED_DIR}/vendor
    mkdir -p ${SHARED_DIR}/storage
    mkdir -p ${SHARED_DIR}/public/system
"

echo -e "${GREEN}✓ Директории созданы${NC}\n"

# Step 2: Clone/update code
echo -e "${BLUE}=== Шаг 2: Получение кода ===${NC}"
echo -e "${YELLOW}Клонирование репозитория в ${RELEASE_DIR}...${NC}"

ssh "${USER}@${SERVER}" "
    if [ -d ${RELEASE_DIR} ]; then
        echo 'Release directory already exists, removing...'
        rm -rf ${RELEASE_DIR}
    fi

    # Clone repository (only back/ subdirectory via sparse checkout)
    git clone --depth 1 --branch ${BRANCH} ${REPO_URL} ${RELEASE_DIR} || {
        echo 'Error: Failed to clone repository'
        exit 1
    }
"

echo -e "${GREEN}✓ Код получен${NC}\n"

# Step 3: Setup environment and install dependencies
echo -e "${BLUE}=== Шаг 3: Установка зависимостей ===${NC}"

ssh "${USER}@${SERVER}" "
    cd ${RELEASE_DIR}/back

    # Setup rbenv environment
    export RBENV_ROOT=\$HOME/.rbenv
    export PATH=\"\$RBENV_ROOT/bin:\$PATH\"
    eval \"\$(rbenv init - bash)\"

    # Ensure correct Ruby version is installed
    if ! rbenv versions | grep -q ${RBENV_RUBY}; then
        echo 'Installing Ruby ${RBENV_RUBY}...'
        rbenv install ${RBENV_RUBY} || true
        rbenv global ${RBENV_RUBY}
    fi

    rbenv local ${RBENV_RUBY}

    # Install bundler if not present
    if ! gem list bundler -i; then
        gem install bundler
    fi

    # Configure bundler for deployment
    bundle config set --local deployment 'true'
    bundle config set --local without 'development test'
    bundle config set --local path 'vendor/bundle'

    # Install gems
    echo 'Installing gems...'
    bundle install || {
        echo 'Error: Failed to install gems'
        exit 1
    }
"

echo -e "${GREEN}✓ Зависимости установлены${NC}\n"

# Step 4: Setup configuration files
echo -e "${BLUE}=== Шаг 4: Настройка конфигурации ===${NC}"

# Upload config files if they exist locally
if [ -f "$PROJECT_DIR/back/config/database_prod.yml" ]; then
    echo -e "${YELLOW}Загрузка database_prod.yml...${NC}"
    scp "$PROJECT_DIR/back/config/database_prod.yml" "${USER}@${SERVER}:${SHARED_DIR}/config/database.yml"
    echo -e "${GREEN}✓ database.yml загружен${NC}"
fi

if [ -f "$PROJECT_DIR/back/config/master.key" ]; then
    echo -e "${YELLOW}Загрузка master.key...${NC}"
    scp "$PROJECT_DIR/back/config/master.key" "${USER}@${SERVER}:${SHARED_DIR}/config/master.key"
    ssh "${USER}@${SERVER}" "chmod 640 ${SHARED_DIR}/config/master.key"
    echo -e "${GREEN}✓ master.key загружен${NC}"
fi

echo -e "${GREEN}✓ Конфигурация обновлена${NC}\n"

# Step 5: Create symlinks
echo -e "${BLUE}=== Шаг 5: Создание симлинков ===${NC}"

ssh "${USER}@${SERVER}" "
    cd ${RELEASE_DIR}/back

    # Create symlinks to shared files
    ln -sfn ${SHARED_DIR}/config/database.yml config/database.yml 2>/dev/null || true
    ln -sfn ${SHARED_DIR}/config/master.key config/master.key 2>/dev/null || true

    # Create symlinks to shared directories
    rm -rf log && ln -sfn ${SHARED_DIR}/log log
    rm -rf tmp/pids && mkdir -p tmp && ln -sfn ${SHARED_DIR}/tmp/pids tmp/pids
    rm -rf tmp/cache && mkdir -p tmp && ln -sfn ${SHARED_DIR}/tmp/cache tmp/cache
    rm -rf tmp/sockets && mkdir -p tmp && ln -sfn ${SHARED_DIR}/tmp/sockets tmp/sockets
    rm -rf storage && ln -sfn ${SHARED_DIR}/storage storage 2>/dev/null || true
    rm -rf public/system && mkdir -p public && ln -sfn ${SHARED_DIR}/public/system public/system 2>/dev/null || true
"

echo -e "${GREEN}✓ Симлинки созданы${NC}\n"

# Step 6: Stop Passenger
echo -e "${BLUE}=== Шаг 6: Остановка Passenger ===${NC}"
ssh "${USER}@${SERVER}" "sudo systemctl stop passenger || true"
echo -e "${GREEN}✓ Passenger остановлен${NC}\n"

# Step 7: Switch current symlink
echo -e "${BLUE}=== Шаг 7: Переключение на новый релиз ===${NC}"

ssh "${USER}@${SERVER}" "
    # Remove old current symlink or directory
    rm -rf ${CURRENT_DIR}

    # Create new symlink pointing to back/ subdirectory
    ln -sfn ${RELEASE_DIR}/back ${CURRENT_DIR}
"

echo -e "${GREEN}✓ Симлинк current обновлен (указывает на back/)${NC}\n"

# Step 8: Start Passenger
echo -e "${BLUE}=== Шаг 8: Запуск Passenger ===${NC}"
ssh "${USER}@${SERVER}" "
    sudo systemctl start passenger || {
        echo 'Error: Failed to start Passenger'
        exit 1
    }
    sleep 2
    sudo systemctl status passenger --no-pager -l || true
"
echo -e "${GREEN}✓ Passenger запущен${NC}\n"

# Check if Passenger is running
echo -e "${YELLOW}Проверка статуса Passenger...${NC}"
if ssh "${USER}@${SERVER}" "sudo systemctl is-active --quiet passenger"; then
    echo -e "${GREEN}✓ Passenger работает${NC}"
else
    echo -e "${RED}⚠ Предупреждение: Passenger может не работать${NC}"
    echo -e "${YELLOW}Проверьте логи: sudo journalctl -u passenger -n 50${NC}"
fi
echo ""

# Step 9: Cleanup old releases
echo -e "${BLUE}=== Шаг 9: Очистка старых releases ===${NC}"

ssh "${USER}@${SERVER}" "
    cd ${DEPLOY_PATH}/releases 2>/dev/null || exit 0
    ls -t | tail -n +$((KEEP_RELEASES + 1)) | xargs -r rm -rf
    echo '✓ Старые releases удалены (оставлено последних ${KEEP_RELEASES})'
"

echo ""
echo -e "${GREEN}=== Деплой завершен успешно ===${NC}"
echo -e "${BLUE}Release: ${TIMESTAMP}${NC}"
echo -e "${BLUE}Путь на сервере: ${CURRENT_DIR}${NC}"
echo ""

# Step 10: Production environment database reset (optional)
echo -e "${BLUE}=== Шаг 10: Сброс и миграция БД для production ===${NC}"

if [ -n "$ANSWER_RESET" ]; then
    PROD_RESET="$ANSWER_RESET"
else
    read -p "Выполнить сброс и миграцию БД для production? (db:drop && db:create && db:migrate) [y/N]: " PROD_RESET
fi

if [[ "$PROD_RESET" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Выполняется сброс и миграция БД для production...${NC}\n"

    # Stop Passenger first to release database connections
    echo -e "${BLUE}Остановка Passenger для освобождения подключений к БД...${NC}"
    ssh "${USER}@${SERVER}" "sudo systemctl stop passenger"
    echo -e "${GREEN}✓ Passenger остановлен${NC}\n"

    ssh "${USER}@${SERVER}" "
        cd ${CURRENT_DIR}

        # Setup rbenv environment
        export RBENV_ROOT=\$HOME/.rbenv
        export PATH=\"\$RBENV_ROOT/bin:\$PATH\"
        eval \"\$(rbenv init - bash)\"
        rbenv local ${RBENV_RUBY}

        # Command 1: db:drop
        echo '>>> Command: RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:drop'
        RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:drop || {
            echo 'Error: Failed to drop database'
            exit 1
        }

        # Command 2: db:create
        echo '>>> Command: RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:create'
        RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:create || {
            echo 'Error: Failed to create database'
            exit 1
        }

        # Command 3: db:migrate
        echo '>>> Command: RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:migrate'
        RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:migrate || {
            echo 'Error: Failed to run migrations'
            exit 1
        }

        echo '✓ Production БД успешно сброшена и миграции выполнены'
    "

    # Restart Passenger after database operations
    echo -e "${BLUE}Запуск Passenger...${NC}"
    ssh "${USER}@${SERVER}" "sudo systemctl start passenger || true"
    echo -e "${GREEN}✓ Passenger запущен${NC}\n"

    echo -e "${GREEN}✓ Production БД успешно сброшена и миграции выполнены${NC}\n"
else
    echo -e "${YELLOW}Сброс БД пропущен${NC}\n"
fi

# Step 11: Load seeds for production (optional)
echo -e "${BLUE}=== Шаг 11: Загрузка сидов для production ===${NC}"

if [ -n "$ANSWER_SEEDS" ]; then
    LOAD_SEEDS="$ANSWER_SEEDS"
else
    read -p "Загрузить сиды для production? [y/N]: " LOAD_SEEDS
fi

if [[ "$LOAD_SEEDS" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Загрузка сидов для production...${NC}\n"

    ssh "${USER}@${SERVER}" "
        cd ${CURRENT_DIR}

        # Setup rbenv environment
        export RBENV_ROOT=\$HOME/.rbenv
        export PATH=\"\$RBENV_ROOT/bin:\$PATH\"
        eval \"\$(rbenv init - bash)\"
        rbenv local ${RBENV_RUBY}

        # Command: db:seed
        echo '>>> Command: RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:seed'
        RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:seed || {
            echo 'Error: Failed to run seeds'
            exit 1
        }

        echo '✓ Сиды успешно загружены в production'
    "

    echo -e "${GREEN}✓ Сиды загружены в production${NC}\n"
else
    echo -e "${YELLOW}Загрузка сидов пропущена${NC}\n"
fi
