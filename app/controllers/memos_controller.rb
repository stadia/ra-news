# frozen_string_literal: true

class MemosController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :set_memo, only: %i[ show destroy ]

  include Pagy::Method

  # GET /memos
  def index
    @pagy, @memos = pagy(Memo.kept.includes(:user).order(created_at: :desc))
    render Views::Memos::Index.new(pagy: @pagy, memos: @memos)
  end

  # GET /memos/:id
  def show
    @comments = @memo.comments.includes(:user).order(created_at: :asc)
    @comment = Comment.new
    render Views::Memos::Show.new(memo: @memo, comments: @comments, comment: @comment)
  end

  # GET /memos/new
  def new
    redirect_to new_session_path unless authenticated?
    @memo = Memo.new
    render Views::Memos::New.new(memo: @memo)
  end

  # POST /memos
  def create
    redirect_to new_session_path unless authenticated?
    @memo = Memo.new(memo_params.merge(user: Current.user))

    if @memo.save
      redirect_to memo_path(@memo), notice: "단문이 작성되었습니다."
    else
      render Views::Memos::New.new(memo: @memo), status: :unprocessable_entity
    end
  end

  # DELETE /memos/:id
  def destroy
    unless authenticated? && @memo.user == Current.user
      redirect_to memos_path, alert: "권한이 없습니다."
      return
    end

    @memo.discard!
    redirect_to memos_path, notice: "단문이 삭제되었습니다."
  end

  private

  def set_memo
    @memo = Memo.kept.find(params[:id])
  end

  def memo_params
    params.expect(memo: [ :body ])
  end
end
