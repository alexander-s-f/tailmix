# frozen_string_literal: true

require "json"
require "time"

module TailmixUi
  class MCPServer
    def self.start
      new.start
    end

    def initialize
      @running = false
    end

    def start
      @running = true
      $stdout.sync = true
      
      # Redirect stderr/logs to tailmix_mcp.log
      log_dir = defined?(Rails) ? Rails.root.join("log") : Pathname.new(Dir.pwd)
      log_path = log_dir.join("tailmix_mcp.log")
      
      begin
        FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)
        @log_file = File.open(log_path, "a")
      rescue => e
        @log_file = File.open("tailmix_mcp.log", "a") rescue nil
      end
      
      log("Tailmix MCP Server started successfully.")

      while @running
        begin
          line = $stdin.gets
          break if line.nil? # EOF

          line = line.strip
          next if line.empty?

          request = JSON.parse(line)
          log("Received request: #{request.inspect}")
          response = handle_request(request)
          if response
            log("Sending response: #{response.inspect}")
            $stdout.puts(JSON.generate(response))
          end
        rescue => e
          log("Error in main loop: #{e.message}\n#{e.backtrace.join("\n")}")
        end
      end
    end

    private

    def log(msg)
      return unless @log_file
      @log_file.puts("[#{Time.now.iso8601}] #{msg}")
      @log_file.flush
    end

    def handle_request(req)
      method = req["method"]
      id = req["id"]

      case method
      when "initialize"
        {
          jsonrpc: "2.0",
          id: id,
          result: {
            protocolVersion: "2024-11-05",
            capabilities: {
              tools: {}
            },
            serverInfo: {
              name: "tailmix-ui-mcp",
              version: "1.0.0"
            }
          }
        }
      when "notifications/initialized"
        log("Handshake completed successfully.")
        nil
      when "tools/list"
        {
          jsonrpc: "2.0",
          id: id,
          result: {
            tools: [
              {
                name: "tailmix_list_components",
                description: "List all available Tailmix UI components, their source file locations, and supported variants.",
                inputSchema: {
                  type: "object",
                  properties: {}
                }
              },
              {
                name: "tailmix_get_component_definition",
                description: "Retrieve the compiled JSON/Hash CVA definition for a specific component (variants, states, styling rules).",
                inputSchema: {
                  type: "object",
                  properties: {
                    component_name: {
                      type: "string",
                      description: "The name of the component (e.g., 'button', 'badge', 'card', 'tabs', 'modal')"
                    }
                  },
                  required: ["component_name"]
                }
              },
              {
                name: "tailmix_render_component",
                description: "Render a specific component in SSR mode with given arguments/variants/block content and verify its HTML.",
                inputSchema: {
                  type: "object",
                  properties: {
                    component_name: {
                      type: "string",
                      description: "The name of the component (e.g., 'button', 'badge', 'card', 'tabs', 'modal')"
                    },
                    args: {
                      type: "array",
                      description: "Positional arguments (e.g., ['Trash'] or [true])"
                    },
                    kwargs: {
                      type: "object",
                      description: "Keyword arguments (e.g., {'size': 'xs', 'color': 'danger'})"
                    },
                    content: {
                      type: "string",
                      description: "Block content to render inside the component"
                    }
                  },
                  required: ["component_name"]
                }
              },
              {
                name: "tailmix_get_state_mappings",
                description: "Get the current active status-to-style mappings resolved by StateResolver.",
                inputSchema: {
                  type: "object",
                  properties: {}
                }
              }
            ]
          }
        }
      when "tools/call"
        name = req.dig("params", "name")
        arguments = req.dig("params", "arguments") || {}
        result = call_tool(name, arguments)
        {
          jsonrpc: "2.0",
          id: id,
          result: result
        }
      else
        {
          jsonrpc: "2.0",
          id: id,
          error: {
            code: -32601,
            message: "Method not found: #{method}"
          }
        }
      end
    end

    def call_tool(name, args)
      case name
      when "tailmix_list_components"
        components = [:button, :badge, :card, :tabs, :modal].map do |sym|
          comp_class, state_class = TailmixUi.resolve_component(sym)
          next nil unless comp_class

          source_file, line_number = nil, nil
          if comp_class.instance_methods(false).include?(:build)
            source_file, line_number = comp_class.instance_method(:build).source_location
          end
          if source_file.nil?
            source_file, line_number = Object.const_source_location(comp_class.name) rescue [nil, nil]
          end
          
          variants = []
          if state_class
            begin
              kwargs = {}
              state_class.instance_method(:initialize).parameters.each do |t, n|
                kwargs[n] = :default if t == :keyreq || t == :key
              end
              inst = state_class.new(**kwargs)
              if inst.respond_to?(:ui) && inst.ui.class.respond_to?(:definition)
                variants = inst.ui.class.definition[:variants].keys
              end
            rescue => e
              log("Error extracting variants for #{sym}: #{e.message}")
            end
          end

          root_path = defined?(Rails) ? Rails.root.to_s : Dir.pwd
          relative_source = source_file ? source_file.sub("#{root_path}/", "") : "Unknown"

          {
            symbol: sym.to_s,
            class_name: comp_class.name,
            source: source_file ? "#{relative_source}:#{line_number}" : "Unknown",
            variants: variants
          }
        end.compact

        {
          content: [
            {
              type: "text",
              text: JSON.pretty_generate({ components: components })
            }
          ]
        }

      when "tailmix_get_component_definition"
        comp_name = args["component_name"]
        comp_class, state_class = TailmixUi.resolve_component(comp_name)
        unless comp_class
          return {
            isError: true,
            content: [{ type: "text", text: "Error: Component '#{comp_name}' not found." }]
          }
        end

        definition = {}
        if state_class
          begin
            kwargs = {}
            state_class.instance_method(:initialize).parameters.each do |t, n|
              kwargs[n] = :default if t == :keyreq || t == :key
            end
            inst = state_class.new(**kwargs)
            if inst.respond_to?(:ui) && inst.ui.class.respond_to?(:definition)
              definition = inst.ui.class.definition
            end
          rescue => e
            return {
              isError: true,
              content: [{ type: "text", text: "Error instantiating CVA definition: #{e.message}" }]
            }
          end
        end

        {
          content: [
            {
              type: "text",
              text: JSON.pretty_generate(definition)
            }
          ]
        }

      when "tailmix_render_component"
        comp_name = args["component_name"]
        pos_args = args["args"] || []
        kw_args = args["kwargs"] || {}
        content_str = args["content"] || ""

        sym_kw_args = kw_args.transform_keys(&:to_sym)

        begin
          html = TailmixUi.render(comp_name, *pos_args, **sym_kw_args) do
            text_node(content_str) if content_str.present?
          end

          {
            content: [
              {
                type: "text",
                text: html
              }
            ]
          }
        rescue => e
          {
            isError: true,
            content: [
              {
                type: "text",
                text: "Error rendering component: #{e.message}\n#{e.backtrace.join("\n")}"
              }
            ]
          }
        end

      when "tailmix_get_state_mappings"
        mappings = TailmixUi.configuration.state_mappings
        {
          content: [
            {
              type: "text",
              text: JSON.pretty_generate(mappings)
            }
          ]
        }

      else
        {
          isError: true,
          content: [{ type: "text", text: "Error: Tool '#{name}' not found." }]
        }
      end
    end
  end
end
