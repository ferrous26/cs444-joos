require 'joos/version'

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

  # @param unit      [Joos::Entity::CompilationUnit]
  # @param platform  [Symbol] pretty much has to be `:i386`
  # @param directory [String] where to put all the asm
  def initialize unit, platform, directory
    @platform = self.class.const_get platform.to_s.capitalize
    @unit     = unit
    @file     = unit.fully_qualified_name.join('_') << '.s'
    @fd       = File.open "#{directory}/#{@file}", 'w'
  end

  def generate_data
    # tag data
    # vtable
    # static fields
  end

  def generate_text
    # static methods
    # instance methods
  end

  def generate_main
    @main = true
    @fd.puts <<-EOC
extern __debexit

global _start
_start:
    mov ebx, 42
    call __debexit
    EOC
  end

  def finalize
    @fd.puts "extern _start" unless @main
    @fd.close
  end

end
