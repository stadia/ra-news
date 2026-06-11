# frozen_string_literal: true
# rbs_inline: enabled

module Search
  module VectorMath
    class << self
      #: (Array[Float]? a, Array[Float]? b) -> Float
      def cosine_similarity(a, b)
        return 0.0 if a.blank? || b.blank? || a.size != b.size

        dot = 0.0
        norm_a = 0.0
        norm_b = 0.0
        # 고차원(1536) 벡터에서 블록 호출 오버헤드를 피하려 while 루프 사용.
        # .to_f 는 정수 등 비-Float 입력에도 안전하도록 유지한다(범용 유틸).
        i = 0
        len = a.size
        while i < len
          av = a[i].to_f
          bv = b[i].to_f
          dot += av * bv
          norm_a += av * av
          norm_b += bv * bv
          i += 1
        end
        return 0.0 if norm_a.zero? || norm_b.zero?

        dot / (Math.sqrt(norm_a) * Math.sqrt(norm_b))
      end
    end
  end
end
