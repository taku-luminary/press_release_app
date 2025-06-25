require 'line/bot'

# LINE Messaging API v2 対応 Controller
class LineBotController < ApplicationController
  # 外部サービスからの POST のため CSRF を無効化
  skip_before_action :verify_authenticity_token

  ############################################################
  # Webhook エンドポイント
  ############################################################
  def webhook
    # URL 埋め込みトークンの照合
    unless params[:token] == ENV['LINE_WEBHOOK_ROUTE_TOKEN']
      Rails.logger.warn("[LINE] 不正なWebhookトークンです: #{params[:token]}")
      head :bad_request and return
    end

    body      = request.raw_post
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    # 署名検証 & パース
    begin
      events = parser.parse(body: body, signature: signature)
    rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
      Rails.logger.warn('[LINE] 署名検証に失敗しました')
      head :bad_request and return
    end

    # イベント処理
    events.each do |event|
      case event
      when Line::Bot::V2::Webhook::MessageEvent
        # テキストメッセージのみ対応
        if event.message.is_a?(Line::Bot::V2::Webhook::TextMessageContent)
          handle_text_message(event)
        end
      else
        Rails.logger.info("[LINE] 未対応イベント: #{event.class}")
      end
    end

    head :ok
  end

  private

  # ---------------------------
  # LINE SDK v2 クライアント
  # ---------------------------
  def line_client
    @line_client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV['LINE_CHANNEL_TOKEN']
    )
  end

  # Webhook 解析用パーサ
  def parser
    @parser ||= Line::Bot::V2::WebhookParser.new(
      channel_secret: ENV['LINE_CHANNEL_SECRET']
    )
  end

  # ---------------------------
  # メッセージ処理
  # ---------------------------
  def handle_text_message(event)
    user_id    = event.source&.user_id || 'unknown'
    user_text  = event.message.text

    # スレッド取得 / 作成
    press_thread = PressThread.find_or_create_by!(title: "LINE: #{user_id}")

    # ユーザー発言保存
    press_thread.messages.create!(content: user_text, role: 'user')

    meta = press_thread.meta || {}
    stage = meta['stage'] || 'start'
    params_collected = meta['params'] || {}

    case stage
    when 'start'
      # 最初のユーザーメッセージを保持
      params_collected['content'] = user_text

      meta['stage'] = 'ask_company'
      meta['params'] = params_collected
      press_thread.update!(meta: meta)

      reply_text = "会社名を教えてください\n例：〇〇株式会社"
      press_thread.messages.create!(content: reply_text, role: 'assistant')
      send_reply(event.reply_token, reply_text)

    when 'ask_company'
      params_collected['company_name'] = user_text
      meta['params'] = params_collected
      meta['stage'] = 'ask_word_count'
      press_thread.update!(meta: meta)

      reply_text = "文字数を教えてください\n例：3000文字"
      press_thread.messages.create!(content: reply_text, role: 'assistant')
      send_reply(event.reply_token, reply_text)

    when 'ask_word_count'
      params_collected['word_count'] = user_text
      meta['params'] = params_collected
      meta['stage'] = 'generating'
      press_thread.update!(meta: meta)

      # 生成中メッセージ
      generating_msg = 'ただいま生成中です…'
      press_thread.messages.create!(content: generating_msg, role: 'assistant')
      send_reply(event.reply_token, generating_msg)

      # 非同期ジョブで生成
      PressReleaseJob.perform_later(user_id, params_collected, press_thread.id)

    else
      # 不明・完了ステータスのため新しいフローを開始
      meta = {
        'stage' => 'ask_company',
        'params' => { 'content' => user_text }
      }
      press_thread.update!(meta: meta)

      reply_text = "会社名を教えてください\n例：〇〇株式会社"
      press_thread.messages.create!(content: reply_text, role: 'assistant')
      send_reply(event.reply_token, reply_text)
    end
  rescue => e
    Rails.logger.error("[LINE] handle_text_message エラー: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  # 返信ヘルパー
  def send_reply(reply_token, text)
    req = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: reply_token,
      messages: [Line::Bot::V2::MessagingApi::TextMessage.new(text: text)]
    )
    line_client.reply_message(reply_message_request: req)
  end

  # 旧 ai_generate_response は PressReleaseService へ移行
end 