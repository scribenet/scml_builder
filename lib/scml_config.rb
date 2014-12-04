module ScmlConfig
  ELEMENTS = 'elements.yml'
  TYPES = 'list_types.yml'

  def self.root
    File.expand_path('../..', __FILE__)
  end

  def self.yaml_string(file)
    File.read(File.join(root, file))
  end

  def self.load_yaml(type)
    YAML.load(yaml_string(type))
  end

  def self.elements
    @elements ||= load_yaml(ELEMENTS)
  end

  def self.runner_knowledge
    @runner_knowledge ||= load_yaml(TYPES)
  end
end
