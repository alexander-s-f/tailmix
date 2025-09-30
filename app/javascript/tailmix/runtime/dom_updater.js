const defaultUpdateStrategy = (element, key, value) => {
    if (key === 'content') {
        if (element.textContent !== String(value)) {
            element.textContent = String(value);
        }
        return;
    }

    // Updating both the attribute and the property for standard elements
    if (element.getAttribute(key) !== String(value)) {
        element.setAttribute(key, String(value));
    }
    if (element[key] !== value) {
        element[key] = value;
    }
};

const selectUpdateStrategy = (element, key, value) => {
    // For <select>, the most important thing is to update the .value property.
    // This will reliably change the selected <option>.
    if (key === 'value') {
        if (element.value !== value) {
            element.value = value;
        }
    }
    // We still set the attribute for CSS selectors ([value="..."]) and for debugging
    if (element.getAttribute(key) !== String(value)) {
        element.setAttribute(key, String(value));
    }
};

const STRATEGIES = {
    'SELECT': selectUpdateStrategy,
    'INPUT': defaultUpdateStrategy,
    'TEXTAREA': defaultUpdateStrategy,
    'DEFAULT': defaultUpdateStrategy
};

export const DOMUpdater = {
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

        // -----------------------------------------------------------
        for (const [key, value] of Object.entries(attributeSet.other)) {
            const tagName = element.tagName.toUpperCase();
            const strategy = STRATEGIES[tagName] || STRATEGIES['DEFAULT'];
            strategy(element, key, value);
        }
    }
};
