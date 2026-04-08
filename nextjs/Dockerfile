# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# package.json과 lock 파일 복사
COPY package*.json ./
# yarn을 사용하는 경우
# COPY package.json yarn.lock ./

# 의존성 설치
RUN npm ci
# yarn을 사용하는 경우
# RUN yarn install --frozen-lockfile

# 소스 코드 복사
COPY . .

# 환경변수 설정 (빌드 타임)
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Next.js 빌드 (standalone 모드)
RUN npm run build
# yarn을 사용하는 경우
# RUN yarn build

# Runtime stage
FROM node:20-alpine AS runner

WORKDIR /app

# 보안을 위한 non-root 유저 생성
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# 필요한 파일만 복사 (standalone 모드)
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

# 환경변수
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# 헬스체크 (범용: 루트 경로 확인. /api/health 엔드포인트가 있으면 해당 경로로 변경 권장)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/', (r) => {process.exit(r.statusCode < 400 ? 0 : 1)}).on('error', () => process.exit(1))"

CMD ["node", "server.js"]
