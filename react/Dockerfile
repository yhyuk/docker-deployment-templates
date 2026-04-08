# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# package.json과 lock 파일 복사 (캐싱 최적화)
COPY package*.json ./
# yarn을 사용하는 경우
# COPY package.json yarn.lock ./

# 의존성 설치 (빌드에 devDependencies 필요)
RUN npm ci
# yarn을 사용하는 경우
# RUN yarn install --frozen-lockfile

# 소스 코드 복사
COPY . .

# 환경변수 설정 (빌드 타임)
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# 프로덕션 빌드
RUN npm run build
# yarn을 사용하는 경우
# RUN yarn build

# Runtime stage - Nginx로 정적 파일 서빙 (non-root)
FROM nginxinc/nginx-unprivileged:alpine

WORKDIR /usr/share/nginx/html

# 기존 파일 삭제
USER root
RUN rm -rf ./*
USER nginx

# 빌드된 파일 복사
COPY --from=builder --chown=nginx:nginx /app/build .

# Nginx 설정 파일 복사
COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
