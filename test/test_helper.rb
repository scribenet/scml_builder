require 'yaml'
require 'rspec'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'scml_builder'

module TestPrep
  def tmpdir
    File.join(ScmlConfig.root, 'tmp')
  end

  def setup
    File.mkdir(tmpdir) unless File.exists?(tmpdir)
  end

  def teardown
    Dir.glob(File.join(tmpdir, '*')).map { |x| File.delete(x) }
  end
end
