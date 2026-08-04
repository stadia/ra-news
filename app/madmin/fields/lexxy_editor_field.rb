# typed: true

class LexxyEditorField < Madmin::Field
  def searchable?
    options.fetch(:searchable, model.column_names.include?(attribute_name.to_s))
  end
end
