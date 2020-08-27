#class NilClass
#  def empty?
#    true
#  end
#end

require 'active_support/core_ext/object/blank.rb'

class HtmlToTwine
  def initialize()
    @passage_name = nil     # Name of passage we are currently in the middle of reading
    @passage_positions = {} # stored values from previously created passages to reuse
    @canvas_min = 100       # x and y value of first new position created
    @canvas_max = 1500      # when x > canvas_max, wrap position to next row (x=canvas_min, y+=canvas_incremen)
    @canvas_increment = 150 # space to leave between new positions
    @adjust_x = 0           # x distance to shift existing nodes from their old positions
    @adjust_y = 0           # y distance to shift existing nodes from their old positions

    @next_passage_id = 1    # next passage created will get this id
    @passage_count = 0      # number of passages converted during current export operating

    @px = @canvas_min       # x, y position of next passage's icon in the Twine passage display
    @py = @canvas_min       # 
    @stop_chomp = 0         # greater than zero indicates that we should not chomp line endings
  end

  def export(story_name:, 
             input_filename:, 
             input_css_filename:, 
             output_filename:, 
             existing_positions_filename: nil, 
             ifid: "")
    read_positions(existing_positions_filename)
    header_line_count = 0
    body_line_count = 0

    File.open(input_filename) do |infile|
      if File.exists? output_filename
        File.delete output_filename 
      end
      File.open(output_filename, "w") do |outfile|
        write_twine_header(story_name:story_name, outfile:outfile, input_css_filename:input_css_filename, ifid:ifid)
        found_body = false
        while line = infile.gets
          line.chomp! if @stop_chomp == 0
          if !found_body 
            found_body = line.match('id="start"')
            if found_body
              puts "skipped " + header_line_count.to_s + " header lines"
            else
              header_line_count += 1
            end
          end
          if found_body
            line = convert_links(line)
            line = convert_tags(line)
            line = escape_tags(line)
            line = tag_start_of_passage(line)
            line = tag_end_of_passage(line)
            outfile.print line
            body_line_count += 1
          end
        end
      end
    end
    puts "Converted " + @passage_count.to_s + " passages"
    puts "wrote " + body_line_count.to_s + " lines"
    puts "to " + output_filename
  end

  def read_positions(positions_filename)
    # Read the positions of the passage nodes from an existing Twine story into @passage_positions
    if File.exists? positions_filename
      File.open(positions_filename) do |file|
        puts "Reading positions from existing file: " + positions_filename
        while line = file.gets
          if line.match /<tw-passagedata pid="[0-9]+" name="([^"]+)"/
            old_passage_name = $1
            if line.match /( size="[0-9.]+,[0-9.]+")/
              icon_size = $1
            else
              icon_size = ''
            end
            # If we don't need to adjust the position, just remember the whole attribute as string
            if @adjust_x == 0 && @adjust_y == 0
              if line.match /(position="[0-9.]+,[0-9.]+")/
                @passage_positions[old_passage_name] = $1 + icon_size
              end
            else # We need to tease apart and adjust the x and y values
              if line.match /position="([0-9.]+),([0-9.]+)"/
                x = Integer(Float($1)) + @adjust_x
                y = Integer(Float($2)) + @adjust_y
                @passage_positions[old_passage_name] = 'position="' + x.to_s + ',' + y.to_s + '"' + icon_size
              end
            end
          end
        end
        puts "Read " + @passage_positions.count.to_s + " existing positions."
        # If we already have passages with positions, put new ones farther down and offset
        if @passage_positions.count > 0
          @canvas_min += rand(40..70) # offset new passages from original grid
          @px = @canvas_min
          @py = @canvas_min + @canvas_max / 2 
        end
      end
    else
      if !positions_filename.blank?
        puts "Positions file not found: " + positions_filename
      end
    end
  end

  def convert_links(line)
    # Link *to* the top questions topic differently so the many links don't clutter the Twine diagram:
    # (link-goto: "text to show", "passage-name") to omit arrow on diagram in Twine editor
    #line.gsub!(%r{<a href="#topq">(.+?)</a>}, '(link-goto: &quot;\1&quot;, &quot;topq&quot;)')
    # For now we just remove all these links, since the above was not working
    line.gsub!(%r{<li><a href="#topq">.+?</a>}, '') # get rid of the link and preceding <li> tag if it is there
    line.gsub!(%r{<a href="#topq">.+?</a>}, '')     # or just get rid of the link

    # Link *from* some topics differently so the many links don't clutter the Twine diagram:      
    if @passage_name && @passage_name.match(/topq|realscience/)
      line.gsub!(%r{<a href="#([^"]+)">(.+?)</a>}, '\2') # '(link-goto: &quot;\2&quot;, &quot;\1&quot;)')
    else
      # Most links use the default link syntax, converting HTML like this:
      # <a href="#startingpoints">Okay, let's get started!</a>
      # into Twine like this:
      # [[Okay, let's get started!->startingpoints]]
      # This works if there are no tags in the link text:
      #line.gsub!(%r{<a href="#([^"]+)">(.+?)</a>}, '[[\2-&gt;\1]]')
      # This also moves any HTML tags (\2 and \4) from inside the href to outside the Twine link
      line.gsub!(%r{<a href="#([^"]+)">(<[^/<>]+>)*(.+?)(</[^/<>]+>)*</a>}, '\2[[\3-&gt;\1]]\4')
    end
    line
  end

  def convert_tags(line)
    line.gsub!('<br>', "\n")
    #line.gsub!('<p align=right>', '==>')
    line.gsub!(/<p( [^>]*)*>/, "\n\n")
    line.gsub!('</p>', '')
    line.gsub!(%r{(<li>.*)}, "\n" + '\1</li>') # add newline and close li tags
    #if line.gsub!('<li>', '* ')
    #  line = "\n" + line + "\n"
    #end
    #line.gsub!(%r{<ul[^>]*>}, '<br>')
    line.gsub!('<ul>', "\n<ul>")
    line.gsub!('</ul>', "\n</ul>\n")
    #line.gsub!("<em>", "//")
    #line.gsub!("</em>", "//")
    #line.gsub!("<strong>", "''")
    #line.gsub!("</strong>", "''")
    line
  end

  def escape_tags(line)
    # Escape some tags so they survive conversion
    keep_tags = %w( abbr div em img pre q span strong s table td th tr li ul u )
    keep_tags.each { |tag|
      if line.gsub!(%r{<(#{tag}( [^>]*)*)>}, '&lt;\1&gt;')
        @stop_chomp += 1 if tag == "pre"
      end
      if line.gsub!("</#{tag}>", "&lt;/#{tag}&gt;")
        @stop_chomp -= 1 if tag == "pre"
      end
      if line.match(%r{<#{tag}})
        puts "tried to escape <" + tag + "> but did not find end: " + line
      end
    }
    line
  end

  def next_position
    #position = 'position="' + rand(@canvas_max).to_s + ',' + rand(@canvas_max).to_s
    'position="' + @px.to_s + ',' + @py.to_s + '"'
  end

  def tag_start_of_passage(line)
    # Convert HTML like this:
    # <article><h2 id="start">Display Title</h2>
    # into Twine like this:
    # <tw-passagedata pid="1" name="start" tags="" position="405,223">\n!!Display Title

    if line.gsub!(%r{<h([1-9]) id="([^"]+)"[^>]*>([^<]+)</h.>}, 
                  '<tw-passagedata pid="' + @next_passage_id.to_s + '" name="\2" tags="" ' + next_position + ">\n" + '&lt;h\1&gt;\3&lt;/h\1&gt;' + "\n" )
      if @passage_name
        puts "Inserting end of passage: " + @passage_name + " before " + $2
        line = "</tw-passagedata>\n" + line
      end
      @passage_name = $2
      @next_passage_id += 1
      @passage_count += 1

      old_pos = @passage_positions[@passage_name]
      if old_pos
        line.gsub!(next_position, old_pos)
      else
        if @passage_positions.count > 0
          puts "New passage: " + @passage_name + ': ' + $3 + ' at ' + next_position
        end
        @px += @canvas_increment
        if @px > @canvas_max
          @px = @canvas_min
          @py += @canvas_increment
        end
      end
    end
    line
  end

  def tag_end_of_passage(line)
    # discard <article> tags, not currently using them to find start/end of passage
    line.gsub!(%r{<article[^>]*>}, '')
    line.gsub!('</article>', '')

    # Passages end with <hr> in HTML, convert to </tw-passagedata>
    if line.gsub!(%r{<hr[^>]*>}, '</tw-passagedata>')
      @passage_name = nil
    end
    line
  end

  def write_twine_header(story_name:, outfile:, input_css_filename: nil, ifid: "")
    outfile.print '<tw-storydata name="' + story_name + '" startnode="1" creator="Twine" creator-version="2.0.11" ifid="'
    outfile.puts ifid + '" format="SugarCube" options="" hidden>'
    outfile.print '<style role="stylesheet" id="twine-user-stylesheet" type="text/twine-css">'
    if File.exists? input_css_filename
      outfile.print File.read(input_css_filename)
    end
    outfile.puts '</style>'
    outfile.puts '<script role="script" id="twine-user-script" type="text/twine-javascript"></script>'
  end

end

date_string = Time.now.strftime("%Y-%m-%d_at_%H-%M-%S")
converter = HtmlToTwine.new()
converter.export(
  story_name: "Imported " + date_string,
  input_filename: "C:/Users/Mark/Documents/Writing/Treemates/Introduction.html",
  input_css_filename: "C:/Users/Mark/Documents/Writing/Treemates/twine.css",
  output_filename: "C:/Users/Mark/Documents/Twine/Import-Export/exported_" + date_string + ".html",
  existing_positions_filename: "C:/Users/Mark/Documents/Twine/Import-Export/Imported 2020-07-28_at_10-35-34.html",
  ifid: "5AAD4F80-2BBB-4EAE-B4A5-63F88CF83E2B")

# load '/c/dev/ruby/twine/html_to_twine.rb'

