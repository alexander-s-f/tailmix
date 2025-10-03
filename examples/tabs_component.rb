# frozen_string_literal: true

class TabsComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :active_tab, default: :profile
    state :tabs, default: [
      { id: :profile, title: "Profile" },
      { id: :billing, title: "Billing" },
      { id: :settings, title: "Settings" }
    ]

    element :container, "p-4"

    element :tab, "px-4 py-2 rounded-t-lg cursor-pointer" do
      # Declare a local variable `current_tab` for the rendering scope of this element.
      # `param` is a built-in variable containing the hash passed during the call (e.g. ui.tab(id: :profile)).
      let :current_tab, state.tabs.find(id: param.id)

      # Bind the text content of the element to the `title` property of our local variable.
      # The DSL is clean. Just variables.
      bind :text, to: var(:current_tab).title

      on :click do
        # The action simply works with variables. The VM will find `active_tab` in the global scope,
        # and `current_tab` in the local rendering scope.
        set state.active_tab, var(:current_tab).id
        log("Click on tab:", var(:current_tab).title)
      end

      # The condition for `dimension` now reads like regular code, without cognitive load.
      dimension on: var(:current_tab).id.eq(state.active_tab) do
        variant true, "bg-blue-600 text-white"
        variant false, "bg-gray-800 text-gray-400 hover:bg-gray-700"
      end
    end

    element :panel, "px-4 py-2" do
      let :current_panel, state.tabs.find(id: param.id)

      dimension on: var(:current_panel).id.eq(state.active_tab).not? do
        variant true, "hidden"
        variant false, "block"
      end
    end
  end

  def initialize(tabs: [], active_tab: :profile)
    initial_state = { active_tab: active_tab }
    initial_state[:tabs] = tabs if tabs.present?
    @ui = tailmix(**initial_state)
  end
end
