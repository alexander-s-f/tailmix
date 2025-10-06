import { Component } from './component';

const Tailmix = {
    _definitions: {},
    _dictionary: [],
    _components: new Map(),
    _observer: null,

    start() {
        this.loadDefinitions();
        this.hydrate(document.body);
        this.observe(); // Start observing for changes
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
            if (!definition) return;

            const component = new Component(element, definition, this._dictionary);
            this._components.set(element, component); // Store component instance
        });
    },

    observe() {
        if (this._observer) this._observer.disconnect();

        this._observer = new MutationObserver(mutations => {
            for (const mutation of mutations) {
                // When new nodes are added, hydrate them
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        if (node.hasAttribute('data-tailmix-component')) {
                            this.hydrate(node);
                        }
                        this.hydrate(node);
                    }
                });

                // When nodes are removed, disconnect them
                mutation.removedNodes.forEach(node => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        const componentElement = node.hasAttribute('data-tailmix-component') ? node : node.querySelector('[data-tailmix-component]');
                        if (componentElement && this._components.has(componentElement)) {
                            this._components.get(componentElement).disconnect();
                            this._components.delete(componentElement);
                        }
                    }
                });
            }
        });

        this._observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
};

document.addEventListener("turbo:load", () => {
    Tailmix.start();
});

export default Tailmix;