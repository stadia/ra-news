# frozen_string_literal: true

class MemoCommentsController < ApplicationController
  include RateLimiting

  before_action :check_rate_limit, only: %i[ create ]
  before_action :set_comment, only: %i[ destroy verify_password ]
  before_action :set_memo, only: %i[ create ]

  allow_unauthenticated_access only: %i[ create verify_password ]

  # POST /memos/:memo_id/comments
  def create
    @comment = @memo.comments.build(comment_params)

    if authenticated?
      @comment.user = Current.user
    else
      @comment.user = nil
    end

    respond_to do |format|
      if @comment.save
        load_comments
        format.html { redirect_to @memo, notice: "댓글이 성공적으로 작성되었습니다." }
        format.turbo_stream
      else
        load_comments
        format.html { redirect_to @memo, alert: "댓글 작성에 실패했습니다." }
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
  end

  # POST /memos/:memo_id/comments/:id/verify_password
  def verify_password
    @memo = @comment.memo

    unless @comment.guest?
      if authenticated? && @comment.user == Current.user
        @comment.destroy
        load_comments
        respond_to do |format|
          format.turbo_stream { render :destroy }
        end
      else
        render turbo_stream: turbo_stream.replace("delete_comment_modal_#{@comment.id}",
          html: "<div class='text-red-400 text-sm mt-2'>권한이 없습니다.</div>".html_safe
        ), status: :unauthorized
      end
      return
    end

    provided_password = params[:password]

    if @comment.authenticate_guest_password(provided_password)
      @comment.destroy
      load_comments
      respond_to do |format|
        format.turbo_stream { render :destroy }
      end
    else
      render turbo_stream: turbo_stream.replace("delete_comment_modal_#{@comment.id}",
        html: "<div class='text-red-400 text-sm mt-2'>비밀번호가 올바르지 않습니다.</div>".html_safe
      ), status: :unauthorized
    end
  end

  # DELETE /memos/:memo_id/comments/:id
  def destroy
    @memo = @comment.memo

    if @comment.guest?
      respond_to do |format|
        format.html { redirect_to @memo, alert: "잘못된 접근입니다." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("delete_comment_modal_#{@comment.id}",
            html: "<div class='text-red-400 text-sm mt-2'>비밀번호 확인이 필요합니다.</div>".html_safe
          ), status: :unprocessable_entity
        end
      end
      return
    end

    if authenticated? && @comment.user == Current.user
      @comment.destroy
      load_comments
      respond_to do |format|
        format.html { redirect_to @memo, notice: "댓글이 삭제되었습니다." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @memo, alert: "권한이 없습니다." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "comments/comment", locals: { comment: @comment }), status: :unauthorized }
      end
    end
  end

  private

  def set_memo
    @memo = Memo.kept.find(params[:memo_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def load_comments
    @comments = @memo.comments.includes(:user)
  end

  def comment_params
    params.expect(comment: [ :body, :guest_name, :guest_password, :parent_id ])
  end
end
