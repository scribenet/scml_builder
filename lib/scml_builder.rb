require 'yaml'
require 'erb'
require_relative 'cmd'
require_relative 'scml_config'
require_relative 'makers/dtd_maker'
require_relative 'makers/scml_list_maker'
require_relative 'makers/word_template_maker'
require_relative 'makers/swim_list_maker'

class ScmlListKnowledge
  def initialize(type, location)
    @type = type
    @location = location
  end

  def generate_output
    run_type = ScmlConfig.runner_knowledge[ @type ]
    klass = Module.const_get( run_type[:runner] )
    trimmed_elements = cleanse_list(ScmlConfig.elements, run_type)
    output = klass.new(run_type[:var_name], trimmed_elements).run
    out_location = File.join(@location, run_type[:name])
    File.open( out_location, 'w' ).write(output)
  end

  def cleanse_list(yaml, run_type)
    removers = run_type[:exclude_for]
    yaml.each do |category, els|
      yaml.delete(category) unless run_type[:categories].include? category.to_s
      els.each do |el, el_info|
        els.delete(el) if removable?(el_info, removers)
      end
    end
    yaml
  end

  def removable?(el_info, removers)
    removers.include?(el_info[:for])
  end
end

