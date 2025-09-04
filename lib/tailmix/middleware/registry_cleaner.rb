# frozen_string_literal: true

module Tailmix
  module Middleware
    class RegistryCleaner
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      ensure
        Tailmix::Registry.instance.clear!
      end
    end
  end
end
