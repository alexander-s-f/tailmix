// app/javascript/tailmix/runtime/trigger_manager.js

/**
 * Manages the binding of DOM events to component actions.
 * It scans for `data-tailmix-action` attributes and attaches event listeners
 * that will execute the appropriate action script via the interpreter.
 */
export class TriggerManager {
    /**
     * @param {import('./component').Component} component The component instance.
     * @param {import('./interpreter').Interpreter} interpreter The interpreter instance.
     */
    constructor(component, interpreter) {
        this.component = component;
        this.interpreter = interpreter;
    }

    /**
     * Binds all actions declared within the component's elements.
     */
    bindActions() {
        const actionElements = this.component.element.querySelectorAll('[data-tailmix-action]');
        actionElements.forEach(element => this.bindAction(element));
    }

    /**
     * Binds a single element's actions. The attribute value is a space-separated
     * list of event->action pairs, e.g., "click->toggle_open mouseenter->highlight".
     * @param {HTMLElement} element The element with the `data-tailmix-action` attribute.
     */
    bindAction(element) {
        const actionString = element.dataset.tailmixAction;
        if (!actionString) return;

        actionString.split(' ').forEach(actionPair => {
            const [eventName, actionName] = actionPair.split('->');

            if (!eventName || !actionName) {
                console.warn(`Tailmix: Invalid action string "${actionPair}" on`, element);
                return;
            }

            const actionDef = this.component.definition.actions[actionName];
            if (!actionDef?.expressions) {
                console.warn(`Tailmix: Action "${actionName}" not found in component definition.`);
                return;
            }

            element.addEventListener(eventName, (event) => {
                this.interpreter.run(actionDef.expressions, event);
            });
        });
    }
}
