#!/bin/bash
# PostgreSQL 테스트 환경 확장 설치 스크립트
# macOS + Postgres.app 15 + Apple Silicon (arm64) 전용
set -e

PG_CONFIG=/Applications/Postgres.app/Contents/Versions/15/bin/pg_config
PG_EXT_DIR=/Applications/Postgres.app/Contents/Versions/15/share/postgresql/extension
PG_LIB_DIR=/Applications/Postgres.app/Contents/Versions/15/lib/postgresql
DB_USER=jeff.dean
DEV_DB=ra-news_development
TEST_DB=ra-news_test

echo "=== 1/5 pg_bigm 설치 ==="
if [ ! -f "$PG_LIB_DIR/pg_bigm.so" ]; then
  cd /tmp
  rm -rf pg_bigm
  git clone --depth 1 https://github.com/pgbigm/pg_bigm.git
  cd pg_bigm
  make USE_PGXS=1 PG_CONFIG=$PG_CONFIG
  make install USE_PGXS=1 PG_CONFIG=$PG_CONFIG
  echo "pg_bigm 설치 완료"
else
  echo "pg_bigm 이미 설치됨"
fi

echo "=== 2/5 textsearch_ko 설치 ==="
if [ ! -f "$PG_LIB_DIR/ts_mecab_ko.so" ]; then
  if [ ! -d /tmp/textsearch_ko ]; then
    cd /tmp
    git clone --depth 1 https://github.com/i0seph/textsearch_ko.git
  fi
  cd /tmp/textsearch_ko

  # Postgres.app은 universal binary로 빌드하지만 mecab-ko는 arm64-only.
  # .o 파일 빌드 후 arm64 전용으로 수동 링크.
  make clean 2>/dev/null || true
  make USE_PGXS=1 PG_CONFIG=$PG_CONFIG 2>/dev/null || true

  gcc -Wall -arch arm64 \
    -bundle -o ts_mecab_ko.so ts_mecab_ko.o \
    -L$PG_CONFIG/../../lib \
    -L/opt/homebrew/Cellar/mecab-ko/*/lib \
    -lmecab -lstdc++ \
    -bundle_loader $PG_CONFIG/../../bin/postgres

  cp ts_mecab_ko.so $PG_LIB_DIR/
  cp textsearch_ko.control $PG_EXT_DIR/
  cp textsearch_ko--1.0.sql ts_mecab_ko.sql $PG_EXT_DIR/
  echo "textsearch_ko 설치 완료"
else
  echo "textsearch_ko 이미 설치됨"
fi

echo "=== 3/5 개발 DB 확장 활성화 ==="
psql -U $DB_USER -d $DEV_DB -c "CREATE EXTENSION IF NOT EXISTS pg_bigm" 2>/dev/null || true
psql -U $DB_USER -d $DEV_DB -c "CREATE EXTENSION IF NOT EXISTS textsearch_ko" 2>/dev/null || true
psql -U $DB_USER -d $DEV_DB -c "CREATE EXTENSION IF NOT EXISTS postgis" 2>/dev/null || true
echo "개발 DB 확장 활성화 완료"

echo "=== 4/5 schema.rb 정합성 보장 ==="
# spatial_ref_sys는 PostGIS 관리 테이블이므로 schema dump에서 제외
if [ ! -f config/initializers/schema_dumper_ignore.rb ]; then
  cat > config/initializers/schema_dumper_ignore.rb << 'RUBY'
# frozen_string_literal: true
ActiveRecord::SchemaDumper.ignore_tables << "spatial_ref_sys" if defined?(ActiveRecord::SchemaDumper)
RUBY
  echo "schema_dumper_ignore.rb 생성 완료"
fi

echo "=== 5/5 테스트 DB 재구성 ==="
psql -U $DB_USER -d postgres -c "DROP DATABASE IF EXISTS \"$TEST_DB\"" 2>/dev/null || true
psql -U $DB_USER -d postgres -c "CREATE DATABASE \"$TEST_DB\"" 2>/dev/null || true
RAILS_ENV=test bin/rails db:schema:load
RAILS_ENV=test bin/rails db:migrate 2>/dev/null || true
echo "테스트 DB 재구성 완료"

echo ""
echo "=== 설치 완료 ==="
echo "실행: bin/rails test"
