#!/bin/bash

# MySQL 데이터베이스 복구 스크립트
# 사용법: ./restore-db.sh [backup_file] [container_name] [database_name]
# 예시: ./restore-db.sh backups/app_db_20240305_120000.sql.gz mysql app_db

set -e

BACKUP_FILE=$1
CONTAINER_NAME=${2:-mysql}
DB_NAME=${3:-app_db}

echo "================================================"
echo "MySQL Database Restore Script"
echo "================================================"
echo "Backup File: $BACKUP_FILE"
echo "Container: $CONTAINER_NAME"
echo "Database: $DB_NAME"
echo "================================================"

# 인자 확인
if [ -z "$BACKUP_FILE" ]; then
    echo "❌ 백업 파일을 지정해주세요."
    echo "사용법: ./restore-db.sh [backup_file] [container_name] [database_name]"
    exit 1
fi

# 백업 파일 존재 확인
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ 백업 파일을 찾을 수 없습니다: $BACKUP_FILE"
    exit 1
fi

# 컨테이너 실행 확인
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "❌ 컨테이너 '$CONTAINER_NAME'가 실행 중이지 않습니다."
    exit 1
fi

# 확인 메시지
echo ""
echo "⚠️  경고: 데이터베이스 '$DB_NAME'의 모든 데이터가 백업 파일로 대체됩니다."
read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 복구가 취소되었습니다."
    exit 1
fi

echo "🔄 복구 시작..."

# Gzip 압축 해제 후 복구
if [[ $BACKUP_FILE == *.gz ]]; then
    gunzip -c $BACKUP_FILE | docker exec -i $CONTAINER_NAME mysql \
        -u root \
        -p${DB_PASSWORD:-password} \
        $DB_NAME
else
    docker exec -i $CONTAINER_NAME mysql \
        -u root \
        -p${DB_PASSWORD:-password} \
        $DB_NAME < $BACKUP_FILE
fi

echo "✅ 복구 완료!"
