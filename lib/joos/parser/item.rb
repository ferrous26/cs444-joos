##
# Item struct to be used by the parser generator
class Joos::Parser::Item

  attr_accessor :left_symbol
  attr_accessor :before_dot
  attr_accessor :after_dot
  attr_accessor :follow

  def == item2
    self.left_symbol == item2.left_symbol &&
    self.before_dot  == item2.before_dot  &&
    self.after_dot   == item2.after_dot
  end

  def merge! item2
    raise "Can not merge #{self.inspect} to #{item2.inspect}" unless self == item2
    
    changed = !(item2.follow - self.follow).empty?
    self.follow += item2.follow

    changed
  end

  def next
    self.after_dot.first
  end

  def complete?
    self.after_dot.empty?
  end

end
