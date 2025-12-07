import { Evaluator } from './evaluator';
import { buildNestedPatch } from '../runtime/utils';

export class ActionInterpreter {
    constructor(component) {
        this.component = component;
    }

    run(instructions, scope) {
        if (!instructions || !Array.isArray(instructions)) return;

        const evaluator = new Evaluator(scope);

        for (const instruction of instructions) {
            this.execute(instruction, evaluator);
        }
    }

    execute(instruction, evaluator) {
        // instruction: [OP_CODE, ARG1, ARG2...]
        const [op, ...args] = instruction;

        switch (op) {
            case 'set': {
                // [:set, [:state, "active"], [:param, "id"]]
                const [targetExpr, valueExpr] = args;
                const value = evaluator.evaluate(valueExpr);
                this.assign(targetExpr, value);
                break;
            }
            case 'log': {
                const values = args.map(arg => evaluator.evaluate(arg));
                console.log(`[Tailmix Log]`, ...values);
                break;
            }
            // todo: toggle, fetch, dispatch etc
            default:
                console.warn(`[Tailmix] Unknown action opcode: ${op}`);
        }
    }

    assign(targetExpr, value) {
        // targetExpr: [:state, "active"]
        if (!Array.isArray(targetExpr)) {
            console.error("[Tailmix] Invalid assignment target", targetExpr);
            return;
        }

        const [domain, pathString] = targetExpr;

        if (domain === 'state') {
            const patch = buildNestedPatch(pathString, value);
            this.component.update(patch);
        } else {
            console.warn(`[Tailmix] Cannot assign to read-only domain: ${domain}`);
        }
    }
}
