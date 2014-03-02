require 'joos/token'
require 'joos/ast'
require 'joos/exceptions'

##
# @todo Documentation
class Joos::Parser
  require 'parser_rules'

  TRANSITIONS = PARSER_RULES[:transitions]
  REDUCTIONS  = PARSER_RULES[:reductions]

  ##
  # Exception raised when a parsing failure occurs due to an unexpected token
  # being processed.
  class UnexpectedToken < Joos::CompilerException

    # @return [Joos::Parser]
    attr_reader :parser

    ##
    # The offending token
    #
    # @return [Joos::Token]
    attr_reader :token

    def initialize parser, token
      @parser = parser
      @token  = token
      syms    = all_symbols.inspect
      inspect = "`#{token.inspect}'"
      source  = if token.respond_to? :source
                  ' from ' << token.source.red
                else
                  ''
                end
      super "Expected one of #{syms}, but got #{inspect}" << source
    end


    private

    def all_symbols
      s = REDUCTIONS[parser.current_state].keys.reduce([], :concat)
      s.concat TRANSITIONS[parser.current_state].keys
      s.uniq!
      s
    end
  end

  # @return [Array<Joos::Token>]
  attr_reader :token_stream

  attr_reader :state_stack
  attr_reader :ast_stack

  def initialize token_stream
    @token_stream = [:EndProgram] + Array(token_stream).reverse
    @state_stack  = [0]
    @ast_stack    = []
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
      parser_debug token if $DEBUG
      oracle(token).process(self, token)
    end
    @ast_stack.pop
    @ast_stack.pop
  end

  def current_state
    @state_stack.last
  end


  private

  def parser_debug token
    $stderr.safe_puts "Parsing #{token} from state #{current_state}"
  end

  def oracle token
    token_sym = token.to_sym

    if token_sym == :Else
      get_transition(:Else) || get_reduction(:Else)
    else
      get_reduction(token_sym) || get_transition(token_sym)
    end || (raise UnexpectedToken.new(self, token))
  end

  def get_reduction token_sym
    # to_a is called to take care of the nil case
    REDUCTIONS[current_state].find { |arr, _| arr.include? token_sym }.to_a.last
  end

  def get_transition token_sym
    TRANSITIONS[current_state].fetch token_sym, nil
  end

end
