require 'joos/token'
require 'joos/ast'
require 'joos/exceptions'

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
    token_sym = token.to_sym

    if token_sym == :Else
      get_transition(:Else) || get_reduction(:Else)
    else
      get_reduction(token_sym) || get_transition(token_sym)
    end || raise_parse_error(token)
  end

  def get_reduction token_sym
    # to_a is called to take care of the nil case
    @reductions[current_state].find { |arr,_| arr.include? token_sym }.to_a.last
  end

  def get_transition token_sym
    @transitions[current_state].fetch token_sym, nil
  end

  def raise_parse_error token
    all_symbols = []
    @reductions[current_state].keys.each do |symbols|
      all_symbols +=symbols
    end
    all_symbols += @transitions[current_state].keys
    all_symbols.uniq!

    raise Joos::CompilerException, "Expected one of #{all_symbols.inspect}, but got #{token.inspect}"
  end

end
