# GitHub OAuth Design

## Goal

Add GitHub as a first-class OAuth sign-in provider alongside Google and Apple.

## Scope

- Reuse the existing Devise OmniAuth callback route and `OauthAccounts::Callbacks` flow.
- Store GitHub accounts in the existing `oauth_accounts` table with `provider = "github"`.
- Match existing users only when GitHub provides a verified, non-relay email.
- Show a GitHub login button only when GitHub OAuth credentials are configured.

## GitHub Email Handling

GitHub may omit `auth.info.email` when the user's public email is private. When the callback has no email, use the GitHub OAuth token to request `https://api.github.com/user/emails` and select the first email where `primary` and `verified` are both true.

If no verified primary email is available, keep the normal OAuth signup path but leave the email blank. The existing signup completion flow remains responsible for user-facing validation.

## Configuration

Add `Configs::GithubOauth` with `GITHUB_OAUTH_CLIENT_ID` and `GITHUB_OAUTH_CLIENT_SECRET`, plus a `github_oauth` preference key. Add `:github` to `User.omniauth_providers` and Devise's OmniAuth configuration with the `user:email` scope.

## UI

Add `Components::OauthButton::Github` and render it from `Views::Sessions::New` next to Google and Apple. Add `sessions.new.continue_with_github` to `ko`, `en`, and `ja`.

## Tests

- Config resolution and `configured?` for GitHub.
- Callback normalization when GitHub provides email directly.
- Callback normalization when GitHub email is fetched from `/user/emails`.
- Callback behavior when GitHub has no verified primary email.
- Controller routing/config guard for GitHub callback.
- Login page renders GitHub button and English label when configured.
