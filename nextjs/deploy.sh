#!/bin/bash

# Next.js 배포 스크립트
# 사용법: ./deploy.sh [env]
# 예시: ./deploy.sh prod

set -e

# 설정
ENV=${1:-prod}
CONTAINER_NAME="nextjs-app"
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
IMAGE_NAME="nextjs-app:${GIT_HASH}"

echo "================================================"
echo "Next.js Deployment Script"
echo "================================================"
echo "Environment: $ENV"
echo "Image Tag: $GIT_HASH"
echo "================================================"

# .env 파일 확인
if [ ! -f .env ]; then
    echo ">>> .env 파일이 없습니다. .env.example을 복사해서 설정하세요."
    exit 1
fi

# 환경변수 로드
set -a
source .env
set +a

# 개발 환경
if [ "$ENV" == "dev" ]; then
    echo ">>> 개발 환경 실행 중..."
    docker compose -f docker-compose.dev.yml down
    docker compose -f docker-compose.dev.yml up --build
    exit 0
fi

# 프로덕션 환경
echo ">>> 기존 컨테이너 중지 중..."
docker compose down

echo ">>> Docker 이미지 빌드 중..."
docker build \
    --build-arg NEXT_PUBLIC_API_URL=$API_URL \
    -t $IMAGE_NAME \
    -t nextjs-app:latest \
    .

echo ">>> 컨테이너 시작 중..."
docker compose up -d

# 헬스체크 대기
echo ">>> 헬스체크 대기 중..."
MAX_RETRIES=30
RETRY_INTERVAL=2
for i in $(seq 1 $MAX_RETRIES); do
    if docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null | grep -q "healthy"; then
        echo ">>> 배포 완료! (healthy)"
        echo ">>> 애플리케이션 접속: http://localhost:${APP_PORT:-3000}"
        echo ""
        echo "로그 확인: docker compose logs -f nextjs-app"
        exit 0
    fi
    echo "    대기 중... ($i/$MAX_RETRIES)"
    sleep $RETRY_INTERVAL
done

echo ">>> 헬스체크 타임아웃. 로그를 확인하세요:"
docker compose logs --tail=50 nextjs-app
exit 1
