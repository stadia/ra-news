PgSearch.multisearch_options = {
  using: {
    tsearch: { dictionary: "simple", tsvector_column: "tsvector_content_tsearch" }
  }
}
