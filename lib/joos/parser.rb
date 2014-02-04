require 'joos/version'

##
# @todo Documentation
class Joos::Parser
  eval File.read("config/parser_rules.rb")

  def initialize token_stream
    @stream = Array(token_stream).reverse
    @state_stack = [0]
    @transitions = PARSER_RULES[:transitions]
    @reductions = PARSER_RULES[:reductions]
  end

  def parse
    until @stream.empty?
      token = @stream.last
      puts token

      rule = oracle token
      if rule.is_a?(Array)
        rule.last.times do
          @state_stack.pop
        end
        @stream.push rule.first
      elsif rule.is_a?(Integer)
        @stream.pop
        @state_stack.push rule
      else

        raise "Unexpected token: #{token}"
      end
    end
  end

private

  def current_state
    @state_stack.last
  end

  def oracle token
    token_symbol = token.to_sym
    next_state = @transitions[current_state] && @transitions[current_state][token_symbol]
    reduction = @reductions[current_state].find do |arr,_| 
      arr.include? token_symbol
    end

    if reduction
      
      reduction.to_a.last
    elsif next_state

      next_state
    else
      puts "Was looking for #{token_symbol}, but did not find in #{@reductions[current_state].keys.inspect} in state #{current_state}"

      return false
    end
  end

end