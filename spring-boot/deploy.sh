#!/bin/bash

# 배포 스크립트
# 사용법: ./deploy.sh [module-name] [profile]
# 예시: ./deploy.sh api-sample prod

set -e

# 설정
MODULE_NAME=${1:-api-sample}
PROFILE=${2:-prod}
CONTAINER_NAME="spring-app"
IMAGE_NAME="spring-app:latest"

echo "================================================"
echo "Spring Boot Deployment Script"
echo "================================================"
echo "Module: $MODULE_NAME"
echo "Profile: $PROFILE"
echo "================================================"

# .env 파일 확인
if [ ! -f .env ]; then
    echo "⚠️  .env 파일이 없습니다. .env.example을 복사해서 설정하세요."
    exit 1
fi

# 환경변수 로드
export $(grep -v '^#' .env | xargs)

# 기존 컨테이너 중지 및 제거
echo "🛑 기존 컨테이너 중지 중..."
docker-compose down

# 이미지 빌드
echo "🔨 Docker 이미지 빌드 중..."
docker build \
    --build-arg MODULE_NAME=$MODULE_NAME \
    -t $IMAGE_NAME \
    .

# 컨테이너 실행
echo "🚀 컨테이너 시작 중..."
SPRING_PROFILE=$PROFILE docker-compose up -d

# 로그 확인
echo "📋 컨테이너 로그 확인 중..."
docker-compose logs -f --tail=100 app
