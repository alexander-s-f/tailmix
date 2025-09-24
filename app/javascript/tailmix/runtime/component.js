// app/javascript/tailmix/runtime/component.js

import { Updater } from './updater';
import { Interpreter } from './interpreter';
import { TriggerManager } from './trigger_manager';
import { ReactionEngine } from './reaction_engine';

/**
 * Represents a component instance that manages the state and behavior of a specific UI element.
 */
export class Component {
    constructor(element, definition, pluginManager) {
        this.element = element;
        this.definition = definition;
        this._state = this.loadInitialState();
        this.elements = this.findElements();

        // NEW: Instantiate the core parts of the new engine
        this.updater = new Updater(this);
        this.interpreter = new Interpreter(this);
        this.triggerManager = new TriggerManager(this, this.interpreter);
        this.reactionEngine = new ReactionEngine(this, this.interpreter);

        // --- API ---
        this.api = {
            get state() {
                return {...this._state};
            },
            setState: (newState) => this.update(newState),
            element: (name) => this.elements[name],
            // Allows running an action programmatically
            runAction: (name, event = null) => {
                const actionDef = this.definition.actions[name];
                if (actionDef?.expressions) {
                    this.interpreter.run(actionDef.expressions, event);
                } else {
                    console.warn(`Tailmix: Action "${name}" not found.`);
                }
            },
            dispatch: (name, detail) => this.dispatch(name, detail),
            on: (name, callback) => this.element.addEventListener(`tailmix:${name}`, callback),
        };

        // Initialize everything
        this.triggerManager.bindActions();
        this.initializeModels(); // Keep this for `model` bindings
        this.updater.run(this._state, {});
        pluginManager.connect(this);

        this.initializeStateSyncing();
        console.log(`Tailmix component "${this.definition.name || 'Unnamed'}" initialized with new engine.`, this);
    }

    /**
     * Gets the current state of the component.
     * @return {Object} The current state of the component.
     */
    get state() {
        return this._state;
    }

    /**
     * Updates the component's state and triggers the update/reaction cycle.
     * @param {Object} newState A hash of state keys and their new values.
     */
    update(newState) {
        const oldState = { ...this._state };
        const changedKeys = new Set();

        for (const key in newState) {
            if (JSON.stringify(this._state[key]) !== JSON.stringify(newState[key])) {
                changedKeys.add(key);
            }
        }

        if (changedKeys.size === 0) return;

        Object.assign(this._state, newState);

        for (const key of changedKeys) {
            const config = this.definition.states[key];
            if (config.persist) {
                const storageKey = `${this.definition.name}:${key}`;
                localStorage.setItem(storageKey, JSON.stringify(this._state[key]));
            }
            if (config.sync === 'hash') {
                if (this._state[key]) {
                    window.location.hash = this._state[key];
                } else {
                    history.pushState("", document.title, window.location.pathname + window.location.search);
                }
            }
        }

        this.element.dataset.tailmixState = JSON.stringify(this._state);

        this.updater.run(this._state, oldState);
        this.reactionEngine.run(changedKeys);
    }

    /**
     * Dispatches a custom event from the component's root element.
     * @param {string} name The name of the event (without the 'tailmix:' prefix).
     * @param {any} detail The data to be attached to the event.
     */
    dispatch(name, detail) {
        const event = new CustomEvent(`tailmix:${name}`, {bubbles: true, detail});
        this.element.dispatchEvent(event);
    }

    /**
     * Loads and parses the initial state from the data attribute.
     * @return {Object} The parsed initial state.
     */
    loadInitialState() {
        const initialState = JSON.parse(this.element.dataset.tailmixState || '{}');
        const stateSchema = this.definition.states || {};

        for (const key in stateSchema) {
            const config = stateSchema[key];
            let value = initialState[key];

            if (config.persist) {
                const storageKey = `${this.definition.name}:${key}`;
                const persistedValue = localStorage.getItem(storageKey);

                if (persistedValue !== null) {
                    value = JSON.parse(persistedValue);
                }
            }

            if (config.sync === 'hash') {
                const hashValue = window.location.hash.substring(1);
                if (hashValue) {
                    value = hashValue;
                }
            }

            if (value !== undefined) {
                initialState[key] = value;
            } else if (config.default !== undefined) {
                initialState[key] = config.default;
            }
        }
        return initialState;
    }

    /**
     * Finds all named elements within the component's scope.
     * @return {Object<string, HTMLElement>} A map of element names to DOM nodes.
     */
    findElements() {
        const elements = {};
        const elementNodes = this.element.querySelectorAll('[data-tailmix-element]');
        elementNodes.forEach(node => {
            const name = node.dataset.tailmixElement;
            elements[name] = node;
        });
        if (this.element.dataset.tailmixElement) {
            elements[this.element.dataset.tailmixElement] = this.element;
        }
        return elements;
    }

    /**
     * Initializes two-way data bindings defined with `model`.
     */
    initializeModels() {
        for (const elName in this.definition.elements) {
            const element = this.elements[elName];
            const modelBindings = this.definition.elements[elName].model_bindings;
            if (!element || !modelBindings) continue;

            for (const attrName in modelBindings) {
                const binding = modelBindings[attrName];
                element.addEventListener(binding.event, (event) => {
                    this.update({[binding.state]: event.target[attrName]});
                });
            }
        }
    }

    /**
     * Builds and returns an object representing the scoped attributes for a given element.
     *
     * @param {string} elementName - The name of the element for which scoped attributes are being built.
     * @param {Object} withData - Additional state data to temporarily augment the current state when calculating attributes.
     * @return {Object} An object containing the final scoped attributes, including class and custom data attributes.
     */
    buildScopedAttributes(elementName, withData) {
        const elementDef = this.definition.elements[elementName];
        if (!elementDef) return {};

        // Creating a temporary, "hybrid" state
        const scopedState = { ...this._state, ...withData };

        const finalAttributes = {};

        // Apply base classes
        const baseClasses = elementDef.attributes?.classes || [];
        const classList = new Set(baseClasses);

        // Apply dimensions
        if (elementDef.dimensions) {
            for (const dimName in elementDef.dimensions) {
                const dimDef = elementDef.dimensions[dimName];
                const stateValue = scopedState[dimName] !== undefined ? scopedState[dimName] : dimDef.default;
                const variantDef = dimDef.variants?.[stateValue];
                if (variantDef?.classes) {
                    variantDef.classes.forEach(cls => classList.add(cls));
                }
            }
        }

        // Gathering final attributes
        finalAttributes.class = [...classList].join(' ');
        finalAttributes['data-tailmix-element'] = elementName;

        return finalAttributes;
    }

    /**
     * Initializes listeners for external state changes (e.g., URL hash).
     */
    initializeStateSyncing() {
        window.addEventListener('hashchange', () => {
            for (const key in this.definition.states) {
                const config = this.definition.states[key];
                if (config.sync === 'hash') {
                    const hashValue = window.location.hash.substring(1);
                    // Updating the component's state if it differs from the current hash
                    if (this.state[key] !== hashValue) {
                        this.update({ [key]: hashValue || config.default });
                    }
                }
            }
        });
    }
}
