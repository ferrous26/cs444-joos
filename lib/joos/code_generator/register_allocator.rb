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
      @stack     = [:nil] # starts off with `ebp` at `[ebp]`
      @offset    = (args.size + 1) * 4 # offset from `[ebp]`

      # [ebp] is the previous ebp,
      # [ebp-4] is the return address (pushed by call)
      args.each do |name|
        @args[name]  = @offset if name
        @offset     -= 4
      end
    end

    ##
    # Allocate space on the stack for a new value with the given `name`.
    #
    # @param name [String]
    # @return [String,nil] location where `name` will be stored if
    #   an existing stack space is being reused, else returns `nil`
    #   indicating the variable can be `push`ed onto the stack
    def allocate name
      # first, check if it already exists on the stack
      i = @stack.index name
      if i
        "[ebp - #{i * 4}]"

      # else, it does not exist, so we need to find a spot
      else

        # check for an open space
        i = @stack.index nil
        if i
          @stack[i] = name
          "[ebp - #{i * 4}]"

        # no open space, so actually allocate a new spot
        else
          @stack << name
          nil
        end
      end
    end
    alias_method :alloc,  :allocate
    alias_method :malloc, :allocate

    ##
    # Allocate some register for the given `name`, possibly kicking
    # out someone else.
    #
    # Essentially follows protocol of {#take_registers}, except for
    # the case of a single `name`.
    #
    # @param name [String]
    # @return [String]
    def allocate_register name
      take_registers(name).first
    end

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
      return if in_reg == name

      # if something is in the register, then we might need to back it up
      if in_reg
        # if it is already on the stack (or args), we can just overwrite
        # the register and reload the value later if needed
        unless on_stack?(in_reg) || arg?(in_reg)
          # it does not exist elsewhere, so we must push it onto the stack
          @stack << in_reg
          @moves << push_instruction(register, in_reg)
        end
      end

      # finally, take over the register
      @registers[register] = name
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
          @registers.find { |reg, val| val == name }.first

        # else we need to allocate a register
        else
          # if it is on the stack, we calculate the offset for loading
          offset, dir = if on_stack? name
                          [stack_offset(name), :stack]
                        elsif arg? name
                          [@args[name], :args]
                        end
          empty_reg = @registers.find { |reg, val| !val }

          if empty_reg
            take_register_private empty_reg, offset, name, dir

          # there are no empty registers, so we need to kick someone out
          else
            # look at registers that we do not need to keep
            taken_regs = @registers.reject { |reg, val| names.include? val }

            # from the available regs, prefer someone on the stack
            # implicitly choosing older variables (hopefully a good
            # heuristic)
            loser = taken_regs.find { |reg, val| @stack.index val }

            # if no loser is on the stack, then we need to arbitrarily
            # pick a loser and kick him/her out, though maybe we can
            # make a smarter choice about who to kick out... @todo
            unless loser
              loser   = taken_regs.first
              @stack << loser.last
              @moves << push_instruction(*loser)
            end

            take_register_private loser, offset, name, dir

          end
        end
      end
    end

    ##
    # Merge `left` into `right`, implicitly freeing the space for `left`
    # and aliasing the name to the name of `right`.
    #
    # @param left  [String]
    # @param right [String]
    # @return [nil]
    def unify name1, name2
      # @todo herp derp
      raise NotImplementedError
    end

    ##
    # Mark the space occupied by `name` as unused so that it can
    # reused by another variable, thus mitigating stack overflow
    # likelyhood.
    #
    # @param dead_name [String]
    def free dead_name
      free_stack dead_name
      free_registers dead_name
      nil
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
      if in_register? name
        @registers.find { |reg, val| val == name }.first.to_s

      elsif arg? name
        "[ebp + #{@args[name]}]"

      elsif on_stack? name
        "[ebp - #{stack_offset name}]"

      end
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

    def on_stack? name
      @stack.index name
    end

    def in_register? name
      @registers.value? name
    end

    def arg? name
      @args.key? name
    end

    def dup
      ra = super
      ra.instance_variable_set(:@stack,     @stack.dup)
      ra.instance_variable_set(:@registers, @registers.dup)
      ra
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

    def free_stack dead_name
      # remove all occurences from the stack
      @stack = @stack.map { |name| name == dead_name ? nil : name }
    end

    def free_registers dead_name
      # remove all occurences from registers
      @registers.keys.each do |register|
        @registers[register] = nil if @registers[register] == dead_name
      end
    end

    def move_instruction reg, offset, name
      "mov #{reg}, [ebp - #{offset}]  ; load #{name}"
    end

    def arg_move_instruction reg, offset, name
      "mov #{reg}, [ebp + #{offset}]  ; load arg #{name}"
    end

    def push_instruction register, name
      "push #{register}    ; backup #{name}"
    end

    def take_register_private pair, offset, name, location
      # only generate a move if it existed on the stack
      if location == :stack
        @moves << move_instruction(pair.first, offset, name)
      elsif location == :args
        @moves << arg_move_instruction(pair.first, offset, name)
      end

      @registers[pair.first] = name
      pair.first
    end

    def stack_offset name
      @stack.index(name) * 4
    end
  end
end
