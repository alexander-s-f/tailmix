# frozen_string_literal: true

class ButtonPreview < Lookbook::Preview
  # @param label text "Button label"
  # @param color select { choices: [default, primary, danger, success, warning, neutral, info, indigo] } "CVA Color scheme"
  # @param size select { choices: [default, xs, sm, md, lg, xl] } "CVA Size"
  # @param icon text "Icon name (e.g. trash, check, plus)"
  def standard(label: "Submit Form", color: :primary, size: :default, icon: nil)
    html = Arbre::Context.new do
      btn(label, color: color.to_sym, size: size.to_sym, icon: icon.presence)
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
