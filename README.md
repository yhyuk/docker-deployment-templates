# Docker Deployment Templates

Spring Boot, React, Next.js 프로젝트를 위한 **프로덕션 레디** Docker 배포 템플릿 모음입니다.

각 템플릿은 Multi-stage 빌드, non-root 실행, Health check, 리소스 제한 등 운영 환경에 필요한 보안/안정성 설정이 적용되어 있습니다.

## 프로젝트 구조

```
docker-deployment-templates/
├── spring-boot/             # Spring Boot + MySQL
│   ├── Dockerfile           # Multi-stage build (JDK 21)
│   ├── docker-compose.yml   # App + MySQL 구성
│   ├── deploy.sh            # 배포 자동화
│   ├── .dockerignore
│   ├── .env.example
│   └── README.md            # 상세 사용 가이드
├── react/                   # React + Nginx
│   ├── Dockerfile           # Production (Nginx 서빙)
│   ├── Dockerfile.dev       # Development (Hot reload)
│   ├── nginx.conf           # SPA 라우팅, Gzip, 보안 헤더
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   ├── deploy.sh
│   ├── .dockerignore
│   ├── .env.example
│   └── README.md            # 상세 사용 가이드
├── nextjs/                  # Next.js (Standalone)
│   ├── Dockerfile           # Standalone 모드 빌드
│   ├── Dockerfile.dev       # Development (Hot reload)
│   ├── next.config.js       # Standalone 설정 예시
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   ├── deploy.sh
│   ├── .dockerignore
│   ├── .env.example
│   └── README.md            # 상세 사용 가이드
└── scripts/                 # 유틸리티 스크립트
    ├── health-check.sh      # 컨테이너 헬스체크
    ├── backup-db.sh         # MySQL 백업
    └── restore-db.sh        # MySQL 복구
```

> 각 템플릿 디렉토리의 README.md에서 환경변수 상세, 트러블슈팅, Yarn/Vite 전환 등 더 자세한 가이드를 확인할 수 있습니다.

## 템플릿별 특징

### Spring Boot

| 항목 | 내용 |
|------|------|
| 베이스 이미지 | `eclipse-temurin:21-jdk-alpine` (빌드) / `eclipse-temurin:21-jre-alpine` (실행) |
| 빌드 방식 | Gradle Multi-stage, 멀티모듈 지원 (`MODULE_NAME` 인자) |
| DB | MySQL 8.0 (Health check, UTF-8, 볼륨 영속화) |
| 보안 | non-root 실행, DB 포트 외부 미노출 |
| JVM | `-XX:+UseContainerSupport`, `MaxRAMPercentage=75%` |
| 기타 | Graceful shutdown, 로그 볼륨 마운트, 리소스 제한 |

```bash
cd spring-boot
cp .env.example .env    # DB_PASSWORD, DB_ROOT_PASSWORD 설정
./deploy.sh api-sample prod
```

### React

| 항목 | 내용 |
|------|------|
| 베이스 이미지 | `node:20-alpine` (빌드) / `nginxinc/nginx-unprivileged:alpine` (실행) |
| 빌드 방식 | npm ci + 정적 빌드, Nginx로 서빙 |
| Nginx | SPA 라우팅, Gzip 압축, 정적 파일 1년 캐싱, API 프록시(선택) |
| 보안 | non-root Nginx, X-Frame-Options, X-Content-Type-Options, XSS-Protection 등 |
| 개발 환경 | `Dockerfile.dev` + `docker-compose.dev.yml`로 Hot reload 지원 |

```bash
cd react
cp .env.example .env    # API_URL 설정
./deploy.sh dev         # 개발 환경 (Hot reload)
./deploy.sh prod        # 프로덕션 배포
```

### Next.js

| 항목 | 내용 |
|------|------|
| 베이스 이미지 | `node:20-alpine` |
| 빌드 방식 | Standalone 모드 (`output: 'standalone'`) |
| 장점 | node_modules 미포함으로 경량 이미지, `node server.js`로 독립 실행 |
| 보안 | non-root 실행 (nextjs:nodejs 유저) |
| 라우터 | Pages Router, App Router 모두 지원 |
| 개발 환경 | `Dockerfile.dev` + `docker-compose.dev.yml`로 Hot reload 지원 |

```bash
cd nextjs
cp .env.example .env    # API_URL 설정
./deploy.sh dev         # 개발 환경 (Hot reload)
./deploy.sh prod        # 프로덕션 배포
```

## 유틸리티 스크립트

### 컨테이너 헬스체크

```bash
# 모든 실행 중인 컨테이너 확인
./scripts/health-check.sh

# 특정 컨테이너만 확인
./scripts/health-check.sh spring-app mysql
```

컨테이너 상태, 포트, CPU/메모리 사용량을 한눈에 확인할 수 있습니다.

### DB 백업 / 복구

```bash
# 백업 (gzip 압축, 7일 이상 자동 삭제)
DB_PASSWORD=yourpassword ./scripts/backup-db.sh mysql app_db

# 복구
DB_PASSWORD=yourpassword ./scripts/restore-db.sh backups/app_db_20240305_120000.sql.gz mysql app_db
```

## 프로젝트에 적용하기

### 1. 필요한 템플릿 복사

```bash
# 예: Spring Boot 프로젝트
cp spring-boot/{Dockerfile,docker-compose.yml,deploy.sh,.env.example,.dockerignore} /path/to/your-project/
```

### 2. 환경에 맞게 수정

- **Spring Boot**: `docker-compose.yml`의 `MODULE_NAME`을 실제 모듈명으로 변경
- **React**: `nginx.conf`의 API 프록시 설정 (필요 시)
- **Next.js**: `next.config.js`에 `output: 'standalone'` 추가

### 3. 환경변수 설정 후 배포

```bash
cp .env.example .env
# .env 파일 편집 후
./deploy.sh prod
```

## 공통 적용 사항

모든 템플릿에 다음 설정이 포함되어 있습니다:

- **Multi-stage 빌드** - 빌드 도구가 최종 이미지에 포함되지 않아 이미지 경량화
- **non-root 실행** - 컨테이너 내부에서 루트 권한 미사용
- **Health check** - Docker 레벨의 헬스체크로 컨테이너 상태 모니터링
- **리소스 제한** - CPU/메모리 limits, reservations 설정
- **로그 관리** - json-file 드라이버, 크기/파일 수 제한
- **Graceful shutdown** - 안전한 컨테이너 종료
- **.dockerignore** - 불필요한 파일 빌드 컨텍스트 제외

## 요구 사항

- Docker 20.10+
- Docker Compose v2+

## 참고 자료

- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
- [Spring Boot Docker 가이드](https://spring.io/guides/gs/spring-boot-docker/)
- [Next.js Docker 가이드](https://nextjs.org/docs/deployment#docker-image)
