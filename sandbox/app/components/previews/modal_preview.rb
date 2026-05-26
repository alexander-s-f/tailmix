# frozen_string_literal: true

class ModalPreview < Lookbook::Preview
  # @param open select { choices: [true, false] } "Is modal open by default"
  def standard(open: false)
    is_open = (open == "true" || open == true)
    html = Arbre::Context.new do
      div do
        # Trigger button using interactive CVA button component
        btn "Open Modal Dialog", color: :primary, size: :sm, data: { action: "click->modal-demo#toggle" }
        
        # Interactive CVA Modal Component
        modal id: "modal-demo", open: is_open do
          div class: "p-6" do
            h3 "Lookbook Interactive Modal", class: "text-lg font-bold text-white mb-2"
            para "This is a reactive modal component built with Arbre and animated using Tailmix, without writing a single line of Stimulus or custom JS!", class: "text-sm text-gray-400 mb-6"
            
            div class: "flex justify-end gap-3" do
              btn "Close Dialog", color: :neutral, size: :sm, data: { action: "click->modal-demo#close" }
              btn "Confirm", color: :success, size: :sm
            end
          end
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
