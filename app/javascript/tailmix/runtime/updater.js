/**
 * Represents a class responsible for managing and updating the state-driven changes
 * for a component's elements. The Updater class ensures that the state of each element
 * aligns with the specified definitions and applies updates dynamically.
 */
export class Updater {
    constructor(component) {
        this.component = component;
        this.definition = component.definition;
    }

    /**
     * Updates elements based on the provided new and old state by iterating through the defined schema.
     *
     * @param {Object} newState - The new state to apply to the elements.
     * @param {Object} oldState - The previous state of the elements.
     * @return {void} Does not return a value.
     */
    run(newState, oldState) {
        // We go through each element defined in the scheme (panel, overlay, etc.).
        for (const elementName in this.definition.elements) {
            const elementNode = this.component.elements[elementName];
            const elementDef = this.definition.elements[elementName];

            if (!elementNode || !elementDef) continue;

            this.updateElement(elementNode, elementDef, newState, oldState);
        }
    }

    /**
     * Updates the given HTML element's class list based on the target definition and state changes.
     *
     * @param {HTMLElement} elementNode - The target element whose classes need to be updated.
     * @param {Object} elementDef - The definition of the element specifying its base and variant classes.
     * @param {Object} newState - The new state that determines which classes should be applied to the element.
     * @param {Object} oldState - The previous state used to compute the necessary changes to the element's classes.
     * @return {void} This method does not return a value.
     */
    updateElement(elementNode, elementDef, newState, oldState) {
        const targetClasses = this.calculateTargetClasses(elementDef, newState);
        const currentClasses = new Set(elementNode.classList);

        // Сравниваем текущие классы с целевыми и применяем разницу
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

        // TODO: Add logic to update data- and aria- attributes
    }

    /**
     * Calculates and returns a set of CSS classes based on the provided element definition and state.
     *
     * @param {Object} elementDef - The definition of the element containing dimensions, variants, and compound variants.
     * @param {Object} state - The current state mapping dimensions to their selected values.
     * @return {Set<string>} A set of CSS classes determined by the element definition and state.
     */
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

    /**
     * Determines if the specified class name is a variant class in the given element definition.
     *
     * @param {Object} elementDef - The element definition object containing dimensions and variants.
     * @param {string} className - The name of the class to check for as a variant class.
     * @return {boolean} Returns true if the className is found in the variants of the elementDef, otherwise false.
     */
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
