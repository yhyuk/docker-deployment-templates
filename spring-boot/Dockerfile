# Build stage
FROM gradle:8.5-jdk21-alpine AS builder

WORKDIR /app

# Gradle wrapper 복사
COPY gradlew .
COPY gradle gradle

# 빌드 스크립트 복사
COPY build.gradle .
COPY settings.gradle .

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

# 로그 디렉토리 생성 및 권한 설정
RUN mkdir -p /srv/logs/app/archive && \
    chmod -R 755 /srv/logs/app

# 빌드된 JAR 파일 복사
COPY --from=builder /app/${MODULE_NAME}/build/libs/${MODULE_NAME}.jar app.jar

# 헬스체크 (포트는 환경변수로 받음, 기본값: 8080)
ENV SERVER_PORT=8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${SERVER_PORT}/ || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
