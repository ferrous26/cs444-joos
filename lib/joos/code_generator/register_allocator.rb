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
      @stack     = [:nil] # starts off with `ebp` already pushed
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
    # Allocate space on the stack for a new value with the given `name`.
    #
    # @param name [String]
    # @return [String,nil] location where `name` will be stored if
    #   an existing stack space is being reused, else returns `nil`
    #   indicating the variable can be `push`ed onto the stack
    def allocate name
      i = @stack.index nil
      if i
        @stack[i] = name
        "[ebp - #{(i + 1) * 4}]"
      else
        @stack << name
        nil
      end
    end
    alias_method :alloc,  :allocate
    alias_method :malloc, :allocate

    ##
    # Forcefully place `name` in the given `register`.
    #
    # @param register [Symbol]
    # @param name [String]
    # @return [String] pointlessly return `register` as a string
    def take register, name
      raise "#{register} is not a register" unless @registers.key? register
      in_reg = @registers[register]

      # if name is already in the register, nothing to do...
      unless in_reg == name
        # if something is in the register...
        if in_reg
          # if it is already on the stack, we can just overwrite it
          unless @stack.index in_reg
            @stack << in_reg
            @moves << "push #{register}    ; backup #{in_reg}"
          end
        end

        @registers[register] = name
      end

      register.to_s # fulfill post condition...
    end

    ##
    # One or more variables which must be allocated into a register
    # and already exists somewhere.
    #
    # @param names [String]
    # @return [Array<String>]
    def take_registers *names
      names.map do |name|
        # if it is already in a register, just use that register
        if @registers.value? name
          # and we do not need to generate any move instructions
          @registers.find { |reg, val| val == name }

        # else we need to allocate a register
        else
          # it is on the stack, so we calculate the offset for loading
          offset    = (@stack.index(name) + 1) * 4
          empty_reg = @registers.find { |reg, val| !val }

          if empty_reg
            @moves << "mov #{empty_reg.first}, [ebp - #{offset}]"
            @registers[empty_reg.first] = name
            empty_reg.first

          # no empty registers, need to kick someone out
          else
            # look at registers that we do not need to keep
            taken_regs = @registers.reject { |reg, val| names.include? val }

            # from the available regs, prefer someone on the stack
            loser = taken_regs.find { |reg, val| @stack.index val }

            # if no loser is on the stack, then we need to arbitrarily
            # pick a loser and kick him/her out
            unless loser
              loser   = taken_regs.first
              @stack << loser.last
              @moves << "push #{loser.first}    ; backup #{loser.last}"
            end

            @registers[loser.first] = name
            loser.first
          end
        end
      end
    end

    def swap old_name, new_name
      # if old_name on the stack, no problem
      # else back that ass up
    end

    ##
    # Mark the space occupied by `name` as unused so that it can
    # reused by another variable, thus mitigating stack overflow
    # likelyhood.
    #
    # @param dead_name [String]
    def free dead_name
      # remove all occurences from the stack
      @stack = @stack.map { |name| name == dead_name ? nil : name }

      # remove all occurences from registers
      @registers.keys.each do |register|
        @registers[register] = nil if @registers[register] == dead_name
      end
    end

    ##
    # Find the location where `name` is stored and return the
    # register or offset calculation.
    #
    # @example
    #
    #   find('foo')  # => 'eax'
    #   find('foo')  # => '[ebp - 12]'
    #   find('this') # => '[ebp + 8]'
    #
    # @param name [String]
    # @return [String] location of `name`
    def find name
      if @registers.value? name
        @registers.find { |reg, val| val == name }.first.to_s

      elsif @args.key? name
        @args[name]
        "[ebp + #{@args[name]}]"

      elsif @stack.include? name
        "[ebp - #{((@stack.index(name) + 1) * 4)}]"

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
    # @note This method is destructive in the same way that
    #       {#movement_instructions} is destructive.
    #
    # To be called when setting up a method.
    #
    # Every register that is currently in use will be backed up to the
    # stack and instructions on how to perform the moves will be returned.
    #
    # @return [Array<String>]
    def caller_save
      @registers.each do |register, name|
        next unless name

        # back it up if it is not already somewhere on the stack
        index = @stack.index name
        unless index
          @stack << name
          @moves << "push #{register}    ; backup #{name}"
        end

        @registers[register] = nil # blank the register
      end

      @moves
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
      instructions = @moves
      @moves = []
      instructions
    end
    alias_method :backup_instructions, :movement_instructions

    # @return [Fixnum] size in bytes, not including saved `ebp`
    def stack_size
      (@stack.size - 1) * 4
    end


    private

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
                  edi: nil
                }
  end
end