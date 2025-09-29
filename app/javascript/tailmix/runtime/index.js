import { Component } from './component';

const Tailmix = {
    _definitions: {},
    _dictionary: [],
    _components: new Map(),

    start() {
        this.loadDefinitions();
        this.hydrate(document.body);
        // TODO: MutationObserver can be added here for dynamically added components.
    },

    loadDefinitions() {
        const definitionsTag = document.querySelector('script[data-tailmix-definitions]');
        if (definitionsTag) {
            try {
                const payload = JSON.parse(definitionsTag.textContent);
                this._dictionary = payload.dictionary || [];
                this._definitions = payload.components || {};
            } catch (e) {
                console.error("Tailmix: Failed to parse definitions.", e);
            }
        }
    },

    hydrate(rootElement) {
        const componentElements = rootElement.querySelectorAll('[data-tailmix-component]');
        componentElements.forEach(element => {
            if (this._components.has(element)) return;

            const componentName = element.dataset.tailmixComponent;
            const definition = this._definitions[componentName];
            if (!definition) {
                console.warn(`Tailmix: Definition for component "${componentName}" not found.`);
                return;
            }

            const component = new Component(element, definition, this._dictionary);
            this._components.set(element, component);
        });
    }
};

document.addEventListener("turbo:load", () => {
    Tailmix.start();
});

export default Tailmix;