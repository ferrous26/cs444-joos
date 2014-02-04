require 'joos/version'
require 'joos/parser/lr1dfa'
require 'joos/parser/state'
require 'joos/parser/item'

##
# Used to generate an LALR(1) parser from the parser definition
class Joos::Parser::ParserGenerator

  def initialize grammar
    grammar = Hash(grammar)
    raise TypeError if grammar.empty?
    @grammar = grammar[:rules]
    @terminals = grammar[:terminals]
    @non_terminals = grammar[:non_terminals]
    @dfa = Joos::Parser::LR1DFA.new
    @transition_queue = {}
    @reductions = {}
    @first = {}
    @nullable = []
    build_first_and_nullable
  end

  def build_parser
    build_start_state
    build_remaining_states
    build_reductions
  end

  def save_parser
    File.open("some_file.rb", "w") do |fd|
      printable_reductions = {}
      @reductions.each_pair do |k,v|
        printable_reductions[k] = Hash[ v.map{ |k2,v2| [k2.to_a, v2] } ]
      end
      h = { transitions: @dfa.transitions,
            reductions: printable_reductions
          }
      fd.puts "PARSER_RULES = " + h.inspect
    end
  end

  attr_reader :grammar
  attr_reader :terminals
  attr_reader :non_terminals
  attr_reader :dfa
  attr_reader :reductions
  attr_reader :first
  attr_reader :nullable

  private

  attr_accessor :transition_queue

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

  def build_start_state
    start_symbol, reductions = @grammar.first
    items = []
    reductions.each do |reduction|
      items.push Joos::Parser::Item.new(start_symbol, [], reduction, Set.new)
    end

    build_state items
  end

  def build_state items
    items = Array(items)
    raise '#build_state requires a non-empty item array' if items.empty?
    state = Joos::Parser::State.new
    until items.empty?
      item = items.shift
      next unless state.add_item item
      symbol = item.next
      if @non_terminals.include?(symbol)
        new_follow = build_next_follow_from_item item
        @grammar[symbol].each do |reduction|
          items.push Joos::Parser::Item.new(symbol, [], reduction, new_follow)
        end
      end
    end

    state_index = @dfa.add_state state
    add_transitions_to_queue state_index unless @dfa.transitions[state_index]

    puts @dfa.states.size - 1
    state_index
  end

  def add_transitions_to_queue state_index
    needed_transition_symbols = []
    state = @dfa.states[state_index]
    state.items.each do |item|
      symbol = item.next
      next if symbol.nil? || needed_transition_symbols.include?(symbol)
      needed_transition_symbols.push symbol
    end
    @transition_queue[state_index] = needed_transition_symbols
  end

  def build_remaining_states
    until @transition_queue.empty?
      transitions_from_state = {}
      from_state_index, symbols = @transition_queue.shift
      from_state = @dfa.states[from_state_index]
      symbols.each do |symbol|
        items = from_state.new_items_after_transition_on symbol
        new_state = build_state items
        @dfa.add_transition from_state_index, symbol, new_state
      end
    end
  end

  def build_reductions
    @dfa.states.each_with_index do |state, state_index|
      @reductions[state_index] = {}
      state.items.each do |item|
        in_follow_set = Set.new
        if item.after_dot.empty?
          if in_follow_set.intersect? item.follow
            raise "Ambiguous Grammar"
          end
          in_follow_set += item.follow
          @reductions[state_index][item.follow] = [ item.left_symbol, item.before_dot.size ]
        end
      end
    end
  end

    def build_next_follow_from_item item
      symbol = item.next
      new_follow = Set.new
      return nil unless @non_terminals.include? symbol
      all_nullable = true
      item.after_dot.inspect
      item.after_dot[1..-1].to_a.each do |symbol2|
        new_follow += @first[symbol2]
        unless @nullable.include? symbol2
          all_nullable = false
          break
        end
      end

      new_follow += item.follow if all_nullable

      new_follow
    end

end
