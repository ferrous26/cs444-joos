require 'base64'
require 'digest/md5'
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

  # @return [Hash]
  attr_reader :strings

  # @param unit      [Joos::Entity::CompilationUnit]
  # @param platform  [Symbol] pretty much has to be `:i386`
  # @param directory [String] where to put all the asm
  def initialize unit, platform, directory
    @platform = self.class.const_get platform.to_s.capitalize
    @unit     = unit
    @file     = unit.fully_qualified_name.join('_') << '.s'
    @fd       = File.open "#{directory}/#{@file}", 'w'
    @symbols  = ['__debexit', '__malloc', '__exception']
    @strings  = literal_string_hash
  end

  if Joos::Utilities.darwin?
    def start_sym
      '_main'
    end
  else
    def start_sym
      '_start'
    end
  end

  def generate_data
    @fd.puts 'section .data'

    # tag data
    # vtable
    # static fields

    # literal strings
  end

  def generate_text
    @fd.puts 'section .text'

    # static methods
    # instance methods
  end

  def generate_main
    @fd.puts <<-EOC
global #{start_sym}
#{start_sym}:
    mov eax, 123
    call __debexit
    EOC
  end

  def finalize
    append_literal_strings
    append_external_symbols
    @fd.close
  end


  private

  def append_literal_strings
    @fd.puts
    @fd.puts ';; Literal strings'
    @fd.puts 'section .data'
    @strings.each_pair do |str, symbol|
      @fd.puts "#{symbol}: db '#{str}'"
    end
  end

  def append_external_symbols
    @fd.puts
    @fd.puts ';; Symbols that we need to import'
    @symbols.each do |symbol|
      @fd.puts "extern #{symbol}"
    end
  end

  def literal_string_hash
    @strings = Hash.new do |hash, key|
      digest = Digest::MD5.digest key
      encode = Base64.encode64 digest
      encode.chomp!
      encode.gsub!(/\+/, '$')
      encode.gsub!(/\//, '?')
      encode.gsub!(/==/, '')
      hash[key] = "string##{encode}"
    end
  end

end
