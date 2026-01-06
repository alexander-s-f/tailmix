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

    async execute(instruction, evaluator) {
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
            case 'fetch': {
                // [:fetch, urlExpr, options, successBlock]
                const [urlExpr, options, successBlock] = args;

                let url = evaluator.evaluate(urlExpr);

                if (options.query) {
                    const params = new URLSearchParams();
                    for (const [key, valExpr] of Object.entries(options.query)) {
                        const val = evaluator.evaluate(valExpr);
                        if (val) params.append(key, val);
                    }
                    if (url.includes('?')) url += '&' + params.toString();
                    else url += '?' + params.toString();
                }

                try {
                    const resp = await fetch(url, {
                        method: options.method || 'GET',
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest', // Rails любит это
                            'Accept': options.response_type === 'json' ? 'application/json' : 'text/html'
                        }
                    });

                    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);

                    let data;
                    if (options.response_type === 'json') {
                        data = await resp.json();
                    } else {
                        data = await resp.text();
                    }

                    if (successBlock) {
                        // Creating a new Scope, to which we add the variable response
                        // We need to create a child scope or simply redefine locals
                        const newScope = evaluator.scope.clone();
                        newScope.locals['response'] = data;

                        // Recursively launch the interpreter for the success block
                        this.run(successBlock, newScope);
                    }
                } catch (e) {
                    console.error("[Tailmix] Fetch failed", e);
                    // TODO: handle error block
                }
                break;
            }
            // todo: toggle, dispatch etc
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
