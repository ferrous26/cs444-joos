require 'joos/version'

class Joos::CodeGenerator
  ##
  # Knows the names of values in registers and the current stack frame.
  #
  # The purpose of this class is to keep track of where variables/values
  # with a given name currently are, and to make decisions on where to
  # move variables/values for instructions.
  #
  class RegisterAllocator

    # @param args [Array<String>] names of args passed to the method
    #  which are ordered highest address to lowest address, indicate
    #  empty (ignored) spots with `nil`
    def initialize args = []
      @moves     = [] # temp store for things that need to move around
      @registers = REGISTERS.dup
      @args      = {}
      @stack     = []
      @offset    = (args.size - 1) * 4 # offset from `[ebp]`

      args.each do |name|
        @args[name]  = @offset if name
        @offset     -= 4
      end
    end

    ##
    # @note We allow a name to exist more than once. When calling
    #       {#find}, order of precedence will determine which copy
    #       you find. {#free} will free all copies.
    #
    # Allocate space for a new value with the given `name`.
    #
    # @param name [String]
    # @return [String] location where `name` will be stored
    def allocate name
      @stack << name # @todo maybe not always do this?
      find name
    end
    alias_method :alloc,  :allocate
    alias_method :malloc, :allocate

    ##
    # Forcefully place `name` in the given `register`.
    #
    # This only works for register take over.
    #
    # @param register [Symbol]
    # @param name [String]
    # @return [String] pointlessly return `register`
    def take register, name
      raise "#{register} is not a register" unless @registers.key? register
      backup register if @registers[register]
      @registers[register] = name
      register.to_s
    end

    ##
    # Mark the space occupied by `name` as unused so that it can
    # reused by another variable, thus mitigating stack overflow
    # likelyhood.
    #
    # @param name [String]
    def free name
      # @todo
    end

    ##
    # Find the location where `name` is stored and return the
    # register or offset calculation.
    #
    # @example
    #
    #   find('foo')  # => 'eax'
    #   find('foo')  # => 'ebp - 12'
    #   find('this') # => 'ebp + 8'
    #
    # @param name [String]
    # @return [String] location of `name`
    def find name
      if @registers.value? name
        @registers.find { |reg, val| val == name }.first.to_s

      elsif @args.key? name
        @args[name]
        'ebp + ' + @args[name].to_s

      elsif @stack.include? name
        'ebp - ' + ((@stack.index(name) + 1) * 4).to_s

      end
    end

    ##
    # Merge `name2` into `name1`, implicitly freeing `name2`
    #
    # @param name1 [String]
    # @param name2 [String]
    # @return [nil]
    def unify name1, name2
      # @todo
    end

    ##
    # To be called when setting up a method.
    #
    # Every register that is currently in use will be backed up to the
    # stack and instructions on how to perform the moves will be returned.
    #
    # @return [Array<String>]
    def caller_save
      # @todo Every register currently in use...or just `pushad`
    end

    ##
    # @note This method mutates state, you must cache the response if you
    #       need to call it multiple times before allocating/moving again
    #
    # After allocating, or forcefully taking a register, it is important
    # to check this method to see if any values need to be moved out of
    # registers.
    #
    # This method returns full instructions for each move that is required.
    #
    # @return [Array<String>]
    def movement_instructions
      instructions = @moves.map { |name, register|
        "        mov #{self.allocate name}, #{register}"
      }
      @moves.clear
      instructions
    end
    alias_method :backup_instructions, :movement_instructions

    ##
    # The current 16 byte offset of the stack
    #
    # @return [Fixnum]
    def alignment_offset
      (@stack.size % 4) * 4
    end


    private

    def backup register
      name = @registers[register]
      @registers[register] = nil
      @moves << [name, register]
    end

    ##
    # The assembly names of registers.
    #
    # @return [Array<String>]
    REGISTERS = {
                  eax: nil,
                  ebx: nil,
                  ecx: nil,
                  edx: nil,
                  esi: nil,
                  edi: nil,
                  ebp: nil,
                  esp: nil
                }

    # Generate convenient accessors for named registers
    [
      :eax, :ebx, :ecx, :edx, :esi, :edi, :ebp, :esp
    ].each_with_index do |reg, index|
      define_method(reg)       {       @registers[reg]       }
      define_method("#{reg}=") { |val| @registers[reg] = val }
    end

  end
end
