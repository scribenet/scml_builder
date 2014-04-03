require 'andand'
require 'erb'
require 'yaml'

class DTDMaker

  attr_reader :type, :template, :name, :structs, :pars, :chars

  EL_TEMPLATE = ERB.new """
<%= tab %><!ELEMENT <%= el[:name] %> ( <%= children %> )<%= modifier %> >
<%= tab %><!ATTLIST <%= el[:name] %>
<%= tab %><%= tab %>%coreattrs;<% if el[:attrs] and type == 'scml'
  el[:attrs].each do |name, val, req| %>
<%= tab %><%= tab %><%= name %><%= tab %><%= val %><%= tab %><%= req %><% end end%>
<%= tab %>>
  """

  ELEMENTS = YAML.load( File.read( File.dirname(__FILE__) + '/elements.yml') ) 

  SAM_TEMPLATE = ERB.new( File.read(File.dirname(__FILE__) + '/sam_dtd.erb') )
  SCML_TEMPLATE = ERB.new( File.read(File.dirname(__FILE__) + '/scml_dtd.erb') )
  SCML_BLOCK_EXTRAS = %w(table)
  SCML_NON_TEXT_INLINE = %w(a br img page)
  SCML_NON_TEXT_COMPACT = %w(hr)
  INLINE_EXTRAS = %w(img)

  def initialize type
    @type = type
    generate_settings type
    generate_element_lists
  end

  def generate_settings type
    @template = type == 'sam' ? SAM_TEMPLATE : SCML_TEMPLATE
    @name = type == 'sam' ? 'sam.dtd' : 'scml.dtd'
  end

  def generate_element_lists
    @structs = ELEMENTS[:structure_styles] 
    @pars = pertinent_elements(ELEMENTS[:paragraph_styles])
    @chars = pertinent_elements(ELEMENTS[:character_styles])
  end

  def pertinent_elements list
    list.each do |x|
      list.delete(x) if x[:for] and x[:for] != type
    end
    list
  end

  CHILDREN = {
    :structs => ['%block_level.group;', '%paragraph_level.group;'],
    :pars => ['%inline_level.group;'],
    :chars => ['%inline_level.group;']
  }

  TYPES = {
    :structs => 'block_level.group',
    :pars => 'paragraph_level.group',
    :chars => 'inline_level.group'
  }

  def element_list els
    opener = entity + TYPES[els]
    opener += els == :chars ? "\n#{tab}\"#PCDATA\n#{tab}\| " : "\n#{tab}\""
    list = generate_type_list(els)
    opener + list + '">'
  end
    
  def generate_type_list els
    list = send(els).map{ |x| x[:name] }
    if type == 'scml'
      list += SCML_NON_TEXT_INLINE if els == :chars and
      list += SCML_NON_TEXT_COMPACT if els == :pars
      list += SCML_BLOCK_EXTRAS if els == :structs
    end
    list += INLINE_EXTRAS if els == :chars
    pipe_joined(list.sort)
  end

  def pipe_joined list
    list.join("\n#{tab}\| ")
  end

  def element_declarations els
    children = CHILDREN[els].join(' | ')
    children = '#PCDATA' if els == :chars and type == 'sam'
    modifier = type == :structs ? '+' : '*'
    list = send(els)
    list.map{ |el| EL_TEMPLATE.result(binding) }.join
  end

  def dtd
    template.result(binding)
  end

# string data holders
  def entity
    '<!ENTITY % '
  end

  def tab
    '  '
  end

end

type = ARGV[0]

dtd_maker = DTDMaker.new(type)

File.open(dtd_maker.name, 'w').write dtd_maker.dtd 
