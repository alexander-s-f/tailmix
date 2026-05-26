# frozen_string_literal: true

class PreviewWrapperComponent < ViewComponent::Base
  def initialize(html)
    @html = html
  end

  def call
    @html.html_safe
  end
end
