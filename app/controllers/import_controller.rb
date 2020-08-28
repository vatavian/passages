require 'nokogiri'
class ImportController < ApplicationController
  before_action :authenticate_user!
  before_action :set_files, only: [:create]

  def new
    @section_title = 'Import a Story'
  end

  def create
    story_importer = nil
    err_msgs = []
    @files.each do |file|
      input_filename = file.original_filename
      input_text = file.read
      xml_doc = Nokogiri::HTML(input_text)
      if !xml_doc
        err_msgs << 'Could not parse HTML.'
        break
      end
      if story_importer # Already started import with previous file, continue with this one.
        story_importer.continue_import(input_text, xml_doc, input_filename, current_user, err_msgs)
      else               # Find an importer that wants to work on this file
        [ImportTwineHtml, ImportGutenbergHtml, ImportWebibleHtml].each do |imp_class|
          story_importer = imp_class.new
          if story_importer.start_import(input_text, xml_doc, input_filename, current_user, err_msgs)
Rails.logger.debug imp_class.name + " can import " + input_filename.to_s
            break
          else
            story_importer = nil
          end
        end
        story_importer || break # If we didn't find one for the first file, stop trying.
      end
    end
    story = story_importer&.finish_import err_msgs
    respond_to do |format|
      if story&.save
        err_msgs << story.story_passages.count.to_s + " passages now in story " + story.name.to_s
        format.html { redirect_to story, notice: err_msgs&.join("\n") }
      else
        err_msgs << "Error saving story: " + story&.errors&.inspect.to_s
        format.html { redirect_to action: 'new', notice: err_msgs&.join("\n") }
        format.json { render json: { error: err_msgs&.join(",") }, status: :unprocessable_entity }
      end
    end
  end

  private

  def import_params
    params.require(:import).permit(uploaded_files: [])
  end

  def set_files
    if params[:html_body] # updated text of story being edited in Twine editor
      @files = [ImportedText.new(params[:html_body])]
    else # file(s) uploaded
      @files = import_params[:uploaded_files]
    end
    if !@files || @files.count == 0
      err_msg = 'Text to import not found in html_body or in import/uploaded_files.'
      respond_to do |format|
        format.html { redirect_to(action: 'new', notice: err_msg) }
        format.json { render json: { error: err_msg }, status: :unprocessable_entity }
      end
    end
  end
end

class ImportedText
  # Hold the text that was imported and make it look like the params of a file upload
  def initialize(text)
    @text = text
  end
  def original_filename
    nil
  end
  def read
    @text
  end
end
