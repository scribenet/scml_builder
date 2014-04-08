require 'yaml'
require 'erb'
require_relative 'lib/dtd_maker'
require_relative 'lib/scml_list_maker'

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
