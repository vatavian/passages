require 'nokogiri'
require 'loofah'

class ImportHtml
  def cant_import(input_text, xml_doc)
    "Base class does not import, it just supports subclasses."
  end

  def import_init(user)
    @story = Story.new
    @last_passage_link = "[[End of imported text]]"
    @sequence = 0
    @canvas_min = 100       # x and y value of first new position created
    @canvas_max = 1500      # when x > canvas_max, wrap position to next row (x=canvas_min, y+=canvas_incremen)
    @canvas_increment = 150 # space to leave between new positions
    @px = @canvas_min       # x, y position of next passage's icon in the Twine passage display
    @py = @canvas_min       # 

    @story.user = user
    @story.name = @xml_doc.at_css("title").inner_html
    @story.stylesheet = @xml_doc.at_css("style").inner_html.strip
    @story.story_format = StoryFormat.second
    @escaper = EscapeAllButActiveText.new
    rewrite_internal_links
  end

  def rewrite_internal_links
    # Rewrite links whose href starts with a # (meaning they link within the document) into Twine style.
    # Example: rewrite this:
    # <a href="#anchor_name">label</a>
    # as:
    # [[label|anchor_name]]
    @xml_doc.css('a').each do |anchor|
      href = anchor.attributes['href']&.value
      if href && href[0] == '#'
        link_text = '[[' + (anchor.children[0]&.text || href[1..]) + '|' + href[1..] + ']]'
        anchor.add_next_sibling Nokogiri::XML::Text.new(link_text, anchor.document)
        anchor.remove
      end
    end
  end

  def passage_name_from_a_name(passage_node)
    # return name of first <a name= tag under passage_node
    if passage_node
      passage_node.css('a').each do |anchor|
        name = anchor.attributes['name']&.value&.strip
        if name&.length > 0
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

end

  # Use loofah to escape HTML tags that we don't want ActiveText to manage
  #
  #     raw_html = "<em>em is handled natively in AT</em> <table>but table is not</table>"
  #     Loofah.fragment(unsafe_html).scrub!(EscapeAllButActiveText)
  #     => "<em>em is handled natively in AT</em> &lt;table&gt;but table is not&lt;/table&gt;"
  #
  class EscapeAllButActiveText < Loofah::Scrubber
    ELEMENTS_UNESCAPED_IN_ACTIVETEXT = Set.new([ "del", "em", "pre", "strong" ])
    ELEMENTS_TO_KEEP_NEWLINES_IN = Set.new([ "pre", "code" ])

    def initialize
      @direction = :top_down
    end

    def scrub(node)
      case node.type
      when Nokogiri::XML::Node::ELEMENT_NODE
        if ELEMENTS_UNESCAPED_IN_ACTIVETEXT.include? node.name
          return CONTINUE
        end
      when Nokogiri::XML::Node::TEXT_NODE, Nokogiri::XML::Node::CDATA_SECTION_NODE
        return CONTINUE
      end
      new_text = node.to_s
      new_text.gsub!("\r", '')
      if !(ELEMENTS_TO_KEEP_NEWLINES_IN.include? node.name)
         new_text.gsub!("\n", ' ')
      end
      node.add_next_sibling Nokogiri::XML::Text.new(new_text, node.document)
      node.remove
      return STOP
    end
  end

