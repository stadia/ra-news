# frozen_string_literal: true

class Components::Articles::GoogleSearch < Components::Base
  ENGINE_ID = "119e8b7b7b2f64488"

  def initialize(query: nil)
    @query = query
  end

  def view_template
    div(
      data_controller: "google-search",
      data_google_search_engine_id_value: ENGINE_ID,
      data_google_search_error_message_value: t("articles.index.google.error"),
      data_google_search_query_value: @query
    ) do
      p(class: "mb-6 text-content-secondary") { t("articles.index.google.description") }
      p(data_google_search_target: "loading", class: "text-content-muted") do
        t("articles.index.google.loading")
      end
      div(data_google_search_target: "container")
      p(
        data_google_search_target: "error",
        class: "text-danger-text",
        hidden: true
      ) { t("articles.index.google.error") }
    end
  end
end
