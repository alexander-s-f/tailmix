
// Helper function for attribute rendering
const buildAttributes = async (interpreter, attrsExpr, context) => {
    // Attributes can be an expression, for example `ui.task_item.with(...)`
    // `interpreter.eval` will evaluate it and return the ready attributes object.
    const attrsObject = await interpreter.eval(attrsExpr, context);
    if (!attrsObject) return '';

    return Object.entries(attrsObject)
        .map(([key, value]) => `${key}="${value}"`)
        .join(' ');
};

export const HtmlOperations = {
    html_build: async (interpreter, args, context) => {
        const [tagName, attrsExpr, content, childrenExprs] = args;

        const attributes = await buildAttributes(interpreter, attrsExpr, context);
        let childrenHtml = '';

        if (childrenExprs && childrenExprs.length > 0) {
            // Recursively render child elements
            const childPromises = childrenExprs.map(childExpr =>
                interpreter.eval(childExpr, context)
            );
            childrenHtml = (await Promise.all(childPromises)).join('');
        }

        const tagAttributes = attributes ? ` ${attributes}` : '';
        const tagContent = content ? content : '';

        return `<${tagName}${tagAttributes}>${tagContent}${childrenHtml}</${tagName}>`;
    }
};