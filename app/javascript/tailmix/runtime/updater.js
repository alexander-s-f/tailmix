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
        const targetClasses = this.calculateTargetClasses(elementDef, newState);
        const currentClasses = new Set(elementNode.classList);

        // We compare current classes with target classes and apply the difference.
        targetClasses.forEach(cls => {
            if (!currentClasses.has(cls)) {
                elementNode.classList.add(cls);
            }
        });

        currentClasses.forEach(cls => {
            if (!targetClasses.has(cls)) {
                // We avoid removing base classes that were originally in HTML.
                // (This is a simple heuristic; it can be improved if base classes are in the definition)
                const isBaseClass = !this.isVariantClass(elementDef, cls);
                if (!targetClasses.has(cls) && !isBaseClass) {
                    elementNode.classList.remove(cls);
                }
            }
        });
    }

    updateAttributes(elementNode, elementDef, newState) {
        if (elementDef.attribute_bindings) {
            for (const attrName in elementDef.attribute_bindings) {
                if (["text", "html"].includes(attrName)) continue;

                const stateKey = elementDef.attribute_bindings[attrName];
                const newValue = newState[stateKey];

                // We update the attribute only if it has changed.
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

        // Обработка `bind :text`
        const textStateKey = bindings.text;
        if (textStateKey !== undefined) {
            const newText = newState[textStateKey] || '';
            if (elementNode.textContent !== newText) {
                elementNode.textContent = newText;
            }
        }

        // Обработка `bind :html`
        const htmlStateKey = bindings.html;
        if (htmlStateKey !== undefined) {
            const newHtml = newState[htmlStateKey] || '';
            if (elementNode.innerHTML !== newHtml) {
                elementNode.innerHTML = newHtml;
            }
        }
    }

    calculateTargetClasses(elementDef, state) {
        const classes = new Set();

        // 1. We add base classes (if any are in the definition).
        // (We skip this for now, as they are already in the HTML)

        // 2. We apply classes from active variants (dimensions).
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

        // 3. We apply classes from active compound variants.
        if (elementDef.compound_variants) {
            elementDef.compound_variants.forEach(cv => {
                const conditions = cv.on;
                const modifications = cv.modifications;

                const isMatch = Object.entries(conditions).every(([key, value]) => {
                    return state[key] === value;
                });

                if (isMatch && modifications.classes) {
                    modifications.classes.forEach(cls => classes.add(cls));
                }
            });
        }

        return classes;
    }

    isVariantClass(elementDef, className) {
        if (elementDef.dimensions) {
            for (const dimName in elementDef.dimensions) {
                const dim = elementDef.dimensions[dimName];
                for (const variantName in dim.variants) {
                    if (dim.variants[variantName].classes?.includes(className)) return true;
                }
            }
        }
        // ... a check can also be added for compound_variants
        return false;
    }
}
