# frozen_string_literal: true

namespace :tailmix do
  desc "Boot the Tailmix UI Model Context Protocol (MCP) Server"
  task :mcp do
    # Load Rails environment if running within a Rails app
    if Rake::Task.task_defined?("environment")
      Rake::Task["environment"].invoke
    elsif defined?(Rails)
      # Rails is already initialized
    else
      require "tailmix_ui"
    end

    TailmixUi::MCPServer.start
  end
end
