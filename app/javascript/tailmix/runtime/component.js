import { Executor } from './executor';
import { DOMUpdater } from './dom_updater';
import { ActionInterpreter } from './action_interpreter';
import { TriggerManager } from './trigger_manager';

export class Component {
    constructor(element, definition, dictionary) {
        this.element = element;
        this.dictionary = dictionary;
        this.definition = this.decompress(definition);
        this._state = this.loadInitialState();

        this.executor = new Executor();
        this.actionInterpreter = new ActionInterpreter(this);
        this.triggerManager = new TriggerManager(this);

        this.isUpdateQueued = false;

        this.triggerManager.bindActions();
        this.performUpdate();

        console.log(`Tailmix component "${this.definition.name || 'Unnamed'}" initialized.`);
    }

    update(newState) {
        Object.assign(this._state, newState);
        this.scheduleUpdate();
    }

    scheduleUpdate() {
        if (this.isUpdateQueued) return;
        this.isUpdateQueued = true;
        requestAnimationFrame(() => this.performUpdate());
    }

    performUpdate() {
        this.element.dataset.tailmixState = JSON.stringify(this._state);

        const allElements = [this.element, ...this.element.querySelectorAll('[data-tailmix-element]')];

        allElements.forEach(elementNode => {
            const elementName = elementNode.dataset.tailmixElement;
            if (!elementName) return;

            const elementDef = this.definition.elements.find(e => e.name === elementName);
            if (!elementDef) return;

            const attributeSet = this.executor.execute(elementDef.rules, this._state, {});
            DOMUpdater.apply(elementNode, attributeSet, elementDef.base_classes);
        });

        this.isUpdateQueued = false;
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
        if (typeof node !== 'object' || node === null) return node;

        if (Array.isArray(node)) {
            return node.map(item => this.decompress(item));
        }

        const newNode = {};
        for (const key in node) {
            if (key === 'classes' && Array.isArray(node[key])) {
                newNode[key] = node[key].map(id => this.dictionary[id]);
            } else {
                newNode[key] = this.decompress(node[key]);
            }
        }
        return newNode;
    }
}