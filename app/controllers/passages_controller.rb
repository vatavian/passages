class PassagesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_passage, only: [:show, :edit, :fork, :update, :destroy]
  before_action :authorize_passage_editor, only: [:edit, :update, :destroy]
  before_action :set_current_story, only: [:index, :new, :create]
  before_action :set_current_story_passages, only: [:index]
  before_action :new_passage, only: [:new, :create]

  # GET /passages
  # GET /passages.json
  def index
    if params[:filter] == 'mine'
      @passages = Passage.where(user_id: current_user.id)
      @section_title = 'My Passages'
    elsif params[:filter] =~ /^user_(.+?)$/ && filter_user = User.find_by(id: $1)
      @passages = Passage.where(user_id: filter_user.id)
      @section_title = filter_user.email + "'s Passages"
    elsif params[:filter] =~ /^story_(.+?)$/ && filter_story = Story.find_by(id: $1)
      @passages = Passage.joins(:story_passages)
        .where("story_passages.story_id=?", filter_story.id).order("story_passages.sequence")
      @section_title = 'Passages in: ' + filter_story.name
    else
      @passages = Passage.all
      @section_title = 'All Passages'
    end
    @passages = @passages.includes(:user)
    @cols = {
      'n' => 'name',
      'c' => 'created_at',
      'u' => 'updated_at',
      'o' => 'users.email',
      's' => nil,
      'a' => nil,
      'e' => nil
    }
    if params[:sort]
      order = params[:sort][1] == 'd' ? ' desc' : ' asc'
      if sort_col = @cols[params[:sort][0]]
        @passages = @passages.order(sort_col + order)
      end
    end
  end

  # GET /passages/1
  # GET /passages/1.json
  def show
    @section_title = @passage&.name
  end

  # GET /passages/new
  def new
    @section_title = 'New Passage'
  end

  # GET /passages/1/edit
  def edit
    @section_title = 'Edit: ' + @passage&.name
  end

  def fork
    @new_passage = @passage.copy
    @new_passage.user = current_user
    @new_passage.name = "Copy of " + @passage.user.email + "'s " + @new_passage.name
    @new_passage.save
    redirect_to edit_passage_path(@new_passage), notice: 'Editing new copy of passage.'
  end

  # POST /passages
  # POST /passages.json
  def create
    respond_to do |format|
      if @passage.save
        format.html { redirect_to @passage, notice: 'Passage created.' }
        # format.json { render :show, status: :created, location: @passage }
      else
        format.html { render :new }
        # format.json { render json: @passage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /passages/1
  # PATCH/PUT /passages/1.json
  def update
    respond_to do |format|
      if @passage.update(passage_params)
        format.html { redirect_to @passage, notice: 'Passage updated.' }
        # format.json { render :show, status: :ok, location: @passage }
      else
        format.html { render :edit, notice: 'Update failed.' }
        # format.json { render json: @passage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /passages/1
  # DELETE /passages/1.json
  def destroy
    if @passage.destroy
      respond_to do |format|
        format.html { redirect_to passages_url, notice: 'Passage deleted.' }
        # format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to passages_url, notice: 'Unable to delete.' }
        # format.json { head :no_content }
      end
    end
  end

  private

  def set_current_story
    # Find the user's story they most recently visited. 
    # New passages are added to this story and passages in this story are displayed differently in index.
    @current_story = Story.find_by(id: session[:story_id])
  end

  def set_current_story_passages
    # Find the passages in @current_story so they can be displayed differently in index.
    if @current_story 
      short_story_name = @current_story.name
      if short_story_name.length > 15
        short_story_name = short_story_name[0..11] + '...'
      end
      @add_label = 'Add to ' + short_story_name
      @remove_label = 'Remove from ' + short_story_name
      @current_story_passages = {}
      StoryPassage.where(story_id: @current_story.id).each { |sp| @current_story_passages[sp.passage_id] = sp }
      if @current_story_passages.empty?
        @current_story_passages = nil
      end
    else
      @current_story_passages = nil
    end
  end

  def set_passage
    @passage = Passage.find(params[:id])
  end

  def authorize_passage_editor
    if !current_user&.id || @passage&.user_id != current_user.id
      respond_to do |format|
        format.html { redirect_to stories_url, notice: 'Only the passage owner may do that.' }
        format.json { head :no_content }
      end
    end
  end

  # Only allow a list of trusted parameters through.
  def passage_params
    params.require(:passage).permit(:name, :content, :uuid)
  end

  def new_passage
    if params[:action] == "new"
      @passage = Passage.new
    else
      @passage = Passage.new(passage_params)
    end
    @passage.user = current_user
    if @current_story
      @passage.stories << @current_story
    end
  end

end
