class ImportGutenbergHtml < ImportHtml

  def cant_import(input_text, xml_doc)
    scan_for = " PROJECT GUTENBERG "
    if input_text.index(scan_for)
      @input_text = input_text
      @xml_doc = xml_doc
      nil
    else
      '"' + scan_for + '" not found.'
    end
  end

  def import_story(user)
    import_init(user)
    accum_xml = []
    @xml_doc.at_css("body").children.each do |child|
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

    if @prev_passage 
       @prev_passage.body = @prev_passage.body.to_s.sub(@last_passage_link, '')
    end

    return @story, nil
  end

  def make_new_passage(user, story, passage_xml_array)
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
      if !new_passage.name.index("End of Project")
        body += @last_passage_link
      end if
      new_passage.body = body
      story_passage_join = StoryPassage.new
      story_passage_join.passage = new_passage
      story_passage_join.sequence = (@sequence+=1).to_s
      story_passage_join.position = next_position
      story.story_passages << story_passage_join
      story.start_passage = new_passage if !story.start_passage

      if @prev_passage
         @prev_passage.body = @prev_passage.body.to_s.sub(@last_passage_link, 
           "[[Next|" + new_passage.name + "]]")
      end
      @prev_passage = new_passage
    end
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
  end
end
