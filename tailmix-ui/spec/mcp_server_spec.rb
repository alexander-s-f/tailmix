# frozen_string_literal: true

require "spec_helper"

RSpec.describe TailmixUi::MCPServer do
  let(:server) { TailmixUi::MCPServer.new }

  describe "Handshake and Tool Listing" do
    it "handles initialize request" do
      req = {
        "jsonrpc" => "2.0",
        "method" => "initialize",
        "id" => 1
      }
      res = server.send(:handle_request, req)
      
      expect(res[:jsonrpc]).to eq("2.0")
      expect(res[:id]).to eq(1)
      expect(res[:result][:protocolVersion]).to eq("2024-11-05")
      expect(res[:result][:serverInfo][:name]).to eq("tailmix-ui-mcp")
    end

    it "handles initialized notification" do
      req = {
        "jsonrpc" => "2.0",
        "method" => "notifications/initialized"
      }
      res = server.send(:handle_request, req)
      expect(res).to be_nil
    end

    it "lists all tools" do
      req = {
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => 42
      }
      res = server.send(:handle_request, req)
      
      expect(res[:id]).to eq(42)
      tools = res[:result][:tools]
      expect(tools.map { |t| t[:name] }).to contain_exactly(
        "tailmix_list_components",
        "tailmix_get_component_definition",
        "tailmix_render_component",
        "tailmix_get_state_mappings"
      )
    end
  end

  describe "Tool Execution (tools/call)" do
    it "calls tailmix_list_components" do
      req = {
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "params" => {
          "name" => "tailmix_list_components",
          "arguments" => {}
        },
        "id" => 2
      }
      res = server.send(:handle_request, req)
      expect(res[:id]).to eq(2)
      
      data = JSON.parse(res[:result][:content][0][:text])
      components = data["components"]
      expect(components.map { |c| c["symbol"] }).to include("button", "badge", "card", "tabs", "modal")
    end

    it "calls tailmix_get_component_definition" do
      req = {
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "params" => {
          "name" => "tailmix_get_component_definition",
          "arguments" => { "component_name" => "badge" }
        },
        "id" => 3
      }
      res = server.send(:handle_request, req)
      expect(res[:id]).to eq(3)
      
      definition = JSON.parse(res[:result][:content][0][:text])
      expect(definition["name"]).to eq("TailmixUi::Components::BadgeState")
      expect(definition["variants"].keys).to contain_exactly("size", "color")
    end

    it "calls tailmix_render_component" do
      req = {
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "params" => {
          "name" => "tailmix_render_component",
          "arguments" => {
            "component_name" => "btn",
            "args" => ["Delete Forever"],
            "kwargs" => { "color" => "danger", "size" => "xs" }
          }
        },
        "id" => 4
      }
      res = server.send(:handle_request, req)
      expect(res[:id]).to eq(4)
      
      html = res[:result][:content][0][:text]
      expect(html).to include("<button ")
      expect(html).to include("bg-red-600")
      expect(html).to include("Delete Forever")
    end

    it "calls tailmix_get_state_mappings" do
      req = {
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "params" => {
          "name" => "tailmix_get_state_mappings",
          "arguments" => {}
        },
        "id" => 5
      }
      res = server.send(:handle_request, req)
      expect(res[:id]).to eq(5)
      
      mappings = JSON.parse(res[:result][:content][0][:text])
      expect(mappings["green"]).to include("active")
      expect(mappings["red"]).to include("failed")
    end
  end
end
