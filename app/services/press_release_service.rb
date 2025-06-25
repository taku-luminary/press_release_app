class PressReleaseService
  class << self
    # content: ユーザーが入力したメインテキスト
    # params: フロントで渡される9項目 + gpt_id
    def generate(content, params)
      gpt_instructions = if params[:gpt_id].present?
                            Gpt.find_by(id: params[:gpt_id])&.instructions.to_s.strip
                          else
                            ''
                          end

      prompt_body = <<~BODY
        あなたは世界一のプレスリリース作成者です。
        ユーザー入力の情報を元に、以下10点と補足を考慮してプレスリリースを作成してください：　
        ※補足には何も記入がなければ、補足については無視してください

        ユーザーの入力: #{content}

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

      full_prompt = gpt_instructions.present? ? "#{prompt_body}\n\n#{gpt_instructions}" : prompt_body

      response_body = call_openai(full_prompt)
      response_body.dig('choices', 0, 'message', 'content')
    rescue => e
      Rails.logger.error "PressReleaseService Error: #{e.message}"
      "申し訳ありません。AIの応答生成中にエラーが発生しました。\n\n#{e.message}"
    end

    private

    def call_openai(prompt)
      http_response = HTTP.post(
        'https://api.openai.com/v1/chat/completions',
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{ENV['OPENAI_API_KEY'] || ENV['OPENAI_ACCESS_TOKEN']}"
        },
        json: {
          model: 'gpt-4o',
          messages: [{ role: 'user', content: prompt }]
        }
      )

      unless http_response.status.success?
        raise "OpenAI API Error: HTTP #{http_response.status} - #{http_response.body.to_s}"
      end

      JSON.parse(http_response.body.to_s)
    end
  end
end 