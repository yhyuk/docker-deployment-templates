#!/bin/bash

# 컨테이너 헬스체크 스크립트
# 사용법: ./health-check.sh [container1 container2 ...]
# 인자가 없으면 실행 중인 모든 컨테이너를 확인합니다.

set -e

echo "================================================"
echo "Container Health Check"
echo "================================================"
echo ""

# 컨테이너 목록: 인자가 있으면 사용, 없으면 실행 중인 컨테이너 자동 탐색
if [ $# -gt 0 ]; then
    CONTAINERS=("$@")
else
    mapfile -t CONTAINERS < <(docker ps --format '{{.Names}}')
fi

if [ ${#CONTAINERS[@]} -eq 0 ]; then
    echo "실행 중인 컨테이너가 없습니다."
    exit 0
fi

# 각 컨테이너 상태 확인
for CONTAINER in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        STATUS=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER 2>/dev/null || echo "unknown")

        if [ "$STATUS" == "healthy" ]; then
            echo "[OK] $CONTAINER: Healthy"
        elif [ "$STATUS" == "unhealthy" ]; then
            echo "[NG] $CONTAINER: Unhealthy"
            echo "     로그 확인: docker logs $CONTAINER"
        elif [ "$STATUS" == "starting" ]; then
            echo "[..] $CONTAINER: Starting..."
        else
            echo "[--] $CONTAINER: Running (No health check)"
        fi
    else
        echo "[NG] $CONTAINER: Not running"
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
