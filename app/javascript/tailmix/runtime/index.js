import { Component } from './component';

const Tailmix = {
    _namedInstances: {},
    _components: new Map(),
    _definitions: {},

    /**
     * Initializes the application by loading definitions, selecting all elements
     * with data attributes corresponding to components, and registering them as components.
     *
     * @return {void} This method does not return any value.
     */
    start() {
        this.loadDefinitions();
        this._namedInstances = {};

        const componentElements = document.querySelectorAll('[data-tailmix-component]');
        componentElements.forEach(element => {
            const componentName = element.dataset.tailmixComponent;
            const definition = this._definitions[componentName];

            if (!definition) {
                console.warn(`Tailmix: Definition for component "${componentName}" not found.`);
                return;
            }

            const component = new Component(element, definition);
            this._components.set(element, component);

            const componentId = element.dataset.tailmixId;
            if (componentId) {
                this._namedInstances[componentId] = component;
            }
        });

        const triggerElements = document.querySelectorAll('[data-tailmix-trigger-for]');
        triggerElements.forEach(element => {
            const targetId = element.dataset.tailmixTriggerFor;
            const targetComponent = this._namedInstances[targetId];

            if (!targetComponent) {
                console.warn(`Tailmix: Component with id "${targetId}" not found for trigger.`, element);
                return;
            }

            targetComponent.dispatcher.bindAction(element);
        });
    },

    /**
     * Loads and parses the component definitions from a script tag with the attribute `data-tailmix-definitions`.
     * If a valid JSON content is found, it assigns it to the `definitions` variable.
     * Logs an error message to the console in case of parsing failure.
     *
     * @return {void} Does not return a value.
     */
    loadDefinitions() {
        const definitionsTag = document.querySelector('script[data-tailmix-definitions]');
        if (definitionsTag) {
            try {
                this._definitions = JSON.parse(definitionsTag.textContent);
            } catch (e) {
                console.error("Tailmix: Failed to parse component definitions.", e);
            }
        }
    },

    /**
     * Retrieves a component associated with the nearest ancestor element
     * that has the `data-tailmix-component` attribute.
     *
     * @param {Element} element - The DOM element from which the component search begins.
     * @return {*} The component associated with the identified ancestor element, or `undefined` if no component is found.
     */
    getComponent(element) {
        const root = element.closest('[data-tailmix-component]');
        return root ? this._components.get(root) : undefined;
    }
};

// Initialize Tailmix on page load
document.addEventListener("turbo:load", () => {
    console.log("Tailmix starting...");
    Tailmix.start();
});


export default Tailmix;
