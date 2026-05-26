# frozen_string_literal: true

class ToastPreview < Lookbook::Preview
  # @param color select { choices: [success, danger, info, warning] } "Toast semantic color scheme"
  # @param open select { choices: [true, false] } "Default open state"
  def standard(color: :success, open: true)
    is_open = (open == "true" || open == true)
    html = Arbre::Context.new do
      div class: "relative h-64 w-full flex items-center justify-center bg-gray-950/40 p-8 rounded-xl border border-gray-900 overflow-hidden" do
        
        # Declarative click-toggle button (changes state of the toast in browser)
        btn "Show Notification", color: :neutral, size: :sm, data: { action: "click->toast-demo#toggle" }

        toast id: "toast-demo", color: color.to_sym, open: is_open do
          body do
            span class: "mr-1.5" do
              case color.to_sym
              when :success then text_node "✅"
              when :danger  then text_node "🚨"
              when :info    then text_node "ℹ️"
              when :warning then text_node "⚠️"
              end
            end
            span "System event resolved successfully."
          end
          close_button
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
