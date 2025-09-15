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

            // If an element has `each` — we use a new collection renderer.
            if (elementDef.each_config) {
                this.updateEach(elementNode, elementDef, newState, old_state);
            } else {
                this.updateElement(elementNode, elementDef, newState, oldState);
            }
        }
    }

    // --- Collection Renderer (Reconciler) ---

    updateEach(container, containerDef, newState, oldState) {
        const { state_key, template_name, key: key_prop } = containerDef.each_config;
        const items = newState[state_key] || [];
        const templateDef = containerDef.templates[template_name];

        const templateNode = container.querySelector(`template[data-template-name="${template_name}"]`);
        if (!templateNode) {
            console.error(`Tailmix: Template "${template_name}" not found inside`, container);
            return;
        }

        const existingNodesByKey = new Map();
        container.querySelectorAll(`[data-tailmix-key]`).forEach(node => {
            existingNodesByKey.set(node.dataset.tailmixKey, node);
        });

        const activeKeys = new Set();

        // Update and Add items
        items.forEach((itemData, index) => {
            const key = itemData[key_prop];
            if (key === undefined) {
                console.warn("Tailmix: Missing key for item in `each` loop. Rendering will be inefficient.", itemData);
            }
            activeKeys.add(String(key));

            let node = existingNodesByKey.get(String(key));

            if (node) { // Node exists, just update it
                // TODO: A more granular update. For now, we can just re-bind.
                this.bindTemplateInstance(node, templateDef, itemData);
            } else { // Node doesn't exist, create it
                const newInstance = templateNode.content.firstElementChild.cloneNode(true);
                newInstance.dataset.tailmixKey = key;
                this.bindTemplateInstance(newInstance, templateDef, itemData);
                container.appendChild(newInstance);
            }
        });

        // Remove old items
        existingNodesByKey.forEach((node, key) => {
            if (!activeKeys.has(key)) {
                node.remove();
            }
        });
    }

    bindTemplateInstance(instance, templateDef, itemData) {
        // This is a simplified binding. It finds elements defined in the template
        // and applies their state based on the itemData.
        for (const elName in templateDef.elements) {
            const elDef = templateDef.elements[elName];
            const node = instance.matches(`[data-tailmix-element="${elName}"]`)
                ? instance
                : instance.querySelector(`[data-tailmix-element="${elName}"]`);

            if (!node) continue;

            // Here, we would run a version of `updateElement`, but the state
            // comes from `itemData` instead of the main component state.
            const itemContextState = this.buildItemContextState(elDef, itemData);
            this.updateElement(node, elDef, itemContextState, {}); // oldState can be empty for simplicity
        }
    }

    buildItemContextState(elementDef, itemData) {
        const state = {};
        // Example for `bind_dimension :completed, to: task.completed`
        if (elementDef.dimension_bindings) { // We need to add this to the DSL
            for (const dimName in elementDef.dimension_bindings) {
                const itemProp = elementDef.dimension_bindings[dimName].property;
                state[dimName] = itemData[itemProp];
            }
        }
        // Example for `bind :text, to: task.title`
        if (elementDef.attribute_bindings) {
            for (const attrName in elementDef.attribute_bindings) {
                const binding = elementDef.attribute_bindings[attrName]; // e.g., { type: 'item', property: 'title' }
                if (binding.type === 'item') {
                    state[attrName] = itemData[binding.property];
                }
            }
        }
        return state;
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