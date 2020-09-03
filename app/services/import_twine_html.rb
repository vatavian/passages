class ImportTwineHtml
  include FormattedStoryHelper
  def start_import(input_text, xml_doc, input_filename, user, err_msgs)
    if @story_xml = xml_doc&.at_css("tw-storydata")
      @story = story_from_xml(user)
      continue_import(input_text, xml_doc, input_filename, user, err_msgs)
      return true
    else
      err_msgs << 'tw-storydata not found.'
      return false
    end
  end

  def continue_import(input_text, xml_doc, input_filename, user, err_msgs)
    @story_xml = xml_doc&.at_css("tw-storydata")
    err_msgs << import_story_xml_children(@story, user)
    nil
  end

  def finish_import(err_msgs)
    @story
  end

  def read_xml_attrib(node, attr_name)
    node&.attributes[attr_name]&.value.to_s.strip
  end

  def read_story_xml_attrib(attr_name)
    read_xml_attrib(@story_xml, attr_name)
  end

  def find_story_to_update(ifid, story_name, user)
    !ifid.blank? && Story.find_by(user: user, ifid: ifid) || Story.find_by(user: user, name: story_name)
  end

  def story_from_xml(user)
    # Find an existing Story that matches the one in @story_xml by ifid or name, or create a new Story.
    # Set all attributes from @story_xml.
    # Return the new or edited Story object.
    story_name = read_story_xml_attrib("name")
    ifid = read_story_xml_attrib("ifid")
    story = find_story_to_update(ifid, story_name, user)
    if story
      story.ifid = ifid if !ifid.blank?
    else
      story = Story.new
      story.user = user
      story.ifid = ifid
    end
    story.name = story_name
    story.zoom = read_story_xml_attrib("zoom")
    story.story_format = StoryFormat.for(read_story_xml_attrib("format"), 
                                         read_story_xml_attrib("format-version"))
    story
  end

  def import_story_xml_children(story, user)
    # Set story's stylesheet, script, and passages from @story_xml.children.
    # Return a string containing warning messages for the user separated by newlines.
    warn_msg = ""
    start_pid = read_story_xml_attrib("startnode")
    sequence = 0
    @story_xml.children.each do |story_child|
      case story_child.name
      when "style" then story.style_s = story_child.content.to_s.strip
      when "script" then story.script = story_child.content.to_s.strip
      when "tw-passagedata"
        if !import_passage(story_child, story, start_pid, sequence, user)
          warn_msg += "Failed to import passage: " + story_child.to_s + "\n"
        end
      when "text"
        if !story_child.to_html.strip.blank?
          warn_msg += "Unexpected text: " + story_child.to_s + "\n"
        end
      else
        warn_msg += "Unexpected child: " + story_child.name + "\n"
      end
    end
    warn_msg
  end

  def find_existing_story_passage(story, passage_name, pid, user)
    # Find an existing story_passage that already has this passage (by pid/uuid or name) in this story.
    # A passage that is not yet linked to this story via a story_passage is not returned.
    if pid.length == 36 # find passage by uuid
      passage = Passage.where(user: user, uuid: pid).order('created_at DESC').first
      if !passage
        passage = Passage.where(uuid: pid).order('created_at DESC').first
      end
      if passage
        if existing_story_passage = story.story_passages.where(passage_id: passage.id).first
          return existing_story_passage
        end
      end
      #find_or_create_by(return 
    end
    #binding.pry if !@stop_prying
    #if existing_story_passage = story.story_passages.joins(:passages).where("passages.passage_name = ?", passage_name).first
#ActiveRecord::ConfigurationError (Can't join 'StoryPassage' to association named 'passages'; perhaps you misspelled it?)
    #  return existing_story_passage
    #end
    #
    #if existing_story_passage = StoryPassage.find_by_sql(
    #  "select story_passages.* from story_passages, passages where story_passages.story_id='" +
    #   story.id.to_s + "' and passages.name='" + passage_name + "'").first
    #  return existing_story_passage
    #end

    return nil
  end

  def import_passage(story_child, imported_story, start_pid, sequence, user)
    passage_name = read_xml_attrib(story_child, "name")
    pid =          read_xml_attrib(story_child, "pid")
    new_passage_body = story_child.children[0]&.to_html

    same_body = false
    existing_story_passage = find_existing_story_passage(imported_story, passage_name, pid, user)
    if existing_story_passage
      existing_body = existing_story_passage.content
      #existing_body = format_passage_body(existing_body)
      same_body = (new_passage_body.strip == existing_body.strip)
    end

    if same_body || (existing_story_passage && existing_story_passage.passage.user == user)
      story_passage_join = existing_story_passage
      imported_passage = existing_story_passage.passage
      if same_body
        Rails.logger.debug "Import: passage identical to existing passage: " + imported_passage.name
      else
        Rails.logger.debug "Import: new body for passage: " + imported_passage.name
        #Rails.logger.debug "Old: '" + existing_story_passage.passage.content + "'"
        #Rails.logger.debug "New: '" + new_passage_body + "'"
        imported_passage.content = new_passage_body
      end
    else # Need to make a new Passage because didn't have one before or can't edit another user's
      imported_passage = Passage.new
      imported_passage.user = user
      imported_passage.name = passage_name
      imported_passage.content = new_passage_body
      imported_passage.uuid = pid if pid.length == 36

      story_passage_join = StoryPassage.new
      story_passage_join.passage = imported_passage
      imported_story.story_passages << story_passage_join
      Rails.logger.debug "Import: new passage: " + imported_passage.name
    end

    imported_story.start_passage = imported_passage if pid == start_pid

    story_passage_join.sequence = (sequence+=1).to_s
    story_passage_join.tags =     read_xml_attrib(story_child, "tags")
    story_passage_join.position = read_xml_attrib(story_child, "position")
    story_passage_join.size =     read_xml_attrib(story_child, "size")
    story_passage_join.save

    imported_passage
  end
end
