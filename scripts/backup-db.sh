#!/bin/bash

# MySQL 데이터베이스 백업 스크립트
# 사용법: ./backup-db.sh [container_name] [database_name]
# 예시: ./backup-db.sh mysql app_db

set -e

CONTAINER_NAME=${1:-mysql}
DB_NAME=${2:-app_db}
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

echo "================================================"
echo "MySQL Database Backup Script"
echo "================================================"
echo "Container: $CONTAINER_NAME"
echo "Database: $DB_NAME"
echo "================================================"

# 백업 디렉토리 생성
mkdir -p $BACKUP_DIR

# 컨테이너 실행 확인
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "❌ 컨테이너 '$CONTAINER_NAME'가 실행 중이지 않습니다."
    exit 1
fi

echo "🔄 백업 시작..."

# MySQL 덤프
docker exec $CONTAINER_NAME mysqldump \
    -u root \
    -p${DB_PASSWORD:-password} \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    $DB_NAME > $BACKUP_FILE

# Gzip 압축
gzip $BACKUP_FILE

echo "✅ 백업 완료!"
echo "파일: ${BACKUP_FILE}.gz"
echo "크기: $(du -h ${BACKUP_FILE}.gz | cut -f1)"

# 7일 이상 된 백업 파일 삭제
echo ""
echo "🗑️  오래된 백업 파일 정리 중..."
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
echo "✅ 정리 완료!"
