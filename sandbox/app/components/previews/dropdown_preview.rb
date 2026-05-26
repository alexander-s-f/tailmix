# frozen_string_literal: true

class DropdownPreview < Lookbook::Preview
  # @param align select { choices: [right, left] } "Alignment of menu"
  # @param size select { choices: [sm, md, lg] } "Width of menu"
  def standard(align: :right, size: :md)
    html = Arbre::Context.new do
      dropdown align: align.to_sym, size: size.to_sym do
        trigger "Options"
        menu do
          item "Edit Profile", href: "#edit"
          item "Account Settings", href: "#settings"
          item "Sign Out", class: "text-red-400 hover:bg-red-950/50"
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
