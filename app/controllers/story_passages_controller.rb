class StoryPassagesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_story_editor

  def create
    @story_passage = StoryPassage.new(story_passage_params)

    respond_to do |format|
      if @story_passage.save
        format.html { redirect_to passages_path, notice: "Passage is now in story." }
        # format.json { render :show, status: :created, location: @story }
      else
        format.html { redirect_to passages_path, notice: 'Passage was not added to story.' }
        # format.json { render json: @story.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @story_passage.update(story_passage_params)
        format.html { redirect_to @story, notice: 'Story passage was successfully updated.' }
        # format.json { render :show, status: :ok, location: @story }
      else
        format.html { render :edit }
        # format.json { render json: @story.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @story_passage.destroy
    respond_to do |format|
      format.html { redirect_to stories_url, notice: 'Passage was removed from story.' }
      # format.json { head :no_content }
    end
  end

  private
    def authorize_story_editor
      if params[:id]
        @story_passage = StoryPassage.find_by(id: params[:id])
        @story = Story.find_by(id: @story_passage.story_id) if @story_passage
      end
      if !@story
        @story = Story.find_by(id: params[:story_id])
      end
      if !@story || !@story.user || @story.user != current_user
        redirect_to passages_url, notice: 'Not owner of this story.'
      else
        if !@story_passage && params[:story_id] && params[:passage_id]
          @story_passage = StoryPassage.find_by(story_id: params[:story_id],
                                              passage_id: params[:passage_id])
        end
      end
    end

    # Only allow a list of trusted parameters through.
    def story_passage_params
      if params[:action] == "create"
        params.require(:story_id)
        params.require(:passage_id)
        params.permit(:story_id, :passage_id, :sequence, :tags, :position, :size)
      else
        params.require(:story_passage).permit(:sequence, :tags, :position, :size)
      end
    end
end
