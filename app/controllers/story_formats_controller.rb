class StoryFormatsController < ApplicationController
  before_action :set_story_format, only: [:show, :edit, :update, :destroy]

  # GET /story_formats
  # GET /story_formats.json
  def index
    @story_formats = StoryFormat.all
  end

  # GET /story_formats/1
  # GET /story_formats/1.json
  def show
  end

  # GET /story_formats/new
  def new
    @story_format = StoryFormat.new
  end

  # GET /story_formats/1/edit
  def edit
  end

  # POST /story_formats
  # POST /story_formats.json
  def create
    @story_format = StoryFormat.new(story_format_params)

    respond_to do |format|
      if @story_format.save
        format.html { redirect_to @story_format, notice: 'Story format was successfully created.' }
        format.json { render :show, status: :created, location: @story_format }
      else
        format.html { render :new }
        format.json { render json: @story_format.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /story_formats/1
  # PATCH/PUT /story_formats/1.json
  def update
    respond_to do |format|
      if @story_format.update(story_format_params)
        format.html { redirect_to @story_format, notice: 'Story format was successfully updated.' }
        format.json { render :show, status: :ok, location: @story_format }
      else
        format.html { render :edit }
        format.json { render json: @story_format.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /story_formats/1
  # DELETE /story_formats/1.json
  def destroy
    @story_format.destroy
    respond_to do |format|
      format.html { redirect_to story_formats_url, notice: 'Story format was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_story_format
      @story_format = StoryFormat.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def story_format_params
      params.require(:story_format).permit(:name, :author, :header, :footer)
    end
end
