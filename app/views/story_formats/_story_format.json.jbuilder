json.extract! story_format, :id, :name, :author, :header, :footer, :created_at, :updated_at
json.url story_format_url(story_format, format: :json)
