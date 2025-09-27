
/**
 * Finds data associated with a DOM element via data-key attributes.
 * @param {HTMLElement} element - The DOM element.
 * @param {Component} component - The component instance.
 * @returns {Object} - A hash with "key" contexts, for example { tab: { tab: 'profile', ... } }
 */
const resolveKeyContext = (element, component) => {
    const context = { key: {} };
    if (!element || !element.dataset.tailmixElement) return context;

    const elementName = element.dataset.tailmixElement;
    const elementDef = component.definition.elements[elementName];
    if (!elementDef?.key_config) return context;

    const keyConfig = elementDef.key_config;
    const keyName = keyConfig.name;
    const keyValue = element.dataset[`tailmixKey${keyName.charAt(0).toUpperCase() + keyName.slice(1)}`];

    if (keyValue === undefined) return context;

    const collection = component.state[keyConfig.collection];
    if (!Array.isArray(collection)) return context;

    const item = collection.find(i => String(i[keyName]) === String(keyValue));
    if (item) {
        context.key[keyName] = item;
    }

    return context;
};


export const ThisOperations = {
    /**
     * The `this` operation extracts data from the context of the element on which the event occurred.
     * S-expression: [:this, :key, :tab, :tab]
     * @param interpreter
     * @param args - The path to extract data, for example, ['key', 'tab', 'tab']
     * @param context - The execution context of the action, contains `event`.
     */
    this: (interpreter, args, context) => {
        if (!context.event?.currentTarget) {
            console.warn("Tailmix: `this` can only be used in an action triggered by a DOM event.");
            return null;
        }

        const element = context.event.currentTarget;
        const keyContext = resolveKeyContext(element, interpreter.component);

        // Extract the value by path from args
        return args.reduce((obj, key) => obj?.[key], keyContext);
    }
};
