# frozen_string_literal: true

require_relative "view_helpers"

module Tailmix
  class Engine < ::Rails::Engine
    isolate_namespace Tailmix

    config.before_initialize do
      Rails.application.config.assets.paths << Engine.root.join("app/javascript")
    end

    initializer "tailmix.assets" do |app|
      app.config.assets.paths << root.join("app/javascript").to_s
      app.config.assets.paths << root.join("app/assets/javascripts").to_s

      if app.config.respond_to?(:assets) && app.config.assets.respond_to?(:precompile)
        app.config.assets.precompile += %w[
          tailmix/tailmix.bundle.js
        ]
      end
    end

    initializer "tailmix.view_helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Tailmix::ViewHelpers
      end
    end
  end
end
