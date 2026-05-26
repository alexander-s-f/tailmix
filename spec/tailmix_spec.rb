# frozen_string_literal: true

require "spec_helper"
require "json"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
module Helpers
  # Build a minimal compiled element definition the same way JSONGenerator does,
  # but without going through the DSL — useful for low-level Renderer tests.
  def compiled_element(name:, static: {}, rules: [])
    { name: name.to_s, static: static, rules: rules }
  end

  def render_element(element_def, state: {}, param: {})
    Tailmix::Interpreter::Renderer.render(element_def, state: state, param: param)
  end
end

RSpec.configure do |c|
  c.include Helpers
end

# ---------------------------------------------------------------------------
# DSL + Compiler
# ---------------------------------------------------------------------------
RSpec.describe "DSL & Compiler" do
  def compile(&block)
    ast = Tailmix::DSL::ComponentParser.parse("TestComponent", &block)
    Tailmix::Compiler::JSONGenerator.new.compile(ast)
  end

  # -------------------------------------------------------------------------
  describe "state" do
    it "stores default values" do
      definition = compile do
        state :open,  default: false
        state :count, default: 0
        state :label, default: "hello"
      end

      expect(definition[:states]).to eq("open" => false, "count" => 0, "label" => "hello")
    end

    it "infers types from defaults" do
      definition = compile do
        state :flag,  default: true
        state :count, default: 42
        state :ratio, default: 3.14
        state :data,  default: {}
        state :name,  default: "alex"
      end

      expect(definition[:types]).to eq(
        "flag"  => :boolean,
        "count" => :integer,
        "ratio" => :float,
        "data"  => :json,
        "name"  => :string
      )
    end

    it "defaults type to :string when value is nil" do
      definition = compile { state :token }
      expect(definition[:types]["token"]).to eq(:string)
    end

    it "supports explicit type override" do
      definition = compile { state :score, default: nil, type: :integer }
      expect(definition[:types]["score"]).to eq(:integer)
    end

    it "records persistence config" do
      definition = compile { state :theme, default: "light", persist: :local }
      expect(definition[:persistence]["theme"]).to eq({ type: :local, key: "theme" })
    end
  end

  # -------------------------------------------------------------------------
  describe "element" do
    it "compiles an element with base classes" do
      definition = compile do
        element :btn, "px-4 py-2"
      end

      elem = definition[:elements].first
      expect(elem[:name]).to eq("btn")
      rule = elem[:rules].first
      expect(rule[0]).to eq(:style)
      expect(rule[1]).to eq(true)
      expect(rule[2]["c"]).to include("px-4")
    end

    it "compiles an on-event rule" do
      definition = compile do
        element :btn do
          on :click do
            set state.open, true
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[0]).to eq(:on)
      expect(rule[1]).to eq("click")
      expect(rule[2].first).to eq([:set, [:state, "open"], true])
    end

    it "compiles toggle instruction" do
      definition = compile do
        element :btn do
          on :click do
            toggle state.open
          end
        end
      end

      instruction = definition[:elements].first[:rules].first[2].first
      expect(instruction).to eq([:toggle, [:state, "open"]])
    end

    it "compiles a style rule without otherwise" do
      definition = compile do
        element :panel do
          style condition: state.open do
            classes "visible opacity-100"
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[0]).to eq(:style)
      expect(rule[1]).to eq([:state, "open"])
      expect(rule[2]["c"]).to eq("visible opacity-100")
      expect(rule[3]).to be_nil
    end

    it "compiles style with otherwise branch" do
      definition = compile do
        element :panel do
          style condition: state.open do
            classes "visible"
            otherwise "hidden"
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[2]["c"]).to eq("visible")
      expect(rule[3]["c"]).to eq("hidden")
    end

    it "compiles style with full otherwise block" do
      definition = compile do
        element :panel do
          style condition: state.open do
            classes "visible"
            aria expanded: true
            otherwise do
              classes "hidden"
              aria expanded: false
            end
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[2]["c"]).to eq("visible")
      expect(rule[2]["a"]["expanded"]).to eq(true)
      expect(rule[3]["c"]).to eq("hidden")
      expect(rule[3]["a"]["expanded"]).to eq(false)
    end

    it "compiles a match rule" do
      definition = compile do
        element :tab do
          match state.active do
            on "profile",  "border-blue-500"
            on "settings", "border-green-500"
            default "border-transparent"
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[0]).to eq(:match)
      expect(rule[1]).to eq([:state, "active"])
      expect(rule[2]["profile"]["c"]).to eq("border-blue-500")
      expect(rule[2]["settings"]["c"]).to eq("border-green-500")
      expect(rule[3]["c"]).to eq("border-transparent")
    end

    it "compiles boolean match keys as strings" do
      definition = compile do
        element :icon do
          match state.open do
            on true,  "rotate-180"
            on false, "rotate-0"
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[2].keys).to contain_exactly("true", "false")
    end

    it "compiles negation (!state.open)" do
      definition = compile do
        element :btn do
          style condition: !state.open do
            classes "hidden"
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[1]).to eq([:not, [:state, "open"]])
    end

    it "compiles binary operator (state.count > 0)" do
      definition = compile do
        element :badge do
          style condition: state.count > 0 do
            classes "visible"
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[1]).to eq([:gt, [:state, "count"], 0])
    end

    it "compiles == condition across state and param" do
      definition = compile do
        element :tab do
          style condition: state.active == param.id do
            classes "selected"
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[1]).to eq([:eq, [:state, "active"], [:param, "id"]])
    end

    it "compiles aria and data attributes" do
      definition = compile do
        element :tab do
          style condition: true do
            aria selected: true
            data highlighted: state.active
          end
        end
      end

      effect = definition[:elements].first[:rules].first[2]
      expect(effect["a"]["selected"]).to eq(true)
      expect(effect["d"]["highlighted"]).to eq([:state, "active"])
    end
  end
end

# ---------------------------------------------------------------------------
# Evaluator
# ---------------------------------------------------------------------------
RSpec.describe Tailmix::Interpreter::Evaluator do
  def scope(state: {}, param: {})
    Tailmix::Interpreter::Scope.new(state: state, param: param)
  end

  def evaluator(state: {}, param: {})
    described_class.new(scope(state: state, param: param))
  end

  it "returns literals as-is" do
    ev = evaluator
    expect(ev.evaluate(42)).to eq(42)
    expect(ev.evaluate("hello")).to eq("hello")
    expect(ev.evaluate(true)).to eq(true)
    expect(ev.evaluate(nil)).to be_nil
  end

  it "resolves state variables" do
    ev = evaluator(state: { "open" => true })
    expect(ev.evaluate([:state, "open"])).to eq(true)
  end

  it "resolves param variables" do
    ev = evaluator(param: { "id" => "profile" })
    expect(ev.evaluate([:param, "id"])).to eq("profile")
  end

  it "resolves nested state paths" do
    ev = evaluator(state: { "user" => { "name" => "Alex" } })
    expect(ev.evaluate([:state, "user", "name"])).to eq("Alex")
  end

  it "evaluates :eq" do
    ev = evaluator(state: { "active" => "profile" }, param: { "id" => "profile" })
    expect(ev.evaluate([:eq, [:state, "active"], [:param, "id"]])).to eq(true)
  end

  it "evaluates :neq" do
    ev = evaluator(state: { "active" => "profile" }, param: { "id" => "settings" })
    expect(ev.evaluate([:neq, [:state, "active"], [:param, "id"]])).to eq(true)
  end

  it "evaluates :not" do
    ev = evaluator(state: { "open" => false })
    expect(ev.evaluate([:not, [:state, "open"]])).to eq(true)
  end

  it "evaluates :and / :or" do
    ev = evaluator(state: { "a" => true, "b" => false })
    expect(ev.evaluate([:and, [:state, "a"], [:state, "b"]])).to eq(false)
    expect(ev.evaluate([:or,  [:state, "a"], [:state, "b"]])).to eq(true)
  end

  it "evaluates arithmetic" do
    ev = evaluator(state: { "count" => 10 })
    expect(ev.evaluate([:add, [:state, "count"], 5])).to eq(15)
    expect(ev.evaluate([:sub, [:state, "count"], 3])).to eq(7)
    expect(ev.evaluate([:mul, [:state, "count"], 2])).to eq(20)
    expect(ev.evaluate([:div, [:state, "count"], 2])).to eq(5)
  end

  it "evaluates :gt / :lt / :gte / :lte" do
    ev = evaluator(state: { "count" => 5 })
    expect(ev.evaluate([:gt,  [:state, "count"], 3])).to eq(true)
    expect(ev.evaluate([:lt,  [:state, "count"], 3])).to eq(false)
    expect(ev.evaluate([:gte, [:state, "count"], 5])).to eq(true)
    expect(ev.evaluate([:lte, [:state, "count"], 5])).to eq(true)
  end

  it "evaluates :concat" do
    ev = evaluator(state: { "first" => "Hello", "last" => "World" })
    result = ev.evaluate([:concat, [:state, "first"], [:state, "last"]])
    expect(result).to eq("HelloWorld")
  end

  it "raises on unknown opcode" do
    expect { evaluator.evaluate([:unknown_op, 1]) }.to raise_error(/Unknown opcode/)
  end
end

# ---------------------------------------------------------------------------
# Renderer
# ---------------------------------------------------------------------------
RSpec.describe Tailmix::Interpreter::Renderer do
  describe "base classes" do
    it "includes static base classes from style true rule" do
      elem = compiled_element(name: :btn, rules: [
        [:style, true, { "c" => "px-4 py-2" }, nil]
      ])
      expect(render_element(elem)["class"]).to eq("px-4 py-2")
    end
  end

  describe "style rule" do
    it "applies truthy branch" do
      elem = compiled_element(name: :panel, rules: [
        [:style, [:state, "open"], { "c" => "visible" }, { "c" => "hidden" }]
      ])
      expect(render_element(elem, state: { "open" => true })["class"]).to  eq("visible")
      expect(render_element(elem, state: { "open" => false })["class"]).to eq("hidden")
    end

    it "handles nil else branch gracefully" do
      elem = compiled_element(name: :badge, rules: [
        [:style, [:state, "show"], { "c" => "block" }, nil]
      ])
      expect(render_element(elem, state: { "show" => false })["class"]).to be_nil
    end

    it "evaluates :eq condition" do
      elem = compiled_element(name: :tab, rules: [
        [:style, [:eq, [:state, "active"], [:param, "id"]], { "c" => "selected" }, nil]
      ])
      result = render_element(elem,
        state: { "active" => "profile" },
        param: { "id" => "profile" }
      )
      expect(result["class"]).to eq("selected")
    end
  end

  describe "match rule" do
    it "selects the matching case" do
      elem = compiled_element(name: :tab, rules: [
        [:match, [:state, "active"],
          { "profile" => { "c" => "active-profile" }, "settings" => { "c" => "active-settings" } },
          nil]
      ])
      expect(render_element(elem, state: { "active" => "profile" })["class"]).to  eq("active-profile")
      expect(render_element(elem, state: { "active" => "settings" })["class"]).to eq("active-settings")
    end

    it "falls back to default" do
      elem = compiled_element(name: :btn, rules: [
        [:match, [:state, "size"],
          { "sm" => { "c" => "text-sm" } },
          { "c" => "text-base" }]
      ])
      expect(render_element(elem, state: { "size" => "xl" })["class"]).to eq("text-base")
    end

    it "handles boolean keys (true/false as strings)" do
      elem = compiled_element(name: :icon, rules: [
        [:match, [:state, "open"],
          { "true" => { "c" => "rotate-180" }, "false" => { "c" => "rotate-0" } },
          nil]
      ])
      expect(render_element(elem, state: { "open" => true })["class"]).to  eq("rotate-180")
      expect(render_element(elem, state: { "open" => false })["class"]).to eq("rotate-0")
    end
  end

  describe "aria attributes" do
    it "renders aria-* attributes" do
      elem = compiled_element(name: :tab, rules: [
        [:style, [:state, "open"], { "a" => { "expanded" => true } }, nil]
      ])
      expect(render_element(elem, state: { "open" => true })["aria-expanded"]).to eq(true)
    end
  end

  describe "data attributes" do
    it "renders data-* attributes with evaluated expressions" do
      elem = compiled_element(name: :btn, rules: [
        [:style, true, { "d" => { "count" => [:state, "count"] } }, nil]
      ])
      expect(render_element(elem, state: { "count" => 7 })["data-count"]).to eq(7)
    end
  end

  describe "prop attributes" do
    it "renders props as plain HTML attributes" do
      elem = compiled_element(name: :input, rules: [
        [:style, true, { "p" => { "disabled" => [:state, "loading"] } }, nil]
      ])
      expect(render_element(elem, state: { "loading" => true })["disabled"]).to eq(true)
    end
  end

  describe "param merging" do
    it "merges extra classes from param" do
      elem = compiled_element(name: :btn, rules: [
        [:style, true, { "c" => "px-4" }, nil]
      ])
      result = render_element(elem, param: { "class" => "mt-2" })
      expect(result["class"]).to include("px-4").and include("mt-2")
    end

    it "merges id from param as a plain attribute" do
      elem = compiled_element(name: :panel, rules: [])
      expect(render_element(elem, param: { "id" => "profile" })["id"]).to eq("profile")
    end

    it "strips root from final attributes" do
      elem = compiled_element(name: :btn, rules: [])
      result = render_element(elem, param: { "root" => true })
      expect(result.key?("root")).to eq(false)
    end

    it "always emits data-tailmix-element" do
      elem = compiled_element(name: :my_btn, rules: [])
      expect(render_element(elem)["data-tailmix-element"]).to eq("my_btn")
    end
  end

  describe "class deduplication" do
    it "deduplicates repeated class names" do
      elem = compiled_element(name: :btn, rules: [
        [:style, true, { "c" => "px-4 px-4 py-2" }, nil]
      ])
      classes = render_element(elem)["class"].split
      expect(classes.uniq).to eq(classes)
    end
  end
end

# ---------------------------------------------------------------------------
# Full integration: DSL → compile → render
# ---------------------------------------------------------------------------
RSpec.describe "Full integration" do
  def build_component(&block)
    Class.new { include Tailmix; tailmix(&block) }
  end

  it "renders active/inactive tabs correctly" do
    klass = build_component do
      state :active, default: "profile"

      element :tab, "cursor-pointer" do
        on :click do
          set state.active, param.id
        end

        style condition: state.active == param.id do
          classes "text-blue-600"
          aria selected: true
          otherwise do
            classes "text-gray-500"
            aria selected: false
          end
        end
      end
    end

    ui = klass.new.tailmix(active: "profile")

    active_tab = ui.tab(id: "profile")
    expect(active_tab["class"]).to include("text-blue-600")
    expect(active_tab["aria-selected"]).to eq(true)

    inactive_tab = ui.tab(id: "settings")
    expect(inactive_tab["class"]).to include("text-gray-500")
    expect(inactive_tab["aria-selected"]).to eq(false)
  end

  it "renders open/closed states correctly" do
    klass = build_component do
      state :open, default: false

      element :menu do
        style condition: state.open do
          classes "block"
          otherwise "hidden"
        end
      end
    end

    expect(klass.new.tailmix(open: false).menu["class"]).to eq("hidden")
    expect(klass.new.tailmix(open: true).menu["class"]).to eq("block")
  end

  it "compiles toggle into the definition" do
    klass = build_component do
      state :open, default: false
      element :btn do
        on :click do
          toggle state.open
        end
      end
    end

    rule = klass.tailmix_facade_class.definition[:elements].first[:rules].first
    expect(rule[2].first).to eq([:toggle, [:state, "open"]])
  end

  it "renders match-based size variants" do
    klass = build_component do
      state :size, default: "md"

      element :btn, "rounded" do
        match state.size do
          on "sm", "text-sm px-2"
          on "md", "text-base px-4"
          on "lg", "text-lg px-6"
        end
      end
    end

    expect(klass.new.tailmix(size: "sm").btn["class"]).to include("text-sm")
    expect(klass.new.tailmix(size: "lg").btn["class"]).to include("text-lg")
  end

  it "accumulates classes from multiple rules" do
    klass = build_component do
      state :active, default: true

      element :btn, "rounded px-4" do
        style condition: state.active do
          classes "bg-blue-500"
          otherwise "bg-gray-200"
        end
      end
    end

    result = klass.new.tailmix(active: true).btn
    expect(result["class"]).to include("rounded")
    expect(result["class"]).to include("px-4")
    expect(result["class"]).to include("bg-blue-500")
  end
end

# ---------------------------------------------------------------------------
# Variants
# ---------------------------------------------------------------------------
RSpec.describe "Variants" do
  def build_component(&block)
    Class.new { include Tailmix; tailmix(&block) }
  end

  def compile(&block)
    ast = Tailmix::DSL::ComponentParser.parse("V", &block)
    Tailmix::Compiler::JSONGenerator.new.compile(ast)
  end

  describe "DSL & Compiler" do
    it "compiles variant definitions with defaults" do
      definition = compile do
        variant :size,   default: :md
        variant :intent, default: :primary
      end

      expect(definition[:variants]["size"][:default]).to eq(:md)
      expect(definition[:variants]["intent"][:default]).to eq(:primary)
    end

    it "compiles match variant.size" do
      definition = compile do
        variant :size, default: :md

        element :btn do
          match variant.size do
            on :sm, "text-sm"
            on :md, "text-base"
            on :lg, "text-lg"
          end
        end
      end

      rule = definition[:elements].first[:rules].first
      expect(rule[0]).to eq(:match)
      expect(rule[1]).to eq([:variant, "size"])
      expect(rule[2]["sm"]["c"]).to eq("text-sm")
    end
  end

  describe "Runtime (SSR)" do
    it "resolves variant in element rendering" do
      klass = build_component do
        variant :size,   default: :md
        variant :intent, default: :primary

        element :btn, "rounded font-medium" do
          match variant.size do
            on :sm, "text-sm px-2 py-1"
            on :md, "text-base px-4 py-2"
            on :lg, "text-lg px-6 py-3"
          end

          match variant.intent do
            on :primary,   "bg-blue-500 text-white"
            on :secondary, "bg-gray-100 text-gray-800"
            on :danger,    "bg-red-500 text-white"
          end
        end
      end

      sm_primary = klass.new.tailmix(size: :sm, intent: :primary).btn
      expect(sm_primary["class"]).to include("text-sm")
      expect(sm_primary["class"]).to include("bg-blue-500")

      lg_danger = klass.new.tailmix(size: :lg, intent: :danger).btn
      expect(lg_danger["class"]).to include("text-lg")
      expect(lg_danger["class"]).to include("bg-red-500")
    end

    it "uses variant defaults when not supplied" do
      klass = build_component do
        variant :size, default: :md

        element :btn do
          match variant.size do
            on :sm, "text-sm"
            on :md, "text-base"
          end
        end
      end

      result = klass.new.tailmix.btn
      expect(result["class"]).to eq("text-base")
    end

    it "separates variant args from state args" do
      klass = build_component do
        state   :open,  default: false
        variant :size,  default: :md
        variant :intent, default: :primary

        element :btn do
          style condition: state.open do
            classes "ring-2"
          end
          match variant.size do
            on :lg, "text-lg"
            on :md, "text-base"
          end
        end
      end

      ui = klass.new.tailmix(open: true, size: :lg)
      expect(ui.btn["class"]).to include("ring-2")   # from state
      expect(ui.btn["class"]).to include("text-lg")  # from variant
    end
  end
end

# ---------------------------------------------------------------------------
# boot {} DSL
# ---------------------------------------------------------------------------
RSpec.describe "boot DSL" do
  def compile(&block)
    ast = Tailmix::DSL::ComponentParser.parse("B", &block)
    Tailmix::Compiler::JSONGenerator.new.compile(ast)
  end

  it "compiles boot instructions" do
    definition = compile do
      state :ready, default: false

      boot do
        set state.ready, true
      end
    end

    expect(definition[:boot]).to eq([[:set, [:state, "ready"], true]])
  end

  it "compiles empty boot as empty array" do
    definition = compile { state :x, default: 0 }
    expect(definition[:boot]).to eq([])
  end
end

# ---------------------------------------------------------------------------
# dispatch instruction
# ---------------------------------------------------------------------------
RSpec.describe "dispatch" do
  def compile(&block)
    ast = Tailmix::DSL::ComponentParser.parse("D", &block)
    Tailmix::Compiler::JSONGenerator.new.compile(ast)
  end

  it "compiles dispatch with detail expressions" do
    definition = compile do
      element :btn do
        on :click do
          dispatch "tailmix:modal-open", detail: { id: param.id }
        end
      end
    end

    rule = definition[:elements].first[:rules].first
    expect(rule[0]).to eq(:on)
    instruction = rule[2].first
    expect(instruction[0]).to eq(:dispatch)
    expect(instruction[1]).to eq("tailmix:modal-open")
    expect(instruction[2]["id"]).to eq([:param, "id"])
  end

  it "compiles dispatch with literal detail" do
    definition = compile do
      element :btn do
        on :click do
          dispatch "app:notify", detail: { level: "info" }
        end
      end
    end

    instruction = definition[:elements].first[:rules].first[2].first
    expect(instruction[2]["level"]).to eq("info")
  end
end

# ---------------------------------------------------------------------------
# watch DSL
# ---------------------------------------------------------------------------
RSpec.describe "watch" do
  def compile(&block)
    ast = Tailmix::DSL::ComponentParser.parse("W", &block)
    Tailmix::Compiler::JSONGenerator.new.compile(ast)
  end

  it "compiles a watch rule at the component level" do
    definition = compile do
      state :query,   default: ""
      state :loading, default: false

      watch state.query do
        toggle state.loading
        log state.query
      end
    end

    expect(definition[:watchers]).not_to be_empty
    watcher = definition[:watchers].first
    expect(watcher[0]).to eq(:watch)
    expect(watcher[1]).to eq([:state, "query"])
    expect(watcher[2].map(&:first)).to contain_exactly(:toggle, :log)
  end

  it "compiles multiple watchers" do
    definition = compile do
      state :query,  default: ""
      state :region, default: "all"

      watch state.query  do; log state.query;  end
      watch state.region do; log state.region; end
    end

    expect(definition[:watchers].length).to eq(2)
    expect(definition[:watchers][0][1]).to eq([:state, "query"])
    expect(definition[:watchers][1][1]).to eq([:state, "region"])
  end
end
