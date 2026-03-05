# React Docker Template

React 프로젝트를 위한 Docker 배포 템플릿입니다.

## 파일 구성

```
react/
├── Dockerfile              # Production 빌드 (Nginx)
├── Dockerfile.dev          # Development 빌드 (Hot reload)
├── nginx.conf             # Nginx 설정
├── docker-compose.yml     # Production 구성
├── docker-compose.dev.yml # Development 구성
├── deploy.sh              # 배포 자동화 스크립트
├── .env.example           # 환경변수 템플릿
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

### 2. 개발 환경 실행

```bash
# 실행 권한 부여
chmod +x deploy.sh

# 개발 서버 시작 (Hot reload 지원)
./deploy.sh dev

# 또는 직접 실행
docker-compose -f docker-compose.dev.yml up
```

### 3. 프로덕션 배포

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
- npm ci로 의존성 설치 (캐시 최적화)
- 환경변수 주입 (빌드 타임)
- Production 빌드 생성

**Runtime Stage:**
- `nginx:alpine` 경량 이미지
- 정적 파일 서빙
- Gzip 압축
- SPA 라우팅 지원
- 보안 헤더 적용
- Health check 내장

### Development (Dockerfile.dev)

- Hot reload 지원
- Volume 마운트로 실시간 코드 반영
- 개발 의존성 포함
- 포트 3000 노출

## 환경변수

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `APP_PORT` | 애플리케이션 포트 | 80 (prod), 3000 (dev) |
| `API_URL` | 백엔드 API URL | http://localhost:8080 |

## Nginx 설정 특징

- **SPA 라우팅**: `try_files`로 모든 경로를 index.html로 리디렉션
- **정적 파일 캐싱**: 이미지, CSS, JS 등 1년 캐시
- **Gzip 압축**: 파일 크기 최적화
- **API 프록시**: /api 경로를 백엔드로 프록시 (선택사항)
- **보안 헤더**: XSS, Clickjacking 방지

## 프로젝트에 적용하기

### 1. 파일 복사

```bash
# React 프로젝트 루트에 복사
cp docker-deployment-templates/react/* your-react-project/
```

### 2. package.json 확인

빌드 스크립트가 있는지 확인:

```json
{
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  }
}
```

### 3. 환경변수 설정

React 환경변수는 `REACT_APP_` 접두사 필요:

```env
# .env
REACT_APP_API_URL=http://localhost:8080
REACT_APP_VERSION=1.0.0
```

### 4. 배포

```bash
# 개발 환경
./deploy.sh dev

# 프로덕션 배포
./deploy.sh prod
```

## 개발 환경 (Hot Reload)

개발 환경에서는 소스 코드가 volume으로 마운트되어 실시간 반영됩니다:

```yaml
volumes:
  - .:/app                # 현재 디렉토리를 /app에 마운트
  - /app/node_modules     # node_modules는 컨테이너 것 사용
```

### 실행

```bash
# docker-compose.dev.yml 사용
docker-compose -f docker-compose.dev.yml up

# 로그 확인
docker-compose -f docker-compose.dev.yml logs -f
```

## API 프록시 설정

백엔드 API를 프록시하려면 `nginx.conf` 수정:

```nginx
location /api {
    proxy_pass http://backend-service:8080;
    # 또는 외부 URL
    # proxy_pass http://api.example.com;
}
```

## Yarn 사용

npm 대신 yarn을 사용하는 경우:

### Dockerfile 수정

```dockerfile
# package.json 복사
COPY package.json yarn.lock ./

# 의존성 설치
RUN yarn install --frozen-lockfile --production

# 빌드
RUN yarn build
```

### Dockerfile.dev 수정

```dockerfile
RUN yarn install
CMD ["yarn", "start"]
```

## Create React App 외 다른 빌더

### Vite

```dockerfile
# 빌드 명령어 변경
RUN npm run build

# 빌드 결과물 경로 변경
COPY --from=builder /app/dist .
```

### Next.js

별도의 Next.js 템플릿 사용 권장

## Tips

### 빌드 크기 최적화

```dockerfile
# .dockerignore 파일 생성
node_modules
.git
.env.local
README.md
*.log
```

### 멀티 스테이지 빌드 캐싱

```bash
# 빌더 스테이지만 캐시
docker build --target builder -t react-builder .
```

### 로그 확인

```bash
# 실시간 로그
docker-compose logs -f react-app

# Nginx 접근 로그
docker exec react-app tail -f /var/log/nginx/access.log
```

## 트러블슈팅

### 빌드 실패

```bash
# 캐시 없이 재빌드
docker-compose build --no-cache
```

### 환경변수가 적용되지 않음

React는 빌드 타임에 환경변수가 주입됩니다:

```bash
# 환경변수 확인
docker build --build-arg REACT_APP_API_URL=http://api.example.com .
```

### SPA 라우팅 404 에러

`nginx.conf`의 `try_files` 설정 확인:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### Hot Reload가 작동하지 않음

`CHOKIDAR_USEPOLLING=true` 환경변수 추가:

```yaml
environment:
  - CHOKIDAR_USEPOLLING=true
```
