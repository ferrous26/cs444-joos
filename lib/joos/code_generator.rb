require 'securerandom'
require 'erb'

require 'joos/exceptions'
require 'joos/utilities'
require 'joos/code_generator/register_allocator'
require 'joos/code_generator/render_segment'


##
# Code generating logic for Joos
class Joos::CodeGenerator

  ##
  # Exception raised when the compilation unit expected to have the main
  # function does not have a main function.
  #
  class NoMainDetected < Joos::CompilerException
    def initialize unit
      super "#{unit.inspect} must have a public static int test() method", unit
    end
  end


  ##
  # Symbols that are externally defined and should be declared as such
  #
  # @return [Array<String>]
  attr_reader :symbols

  ##
  # Literal strings used in the compilation unit
  #
  # Map of string value to symbol name.
  #
  # @return [Hash{ String => String }]
  attr_reader :strings

  # @param unit      [Joos::Entity::CompilationUnit]
  # @param platform  [Symbol] pretty much has to be `:i386`
  # @param directory [String] where to put all the asm
  # @param main      [Boolean] whether or not to generate the main routine
  def initialize unit, platform, directory, main
    #@platform = self.class.const_get platform.to_s.capitalize
    @unit     = unit
    @file     = "#{directory}/_#{unit.fully_qualified_name.join('_') << '.s'}"
    @symbols  = default_symbols
    @globals  = determine_global_symbols
    @strings  = literal_string_hash
    @main     = main
  end

  def start_sym
    Joos::Utilities.darwin? ? '_main' : '_start'
  end

  def self.render_array_to_file platform, directory, root_package
    array = Joos::Array.new Joos::BasicType.new :Int
    array.root_package = root_package
    array.define_singleton_method(:label) { 'array' } # hack
    gen   = new array, platform, directory, false
    gen.render_array_class
  end

  def render_to_file
    File.open @file, 'w' do |fd|
      fd.write render_object
    end
  end

  def render_array_class
    File.open @file, 'w' do |fd|
      fd.write render_joos_array
    end
  end

  # Compile and render a {SSA::Segment} to machine code
  # @param segment [Joos::SSA::Segment]
  # @return [String]
  def render_segment segment
    # Actual code is in code_generator/render_segment.rb
    render_segment_x86(segment).join("\n    ")
  end


  # Load all the templates
  [
    'joos_array',
    'object',
    # section .text
    'field_initializers',
    'aggregate_field_initializer',
    'methods',
    'constructors',
    'main',
    # section .data
    'vtable',
    'ancestry_table',
    'static_field_data',
    'literal_strings',
    # section (other)
    'extern_symbols'
  ].each do |name|
    template = File.read "config/#{name}.s.erb"
    ERB.new(template, nil, '>-').def_method(self, "render_#{name}")
  end

  def render_runtime
    File.read 'config/joos_runtime.s'
  end


  private

  def literal_string_hash
    Hash.new do |hash, key|
      id = SecureRandom.uuid
      id.gsub!(/-/, '_')
      hash[key] = "string##{id}"
    end
  end

  def default_symbols
    base = [ '__debexit', '__malloc', '__exception' ]

    base << vtable(@unit.get_string_class) unless @unit.string_class?
    base << 'vtable_array' unless @unit.array_type? # @todo not hardcode this

    base
  end

  def fields_initializer
    'init_fields' + @unit.label
  end

  def unit_initializer unit
    'init_' + unit.label
  end

  def unit_initializers
    @unit.root_package.all_classes.map do |unit|
      unit_initializer(unit).tap do |label|
        @symbols << label
      end
    end
  end

  def concrete_methods
    @unit.methods.reject(&:abstract?).reject(&:native?)
  end

  def joos_main
    method = @unit.methods.find { |m| m.signature == ['test', []] }
    raise NoMainDetected.new @unit unless method
    method.label
  end

  def vtable unit
    'vtable_' + unit.label
  end

  def vtable_label
    vtable @unit
  end

  def vtable_methods
    methods = @unit.all_instance_methods
      .reject(&:abstract?)
      .sort_by(&:method_number)

    methods.each do |method|
      @symbols << method.label
    end

    mtable = Array.new(methods.last.method_number) do |index|
      methods.find { |method| method.method_number == index }
    end
    mtable.shift # throw away index zero, which is always empty

    mtable.map { |m| m ? m.label : '0x00' }
  end

  def atable_label
    'atable_' + @unit.label
  end

  # @return [Array<Joos::Entity::CompilationUnit>]
  def unit_ancestors
    @unit.ancestors.uniq
  end

  def static_fields
    @unit.fields.select(&:static?)
  end

  def determine_global_symbols
    base = [vtable_label, unit_initializer(@unit)]
    unless @unit.array_type?
      base.concat concrete_methods.map(&:label)
      base.concat @unit.constructors.map(&:label)
      base.concat @unit.static_fields.map(&:label)
    end
    base
  end

end
