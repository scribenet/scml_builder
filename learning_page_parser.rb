require 'nokogiri'
require 'open-uri'
require 'yaml'

class GetMyScmlStuff

  attr_reader :elements, :ls, :new_attrs, :scml
  PAGE = 'http://learning.scribenet.com/tutorials/wfdw/composition/scml'

  def initialize
    @scml = YAML.load(File.read('elements.yml'))
    @elements = scml.map{ |x| 
      x[1].keys
    }.compact.flatten
    @ls = Nokogiri.HTML( open(PAGE) )
    @new_attrs = {}
  end

  def run 
    scan_ls_and_build_list
    add_new_attrs
    scml.to_yaml
  end

  def scan_ls_and_build_list
    scml_table = ls.css('table')[3] 
    ls_cat = ''
    scml_table.css('tr').each do |tr|
      if tr.at_css('th[id]') 
      ls_cat = tr.at_css('th[id]').text
      end
#      require 'pry'; binding.pry if tr.text.match(/epigraph/) 
      if tr.css('td')[1] and elements.include?( tr.css('td')[1].text.gsub(/\s/,'') )
        el = tr.css('td')[1].text.gsub(/\s/,'')
        new_attrs[el] = {}
        new_attrs[el][:learning_category] = ls_cat unless ls_cat.empty?
        new_attrs[el][:name] = tr.css('td')[0].text if tr.css('td')[0].text
        new_attrs[el][:tip] = tr.at_css('td span[class=qtip]')[:title] if tr.at_css('td span[class=qtip]')
        new_attrs[el][:date] = tr.css('td')[2].text if tr.css('td')[2]
        new_attrs[el][:shortcut] = tr.css('td')[3].text if tr.css('td')[3]
      end
    end
  end

  def add_new_attrs
    @scml.each do |categ, els|
      els.each do |el, info|
        info.merge!(new_attrs[el]) if new_attrs[el]
      end 
    end
  end

end

File.open('elements_out.yml', 'w').write GetMyScmlStuff.new.run
