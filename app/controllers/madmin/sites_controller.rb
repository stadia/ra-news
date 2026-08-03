# rbs_inline: enabled

module Madmin
  class SitesController < Madmin::ResourceController
    def discard
      if @record.discard
        redirect_to madmin_site_path(@record), notice: "사이트를 폐기했습니다."
      else
        redirect_to madmin_sites_path, alert: "사이트 폐기에 실패했습니다."
      end
    rescue StandardError => e
      redirect_to madmin_sites_path, alert: "오류가 발생했습니다: #{e.message}"
    end

    def restore
      if @record.undiscard
        redirect_to madmin_site_path(@record), notice: "사이트를 복원했습니다."
      else
        redirect_to madmin_sites_path, alert: "사이트 복원에 실패했습니다."
      end
    rescue StandardError => e
      redirect_to madmin_sites_path, alert: "오류가 발생했습니다: #{e.message}"
    end
  end
end
