# encoding: utf-8
require 'yaml'
require 'rspec'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'

class ElementsYamlTests < Minitest::Test
  ELEMENTS = YAML.load(File.read('elements.yml'))
  LS_EXCEPTIONS = %w(br hr)

  def exception?(el, attrs)
    LS_EXCEPTIONS.include?(el) or
      attrs[:group_name] == 'media' or %w(media med).include?(el)
  end

  def test_all_have_learning_categories
    missing = []
    ELEMENTS.each do |cat, els|
      els.each do |el, hsh|
        missing << el unless hsh[:learning_category] or exception?(el, hsh)
      end
    end
    assert missing.empty?, "The following are missing learning categories:\n  #{missing.join("\n  ")}"
  end

  def test_all_have_learning_names
    missing = []
    ELEMENTS.each do |cat, els|
      els.each do |el, hsh|
        missing << el unless hsh[:name]  or exception?(el, hsh)
      end
    end
    assert missing.empty?, "The following are missing names:\n  #{missing.join("\n  ")}"
  end

  def test_all_paras_have_weights
    missing = []
    ELEMENTS[:paragraph_styles].each do |el, hsh|
      missing << el unless hsh[:weight]  or exception?(el, hsh)
    end
    assert missing.empty?, "The following are missing weights:\n  #{missing.join("\n  ")}"
  end
end
