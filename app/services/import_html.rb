require 'nokogiri'

class ImportHtml
  def start_import(input_text, xml_doc, input_filename, user, err_msgs)
    start_new_story input_text, xml_doc, input_filename, user, err_msgs
  end

  def continue_import(input_text, xml_doc, input_filename, user, err_msgs)
  end

  def finish_import(err_msgs)
    @story
  end

  def rewrite_all_internal_links(xml_doc)
    xml_doc.css('a').each do |anchor|
      rewrite_one_internal_link anchor
    end
  end

  def rewrite_one_internal_link(anchor)
    # Rewrite link whose href starts with a # (meaning they link within the document) into Twine style.
    # Example: rewrite this:
    # <a href="#anchor_name">label</a>
    # as:
    # [[label|anchor_name]]
    href = anchor.attributes['href']&.value
    if href && href[0] == '#'
      link_text = '[[' + (anchor.children[0]&.text || href[1..]) + '|' + href[1..] + ']]'
      anchor.add_next_sibling new_text_node(link_text, anchor.document)
      anchor.remove
    end
  end

  def passage_name_from_a_name(passage_node)
    # return name of first <a name= tag under passage_node
    if passage_node
      passage_node.css('a').each do |anchor|
        name = anchor.attributes['name']&.value&.strip
        if name && name.length > 0
          return name
        end
      end
    end
    nil
  end

  def next_position
    #position = 'position="' + rand(@canvas_max).to_s + ',' + rand(@canvas_max).to_s
    'position="' + @px.to_s + ',' + @py.to_s + '"'
    @px += @canvas_increment
    if @px > @canvas_max
      @px = @canvas_min
      @py += @canvas_increment
    end
  end

  def line_name(line)
    # Turn text from the body into a passage name.
    # Try ending at the first newline or period, or just take first 90 characters.
    ls = line.strip
    line_end = ls.index(/[\r\n\.]/)
    if !line_end || line_end > 100
      line_end = 90
    end
    return ls[0..line_end-1].strip
  end

  private

  def new_text_node(link_text, xml_doc)
    Nokogiri::XML::Text.new(link_text, xml_doc)
  end

  def story_name_from_xml(xml_doc)
    xml_doc&.at_css("title")&.inner_html&.strip
  end

  def stylesheet_from_xml(xml_doc)
    xml_doc&.at_css("style")&.inner_html&.strip
  end

  def start_new_story(input_text, xml_doc, input_filename, user, err_msgs)
    @story = Story.new
    @sequence = 0
    @canvas_min = 100       # x and y value of first new position created
    @canvas_max = 1500      # when x > canvas_max, wrap position to next row (x=canvas_min, y+=canvas_incremen)
    @canvas_increment = 150 # space to leave between new positions
    @px = @canvas_min       # x, y position of next passage's icon in the Twine passage display
    @py = @canvas_min       # 

    @story.user = user
    @story.name = story_name_from_xml(xml_doc)
    @story.style_s = stylesheet_from_xml(xml_doc)
    @story.story_format = StoryFormat.second # Default to Harlowe
    @escaper = EscapeAllButActiveText.new
    return false # Base class does not currently import.
  end
end
