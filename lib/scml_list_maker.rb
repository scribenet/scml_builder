class ScmlListMaker

  attr_reader :list, :output
  TAB = "\t"
  TYPES = {
    :paragraph_styles => 'P',
    :character_styles => 'C',
  }

  def initialize type, list
    @list = list
    @output = ''
  end

  def run
    iterate_list
    output
  end

  def iterate_list
    list.each do |category, els|
      els.each do |el, info|
        @output += line(category, el, info)
      end
    end
  end

  def line category, el, info
    descrip = info[:description] ? "#{TAB}##{TAB}#{info[:description]}" : ''
    TYPES[category] + TAB + el + descrip + "\n"
  end

end
