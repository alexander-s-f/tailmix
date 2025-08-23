const SELECTOR_ATTRIBUTE = "data-tm-el";

/**
 * find element [data-tm-el="..."]
 * @param {HTMLElement} rootElement
 * @param {string} name
 * @returns {HTMLElement|null}
 */
export function findElement(rootElement, name) {
    const selector = `[${SELECTOR_ATTRIBUTE}="${name}"]`;
    return rootElement.querySelector(selector);
}