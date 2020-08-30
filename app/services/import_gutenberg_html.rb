class ImportGutenbergHtml < ImportHtml

  def start_import(input_text, xml_doc, input_filename, user, err_msgs)
    scan_for = " PROJECT GUTENBERG "
    if input_text.index(scan_for)
      super
      @last_passage_link = "\n----End of imported text----"
      @prev_story_name = @story.name
      @index_name = "Index"
      @index_body = [@story.name + ' ' + @index_name + ' <br><ul>']
      continue_import(input_text, xml_doc, input_filename, user, err_msgs)
      return true
    else
      err_msgs << '"' + scan_for + '" not found.'
      return false
    end
  end

  def continue_import(input_text, xml_doc, input_filename, user, err_msgs)
    this_story_name = story_name_from_xml(xml_doc)
    if this_story_name != @prev_story_name
      make_new_passage(user, @story,
        ['<h2>End of ' + @prev_story_name + ", Start of " + this_story_name + '</h2>'])
      @prev_story_name = this_story_name
    end
    rewrite_all_internal_links xml_doc
    
    accum_xml = []
    xml_doc.at_css("body").children.each do |child|
      if child.name != 'comment'
        child_html = child.to_html.strip
        if child_html.length > 0
          child_is_new_passage = child_html.length > 100 ||
                                 child.name == "div" ||
                                 child.name == "article"
          if child_is_new_passage
            make_new_passage(user, @story, accum_xml)
            accum_xml = []
            make_new_passage(user, @story, [child])
          else
            accum_xml << child
          end
        end
      end
    end
    make_new_passage(user, @story, accum_xml)
    nil
  end

  def finish_import(err_msgs)
    if @prev_passage
       @prev_passage.content = @prev_passage.content.sub(@last_passage_link, '')
    end
    @index_body << ["</ul>"]
    @story.start_passage = add_passage_to_story(@index_name, @index_body.join("\n"))
    return @story
  end

  def make_new_passage(user, story, passage_xml_array)
    if passage_xml_array&.present?
      name = nil
      body = ''
      passage_xml_array.each do |passage_xml|
        if name.blank?
          name = passage_name_from_a_name(passage_xml) ||
                         get_passage_name(passage_xml)
        end
        frag = Loofah.fragment(passage_xml.to_s)
        body += frag.scrub!(@escaper).to_s.strip
      end
      if name.blank?
        passage_xml_array.each do |passage_xml|
          name ||= line_name(passage_xml.inner_html)
          break if !name.blank?
        end
      end
      if !name.index("End of Project")
        body += @last_passage_link
      end
      add_passage_to_story(name, body)
    end
  end

  def add_passage_to_story(passage_name, passage_body)
    new_passage = Passage.new
    new_passage.user = @story.user
    if passage_name.blank?
       new_passage.name = new_passage.uuid
    else
       new_passage.name = passage_name
    end
    new_passage.content = passage_body
    story_passage_join = StoryPassage.new
    story_passage_join.passage = new_passage
    story_passage_join.sequence = (@sequence+=1).to_s
    story_passage_join.position = next_position
    @story.story_passages << story_passage_join
    @story.start_passage = new_passage if !@story.start_passage

    if @prev_passage
       @prev_passage.content = @prev_passage.content.sub(@last_passage_link, 
         "[[Next|" + new_passage.name + "]]")
    end
    if new_passage.name != 'Index'
      @index_body << '<li>[[' + new_passage.name + ']]</li>'
    end
    @prev_passage = new_passage
  end

  def get_passage_name(passage_xml)
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
    nil
  end
end
