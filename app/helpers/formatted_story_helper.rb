module FormattedStoryHelper
  def format_passage_tag(story_passage)
    '<tw-passagedata pid="' + story_passage.passage.uuid.to_s +
      '" name="' + story_passage.passage.name.to_s +
      '" tags="' + story_passage.tags.to_s +
      '" position="' + story_passage.position.to_s +
      '" size="' + story_passage.size.to_s + '">'
  end

  # was: <%# raw CGI::escapeHTML(s_passage.passage.content) %>
  def format_passage_body(passage)
    case passage.body_type 
    when "TextContent"
      passage.content.gsub("&amp;", "&")
    else
      passage.body_type + '#' + passage.body_id.to_s
    end
  end
end
