require 'nokogiri'
require 'loofah'

# Use loofah to escape HTML tags that we don't want ActiveText to manage
#
#     raw_html = "<em>em is handled natively in AT</em> <table>but table is not</table>"
#     Loofah.fragment(unsafe_html).scrub!(EscapeAllButActiveText)
#     => "<em>em is handled natively in AT</em> &lt;table&gt;but table is not&lt;/table&gt;"
#
class EscapeAllButActiveText < Loofah::Scrubber
  ELEMENTS_UNESCAPED_IN_ACTIVETEXT = Set.new([ "del", "em", "pre", "strong" ])
  ELEMENTS_TO_KEEP_NEWLINES_IN = Set.new([ "pre", "code" ])

  def initialize
    @direction = :top_down
  end

  def scrub(node)
    case node.type
    when Nokogiri::XML::Node::ELEMENT_NODE
      if ELEMENTS_UNESCAPED_IN_ACTIVETEXT.include? node.name
        return CONTINUE
      end
    when Nokogiri::XML::Node::TEXT_NODE, Nokogiri::XML::Node::CDATA_SECTION_NODE
      return CONTINUE
    end
    new_text = node.to_s
    new_text.gsub!("\r", '')
    if !(ELEMENTS_TO_KEEP_NEWLINES_IN.include? node.name)
       new_text.gsub!("\n", ' ')
    end
    node.add_next_sibling Nokogiri::XML::Text.new(new_text, node.document)
    node.remove
    return STOP
  end
end

