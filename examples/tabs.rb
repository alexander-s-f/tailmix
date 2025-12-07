# frozen_string_literal: true

# require_relative "../lib/tailmix"

class Tabs < ::Arbre::Component
  include Tailmix
  builder_method :tabs
  attr_reader :ui

  tailmix do
    state :active, default: "profile"

    element :tabs, ""
    element :header, "mb-4 border-b border-gray-200 dark:border-gray-700 flex items-center"
    element :tablist, "flex flex-wrap -mb-px text-sm font-medium text-center"
    element :tabcontent, ""
    element :tab, "cursor-pointer px-4 py-2 font-medium transition-colors duration-200" do
      on :click do
        set state.active, param.id
        log "Tab clicked:", param.id
      end

      style condition: state.active == param.id do
        classes "border-b-2 border-blue-500 text-blue-600"
        aria selected: true
      end

      style condition: state.active != param.id do
        classes "text-gray-500 hover:text-gray-700 hover:border-gray-300 border-b-2 border-transparent"
        aria selected: false
      end
    end

    element :panel, "p-4" do
      style condition: state.active != param.id do
        classes "hidden"
      end
    end
  end

  def build(options = {})
    default_options = {}
    options = default_options.merge(options)

    @ui = tailmix(active: options.delete(:active))
    super(@ui.tabs(root: true))


    div @ui.header do
      @nav = ul @ui.tablist
    end

    @panels = div @ui.tabcontent
  end

  def tab(title, id: nil, &block)
    id = (id || title.to_s.parameterize).to_s
    @nav << build_nav(title, id: id)
    @panels << build_panel(title, id: id, &block)
  end

  private

  def build_nav(title, id:)
    li role: "presentation", class: "me-2" do
      button @ui.tab(id: id) do
        span title.is_a?(Symbol) ? title.to_s.humanize.titleize : title
      end
    end
  end

  def build_panel(title, id:, &block)
    div @ui.panel(id: id) do
      block.call
    end
  end
end
