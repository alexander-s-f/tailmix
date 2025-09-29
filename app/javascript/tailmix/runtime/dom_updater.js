// app/javascript/tailmix/runtime/dom_updater.js

export const DOMUpdater = {
    /**
     * Applies the target set of attributes to the DOM element.
     * @param {HTMLElement} element - The target DOM element.
     * @param {Object} attributeSet - An object with attributes from the Executor.
     * @param {Array} baseClasses - The base classes of the element from the definition.
     */
    apply(element, attributeSet, baseClasses = []) {
        // Updating Classes
        const targetClasses = attributeSet.classes;
        element.classList.forEach(cls => {
            if (!targetClasses.has(cls) && !baseClasses.includes(cls)) {
                element.classList.remove(cls);
            }
        });
        targetClasses.forEach(cls => {
            if (!element.classList.contains(cls)) {
                element.classList.add(cls);
            }
        });

        // Updating data-attributes
        for (const [key, value] of Object.entries(attributeSet.data)) {
            const attrName = `data-${key.replace(/([A-Z])/g, '-$1').toLowerCase()}`;
            if (element.getAttribute(attrName) !== String(value)) {
                element.setAttribute(attrName, value);
            }
        }

        // Updating the remaining attributes (value, hidden, type, etc.)
        for (const [key, value] of Object.entries(attributeSet.other)) {
            // ... TODO: logic for `value`, `hidden`, etc. will be here
        }
    }
};
