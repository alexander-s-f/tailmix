# frozen_string_literal: true

require_relative "./arbre/context_helpers"

module Tailmix
  class Engine < ::Rails::Engine
    config.before_initialize do
      Rails.application.config.assets.paths << Engine.root.join("app/javascript")
    end

    PRECOMPILE_ASSETS = %w[ runtime/index.js ]

    initializer "tailmix.assets" do
      if Rails.application.config.respond_to?(:assets)
        Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end

    initializer "tailmix.add_middleware" do |app|
      app.middleware.use Tailmix::Middleware::RegistryCleaner
    end

    initializer "tailmix.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Tailmix::ViewHelpers
      end
    end
  end
end
