require 'nokogiri'
class ImportController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story_importer, only: [:create]

  def new
    @section_title = 'Import a Story'
  end

  def create
    imported_story, warn_msg = @story_importer.import_story(current_user)
    warn_msg ||= ""
    if imported_story&.save
      redirect_to imported_story, notice: warn_msg + imported_story.story_passages.count.to_s + " passages now in story " + imported_story.name
    else
      redirect_to action: 'new', notice: warn_msg + "\nError saving story: " + imported_story&.errors.inspect
    end
  end

  private

  def import_params
    params.require(:import).permit(:uploaded_story)
  end

  def set_story_importer
    input_text = params[:html_body] || import_params[:uploaded_story].read
    if !input_text
      err_msg = 'Text to import not found in html_body or in import/uploaded_story.'
    else
      xml_doc = Nokogiri::HTML(input_text)
      if !xml_doc
        err_msg = 'Could not parse HTML.'
      else
        err_msgs = []
        [ImportTwineHtml, ImportGutenbergHtml].each do |imp_class|
          @story_importer = imp_class.new
          if this_imp_err = @story_importer.cant_import(input_text, xml_doc)
            err_msgs << this_imp_err
          else
            Rails.logger.debug imp_class.name + " can import"
            err_msgs = nil
            break
          end
        end
        err_msg = err_msgs&.join("\n") 
      end
    end
    if err_msg
      respond_to do |format|
        format.html { redirect_to(action: 'new', notice: err_msg) }
        format.json { render json: { error: err_msg }, status: :unprocessable_entity }
      end
    end
  end
end
