require 'yaml'
require 'erb'
require 'dox'

class WordTemplateMaker

  DOTX = File.dirname(__FILE__) + '/../templates/scr-word-template.dotx'
  DEFAULT_CHAR = 'DefaultParagraphFont'
  NEW_STYLE_CHAR = ERB.new '<w:style w:type="character" w:customStyle="1" w:styleId="<%= name %>"><w:name w:val="<%= name %>"/><w:basedOn w:val="<%= DEFAULT_CHAR %>"/><w:rsid w:val="004A770A"/><w:rPr><w:color w:val="8B008B"/></w:rPr></w:style>'

  DEFAULT_PAR = 'pf'
  NEW_STYLE_PAR = ERB.new '<w:style w:type="paragraph" w:customStyle="1" w:styleId="<%= name %>"><w:name w:val="<%= name %>"/><w:basedOn w:val="<%= DEFAULT_PAR %>"/><w:qFormat/><w:rsid w:val="004A770A"/><w:rPr></w:rPr></w:style>'

  attr_reader :list, :type, :dotx, :elements
  attr_reader :document, :styles, :styles_with_effects

  def initialize type, list
    @list = list
    @type = type
    @elements = list.keys.map{ |k| list[k].keys }.flatten.sort
    @dotx = Dox.new(DOTX)
  end

  def run
    adjust_styles
    @dotx.rezip
  end

  def adjust_styles
    remove_old_styles
    add_new_styles
  end

  def add_new_styles
    missing = elements - @dotx.style_name_to_id.keys
    missing.each do |st_name|
      next if media?(st_name)
      template = paragraph?(st_name) ? NEW_STYLE_PAR : NEW_STYLE_CHAR
      add_style_el(template, st_name)
      say_added(st_name)
    end
  end

  # will be deprecated once media styles are integrated into the workflow
  def media?(st)
    return true if st == 'med'
    data = list[:paragraph_styles][st]
    return false unless data
    data[:group_name] == 'media'
  end

  def add_style_el(template, name)
    @dotx.styles.root.add_child(template.result(binding))
  end

  def paragraph?(name)
    !!@list[:paragraph_styles][name]
  end

  def remove_old_styles
    @dotx.styles.style_set.each do |st|
      remove(st) if old_scml(st)
    end
  end

  def remove(st)
    st.unlink
      say_deleted(st.name)
  end

  def old_scml(st)
    !!st.name[/^[a-z0-9\-]+$/] and !elements.include?(st.name)
  end

  def say_deleted(name)
    puts "deleted #{name}..."
  end

  def say_added(name)
    puts "added #{name}..."
  end
end
