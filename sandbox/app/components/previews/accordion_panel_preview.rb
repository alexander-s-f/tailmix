# frozen_string_literal: true

class AccordionPanelPreview < Lookbook::Preview
  def standard
    html = Arbre::Context.new do
      div class: "max-w-2xl mx-auto space-y-2 p-6 bg-gray-900/20 rounded-2xl border border-gray-800" do
        h3 "Frequently Asked Questions", class: "text-lg font-bold text-white mb-4"

        accordion_panel open: true do
          trigger "What is Tailmix UI?"
          panel do
            para "Tailmix UI is a premium, declarative state-driven interface system designed to combine the expressiveness of Ruby Arbre with highly optimized, reactive Tailwind styling rules.", class: "text-gray-400 text-sm leading-relaxed"
          end
        end

        accordion_panel open: false do
          trigger "Does it require Stimulus JS?"
          panel do
            para "No! Tailmix uses a compiled JSON manifest to directly hydrate native elements and bind interaction rules without needing custom Stimulus controllers.", class: "text-gray-400 text-sm leading-relaxed"
          end
        end

        accordion_panel open: false do
          trigger "Is it suitable for enterprise CRM applications?"
          panel do
            para "Absolutely. By structuring UI logic declaratively into state and layout twins, it eliminates visual rendering bugs and enables rapid enterprise ERP/CRM development cycles.", class: "text-gray-400 text-sm leading-relaxed"
          end
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
