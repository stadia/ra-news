module Madmin
  class SitesController < Madmin::ResourceController
    def discard
      if @record.discard
        redirect_to madmin_site_path(@record), notice: "site discarded successfully."
      else
        redirect_to madmin_sites_path, alert: "Failed to discard site."
      end
    rescue StandardError => e
      redirect_to madmin_sites_path, alert: "An error occurred: #{e.message}"
    end

    def restore
      if @record.undiscard
        redirect_to madmin_site_path(@record), notice: "site restored successfully."
      else
        redirect_to madmin_sites_path, alert: "Failed to restore site."
      end
    rescue StandardError => e
      redirect_to madmin_sites_path, alert: "An error occurred: #{e.message}"
    end
  end
end
