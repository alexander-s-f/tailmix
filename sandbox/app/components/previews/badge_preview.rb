# frozen_string_literal: true

class BadgePreview < Lookbook::Preview
  # @param value text "Status or raw value"
  # @param size select { choices: [default, xs, sm, md, lg, xl] } "CVA Size"
  def standard(value: "active", size: :default)
    html = Arbre::Context.new do
      badge(value, size: size.to_sym)
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end

  # @param val select { choices: [true, false] } "Boolean status of lead"
  # @param size select { choices: [default, xs, sm, md, lg, xl] } "CVA Size"
  def boolean_status(val: true, size: :default)
    html = Arbre::Context.new do
      badge(val == "true" || val == true, size: size.to_sym)
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
