# frozen_string_literal: true

require "json"
require_relative "ast"
require_relative "dsl/component_parser"
require_relative "visitors/debug_printer"
require_relative "compiler/json_generator"
require_relative "runtime/facade_builder"

module Tailmix
  module DSL
    attr_reader :tailmix_facade_class

    def tailmix(&block)
      ast = DSL::ComponentParser.parse(self.name, &block)

      @compiled_definition = Compiler::JSONGenerator.new.compile(ast)
      @tailmix_facade_class = Runtime::FacadeBuilder.build(@compiled_definition)

      if ENV["TAILMIX_DEBUG"]
        puts "\n[Tailmix Build: #{self.name}]"
        puts "  - Generated class with methods: #{@compiled_definition[:elements].map { |e| e[:name] }.join(', ')}"
        puts "  - State accessors: #{@compiled_definition[:states].keys.join(', ')}"
      end
    end

    def tailmix_definition
      raise "Tailmix definition not found definition for #{name}" unless @compiled_definition
      @compiled_definition
    end
  end
end
