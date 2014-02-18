require 'joos/parser'
require 'joos/parser/lr1dfa'
require 'joos/parser/state'
require 'joos/parser/item'

##
# Used to generate an LALR(1) parser from the parser definition
class Joos::Parser::ParserGenerator

  attr_reader :grammar
  attr_reader :terminals
  attr_reader :non_terminals
  attr_reader :start_symbol
  attr_reader :dfa
  attr_reader :first
  attr_reader :nullable

  def initialize grammar
    grammar = Hash(grammar)
    raise TypeError if grammar.empty?
    @grammar = grammar[:rules]
    @terminals = grammar[:terminals]
    @non_terminals = grammar[:non_terminals]
    @start_symbol = grammar[:start_symbol]
    @dfa = Joos::Parser::LR1DFA.new
    @first = {}
    @nullable = []
    @reductions = []
    @transition_queue = []
    build_first_and_nullable
  end

  def build_parser
    build_start_state #bootstraps generation

    until @transition_queue.empty? #main loop
      puts @transition_queue.size.inspect
      from_state, symbol = @transition_queue.shift
      items = @dfa.states[from_state].new_items_after_transition_on symbol
      next_state = build_state items
      @dfa.add_transition from_state, symbol, next_state
    end

    build_reductions
    true
  end

  def build_start_state
    items = []
    @grammar[@start_symbol].each do |rule|
      items.push Joos::Parser::Item.new(@start_symbol, [], rule, Set.new)
    end
    build_state items
  end

  def build_state items
    state = Joos::Parser::State.new

    until items.empty?
      item = items.shift
      next unless state.add_item item
      next_symbol = item.next
      if @non_terminals.include? next_symbol
        new_follow = compute_next_symbol_follow item
        @grammar[next_symbol].each do |rule|
          items.push Joos::Parser::Item.new(next_symbol, [], rule, new_follow)
        end
      end
    end

    added_state = @dfa.add_state state
    if added_state == @dfa.states.size-1 #hack ...
      fill_transition_queue_for_state added_state
    end

    added_state
  end

  def compute_next_symbol_follow item
    after_symbol = item.after_dot[1..-1]
    new_follow = first(after_symbol)
    if all_nullable?(after_symbol)
      new_follow += item.follow
    end

    new_follow
  end

  def first symbols
    first_set = Set.new
    symbols.each do |symbol|
      first_set += @first[symbol]
      break unless @nullable.include? symbol
    end

    first_set
  end

  def all_nullable? symbols
    symbols.each do |symbol|
      return false unless @nullable.include? symbol
    end

    true
  end

  def fill_transition_queue_for_state state_index
    state = @dfa.states[state_index]
    finished_symbols = []
    state.items.each do |item|
      symbol = item.next
      next if symbol.nil? || finished_symbols.include?(symbol)
      finished_symbols.push symbol
      @transition_queue.push [state_index, symbol]
    end
  end

  def build_reductions
    @dfa.states.each_with_index do |state, index|
      @reductions[index] = state.reductions
    end
  end

  def save_parser
    File.open('config/parser_rules.rb', 'w') do |fd|
      fd.puts('PARSER_RULES = ' + file_format.inspect)
    end
  end

  def save_pretty_parser
    require 'pp'
    File.open('config/parser_rules_pp.rb', 'w') do |fd|
      p = PP.new(fd)
      fd.puts 'PARSER_RULES = '
      p.pp file_format
      p.flush
    end
  end

  def build_first_and_nullable
    @non_terminals.each do |symbol|
      @first[symbol] = Set.new
    end
    @terminals.each do |terminal|
      @first[terminal] = Set.new([terminal])
    end

    change = true
    while change
      change = false
      @grammar.each do |left_symbol, rules|
        rules.each do |rule|
          unless @nullable.include?(left_symbol) ||
                 ( !rule.all? { |right_symbol| @nullable.include?(right_symbol) } )
            @nullable.push left_symbol
            change = true
          end
          rule.each_with_index do |symbol, index|
            if rule.take(index).all? { |right_symbol| @nullable.include?(right_symbol) }
              if @non_terminals.include? symbol
                new_first = @first[left_symbol] + @first[symbol]
                unless (new_first - @first[left_symbol]).empty?
                  @first[left_symbol] = new_first
                  change = true
                end
              elsif !@first[left_symbol].include? symbol
                @first[left_symbol].add symbol
                change = true
              end
            end
          end
        end
      end
    end
  end


  private

  def file_format
    printable_reductions = Array.new(@dfa.states.size)
    printable_transitions = Array.new(@dfa.states.size)
    for index in 0..@dfa.states.size-1
      # This takes care of the cases where a state has no transitions,
      # or no reductions
      printable_reductions[index] = Hash[
        @reductions[index].map{ |k2,v2| [k2.to_a, v2] }
      ]
      printable_transitions[index] = Hash @dfa.transitions[index]
    end
    {
     reductions: printable_reductions,
     transitions: printable_transitions
    }
  end

end
