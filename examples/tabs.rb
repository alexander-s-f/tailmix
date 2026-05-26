# frozen_string_literal: true

# Tabs component — shows state, set, style/otherwise, per-element params
#
# Usage (Arbre):
#
#   tabs = TabsComponent.new(active: "profile")
#   ui   = tabs.ui
#
#   div ui.root do
#     nav ui.tablist, role: "tablist" do
#       %w[profile billing security].each do |id|
#         button ui.tab(id: id), role: "tab" do
#           text_node id.capitalize
#         end
#       end
#     end
#
#     div ui.panels do
#       div ui.panel(id: "profile"), role: "tabpanel" do
#         para "Profile settings…"
#       end
#       div ui.panel(id: "billing"), role: "tabpanel" do
#         para "Billing information…"
#       end
#       div ui.panel(id: "security"), role: "tabpanel" do
#         para "Security settings…"
#       end
#     end
#   end
#
# Or use the builder helper (Arbre component style):
#
#   tabs active: "profile" do
#     tab "Profile",  id: "profile"  do … end
#     tab "Billing",  id: "billing"  do … end
#     tab "Security", id: "security" do … end
#   end

class TabsComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :active, default: "profile"

    # ── Shell ─────────────────────────────────────────────────────────────────
    element :root,   "w-full"
    element :panels, "mt-4"

    # ── Tab list ──────────────────────────────────────────────────────────────
    element :tablist, "flex gap-1 border-b border-gray-200"

    # ── Individual tab button ─────────────────────────────────────────────────
    element :tab, "px-4 py-2.5 text-sm font-medium rounded-t-lg -mb-px
                   transition-colors duration-150 cursor-pointer focus:outline-none
                   focus:ring-2 focus:ring-inset focus:ring-blue-500" do
      on :click do
        set state.active, param.id
      end

      style condition: state.active == param.id do
        classes "border border-b-white border-gray-200 text-blue-600 bg-white"
        aria selected: true
        otherwise do
          classes "border border-transparent text-gray-500 hover:text-gray-700 hover:bg-gray-50"
          aria selected: false
        end
      end
    end

    # ── Individual tab panel ──────────────────────────────────────────────────
    element :panel do
      style condition: state.active == param.id do
        classes "block"
        aria hidden: false
        otherwise do
          classes "hidden"
          aria hidden: true
        end
      end
    end
  end

  def initialize(active: "profile")
    @ui = tailmix(active: active)
  end
end

# ── Arbre builder variant ─────────────────────────────────────────────────────
# Wrap TabsComponent as a reusable Arbre builder component.

class Tabs < ::Arbre::Component
  builder_method :tabs
  attr_reader :ui

  def build(options = {})
    @active  = options.delete(:active) || "profile"
    @tabs_ui = TabsComponent.new(active: @active).ui

    super(@tabs_ui.root(root: true))

    div @tabs_ui.tablist, role: "tablist" do
      @nav_target = current_arbre_element
    end

    div @tabs_ui.panels do
      @panels_target = current_arbre_element
    end
  end

  def tab(label, id: nil, &block)
    id = (id || label.to_s.parameterize).to_s

    @nav_target << build_nav_item(label, id: id)
    @panels_target << build_panel(id: id, &block)
  end

  private

  def build_nav_item(label, id:)
    button @tabs_ui.tab(id: id), role: "tab" do
      text_node label.is_a?(Symbol) ? label.to_s.humanize : label
    end
  end

  def build_panel(id:, &block)
    div @tabs_ui.panel(id: id), role: "tabpanel" do
      block.call if block
    end
  end
end
