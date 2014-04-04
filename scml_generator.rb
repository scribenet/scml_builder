require 'yaml'

class DTDMaker



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
