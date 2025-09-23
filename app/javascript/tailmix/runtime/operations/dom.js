
export const DomOperations = {
    dom_append: async (interpreter, args, context) => {
        const [selectorExpr, htmlExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        const htmlString = await interpreter.eval(htmlExpr, context);

        document.querySelectorAll(selector).forEach(el => {
            el.insertAdjacentHTML('beforeend', htmlString);
        });
    },

    dom_add_class: async (interpreter, args, context) => {
        const [selectorExpr, classesExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        const classes = await interpreter.eval(classesExpr, context);

        document.querySelectorAll(selector).forEach(el => {
            el.classList.add(...classes.split(' '));
        });
    },

    dom_remove: async (interpreter, args, context) => {
        const [selectorExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        document.querySelectorAll(selector).forEach(el => el.remove());
    },

    dom_prepend: async (interpreter, args, context) => {
        const [selectorExpr, htmlExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        const htmlString = await interpreter.eval(htmlExpr, context);

        document.querySelectorAll(selector).forEach(el => {
            el.insertAdjacentHTML('afterbegin', htmlString);
        });
    },

    dom_replace: async (interpreter, args, context) => {
        const [selectorExpr, htmlExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        const htmlString = await interpreter.eval(htmlExpr, context);

        document.querySelectorAll(selector).forEach(el => {
            el.innerHTML = htmlString;
        });
    },

    dom_remove_class: async (interpreter, args, context) => {
        const [selectorExpr, classesExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        const classes = await interpreter.eval(classesExpr, context);

        document.querySelectorAll(selector).forEach(el => {
            el.classList.remove(...classes.split(' '));
        });
    },

    dom_toggle_class: async (interpreter, args, context) => {
        const [selectorExpr, classExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        const className = await interpreter.eval(classExpr, context);

        document.querySelectorAll(selector).forEach(el => {
            // .toggle() works best with a single class
            el.classList.toggle(className);
        });
    },

    dom_set_attribute: async (interpreter, args, context) => {
        const [selectorExpr, nameExpr, valueExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        const name = await interpreter.eval(nameExpr, context);
        const value = await interpreter.eval(valueExpr, context);

        document.querySelectorAll(selector).forEach(el => {
            el.setAttribute(name, value);
        });
    },

    dom_set_value: async (interpreter, args, context) => {
        const [selectorExpr, valueExpr] = args;
        const selector = await interpreter.eval(selectorExpr, context);
        const value = await interpreter.eval(valueExpr, context);

        document.querySelectorAll(selector).forEach(el => {
            if ('value' in el) {
                el.value = value;
            }
        });
    },
};