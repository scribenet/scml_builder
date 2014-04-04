require_relative '../structing/lib/structing'
require 'yaml'

class ScmlReader

  def initialize yamlin, yamlout
    file = File.read yamlin
    grab_header(file)
    @in = YAML.load file 
    @out = File.open(yamlout, 'w')
  end

  def grab_header file
    headers = []
    file.each_line do |line|
      headers << line if line.match(/^#/)
    end
    @header = headers.join + "\n"
  end

  def add_group_info
    @groups = {:groups =>{} }
    @in.map{ |category, els|
      els.each do |el_name, hsh|
        hsh = {} if hsh.nil?
        els[el_name] = hsh if hsh.empty?
        if cat = Scml.category(el_name)
          hsh[:group_name] = cat 
          hsh[:abbrev] = Scml.front_matter_chapter_id(el_name) if Scml.front_matter_chapter_id(el_name)
        end
        hsh[:primary_structure] = Scml.structure_element_name(el_name) if Scml.structure_element_name(el_name)
        hsh[:chapter_start] = true if Scml.chapter_start_element?(el_name)
      end
    }
  end

  def print
    add_group_info
    new = @in.to_yaml
    @out.write @header + new
  end

end

yaml_maker = ScmlReader.new ARGV[0], ARGV[1]
yaml_maker.print
