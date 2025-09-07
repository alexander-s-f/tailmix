import {Component} from './component';
import {PluginManager} from './plugins';

/**
 * The Tailmix global object that manages the lifecycle of components and plugins.
 * It provides methods for starting the application, hydration of components,
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
     * @param rootElement
     */
    hydrate(rootElement) {
        const componentElements = rootElement.querySelectorAll('[data-tailmix-component]');
        componentElements.forEach(element => {
            if (this._components.has(element)) return;

            const componentName = element.dataset.tailmixComponent;
            const definition = this._definitions[componentName];
            if (!definition) { /* ... */
                return;
            }

            const component = new Component(element, definition, this._pluginManager);
            this._components.set(element, component);

            const componentId = element.dataset.tailmixId;
            if (componentId) {
                this._namedInstances[componentId] = component;
            }
        });

        // External trigger binding
        const triggerElements = rootElement.querySelectorAll('[data-tailmix-trigger-for]');
        triggerElements.forEach(element => {
            const targetId = element.dataset.tailmixTriggerFor;
            const targetComponent = this._namedInstances[targetId];
            if (targetComponent) {
                targetComponent.dispatcher.bindAction(element);
            }
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
    },

    registerPlugin(plugin) {
        this._pluginManager.register(plugin);
    },

    /**
     * Observes changes in the DOM and rehydrates components when they are added or modified.
     */
    observeChanges() {
        if (this._observer) this._observer.disconnect();

        this._observer = new MutationObserver(mutations => {
            for (const mutation of mutations) {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach(node => {
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            // If the component itself was added
                            if (node.matches('[data-tailmix-component]')) {
                                this.hydrate(node);
                            }
                            // If a parent was added, which may contain components
                            this.hydrate(node);
                        }
                    });
                }
            }
        });

        this._observer.observe(document.body, {childList: true, subtree: true});
    }
};

// Initialize Tailmix on page load
document.addEventListener("turbo:load", () => {
    console.log("Tailmix starting...");
    Tailmix.start();
});


export default Tailmix;
