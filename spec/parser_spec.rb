require 'spec_helper'

describe 'Joos 1W parsing' do

  it 'collapses use of unary minus on literal integers'
  it 'does not allow classes to be both final and abstract'
  it 'must ensure methods have a body if it is not abstract/native'
  it 'must ensure methods that are abstract/native do not have a body'
  it 'does not allow abstract methods to be static or final'
  it 'does not allow static methods to be final'
  it 'ensures that native methods are static'
  # void can only be used as a method return type
  it 'does not allow void to be the type of a local decl'
  it 'does not allow initializers in formal parameter lists'
  it 'checks that the class/interface name matches the file name'
  it 'checks that interfaces do not contain fields or constructors'
  it 'does not allow interface methods to be static, final, or native'
  it 'does not allow interface methods to have a body'
  it 'checks that each class has at least one constructor'
  it 'does not allow fields to be final'
  it 'does not allow multi-dimensional arrays (AT ALL)'
  it 'does not allow methods/constructors to use explicit this()/super()'

end
