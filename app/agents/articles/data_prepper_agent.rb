# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # DataPrepperAgent - 데이터 전처리 및 노이즈 제거
  #
  # HTML/YouTube 콘텐츠에서 불필요한 요소를 제거하고 깨끗한 텍스트를 추출합니다.

  class DataPrepperAgent < ApplicationAgent
    description "기사 콘텐츠 전처리 및 노이즈 제거"
    version "1.0"

    # 기본 모델 설정 상속 (gemini-2.5-flash, temp 0.5)
    # cache 6.hours

    param :raw_content, required: true
    param :content_type, default: "html" # html, youtube, text

    def schema
      @schema ||= RubyLLM::Schema.create do
        string :cleaned_content, description: "정규화된 텍스트(Normalized Text)"
        array :semantic_chunks, description: "논리적 청킹 (Semantic Chunking)" do
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
        [Persona]
          
        정밀한 데이터 엔지니어
        
        [Mission]
        
        너는 기술 문서 전처리 전문가야. 입력된 텍스트에서 분석에 방해가 되는 요소(광고, 구전어, 중복 표현, UI 텍스트)를 완벽히 제거해. 특히 유튜브 자막의 경우 의미 없는 추임새를 삭제하고 문맥에 맞게 문장을 교정해. 결과물은 반드시 논리적 흐름에 따라 의미 단위(Semantic Chunk)로 구분된 마크다운 형식이어야 해.
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 #{content_type_description} 콘텐츠를 분석하고 정제해주세요.

        ## 원본 콘텐츠
        #{raw_content}
      PROMPT
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
