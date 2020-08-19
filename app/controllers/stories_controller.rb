class StoriesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_story, only: [:show, :edit, :fork, :update, :destroy]
  before_action :authorize_story_editor, only: [:edit, :update, :destroy]
  before_action :new_story, only: [:new, :create]

  # GET /stories
  # GET /stories.json
  def index
    if params[:filter] == 'mine'
      @stories = Story.where(user_id: current_user.id)
      @section_title = 'My Stories'
    else
      @stories = Story.all
      @section_title = 'All Stories'
    end
  end

  # GET /stories/1
  # GET /stories/1.json
  def show
    @section_title = @story&.name
  end

  # GET /stories/new
  def new
    @section_title = 'New Story'
  end

  # GET /stories/1/edit
  def edit
    set_story_passages
    @section_title = 'Edit ' + @story&.name
  end

  def fork
    @new_story = @story.copy
    @new_story.user = current_user
    @new_story.name = "Copy of " + @story.user.email + "'s " + @new_story.name
    @story.story_passages.order('sequence asc').each do |old_story_passage|
      new_story_passage = StoryPassage.new
      new_story_passage.passage_id = old_story_passage.passage_id
      new_story_passage.sequence =   old_story_passage.sequence
      new_story_passage.tags =       old_story_passage.tags
      new_story_passage.position =   old_story_passage.position
      new_story_passage.size =       old_story_passage.size
      @new_story.story_passages << new_story_passage
    end
    @new_story.save
    redirect_to edit_story_path(@new_story), notice: 'Editing new copy of story.'
  end

  # POST /stories
  # POST /stories.json
  def create
    respond_to do |format|
      if @story.save
        set_session_story
        format.html { redirect_to @story, notice: 'Story was successfully created.' }
        format.json { head :no_content, status: :ok, location: @story }
      else
        format.html { render :new }
        format.json { head :no_content, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stories/1
  # PATCH/PUT /stories/1.json
  def update
    respond_to do |format|
      if @story.update(story_params)
        set_session_story

        format.html { redirect_to @story, notice: 'Story was successfully updated.' }
        format.json { head :no_content, status: :ok, location: @story }
      else
        format.html { render :edit, notice: 'Update unsuccessful.' }
        format.json { head :no_content, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stories/1
  # DELETE /stories/1.json
  def destroy
    session[:story_id] = nil
    session[:story_name] = nil
    @story.transaction do
      if params[:destroy_passages] == 'true'
        @story.update_attribute(:start_passage_id, nil)
        @story.passages.each do |passage|
          if passage.user == current_user && passage.stories.count == 1
            #passage.body.destroy
            passage.destroy
          end
        end
      end
      @story.destroy
    end
    respond_to do |format|
      format.html { redirect_to stories_url, notice: 'Story was deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def set_story
    @story = Story.find(params[:id])
    set_session_story
  end

  def authorize_story_editor
    if !current_user&.id || @story&.user_id != current_user.id
      respond_to do |format|
        format.html { redirect_to stories_url, notice: 'Only the story owner may do that.' }
        format.json { head :no_content }
      end
    end
  end

  def set_session_story
    # Don't have to be authenticated to get here, 
    # but if we are this story's user, store story ID in session.
    if current_user&.id && @story&.user&.id == current_user.id
      session[:story_id] = @story.id
      session[:story_name] = @story.name
    end
  end

  # Only allow a list of trusted parameters through.
  def story_params
    params.require(:story).permit(:name, :story_format_id, :ifid, :stylesheet, :script, :start_passage_id)
  end

  def set_story_passages
    @story_passages = @story.story_passages.order('sequence asc').includes(passage: :user)
  end

  def new_story
    if params[:action] == "new"
      @story = Story.new
    else
      @story = Story.new(story_params)
    end
    @story.user = current_user
    @story_passages = []
  end

end
