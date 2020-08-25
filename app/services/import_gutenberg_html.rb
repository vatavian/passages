class ImportGutenbergHtml
  def cant_import(input_text, xml_doc)
    if input_text.index(" PROJECT GUTENBERG ")
      @input_text = input_text
      @xml_doc = xml_doc
      nil
    else
      '" PROJECT GUTENBERG " not found.'
    end
  end

  def import_story(user)
    story = Story.new
    @last_passage_link = "\n----End of imported text----"
    @sequence = 0
    @canvas_min = 100       # x and y value of first new position created
    @canvas_max = 1500      # when x > canvas_max, wrap position to next row (x=canvas_min, y+=canvas_incremen)
    @canvas_increment = 150 # space to leave between new positions
    @px = @canvas_min       # x, y position of next passage's icon in the Twine passage display
    @py = @canvas_min       # 

    story.user = user
    story.name = @xml_doc.at_css("title").inner_html
    story.stylesheet = @xml_doc.at_css("style").inner_html.strip
    story.story_format = StoryFormat.second
    accum_xml = nil
    accum_body = []
    rewrite_internal_links
    @xml_doc.at_css("body").children.each do |child|
      if child.name != 'comment'
        child_html = child.to_html.strip
        if child_html.length > 0
          child_is_new_passage = child_html.length > 100 ||
                               child.name == "div" ||
                               child.name == "article"
          if child_is_new_passage
            if accum_body.present?
              make_new_passage(user, story, accum_body.join("\n"), accum_xml)
              accum_body = []
              accum_xml = nil
            end
            make_new_passage(user, story, child_html, child)
          else
            accum_body << child_html
            accum_xml ||= child
          end
        end
      end
    end
    accum_body.present? && make_new_passage(user, story, accum_body.join("\n"), accum_xml)
    return story, nil
  end

  def rewrite_internal_links
    @xml_doc.css('a').each do |anchor|
      href = anchor.attributes['href']&.value
      if href
        if href[0] == '#'
          anchor.inner_html = '[[' + anchor.children[0]&.text.to_s + '|' + href[1..] + ']]'
          anchor.remove_attribute('href')
          anchor.name = "code"
        end
      #else
      #  name = anchor.attributes['name']&.value
      end
    end
  end

  def passage_name_from_a_name(passage_node)
    # return name of first <a name= tag under passage_node
    # remove all <a name= tags from this part of the document
    node_name = nil
    if passage_node
      passage_node.css('a').each do |anchor|
        name = anchor.attributes['name']&.value
        if name
          node_name ||= name
          #anchor.delete(anchor)
        end
      end
    end
    node_name
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

  def make_new_passage(user, story, passage_body, passage_xml)
    if passage_body&.length > 0
#Rails.logger.debug "make_new_passage: " + passage_body[0..100]
      new_passage = Passage.new
      new_passage.user = user
      new_passage.name = passage_name_from_a_name(passage_xml) ||
                         get_passage_name(passage_xml) ||
                         line_name(passage_body)
#Rails.logger.debug "make_new_passage: final name: " + new_passage.name
      if new_passage.name.index("End of Project")
        new_passage.body = passage_body
      else
        new_passage.body = passage_body + @last_passage_link
      end if
#Rails.logger.debug "Passage Body: " + new_passage.body.to_s[0..60]
      story_passage_join = StoryPassage.new
      story_passage_join.passage = new_passage
      story_passage_join.sequence = (@sequence+=1).to_s
      story_passage_join.position = next_position
      story.story_passages << story_passage_join
      story.start_passage = new_passage if !story.start_passage

      if @prev_passage
         @prev_passage.body = @prev_passage.body.to_s.sub(@last_passage_link, 
           "\n\n[[Next|" + new_passage.name + "]]")
      end
      @prev_passage = new_passage
    end
  end

  def get_passage_name(passage_xml)
    if passage_xml
      case passage_xml.name
      when "pre"
#Rails.logger.debug "get_passage_name: pre: " + line_name(passage_xml.inner_html)
        return line_name(passage_xml.inner_html)
      when "img"
#Rails.logger.debug "get_passage_name: img: " + passage_xml.attributes["alt"]&.value || passage_xml.attributes["src"]&.value || "image"
        return passage_xml.attributes["alt"]&.value ||
               passage_xml.attributes["src"]&.value || "image"
      end
      passage_xml.children&.each do |child|
        child_name = get_passage_name(child)
        if not child_name.blank?
#Rails.logger.debug "get_passage_name: child_name: " + child_name
          return child_name
        end
      end
#Rails.logger.debug "get_passage_name: line_name: " + line_name(passage_xml.inner_html)
      return line_name(passage_xml.inner_html)
    end
  end

  def line_name(line)
    ls = line.strip
    line_end = ls.index(/[\r\n\.]/)
    if !line_end || line_end > 100
      line_end = 90
    end
    return ls[0..line_end-1]
  end

end