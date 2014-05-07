class SwimListMaker

  attr_reader :list, :types
  TEMPLATE =  ERB.new( File.read(File.dirname(__FILE__) + '/../templates/scml-tag-list.swim.erb') )

  def initialize type, list
    @list = list.keys.inject({}){ |hsh, k| hsh.merge!(list[k]); hsh }
    @types = []
  end

  def run
    make_table_instance_vars
    TEMPLATE.result(binding)
  end
    
  def make_table_instance_vars
    organize_into_learning_lists
    sort_lists
    format_into_tables
  end
    
  def organize_into_learning_lists
    list.each do |el, vals|
      next unless vals[:learning_category]
      cate = constantize( vals[:learning_category] )
      if types.include? cate
        instance_variable_get('@' + cate)[el] = vals
      else
        types << cate
        generate_instance_val cate
        instance_variable_get('@' + cate)[el] = vals
      end
    end
  end

  def generate_instance_val cate
    instance_variable_set("@#{cate}", {}) 
    self.class.send(:attr_accessor, "#{cate}")
  end
    
  def sort_lists # keeping this separate since it will be a more advanced method eventually
    types.each do |type|
      sorted = instance_variable_get('@' + type).sort_by{ |k,v| k }
      instance_variable_set('@' + type, sorted) 
    end
  end
    
  def format_into_tables
    types.each do |type|
      list = instance_variable_get('@' + type)
      formatted_list = iterate_and_format_list( list )
      instance_variable_set('@' + type, formatted_list) 
    end
  end

  # Definition | Tag | Revision | Reference | Shortcut
  def iterate_and_format_list list
    list.map{ |el, vals|
      defin = vals[:name] || ''
      tag = make_tag(el, vals)    
      rev = vals[:date] || ''
      ref = ''
      shortcut = vals[:shortcut] || ''
      "#{defin} | #{tag} | #{rev} | #{ref} | #{shortcut} "
    }.join("\n")
  end

  def make_tag el, vals
    return "`#{el}`" unless vals[:tip]
    return "{~tt:`#{el}` #{vals[:tip]}"
  end

  def constantize string
    string.downcase.gsub(/[ \/\-]/,'_').gsub(/[^a-z_]/, '')
  end

end
