# frozen_string_literal: true

# rbs_inline: enabled

# ApplicationAgent - Base class for all agents in this application
#
# All agents inherit from this class. Configure shared settings here
# that apply to all agents, or override them per-agent as needed.
class ApplicationAgent < RubyLLM::Agents::Base
  # ============================================
  # Shared Model Configuration
  # ============================================
  # These settings are inherited by all agents

  model "gemini-2.5-flash" # Default model for all agents
  temperature 0.5
  timeout 60 # Default timeout in seconds

  # ============================================
  # Shared Caching
  # ============================================

  # cache 1.hour  # Enable caching for all agents (override per-agent if needed)

  # ============================================
  # Shared Reliability Settings
  # ============================================
  # Configure once here, all agents inherit these settings

  # Automatic retries for all agents
  retries max: 2, backoff: :exponential, base: 0.4, max_delay: 3.0

  # Shared fallback models
  # fallback_models ["gpt-4o-mini", "claude-3-haiku"]

  # Total timeout across retries/fallbacks
  # total_timeout 30

  # Circuit breaker (per agent-model pair)
  # circuit_breaker errors: 5, within: 60, cooldown: 300

  # ============================================
  # Shared Helper Methods
  # ============================================
  # Define methods here that can be used by all agents

  # Common system prompt prefix
  def system_prompt_prefix #: String
    <<~PROMPT
      ## 시스템 역할: 기술 콘텐츠 지능화 팀(Tech Intelligence Team)
      
      1. 운영 원칙 (Operational Principles)
         * 단일 책임: 너는 전체 파이프라인 중 너에게 할당된 특정 단계만 책임진다. 다른 에이전트의 영역을 침범하지 마라.
         * 데이터 보존: 앞선 에이전트가 생성한 데이터를 임의로 삭제하거나 훼손하지 마라. 너의 결과물을 지정된 JSON 필드에 추가(Append)하거나 업데이트하라. 
         * 기술적 정확성: 모든 처리 과정에서 기술적 사실(함수명, 아키텍처, 버전 등)의 정확성을 최우선으로 한다.
      
      2. 데이터 통신 규약 (Data Protocol)
         * JSON 출력: 모든 응답은 사전에 정의된 JSON 구조를 엄격히 준수해야 한다.
         * 마크다운 활용: 텍스트 데이터 작성 시 구조화된 가독성을 위해 마크다운(Markdown) 문법을 적극 사용하라. 
      
      3. 할루시네이션 방지 (Anti-Hallucination)
         * 모호함 처리: 원문에 없는 내용을 추측해서 지어내지 마라.
      
      4. 톤 앤 매너 (Tone & Voice)
         * 전문성: 전 세계 시니어 엔지니어들이 읽어도 신뢰할 수 있는 전문적이고 간결한 어조를 유지하라.
    PROMPT
  end

  # Example: Common metadata
  # def execution_metadata
  #   { app_version: Rails.application.config.version }
  # end
end
