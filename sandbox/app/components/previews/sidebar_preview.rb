# frozen_string_literal: true

class SidebarPreview < Lookbook::Preview
  # @param open select { choices: [true, false] } "Default drawer open state (mobile)"
  def standard(open: false)
    is_open = (open == "true" || open == true)
    html = Arbre::Context.new do
      sidebar id: "sidebar-demo", open: is_open do
        # Sidebar drawer container
        drawer do
          div class: "flex items-center gap-2 mb-6 border-b border-gray-800 pb-4" do
            span "📊"
            span "CRM Layout Shell", class: "font-bold text-white tracking-wide"
          end

          div class: "flex flex-col gap-2 flex-grow" do
            a "Dashboard", href: "#", class: "px-3 py-2 text-sm font-semibold rounded-lg text-white bg-gray-900 border border-gray-800 transition-colors"
            a "CRM Leads", href: "#", class: "px-3 py-2 text-sm font-medium rounded-lg text-gray-400 hover:text-white hover:bg-gray-800/50 transition-colors"
            a "System Resource Stats", href: "#", class: "px-3 py-2 text-sm font-medium rounded-lg text-gray-400 hover:text-white hover:bg-gray-800/50 transition-colors"
          end

          div class: "mt-auto border-t border-gray-800 pt-4" do
            para "Tailmix UI v#{TailmixUi::VERSION}", class: "text-xs text-gray-500 font-medium"
          end
        end

        # Main content container
        main do
          header class: "flex justify-between items-center bg-gray-900/60 backdrop-blur border-b border-gray-800 p-4" do
            # Mobile drawer toggle menu trigger button
            button "data-tailmix-element": "toggle", class: "md:hidden p-2 text-gray-400 hover:text-white hover:bg-gray-800 rounded-lg cursor-pointer flex items-center justify-center" do
              span "☰"
            end

            span "System Admin Console", class: "text-sm font-bold text-white"
          end

          div class: "p-6 flex-grow flex items-center justify-center" do
            div class: "text-center max-w-sm" do
              h3 "Layout Shell Content Area", class: "text-lg font-bold text-white mb-2"
              para "The main dashboard layout view is rendered inside the main tag. Shrink your viewport size to test the collapsible mobile navigation drawer!", class: "text-sm text-gray-400"
            end
          end
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
