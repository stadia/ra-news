# frozen_string_literal: true

# PostGIS 확장이 관리하는 spatial_ref_sys 테이블을 schema dump에서 제외.
# PostGIS를 설치한 데이터베이스에서 schema.rb를 덤프할 때 충돌을 방지한다.
ActiveRecord::SchemaDumper.ignore_tables << "spatial_ref_sys" if defined?(ActiveRecord::SchemaDumper)
