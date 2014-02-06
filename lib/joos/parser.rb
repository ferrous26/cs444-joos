require 'joos/token'
require 'joos/cst'

##
# @todo Documentation
class Joos::Parser
  eval File.read('config/parser_rules.rb')

  attr_reader :token_stream
  attr_reader :state_stack
  attr_reader :cst_stack

  def initialize token_stream
    @token_stream = Array(token_stream).reverse
    @state_stack  = [0]
    @cst_stack    = []
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
        klass = Joos::CST.const_get(first, false)
        parser.token_stream.push klass.new(parser.cst_stack.pop last)
      end
    end

    refine Fixnum do
      def process parser, token
        parser.token_stream.pop
        parser.state_stack.push self
        parser.cst_stack.push token
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
      puts token if $DEBUG
      oracle(token).process(self, token)
    end
  end


  private

  def current_state
    @state_stack.last
  end

  def oracle token
    token_sym = token.type
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

    next_state.fetch token_sym
  end

end
