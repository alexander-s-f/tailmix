
// A robust debounce utility.
// It ensures a function is not called until it has been idle for a specified time.
export const debounce = (func, wait) => {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func.apply(this, args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
};

export const isObject = (item) => {
    return (item && typeof item === 'object' && !Array.isArray(item));
}

export const deepMerge = (target, source) => {
    let output = { ...target };
    if (isObject(target) && isObject(source)) {
        Object.keys(source).forEach(key => {
            if (isObject(source[key])) {
                if (!(key in target))
                    Object.assign(output, { [key]: source[key] });
                else
                    output[key] = deepMerge(target[key], source[key]);
            } else {
                Object.assign(output, { [key]: source[key] });
            }
        });
    }
    return output;
}

// Takes a path like ['filters', 'name_cont'] and a value,
// returns a nested object like { filters: { name_cont: value } }
export const buildNestedState = (path, value) => {
    return path.reduceRight((acc, key) => ({ [key]: acc }), value);
}


export const getCsrfToken = () => {
    const token = document.querySelector('meta[name="csrf-token"]');
    return token ? token.content : null;
}

export const toQueryString = (obj, prefix) => {
    const str = [];
    let p;
    for (p in obj) {
        if (Object.hasOwn(obj, p)) {
            const k = prefix ? `${prefix}[${p}]` : p;
            const v = obj[p];
            str.push((v !== null && typeof v === 'object') ? toQueryString(v, k) : `${encodeURIComponent(k)}=${encodeURIComponent(v)}`);
        }
    }
    return str.join('&');
}

export const getStateKey = (expression) => {
    if (expression[0] !== 'state' || !expression[1]) {
        console.warn("Tailmix: This operation currently only supports direct state properties (e.g., `state.foo`).");
        return null;
    }
    return expression[1];
}

export function safeReplacer() {
    const seen = new WeakSet();
    return function (_key, value) {
        if (typeof value === 'function') return `[Function ${value.name || 'anonymous'}]`;
        if (typeof value === 'bigint')   return `${value}n`;

        if (value && typeof value === 'object') {
            if (seen.has(value)) return '[Circular]';
            seen.add(value);
        }
        return value;
    };
}

export function prettyJSON(value, space = 2) {
    return JSON.stringify(value, safeReplacer(), space);
}