/**
 * Finds an element by the new Tailmix selector convention.
 * e.g., [data-tailmix-panel]
 * @param {HTMLElement} rootElement
 * @param {string} name - The logical name of the element (e.g., "panel").
 * @returns {HTMLElement|null}
 */
export function findElement(rootElement, name) {
    const selector = `[data-tailmix-${name}]`;

    if (rootElement.matches(selector)) {
        return rootElement;
    }
    return rootElement.querySelector(selector);
}