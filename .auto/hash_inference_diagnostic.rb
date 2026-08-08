# typed: true
# rbs_inline: enabled

module AutoresearchHashInferenceDiagnostic
  #: () -> Hash[Symbol, String]
  def self.return_signature_only
    { count: 1 } # diagnostic:return-signature-only
  end

  #: () -> Hash[Symbol, String]
  def self.inline_local_annotation
    value = { count: 1 } #: Hash[Symbol, String] # diagnostic:inline-local-annotation
    value
  end

  #: () -> Hash[Symbol, String]
  def self.native_t_let
    T.let({ count: 1 }, T::Hash[Symbol, String]) # diagnostic:native-t-let
  end

  #: () -> Hash[Symbol, String]
  def self.typed_accumulator
    value = T.let({}, T::Hash[Symbol, String])
    value[:count] = 1 # diagnostic:typed-accumulator-mutation
    value
  end

  #: () -> Hash[Symbol, String]
  def self.inline_rbs_accumulator
    value = {} #: Hash[Symbol, String]
    value[:count] = 1 # diagnostic:inline-rbs-accumulator-mutation
    value
  end
end
