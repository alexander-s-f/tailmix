import { Scope } from './scope';
import { ExpressionEvaluator } from './expression_evaluator';
import { OPERATIONS } from './operations';

export class ActionInterpreter {
    constructor(component) {
        this.component = component;
    }

    async run(instructions, context, runtimeContext, elementDef) {
        if (!instructions) return;

        const componentScope = runtimeContext.scope;

        await componentScope.inNewScope(async actionScope => {
            try {
                // 1. Hydrate scope
                let param = {};
                const element = context.event?.currentTarget;
                if (element && element.dataset.tailmixParam) {
                    try {
                        param = JSON.parse(element.dataset.tailmixParam);
                    } catch (e) { console.error("Tailmix: Invalid JSON in data-tailmix-param", e, element); }
                }
                actionScope.define('param', param);
                actionScope.define('event', context.event);
                actionScope.define('payload', context.payload);

                // 2. Re-evaluate `let` rules if they exist
                const evaluator = new ExpressionEvaluator(actionScope);

                const letRules = (elementDef?.rules || []).filter(rule => rule[0] === 'define_var');

                for (const rule of letRules) {
                    const [_, args] = rule;
                    const value = evaluator.evaluate(args.expression);
                    actionScope.define(args.name, value);
                }

                // 3. Execute instructions
                for (const instruction of instructions) {
                    const op = instruction.operation;
                    const handler = OPERATIONS[op];

                    if (handler) {
                        await handler(this, instruction, actionScope, runtimeContext, elementDef);
                    } else {
                        console.warn(`Unknown action operator: ${op}`);
                    }
                }
            } catch(e) {
                console.error("Tailmix interpreter error:", e);
            }
        });
    }
}