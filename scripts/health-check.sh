#!/bin/bash

# 컨테이너 헬스체크 스크립트
# 사용법: ./health-check.sh

set -e

echo "================================================"
echo "Container Health Check"
echo "================================================"
echo ""

# 컨테이너 목록
CONTAINERS=("backend" "frontend" "mysql")

# 각 컨테이너 상태 확인
for CONTAINER in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        STATUS=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER 2>/dev/null || echo "unknown")

        if [ "$STATUS" == "healthy" ]; then
            echo "✅ $CONTAINER: Healthy"
        elif [ "$STATUS" == "unhealthy" ]; then
            echo "❌ $CONTAINER: Unhealthy"
            echo "   로그 확인: docker logs $CONTAINER"
        elif [ "$STATUS" == "starting" ]; then
            echo "🔄 $CONTAINER: Starting..."
        else
            echo "⚪ $CONTAINER: Running (No health check)"
        fi
    else
        echo "❌ $CONTAINER: Not running"
    fi
done

echo ""
echo "================================================"
echo "Container Status"
echo "================================================"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "================================================"
echo "Resource Usage"
echo "================================================"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
