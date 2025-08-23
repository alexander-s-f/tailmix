/**
 * @param {HTMLElement} element
 * @param {object} command - { field: "classes", method: "toggle", payload: "hidden" }.
 */
export function applyCommand(element, command) {
    const { field, method, payload } = command;

    if (field === 'classes') {
        payload.split(' ').forEach(klass => {
            if (klass) element.classList[method](klass);
        });
    } else if (field === 'data') {
        for (const key in payload) {
            const attributeName = `data-${key.replace(/_/g, '-')}`;
            const value = payload[key];

            if (method === 'remove') {
                element.removeAttribute(attributeName);
            } else if (method === 'toggle') {
                element.hasAttribute(attributeName)
                    ? element.removeAttribute(attributeName)
                    : element.setAttribute(attributeName, value);
            } else { // 'add'
                element.setAttribute(attributeName, value);
            }
        }
    }
}