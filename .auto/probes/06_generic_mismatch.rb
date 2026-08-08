# typed: true
# rbs_inline: enabled

module AutoresearchProbe06
  #: (Array[String] values) -> String
  def self.join(values) = values.join(",")
  join([ 1, 2 ])
end
