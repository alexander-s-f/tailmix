export class TriggerManager {
    constructor(component) {
        this.component = component;
        this.actionInterpreter = component.actionInterpreter;
        this.runtimeContext = component.runtimeContext;
    }

    bind() {
        this.bindActions();
        this.bindModels();
    }

    bindActions() {
        const actionElements = this.component.element.querySelectorAll('[data-tailmix-action]');
        actionElements.forEach(element => this.bindAction(element));
    }

    bindAction(element) {
        const actionString = element.dataset.tailmixAction;
        if (!actionString) return;

        let payload = {};
        if (element.dataset.tailmixActionWith) {
            try {
                payload = JSON.parse(element.dataset.tailmixActionWith);
            } catch (e) {
                console.error("Tailmix: Invalid JSON in data-tailmix-action-with", e, element);
            }
        }

        actionString.split(' ').forEach(actionPair => {
            const [eventName, actionName] = actionPair.split('->');
            if (!eventName || !actionName) return;

            const actionDef = this.component.definition.actions.find(a => a.name === actionName);
            // Find the definition for the element that has the action attached.
            const elementDef = this.component.definition.elements.find(e => e.name === element.dataset.tailmixElement);

            if (!actionDef?.instructions || !elementDef) return;

            const runtimeContext = this.runtimeContext;

            element.addEventListener(eventName, (event) => {
                const context = { event, payload };
                // Pass the element's definition to the interpreter.
                this.actionInterpreter.run(actionDef.instructions, context, runtimeContext, elementDef);
            });
        });
    }

    bindModels() {
        const modelElements = this.component.element.querySelectorAll('[data-model-state]');
        modelElements.forEach(element => {
            const attribute = element.dataset.modelAttr;
            const statePath = element.dataset.modelState; // e.g. "filters.name_cont"
            const eventName = element.dataset.modelEvent || 'input';

            if (!attribute || !statePath) return;

            element.addEventListener(eventName, (event) => {
                const value = event.target[attribute];
                const keys = statePath.split('.');

                // Build a nested object from the path for the update
                // e.g., "filters.name_cont" and "1" becomes { filters: { name_cont: "1" } }
                const newState = keys.reduceRight((acc, key) => {
                    return { [key]: acc };
                }, value);

                this.component.update(newState);
            });
        });
    }
}