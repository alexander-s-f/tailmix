import { Scope } from './scope';
import { ExpressionEvaluator } from './expression_evaluator';
import { OPERATIONS } from './operations';

export class ActionInterpreter {
    constructor(component) {
        this.component = component;
    }

    async run(instructions, context, componentScope, elementDef) { // <-- Added elementDef
        if (!instructions) return;

        componentScope.inNewScope(actionScope => {
            // 1. Hydrate param, event, and payload for the action scope
            let param = {};
            const element = context.event.currentTarget;
            if (element && element.dataset.tailmixParam) {
                try {
                    param = JSON.parse(element.dataset.tailmixParam);
                } catch (e) { console.error("Tailmix: Invalid JSON in data-tailmix-param", e, element); }
            }
            actionScope.define('param', param);
            actionScope.define('event', context.event);
            actionScope.define('payload', context.payload);

            // 2. Re-evaluate all `let` rules (`define_var` instructions) for this element
            //    to populate the action's scope with local variables (e.g., `current_tab`).
            const letRules = elementDef.rules.filter(rule => rule[0] === 'define_var');
            const letEvaluator = new ExpressionEvaluator(actionScope);
            for (const rule of letRules) {
                const [_, args] = rule;
                const value = letEvaluator.evaluate(args.expression);
                actionScope.define(args.name, value);
            }

            // 3. Now execute the action's instructions within the fully prepared scope.
            for (const instruction of instructions) {
                const op = instruction.operation;
                const args = instruction.args;
                const handler = OPERATIONS[op];

                if (handler) {
                    handler(this, args, actionScope);
                } else {
                    console.warn(`Unknown action operator: ${op}`);
                }
            }
        });
    }
}