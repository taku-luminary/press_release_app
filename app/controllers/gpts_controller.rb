class GptsController < ApplicationController
  before_action :set_gpt, only: [:edit, :update, :destroy]

  def index
    @gpts = Gpt.all
  end

  def new
    @gpt = Gpt.new
  end

  # POST /gpts (JSON)
  # モーダルからの非同期作成
  def create
    @gpt = Gpt.new(gpt_params)

    respond_to do |format|
      if @gpt.save
        format.json { render json: { success: true, gpt: { id: @gpt.id, name: @gpt.name } } }
        format.html { redirect_to press_threads_path, notice: 'GPTを作成しました。' }
      else
        format.json { render json: { success: false, errors: @gpt.errors.full_messages }, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # GET /gpts/:id/edit
  # GPT編集ページ
  def edit
  end

  # PATCH/PUT /gpts/:id
  def update
    respond_to do |format|
      if @gpt.update(gpt_params)
        format.json { render json: { success: true } }
        format.html { redirect_to press_threads_path, notice: 'GPTを更新しました。' }
      else
        format.json { render json: { success: false, errors: @gpt.errors.full_messages }, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gpts/:id
  def destroy
    @gpt.destroy
    respond_to do |format|
      format.json { render json: { success: true } }
      format.html { redirect_to press_threads_path, notice: 'GPTを削除しました。' }
    end
  end

  private

  def set_gpt
    @gpt = Gpt.find(params[:id])
  end

  def gpt_params
    params.require(:gpt).permit(:name, :description, :instructions)
  end
end
