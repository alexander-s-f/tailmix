# frozen_string_literal: true

# Modal component — shows toggle, dispatch, style/otherwise
#
# Usage (Arbre):
#
#   modal = ModalComponent.new
#   ui    = modal.ui
#
#   # Trigger from anywhere on the page:
#   button "Open", ui.open_btn
#
#   # The modal itself:
#   div ui.backdrop do
#     div ui.panel do
#       div ui.header do
#         h3 "Confirm action"
#         button ui.close_btn do
#           text_node "×"
#         end
#       end
#       div ui.body do
#         para "Are you sure you want to continue?"
#       end
#       div ui.footer do
#         button ui.cancel_btn do
#           text_node "Cancel"
#         end
#         button ui.confirm_btn do
#           text_node "Confirm"
#         end
#       end
#     end
#   end

class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :open, default: false

    # ── Trigger ────────────────────────────────────────────────────────────────
    element :open_btn, "inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg
                        hover:bg-blue-700 transition-colors font-medium text-sm" do
      on :click do
        toggle state.open
      end
    end

    # ── Backdrop ────────────────────────────────────────────────────────────────
    element :backdrop, "fixed inset-0 z-40 flex items-center justify-center p-4" do
      # Close on click outside panel (click lands on backdrop, not panel)
      on :click do
        toggle state.open
      end

      style condition: state.open do
        classes "bg-black/50 backdrop-blur-sm"
        aria hidden: false
        otherwise do
          classes "hidden"
          aria hidden: true
        end
      end
    end

    # ── Panel ───────────────────────────────────────────────────────────────────
    element :panel, "relative z-50 w-full max-w-md rounded-xl bg-white shadow-2xl
                     ring-1 ring-black/5 transform transition-all" do
      # Stop backdrop click from propagating into panel
      # (handled via stopPropagation in template with data-action or similar)
      on :click do
        # no-op: handled at element level to stop bubbling in template
      end

      style condition: state.open do
        classes "scale-100 opacity-100"
        otherwise do
          classes "scale-95 opacity-0 pointer-events-none"
        end
      end
    end

    # ── Header ──────────────────────────────────────────────────────────────────
    element :header, "flex items-center justify-between px-6 py-4 border-b border-gray-100"

    element :title, "text-lg font-semibold text-gray-900"

    element :close_btn, "rounded-lg p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100
                         transition-colors" do
      on :click do
        toggle state.open
      end
    end

    # ── Body ────────────────────────────────────────────────────────────────────
    element :body, "px-6 py-5 text-sm text-gray-600 leading-relaxed"

    # ── Footer ──────────────────────────────────────────────────────────────────
    element :footer, "flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100"

    element :cancel_btn, "px-4 py-2 text-sm font-medium text-gray-700 bg-white border
                          border-gray-300 rounded-lg hover:bg-gray-50 transition-colors" do
      on :click do
        toggle state.open
      end
    end

    element :confirm_btn, "px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg
                           hover:bg-blue-700 transition-colors" do
      on :click do
        # Fire a custom event so parent components can react
        dispatch "modal:confirmed"
        toggle state.open
      end
    end
  end

  def initialize(open: false)
    @ui = tailmix(open: open)
  end
end
