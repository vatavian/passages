class StoryPassagesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_story_editor

  def create
    @story_passage = StoryPassage.new(story_passage_params)

    respond_to do |format|
      if @story_passage.save
        format.html { redirect_to @story, notice: 'Story was successfully created.' }
        format.json { render :show, status: :created, location: @story }
      else
        format.html { render :new }
        format.json { render json: @story.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @story_passage.update(story_passage_params)
        format.html { redirect_to @story, notice: 'Story was successfully updated.' }
        format.json { render :show, status: :ok, location: @story }
      else
        format.html { render :edit }
        format.json { render json: @story.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @story_passage.destroy
    respond_to do |format|
      format.html { redirect_to stories_url, notice: 'Passage was successfully removed from story.' }
      format.json { head :no_content }
    end
  end

  private
    def authorize_story_editor
      @story = Story.find(story_passage_params[:story_id])
      unless @story.user == current_user
        redirect_to passages_url, notice: 'Not owner of this story.'
      end
      @story_passage = StoryPassage.find_by(id: story_passage_params[:story_passage_id])
    end

    # Only allow a list of trusted parameters through.
    def story_passage_params
      # params.require(:story_passage).permit(:story_id, :passage_id, :sequence)
      params.permit(:story_id, :passage_id, :sequence)
    end
end
