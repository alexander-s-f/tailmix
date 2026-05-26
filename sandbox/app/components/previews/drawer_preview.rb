# frozen_string_literal: true

class DrawerPreview < Lookbook::Preview
  # @param align select { choices: [right, left] } "Slide direction alignment"
  # @param open select { choices: [true, false] } "Default open state"
  def standard(align: :right, open: true)
    is_open = (open == "true" || open == true)
    html = Arbre::Context.new do
      div class: "relative h-96 w-full flex items-center justify-center bg-gray-950/40 p-8 rounded-xl border border-gray-900 overflow-hidden" do
        
        # Click trigger to show drawer
        btn "Open Slide-Over Drawer", color: :primary, size: :md, data: { action: "click->drawer-demo#toggle" }

        drawer id: "drawer-demo", align: align.to_sym, open: is_open do
          panel do
            header "Lead Profile Details"
            
            body do
              div class: "space-y-4 text-sm text-gray-300" do
                div class: "flex justify-between border-b border-gray-800 pb-2" do
                  span "Company Name", class: "text-gray-500 font-medium"
                  span "Acme Corporation", class: "text-white"
                end
                div class: "flex justify-between border-b border-gray-800 pb-2" do
                  span "Contact Email", class: "text-gray-500 font-medium"
                  span "ceo@acme.com", class: "text-white"
                end
                div class: "flex justify-between border-b border-gray-800 pb-2" do
                  span "Deal Value", class: "text-gray-500 font-medium"
                  span "$120,000", class: "text-emerald-400 font-bold"
                end
                div class: "pt-2" do
                  span "Description", class: "text-gray-500 font-medium block mb-1"
                  para "Customer is looking for a multi-tenant enterprise CRM migration with declarative layout support.", class: "text-gray-400 leading-relaxed"
                end
              end
            end

            footer do
              btn "Cancel", color: :neutral, size: :sm, data: { action: "click->drawer-demo#toggle" }
              btn "Save Progress", color: :primary, size: :sm
            end
          end
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
