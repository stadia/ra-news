# frozen_string_literal: true

require "active_storage/service/s3_service"

module ActiveStorageR2CdnPatch
  def public_url(key, **client_opts)
    cdn_host = ENV["ACTIVE_STORAGE_CDN_HOST"].presence

    return super unless cdn_host && name.to_s == "cloudflare"

    "#{cdn_host.delete_suffix('/')}/#{key}"
  end
end

ActiveStorage::Service::S3Service.prepend(ActiveStorageR2CdnPatch) unless
  ActiveStorage::Service::S3Service < ActiveStorageR2CdnPatch
