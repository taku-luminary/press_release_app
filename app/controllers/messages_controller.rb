class MessagesController < ApplicationController
  require 'http'

  def create
    @press_thread = PressThread.find(params[:press_thread_id])
    @message = @press_thread.messages.build(message_params)
    @message.role = 'user'

    if @message.save
      # AIレスポンスを生成
      ai_response = generate_ai_response(@message, params)

      # AIレスポンスを保存
      @ai_message = @press_thread.messages.create!(
        content: ai_response,
        role: 'assistant'
      )

      respond_to do |format|
        format.json {
          render json: {
            success: true,
            content: render_to_string(
              partial: 'press_threads/content',
              locals: { press_thread: @press_thread, message: Message.new },
              formats: [:html]
            )
          }
        }
      end
    else
      respond_to do |format|
        format.json {
          render json: {
            success: false,
            errors: @message.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH /messages/:id
  def update
    @message = Message.find(params[:id])
    
    if @message.update(message_update_params)
      respond_to do |format|
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @message.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :press_thread_id)
  end

  def message_update_params
    params.require(:message).permit(:content)
  end

  def generate_ai_response(message, params)
    # GPT指示の取得
    gpt_instructions = if params[:gpt_id].present?
                         Gpt.find_by(id: params[:gpt_id])&.instructions.to_s.strip
                       else
                         ''
                       end

    # プロンプトの構築
    prompt_body = <<~BODY
      あなたは世界一のプレスリリース作成者です。
      ユーザー入力の情報を元に、以下10点と補足を考慮してプレスリリースを作成してください：　
      ※補足には何も記入がなければ、補足については無視してください

      ユーザーの入力: #{message.content}

      ■10項目
      1.プレスリリースの対象となる会社名: #{params[:company_name]}
      2.文字数: #{params[:word_count]}
      3.ターゲットの読者: #{params[:target_audience]}
      4.トーン: #{params[:tone]}
      5.絶対入れてほしい必須ワード: #{params[:required_words]}
      6.絶対に入れないワード: #{params[:ng_words]}
      7.メインメッセージ: #{params[:main_message]}
      8.このプレスリリースを読んだ人に期待する行動: #{params[:expected_action]}
      9.期待する効果: #{params[:expected_effect]}
      
      ■補足
    BODY

    full_prompt = if gpt_instructions.present?
                    "#{prompt_body}\n\n#{gpt_instructions}"
                  else
                    prompt_body
                  end

    PressReleaseService.generate(message.content, params)
  rescue => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    "申し訳ありません。AIの応答生成中にエラーが発生しました。\n\n#{e.message}"
  end

  # 旧 openai_api_call は PressReleaseService に移行済み
end
