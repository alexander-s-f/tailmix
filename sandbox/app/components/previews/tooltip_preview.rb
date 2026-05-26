# frozen_string_literal: true

class TooltipPreview < Lookbook::Preview
  def standard
    html = Arbre::Context.new do
      div class: "h-48 w-full flex items-center justify-center bg-gray-950/40 p-8 rounded-xl border border-gray-900" do
        tooltip do
          trigger class: "inline-block" do
            btn "Hover Over Me", color: :primary, size: :sm
          end
          bubble "Information popover details successfully activated!"
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
