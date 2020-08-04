class PassagesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_passage, only: [:show, :edit, :update, :destroy]
  before_action :set_current_story

  # GET /passages
  # GET /passages.json
  def index
    if params[:filter] == 'mine'
      @passages = Passage.where(user_id: current_user.id)
    else
      @passages = Passage.all
    end
  end

  # GET /passages/1
  # GET /passages/1.json
  def show
  end

  # GET /passages/new
  def new
    @passage = Passage.new
    @passage.user = current_user
  end

  # GET /passages/1/edit
  def edit
  end

  # POST /passages
  # POST /passages.json
  def create
    @passage = Passage.new(passage_params)
    @passage.user = current_user

    respond_to do |format|
      if @passage.save
        format.html { redirect_to @passage, notice: 'Passage was successfully created.' }
        format.json { render :show, status: :created, location: @passage }
      else
        format.html { render :new }
        format.json { render json: @passage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /passages/1
  # PATCH/PUT /passages/1.json
  def update
    respond_to do |format|
      #if @passage.user.id == current_user.id
        if @passage.update(passage_params)
          format.html { redirect_to @passage, notice: 'Passage was successfully updated.' }
          format.json { render :show, status: :ok, location: @passage }
        else
          format.html { render :edit }
          format.json { render json: @passage.errors, status: :unprocessable_entity }
        end
      #else
      #  format.html { redirect_to @passage, notice: 'Cannot updated another user's passage.' }
      #end
    end
  end

  # DELETE /passages/1
  # DELETE /passages/1.json
  def destroy
    @passage.destroy
    respond_to do |format|
      format.html { redirect_to passages_url, notice: 'Passage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_current_story
      @current_story = Story.find_by(id: session[:story_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_passage
      @passage = Passage.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def passage_params
      params.require(:passage).permit(:title, :body)
    end
end
