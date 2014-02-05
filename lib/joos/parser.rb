require 'joos/token'

##
# @todo Documentation
class Joos::Parser
  eval File.read('config/parser_rules.rb')

  def initialize token_stream
    @stream      = Array(token_stream).reverse
    @state_stack = [0]
    @transitions = PARSER_RULES[:transitions]
    @reductions  = PARSER_RULES[:reductions]
  end

  ##
  # Freedom patches on classes used by the parser in order to optimize
  # code flow.
  module ParserRefinements
    refine Array do
      def act state_stack, stream, token
        state_stack.pop last
        stream.push first
      end
    end

    refine Fixnum do
      def act state_stack, stream, token
        stream.pop
        state_stack self
      end
    end

    refine NilClass do
      def act _, _, token
        raise "Unexpected token: #{token}"
      end

      def type
        to_sym
      end
    end
  end

  # unleash the magic (of getting the dispatcher to do our branching)
  # sadly, we are putting 2 types of objects through this method, so I'm
  # not sure how effective the call site cache will work :(
  using ParserRefinements

  def parse
    until @stream.empty?
      token = @stream.last
      puts token
      oracle(token.type).act(@state_stack, @stream, token)
    end
  end


  private

  def current_state
    @state_stack.last
  end

  def oracle token
    reduction = @reductions[current_state].find { |arr, _| arr.include? token }

    # @todo wtf are we calling #to_a on the reduction?
    return reduction.to_a.last if reduction

    next_state = @transitions.fetch(current_state) do
      return puts <<-EOM
Expected one of #{@reductions[current_state].keys.inspect},
but got #{token.inspect} from state `#{current_state}'
      EOM
    end

    next_state.fetch token_symbol
  end

end
