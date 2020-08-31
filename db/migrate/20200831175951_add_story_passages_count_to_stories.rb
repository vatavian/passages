class AddStoryPassagesCountToStories < ActiveRecord::Migration[6.0]
  def change
    add_column :stories, :story_passages_count, :integer, default: 0
    Story.all.each {|s| Story.reset_counters(s.id, :story_passages_count)};
  end
end
