# <a href="#startingpoints">Okay, let's get started!</a>
# [[Okay, let's get started!->startingpoints]]

# <article><h1 id="start">Start</h1>
# <tw-passagedata pid="1" name="Start" tags="" position="405,223">
date_string = Time.now.strftime("%Y-%m-%d_at_%H-%M-%S")
story_name = "Imported " + date_string
input_filename = "C:/Users/Mark/Documents/Writing/Treemates/Introduction.html"
output_filename = "C:/Users/Mark/Documents/Twine/Import-Export/export_" + date_string + ".html"
positions_filename = "C:/Users/Mark/Documents/Twine/Import-Export/Imported 2020-07-27_at_18-04-17.html"

passage_positions = {}
adjust_x = 0 # 200
adjust_y = 0 # 200

if File.exists? positions_filename
  File.open(positions_filename) do |file|
    puts "Reading positions from existing file: " + positions_filename
    while line = file.gets
      if line.match /<tw-passagedata pid="[0-9]+" name="([^"]+)"/
        passage_name = $1
        if line.match /( size="[0-9.]+,[0-9.]+")/
          icon_size = $1
        else
          icon_size = ''
        end
        # If we don't need to adjust the position, just remember the whole attribute as string
        if adjust_x == 0 && adjust_y == 0
          if line.match /(position="[0-9.]+,[0-9.]+")/
            passage_positions[passage_name] = $1 + icon_size
          end
        else # We need to tease apart and adjust the x and y values
          if line.match /position="([0-9.]+),([0-9.]+)"/
            x = Integer(Float($1)) + adjust_x
            y = Integer(Float($2)) + adjust_y
            passage_positions[passage_name] = 'position="' + x.to_s + ',' + y.to_s + '"' + icon_size
          end
        end
      end
    end
    puts "Read " + passage_positions.count.to_s + " existing positions."
  end
end

passage_id = 1
canvas_min = 100
canvas_max = 1500
canvas_increment = 150
passage_count = 0

# If we already have passages with positions, put new ones farther down
if passage_positions.count > 0
  py = canvas_max / 2
  canvas_min += rand(40..70) # offset new passages from original grid
else
  py = canvas_min
end
px = canvas_min

#position = 'position="' + rand(canvas_max).to_s + ',' + rand(canvas_max).to_s
position = 'position="' + px.to_s + ',' + py.to_s + '"'
passage_name = nil

if File.exists? output_filename
  File.delete output_filename
end

File.open(output_filename, "w") do |outfile|
  outfile.puts '<tw-storydata name="' + story_name + '" startnode="1" creator="Twine" creator-version="2.0.11" ifid="5AAD4F80-2BBB-4EAE-B4A5-63F88CF83E2B" format="SugarCube" options="" hidden>'
  outfile.puts '<style role="stylesheet" id="twine-user-stylesheet" type="text/twine-css"></style>'
  outfile.puts '<script role="script" id="twine-user-script" type="text/twine-javascript"></script>'

  File.open(input_filename) do |infile|
    while line = infile.gets
      line.gsub!('<p align=right>', '==>')
      line.gsub!(/<p [^>]+>/, "\n")
      line.gsub!('<p>', "\n") # '<p></p>')
      line.gsub!('</p>', '')
      line.gsub!('<li>', '* ') # line.gsub!(%r{(<li>.*)}, '\1</li>') #Instead of closing li, we now replace it
      line.gsub!(%r{<ul[^>]*>}, '')
      line.gsub!('</ul>', '')
      line.gsub!("<em>", "//")
      line.gsub!("</em>", "//")
      line.gsub!("<strong>", "''")
      line.gsub!("</strong>", "''")
      line.gsub!(%r{<article[^>]*>}, '')
      line.gsub!('</article>', '')
      if line.gsub!(%r{<hr[^>]*>}, '</tw-passagedata>')
        passage_name = nil
      end

      # Escape some tags so they survive conversion
      line.gsub!(%r{<(img [^>]*)>}, '&lt;\1&gt;')
      line.gsub!(%r{<(q[^>]*)>}, '&lt;\1&gt;')
      line.gsub!('</q>', '&lt;/q&gt;')

      # Link *to* some topics differently so the many links don't clutter the Twine diagram:
      # (link-goto: "text to show", "passage-name") to omit arrow on diagram in Twine editor
      line.gsub!(%r{<a href="#(topq|realscience)">(.+?)</a>}, '') # '(link-goto: &quot;\2&quot;, &quot;\1&quot;)')

      # Link *from* some topics differently so the many links don't clutter the Twine diagram:      
      if passage_name
        if passage_name.match /topq|realscience/
          line.gsub!(%r{<a href="#([^"]+)">(.+?)</a>}, '\2') # '(link-goto: &quot;\2&quot;, &quot;\1&quot;)')
        else
          # Most links use the default link syntax
          line.gsub!(%r{<a href="#([^"]+)">(.+?)</a>}, '[[\2-&gt;\1]]')
        end
      end

      # Tag the start of a passage
      if line.gsub!(%r{<h([1-9]) id="([^"]+)"[^>]*>([^<]+)</h.>}, 
                    '<tw-passagedata pid="' + passage_id.to_s + '" name="\2" tags="" ' + position + ">\n" + '<h\1>\3' )
        if passage_name
          puts "Inserting end of passage: " + passage_name + " before " + $2
          line = "</tw-passagedata>\n" + line
        end
        passage_name = $2
        passage_id += 1
        passage_count += 1

        old_pos = passage_positions[passage_name]
        if old_pos
          line.gsub!(position, old_pos)
        else
          puts "New passage: " + passage_name + ': ' + $3 + ' at ' + position if passage_positions.count > 0
          px += canvas_increment
          if px > canvas_max
            px = canvas_min
            py += canvas_increment
          end
          position = 'position="' + px.to_s + ',' + py.to_s + '"'
        end
      end
      line.gsub!('<h1>', '!')
      line.gsub!('<h2>', '!!')
      outfile.puts line
    end
  end
  puts "Converted " + passage_count.to_s + " passages, wrote " + output_filename
end
#load '../../twine/convert_html_to_sugarcube.rb'
#load '/c/dev/ruby/twine/convert_html_to_sugarcube.rb'
