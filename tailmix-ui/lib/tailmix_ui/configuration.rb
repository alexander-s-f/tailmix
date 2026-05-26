# frozen_string_literal: true

module TailmixUi
  class Configuration
    attr_accessor :icon_provider, :icon_storage_path, :icon_renderer

    def initialize
      @icon_provider = :custom
      @icon_storage_path = "app/assets/icons"
      @icon_renderer = ->(name, options = {}) {
        if defined?(Rails)
          path = Rails.root.join(@icon_storage_path, "#{name}.svg")
          if File.exist?(path)
            File.read(path).html_safe
          else
            "<!-- Icon '#{name}' not found at #{path} -->".html_safe
          end
        else
          "<!-- Icon '#{name}' (No Rails) -->".html_safe
        end
      }
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
