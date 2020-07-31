json.extract! story, :id, :passage_id, :user_id, :story_format_id, :created_at, :updated_at
json.url story_url(story, format: :json)
