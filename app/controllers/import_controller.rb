require 'nokogiri'
class ImportController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    params = import_params
    upload = params[:uploaded_story]
    # Rails.logger.debug "import_controller.create file name: " + upload.original_filename
    if upload.content_type.chomp != "text/html"
      redirect_to(action: 'new', notice: 'Upload must be text/html.')
      return
    end
    file_contents = upload.read
    doc = Nokogiri::HTML(file_contents)
    story_data = doc.at_css("tw-storydata")
    if !story_data
      redirect_to(action: 'new', notice: 'Could not import, tw-storydata not found in ' + upload.original_filename)
      return
    end
    imported_story = Story.new
    imported_story.user = current_user
    imported_story.name = story_data.attributes["name"].value
    imported_story.ifid = story_data.attributes["ifid"].value
    imported_story.zoom = story_data.attributes["zoom"].value

    start_pid = story_data.attributes["startnode"].value

    imported_story.story_format = StoryFormat.for(story_data.attributes["format"].value, 
                                                  story_data.attributes["format-version"].value)
    
    #imported_passages = []
    story_data.children.each do |story_child|
      case story_child.name
      when "style"
      when "script"
      when "tw-passagedata"
        if !import_passage(story_child, imported_story, start_pid)
          return
        end
      else
        Rails.logger.debug "---------------------------------------------Unexpected child: " + story_child.name
      end
    end
    #Rails.logger.debug "Found " + imported_story.passages.count.to_s + " passages in uploaded file " + upload.original_filename

    #binding.pry
    if imported_story.save
      redirect_to imported_story, notice: 'Story was successfully imported.'
    else
      redirect_to(action: 'new', notice: 'Could not save story: ' + imported_story.errors.inspect)
    end
    return
    
    #Rails.logger.debug "Page title is " + doc.xpath("//title").inner_html
    #binding.pry
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
      imported_passage = Passage.new
      imported_passage.user = current_user
      imported_passage.title = story_child.attributes["name"].value
      imported_passage.body = story_child.children[0]&.text

      existing_passage = Passage.find_by(title: imported_passage.title, user: current_user)
      if existing_passage
        if existing_passage.body.to_s == imported_passage.body.to_s
          imported_passage = existing_passage
          Rails.logger.debug "Imported passage identical to existing passage: " + imported_passage.title
        else
          imported_passage = nil
          redirect_to(action: 'new', notice: 'You already have a different passage titled: ' + existing_passage.title)
          return
        end
      end

      pid = story_child.attributes["pid"]&.value

      #imported_story.passages << imported_passage
      imported_story.start_passage = imported_passage if pid == start_pid

      story_passage_join = StoryPassage.new
      #story_passage_join.story = imported_story
      story_passage_join.passage = imported_passage
      story_passage_join.sequence = pid
      story_passage_join.tags = story_child.attributes["tags"]&.value
      story_passage_join.position = story_child.attributes["position"]&.value
      story_passage_join.size = story_child.attributes["size"]&.value
      imported_story.story_passages << story_passage_join
      #Rails.logger.debug "story_passage_join.sequence = " + story_passage_join.sequence.to_s + " position = " + story_passage_join.position
      imported_passage
    end
end