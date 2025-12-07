# frozen_string_literal: true

module Tailmix
  class Engine < ::Rails::Engine
    isolate_namespace Tailmix

    config.before_initialize do
      Rails.application.config.assets.paths << Engine.root.join("app/javascript")
    end

    PRECOMPILE_ASSETS = %w[ runtime/index.js ]

    initializer "tailmix.assets" do
      if Rails.application.config.respond_to?(:assets)
        Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end

    # initializer "tailmix.middleware" do |app|
    #   if Rails.env.development?
    #     app.middleware.use Tailmix::Middleware::DefinitionsProvider
    #   end
    # end

    initializer "tailmix.view_helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Tailmix::ViewHelper
      end
    end
  end
end
