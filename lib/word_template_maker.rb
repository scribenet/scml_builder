require 'yaml'
require 'erb'
require 'docx_tools'

class WordTemplateMaker

  DOTX = File.dirname(__FILE__) + '/../templates/scr-word-template.dotx'
  DEFAULT_CHAR = 'l-spa'
  DEFAULT_PAR = 'p'
  # use Default Paragraph Font, make it a weird color
  attr_reader :list, :output, :type

  def initialize type, list
    @list = list
    @type = type
    @dotx = DocxTools.new(DOTX) 
    require 'pry'; binding.pry 
  end

  def run
    @dotx.rezip
  end

end
