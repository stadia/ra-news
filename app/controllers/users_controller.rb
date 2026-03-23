# frozen_string_literal: true

# rbs_inline: enabled

class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[ new create ]

  before_action :set_user, except: %i[ new create ]

  def show
    render Views::Users::Show.new(user: @user)
  end

  def new
    render Views::Users::New.new(user: User.new)
  end

  def edit
    render Views::Users::Edit.new(user: @user)
  end

  def password
    render Views::Users::Password.new(user: @user)
  end

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        start_new_session_for @user
        format.html { redirect_to new_session_path, notice: t("registration_success") }
      else
        format.html { render Views::Users::New.new(user: @user), status: :unprocessable_entity }
      end
    end
  end

  def update
    updating_password = password_update_request?
    permitted_params = updating_password ? password_params : user_params
    failure_view = updating_password ? :password : :edit

    respond_to do |format|
      if @user.update(permitted_params)
        format.html { redirect_to users_path, notice: t("update_success") }
      else
        if failure_view == :edit
          format.html { render Views::Users::Edit.new(user: @user), status: :unprocessable_entity }
        elsif failure_view == :password
          format.html { render Views::Users::Password.new(user: @user), status: :unprocessable_entity }
        else
          format.html { render failure_view, status: :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other, notice: "계정이 삭제되었습니다." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = current_user
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.expect(user: [ :email_address, :name ])
    end

    def password_params
      params.expect(user: [ :password, :password_confirmation ])
    end

    def password_update_request?
      user = params[:user]
      return false unless user.respond_to?(:key?)

      user.key?(:password) || user.key?(:password_confirmation) ||
        user.key?("password") || user.key?("password_confirmation")
    end
end
