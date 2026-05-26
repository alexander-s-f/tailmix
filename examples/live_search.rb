# frozen_string_literal: true

# Live Search component — shows watch + fetch, loading state, empty state
#
# The `watch state.query` block fires every time the query changes.
# The input's `on :input` handler updates state.query from the event value.
# Together they create reactive live search with no extra JS.
#
# Usage (Arbre):
#
#   search = LiveSearchComponent.new
#   ui     = search.ui
#
#   div ui.root do
#     div ui.search_box do
#       span ui.search_icon          # magnifying glass SVG
#       input ui.input, type: "text", placeholder: "Search…", value: ""
#       span ui.clear_btn            # × button, visible when query non-empty
#     end
#
#     # Loading
#     div ui.spinner
#
#     # Empty state
#     div ui.empty_state do
#       para "No results found."
#     end
#
#     # Results list — populated server-side from state.results (JSON)
#     ul ui.results_list do
#       # In a real component you'd iterate state.results and render items.
#       # With Tailmix, the JS runtime updates the DOM; SSR renders initial state.
#     end
#   end

class LiveSearchComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :query,   default: ""
    state :results, default: [], type: :json
    state :loading, default: false
    state :focused, default: false

    # ── Root ─────────────────────────────────────────────────────────────────
    element :root, "relative w-full max-w-lg"

    # ── Search box ───────────────────────────────────────────────────────────
    element :search_box, "relative flex items-center rounded-xl border bg-white shadow-sm
                          transition-all duration-200" do
      style condition: state.focused do
        classes "ring-2 ring-blue-500 border-blue-500"
        otherwise do
          classes "border-gray-300 hover:border-gray-400"
        end
      end
    end

    element :search_icon, "absolute left-3 h-5 w-5 text-gray-400 pointer-events-none"

    element :input, "w-full pl-10 pr-10 py-3 bg-transparent text-sm text-gray-900
                     placeholder:text-gray-400 focus:outline-none rounded-xl" do
      on :input do
        set state.query, event.value
      end
      on :focus do
        set state.focused, true
      end
      on :blur do
        set state.focused, false
      end
    end

    element :clear_btn, "absolute right-3 h-5 w-5 text-gray-400 cursor-pointer
                         hover:text-gray-600 transition-colors" do
      on :click do
        set state.query, ""
        set state.results, []
      end

      style condition: state.query == "" do
        classes "hidden"
        otherwise do
          classes "block"
        end
      end
    end

    # ── Spinner ───────────────────────────────────────────────────────────────
    element :spinner, "mt-2 flex items-center justify-center py-4" do
      style condition: state.loading do
        classes "flex"
        otherwise do
          classes "hidden"
        end
      end
    end

    # ── Results ───────────────────────────────────────────────────────────────
    element :results_list, "mt-2 divide-y divide-gray-100 rounded-xl border border-gray-200
                            bg-white shadow-lg overflow-hidden" do
      style condition: state.loading do
        classes "opacity-50 pointer-events-none"
      end

      # Hide when empty
      style condition: state.results == [] do
        classes "hidden"
      end
    end

    element :result_item, "flex items-center gap-3 px-4 py-3 text-sm text-gray-700
                           hover:bg-blue-50 cursor-pointer transition-colors"

    # ── Empty state ───────────────────────────────────────────────────────────
    element :empty_state, "mt-2 rounded-xl border border-gray-200 bg-white py-8 text-center
                           text-sm text-gray-400" do
      # Show only when: query non-empty, not loading, and no results
      style condition: state.query == "" do
        classes "hidden"
      end

      style condition: state.loading do
        classes "hidden"
      end
    end

    # ── Reactive watcher ──────────────────────────────────────────────────────
    # Fires automatically when state.query changes (after any :input event).
    watch state.query do
      set state.loading, true
      fetch "/api/search", query: { q: state.query } do |response|
        set state.results, response
        set state.loading, false
      end
    end
  end

  def initialize
    @ui = tailmix
  end
end
