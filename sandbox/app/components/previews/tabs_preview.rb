# frozen_string_literal: true

class TabsPreview < Lookbook::Preview
  # @param active select { choices: [tab1, tab2, tab3] } "Default active tab"
  def standard(active: "tab1")
    html = Arbre::Context.new do
      tabs active: active do
        tab "Profile", id: "tab1" do
          div class: "p-4 bg-gray-900 border border-gray-800 rounded-lg text-sm" do
            para "Profile Panel: shows personal details of the lead."
          end
        end
        tab "Deals (ERP)", id: "tab2" do
          div class: "p-4 bg-gray-900 border border-gray-800 rounded-lg text-sm" do
            para "Deals Panel: active contracts, billing, and balance."
          end
        end
        tab "Activity Logs", id: "tab3" do
          div class: "p-4 bg-gray-900 border border-gray-800 rounded-lg text-sm" do
            para "Logs Panel: history of calls, emails, and system triggers."
          end
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
