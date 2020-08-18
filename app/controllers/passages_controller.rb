class PassagesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_passage, only: [:show, :edit, :update, :destroy]
  before_action :set_current_story, only: [:index, :new, :create]
  before_action :new_passage, only: [:new, :create]

  # GET /passages
  # GET /passages.json
  def index
    if params[:filter] == 'mine'
      @passages = Passage.where(user_id: current_user.id)
      @header_prefix = 'My '
    else
      @passages = Passage.all
      @header_prefix = 'All '
    end
  end

  # GET /passages/1
  # GET /passages/1.json
  def show
  end

  # GET /passages/new
  def new
  end

  # GET /passages/1/edit
  def edit
  end

  # POST /passages
  # POST /passages.json
  def create
    respond_to do |format|
      if @passage.save
        format.html { redirect_to @passage, notice: 'Passage was successfully created.' }
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
    success_msg = 'Passage was successfully updated.'
    if @passage.user != current_user
      @new_passage = @passage.copy
      @new_passage.user = current_user
      @passage = @new_passage
      success_msg = 'New copy of passage was successfully updated.'
    end
    respond_to do |format|
      if @passage.update(passage_params)
        format.html { redirect_to @passage, notice: success_msg }
        # format.json { render :show, status: :ok, location: @passage }
      else
        format.html { render :edit, notice: 'Update unsuccessful.' }
        # format.json { render json: @passage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /passages/1
  # DELETE /passages/1.json
  def destroy
    if @passage&.user == current_user
      @passage.destroy
      respond_to do |format|
        format.html { redirect_to passages_url, notice: 'Passage was deleted.' }
        # format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to passages_url, notice: 'Only the passage owner may delete it.' }
        # format.json { head :no_content }
      end
    end
  end

  private
    def set_current_story
      @current_story = Story.find_by(id: session[:story_id])
    end

    def set_passage
      @passage = Passage.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def passage_params
      params.require(:passage).permit(:name, :body, :uuid)
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
