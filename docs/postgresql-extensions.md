# PostgreSQL 확장 설치 가이드 (macOS)

## 개요

Ruby-News 프로젝트는 한국어 전문 검색 및 벡터 검색을 위해 다음 PostgreSQL 확장이 필요합니다:

- **pg_bigm**: 바이그램 기반 전문 검색
- **textsearch_ko**: 한국어 형태소 분석 (mecab-ko 기반)
- **pgvector**: 벡터 임베딩 및 유사도 검색

## 전제 조건

- macOS (Apple Silicon 또는 Intel)
- Homebrew 설치
- PostgreSQL 14 설치 (`brew install postgresql@14`)

## 빠른 시작

```bash
# 1. PostgreSQL 확장 디렉토리로 이동
cd /tmp

# 2. pg_bigm 설치
git clone https://github.com/pgbigm/pg_bigm.git
cd pg_bigm
make USE_PGXS=1
sudo make install USE_PGXS=1
cd ..

# 3. mecab-ko 및 사전 설치
brew unlink mecab  # 기존 mecab이 있다면
brew install mecab-ko-dic
echo "dicdir = /opt/homebrew/lib/mecab/dic/mecab-ko-dic" | sudo tee /opt/homebrew/etc/mecabrc

# 4. textsearch_ko 설치 (패치 필요)
git clone https://github.com/i0seph/textsearch_ko.git
cd textsearch_ko

# 4-1. mecab 설정 경로 패치 적용
cat > patch.txt << 'EOF'
--- ts_mecab_ko.c.orig	2025-11-19 16:00:00.000000000 +0900
+++ ts_mecab_ko.c	2025-11-19 16:00:00.000000000 +0900
@@ -145,8 +145,8 @@
 {
 	if (_mecab == NULL)
 	{
-		int			argc = 1;
-		char	   *argv[] = { "mecab" };
+		int			argc = 5;
+		char	   *argv[] = { "mecab", "-r", "/opt/homebrew/etc/mecabrc", "-d", "/opt/homebrew/lib/mecab/dic/mecab-ko-dic" };
 		_mecab = mecab_new(argc, argv);
 		mecab_assert(_mecab);
 	}
EOF

patch ts_mecab_ko.c < patch.txt

# 4-2. 빌드 및 설치
make USE_PGXS=1
sudo make install USE_PGXS=1

# 5. PostgreSQL 재시작
brew services restart postgresql@14

# 6. 마이그레이션 실행
cd /path/to/ra-news
bin/rails db:migrate
```

## 상세 설치 과정

### 1. pg_bigm 설치

pg_bigm은 바이그램을 사용한 전문 검색 확장으로, 한국어를 포함한 다국어 검색에 유용합니다.

```bash
cd /tmp
git clone https://github.com/pgbigm/pg_bigm.git
cd pg_bigm
make USE_PGXS=1
sudo make install USE_PGXS=1
```

### 2. mecab-ko 및 사전 설치

textsearch_ko는 mecab-ko (한국어 형태소 분석기)를 사용합니다.

```bash
# 기존 mecab과 충돌 방지
brew unlink mecab

# mecab-ko와 한국어 사전 설치
brew install mecab-ko-dic

# mecab 설정 파일 생성
echo "dicdir = /opt/homebrew/lib/mecab/dic/mecab-ko-dic" | sudo tee /opt/homebrew/etc/mecabrc
```

**확인:**
```bash
mecab --version
# mecab of 0.996/ko-0.9.2

echo "테스트" | mecab
# 테스트	NNG,행위,F,테스트,*,*,*,*
# EOS
```

### 3. textsearch_ko 소스 빌드 및 패치

textsearch_ko는 PostgreSQL이 mecab 설정을 찾을 수 있도록 소스 코드 패치가 필요합니다.

```bash
cd /tmp
git clone https://github.com/i0seph/textsearch_ko.git
cd textsearch_ko
```

**패치 파일 생성 및 적용:**

`ts_mecab_ko.c` 파일의 `_PG_init` 함수에서 mecab 초기화 시 설정 파일 경로를 명시적으로 지정해야 합니다.

```bash
cat > patch.txt << 'EOF'
--- ts_mecab_ko.c.orig	2025-11-19 16:00:00.000000000 +0900
+++ ts_mecab_ko.c	2025-11-19 16:00:00.000000000 +0900
@@ -145,8 +145,8 @@
 {
 	if (_mecab == NULL)
 	{
-		int			argc = 1;
-		char	   *argv[] = { "mecab" };
+		int			argc = 5;
+		char	   *argv[] = { "mecab", "-r", "/opt/homebrew/etc/mecabrc", "-d", "/opt/homebrew/lib/mecab/dic/mecab-ko-dic" };
 		_mecab = mecab_new(argc, argv);
 		mecab_assert(_mecab);
 	}
EOF

patch ts_mecab_ko.c < patch.txt
```

**빌드 및 설치:**

```bash
make USE_PGXS=1
sudo make install USE_PGXS=1
```

### 4. PostgreSQL 재시작

확장이 제대로 로드되도록 PostgreSQL을 재시작합니다.

```bash
brew services restart postgresql@14

# 재시작 확인
brew services list | grep postgresql@14
# postgresql@14 started
```

### 5. 마이그레이션 실행

```bash
cd /path/to/ra-news
bin/rails db:migrate
```

## 트러블슈팅

### "mecab:" 오류

**증상:**
```
PG::ExternalRoutineException: ERROR:  mecab:
```

**원인:** PostgreSQL 프로세스가 mecab 설정 파일이나 사전을 찾지 못함

**해결방법:**
1. mecabrc 파일이 올바른 위치에 있는지 확인:
   ```bash
   cat /opt/homebrew/etc/mecabrc
   # dicdir = /opt/homebrew/lib/mecab/dic/mecab-ko-dic
   ```

2. 사전 파일이 존재하는지 확인:
   ```bash
   ls /opt/homebrew/lib/mecab/dic/mecab-ko-dic/
   # char.bin  dicrc  left-id.def  matrix.bin  model.bin  pos-id.def  rewrite.def  ...
   ```

3. textsearch_ko 패치가 제대로 적용되었는지 확인:
   ```bash
   grep -A 3 'int.*argc.*=' /tmp/textsearch_ko/ts_mecab_ko.c | grep -A 2 '_PG_init' -A 10
   # argc = 5 와 mecabrc 경로가 포함되어 있어야 함
   ```

4. 패치를 다시 적용하고 재빌드:
   ```bash
   cd /tmp/textsearch_ko
   cp ts_mecab_ko.c.bak ts_mecab_ko.c  # 백업이 있다면
   # 패치 재적용
   make USE_PGXS=1
   sudo make install USE_PGXS=1
   brew services restart postgresql@14
   ```

### "could not open extension control file" 오류

**증상:**
```
ERROR:  could not open extension control file "/opt/homebrew/share/postgresql@14/extension/pg_bigm.control": No such file or directory
```

**원인:** 확장이 제대로 설치되지 않음

**해결방법:**
```bash
# 확장 파일 존재 확인
ls /opt/homebrew/share/postgresql@14/extension/pg_bigm.control
ls /opt/homebrew/share/postgresql@14/extension/textsearch_ko.control

# 없다면 해당 확장 재설치
cd /tmp/pg_bigm  # 또는 /tmp/textsearch_ko
sudo make install USE_PGXS=1
```

### mecab과 mecab-ko 충돌

**증상:**
```
Error: Cannot install mecab-ko because conflicting formulae are installed.
  mecab: because both install mecab binaries
```

**해결방법:**
```bash
brew unlink mecab
brew install mecab-ko-dic
```

### Intel Mac에서 경로 차이

Intel Mac에서는 Homebrew 경로가 다릅니다:
- Apple Silicon: `/opt/homebrew`
- Intel: `/usr/local`

패치 파일의 경로를 Intel Mac 기준으로 수정:
```c
char *argv[] = { "mecab", "-r", "/usr/local/etc/mecabrc", "-d", "/usr/local/lib/mecab/dic/mecab-ko-dic" };
```

### PostgreSQL 로그 확인

문제 발생 시 PostgreSQL 로그를 확인:
```bash
tail -f /opt/homebrew/var/log/postgresql@14.log
```

## 다른 플랫폼

### Linux (Ubuntu/Debian)

```bash
# PostgreSQL 개발 패키지
sudo apt-get install postgresql-server-dev-14

# mecab-ko 설치
sudo apt-get install mecab libmecab-dev
# 또는 소스에서 빌드

# 나머지는 macOS와 동일
```

### Docker 환경

프로젝트에 `Dockerfile` 또는 `docker-compose.yml`이 있다면 확장 설치를 자동화할 수 있습니다:

```dockerfile
FROM postgres:14

# pg_bigm 설치
RUN apt-get update && apt-get install -y \
    build-essential \
    postgresql-server-dev-14 \
    git

RUN cd /tmp && \
    git clone https://github.com/pgbigm/pg_bigm.git && \
    cd pg_bigm && \
    make USE_PGXS=1 && \
    make install USE_PGXS=1

# mecab-ko 및 textsearch_ko 설치
# (추가 작업 필요)
```

## 검증

모든 확장이 제대로 설치되었는지 확인:

```bash
# Rails 콘솔에서
bin/rails runner "
  puts ActiveRecord::Base.connection.execute(\"
    SELECT * FROM pg_available_extensions 
    WHERE name IN ('pg_bigm', 'textsearch_ko', 'vector')
  \").to_a
"
```

또는 psql에서:
```sql
\dx
-- 설치된 확장 목록 확인

SELECT * FROM pg_available_extensions 
WHERE name IN ('pg_bigm', 'textsearch_ko', 'vector');
```

## 참고 자료

- [pg_bigm GitHub](https://github.com/pgbigm/pg_bigm)
- [textsearch_ko GitHub](https://github.com/i0seph/textsearch_ko)
- [mecab-ko-dic](https://github.com/bibreen/mecab-ko-dic)
- [pgvector](https://github.com/pgvector/pgvector)

## 기여

설치 과정에서 문제를 발견하거나 개선사항이 있다면 이슈나 PR을 환영합니다.
