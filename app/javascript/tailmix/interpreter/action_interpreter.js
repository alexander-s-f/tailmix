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
            case 'toggle': {
                // [:toggle, [:state, "open"]]
                const [targetExpr] = args;
                const current = evaluator.evaluate(targetExpr);
                this.assign(targetExpr, !current);
                break;
            }
            case 'dispatch': {
                // [:dispatch, "event-name", { key: expr, ... }]
                const [eventName, detailExprs] = args;
                const detail = {};
                if (detailExprs) {
                    for (const [key, valExpr] of Object.entries(detailExprs)) {
                        detail[key] = evaluator.evaluate(valExpr);
                    }
                }
                const ev = new CustomEvent(eventName, { bubbles: true, cancelable: true, detail });
                this.component.element.dispatchEvent(ev);
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
                        if (val !== null && val !== undefined) params.append(key, val);
                    }
                    const qs = params.toString();
                    if (qs) url += (url.includes('?') ? '&' : '?') + qs;
                }

                try {
                    const resp = await fetch(url, {
                        method: options.method || 'GET',
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'Accept': options.response_type === 'json' ? 'application/json' : 'text/html'
                        }
                    });

                    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);

                    const data = options.response_type === 'json' ? await resp.json() : await resp.text();

                    if (successBlock) {
                        const newScope = evaluator.scope.clone();
                        newScope.locals['response'] = data;
                        this.run(successBlock, newScope);
                    }
                } catch (e) {
                    console.error("[Tailmix] Fetch failed", e);
                }
                break;
            }
            default:
                console.warn(`[Tailmix] Unknown action opcode: ${op}`);
        }
    }

    // Create an Evaluator bound to a given Scope (used by watchers in component.js)
    evaluatorFor(scope) {
        return new Evaluator(scope);
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
