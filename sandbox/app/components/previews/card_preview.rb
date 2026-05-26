# frozen_string_literal: true

class CardPreview < Lookbook::Preview
  # @param title text "Card title"
  # @param content text "Main content description"
  # @param name_label text "Param name"
  # @param val_label text "Param value"
  def standard(title: "Lead Info Card", content: "Additional information about the client", name_label: "Database Status", val_label: "completed")
    html = Arbre::Context.new do
      card title do
        para content, class: "text-sm text-gray-300 mb-4"
        line name_label, val_label
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
