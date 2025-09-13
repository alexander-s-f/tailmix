// Operations for server interaction.
export const HttpOperations = {
    fetch: async (interpreter, args, context) => {
        const [options, callbackBody] = args;
        const { url, method = 'get', params = {}, service } = options;

        const resolvedUrl = await interpreter.eval(url, context);
        const urlWithParams = new URL(resolvedUrl, window.location.origin);
        const fetchOptions = {
            method: method.toUpperCase(),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
        };

        const resolvedParams = {};
        for (const [key, value] of Object.entries(params)) {
            resolvedParams[key] = await interpreter.eval(value, context);
        }

        if (method.toLowerCase() === 'get') {
            Object.entries(resolvedParams).forEach(([key, value]) => {
                urlWithParams.searchParams.append(key, value);
            });
        } else {
            fetchOptions.body = JSON.stringify(resolvedParams);
        }

        let responseContext;
        try {
            const response = await window.fetch(urlWithParams.toString(), fetchOptions);
            const responseData = await response.json();
            responseContext = {
                success: response.ok,
                status: response.status,
                result: responseData,
                error: response.ok ? null : { message: response.statusText },
            };
        } catch (error) {
            console.error("Tailmix fetch error:", error);
            responseContext = {
                success: false,
                status: null,
                result: null,
                error: { message: error.message },
            };
        }

        if (callbackBody) {
            await interpreter.run(callbackBody, responseContext);
        }
    },
};
