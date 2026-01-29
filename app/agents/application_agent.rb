# frozen_string_literal: true

# rbs_inline: enabled

# ApplicationAgent - Base class for all agents in this application
#
# All agents inherit from this class. Configure shared settings here
# that apply to all agents, or override them per-agent as needed.
#
# Example:
#   class MyAgent < ApplicationAgent
#     param :query, required: true
#
#     def user_prompt
#       query
#     end
#   end
#
# Usage:
#   MyAgent.call(query: "hello")
#   MyAgent.call(query: "hello", dry_run: true)    # Debug mode
#   MyAgent.call(query: "hello", skip_cache: true) # Bypass cache
#
class ApplicationAgent < RubyLLM::Agents::Base
  # ============================================
  # Shared Model Configuration
  # ============================================
  # These settings are inherited by all agents

  model "gemini-2.0-flash"   # Default model for all agents
  temperature 0.0            # Default temperature (0.0 = deterministic)
  timeout 60                 # Default timeout in seconds

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

  # 한국어 시스템 프롬프트 prefix
  # @rbs return: String
  def system_prompt_prefix #: String
    "당신은 Ruby 프로그래밍 언어 전문 개발자입니다. 모든 출력은 한국어로 작성합니다."
  end

  # 한국어 Ruby 전문가 시스템 프롬프트
  # @rbs return: String
  def korean_ruby_expert_prompt #: String
    <<~PROMPT
      당신은 Ruby 프로그래밍 언어 전문 개발자이자 뛰어난 기술 작가입니다.
      Ruby, Rails, 그리고 Ruby 생태계에 대한 깊은 이해를 바탕으로 정확하고 유용한 정보를 제공합니다.
      모든 출력은 한국어로 작성하며, 기술 용어는 원어를 유지합니다.
    PROMPT
  end

  # Common metadata
  # @rbs return: Hash[Symbol, untyped]
  def execution_metadata #: Hash[Symbol, untyped]
    { app_name: "RubyNews", rails_env: Rails.env }
  end
end
