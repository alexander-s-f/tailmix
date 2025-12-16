export class DOMPatcher {
    static patch(element, result) {
        // 1. Classes
        const newClassString = Array.from(result.classes).join(' ');
        if (element.className !== newClassString) {
            element.className = newClassString;
        }

        // 2. Data Attributes
        for (const [key, value] of Object.entries(result.data)) {
            // camelCase -> kebab-case
            const attrName = `data-${key.replace(/[A-Z]/g, m => "-" + m.toLowerCase())}`;
            const strValue = String(value);
            if (element.getAttribute(attrName) !== strValue) {
                element.setAttribute(attrName, strValue);
            }
        }

        // 3. Aria Attributes
        for (const [key, value] of Object.entries(result.aria)) {
            const attrName = `aria-${key.replace(/[A-Z]/g, m => "-" + m.toLowerCase())}`;
            const strValue = String(value);
            if (element.getAttribute(attrName) !== strValue) {
                element.setAttribute(attrName, strValue);
            }
        }

        // 4. Other Attributes
        for (const [key, value] of Object.entries(result.other)) {
            if (key === 'value' && 'value' in element) {
                if (element.value !== value) element.value = value;
            } else if (key === 'checked' && 'checked' in element) {
                element.checked = !!value;
            } else if (key === 'disabled' && 'disabled' in element) {
                element.disabled = !!value;
            } else {
                if (element.getAttribute(key) !== String(value)) {
                    element.setAttribute(key, String(value));
                }
            }
        }

        // 5. Properties (value, checked, etc.)
        // result.props come from Renderer
        if (result.props) {
            for (const [key, value] of Object.entries(result.props)) {
                // Special handling for 'value' to prevent cursor reset
                if (key === 'value' && element.tagName === 'INPUT') {
                    // Update only if the actual value differs
                    if (element.value !== String(value)) {
                        element.value = String(value);
                    }
                }
                else if (key === 'checked') {
                    element.checked = !!value;
                }
                else if (key === 'disabled') {
                    element.disabled = !!value;
                }
                else {
                    // Fallback for other attributes (src, href)
                    if (element.getAttribute(key) !== String(value)) {
                        element.setAttribute(key, String(value));
                    }
                }
            }
        }
    }
}