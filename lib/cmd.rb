class Cmd
  def run
    type = ARGV[0]
    location = ARGV[1] || Dir.pwd
    ScmlListKnowledge.new(type, location).generate_output
  end
end
