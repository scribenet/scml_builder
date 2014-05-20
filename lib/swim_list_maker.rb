class SwimListMaker

  attr_reader :list, :types
  TEMPLATE =  ERB.new( File.read(File.dirname(__FILE__) + '/../templates/scml-tag-list.swim.erb') )
  SPACING = YAML.load( File.read(File.dirname(__FILE__) + '/../spacing_profiles.yml') )

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
      cate = get_category(vals)
      vals = drop_in_spacing_category(vals) if vals[:spacing_profile]
      if types.include? cate
        instance_variable_get('@' + cate)[el] = vals
      else
        types << cate
        generate_instance_val cate
        instance_variable_get('@' + cate)[el] = vals
      end
    end
  end
      
  def drop_in_spacing_category(vals)
    prof = vals[:spacing_profile]
    vals[:spacing_category] = SPACING[prof][:type]
    vals
  end

  def get_category vals
    if vals[:for] and vals[:for] == 'expanded'
      cate = constantize( vals[:learning_category] + '_expanded' )
    else
      cate = constantize( vals[:learning_category] )
    end
  end

  def generate_instance_val cate
    instance_variable_set("@#{cate}", {}) 
    self.class.send(:attr_accessor, "#{cate}")
  end
    
  def sort_lists # keeping this separate since it will be a more advanced method eventually
    types.each do |type|
      sorted = instance_variable_get('@' + type).sort_by{ |k,v| k }
      sorted = sort_by_scml_logic( sorted )
      sorted = pull_heads_to_top( sorted ) unless list_is_all_heads?(type)
      instance_variable_set('@' + type, sorted) 
    end
  end
      
  def list_is_all_heads?(type)
    %w(book chapter heads).any?{ |x| type.to_s.match(x) } 
  end
      
  def pull_heads_to_top sorted 
    heads = sorted.collect{ |item| item if item[1][:spacing_category] == :head }.compact
    %w(t h ah ahaft bh bhaft ch chaft dh dhaft 1h 2h 3h).reverse.each do |type|
      head_vars = heads.collect{ |head| head if head.first.match(/#{type}$/) }.compact
      next if head_vars.empty?
      head_vars.each do |head_var|
        ind = sorted.index(head_var)
        sorted.insert(0, sorted.delete_at(ind))
        heads.delete(head_var)
      end
    end
    sorted
  end

  def sort_by_scml_logic sorted
    sorted.each_with_index do |item, ind|
      item_name = item.first
      %w(f l s o).reverse.each do |spacer|
        variant = sorted.collect{ |name, info| [name, info] if name == item_name + spacer }.compact.first
        next if variant.nil?
        var_ind = sorted.index(variant)
        sorted.insert(ind + 1, sorted.delete_at( var_ind ) )
      end
    end
    sorted
  end
    
  def format_into_tables
    types.each do |type|
      list = instance_variable_get('@' + type)
      formatted_list = iterate_and_format_list( list )
      instance_variable_set('@' + type, formatted_list) 
    end
  end

  def iterate_and_format_list list
    list.map{ |el, vals|
      defin = vals[:name] || ''
      tag = make_tag(el, vals)    
      rev = vals[:date] || ''
      "#{tag} | #{defin} | #{rev} "
    }.join("\n")
  end

  def make_tag el, vals
    return "`#{el}`" unless vals[:tip]
    return "{~tt:`#{el}` #{vals[:tip]}}"
  end

  def constantize string
    string.downcase.gsub(/[ \/\-]/,'_').gsub(/[^a-z_]/, '')
  end

end
