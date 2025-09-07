# Getting Started with Tailmix

Welcome to Tailmix! This guide will walk you through installing the gem, setting up your project, and creating your first component.

## Philosophy

Tailmix is built on the idea of **co-location**. Instead of defining component styles in separate CSS, SCSS, or CSS-in-JS files, you define them directly within the Ruby class that represents your component. This creates self-contained, highly reusable, and easily maintainable UI components.

The core of Tailmix is a powerful and expressive **DSL (Domain-Specific Language)** that allows you to declaratively define how a component should look based on its properties or "variants".

## Installation

Getting started with Tailmix involves two simple steps: adding the gem and installing the JavaScript bridge.

### 1. Add the Gem

Add `tailmix` to your application's Gemfile:

```bash
bundle add tailmix
```

### 2. Install JavaScript Assets

Run the installer to set up the necessary JavaScript files for the client-side bridge (used by actions).

```bash
bin/rails g tailmix:install
```

This command will add tailmix to your importmap.rb and ensure its JavaScript is available in your application.

### Your First Component: A Badge
Let's create a simple BadgeComponent to see Tailmix in action.

#### 1. Define the Component Class



