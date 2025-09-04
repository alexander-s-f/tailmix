export class ActionDispatcher {
    constructor(component) {
        this.component = component;
        this.bindActions();
    }

    bindActions() {
        const actionElements = this.component.element.querySelectorAll('[data-tailmix-action]');

        actionElements.forEach(element => {
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
                this.dispatch(actionDefinition, event);
            });
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
        console.log(`Dispatching action`, actionDefinition);

        actionDefinition.transitions.forEach(transition => {
            const { type, payload } = transition;

            switch (type) {
                case 'set_state':
                    this.component.update(payload);
                    break;
                case 'toggle_state':
                    this.component.update({ [payload]: !this.component.state[payload] });
                    break;
                // refresh_state will be implemented later.
                default:
                    console.warn(`Tailmix: Unknown transition type "${type}"`);
            }
        });
    }
}
