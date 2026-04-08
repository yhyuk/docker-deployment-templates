#!/bin/bash

# 배포 스크립트
# 사용법: ./deploy.sh [module-name] [profile]
# 예시: ./deploy.sh api-sample prod

set -e

# 설정
MODULE_NAME=${1:-api-sample}
PROFILE=${2:-prod}
CONTAINER_NAME="spring-app"
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
IMAGE_NAME="spring-app:${GIT_HASH}"

echo "================================================"
echo "Spring Boot Deployment Script"
echo "================================================"
echo "Module: $MODULE_NAME"
echo "Profile: $PROFILE"
echo "Image Tag: $GIT_HASH"
echo "================================================"

# .env 파일 확인
if [ ! -f .env ]; then
    echo ">>> .env 파일이 없습니다. .env.example을 복사해서 설정하세요."
    exit 1
fi

# 필수 환경변수 확인
set -a
source .env
set +a

if [ -z "$DB_PASSWORD" ]; then
    echo ">>> DB_PASSWORD가 설정되지 않았습니다. .env 파일을 확인하세요."
    exit 1
fi

# 기존 컨테이너 중지 및 제거
echo ">>> 기존 컨테이너 중지 중..."
docker compose down

# 이미지 빌드
echo ">>> Docker 이미지 빌드 중..."
docker build \
    --build-arg MODULE_NAME=$MODULE_NAME \
    -t $IMAGE_NAME \
    -t spring-app:latest \
    .

# 컨테이너 실행
echo ">>> 컨테이너 시작 중..."
SPRING_PROFILE=$PROFILE docker compose up -d

# 헬스체크 대기
echo ">>> 헬스체크 대기 중..."
MAX_RETRIES=60
RETRY_INTERVAL=2
for i in $(seq 1 $MAX_RETRIES); do
    if docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null | grep -q "healthy"; then
        echo ">>> 배포 완료! (healthy)"
        echo ">>> 애플리케이션 접속: http://localhost:${SERVER_PORT:-8080}"
        echo ""
        echo "로그 확인: docker compose logs -f app"
        exit 0
    fi
    echo "    대기 중... ($i/$MAX_RETRIES)"
    sleep $RETRY_INTERVAL
done

echo ">>> 헬스체크 타임아웃. 로그를 확인하세요:"
docker compose logs --tail=100 app
exit 1
