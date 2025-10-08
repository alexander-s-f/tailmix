import { Executor } from './executor';
import { DOMUpdater } from './dom_updater';
import { ActionInterpreter } from './action_interpreter';
import { TriggerManager } from './trigger_manager';
import { RuntimeContext } from './runtime_context';
import { debounce, deepMerge, prettyJSON } from './utils';

export class Component {
    constructor(element, definition, dictionary) {
        this.element = element;
        this.dictionary = dictionary;
        this.definition = this.decompress(definition);
        this._state = this.loadInitialState();

        this.runtimeContext = new RuntimeContext(this);

        this.executor = new Executor();
        this.actionInterpreter = new ActionInterpreter(this);
        this.triggerManager = new TriggerManager(this);

        this.performUpdate = this.performUpdate.bind(this);
        this.debouncedUpdate = debounce(this.performUpdate, 16);

        this.triggerManager.bind();
        this.performUpdate();

        if (this.definition.connect_instructions?.length > 0) {
            this.actionInterpreter.run(this.definition.connect_instructions, {}, this.runtimeContext, {});
        }

        console.log(`Tailmix component "${this.definition.name || 'Unnamed'}" initialized.`);
    }

    disconnect() {
        if (this.definition.disconnect_instructions?.length > 0) {
            this.actionInterpreter.run(this.definition.disconnect_instructions, {}, this.runtimeContext, {});
        }
        console.log(`Tailmix component "${this.definition.name || 'Unnamed'}" disconnected.`);
    }

    get state() {
        return this._state;
    }

    update(newState) {
        this._state = deepMerge(this._state, newState);
        this.runtimeContext.onStateUpdate();
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
            const attributeSet = this.executor.execute(elementDef.rules, this.runtimeContext.scope, param);
            DOMUpdater.apply(elementNode, attributeSet, elementDef.base_classes, elementDef.variant_classes || []);
        });
    }

    loadInitialState() {
        const initialState = JSON.parse(this.element.dataset.tailmixState || '{}');
        const stateDefs = this.definition.states || [];

        const buildState = (defs, stateSlice) => {
            for (const stateDef of defs) {
                const key = stateDef.name;
                if (stateSlice[key] === undefined && stateDef.options.default !== undefined) {
                    stateSlice[key] = stateDef.options.default;
                }
                if (stateDef.nested_states?.length > 0) {
                    stateSlice[key] = stateSlice[key] || {};
                    buildState(stateDef.nested_states, stateSlice[key]);
                }
            }
            return stateSlice;
        }
        return buildState(stateDefs, initialState);
    }

    decompress(node) {
        if (typeof node !== 'object' || node === null) return node;
        if (Array.isArray(node)) return node.map(item => this.decompress(item));

        const newNode = {};
        for (const key in node) {
            if (Object.prototype.hasOwnProperty.call(node, key)) {
                const value = node[key];
                if ((key === 'base_classes' || key === 'variant_classes') && Array.isArray(value)) {
                    newNode[key] = value.map(id => this.dictionary[id]);
                } else if (key === 'variants' && typeof value === 'object' && value !== null) {
                    newNode[key] = {};
                    for (const variantKey in value) {
                        if (Object.prototype.hasOwnProperty.call(value, variantKey)) {
                            newNode[key][variantKey] = value[variantKey].map(id => this.dictionary[id]);
                        }
                    }
                } else {
                    newNode[key] = this.decompress(value);
                }
            }
        }
        return newNode;
    }

}