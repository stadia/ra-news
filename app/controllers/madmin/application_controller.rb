# typed: true
# rbs_inline: enabled

module Madmin
  class ApplicationController < Madmin::BaseController
    # Madmin::Engine은 `isolate_namespace Madmin`이므로 Madmin:: 하위 컨트롤러/뷰는
    # 엔진 라우트만 가진다. `madmin_*_path`는 호스트 앱의 `namespace :madmin`에
    # 정의되어 있으므로, 메인 앱 url_helpers를 명시적으로 include해야 한다.
    # (`send(:include, ...)`는 Sorbet이 동적 include를 허용하기 위한 형태)
    send(:include, Rails.application.routes.url_helpers)

    before_action :authenticate_admin_user

    def authenticate_admin_user
      authenticate_user!
      redirect_to "/", status: :forbidden unless current_user&.admin?
    end
  end
end
