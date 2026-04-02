module Madmin
  class ArticlesController < Madmin::ResourceController
    def discard
      if @record.discard
        redirect_to madmin_article_path(@record), notice: "기사를 폐기했습니다."
      else
        redirect_to madmin_articles_path, alert: "기사 폐기에 실패했습니다."
      end
    rescue StandardError => e
      redirect_to madmin_articles_path, alert: "오류가 발생했습니다: #{e.message}"
    end

    def restore
      if @record.undiscard
        redirect_to madmin_article_path(@record), notice: "기사를 복원했습니다."
      else
        redirect_to madmin_articles_path, alert: "기사 복원에 실패했습니다."
      end
    rescue StandardError => e
      redirect_to madmin_articles_path, alert: "오류가 발생했습니다: #{e.message}"
    end

    def mark_unrelated
      if @record.update(is_related: false)
        redirect_to madmin_article_path(@record), notice: "기사를 관련 없음으로 표시했습니다."
      else
        redirect_to madmin_article_path(@record), alert: "관련 없음 표시에 실패했습니다: #{@record.errors.full_messages.join(", ")}"
      end
    rescue StandardError => e
      redirect_to madmin_article_path(@record), alert: "오류가 발생했습니다: #{e.message}"
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
