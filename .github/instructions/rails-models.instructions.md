---
applyTo: "app/models/**/*.rb"
name: "Rails Models Reference"
description: "ActiveRecord models — associations, validations, scopes, enums"
---

# ActiveRecord Models (18)

Check here first for scopes, constants, associations. Read model files for business logic/methods.

- ActsAsTaggableOn::Tag (1 associations)
- ActsAsTaggableOn::Tagging (3 associations)
- Article (10 associations)
  scopes: full_text_search_for, related, unrelated, confirmed, without_toast, for_admin_index
- Federails::Actor (14 associations)
- Federails::Following (3 associations)
- Like (2 associations)
- Post (9 associations)
  scopes: comments, standalone
- Preference (0 associations)
  PROTECTED_KEYS: name, value
- PushSubscription (1 associations)
- Role (0 associations)
  scopes: named
- Site (1 associations)
- SlackArticleDelivery (2 associations)
- SlackWorkspace (1 associations)
  scopes: active, delivery_ready
- Socialization::ActiveRecordStores::Follow (2 associations)
- Socialization::ActiveRecordStores::Like (2 associations)
- Socialization::ActiveRecordStores::Mention (2 associations)
- Tag (1 associations)
  scopes: confirmed, unconfirmed
- User (6 associations)
  scopes: with_role, admins