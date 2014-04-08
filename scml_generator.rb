require 'yaml'
require 'erb'

class DTDMaker

  attr_reader :list, :output, :type
  BREADTH = 60
  DELIMITER = '=' * BREADTH
  TAB = '  '

  EL_TEMPLATE = ERB.new """
<%= TAB %><!ELEMENT <%= name %> <%= children(category, info) %> >
<%= TAB %><!ATTLIST <%= name %>
<%= TAB %><%= TAB %>%coreattrs;<% if info[:attrs]; info[attrs].each do |name, val, req| %>
<%= TAB %><%= TAB %><%= name %><%= TAB %><%= val %><%= TAB %><%= req %><% end end%>
<%= TAB %>>"""
  
  CORE_ATTRS = "#{TAB}<!ENTITY % coreattrs
#{TAB}#{TAB}\"id        ID      #IMPLIED
#{TAB}#{TAB}type      CDATA   #IMPLIED
#{TAB}#{TAB}semantic  CDATA   #IMPLIED\"
#{TAB}>"

  def initialize type, list
    @list = list
    @type = type
    @output = ''
  end

  def run
    entity_declarations
    iterate_categories
    output
  end

  def entity_declarations
    @output += header_and_core_attrs + "\n"
    list.each do |category, els|
      next unless children_types[type].include? category
      @output += entity(category, els.keys)
    end
  end

  def entity category, el_names
    "\n\n#{TAB}<!ENTITY % " + category.to_s + "\n#{TAB}\"" + el_names.join("\n#{TAB}\| ") + "\">\n\n"
  end

  def header_and_core_attrs
    header = DTDCategoryHeader.new(:entity_declarations).category_header
    [header, CORE_ATTRS].join("\n\n") 
  end

  def iterate_categories
    list.each do |category, els|
      header = DTDCategoryHeader.new(category).category_header
      declarations = els.map{ |name, info|
        attrs = "#{type}_attrs".to_sym
        EL_TEMPLATE.result(binding)
      }
      section = declarations.unshift(header).join("\n")
      @output += section + "\n\n"
    end
  end

  def children_types
    {
      'scml' => {
        :block_styles => ['%block_styles;', '%paragraph_styles;'],
        :paragraph_styles => ['#PCDATA', '%character_styles;'], 
        :character_styles => ['#PCDATA', '%character_styles;']
      },
      'sam' => {
        :block_styles => ['%block_styles;', '%paragraph_styles;'],
        :paragraph_styles => ['#PCDATA', '%character_styles;'],
        :character_styles => ['#PCDATA']
      }
    }
  end

  def children category, info
    contents = "#{type}_specialized_contents".to_sym
    return info[contents] if info[contents]
    kids = children_types[type][category]
    return '( ' + kids.join(' | ') + ' )*' 
  end

  class DTDCategoryHeader

    attr_reader :category

    def initialize category
      @category = category
    end

    def category_header
      head = cat_head(category)
      [delimiter, header_line(head), delimiter].join("\n")
    end

    def header_line head
      length = head.length
      sides = (BREADTH - length) / 2
      back_length = length.odd? ? sides + 1 : sides
      '<!-- ' + spaces(sides) + head + spaces(back_length) + ' -->'
    end

    def spaces num
      ' ' * num
    end

    def delimiter
      '<!-- ' + (DELIMITER) + ' -->'
    end

    def cat_head category
      cate = category.to_s
      cate.gsub!(/s$/, '') if cate.match(/root/i)
      cate.split(/_/).map{ |x|
        x.capitalize
      }.join(' ')
    end

  end

end

class ScmlListKnowledge

  SCML_YAML = YAML.load( File.read("elements.yml") )
  RUNNER_KNOWLEDGE = YAML.load( File.read("list_types.yml") )

  def initialize type
    @type = type
  end

  def generate_output
    run_type = RUNNER_KNOWLEDGE[ @type ]
    klass = Module.const_get( run_type[:runner] )
    trimmed_yaml = cleanse_list(SCML_YAML, run_type)
    output = klass.new(run_type[:var_name], trimmed_yaml).run
    File.open( run_type[:name], 'w' ).write output
  end

  def cleanse_list yaml, run_type
    removers = run_type[:exclude_for]
    yaml.each do |category, els|
      yaml.delete(category) unless run_type[:categories].include? category.to_s
      els.each do |el, el_info|
        els.delete(el) if removable?(el_info, removers)
      end
    end
    yaml
  end 

  def removable? el_info, removers
    removers.include? el_info[:for]
  end

end

ScmlListKnowledge.new(ARGV[0]).generate_output
