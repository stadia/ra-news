# typed: true
# rbs_inline: enabled

module AutoresearchSetterFormsDiagnostic
  class << self
    #: (String value) -> void
    def plain_name=(value)
      value
    end
  end

  self.plain_name = 123 # diagnostic:plain-assignment
  self.plain_name=(123) # diagnostic:plain-explicit-call
  Article.new.title = 123 # diagnostic:rails-assignment
  Article.new.title=(123) # diagnostic:rails-explicit-call
end
