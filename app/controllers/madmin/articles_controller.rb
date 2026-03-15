module Madmin
  class ArticlesController < Madmin::ResourceController
    def discard
      if @record.discard
        redirect_to madmin_article_path(@record), notice: "article discarded successfully."
      else
        redirect_to madmin_articles_path, alert: "Failed to discard article."
      end
    rescue StandardError => e
      redirect_to madmin_articles_path, alert: "An error occurred: #{e.message}"
    end

    def restore
      if @record.undiscard
        redirect_to madmin_article_path(@record), notice: "article restored successfully."
      else
        redirect_to madmin_articles_path, alert: "Failed to restore article."
      end
    rescue StandardError => e
      redirect_to madmin_articles_path, alert: "An error occurred: #{e.message}"
    end

    private

    def scoped_resources
      super.includes(:site)
    end

    def resource_params
      hash = super
      hash[:user_id] = User.first_bot.id
      hash
    end
  end
end
