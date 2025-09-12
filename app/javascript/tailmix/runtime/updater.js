export class Updater {
    constructor(component) {
        this.component = component;
        this.definition = component.definition;
    }

    run(newState, oldState) {
        for (const elementName in this.definition.elements) {
            const elementNode = this.component.elements[elementName];
            const elementDef = this.definition.elements[elementName];

            if (!elementNode || !elementDef) continue;

            this.updateElement(elementNode, elementDef, newState, oldState);
        }
    }

    updateElement(elementNode, elementDef, newState, oldState) {
        this.updateClasses(elementNode, elementDef, newState);
        this.updateAttributes(elementNode, elementDef, newState);
        this.updateContent(elementNode, elementDef, newState);
    }

    updateClasses(elementNode, elementDef, newState) {
        // This logic remains unchanged
        const targetClasses = this.calculateTargetClasses(elementDef, newState);
        const currentClasses = new Set(elementNode.classList);

        targetClasses.forEach(cls => {
            if (!currentClasses.has(cls)) {
                elementNode.classList.add(cls);
            }
        });

        currentClasses.forEach(cls => {
            if (!targetClasses.has(cls)) {
                const isBaseClass = !this.isVariantClass(elementDef, cls);
                if (!targetClasses.has(cls) && !isBaseClass) {
                    elementNode.classList.remove(cls);
                }
            }
        });
    }

    updateAttributes(elementNode, elementDef, newState) {
        // This logic remains unchanged
        if (elementDef.attribute_bindings) {
            for (const attrName in elementDef.attribute_bindings) {
                if (["text", "html"].includes(attrName)) continue;

                const stateKey = elementDef.attribute_bindings[attrName];
                const newValue = newState[stateKey];

                if (elementNode.getAttribute(attrName) !== newValue) {
                    if (newValue === null || newValue === undefined) {
                        elementNode.removeAttribute(attrName);
                    } else {
                        elementNode.setAttribute(attrName, newValue);
                    }
                }
            }
        }
    }

    updateContent(elementNode, elementDef, newState) {
        const bindings = elementDef.attribute_bindings;
        if (!bindings) return;

        const textStateKey = bindings.text;
        if (textStateKey !== undefined) {
            const newText = newState[textStateKey] ?? '';
            if (elementNode.textContent !== String(newText)) { // Ensure we compare strings
                elementNode.textContent = newText;
            }
        }

        const htmlStateKey = bindings.html;
        if (htmlStateKey !== undefined) {
            const newHtml = newState[htmlStateKey] ?? '';
            if (elementNode.innerHTML !== String(newHtml)) { // Ensure we compare strings
                elementNode.innerHTML = newHtml;
            }
        }
    }

    calculateTargetClasses(elementDef, state) {
        // This logic remains unchanged
        const classes = new Set();
        if (elementDef.dimensions) {
            for (const dimName in elementDef.dimensions) {
                const dimDef = elementDef.dimensions[dimName];
                const stateValue = state[dimName] !== undefined ? state[dimName] : dimDef.default;
                const variantDef = dimDef.variants?.[stateValue];
                if (variantDef?.classes) {
                    variantDef.classes.forEach(cls => classes.add(cls));
                }
            }
        }
        if (elementDef.compound_variants) {
            elementDef.compound_variants.forEach(cv => {
                const isMatch = Object.entries(cv.on).every(([key, value]) => state[key] === value);
                if (isMatch && cv.modifications.classes) {
                    cv.modifications.classes.forEach(cls => classes.add(cls));
                }
            });
        }
        return classes;
    }

    isVariantClass(elementDef, className) {
        // This logic remains unchanged
        if (elementDef.dimensions) {
            for (const dimName in elementDef.dimensions) {
                const dim = elementDef.dimensions[dimName];
                for (const variantName in dim.variants) {
                    if (dim.variants[variantName].classes?.includes(className)) return true;
                }
            }
        }
        return false;
    }
}