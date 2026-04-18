module ActiveStorageR2CdnPatch
  def url(key, **)
    return super unless public?
    "#{ENV['ACTIVE_STORAGE_CDN_HOST']}/#{key}"
  end
end

Rails.application.config.after_initialize do
  if ENV["ACTIVE_STORAGE_CDN_HOST"].present?
    ActiveStorage::Service::S3Service.prepend(ActiveStorageR2CdnPatch)
  end
end
