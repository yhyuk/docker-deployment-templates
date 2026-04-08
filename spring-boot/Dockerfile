# Build stage
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# Gradle wrapper 복사
COPY gradlew .
COPY gradle gradle
RUN chmod +x gradlew

# 빌드 스크립트 복사 (의존성 캐싱을 위해 소스보다 먼저)
COPY build.gradle .
COPY settings.gradle .

# 의존성 프리페치 (레이어 캐싱 최적화)
RUN ./gradlew dependencies --no-daemon || true

# 소스 코드 복사 (멀티모듈 구조)
COPY common common
COPY domain domain
COPY api-* api-*/

# 모듈명을 환경변수로 받아서 빌드 (기본값: api-sample)
ARG MODULE_NAME=api-sample
RUN ./gradlew :${MODULE_NAME}:bootJar --no-daemon

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

ARG MODULE_NAME=api-sample

# non-root 사용자 생성
RUN addgroup --system --gid 1001 spring && \
    adduser --system --uid 1001 --ingroup spring spring

# 로그 디렉토리 생성 및 권한 설정
RUN mkdir -p /srv/logs/app/archive && \
    chown -R spring:spring /srv/logs/app

# 빌드된 JAR 파일 복사
COPY --from=builder --chown=spring:spring /app/${MODULE_NAME}/build/libs/${MODULE_NAME}.jar app.jar

USER spring

# 헬스체크 (Spring Boot Actuator 엔드포인트)
ENV SERVER_PORT=8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${SERVER_PORT}/actuator/health || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-jar", "app.jar"]
