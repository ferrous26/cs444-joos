require 'securerandom'
require 'erb'

require 'joos/exceptions'
require 'joos/utilities'


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
  # Knows the names of values in registers and the current stack frame.
  #
  # The purpose of this class is to keep track of where variables/values
  # with a given name currently are, and to make decisions on where to
  # move variables/values for instructions.
  #
  class RegisterAllocator

    def initialize
      @registers = []
      @stack     = []
    end

    ##
    # Move variable with the given `name` into the given register
    def move name, to: available_register
    end

    ##
    # Find the first available register
    #
    # @return [String]
    def available_register
      REGISTER[0]
    end


    private

    ##
    # The assembly names of registers.
    #
    # @return [Array<String>]
    REGISTER = []

    # Generate convenient accessors for named registers
    [
      'eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp', 'esp'
    ].each_with_index do |reg, index|
      REGISTER[index] = reg
      define_method(reg)       {       @registers[index]       }
      define_method("#{reg}=") { |val| @registers[index] = val }
    end
  end

  ##
  # Collection of helpers to generate actual instructions for i386 CPUs.
  #
  # Goals: given the operands for an (somewhat) abstract instruction,
  # rearrange things for the specific CPU. Also, good comment for the
  # instruction that indicates the high level parameters.
  #
  module I386
    extend self

    def static_field_read label
      "mov     eax, [#{offset}]"
    end

    def static_field_write label, value
      "mov     [#{label}], #{value}"
    end

    def instance_field_read offset
      "mov     eax, [ebx + #{offset}]"
    end

    # @param value [String]
    def instance_field_write offset, value
      "mov     [ebx + #{offset}], #{value}"
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
    @platform = self.class.const_get platform.to_s.capitalize
    @unit     = unit
    @file     = "#{directory}/#{unit.fully_qualified_name.join('_') << '.s'}"
    @symbols  = default_symbols
    @strings  = literal_string_hash
    @main     = main
  end

  def start_sym
    Joos::Utilities.darwin? ? '_main' : '_start'
  end

  def render_to_file
    File.open @file, 'w' do |fd|
      fd.write render_object
    end
  end

  # Load all the templates
  [
    'object',
    # section .text
    'field_initializers',
    'aggregate_field_initializer',
    'methods',
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


  private

  def literal_string_hash
    Hash.new do |hash, key|
      id = SecureRandom.uuid
      id.gsub!(/-/, '_')
      hash[key] = "string##{id}"
    end
  end

  def default_symbols
    [
      '__debexit', '__malloc', '__exception',
      '__division',
      '__downcast_check', '__instanceof'
    ]
  end

  def field_initializer field
    'init_' + field.label
  end

  def static_field_initializers
    @unit.fields.select(&:static?).select(&:initializer).map do |field|
      field_initializer field
    end
  end

  def unit_initializer unit
    'init_' + unit.label
  end

  def unit_initializers
    @unit.root_package.all_classes.map do |unit|
      unit_initializer(unit).tap do |label|
        @symbols << label unless unit == @unit
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

  def vtable_label
    'vtable_' + @unit.label
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

end
