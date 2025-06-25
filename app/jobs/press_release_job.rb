require 'line/bot'

class PressReleaseJob < ApplicationJob
  queue_as :default

  # user_id: LINE userId（push 送付先）
  # user_text: 受信した本文
  # press_thread_id: 保存用スレッドID
  def perform(user_id, user_text, press_thread_id)
    service_params = {
      company_name: '', word_count: '', target_audience: '', tone: '',
      required_words: '', ng_words: '', main_message: '', expected_action: '',
      expected_effect: '', gpt_id: nil
    }

    ai_response = PressReleaseService.generate(user_text, service_params)

    # 保存
    press_thread = PressThread.find_by(id: press_thread_id)
    if press_thread
      press_thread.messages.create!(content: ai_response, role: 'assistant')
    end

    # LINE へ push
    client = line_client
    return unless client

    message = Line::Bot::V2::MessagingApi::TextMessage.new(text: ai_response)
    push_req = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: user_id,
      messages: [message]
    )
    begin
      res = client.push_message(push_message_request: push_req)
      Rails.logger.info("[LINE] push_message status: "+res.inspect)
    rescue => e
      Rails.logger.error("[LINE] push_message error: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  rescue => e
    Rails.logger.error("PressReleaseJob Error: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  private

  def line_client
    @line_client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV['LINE_CHANNEL_TOKEN']
    )
  end
end 