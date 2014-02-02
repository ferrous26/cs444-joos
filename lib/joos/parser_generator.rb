require 'joos/version'

##
# Used to generate an LALR(1) parser from the parser definition
class Joos::ParserGenerator

  def initialize grammar
    grammar = Hash(grammar)
    raise TypeError if grammar.empty?
    @grammar = grammar[:rules]
    @terminals = grammar[:terminals]
    @non_terminals = grammar[:non_terminals]
    @states = []
    @transitions = {}
    @transition_queue = {}
    @reductions = {}
    @first = {}
    @nullable = []
    build_first_and_nullable
  end


  ##
  # In order to build the finite state machine to be used as the final LALR(1)
  # parser, an intermediate form is used to contain all metadata needed to
  # construct every state properly. Once all states and transitions are in
  # place,the inetermediate form is reduced to the final machine and returned
  # to the caller.
  #
  # The intermediate form will look as such at any point of its creation:
  #   grammar -> the grammar used to build the parser
  #   start_state -> an alias for the first state in the states array
  #   transition_queue -> a queue of transitions that must be added to the FSM
  #     queued_transition -> a hash of the form { from_state => [:symbol, :symbol, ...] } each :symbol
  #                          represents a symbol that the from_state will need to transition on
  #   transitions -> a hash of the form { from_state => { transition_symbol: next_state } }
  #   states -> an array of the states of the FSM
  #     state -> an array of items (in the LR parser sense) of the form
  #       items -> an array of items (in the LR parser sense) of the form:
  #                [:left_symbol, [symbols_before_dot], [symbols_after_dot], #<Set: follow_symbols>].
  #                Example: [:A, [:B], [:a, :C], #<Set: {:a, :c}>]
  #
  #
  # The final form being returned to the caller will simply be a hash
  # containing the transitions and reductions
  # The transitions will be in the same form as documented above, and the reductions
  # will take the more complicated form of:
  #  { from_state => { #<Set: follow_set> => [left_symbol, right_size] } }
  # where from_state is the current FSM state, follow set is the set of all possible
  # terminals to follow the reduction, left_symbol is the left-hand side of the
  # reduction, and right_size is the size of the right hand side of the reduction.
  #
  def build_parser
    build_start_state
    build_remaining_states
    build_reductions
    { transitions: @transitions, reductions: @reductions }
  end

  def save_parser
    puts @reductions
  end

  def start_state
    @start_state ||= @states.first
  end

  attr_reader :grammar
  attr_reader :terminals
  attr_reader :non_terminals
  attr_reader :states
  attr_reader :transitions
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
                puts left_symbol
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
    return if @start_state
    start_symbol, reductions = @grammar.first
    items = []
    reductions.each do |reduction|
      items.push [start_symbol, [], reduction, Set.new]
    end

    build_state items
  end

  def build_state items
    items = Array(items) # a little coercion never killed anyone
    raise '#build_state requires a non-empty item array' if items.empty?
    state = []
    items.uniq! # ensure all items are unique
    until items.empty?
      item = items.shift
      next unless state.index(item).nil?
      state.push item
      symbol = next_symbol item
      if @non_terminals.include?(symbol)
        new_follow = build_follow_from_item item
        @grammar[symbol].each do |reduction|
          items.push [symbol, [], reduction, new_follow]
        end
      end
    end

    matching_state = find_matching_state state
    return matching_state if matching_state

    @states.push state
    add_transitions_to_queue state

    @states.size - 1 # return index of current state
  end

  def build_follow_from_item item
    symbol = next_symbol item
    return unless @non_terminals.include? symbol
    new_follow = Set.new
    all_nullable = true
    item[2][1..-1].to_a.each do |symbol2|
      new_follow += @first[symbol2]
      unless @nullable.include? symbol2
        all_nullable = false
        break
      end
    end
    new_follow += item.last if all_nullable

    new_follow
  end

  def find_matching_state state
    puts @states.size
    @states.each do |existing_state|
      if (existing_state - state).empty? && (state - existing_state).empty?
        return @states.index existing_state
      end
    end

    nil
  end

  def add_transitions_to_queue state
    needed_transition_symbols = []
    state.each do |item|
      symbol = next_symbol item
      next if symbol.nil? || needed_transition_symbols.include?(symbol)
      needed_transition_symbols.push symbol
    end
    @transition_queue[@states.index(state)] = needed_transition_symbols
  end

  def build_remaining_states
    until @transition_queue.empty?
      transitions_from_state = {}
      state_index, symbols = @transition_queue.shift
      from_state = @states[state_index]
      symbols.each do |symbol|
        items = get_items_from_state_after_transition_on from_state, symbol
        new_state = build_state items
        transitions_from_state[symbol] = new_state
      end

      @transitions[state_index] = transitions_from_state
    end
  end

  def get_items_from_state_after_transition_on state, symbol
    items = []
    state.each do |item|
      if next_symbol(item) == symbol
        left_side = item[1].dup.push(item[2].first)
        right_side = item[2].dup
        right_side.shift
        new_item = [item[0], left_side, right_side, item.last]
        items.push new_item
      end
    end

    items
  end

  def build_reductions
    @states.each do |state|
      state_index = @states.index state

      state.each do |item|
        in_follow_set = Set.new
        if item[2].empty?
          if in_follow_set.intersect? item[3]
            raise "Ambiguous Grammar"
          end
          in_follow_set += item[3]
          @reductions[state_index] = { item[3] => [item[0], item[1]] }
        end
      end
    end
  end

  def next_symbol item
    item[2].first
  end

end
