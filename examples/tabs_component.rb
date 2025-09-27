class TabsComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :active_tab, default: :profile, persist: true, sync: :hash
    state :tabs, collection: true, default: [
      { tab: :profile, title: "Profile" },
      { tab: :billing, title: "Billing" }
    ]

    element :container, "p-4"

    element :tab, "px-4 py-2 rounded-t-lg cursor-pointer" do
      constructor do |param|
        key :tab, to: state.tabs, on: param.key

        # Use `this` for the event
        on :click do |b|
          b.set(state.active_tab, this.key.tab.tab)
          log concat("click: ", this.key.tab.tab)
        end

        # Use `item` to declare rendering
        dimension :active, on: item.tab.eq(state.active_tab) do
          variant true, "bg-blue-600 text-white"
          variant false, "bg-gray-800 text-gray-400 hover:bg-gray-700"
        end
      end
    end

    element :panel, "px-4 py-2" do
      constructor do |param|
        key :tab, to: state.tabs, on: param.key

        dimension :hidden, on: item.tab.eq(state.active_tab).not? do
          variant true, "hidden"
          variant false, "block"
        end
      end
    end
  end

  def initialize(tabs: [], active_tab: :profile)
    @ui = tailmix(tabs: tabs.presence, active_tab: active_tab)
  end
end
