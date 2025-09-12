import { Component } from './component';
import { PluginManager } from './plugins';

/**
 * The Tailmix global object that manages the lifecycle of components and plugins.
 */
const Tailmix = {
    _namedInstances: {},
    _components: new Map(),
    _definitions: {},
    _pluginManager: new PluginManager(),
    _observer: null,

    /**
     * Starts the Tailmix application by loading component definitions and initializing components.
     */
    start() {
        this.loadDefinitions();
        this._namedInstances = {};
        this._components.clear();

        this.hydrate(document.body);
        this.observeChanges();
    },

    /**
     * Hydrate components within the specified root element.
     * @param {HTMLElement} rootElement The element to search for components within.
     */
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

            const component = new Component(element, definition, this._pluginManager);
            this._components.set(element, component);

            const componentId = element.dataset.tailmixId;
            if (componentId) {
                this._namedInstances[componentId] = component;
            }
        });

        // NEW: Re-introduced logic for binding external triggers.
        const triggerElements = rootElement.querySelectorAll('[data-tailmix-trigger-for]');
        triggerElements.forEach(element => {
            // Avoid re-binding if the element has already been processed (e.g., inside a component).
            if (element.dataset.tailmixTriggerBound) return;

            const targetId = element.dataset.tailmixTriggerFor;
            const targetComponent = this._namedInstances[targetId];

            if (targetComponent) {
                // We ask the TriggerManager of the TARGET component to bind this external element.
                targetComponent.triggerManager.bindAction(element);
                element.dataset.tailmixTriggerBound = "true"; // Mark as bound
            } else {
                // This can happen if the target component is not yet on the page.
                // The observer will handle it when it appears.
            }
        });
    },

    /**
     * Loads and parses the component definitions from the dedicated script tag.
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
     * Retrieves a component instance associated with a given DOM element.
     * @param {Element} element The DOM element.
     * @returns {Component | undefined}
     */
    getComponent(element) {
        const root = element.closest('[data-tailmix-component]');
        return root ? this._components.get(root) : undefined;
    },

    registerPlugin(plugin) {
        this._pluginManager.register(plugin);
    },

    /**
     * Observes DOM changes to automatically hydrate new components and bind triggers.
     */
    observeChanges() {
        if (this._observer) this._observer.disconnect();

        this._observer = new MutationObserver(mutations => {
            for (const mutation of mutations) {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach(node => {
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            // If the added node is a component or contains components/triggers
                            this.hydrate(node);
                        }
                    });
                }
            }
        });

        this._observer.observe(document.body, { childList: true, subtree: true });
    }
};

// Initialize Tailmix when the page loads or Turbo navigates.
document.addEventListener("turbo:load", () => {
    console.log("Tailmix starting...");
    Tailmix.start();
});


export default Tailmix;