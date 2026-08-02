# typed: true

# The `yt` gem does `module Yt; include Yt::Models; end`, which makes
# `Yt::Video` and `Yt::Channel` resolve at runtime through the included
# module. Sorbet does not follow `include` when resolving a scoped constant,
# so it reports those references as unresolved even though the generated
# yt RBI declares Yt::Models::Video and Yt::Models::Channel.
#
# Declare the short names as aliases rather than rewriting call sites: the
# app and its tests use `Yt::Video` / `Yt::Channel` throughout, and that is
# the gem's documented public spelling.

module Yt
  Channel = ::Yt::Models::Channel
  Video = ::Yt::Models::Video
end
