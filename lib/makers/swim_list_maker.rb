class SwimListMaker

  attr_reader :list, :types
  TEMPLATE =  ERB.new( File.read(File.dirname(__FILE__) + '/../templates/scml-tag-list.swim.erb') )
  SPACING = YAML.load( File.read(File.dirname(__FILE__) + '/../../spacing_profiles.yml') )
  BASE_STYLES = %w(bl bq bx cl ctoc dia ep ex in lt nl rp sb sl st toc ul wl)

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
      sorted = sort_by_weight(sorted, type) if sorted.first[1][:weight]
      instance_variable_set('@' + type, sorted)
    end
  end

  def sort_by_weight(list, type)
    weights = list.each_with_object({}) do |arr, weights|
      w = arr[1][:weight]
      if weights[w]
        weights[w] << arr
      else
        weights[w] = []
        weights[w] << arr
      end
    end
    weights.keys.sort.map { |num| weights[num].sort_by { |n, v| n } }.flatten.each_slice(2).to_a
  end

  def list_is_all_heads?(type)
    %w(book chapter heads).any?{ |x| type.to_s.match(x) }
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
    return "{~scml:#{el}}" unless vals[:tip]
    return "{~tt:{~scml:#{el}} #{vals[:tip]}}"
  end

  def constantize string
    string.downcase.gsub(/[ \/\-]/,'_').gsub(/[^a-z_]/, '')
  end
end
