require 'nokogiri'
class ImportController < ApplicationController
  before_action :authenticate_user!
  # skip_before_action :verify_authenticity_token

  def new
  end

  def create
    # Rails.logger.debug "import_controller.create file name: " + upload.original_filename
    if params[:html_body]
      file_contents = params[:html_body]
    else
      upload = import_params[:uploaded_story]
      if upload.content_type.chomp != "text/html"
        redirect_to(action: 'new', notice: 'Upload must be text/html.')
        return
      else
        file_contents = upload.read
      end
    end

    doc = Nokogiri::HTML(file_contents)
    story_data = doc.at_css("tw-storydata")
    if !story_data
      respond_to do |format|
        format.html do
          redirect_to(action: 'new', 
                      notice: 'Could not import, tw-storydata not found in ' + upload.original_filename)
        end
        format.json { render json: { error: "tw-storydata not found" }, status: :unprocessable_entity }
      end
      return
    end

    start_pid = story_data.attributes["startnode"]&.value.to_s.strip
    ifid = story_data.attributes["ifid"]&.value.to_s.strip
    story_name = story_data.attributes["name"]&.value.to_s.strip

    if ifid.blank?
      existing_story = Story.find_by(user: current_user, name: story_name)
    else
      existing_story = Story.find_by(user: current_user, ifid: ifid)
    end

    if existing_story
      imported_story = existing_story
    else
      imported_story = Story.new
      imported_story.user = current_user
    end
    imported_story.name = story_name
    imported_story.ifid = ifid
    imported_story.zoom = story_data.attributes["zoom"]&.value.to_s.strip

    imported_story.story_format = StoryFormat.for(story_data.attributes["format"]&.value.to_s.strip, 
                                                  story_data.attributes["format-version"]&.value.to_s.strip)
    story_data.children.each do |story_child|
      case story_child.name
      when "style"
        imported_story.stylesheet = story_child.content
      when "script"
        imported_story.script = story_child.content
      when "tw-passagedata"
        if !import_passage(story_child, imported_story, start_pid)
          Rails.logger.debug "---------------------------------------------Failed to import passage: " + story_child.to_html
          # return
        end
      else
        Rails.logger.debug "---------------------------------------------Unexpected child: " + story_child.name
      end
    end
    #Rails.logger.debug "Found " + imported_story.passages.count.to_s + " passages in uploaded file " + upload.original_filename

    if imported_story.save
      redirect_to imported_story, notice: 'Story was successfully imported.'
    else
      redirect_to(action: 'new', notice: 'Could not save story: ' + imported_story.errors.inspect)
    end
    return
    
    #Rails.logger.debug "Page title is " + doc.xpath("//title").inner_html
    #start = file_contents.index('<tw-storydata')
    #if start 
    #  Rails.logger.debug file_contents[start..start+40]
    #else
    #  Rails.logger.debug "."
    #end
    #end
    #self.data = upload.read
  end

  private
    def import_params
      params.require(:import).permit(:uploaded_story)
    end

    def import_passage(story_child, imported_story, start_pid)
      passage_name = story_child&.attributes["name"]&.value.to_s.strip
      if passage_name.blank?
        return nil
      end
      new_passage_body = story_child.children[0]&.to_html

      # existing_passage = Passage.find_by(name: passage_name, story: imported_story, user: current_user)
      # existing_story_passage = StoryPassage.find_by(story: imported_story, passage.name: passage_name)
      existing_story_passages = StoryPassage.find_by_sql(
        "select story_passages.* from story_passages, passages where story_passages.story_id='" +
         imported_story.id.to_s +
         "' and passages.name='" + passage_name + "'")
      if existing_story_passages.empty?
        existing_story_passage = nil
      else
        existing_story_passage = existing_story_passages[0]
      end
      #new_passage_name = passage_name
      #passage_suffix = 0
      #while Passage.find_by(name: new_passage_name, user: current_user)
      #  passage_suffix += 1
      #  new_passage_name = passage_name + ' ' + passage_suffix.to_s
      #end
      #passage_name = new_passage_name

      #if existing_passage

      same_body = existing_story_passage && new_passage_body == existing_story_passage.passage.body.to_s

      if same_body || (existing_story_passage && existing_story_passage.passage.user == current_user)
        story_passage_join = existing_story_passage
        imported_passage = existing_story_passage.passage
        if same_body
          Rails.logger.debug "Import: passage identical to existing passage: " + imported_passage.name
        else
          Rails.logger.debug "Import: new body for passage: " + imported_passage.name
          imported_passage.body = new_passage_body
        end

        #if imported_passage.body.to_s == 
        #  
        #else
        #  imported_passage = nil
        #  redirect_to(action: 'new', notice: 'You already have a different passage named: ' + existing_passage.name)
        #  return
        #end
      else
        imported_passage = Passage.new
        imported_passage.user = current_user
        imported_passage.name = passage_name
        imported_passage.body = new_passage_body

        story_passage_join = StoryPassage.new
        story_passage_join.passage = imported_passage
        imported_story.story_passages << story_passage_join
        Rails.logger.debug "Import: new passage: " + imported_passage.name
      end

      pid = story_child.attributes["pid"]&.value
      imported_story.start_passage = imported_passage if pid == start_pid

      story_passage_join.sequence = pid
      story_passage_join.tags = story_child.attributes["tags"]&.value
      story_passage_join.position = story_child.attributes["position"]&.value
      story_passage_join.size = story_child.attributes["size"]&.value

      imported_passage
    end
end