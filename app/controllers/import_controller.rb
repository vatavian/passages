require 'nokogiri'
class ImportController < ApplicationController
  include FormattedStoryHelper
  before_action :authenticate_user!
  before_action :set_story_xml, only: [:create]

  def new
  end

  def create
    imported_story = story_from_xml
    warn_msg = import_story_xml_children(imported_story)
    if imported_story.save
      redirect_to imported_story, notice: warn_msg + imported_story.story_passages.count.to_s + " passages now in story " + imported_story.name
    else
      redirect_to action: 'new', notice: warn_msg + "/nError saving story: " + imported_story.errors.inspect
    end
  end

  private

  def import_params
    params.require(:import).permit(:uploaded_story)
  end

  def set_story_xml
    input_text = params[:html_body] || import_params[:uploaded_story].read
    if !input_text
      err_msg = 'Text to import not found in html_body or in import/uploaded_story.'
    else
      @story_xml = Nokogiri::HTML(input_text)&.at_css("tw-storydata")
      if !@story_xml
        err_msg = 'tw-storydata not found.'
      end
    end
    if err_msg
      respond_to do |format|
        format.html { redirect_to(action: 'new', notice: err_msg) }
        format.json { render json: { error: err_msg }, status: :unprocessable_entity }
      end
    end
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

  def story_from_xml
    # Find an existing Story that matches the one in @story_xml by ifid or name, or create a new Story.
    # Set all attributes from @story_xml.
    # Return the new or edited Story object.
    user = current_user
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

  def import_story_xml_children(story)
    # Set story's stylesheet, script, and passages from @story_xml.children.
    # Return a string containing warning messages for the user separated by newlines.
    warn_msg = ""
    start_pid = read_story_xml_attrib("startnode")
    @story_xml.children.each do |story_child|
      case story_child.name
      when "style" then story.stylesheet = story_child.content.to_s.strip
      when "script" then story.script = story_child.content.to_s.strip
      when "tw-passagedata"
        if !import_passage(story_child, story, start_pid)
          #warn_msg += "Failed to import passage: " + sanitize(story_child.to_html) + "/n"
          warn_msg += "Failed to import passage: " + story_child.to_s + "/n"
        end
      when "text"
        if !story_child.to_html.strip.blank?
          warn_msg += "Unexpected text: " + story_child.to_s + "/n"
        end
      else
        #warn_msg += "Unexpected child: " + sanitize(story_child.name) + "/n"
        warn_msg += "Unexpected child: " + story_child.name + "/n"
      end
    end
    warn_msg
  end

  def find_existing_story_passage(story, passage_name, pid)
    # Find an existing story_passage that already has this passage (by pid/uuid or name) in this story.
    # A passage that is not yet linked to this story via a story_passage is not returned.
    if pid.length == 36 # find passage by uuid
      passage = Passage.where(user: current_user, uuid: pid).order('created_at DESC').first
      if !passage
        passage = Passage.where(uuid: pid).order('created_at DESC').first
      end
      if passage
        existing_story_passages = StoryPassage.find_by_sql(
         "select * from story_passages where story_id='" + story.id.to_s +
                                    "' and passage_id='" + passage.id.to_s + "'")
        if !existing_story_passages.empty?
          return existing_story_passages.first
        end
      end
      #find_or_create_by(return 
    end
    existing_story_passages = StoryPassage.find_by_sql(
      "select story_passages.* from story_passages, passages where story_passages.story_id='" +
       story.id.to_s + "' and passages.name='" + passage_name + "'")
    if !existing_story_passages.empty?
      return existing_story_passages.first
    end
    return nil
  end

  def import_passage(story_child, imported_story, start_pid)
    passage_name = read_xml_attrib(story_child, "name")
    pid =          read_xml_attrib(story_child, "pid")
    new_passage_body = story_child.children[0]&.to_html

    same_body = false
    existing_story_passage = find_existing_story_passage(imported_story, passage_name, pid)
    if existing_story_passage
      existing_body = existing_story_passage.passage.body.to_s
      existing_body = format_passage_body(existing_body)
      same_body = (new_passage_body.strip == existing_body.strip)
    end

    if same_body || (existing_story_passage && existing_story_passage.passage.user == current_user)
      story_passage_join = existing_story_passage
      imported_passage = existing_story_passage.passage
      if same_body
        Rails.logger.debug "Import: passage identical to existing passage: " + imported_passage.name
      else
        Rails.logger.debug "Import: new body for passage: " + imported_passage.name
        #Rails.logger.debug "Old: '" + existing_story_passage.passage.body.to_s + "'"
        #Rails.logger.debug "New: '" + new_passage_body + "'"
        imported_passage.body = new_passage_body
      end
    else # Need to make a new Passage because didn't have one before or can't edit another user's
      imported_passage = Passage.new
      imported_passage.user = current_user
      imported_passage.name = passage_name
      imported_passage.body = new_passage_body
      imported_passage.uuid = pid if pid.length == 36

      story_passage_join = StoryPassage.new
      story_passage_join.passage = imported_passage
      imported_story.story_passages << story_passage_join
      Rails.logger.debug "Import: new passage: " + imported_passage.name
    end

    imported_story.start_passage = imported_passage if pid == start_pid

    story_passage_join.sequence = pid
    story_passage_join.tags =     read_xml_attrib(story_child, "tags")
    story_passage_join.position = read_xml_attrib(story_child, "position")
    story_passage_join.size =     read_xml_attrib(story_child, "size")

    imported_passage
  end
end