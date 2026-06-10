# frozen_string_literal: true
# rbs_inline: enabled

module Search
  module VectorMath
    module_function

    #: (Array[Float]? a, Array[Float]? b) -> Float
    def cosine_similarity(a, b)
      return 0.0 if a.blank? || b.blank? || a.size != b.size

      dot = 0.0
      norm_a = 0.0
      norm_b = 0.0
      a.each_index do |i|
        av = a[i].to_f
        bv = b[i].to_f
        dot += av * bv
        norm_a += av * av
        norm_b += bv * bv
      end
      return 0.0 if norm_a.zero? || norm_b.zero?

      dot / (Math.sqrt(norm_a) * Math.sqrt(norm_b))
    end
  end
end
