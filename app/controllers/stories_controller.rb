class StoriesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_story, only: [:show, :edit, :update, :destroy]

  # GET /stories
  # GET /stories.json
  def index
    if params[:filter] == 'mine'
      @stories = Story.where(user_id: current_user.id)
      @header_prefix = 'My '
    else
      @stories = Story.all
      @header_prefix = 'All '
    end
  end

  # GET /stories/1
  # GET /stories/1.json
  def show
  end

  # GET /stories/new
  def new
    @story = Story.new
    @story.user = current_user
  end

  # GET /stories/1/edit
  def edit
    set_story_passages
  end

  # POST /stories
  # POST /stories.json
  def create
    @story = Story.new(story_params)
    @story.user = current_user

    respond_to do |format|
      if @story.save
        format.html { redirect_to @story, notice: 'Story was successfully created.' }
        #format.json { render :show, status: :created, location: @story }
      else
        format.html { render :new }
        #format.json { render json: @story.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stories/1
  # PATCH/PUT /stories/1.json
  def update
    respond_to do |format|
      if @story.update(story_params)
        session[:story_id] = @story.id
        session[:story_name] = @story.name

        format.html { redirect_to @story, notice: 'Story was successfully updated.' }
        #format.json { render :show, status: :ok, location: @story }
      else
        format.html { render :edit }
        #format.json { render json: @story.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stories/1
  # DELETE /stories/1.json
  def destroy
    if @story&.user == current_user
      session[:story_id] = nil
      session[:story_name] = nil
      #binding.pry
      @story.transaction do
        if params[:destroy_passages] == 'true'

          #> Passage.where(id: [110, 111])
          #> passage_ids = ActiveRecord::Base.connection.execute('select distinct record_id from action_text_rich_texts')
          #> passage_ids.map{|id| id unless Passage.find_by(id: id)}.compact

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
        # format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to stories_url, notice: 'Only the story owner may delete it.' }
        # format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_story
      @story = Story.find(params[:id])
      # Don't have to be authenticated to get here for show, 
      # but if we are this story's user, store story ID in session
      if current_user && current_user.id && @story&.user&.id == current_user.id
        session[:story_id] = @story.id
        session[:story_name] = @story.name
      end
    end

    # Only allow a list of trusted parameters through.
    def story_params
      params.require(:story).permit(:start_passage_id, :story_format_id, :name)
    end

    def set_story_passages
      @story_passages = @story.story_passages.includes(passage: :user)
    end
end
