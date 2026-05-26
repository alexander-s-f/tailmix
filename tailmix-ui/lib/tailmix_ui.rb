# frozen_string_literal: true

require "arbre"
require "active_support/all"
require "tailmix"

require_relative "tailmix_ui/version"
require_relative "tailmix_ui/configuration"
require_relative "tailmix_ui/state_resolver"
require_relative "tailmix_ui/base_component"
require_relative "tailmix_ui/mcp_server"
require_relative "tailmix_ui/railtie"

require_relative "tailmix_ui/components/button"
require_relative "tailmix_ui/components/badge"
require_relative "tailmix_ui/components/card"
require_relative "tailmix_ui/components/tabs"
require_relative "tailmix_ui/components/modal"
require_relative "tailmix_ui/components/dropdown"

module TailmixUi
  class Error < StandardError; end

  def self.resolve_component(class_or_symbol)
    if class_or_symbol.is_a?(Symbol) || class_or_symbol.is_a?(String)
      sym = class_or_symbol.to_sym
      case sym
      when :btn, :button
        [Components::Button, Components::ButtonState]
      when :badge
        [Components::Badge, Components::BadgeState]
      when :card
        [Components::Card, Components::CardState]
      when :tabs
        [Components::Tabs, Components::TabsState]
      when :modal
        [Components::Modal, Components::ModalState]
      when :dropdown
        [Components::Dropdown, Components::DropdownState]
      else
        class_name = sym.to_s.camelize
        comp_class = Components.const_get(class_name) rescue nil
        state_class = Components.const_get("#{class_name}State") rescue nil
        [comp_class, state_class]
      end
    elsif class_or_symbol.is_a?(Class)
      comp_class = class_or_symbol
      class_name = comp_class.name.demodulize
      state_class = Components.const_get("#{class_name}State") rescue nil
      [comp_class, state_class]
    else
      [nil, nil]
    end
  end

  def self.resolve_builder_method(comp_class)
    case comp_class.name
    when "TailmixUi::Components::Button" then :btn
    when "TailmixUi::Components::Badge" then :badge
    when "TailmixUi::Components::Card" then :card
    when "TailmixUi::Components::Tabs" then :tabs
    when "TailmixUi::Components::Modal" then :modal
    when "TailmixUi::Components::Dropdown" then :dropdown
    else
      comp_class.name.demodulize.underscore.to_sym
    end
  end

  def self.render(component_symbol, *args, **kwargs, &block)
    comp_class, _ = resolve_component(component_symbol)
    unless comp_class
      raise ArgumentError, "Component '#{component_symbol}' not found."
    end

    builder_name = resolve_builder_method(comp_class)
    context = Arbre::Context.new
    # Enforce development env attributes rendering
    old_env = ENV["TAILMIX_ENV"]
    ENV["TAILMIX_ENV"] = "development"

    begin
      context.instance_eval do
        send(builder_name, *args, **kwargs, &block)
      end
    ensure
      ENV["TAILMIX_ENV"] = old_env
    end
    context.to_s
  end

  def self.inspect(component_class_or_symbol)
    comp_class, state_class = resolve_component(component_class_or_symbol)
    unless comp_class
      puts "\e[31mError: Component '#{component_class_or_symbol}' not found.\e[0m"
      return
    end

    source_file, line_number = nil, nil
    if comp_class.instance_methods(false).include?(:build)
      source_file, line_number = comp_class.instance_method(:build).source_location
    end
    if source_file.nil?
      source_file, line_number = Object.const_source_location(comp_class.name) rescue [nil, nil]
    end

    if source_file
      root_path = defined?(Rails) ? Rails.root.to_s : Dir.pwd
      relative_path = source_file.sub("#{root_path}/", "")
      source_info = "#{relative_path}:#{line_number}"
    else
      source_info = "Unknown"
    end

    cva_definition = nil
    if state_class
      begin
        kwargs = {}
        state_class.instance_method(:initialize).parameters.each do |type, name|
          if type == :keyreq || type == :key
            kwargs[name] = :default
          end
        end
        inst = state_class.new(**kwargs)
        if inst.respond_to?(:ui) && inst.ui.class.respond_to?(:definition)
          cva_definition = inst.ui.class.definition
        end
      rescue => e
        # ignore error during layout inspection
      end
    end

    puts "\e[38;2;147;51;234m" + "=" * 80 + "\e[0m"
    puts "\e[1;38;2;147;51;234mTailmix UI Component: #{comp_class.name}\e[0m"
    puts "\e[38;2;147;51;234m" + "=" * 80 + "\e[0m"
    puts "\e[1m📄 Ruby Source:\e[0m     \e[36m#{source_info}\e[0m"
    puts "\e[1m🧱 Arbre Class:\e[0m     #{comp_class.name}"
    puts "\e[1m🧬 CVA State:\e[0m       #{state_class ? state_class.name : 'None'}"

    if cva_definition
      puts "\n\e[1m📐 Available Variants:\e[0m"
      if cva_definition[:variants] && !cva_definition[:variants].empty?
        cva_definition[:variants].each do |var_name, var_config|
          possible_values = [var_config[:default] || :default]
          cva_definition[:elements].each do |el|
            el[:rules].each do |rule|
              if rule[0] == :match && rule[1] == [:variant, var_name.to_s]
                possible_values += rule[2].keys.map(&:to_sym)
              end
            end
          end
          possible_values = possible_values.uniq
          puts "   - \e[33m#{var_name}\e[0m: #{possible_values.inspect} (default: \e[32m:#{var_config[:default] || :default}\e[0m)"
        end
      else
        puts "   No variants defined."
      end

      puts "\n\e[1m🧬 Reactive States:\e[0m"
      if cva_definition[:states] && !cva_definition[:states].empty?
        cva_definition[:states].each do |state_name, default_val|
          type = cva_definition[:types] ? cva_definition[:types][state_name] : nil
          puts "   - \e[33m#{state_name}\e[0m: default \e[32m#{default_val.inspect}\e[0m (type: \e[36m#{type || 'unknown'}\e[0m)"
        end
      else
        puts "   No reactive states defined."
      end
    end

    puts "\n\e[1m🔴 Status Mappings (StateResolver):\e[0m"
    mappings = TailmixUi.configuration.state_mappings
    sample_mappings = {
      green: mappings[:green]&.take(3),
      yellow: mappings[:yellow]&.take(3),
      red: mappings[:red]&.take(3)
    }
    sample_mappings.each do |color, list|
      if list
        puts "   - \e[32m:#{color}\e[0m -> #{list.map { |s| ":#{s}" }.join(', ')} ..."
      end
    end

    builder_name = resolve_builder_method(comp_class)
    puts "\n\e[1m⚡ Sample SSR Test Render (#{builder_name}):\e[0m"
    begin
      html_sample = ""
      case builder_name
      when :btn
        html_sample = render(:btn, "Test Button", color: :primary, size: :sm)
      when :badge
        html_sample = render(:badge, :completed, size: :sm)
      when :card
        html_sample = render(:card, "Test Card") { "Card Content" }
      when :tabs
        html_sample = render(:tabs, active: "tab1") { tab("Tab 1", id: "tab1") { "Tab 1 Content" } }
      when :modal
        html_sample = render(:modal, open: false) { "Modal Content" }
      when :dropdown
        html_sample = render(:dropdown) { trigger("Options"); menu { item("Edit Profile", href: "#edit") } }
      else
        html_sample = render(builder_name)
      end
      
      highlighted = html_sample
        .gsub(/(<\/?[a-zA-Z0-9_\-]+)/, "\e[34m\\1\e[0m")
        .gsub(/([a-zA-Z0-9_\-]+)=("[^"]*")/, "\e[33m\\1\e[0m=\e[32m\\2\e[0m")
        .gsub(/(>)/, "\e[34m>\e[0m")
      puts "   #{highlighted}"
    rescue => e
      puts "   \e[31mFailed to render sample: #{e.message}\e[0m"
    end
    puts "\e[38;2;147;51;234m" + "=" * 80 + "\e[0m"
    nil
  end
end
