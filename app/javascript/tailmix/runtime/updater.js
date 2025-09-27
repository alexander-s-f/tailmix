
/**
 * Finds data associated with the DOM element via data-key attributes.
* Duplicates logic from this.js
 */
const resolveKeyContextForItem = (element, component) => {
    if (!element?.dataset.tailmixElement) return null;

    const elementName = element.dataset.tailmixElement;
    const elementDef = component.definition.elements[elementName];
    if (!elementDef?.key_config) return null;

    const keyConfig = elementDef.key_config;
    const keyName = keyConfig.name;
    const keyValue = element.dataset[`tailmixKey${keyName.charAt(0).toUpperCase() + keyName.slice(1)}`];

    if (keyValue === undefined) return null;

    const collection = component.state[keyConfig.collection];
    if (!Array.isArray(collection)) return null;

    return collection.find(i => String(i[keyName]) === String(keyValue));
};


export class Updater {
    constructor(component) {
        this.component = component;
        this.definition = component.definition;
    }

    async run(newState, oldState) {
        const elementsInDom = this.component.element.querySelectorAll('[data-tailmix-element]');

        const updatePromises = [];
        elementsInDom.forEach(elementNode => {
            updatePromises.push(this.updateElementWithScope(elementNode, newState));
        });

        if (this.component.element.dataset.tailmixElement) {
            const elDef = this.definition.elements[this.component.element.dataset.tailmixElement];
            if (elDef && !elDef.key_config) { // Update the root only if it is not "key"
                updatePromises.push(this.updateElement(this.component.element, elDef, newState));
            }
        }

        await Promise.all(updatePromises);
    }

    async updateElementWithScope(elementNode, newState) {
        const elementName = elementNode.dataset.tailmixElement;
        const elementDef = this.definition.elements[elementName];
        if (!elementDef) return;

        const itemContext = resolveKeyContextForItem(elementNode, this.component);
        const scopedState = { ...newState, ...itemContext };

        await this.updateElement(elementNode, elementDef, scopedState);
    }

    async updateElement(elementNode, elementDef, scopedState) {
        await this.updateClasses(elementNode, elementDef, scopedState);
        this.updateAttributes(elementNode, elementDef, scopedState);
        this.updateContent(elementNode, elementDef, scopedState);
    }

    async updateClasses(elementNode, elementDef, scopedState) {
        const targetClasses = await this.calculateTargetClasses(elementDef, scopedState);

        targetClasses.forEach(cls => {
            if (!elementNode.classList.contains(cls)) {
                elementNode.classList.add(cls);
            }
        });

        elementNode.classList.forEach(cls => {
            const isBaseClass = elementDef.attributes?.classes?.includes(cls);
            if (!targetClasses.has(cls) && !isBaseClass) {
                elementNode.classList.remove(cls);
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
            const textToRender = typeof newText === 'object' && newText !== null ? JSON.stringify(newText) : newText;
            if (elementNode.textContent !== String(textToRender)) {
                elementNode.textContent = textToRender;
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

    async calculateTargetClasses(elementDef, state) {
        const classes = new Set(elementDef.attributes?.classes || []);

        if (elementDef.dimensions) {
            for (const dimName in elementDef.dimensions) {
                const dimDef = elementDef.dimensions[dimName];
                const interpreter = this.component.interpreter;
                let value;

                if (Array.isArray(dimDef.on)) {
                    const evaluationContext = {
                        ...this.buildKeyContextForEval(state),
                        item: state
                    };
                    value = await interpreter.eval(dimDef.on, evaluationContext);
                } else {
                    const stateKey = dimDef.on || dimName;
                    value = state[stateKey] !== undefined ? state[stateKey] : dimDef.default;
                }

                const variantDef = dimDef.variants?.[value];
                if (variantDef?.classes) {
                    variantDef.classes.forEach(cls => classes.add(cls));
                }
            }
        }
        return classes;
    }

    buildKeyContextForEval(itemState) {
        // TODO: This logic should be smarter, but for our case with the key :tab, this is enough
        if (itemState.tab) {
            return { this: { key: { tab: itemState } } };
        }
        return {};
    }

    // calculateTargetClasses(elementDef, state) {
    //     ...
    //     if (elementDef.compound_variants) {
    //         elementDef.compound_variants.forEach(cv => {
    //             const isMatch = Object.entries(cv.on).every(([key, value]) => state[key] === value);
    //             if (isMatch && cv.modifications.classes) {
    //                 cv.modifications.classes.forEach(cls => classes.add(cls));
    //             }
    //         });
    //     }
    //     return classes;
    // }

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