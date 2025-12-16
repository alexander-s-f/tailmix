import { PersistenceManager } from './persistence';
import { Renderer } from '../interpreter/renderer';
import { DOMPatcher } from '../interpreter/dom_patcher';
import { ActionInterpreter } from '../interpreter/action_interpreter';
import { Scope } from '../interpreter/scope';
import { deepMerge } from './utils';

export class Component {
    constructor(element, definition) {
        this.element = element;
        this.definition = definition;
        this.persistence = new PersistenceManager(this);
        this.state = this.initializeState();
        this.interpreter = new ActionInterpreter(this);
        this.persistence.bindListeners();
        this.update = this.update.bind(this);
        this.eventControllers = new WeakMap();
        this.bindEvents();
        this.render();

        console.log(`[Tailmix] Component "${this.definition.name}" hydrated.`);
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
        this.state = deepMerge(this.state, newStatePatch);

        if (!options.skipPersistence) {
            this.persistence.save(newStatePatch);
        }

        this.element.dataset.tailmixState = JSON.stringify(this.state);
        this.render();
    }

    bindEvents() {
        const elementNodes = this.element.querySelectorAll('[data-tailmix-element]');

        elementNodes.forEach(node => {
            if (this.eventControllers.has(node)) return;

            const elementName = node.dataset.tailmixElement;
            const elementDef = this.definition.elements.find(e => e.name === elementName);

            if (!elementDef || !elementDef.rules) return;

            // 'on'
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

                    const scope = new Scope(this.state, param, node);
                    scope.locals = { event };

                    this.interpreter.run(instructions, scope);

                }, { signal: controller.signal });
            });
        });
    }

    render() {
        const elementNodes = this.element.querySelectorAll('[data-tailmix-element]');
        elementNodes.forEach(node => {
            const elementName = node.dataset.tailmixElement;
            const elementDef = this.definition.elements.find(e => e.name === elementName);
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