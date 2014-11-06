# encoding: utf-8
require_relative 'test_helper'

class TestCLI < Minitest::Test
  include TestPrep

  def builder_cmd(output)
    `bundle exec scml_builder #{output} tmp/`
  end

  def test_can_produce_each_output
    ScmlConfig.runner_knowledge.each do |type, info|
      builder_cmd(type)
      output = File.join(tmpdir, info[:name])
      assert File.exists?(output)
    end
  end
end
