# frozen_string_literal: true

require "spec_helper"

RSpec.describe TailmixUi do
  describe "Button (btn)" do
    it "renders as an anchor tag when a path is provided" do
      context = Arbre::Context.new
      context.instance_eval { btn("Click me", "/path/to/go") }
      html = context.to_s

      expect(html).to include("<a ")
      expect(html).to include('href="/path/to/go"')
      expect(html).to include("Click me")
    end

    it "renders as a button tag when no path is provided" do
      context = Arbre::Context.new
      context.instance_eval { btn("Submit") }
      html = context.to_s

      expect(html).to include("<button ")
      expect(html).to include("Submit")
    end

    it "applies correct Tailwind colors and sizes" do
      context = Arbre::Context.new
      context.instance_eval { btn("Danger", color: :danger, size: :xs) }
      html = context.to_s

      expect(html).to include("bg-red-600")
      expect(html).to include("px-1.5")
    end

    it "renders icons" do
      TailmixUi.configure do |config|
        config.icon_renderer = ->(name, options = {}) { "<svg-#{name}></svg-#{name}>".html_safe }
      end

      context = Arbre::Context.new
      context.instance_eval { btn("Trash", icon: "trash") }
      html = context.to_s

      expect(html).to include("<svg-trash></svg-trash>")
      expect(html).to include("Trash")
    end
  end

  describe "Badge (badge)" do
    it "renders correct text and classes for custom statuses" do
      context = Arbre::Context.new
      context.instance_eval { badge(:active) }
      html = context.to_s

      expect(html).to include("Active")
      expect(html).to include("bg-green-900")
    end

    it "renders correct colors for true and false boolean statuses" do
      context1 = Arbre::Context.new
      context1.instance_eval { badge(true) }
      expect(context1.to_s).to include("Yes")
      expect(context1.to_s).to include("bg-green-900")

      context2 = Arbre::Context.new
      context2.instance_eval { badge(false) }
      expect(context2.to_s).to include("No")
      expect(context2.to_s).to include("bg-red-900")
    end

    it "applies specific sizes" do
      context = Arbre::Context.new
      context.instance_eval { badge("Mini", size: :xs) }
      html = context.to_s

      expect(html).to include("text-xs")
    end
  end

  describe "Card (card)" do
    it "renders layout structures and description lines" do
      context = Arbre::Context.new
      context.instance_eval do
        card "System Info" do
          line "IP Address", "192.168.1.1"
          line "Status", true
        end
      end
      html = context.to_s

      expect(html).to include("System Info")
      expect(html).to include("IP Address")
      expect(html).to include("192.168.1.1")
      expect(html).to include("Yes")
      expect(html).to include("bg-green-900")
    end
  end

  describe "Tabs (tabs)" do
    it "compiles definition and renders tab structure" do
      context = Arbre::Context.new
      context.instance_eval do
        tabs active: "billing" do
          tab "Profile", id: "profile" do
            para "Profile panel"
          end
          tab "Billing", id: "billing" do
            para "Billing panel"
          end
        end
      end
      html = context.to_s

      expect(html).to include('data-tailmix-component="TailmixUi::Components::TabsState"')
      expect(html).to include('data-tailmix-element="root"')
      expect(html).to include('role="tablist"')
      expect(html).to include('role="tab"')
      expect(html).to include('role="tabpanel"')
      expect(html).to include("Billing panel")
      expect(html).to include("Profile panel")
    end
  end

  describe "Modal (modal)" do
    it "compiles open definition and renders backdrop + panel" do
      context = Arbre::Context.new
      context.instance_eval do
        modal open: false do
          para "Confirm delete"
        end
      end
      html = context.to_s

      expect(html).to include('data-tailmix-component="TailmixUi::Components::ModalState"')
      expect(html).to include('data-tailmix-state="{&quot;open&quot;:false}"')
      expect(html).to include('data-tailmix-element="backdrop"')
      expect(html).to include('data-tailmix-element="panel"')
      expect(html).to include("Confirm delete")
    end
  end

  describe "Toast (toast)" do
    it "compiles state definition and renders container + body + close button" do
      context = Arbre::Context.new
      context.instance_eval do
        toast open: true, color: :danger do
          body "Something went wrong!"
          close_button
        end
      end
      html = context.to_s

      expect(html).to include('data-tailmix-component="TailmixUi::Components::ToastState"')
      expect(html).to include('data-tailmix-state="{&quot;open&quot;:true}"')
      expect(html).to include('data-tailmix-element="root"')
      expect(html).to include('data-tailmix-element="close_btn"')
      expect(html).to include("Something went wrong!")
    end
  end

  describe "Tooltip (tooltip)" do
    it "compiles active state definition and renders trigger + bubble" do
      context = Arbre::Context.new
      context.instance_eval do
        tooltip do
          trigger do
            "Info Hover"
          end
          bubble "Detailed explanation text"
        end
      end
      html = context.to_s

      expect(html).to include('data-tailmix-component="TailmixUi::Components::TooltipState"')
      expect(html).to include('data-tailmix-state="{&quot;active&quot;:false}"')
      expect(html).to include('data-tailmix-element="root"')
      expect(html).to include('data-tailmix-element="trigger"')
      expect(html).to include('data-tailmix-element="bubble"')
      expect(html).to include("Info Hover")
      expect(html).to include("Detailed explanation text")
    end
  end

  describe "Sidebar (sidebar)" do
    it "compiles open definition and renders backdrop + drawer + main" do
      context = Arbre::Context.new
      context.instance_eval do
        sidebar open: true do
          drawer do
            "Nav links"
          end
          main do
            "Main panel"
          end
        end
      end
      html = context.to_s

      expect(html).to include('data-tailmix-component="TailmixUi::Components::SidebarState"')
      expect(html).to include('data-tailmix-state="{&quot;open&quot;:true}"')
      expect(html).to include('data-tailmix-element="backdrop"')
      expect(html).to include('data-tailmix-element="drawer"')
      expect(html).to include('data-tailmix-element="main"')
      expect(html).to include("Nav links")
      expect(html).to include("Main panel")
    end
  end

  describe "AccordionPanel (accordion_panel)" do
    it "compiles state definition and renders trigger + chevron + content" do
      context = Arbre::Context.new
      context.instance_eval do
        accordion_panel open: true do
          trigger "Faq Header"
          panel do
            para "Faq Description"
          end
        end
      end
      html = context.to_s

      expect(html).to include('data-tailmix-component="TailmixUi::Components::AccordionPanelState"')
      expect(html).to include('data-tailmix-state="{&quot;open&quot;:true}"')
      expect(html).to include('data-tailmix-element="root"')
      expect(html).to include('data-tailmix-element="trigger"')
      expect(html).to include('data-tailmix-element="chevron"')
      expect(html).to include('data-tailmix-element="content"')
      expect(html).to include("Faq Header")
      expect(html).to include("Faq Description")
    end
  end

  describe "Drawer (drawer)" do
    it "compiles active open alignment state and renders backdrop + panel + header + body + footer" do
      context = Arbre::Context.new
      context.instance_eval do
        drawer align: :left, open: true do
          panel do
            header "Drawer Title"
            body "Drawer Body"
            footer "Drawer Footer"
          end
        end
      end
      html = context.to_s

      expect(html).to include('data-tailmix-component="TailmixUi::Components::DrawerState"')
      expect(html).to include('data-tailmix-state="{&quot;open&quot;:true}"')
      expect(html).to include('data-tailmix-element="root"')
      expect(html).to include('data-tailmix-element="backdrop"')
      expect(html).to include('data-tailmix-element="panel"')
      expect(html).to include('data-tailmix-element="close_btn"')
      expect(html).to include("Drawer Title")
      expect(html).to include("Drawer Body")
      expect(html).to include("Drawer Footer")
    end
  end

  describe "Stepper (stepper)" do
    it "compiles state definition and renders steps + buttons inside controls container" do
      context = Arbre::Context.new
      context.instance_eval do
        stepper current_step: 2, max_steps: 3 do
          step(1, "Step One")
          step(2, "Step Two")
          step(3, "Step Three")
          controls do
            prev_button "Back"
            next_button "Forward"
          end
        end
      end
      html = context.to_s

      expect(html).to include('data-tailmix-component="TailmixUi::Components::StepperState"')
      expect(html).to include('data-tailmix-state="{&quot;current_step&quot;:2}"')
      expect(html).to include('data-tailmix-element="root"')
      expect(html).to include('data-tailmix-element="step_item"')
      expect(html).to include('data-tailmix-element="prev_btn"')
      expect(html).to include('data-tailmix-element="next_btn"')
      expect(html).to include("Step One")
      expect(html).to include("Step Two")
      expect(html).to include("Step Three")
      expect(html).to include("Back")
      expect(html).to include("Forward")
    end
  end

  describe "REPL Helper Tools" do
    it "renders component HTML string using TailmixUi.render" do
      html = TailmixUi.render(:btn, "Click", color: :danger, size: :xs)
      expect(html).to include("<button ")
      expect(html).to include("bg-red-600")
      expect(html).to include("Click")
      expect(html).to include("data-tailmix-dev-component")
    end

    it "runs TailmixUi.inspect successfully without crashing" do
      expect { TailmixUi.inspect(:badge) }.to output(/Tailmix UI Component: TailmixUi::Components::Badge/).to_stdout
      expect { TailmixUi.inspect(:btn) }.to output(/Tailmix UI Component: TailmixUi::Components::Button/).to_stdout
    end
  end
end
