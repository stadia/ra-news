# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  class DataPrepperAgent < ApplicationAgent
    description "Raw 콘텐츠를 정제하고 의미 단위로 청킹"
    version "1.0"
    timeout 240

    param :raw_content, required: true
    param :title, required: true
    param :url, required: true
    param :content_type, default: "html" # html, youtube, text

    def schema
      @schema ||= RubyLLM::Schema.create do
        string :cleaned_content, description: "노이즈 제거된 마크다운 텍스트"
        array :semantic_chunks, description: "의미 단위 청크 배열" do
          object do
            number :id
            string :heading
            string :content
          end
        end
      end
    end

    private

    def system_prompt
      <<~PROMPT
        기술 콘텐츠 데이터 전처리 전문가

        [Goal]
        Raw Content의 노이즈를 제거하고, 문맥이 끊기지 않는 논리적 청크(Semantic Chunks)를 생성

        [Rules]
        - 단일 책임: 내용을 해석하거나 요약하지 말고, 오직 정제와 분리에만 집중
        - 데이터 보존: 원문의 핵심 의미와 코드 블록은 손실 없이 보존
        - 코드 블록은 반드시 관련 설명이 포함된 청크 내에 유지
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        [Task]

        다음 #{content_type_description} 콘텐츠를 청소하여 정제된 텍스트와 논리적 청크를 생성하십시오.

        [Input]

        * Title: #{title}
        * URL: #{url}
        * Content Type: #{content_type_description}
        * Raw Content:
        #{raw_content}

        [Output Requirements]

        ## 1. cleaned_content (정규화된 텍스트)

        다음 노이즈를 제거하고 깨끗한 마크다운 텍스트를 생성하십시오:

        #{noise_removal_instructions}

        ## 2. semantic_chunks (논리적 청킹)

        ### 청킹 기준
        - 주제 전환점: 새로운 개념이나 기능 소개 시점
        - 논리적 단위: 문제-해결, 원인-결과, 비교-대조 구조
        - 코드 블록: 설명과 함께 하나의 청크로 묶음
        - 목록/단계: 연관된 항목은 하나의 청크로 유지

        ### 청크 크기 가이드라인
        - 최소: 100자 이상 (너무 잘게 분할하지 않음)
        - 최대: 1000자 이하 (하나의 청크가 너무 길지 않게)
        - 적정 청크 수: 3-10개 (콘텐츠 길이에 따라 조절)
      PROMPT
    end

    # @rbs return: String
    def noise_removal_instructions #: String
      case content_type.to_s
      when "html"
        <<~INSTRUCTIONS
          #### HTML 콘텐츠 노이즈 제거
          - 네비게이션, 푸터, 사이드바, 광고 영역 텍스트
          - 쿠키 동의, 뉴스레터 구독 안내 문구
          - 소셜 미디어 공유 버튼 텍스트
          - 댓글 섹션 및 관련 게시물 목록
          - 반복되는 저작권/라이선스 고지 (문서 하단)
          - 빈 줄 3개 이상 → 1개로 축소
        INSTRUCTIONS
      when "youtube"
        <<~INSTRUCTIONS
          #### YouTube 자막 노이즈 제거
          - 필러 단어: 음, 어, 그, 저, 뭐랄까, 있잖아요
          - 반복 발화: 같은 단어/구절의 연속 반복
          - 자동 생성 자막의 인식 오류 (문맥상 명백한 경우)
        INSTRUCTIONS
      else
        <<~INSTRUCTIONS
          #### 일반 텍스트 노이즈 제거
          - 불필요한 공백 및 줄바꿈 정규화
          - 깨진 인코딩 문자 제거 또는 수정
          - 반복되는 구분선 또는 장식 문자
        INSTRUCTIONS
      end
    end

    # @rbs return: String
    def content_type_description #: String
      case content_type.to_s
      when "html" then "HTML"
      when "youtube" then "YouTube 자막"
      else "텍스트"
      end
    end
  end
end
