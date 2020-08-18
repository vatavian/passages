module FormattedStoryHelper
  def format_passage_tag(story_passage)
    '<tw-passagedata pid="' + story_passage.passage.uuid.to_s +
      '" name="' + story_passage.passage.name.to_s +
      '" tags="' + story_passage.tags.to_s +
      '" position="' + story_passage.position.to_s +
      '" size="' + story_passage.size.to_s + '">'
  end

  # was: <%# raw CGI::escapeHTML(s_passage.passage.body.to_s) %>
  def format_passage_body(passage_body)
    txt = passage_body.to_s.gsub("&amp;", "&")
    # Remove the outside div that Trix/ActiveText adds
    if txt.sub!(/<div class="trix-content">\n\s*/, '')
      enddiv = txt.index("</div>\n", -10)
      txt = txt[0..enddiv-1] if enddiv
    end
    txt
  end
end
