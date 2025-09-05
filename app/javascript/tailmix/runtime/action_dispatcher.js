export class ActionDispatcher {
    constructor(component) {
        this.component = component;
        const internalActionElements = this.component.element.querySelectorAll('[data-tailmix-action]');
        internalActionElements.forEach(element => this.bindAction(element));
    }

    bindAction(element) {
        const actionString = element.dataset.tailmixAction;
        const [eventName, actionName] = actionString.split('->');

        if (!eventName || !actionName) {
            console.warn(`Tailmix: Invalid action string "${actionString}"`);
            return;
        }

        // We find the corresponding action in definition
        const actionDefinition = this.component.definition.actions[actionName];
        if (!actionDefinition) {
            console.warn(`Tailmix: Action "${actionName}" not found in definition.`);
            return;
        }

        element.addEventListener(eventName, (event) => {
            // Let's make sure the trigger is not part of another component.
            if (element.dataset.tailmixTriggerFor && element.closest('[data-tailmix-component]') !== this.component.element) {
                // Logic to prevent double triggering, if needed
            }
            this.dispatch(actionDefinition, event);
        });
    }

    /**
     * Dispatches an action based on the provided action definition and event input.
     * Processes each transition within the action definition and performs state updates
     * or other specified operations on the component.
     *
     * @param {Object} actionDefinition The definition of the action containing transitions to be processed.
     * @param {Object} event The event triggering the dispatch, providing context for the action.
     * @return {void} This method does not return any value.
     */
    dispatch(actionDefinition, event) {
        console.log(`Dispatching action`, { action: actionDefinition, event });

        let payload = {};
        const payloadAttr = event.currentTarget.dataset.tailmixActionPayload;
        if (payloadAttr) {
            try {
                payload = JSON.parse(payloadAttr);
            } catch (e) {
                console.error("Tailmix: Invalid action payload JSON.", e);
            }
        }

        actionDefinition.transitions.forEach(transition => {
            const { type, payload: transPayload } = transition;

            switch (type) {
                case 'set_state':
                    const resolvedPayload = this.resolvePayload(transPayload, payload);
                    this.component.update(resolvedPayload);
                    break;
                case 'toggle_state':
                    this.component.update({ [transPayload]: !this.component.state[transPayload] });
                    break;
                case 'merge_payload':
                    this.component.update(payload);
                    break;
                default:
                    console.warn(`Tailmix: Unknown transition type "${type}"`);
            }
        });
    }

    resolvePayload(templatePayload, runtimePayload) {
        const result = {};
        for (const key in templatePayload) {
            const value = templatePayload[key];
            if (value && value.__type === 'payload_value') {
                // Found the marker – taking the value from the runtime payload.
                result[key] = runtimePayload[value.key];
            } else {
                // This is a static value - we just copy it.
                result[key] = value;
            }
        }
        return result;
    }
}
