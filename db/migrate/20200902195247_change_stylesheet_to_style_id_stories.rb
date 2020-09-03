class ChangeStylesheetToStyleIdStories < ActiveRecord::Migration[6.0]
  def up
    add_reference :stories, :style_p, references: :passages, index: false
    add_foreign_key :stories, :passages, column: :style_p_id
    Story.all.each do |s|
      if s.stylesheet.to_s&.strip.present?
        p = Passage.new
        p.content = s.stylesheet
        p.name = "Style for " + s.name
        p.user_id = s.user_id
        p.save
        s.style_p_id = p.id
        s.save
      end
    end;
    remove_column :stories, :stylesheet
  end

  def down
    add_column :stories, :stylesheet, :text, null: true
    style_passages = Set.new
    Story.all.each do |s|
      if s.style_p_id
        p = s.style_p
        s.stylesheet = p.content
        s.style_p_id = nil
        s.save
        style_passages << p
      end
    end;
    style_passages.each { |p| p.destroy }
    remove_foreign_key :stories, :passages, column: :style_p_id
    remove_reference :stories, :style_p, index: false
  end
end
