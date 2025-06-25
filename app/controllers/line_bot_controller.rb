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

    # すぐに「生成中」メッセージを返信
    waiting_reply = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: event.reply_token,
      messages: [
        Line::Bot::V2::MessagingApi::TextMessage.new(text: 'ただいま生成中です…')
      ]
    )
    begin
      res = line_client.reply_message(reply_message_request: waiting_reply)
      Rails.logger.info("[LINE] waiting_reply status: "+res.inspect)
    rescue => e
      Rails.logger.error("[LINE] waiting_reply error: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    # 非同期ジョブで生成 & push
    PressReleaseJob.perform_later(user_id, user_text, press_thread.id)
  rescue => e
    Rails.logger.error("[LINE] handle_text_message エラー: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  # 旧 ai_generate_response は PressReleaseService へ移行
end 