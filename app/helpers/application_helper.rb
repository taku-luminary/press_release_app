module ApplicationHelper
  def markdown(text)
    return '' if text.blank?
    
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      filter_html: false,
      escape_html: false,
      no_links: false,
      no_images: false,
      no_styles: false,
      safe_links_only: false,
      with_toc_data: false,
      prettify: true
    )
    
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true,
      footnotes: true
    )
    
    markdown.render(text).html_safe
  end
end
