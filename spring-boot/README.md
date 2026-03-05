# Spring Boot Docker Template

Spring Boot 멀티모듈 프로젝트를 위한 Docker 배포 템플릿입니다.

## 파일 구성

```
spring-boot/
├── Dockerfile           # Multi-stage build Dockerfile
├── docker-compose.yml   # Spring Boot + MySQL 구성
├── deploy.sh           # 배포 자동화 스크립트
├── .env.example        # 환경변수 템플릿
└── README.md
```

## 사용 방법

### 1. 환경 설정

```bash
# .env 파일 생성
cp .env.example .env

# 필요에 따라 환경변수 수정
vi .env
```

### 2. 배포

```bash
# 실행 권한 부여
chmod +x deploy.sh

# 기본 배포 (api-sample 모듈, prod 프로필)
./deploy.sh

# 특정 모듈 배포
./deploy.sh api-admin prod

# 개발 환경 배포
./deploy.sh api-sample dev
```

### 3. 수동 실행

```bash
# 빌드 및 실행
docker-compose up -d --build

# 로그 확인
docker-compose logs -f app

# 중지
docker-compose down

# 볼륨까지 삭제
docker-compose down -v
```

## Dockerfile 특징

### Build Stage
- `gradle:8.5-jdk21-alpine` 베이스 이미지
- Gradle 캐시 최적화를 위한 레이어 구조
- 멀티모듈 프로젝트 지원
- `MODULE_NAME` 빌드 인자로 특정 모듈 빌드

### Runtime Stage
- `eclipse-temurin:21-jre-alpine` 경량 이미지
- 로그 디렉토리 자동 생성
- Health check 내장
- 환경변수로 포트 설정 가능

## 환경변수

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `SERVER_PORT` | 애플리케이션 포트 | 8080 |
| `SPRING_PROFILE` | Spring Profile | prod |
| `DB_NAME` | 데이터베이스 이름 | app_db |
| `DB_USER` | 데이터베이스 사용자 | root |
| `DB_PASSWORD` | 데이터베이스 비밀번호 | password |
| `DB_PORT` | 데이터베이스 포트 | 3306 |
| `JPA_DDL_AUTO` | JPA DDL 설정 | validate |
| `JPA_SHOW_SQL` | SQL 로그 출력 여부 | false |

## 프로젝트에 적용하기

### 1. Dockerfile 복사

```bash
# 프로젝트 루트에 복사
cp docker-deployment-templates/spring-boot/Dockerfile your-project/

# 또는 docker 디렉토리 생성
mkdir your-project/docker
cp docker-deployment-templates/spring-boot/* your-project/docker/
```

### 2. docker-compose.yml 수정

```yaml
# MODULE_NAME을 실제 모듈명으로 변경
build:
  args:
    MODULE_NAME: your-api-module
```

### 3. 배포

```bash
cd your-project/docker
./deploy.sh your-api-module prod
```

## Tips

### 다른 모듈 배포

멀티모듈 프로젝트에서 여러 API 모듈을 배포할 경우:

```bash
# api-admin 배포
./deploy.sh api-admin prod

# api-customer 배포
./deploy.sh api-customer prod
```

### 로그 확인

```bash
# 실시간 로그
docker-compose logs -f app

# 최근 100줄
docker-compose logs --tail=100 app

# 호스트 디렉토리에 저장된 로그
tail -f ./logs/application.log
```

### Health Check

```bash
# 컨테이너 상태 확인
docker ps

# Health check 로그
docker inspect --format='{{json .State.Health}}' spring-app
```

### 데이터베이스 초기화

초기 SQL 스크립트를 실행하려면 `init.sql` 파일을 생성:

```sql
-- init.sql
CREATE TABLE IF NOT EXISTS sample (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 트러블슈팅

### 포트 충돌

```bash
# .env 파일에서 포트 변경
SERVER_PORT=8081
DB_PORT=3307
```

### 빌드 실패

```bash
# 캐시 없이 재빌드
docker-compose build --no-cache
```

### 데이터베이스 연결 실패

```bash
# MySQL 컨테이너 로그 확인
docker-compose logs mysql

# Health check 확인
docker-compose ps
```
