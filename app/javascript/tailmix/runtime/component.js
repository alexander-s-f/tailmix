import { PersistenceManager } from './persistence';
import { Renderer } from '../interpreter/renderer';
import { DOMPatcher } from '../interpreter/dom_patcher';
import { ActionInterpreter } from '../interpreter/action_interpreter';
import { Scope } from '../interpreter/scope';
import { deepMerge } from './utils';

export class Component {
    constructor(element, definition) {
        this.element    = element;
        this.definition = definition;
        // Pre-index elements by name for O(1) lookup in render/bindEvents
        this.elementIndex = Object.fromEntries(
            (definition.elements || []).map(e => [e.name, e])
        );
        // Resolve variants from definition defaults
        this.variants    = this.initializeVariants();
        this.persistence = new PersistenceManager(this);
        this.state       = this.initializeState();
        this.interpreter = new ActionInterpreter(this);
        this.persistence.bindListeners();
        this.update = this.update.bind(this);
        this.eventControllers = new WeakMap();
        this.bindEvents();
        this.render();
        this.runBoot();

        if (window.TAILMIX_DEBUG) {
            console.log(`[Tailmix] Component "${this.definition.name}" hydrated.`);
        }
    }

    initializeVariants() {
        const variants = {};
        for (const [name, config] of Object.entries(this.definition.variants || {})) {
            variants[name] = config.default;
        }
        return variants;
    }

    initializeState() {
        const domState = this.loadInitialStateFromDOM();
        const persistedState = this.persistence.loadOverrides();
        // Server Defaults -> DOM State -> Persisted State
        return { ...domState, ...persistedState };
    }

    loadInitialStateFromDOM() {
        const json = this.element.dataset.tailmixState;
        try {
            return json ? JSON.parse(json) : {};
        } catch (e) {
            console.error(`[Tailmix] Failed to parse state`, e);
            return {};
        }
    }

    update(newStatePatch = {}, options = {}) {
        const previousState = { ...this.state };

        this.state = deepMerge(this.state, newStatePatch);

        if (!options.skipPersistence) {
            this.persistence.save(newStatePatch);
        }

        this.element.dataset.tailmixState = JSON.stringify(this.state);
        this.render();
        this.runWatchers(previousState);
    }

    runWatchers(previousState) {
        const watchers = this.definition.watchers;
        if (!watchers || watchers.length === 0) return;

        const scope     = new Scope(this.state,    {}, this.element, this.variants);
        const prevScope = new Scope(previousState, {}, this.element, this.variants);
        // Create evaluators once for all watchers
        const evaluator     = this.interpreter.evaluatorFor(scope);
        const prevEvaluator = this.interpreter.evaluatorFor(prevScope);

        for (const watcher of watchers) {
            // [:watch, subjectExpr, instructions]
            const [_, subjectExpr, instructions] = watcher;

            const newVal = evaluator.evaluate(subjectExpr);
            const oldVal = prevEvaluator.evaluate(subjectExpr);

            if (JSON.stringify(newVal) !== JSON.stringify(oldVal)) {
                this.interpreter.run(instructions, scope);
            }
        }
    }

    runBoot() {
        const bootInstructions = this.definition.boot;
        if (!bootInstructions || bootInstructions.length === 0) return;

        const scope = new Scope(this.state, {}, this.element, this.variants);
        this.interpreter.run(bootInstructions, scope);
    }

    bindEvents() {
        const elementNodes = this.element.querySelectorAll('[data-tailmix-element]');

        elementNodes.forEach(node => {
            if (this.eventControllers.has(node)) return;

            const elementDef = this.elementIndex[node.dataset.tailmixElement];

            if (!elementDef || !elementDef.rules) return;

            const eventRules = elementDef.rules.filter(r => r[0] === 'on');
            if (eventRules.length === 0) return;

            const controller = new AbortController();
            this.eventControllers.set(node, controller);

            eventRules.forEach(rule => {
                // [:on, "click", instructions]
                const [_, eventName, instructions] = rule;

                node.addEventListener(eventName, (event) => {
                    let param = {};
                    try {
                        param = JSON.parse(node.dataset.tailmixParam || '{}');
                    } catch (e) {}

                    const scope = new Scope(this.state, param, node, this.variants);
                    scope.locals = { event };

                    this.interpreter.run(instructions, scope);

                }, { signal: controller.signal });
            });
        });
    }

    render() {
        const elementNodes = this.element.querySelectorAll('[data-tailmix-element]');
        elementNodes.forEach(node => {
            const elementDef = this.elementIndex[node.dataset.tailmixElement];
            if (!elementDef) return;

            let param = {};
            try { param = JSON.parse(node.dataset.tailmixParam || '{}'); } catch (e) {}

            const result = Renderer.calculate(elementDef, this.state, param, node);
            DOMPatcher.patch(node, result);
        });
    }

    disconnect() {
        this.persistence.disconnect();
    }
}
