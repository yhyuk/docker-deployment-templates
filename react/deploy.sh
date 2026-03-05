#!/bin/bash

# React 배포 스크립트
# 사용법: ./deploy.sh [env]
# 예시: ./deploy.sh prod

set -e

# 설정
ENV=${1:-prod}
CONTAINER_NAME="react-app"
IMAGE_NAME="react-app:latest"

echo "================================================"
echo "React Deployment Script"
echo "================================================"
echo "Environment: $ENV"
echo "================================================"

# .env 파일 확인
if [ ! -f .env ]; then
    echo "⚠️  .env 파일이 없습니다. .env.example을 복사해서 설정하세요."
    exit 1
fi

# 환경변수 로드
export $(grep -v '^#' .env | xargs)

# 개발 환경
if [ "$ENV" == "dev" ]; then
    echo "🔧 개발 환경 실행 중..."
    docker-compose -f docker-compose.dev.yml down
    docker-compose -f docker-compose.dev.yml up --build
    exit 0
fi

# 프로덕션 환경
echo "🛑 기존 컨테이너 중지 중..."
docker-compose down

echo "🔨 Docker 이미지 빌드 중..."
docker build \
    --build-arg REACT_APP_API_URL=$API_URL \
    -t $IMAGE_NAME \
    .

echo "🚀 컨테이너 시작 중..."
docker-compose up -d

echo "✅ 배포 완료!"
echo "📋 애플리케이션 접속: http://localhost:${APP_PORT:-80}"
echo ""
echo "로그 확인: docker-compose logs -f react-app"
