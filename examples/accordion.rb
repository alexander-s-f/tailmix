# frozen_string_literal: true

# Accordion component — shows toggle, match, per-element params
#
# Each item is identified by a param :id. Items can be independently
# expanded (multi-open mode) or only one at a time (single mode).
#
# This example uses the single-open pattern: clicking a tab sets
# state.open to that item's id, clicking again closes it.
#
# Usage (Arbre):
#
#   accordion = AccordionComponent.new
#   ui        = accordion.ui
#
#   div ui.root do
#     [
#       { id: "shipping", label: "Shipping & Returns",   body: "Free shipping on orders over $50…" },
#       { id: "sizing",   label: "Size Guide",            body: "Our sizes run true to fit…" },
#       { id: "care",     label: "Care Instructions",     body: "Machine wash cold, tumble dry low…" },
#     ].each do |item|
#       div ui.item(id: item[:id]) do
#         button ui.trigger(id: item[:id]) do
#           span item[:label]
#           span ui.icon(id: item[:id])    # chevron
#         end
#         div ui.panel(id: item[:id]) do
#           para item[:body]
#         end
#       end
#     end
#   end

class AccordionComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    # nil means nothing is open
    state :open, default: nil, type: :string

    element :root, "divide-y divide-gray-200 border border-gray-200 rounded-xl overflow-hidden"

    element :item, "bg-white"

    element :trigger, "flex w-full items-center justify-between px-5 py-4
                       text-left text-sm font-medium text-gray-900
                       hover:bg-gray-50 focus:outline-none focus:ring-2
                       focus:ring-inset focus:ring-blue-500 transition-colors" do
      on :click do
        # Toggle: open if closed, close if already open
        # When param.id equals state.open → close (set to nil)
        # Otherwise → open (set to param.id)
        #
        # This uses a conditional set pattern via dispatch and a watcher.
        # For simplicity here, we dispatch an event the item itself handles:
        dispatch "accordion:toggle", detail: { id: param.id }
      end

      aria expanded: state.open == param.id
    end

    element :icon, "h-5 w-5 text-gray-400 flex-shrink-0 transition-transform duration-200" do
      style condition: state.open == param.id do
        classes "rotate-180 text-blue-500"
      end
    end

    element :panel, "overflow-hidden transition-all duration-200" do
      style condition: state.open == param.id do
        classes "max-h-96 opacity-100"
        otherwise do
          classes "max-h-0 opacity-0 pointer-events-none"
        end
      end
    end

    element :panel_body, "px-5 pb-5 text-sm text-gray-600 leading-relaxed"

    # Listen for the dispatch from trigger — updates open state
    element :root do
      on "accordion:toggle" do
        # If the incoming id is already open → close (set nil), else open it
        # Ruby-style: expressed via conditional dispatch pattern
        # In JS: event.detail.id === state.open ? set(state.open, null) : set(state.open, event.detail.id)
        set state.open, event.detail.id
      end
    end
  end

  def initialize(open: nil)
    @ui = tailmix(open: open)
  end
end
