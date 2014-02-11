require 'joos/token'
require 'joos/ast'

##
# @todo Documentation
class Joos::Parser
  require 'parser_rules'

  attr_reader :token_stream
  attr_reader :state_stack
  attr_reader :ast_stack

  def initialize token_stream
    @token_stream = [:EndProgram] + Array(token_stream).reverse
    @state_stack  = [0]
    @ast_stack    = []
    @transitions  = PARSER_RULES[:transitions]
    @reductions   = PARSER_RULES[:reductions]
  end

  ##
  # Freedom patches on classes used by the parser in order to optimize
  # code flow.
  module ParserRefinements
    refine Array do
      def process parser, token
        parser.state_stack.pop last
        klass = Joos::AST.const_get(first, false)
        parser.token_stream.push klass.new(parser.ast_stack.pop last)
      end
    end

    refine Fixnum do
      def process parser, token
        parser.token_stream.pop
        parser.state_stack.push self
        parser.ast_stack.push token
      end
    end
  end

  ##
  # Extensions to the symbol class that are used for debugging
  class ::Symbol
    alias_method :type, :to_sym # :)
  end

  # unleash the magic (of getting the dispatcher to do our branching)
  # sadly, we are putting 2 types of objects through this method, so I'm
  # not sure how effective the call site cache will work :(
  using ParserRefinements

  def parse
    until @token_stream.empty?
      token = @token_stream.last
      $stderr.safe_puts "Parsing #{token} from state #{current_state}" if $DEBUG
      oracle(token).process(self, token)
    end
    @ast_stack.pop
    @ast_stack.pop
  end


  private

  def current_state
    @state_stack.last
  end

  def oracle token
    token_sym = token.type
    return dangling_else if token_sym == :Else
    reduction = @reductions[current_state].find { |arr, _|
      arr.include? token_sym
    }

    # @todo wtf are we calling #to_a on the reduction?
    return reduction.to_a.last if reduction

    next_state = @transitions.fetch(current_state) do
      # @todo we should do this with a bit more grace
      raise("Expected one of #{@reductions[current_state].keys.inspect}" +
            ", but got #{token.inspect} from state #{current_state}")
    end

    next_state.fetch token_sym do |_|
      raise("no transition on #{next_state.inspect} with #{token_sym}")
    end
  end

  def dangling_else
    current_transitions = @transitions[current_state]
    next_state = current_transitions && current_transitions[:Else]
    unless next_state
      reduction = @reductions[current_state].find { |arr, _|
        arr.include? :Else
      }
      next_state = reduction.to_a.last
    end

    if next_state
      return next_state
    else
      Raise "Parse error. Too lazy to figure out what to actually output."
    end
  end

end
