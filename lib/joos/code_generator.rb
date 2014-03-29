require 'securerandom'
require 'erb'

require 'joos/utilities'


##
# Code generating logic for Joos
class Joos::CodeGenerator

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

    def add left, right
    end

    def imult left, right
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
    @platform  = self.class.const_get platform.to_s.capitalize
    @unit      = unit
    @directory = directory
    @file      = unit.fully_qualified_name.join('_') << '.s'
    @symbols   = default_symbols
    @strings   = literal_string_hash
    @main      = main
  end

  def start_sym
    Joos::Utilities.darwin? ? '_main' : '_start'
  end

  def render
    File.open "#{@directory}/#{@file}", 'w' do |fd|
      fd.write render_object
    end
  end


  def self.read name
    File.read "config/#{name}.erb"
  end
  ERB.new(read('object.s'), nil, '>-').def_method(self, :render_object)


  private

  def literal_string_hash
    Hash.new do |hash, key|
      id = SecureRandom.uuid
      id.gsub!(/-/, '_')
      hash[key] = "string##{id}"
    end
  end

  def default_symbols
    ['__debexit', '__malloc', '__exception', '__division']
  end

  def static_initializers
    @unit.fields.select(&:static?).select(&:initializer).map do |field|
      'Init_' << field.label
    end
  end

  def unit_initializers
    @unit.root_package.all_classes.map do |unit|
      label = 'Init_' + unit.label
      @symbols << label unless unit == @unit
      label
    end
  end

end
