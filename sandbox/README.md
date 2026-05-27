# Tailmix Sandbox

Rails sandbox app for exercising Tailmix and Tailmix UI components in a real browser.

## What is here

- `app/views/pages/` contains example dashboard pages built with Arbre helpers.
- `app/components/previews/` contains Lookbook previews for the bundled Tailmix UI components.
- `/tailmix` is mounted by the Tailmix engine to serve compiled component definitions.
- `/lookbook` is mounted for interactive component previews.

## Run locally

```bash
bin/dev
```

Then open:

- `http://127.0.0.1:3000/` for the dashboard sandbox
- `http://127.0.0.1:3000/leads` for the CRM leads page
- `http://127.0.0.1:3000/lookbook` for component previews

## Runtime files

Local server artifacts live under `tmp/`, `log/`, and `public/assets/`. They are ignored by git and should not be committed.
