# Next.js Docker Template

Next.js 프로젝트를 위한 Docker 배포 템플릿입니다.

## 파일 구성

```
nextjs/
├── Dockerfile              # Production 빌드 (Standalone)
├── Dockerfile.dev          # Development 빌드 (Hot reload)
├── next.config.js          # Next.js 설정 (Standalone 모드)
├── docker-compose.yml      # Production 구성
├── docker-compose.dev.yml  # Development 구성
├── deploy.sh               # 배포 자동화 스크립트
├── .env.example            # 환경변수 템플릿
└── README.md
```

## 사용 방법

### 1. 환경 설정

```bash
# .env 파일 생성
cp .env.example .env

# 환경변수 수정
vi .env
```

### 2. Next.js 설정 적용

`next.config.js` 파일을 프로젝트에 복사하거나 기존 설정에 병합:

```javascript
// next.config.js
const nextConfig = {
  output: 'standalone',  // 중요: Docker 최적화
}
```

### 3. 개발 환경 실행

```bash
# 실행 권한 부여
chmod +x deploy.sh

# 개발 서버 시작 (Hot reload 지원)
./deploy.sh dev

# 또는 직접 실행
docker-compose -f docker-compose.dev.yml up
```

### 4. 프로덕션 배포

```bash
# 배포
./deploy.sh prod

# 또는 직접 실행
docker-compose up -d --build
```

## Dockerfile 특징

### Production (Dockerfile)

**Build Stage:**
- `node:20-alpine` 베이스 이미지
- npm ci로 의존성 설치
- 환경변수 주입 (빌드 타임)
- Standalone 모드로 빌드

**Runtime Stage:**
- 최소 파일만 복사 (standalone)
- Non-root 유저 실행 (보안)
- 최적화된 경량 이미지
- Health check 내장

### Development (Dockerfile.dev)

- Hot reload 지원
- Volume 마운트로 실시간 코드 반영
- 개발 의존성 포함
- 포트 3000 노출

## Standalone 모드란?

Next.js의 Standalone 모드는 Docker 배포를 위한 최적화 기능입니다:

- **작은 이미지 크기**: 필요한 파일만 포함
- **빠른 빌드**: node_modules 전체를 복사하지 않음
- **독립 실행**: 단일 `node server.js`로 실행

### 활성화 방법

```javascript
// next.config.js
module.exports = {
  output: 'standalone',
}
```

## 환경변수

### 클라이언트 환경변수 (NEXT_PUBLIC_*)

Next.js에서 브라우저에서 접근 가능한 환경변수는 `NEXT_PUBLIC_` 접두사 필요:

```env
# .env
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_APP_VERSION=1.0.0
```

사용:

```javascript
const apiUrl = process.env.NEXT_PUBLIC_API_URL
```

### 서버 환경변수

서버에서만 사용하는 환경변수는 접두사 불필요:

```env
DATABASE_URL=postgresql://...
API_SECRET=your-secret
```

## Health Check API 추가

Health check가 작동하려면 `/api/health` 엔드포인트 필요:

```javascript
// pages/api/health.js (Pages Router)
export default function handler(req, res) {
  res.status(200).json({ status: 'ok' })
}

// app/api/health/route.js (App Router)
export async function GET() {
  return Response.json({ status: 'ok' })
}
```

## 프로젝트에 적용하기

### 1. 파일 복사

```bash
# Next.js 프로젝트 루트에 복사
cp docker-deployment-templates/nextjs/{Dockerfile,Dockerfile.dev,docker-compose.yml,docker-compose.dev.yml,deploy.sh,.env.example} your-nextjs-project/
```

### 2. next.config.js 수정

기존 설정에 `output: 'standalone'` 추가:

```javascript
const nextConfig = {
  output: 'standalone',
  // 기존 설정...
}
```

### 3. .dockerignore 생성

```
node_modules
.next
.git
.env.local
*.log
README.md
```

### 4. 배포

```bash
# 개발 환경
./deploy.sh dev

# 프로덕션 배포
./deploy.sh prod
```

## Pages Router vs App Router

두 방식 모두 동일한 Dockerfile로 작동합니다.

### Pages Router 구조

```
pages/
├── api/
│   └── health.js
├── _app.js
└── index.js
```

### App Router 구조

```
app/
├── api/
│   └── health/
│       └── route.js
├── layout.js
└── page.js
```

## 환경별 설정

### 개발 환경 (docker-compose.dev.yml)

- Hot reload 활성화
- Volume 마운트
- 개발 서버 실행

### 프로덕션 환경 (docker-compose.yml)

- Standalone 빌드
- 최적화된 이미지
- Production 모드 실행

## API Routes와 SSR

Next.js의 API Routes와 SSR은 Node.js 서버가 필요하므로 Nginx만으로는 부족합니다.
따라서 이 템플릿은 Node.js 서버를 사용합니다.

## Image Optimization

Next.js의 이미지 최적화를 사용하려면:

```javascript
// next.config.js
module.exports = {
  images: {
    domains: ['your-cdn.com', 'localhost'],
  },
}
```

외부 이미지 최적화 서비스 사용 시:

```javascript
module.exports = {
  images: {
    loader: 'cloudinary',
    path: 'https://your-cdn.com/',
  },
}
```

## Yarn 사용

npm 대신 yarn을 사용하는 경우:

### Dockerfile 수정

```dockerfile
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
RUN yarn build
```

### Dockerfile.dev 수정

```dockerfile
RUN yarn install
CMD ["yarn", "dev"]
```

## Tips

### 빌드 크기 확인

```bash
# 빌드 후 이미지 크기 확인
docker images nextjs-app:latest

# 레이어별 크기 확인
docker history nextjs-app:latest
```

### 로그 확인

```bash
# 실시간 로그
docker-compose logs -f nextjs-app

# 최근 100줄
docker-compose logs --tail=100 nextjs-app
```

### 환경변수 디버깅

빌드 시 환경변수가 올바르게 주입되었는지 확인:

```bash
docker build --build-arg NEXT_PUBLIC_API_URL=http://test.com . --no-cache
```

## 트러블슈팅

### Standalone 빌드 실패

`next.config.js`에 `output: 'standalone'` 추가 확인

### 환경변수가 undefined

- 클라이언트 변수는 `NEXT_PUBLIC_` 접두사 필요
- 빌드 타임에 환경변수가 주입되므로 재빌드 필요

### Hot Reload가 작동하지 않음

`WATCHPACK_POLLING=true` 환경변수 추가:

```yaml
environment:
  - WATCHPACK_POLLING=true
```

### 이미지 최적화 에러

외부 도메인 사용 시 `next.config.js`에 도메인 추가:

```javascript
images: {
  domains: ['your-domain.com'],
}
```

또는 최적화 비활성화:

```javascript
images: {
  unoptimized: true,
}
```

### Health check 실패

`/api/health` 엔드포인트 구현 확인

## 성능 최적화

### 1. 멀티 스테이지 캐싱

```bash
# Dependencies layer 캐싱
docker build --target deps -t nextjs-deps .
```

### 2. 빌드 캐시 활용

```bash
# BuildKit 캐시
DOCKER_BUILDKIT=1 docker build --cache-from nextjs-app:latest .
```

### 3. 불필요한 파일 제외

`.dockerignore` 파일 활용:

```
.git
.next
node_modules
*.md
.env.local
```
