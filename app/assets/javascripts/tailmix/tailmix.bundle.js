var Tailmix = (() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // app/javascript/tailmix/runtime/index.js
  var index_exports = {};
  __export(index_exports, {
    default: () => index_default
  });

  // app/javascript/tailmix/interpreter/scope.js
  var Scope = class {
    constructor(state = {}, param = {}, element = null) {
      this.state = state;
      this.param = param;
      this.element = element;
      this.locals = {};
    }
    resolve(domain, pathString) {
      let root;
      switch (domain) {
        case "state":
          root = this.state;
          break;
        case "param":
          root = this.param;
          break;
        case "this":
          if (!this.element) return null;
          root = this.element;
          break;
        case "local":
          root = this.locals;
          break;
        default:
          return null;
      }
      if (!pathString) return root;
      const keys = pathString.split(".");
      let current = root;
      for (const key of keys) {
        if (current === null || current === void 0) {
          return null;
        }
        current = current[key];
      }
      return current;
    }
  };

  // app/javascript/tailmix/interpreter/evaluator.js
  var Evaluator = class {
    constructor(scope) {
      this.scope = scope;
    }
    evaluate(expr) {
      if (!Array.isArray(expr)) {
        return expr;
      }
      const [op, arg1, arg2] = expr;
      switch (op) {
        // Variables
        case "state":
        case "param":
        case "this":
          return this.scope.resolve(op, arg1);
        // Logic
        case "eq":
          return this.evaluate(arg1) == this.evaluate(arg2);
        case "neq":
          return this.evaluate(arg1) != this.evaluate(arg2);
        case "not":
          return !this.evaluate(arg1);
        case "and":
          return this.evaluate(arg1) && this.evaluate(arg2);
        case "or":
          return this.evaluate(arg1) || this.evaluate(arg2);
        case "gt":
          return this.evaluate(arg1) > this.evaluate(arg2);
        case "lt":
          return this.evaluate(arg1) < this.evaluate(arg2);
        case "gte":
          return this.evaluate(arg1) >= this.evaluate(arg2);
        case "lte":
          return this.evaluate(arg1) <= this.evaluate(arg2);
        // Math
        case "add":
          return this.evaluate(arg1) + this.evaluate(arg2);
        case "sub":
          return this.evaluate(arg1) - this.evaluate(arg2);
        case "mul":
          return this.evaluate(arg1) * this.evaluate(arg2);
        case "div":
          return this.evaluate(arg1) / this.evaluate(arg2);
        // Helpers
        case "concat":
          return String(this.evaluate(arg1)) + String(this.evaluate(arg2));
        default:
          console.warn(`[Tailmix] Unknown opcode: ${op}`);
          return null;
      }
    }
    normalize(val) {
      return val;
    }
  };

  // app/javascript/tailmix/interpreter/renderer.js
  var Renderer = class _Renderer {
    static calculate(elementDef, state, param, element) {
      return new _Renderer(elementDef, state, param, element).calculate();
    }
    constructor(elementDef, state, param, element) {
      this.definition = elementDef;
      this.scope = new Scope(state, param, element);
      this.evaluator = new Evaluator(this.scope);
      this.extraAttributes = param;
    }
    calculate() {
      const staticAttrs = this.definition.static || {};
      const acc = {
        classes: new Set(staticAttrs.class ? staticAttrs.class.split(/\s+/) : []),
        data: {},
        aria: {},
        other: { ...staticAttrs }
        // ID, type, etc.
      };
      delete acc.other.class;
      if (this.definition.rules) {
        for (const rule of this.definition.rules) {
          this.processRule(rule, acc);
        }
      }
      this.mergeExtraAttributes(acc);
      return acc;
    }
    processRule(rule, acc) {
      const op = rule[0];
      switch (op) {
        case "style": {
          const [_, condition, trueEff, falseEff] = rule;
          if (this.evaluator.evaluate(condition)) {
            this.applyEffect(trueEff, acc);
          } else {
            this.applyEffect(falseEff, acc);
          }
          break;
        }
        case "match": {
          const [_, subject, cases, defaultEff] = rule;
          const val = this.evaluator.evaluate(subject);
          const key = String(val);
          if (cases && Object.prototype.hasOwnProperty.call(cases, key)) {
            this.applyEffect(cases[key], acc);
          } else if (defaultEff) {
            this.applyEffect(defaultEff, acc);
          }
          break;
        }
      }
    }
    applyEffect(effect, acc) {
      if (!effect) return;
      if (effect.c) {
        const classes = effect.c.split(/\s+/);
        for (const cls of classes) {
          if (cls) acc.classes.add(cls);
        }
      }
      if (effect.d) {
        for (const [key, expr] of Object.entries(effect.d)) {
          acc.data[key] = this.evaluator.evaluate(expr);
        }
      }
      if (effect.a) {
        for (const [key, expr] of Object.entries(effect.a)) {
          acc.aria[key] = this.evaluator.evaluate(expr);
        }
      }
    }
    mergeExtraAttributes(acc) {
      for (const [key, value] of Object.entries(this.extraAttributes)) {
        if (key === "class") {
          const classes = String(value).split(/\s+/);
          for (const cls of classes) if (cls) acc.classes.add(cls);
        } else if (key.startsWith("data-")) {
          const dataKey = key.replace(/^data-/, "");
          acc.data[dataKey] = value;
        } else if (key.startsWith("aria-")) {
          const ariaKey = key.replace(/^aria-/, "");
          acc.aria[ariaKey] = value;
        } else if (key !== "root") {
          acc.other[key] = value;
        }
      }
    }
  };

  // app/javascript/tailmix/interpreter/dom_patcher.js
  var DOMPatcher = class {
    static patch(element, result) {
      const newClassString = Array.from(result.classes).join(" ");
      if (element.className !== newClassString) {
        element.className = newClassString;
      }
      for (const [key, value] of Object.entries(result.data)) {
        const attrName = `data-${key.replace(/[A-Z]/g, (m) => "-" + m.toLowerCase())}`;
        const strValue = String(value);
        if (element.getAttribute(attrName) !== strValue) {
          element.setAttribute(attrName, strValue);
        }
      }
      for (const [key, value] of Object.entries(result.aria)) {
        const attrName = `aria-${key.replace(/[A-Z]/g, (m) => "-" + m.toLowerCase())}`;
        const strValue = String(value);
        if (element.getAttribute(attrName) !== strValue) {
          element.setAttribute(attrName, strValue);
        }
      }
      for (const [key, value] of Object.entries(result.other)) {
        if (key === "value" && "value" in element) {
          if (element.value !== value) element.value = value;
        } else if (key === "checked" && "checked" in element) {
          element.checked = !!value;
        } else if (key === "disabled" && "disabled" in element) {
          element.disabled = !!value;
        } else {
          if (element.getAttribute(key) !== String(value)) {
            element.setAttribute(key, String(value));
          }
        }
      }
    }
  };

  // app/javascript/tailmix/runtime/utils.js
  function isObject(item) {
    return item && typeof item === "object" && !Array.isArray(item);
  }
  function deepMerge(target, source) {
    const output = { ...target };
    if (isObject(target) && isObject(source)) {
      Object.keys(source).forEach((key) => {
        if (isObject(source[key])) {
          if (!(key in target)) Object.assign(output, { [key]: source[key] });
          else output[key] = deepMerge(target[key], source[key]);
        } else {
          Object.assign(output, { [key]: source[key] });
        }
      });
    }
    return output;
  }
  function buildNestedPatch(pathString, value) {
    const keys = pathString.split(".");
    return keys.reduceRight((acc, key) => ({ [key]: acc }), value);
  }

  // app/javascript/tailmix/interpreter/action_interpreter.js
  var ActionInterpreter = class {
    constructor(component) {
      this.component = component;
    }
    run(instructions, scope) {
      if (!instructions || !Array.isArray(instructions)) return;
      const evaluator = new Evaluator(scope);
      for (const instruction of instructions) {
        this.execute(instruction, evaluator);
      }
    }
    execute(instruction, evaluator) {
      const [op, ...args] = instruction;
      switch (op) {
        case "set": {
          const [targetExpr, valueExpr] = args;
          const value = evaluator.evaluate(valueExpr);
          this.assign(targetExpr, value);
          break;
        }
        case "log": {
          const values = args.map((arg) => evaluator.evaluate(arg));
          console.log(`[Tailmix Log]`, ...values);
          break;
        }
        // todo: toggle, fetch, dispatch etc
        default:
          console.warn(`[Tailmix] Unknown action opcode: ${op}`);
      }
    }
    assign(targetExpr, value) {
      if (!Array.isArray(targetExpr)) {
        console.error("[Tailmix] Invalid assignment target", targetExpr);
        return;
      }
      const [domain, pathString] = targetExpr;
      if (domain === "state") {
        const patch = buildNestedPatch(pathString, value);
        this.component.update(patch);
      } else {
        console.warn(`[Tailmix] Cannot assign to read-only domain: ${domain}`);
      }
    }
  };

  // app/javascript/tailmix/runtime/component.js
  var Component = class {
    constructor(element, definition) {
      this.element = element;
      this.definition = definition;
      this.state = this.loadInitialState();
      this.interpreter = new ActionInterpreter(this);
      this.update = this.update.bind(this);
      this.eventControllers = /* @__PURE__ */ new WeakMap();
      this.bindEvents();
      this.render();
      console.log(`[Tailmix] Component "${this.definition.name}" hydrated.`);
    }
    loadInitialState() {
      const json = this.element.dataset.tailmixState;
      try {
        return json ? JSON.parse(json) : {};
      } catch (e) {
        console.error(`[Tailmix] Failed to parse state`, e);
        return {};
      }
    }
    update(newStatePatch = {}) {
      this.state = deepMerge(this.state, newStatePatch);
      this.element.dataset.tailmixState = JSON.stringify(this.state);
      this.render();
    }
    bindEvents() {
      const elementNodes = this.element.querySelectorAll("[data-tailmix-element]");
      elementNodes.forEach((node) => {
        if (this.eventControllers.has(node)) return;
        const elementName = node.dataset.tailmixElement;
        const elementDef = this.definition.elements.find((e) => e.name === elementName);
        if (!elementDef || !elementDef.rules) return;
        const eventRules = elementDef.rules.filter((r) => r[0] === "on");
        if (eventRules.length === 0) return;
        const controller = new AbortController();
        this.eventControllers.set(node, controller);
        eventRules.forEach((rule) => {
          const [_, eventName, instructions] = rule;
          node.addEventListener(eventName, (event) => {
            let param = {};
            try {
              param = JSON.parse(node.dataset.tailmixParam || "{}");
            } catch (e) {
            }
            const scope = new Scope(this.state, param, node);
            scope.locals = { event };
            this.interpreter.run(instructions, scope);
          }, { signal: controller.signal });
        });
      });
    }
    render() {
      const elementNodes = this.element.querySelectorAll("[data-tailmix-element]");
      elementNodes.forEach((node) => {
        const elementName = node.dataset.tailmixElement;
        const elementDef = this.definition.elements.find((e) => e.name === elementName);
        if (!elementDef) return;
        let param = {};
        try {
          param = JSON.parse(node.dataset.tailmixParam || "{}");
        } catch (e) {
        }
        const result = Renderer.calculate(elementDef, this.state, param, node);
        DOMPatcher.patch(node, result);
      });
    }
  };

  // app/javascript/tailmix/runtime/index.js
  var globalNamespace = typeof window !== "undefined" && window.Tailmix ? window.Tailmix : {};
  var Tailmix = {
    definitions: globalNamespace.definitions || {},
    instances: /* @__PURE__ */ new WeakMap(),
    booted: false,
    observer: null,
    start() {
      var _a;
      if (this.booted) return;
      this.booted = true;
      if ((_a = window.Tailmix) == null ? void 0 : _a.definitions) {
        Object.assign(this.definitions, window.Tailmix.definitions);
      }
      this.boot();
      this.observe();
      this.log("info", `Started with ${Object.keys(this.definitions).length} definitions`);
    },
    stop() {
      var _a;
      if (!this.booted) return;
      (_a = this.observer) == null ? void 0 : _a.disconnect();
      booted = false;
      this.log("info", "Stopped");
    },
    log(level, ...args) {
      var _a;
      if (window.TAILMIX_DEBUG) {
        (_a = console[level === "debug" ? "log" : level]) == null ? void 0 : _a.call(console, "[Tailmix]", ...args);
      }
    },
    observe() {
      this.observer = new MutationObserver((mutations) => {
        let shouldBoot = false;
        for (const m of mutations) {
          if ([...m.addedNodes].some((n) => {
            var _a;
            return n.nodeType === 1 && ((_a = n.matches) == null ? void 0 : _a.call(n, "[data-tailmix]"));
          })) {
            shouldBoot = true;
            break;
          }
        }
        if (shouldBoot) this.boot();
      });
      this.observer.observe(document.documentElement, { childList: true, subtree: true });
    },
    boot(root = document) {
      const componentRoots = root.querySelectorAll("[data-tailmix-component]");
      componentRoots.forEach((element) => {
        if (this.instances.has(element)) return;
        const name = element.dataset.tailmixComponent;
        const definition = this.definitions[name];
        if (definition) {
          const instance = new Component(element, definition);
          this.instances.set(element, instance);
        } else {
          console.warn(`[Tailmix] Definition for "${name}" not found.`);
        }
      });
    }
  };
  if (typeof window !== "undefined") {
    window.Tailmix = Object.assign(window.Tailmix || {}, Tailmix);
    document.addEventListener("DOMContentLoaded", () => Tailmix.start());
    document.addEventListener("turbo:load", () => Tailmix.start());
  }
  var index_default = Tailmix;
  return __toCommonJS(index_exports);
})();
//# sourceMappingURL=tailmix.bundle.js.map
