import {ActionDispatcher} from './action_dispatcher';
import {Updater} from './updater';
import { ReactionEngine } from './reaction_engine';

/**
 * Represents a component instance that manages the state and behavior of a specific UI element.
 * The Component class is responsible for loading and initializing the component's state,
 * finding and managing its elements, and updating the UI based on the component's state.
 */
export class Component {
    constructor(element, definition, pluginManager) {
        this.element = element;
        this.definition = definition;
        this._state = this.loadInitialState();
        this.elements = this.findElements();
        this.updater = new Updater(this);
        this.dispatcher = new ActionDispatcher(this);
        this.reactionEngine = new ReactionEngine(this);

        // --- API ---
        this.api = {
            get state() {
                return {...this._state};
            },
            setState: (newState) => this.update(newState),
            element: (name) => this.elements[name],
            runAction: (name, payload) => this.dispatcher.runActionByName(name, payload),
            dispatch: (name, detail) => this.dispatch(name, detail),
            on: (name, callback) => this.element.addEventListener(`tailmix:${name}`, callback),
        };

        this.initializeModels();
        this.updater.run(this._state, {});
        pluginManager.connect(this);

        console.log(`Tailmix component "${this.definition.name || 'Unnamed'}" initialized.`, this);
    }

    /**
     * Gets the current state of the component.
     * @return {Object} The current state of the component.
     */
    get state() {
        return this._state;
    }

    /**
     * Updates the component's state with the provided new state and triggers the update mechanism.
     * The previous state is logged for debugging purposes.
     '
     * @param newState
     */
    update(newState) {
        const oldState = { ...this._state };
        const changedKeys = new Set();

        for (const key in newState) {
            if (this._state[key] !== newState[key]) {
                changedKeys.add(key);
            }
        }

        // If nothing has changed, we exit.
        if (changedKeys.size === 0) return;

        Object.assign(this._state, newState);
        this.element.dataset.tailmixState = JSON.stringify(this._state);

        this.updater.run(this._state, oldState);
        this.reactionEngine.run(changedKeys);
    }

    /**
     * Dispatches a custom event with the specified name and detail.
     * @param {string} name - The name of the event to be dispatched.
     * @param {any} detail - The detail object to be attached to the event.
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
            if (initialState[key] === undefined && stateSchema[key].default !== undefined) {
                initialState[key] = stateSchema[key].default;
            }
        }
        return initialState;
    }

    /**
     * Finds and retrieves all elements with a specific data attribute (`data-tailmix-element`)
     * within the current root element, and maps their associated names to the DOM nodes.
     * The root element itself is included if it also has the attribute with a defined name.
     *
     * @return {Object} An object where the keys are the names specified in the `data-tailmix-element`
     *                  attribute, and the values are the corresponding DOM nodes.
     */
    findElements() {
        const elements = {};
        const elementNodes = this.element.querySelectorAll('[data-tailmix-element]');
        elementNodes.forEach(node => {
            const name = node.dataset.tailmixElement;
            elements[name] = node;
        });
        // We also add the root element itself, if it has a name.
        if (this.element.dataset.tailmixElement) {
            elements[this.element.dataset.tailmixElement] = this.element;
        }
        return elements;
    }

    /**
     * Initializes models by binding event listeners to elements and updating state accordingly.
     * This method iterates through the component's elements and model bindings,
     * and sets up event listeners for each attribute that needs to be updated.
     *
     * @return {void} This method does not return a value.
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
                    if (binding.action) {
                        // It is possible to add action execution after model update.
                    }
                });
            }
        }
    }
}
