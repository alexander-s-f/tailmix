export class TriggerManager {
    constructor(component) {
        this.component = component;
        this.actionInterpreter = component.actionInterpreter;
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
            if (!actionDef?.instructions) return;

            element.addEventListener(eventName, (event) => {
                const context = { event, payload, param: payload };
                this.actionInterpreter.run(actionDef.instructions, context);
            });
        });
    }

    bindModels() {
        const modelElements = this.component.element.querySelectorAll('[data-tailmix-model-state]');
        modelElements.forEach(element => {
            const attribute = element.dataset.tailmixModelAttr;     // 'value'
            const stateKey = element.dataset.tailmixModelState;    // 'value'
            const eventName = element.dataset.tailmixModelEvent || 'input'; // 'input'

            if (!attribute || !stateKey) return;

            element.addEventListener(eventName, (event) => {
                this.component.update({ [stateKey]: event.target[attribute] });
            });
        });
    }
}
