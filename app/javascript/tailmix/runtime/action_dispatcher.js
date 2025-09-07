export class ActionDispatcher {

    /**
     * Creates an instance of ActionDispatcher.
     * @param {Component} component - The component instance to which the dispatcher is attached.
     */
    constructor(component) {
        this.component = component;
        const internalActionElements = this.component.element.querySelectorAll('[data-tailmix-action]');
        internalActionElements.forEach(element => this.bindAction(element));
    }

    /**
     * Binds an action to a specific element based on its data-tailmix-action attribute.
     * The attribute value should be in the format "eventName->actionName".
     * @param {HTMLElement} element - The element to which the action is bound.
     * @return {void}
     */
    bindAction(element) {
        const actionString = element.dataset.tailmixAction;
        const [eventName, actionName] = actionString.split('->');

        if (!eventName || !actionName) {
            console.warn(`Tailmix: Invalid action string "${actionString}"`);
            return;
        }

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
            this.dispatch(actionDefinition, event, element);
        });
    }

    /**
     * Dispatches an action based on the provided action definition and event input.
     * Processes each transition within the action definition and performs state updates
     * or other specified operations on the component.
     * @param {Object} actionDefinition - The definition of the action containing transitions to be processed.
     * @param {Object} event - The event triggering the dispatch, providing context for the action.
     * @param {HTMLElement} triggerElement - The element that triggered the action.
     * @return {void}
     */
    dispatch(actionDefinition, event, triggerElement) {
        let runtimePayload = {};
        const withMapAttr = triggerElement.dataset.tailmixActionWith;
        if (withMapAttr) {
            const withMap = JSON.parse(withMapAttr);
            for (const key in withMap) {
                runtimePayload[key] = this.component.state[withMap[key]];
            }
        }

        actionDefinition.transitions.forEach(transition => {
            this.executeTransition(transition, runtimePayload, event);
        });
    }

    /**
     * Executes a transition within an action definition.
     * This method handles different transition types and applies updates to the component's state.'
     * @param transition
     * @param runtimePayload
     * @param event
     */
    executeTransition(transition, runtimePayload, event) {
        const {type, payload} = transition;
        switch (type) {
            case 'set':
                const resolvedValue = this.resolveValue(payload.value, runtimePayload, event);
                this.component.update({[payload.key]: resolvedValue});
                break;
            case 'toggle':
                this.component.update({[payload.key]: !this.component.state[payload.key]});
                break;
            case 'refresh':
                this.handleRefresh(payload, runtimePayload);
                break;
            case 'dispatch':
                const detail = this.resolveValue(payload.detail, runtimePayload, event);
                this.component.dispatch(payload.name, detail);
                break;
        }
    }

    /**
     * Handles the refresh transition by fetching data from an endpoint based on the provided payload.
     * @param {Object} payload - The payload containing the refresh configuration.
     * @param {Object} runtimePayload - The runtime payload containing values to be used in the endpoint URL.
     * @return {void}
     */
    handleRefresh(payload, runtimePayload) {
        const stateDef = this.component.definition.states[payload.key];
        if (!stateDef?.endpoint) {
            console.warn(`Tailmix: No endpoint defined for state "${payload.key}"`);
            return;
        }

        const params = new URLSearchParams();
        if (payload.params) {
            for (const key in payload.params) {
                const stateKey = payload.params[key];
                params.append(key, this.component.state[stateKey]);
            }
        }

        const url = `${stateDef.endpoint.url}?${params.toString()}`;

        // fetch(url, { headers: { 'Accept': 'text/vnd.turbo-stream.html' } })
        //   .then(r => r.text())
        //   .then(html => Turbo.renderStreamMessage(html));
        console.log(`TODO: Fetch data for "${payload.key}" from ${url}`);
    }

    resolveValue(valueTemplate, runtimePayload, event) {
        if (valueTemplate && valueTemplate.__type === 'payload_value') {
            const keyPath = valueTemplate.key.split('.'); // e.g., "event.target.value"
            let result = {event, ...runtimePayload};
            keyPath.forEach(key => result = result?.[key]);
            return result;
        }
        return valueTemplate;
    }
}
