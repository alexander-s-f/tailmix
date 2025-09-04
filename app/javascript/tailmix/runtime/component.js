import { ActionDispatcher } from './action_dispatcher';
import { Updater } from './updater';

export class Component {
    constructor(element, definition) {
        this.element = element;
        this.definition = definition;

        this.state = this.loadInitialState();
        this.elements = this.findElements();

        this.updater = new Updater(this);
        this.dispatcher = new ActionDispatcher(this);

        console.log(`Tailmix component "${definition.component_name || 'Unnamed'}" initialized.`, this);

        this.updater.run(this.state, {});
    }

    /**
     * Loads and parses the initial state from the data attribute.
     */
    loadInitialState() {
        try {
            return JSON.parse(this.element.dataset.tailmixState || '{}');
        } catch (e) {
            console.error("Tailmix: Invalid initial state JSON.", e);
            return {};
        }
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
        // Также добавляем сам корневой элемент, если у него есть имя
        if (this.element.dataset.tailmixElement) {
            elements[this.element.dataset.tailmixElement] = this.element;
        }
        return elements;
    }

    /**
     * Updates the current state with the provided new state and triggers the update mechanism.
     * The previous state is logged for debugging purposes.
     *
     * @param {Object} newState - The new state values to be merged into the existing state.
     * @returns {void}
     */
    update(newState) {
        const oldState = { ...this.state };
        Object.assign(this.state, newState);

        console.log("State updated", { from: oldState, to: this.state });

        this.element.dataset.tailmixState = JSON.stringify(this.state);

        this.updater.run(this.state, oldState);
    }
}
