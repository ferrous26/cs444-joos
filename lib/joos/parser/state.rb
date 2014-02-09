require 'joos/parser/item'

# state struct to be used by the parser generator
Joos::Parser::State = Struct.new :items do
  def initialize items = []
    items = Array(items)
    items.each do |item|
      unless item.is_a? Joos::Parser::Item
        raise "Joos::Parser::State#initialize expects an array of items. Instead found #{item.inspect}"
      end
    end

    self.items = items
  end

  def == state2
    (self.items - state2.items).empty? && (state2.items - self.items).empty?
  end

  def add_item item
    unless item.is_a?(Joos::Parser::Item)
      raise "Attempted to add #{item}, which is not an item, to state
              #{state_number}"
    end

    matching_item = self.items.find { |state_item| state_item == item }
    if matching_item
      matching_item.merge!(item)
    else
      self.items.push item

      true
    end
  end

  def new_items_after_transition_on symbol
    items = []
    self.items.each do |item|
      if item.next == symbol && !item.after_dot.empty?
        items.push Joos::Parser::Item.new(item.left_symbol,
                                          item.before_dot + [item.after_dot.first],
                                          item.after_dot[1..-1],
                                          item.follow)
      end
    end

    items
  end

  def reductions
    reduction_hash = {}
    added_to_follow = Set.new
    complete_items = self.items.select do |item|
      item.complete?
    end
    complete_items.each do |item|
      if added_to_follow.intersect? item.follow
        raise "Ambiguous Grammar - #{self.items.inspect}"
      end
      added_to_follow += item.follow
      reduction_hash[item.follow] = [item.left_symbol, item.before_dot.size]
    end

    reduction_hash
  end
end

