class ImportWebibleHtml < ImportHtml
  # Import a chapter of the HTML version of the World English Bible https://eBible.org
  # All chapters are included in the download at https://ebible.org/eng-web/eng-web_html.zip

  def start_import(input_text, xml_doc, input_filename, user, err_msgs)
@nopry = nil      
    scan_for = "<title>World English Bible"
    if input_text.index(scan_for)
      @remove_pattern = /World English Bible with Deuterocanon[ ]*/
      super
      @story.name = @story.name.sub(@remove_pattern, '') if @remove_pattern
      @story.story_format = StoryFormat.first # Chapbook
      continue_import(input_text, xml_doc, input_filename, user, err_msgs)
      true
    else
      err_msgs << '"' + scan_for + '" not found.'
      false
    end
  end

  def continue_import(input_text, xml_doc, input_filename, user, err_msgs)
    @input_filename = input_filename
    rewrite_all_internal_links xml_doc
    accum_xml = []
    xml_doc.at_css("div.copyright")&.remove
    xml_doc.at_css("body").children.each do |child|
      if child.name != 'comment'
        child_html = child.to_html.strip
        if child_html.length > 0
          accum_xml << child
        end
      end
    end
    make_new_passage(user, accum_xml)
    nil
  end

  def make_new_passage(user, passage_xml_array)
    if passage_xml_array&.present?
      new_passage = Passage.new
      new_passage.user = user
      body = ''
      passage_xml_array.each do |passage_xml|
        if new_passage.name.blank?
          new_passage.name = passage_name_from_a_name(passage_xml) ||
                             get_passage_name(passage_xml)
        end
        frag = Loofah.fragment(passage_xml.to_s)
        body += frag.scrub!(@escaper).to_s.strip
      end
      if !new_passage.name
        passage_xml_array.each do |passage_xml|
          new_passage.name ||= line_name(passage_xml.inner_html)
          break if new_passage.name&.length > 0
        end
      end

      new_passage.body = body
      story_passage_join = StoryPassage.new
      story_passage_join.passage = new_passage
      story_passage_join.sequence = (@sequence+=1).to_s
      story_passage_join.position = next_position
      @story.story_passages << story_passage_join
      @story.start_passage = new_passage if !@story.start_passage

    end
  end

  def get_passage_name(passage_xml)
    return @input_filename if @input_filename
    if passage_xml
      case passage_xml.name
      when "pre"
        return line_name(passage_xml.inner_html)
      when "img"
        return "#{(passage_xml.attributes['alt']&.value) || 'Image'}" +
               ":#{passage_xml.attributes['src']&.value}"
      when "table"
        if @table_index
          return "Table " + (@table_index += 1).to_s
        else
          @table_index = 1
          return "Table"
        end
      end
      passage_xml.children&.each do |child|
        child_name = get_passage_name(child)
        if not child_name.blank?
          return child_name
        end
      end
    end
  end

  def rewrite_one_internal_link(anchor)
    # Rewrite a href link into Twine style.
    # Example: rewrite this:
    # <a href="#anchor_name">label</a>
    # as:
    # [[label|anchor_name]]
    # or: # <a href="https://www.gutenberg.org/0/5/5-h/5-h.htm">Constitution</a>
    # as: [[Constitution|www.gutenberg.org/0/5/5-h/5-h.htm]]
    href = anchor.attributes['href']&.value
    label = anchor.inner_html
    case label
    when '&lt;'
      label = '<'
    when '&gt;'
      label = '>'
    end

    if href
      if href == 'index.htm' || label =~ @remove_pattern
        new_text = '' # Remove these links entirely
      elsif label&.index('"popup"') || anchor.attributes['class']&.value == 'notebackref'
        return # Leave these links as-is, they are only within the chapter and they work.
      else
        href = $1 if href =~ /[^\/]*:\/+(.*)/
        href = href[1..] if href[0] == '#'
        new_text = '[[' + (label || href) + '|' + href + ']]'
      end
#Rails.logger.debug "---Original link: " + anchor.to_s          
#Rails.logger.debug "+++New link: " + new_text
      anchor.add_next_sibling Nokogiri::XML::Text.new(new_text, anchor.document)
      anchor.remove
    end
  end

end
