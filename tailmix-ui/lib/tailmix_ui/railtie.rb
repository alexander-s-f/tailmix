# frozen_string_literal: true

if defined?(Rails::Railtie)
  module TailmixUi
    class Railtie < ::Rails::Railtie
      rake_tasks do
        path = File.expand_path("../../tasks/tailmix_mcp.rake", __FILE__)
        load path if File.exist?(path)
      end
    end
  end
end
