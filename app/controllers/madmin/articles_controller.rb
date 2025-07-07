module Madmin
  class ArticlesController < Madmin::ResourceController
    def discard
      if @record.discard
        redirect_to madmin_article_path(@record), notice: "Article discarded successfully."
      else
        redirect_to madmin_articles_path, alert: "Failed to discard article."
      end
    rescue StandardError => e
      redirect_to madmin_articles_path, alert: "An error occurred: #{e.message}"
    end

    def restore
      if @record.undiscard
        redirect_to madmin_article_path(@record), notice: "Article restored successfully."
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
  end
end
