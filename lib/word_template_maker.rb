require 'yaml'
require 'erb'
require 'docx_tools'

class WordTemplateMaker

  DOTX = File.dirname(__FILE__) + '/../templates/scr-word-template.dotx'
  DEFAULT_CHAR = 'DefaultParagraphFont'
  NEW_STYLE_CHAR = ERB.new '<w:style w:type="character" w:customStyle="1" w:styleId="<%= name %>"><w:name w:val="<%= name %>"/><w:basedOn w:val="<%= DEFAULT_CHAR %>"/><w:rsid w:val="004A770A"/><w:rPr><w:color w:val="8B008B"/></w:rPr></w:style>'
  DOC_CHAR = ERB.new '<w:p w:rsidR="00996D58" w:rsidRPr="007127E2" w:rsidRDefault="00996D58" w:rsidP="00996D58"><w:pPr><w:pStyle w:val="psec"/><w:rPr><w:rStyle w:val="<%= name %>"/></w:rPr></w:pPr><w:r w:rsidRPr="007127E2"><w:rPr><w:rStyle w:val="<%= name %>"/></w:rPr><w:t><%= name %></w:t></w:r></w:p>'

  DEFAULT_PAR = 'pf'
  NEW_STYLE_PAR = ERB.new '<w:style w:type="paragraph" w:customStyle="1" w:styleId="<%= name %>"><w:name w:val="<%= name %>"/><w:basedOn w:val="<%= DEFAULT_PAR %>"/><w:qFormat/><w:rsid w:val="004A770A"/><w:rPr></w:rPr></w:style>'
  DOC_PAR = ERB.new '<w:p w:rsidR="00996D58" w:rsidRDefault="00996D58" w:rsidP="00996D58"><w:pPr><w:pStyle w:val="<%= name %>"/></w:pPr><w:r><w:t><%= name %></w:t></w:r></w:p>'

  CHAR_STYLE_HEADER = 'Character Styles:'
  
  attr_reader :list, :type, :dotx, :elements
  attr_reader :document, :styles, :styleswitheffects

  def initialize type, list
    @list = list
    @type = type
    @elements = list.keys.map{ |k| list[k].keys }.flatten.sort
    @dotx = DocxTools.new(DOTX) 
    @document = Nokogiri.XML dotx.document
    @styles = Nokogiri.XML dotx.styles
    @styleswitheffects = Nokogiri.XML dotx.styleswitheffects
  end

  def run
    adjust_templates
    cleanup_document
    reset_dotx
    @dotx.rezip
  end

  def cleanup_document
    document.css('w|p').map{ |x| x.remove if x.text.empty? }
  end
    
  def reset_dotx
    [:document, :styles, :styleswitheffects].each do |xml|
      new_xml = self.send(xml).serialize(:save_with => 0)
      setter = xml.to_s + '='
      dotx.send(setter, new_xml)
    end
  end
    
  def adjust_templates
    current_styles = (gather_existing_styles(styles) + gather_existing_styles(styleswitheffects)).uniq.sort
    trim_template(current_styles, styles)
    trim_template(current_styles, styleswitheffects)
    add_to_template(current_styles, styles)
    add_to_template(current_styles, styleswitheffects)
    trim_document(current_styles)
    add_to_document(current_styles)
  end

  def gather_existing_styles style_list
    style_list.css('w|name[w|val]').map{ |x| x['w:val'] }.reject{ |x| x.match(/^[0-9]|[A-Z]/) }
  end

  def trim_template current_styles, style_list
    (current_styles - elements).each do |bad_style|
      style_list.css("w|name[w|val=#{bad_style}").map{ |x| x.parent.remove }
    end
  end
    
  def add_to_template current_styles, style_list
    (elements - current_styles).each do |name|
      template = is_paragraph?(name) ? NEW_STYLE_PAR : NEW_STYLE_CHAR
      new_node = template.result(binding)
      style_list.root.add_child(new_node)
    end
  end

  def is_paragraph? style
    list[:paragraph_styles].keys.include? style
  end

  def trim_document(current_styles)
    (current_styles - elements).each do |bad_style|
      document.css("[w|val=#{bad_style}]").map{ |x| x.parent.parent.remove }
    end
  end

  def add_to_document current_styles
    new_styles = elements - current_styles
    paragraphs = new_styles.collect{ |x| x if is_paragraph?(x) }.compact
    characters = new_styles - paragraphs
    add_new_characters(characters)
    add_new_paragraphs(paragraphs)
  end

  def character_style_lines
    start = character_start
    size = document.root.css('w|p').size
    start_index = document.root.css('w|p').index(start) + 1
    range = document.root.css('w|p')[start_index .. size]
    names = range.map{ |x| x.at_css('w|rStyle').andand['w:val'] }
    hash = Hash[names.zip(range)]
    hash.delete(nil) if hash[nil]
    hash
  end

  def character_start
    start = document.css('w|p').collect{ |x| x if x.text.match(/#{CHAR_STYLE_HEADER}/) }.compact.first
    raise "Can't find specified character style list start." if start.nil?
    start
  end

  def add_new_characters(characters)
    char_lines_hsh = character_style_lines
    characters.each do |name|
      sib = find_closest_sibling(name, char_lines_hsh)
      node = DOC_CHAR.result(binding)
      sib.add_next_sibling(node)
    end 
  end
      
  def add_new_paragraphs(paragraphs)
    start = character_start
    paragraphs.each do |name|
      node = DOC_PAR.result(binding)
      start.add_previous_sibling(node)      
    end
  end

  def find_closest_sibling name, char_lines_hsh
    keys = char_lines_hsh.keys
    with_name = (keys << name).sort
    new_index = with_name.index(name)
    nearest_name = with_name[ new_index - 1 ]
    char_lines_hsh[ nearest_name ]
  end

end
