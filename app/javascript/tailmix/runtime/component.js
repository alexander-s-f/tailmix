import { Executor } from './executor';
import { DOMUpdater } from './dom_updater';
import { ActionInterpreter } from './action_interpreter';
import { TriggerManager } from './trigger_manager';
import { Scope } from './scope';
import { debounce } from './utils';

export class Component {
    constructor(element, definition, dictionary) {
        this.element = element;
        this.dictionary = dictionary;
        this.definition = this.decompress(definition);
        this._state = this.loadInitialState();

        this.scope = new Scope(this._state);

        this.executor = new Executor();
        this.actionInterpreter = new ActionInterpreter(this);
        this.triggerManager = new TriggerManager(this);

        this.performUpdate = this.performUpdate.bind(this);
        this.debouncedUpdate = debounce(this.performUpdate, 16);

        this.triggerManager.bind();
        this.performUpdate();

        console.log(`Tailmix component "${this.definition.name || 'Unnamed'}" initialized.`);
    }

    get state() {
        return this._state;
    }

    update(newState) {
        Object.assign(this._state, newState);
        // Keep the scope in sync with the state.
        // A more robust solution might involve a dedicated state management object
        // that the scope can reference, but this is a simple and effective approach for now.
        this.scope = new Scope(this._state);
        this.scheduleUpdate();
    }

    scheduleUpdate() {
        this.debouncedUpdate();
    }

    performUpdate() {
        if (!this.element.isConnected) return; // Optimization: don't render disconnected elements

        this.element.dataset.tailmixState = JSON.stringify(this._state);

        const allElements = [this.element, ...this.element.querySelectorAll('[data-tailmix-element]')];

        allElements.forEach(elementNode => {
            const elementName = elementNode.dataset.tailmixElement;
            if (!elementName) return;

            const elementDef = this.definition.elements.find(e => e.name === elementName);
            if (!elementDef) return;

            let param = {};
            const paramAttr = elementNode.dataset.tailmixParam;
            if (paramAttr) {
                try {
                    param = JSON.parse(paramAttr);
                } catch (e) {
                    console.error("Tailmix: Invalid JSON in data-tailmix-param", e, elementNode);
                }
            }
            const attributeSet = this.executor.execute(elementDef.rules, this.scope, param);

            // The deterministic updater is still crucial for correctness.
            DOMUpdater.apply(elementNode, attributeSet, elementDef.base_classes, elementDef.variant_classes || []);
        });
    }

    loadInitialState() {
        const initialState = JSON.parse(this.element.dataset.tailmixState || '{}');
        const stateDefs = this.definition.states || [];

        for (const stateDef of stateDefs) {
            const key = stateDef.name;
            if (initialState[key] === undefined && stateDef.options.default !== undefined) {
                initialState[key] = stateDef.options.default;
            }
        }
        return initialState;
    }

    decompress(node) {
        // If it's not an object or array, return it as is (e.g., strings, numbers)
        if (typeof node !== 'object' || node === null) {
            return node;
        }

        // If it's an array, decompress each item
        if (Array.isArray(node)) {
            return node.map(item => this.decompress(item));
        }

        // If it's an object, iterate over its keys
        const newNode = {};
        for (const key in node) {
            if (Object.prototype.hasOwnProperty.call(node, key)) {
                const value = node[key];

                // These are the keys we know contain class IDs that need to be looked up
                if ((key === 'base_classes' || key === 'variant_classes') && Array.isArray(value)) {
                    newNode[key] = value.map(id => this.dictionary[id]);
                } else if (key === 'variants' && typeof value === 'object' && value !== null) {
                    // For the `variants` object, decompress the class arrays in its values
                    newNode[key] = {};
                    for (const variantKey in value) {
                        if (Object.prototype.hasOwnProperty.call(value, variantKey)) {
                            newNode[key][variantKey] = value[variantKey].map(id => this.dictionary[id]);
                        }
                    }
                } else {
                    // For all other keys, recurse
                    newNode[key] = this.decompress(value);
                }
            }
        }
        return newNode;
    }
}