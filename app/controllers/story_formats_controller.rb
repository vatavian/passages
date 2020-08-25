class StoryFormatsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_story_format, only: [:show, :edit, :update, :destroy]

  # GET /story_formats
  # GET /story_formats.json
  def index
    @story_formats = StoryFormat.all
    @section_title = 'Story Formats'
  end

  # GET /story_formats/1
  # GET /story_formats/1.json
  def show
    @section_title = @story_format.name + ' ' + @story_format.version
  end

  # GET /story_formats/new
  def new
    @story_format = StoryFormat.new
    @section_title = 'New Story Format'
  end

  # GET /story_formats/1/edit
  def edit
    @section_title = 'Edit ' + @story_format.name + ' ' + @story_format.version
  end

  # POST /story_formats
  # POST /story_formats.json
  def create
    @story_format = StoryFormat.new(story_format_params)
    upload = params[:story_format][:uploaded_story]
    if upload
      if upload.content_type.chomp != "text/html"
        redirect_to(action: 'new', notice: 'Upload must be text/html.')
        return
      end
      @story_format.header = upload.read.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
    end

    # If .header contains a story, remove the story and move the part after it into .footer
    story_start = @story_format.header.index("<tw-storydata ")
    if story_start
      story_end_tag = "</tw-storydata>"
      story_end = @story_format.header.index(story_end_tag, story_start)
      if story_end
        found_format = attr_value('format', @story_format.header, story_start)
        found_version = attr_value('format-version', @story_format.header, story_start)
        @story_format.name = found_format if found_format
        @story_format.version = found_version if found_version
        @story_format.footer = @story_format.header[story_end + story_end_tag.length..]
      end
      @story_format.header = @story_format.header[0..story_start-1]
    end

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
      format.html { redirect_to story_formats_url, notice: 'Story format was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    def set_story_format
      @story_format = StoryFormat.find(params[:id])
    end

    def story_format_params
      params.require(:story_format).permit(:name, :version, :author, :header, :footer)
    end

    def attr_value(attr_name, str, start)
      search_for = ' ' + attr_name + '="'
      attr_start = str.index(search_for, start)
      if attr_start
        attr_end = str.index('"', attr_start + search_for.length)
        if attr_end
          @story_format.header[attr_start + search_for.length..attr_end - 1]
        end
      end
    end        
end
