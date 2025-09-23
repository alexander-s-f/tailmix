
// Helper function for attribute rendering
const buildAttributes = async (interpreter, attrsExpr, context) => {
    const attrsObject = await interpreter.eval(attrsExpr, context);
    if (!attrsObject || typeof attrsObject !== 'object') return '';

    return Object.entries(attrsObject)
        .map(([key, value]) => `${key}="${String(value).replace(/"/g, '&quot;')}"`)
        .join(' ');
};

export const HtmlOperations = {
    html_build: async (interpreter, args, context) => {
        const [tagName, attrsExpr, childrenExprs] = args;

        const attributes = await buildAttributes(interpreter, attrsExpr, context);
        let childrenHtml = '';

        if (childrenExprs && childrenExprs.length > 0) {
            const childPromises = childrenExprs.map(childExpr =>
                interpreter.eval(childExpr, context)
            );
            childrenHtml = (await Promise.all(childPromises)).join('');
        }

        const tagAttributes = attributes ? ` ${attributes}` : '';

        return `<${tagName}${tagAttributes}>${childrenHtml}</${tagName}>`;
    }
};