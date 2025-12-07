export function isObject(item) {
    return (item && typeof item === 'object' && !Array.isArray(item));
}

export function deepMerge(target, source) {
    const output = { ...target };
    if (isObject(target) && isObject(source)) {
        Object.keys(source).forEach(key => {
            if (isObject(source[key])) {
                if (!(key in target)) Object.assign(output, { [key]: source[key] });
                else output[key] = deepMerge(target[key], source[key]);
            } else {
                Object.assign(output, { [key]: source[key] });
            }
        });
    }
    return output;
}

// Converts the path "user.profile.name" and the value "Alex"
// into an object { user: { profile: { name: "Alex" } } }
export function buildNestedPatch(pathString, value) {
    const keys = pathString.split('.');
    return keys.reduceRight((acc, key) => ({ [key]: acc }), value);
}