require 'spec_helper'
require 'joos/entity/method'

describe Joos::Entity::Method do

  outer = self

  extract = lambda do |file|
    ast = get_ast file
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    meth_ast = body.find { |decl| decl.MethodDeclaratorRest }
    [meth_ast, Joos::Entity::Method.new(meth_ast, self)]
  end

  it 'takes a node at init and parses it correctly' do
    ast, method = extract['J1_fullyLoadedMethod']

    expect(method.name.to_s).to be    == 'hello'
    expect(method.modifiers).to be    == [:Final, :Public]
    expect(method.type).to be         == (ast.Void || ast.Type)
    expect(method.body).to be         == (ast
                                          .MethodDeclaratorRest
                                          .MethodBody
                                          .Block)
    expect(method.parent).to be       == outer

    expect(method.parameters.size).to be == 1
    expect(method.parameters.first).to be_kind_of Joos::Entity::FormalParameter
  end

  it 'sets the default modifiers to be empty' do
    _, method = extract['Je_methodNoModifiers']
    expect(method.modifiers).to be_empty
  end

  it 'sets the default body to be nil' do
    _, method = extract['Je_staticMethodNoBody']
    expect(method.body).to be_nil
  end

  it 'responds to #to_sym correctly' do
    _, method = extract['Je_finalMethodNoBody']
    expect(method.to_sym).to be == :Method
  end

  it 'validates that abstract and static are not both used' do
    _, method = extract['Je_abstractStaticMethod']
    expect { method.validate }.to raise_error(/Abstract or Static/)
  end

  it 'validates that abstract and final not used together' do
    _, method = extract['Je_abstractFinalMethod']
    expect { method.validate }.to raise_error(/Abstract or Static or Final/)
  end

  it 'validates that static methods are not final' do
    _, method = extract['Je_staticFinalMethod']
    expect { method.validate }.to raise_error(/Static or Final/)
  end

  it 'validates that native methods are static' do
    _, method = extract['Je_nonStaticNativeMethod']
    expect { method.validate }.to raise_error(/must be declared static/)

    _, method = extract['J1_staticNativeMethod']
    expect { method.validate }.to_not raise_error
  end

  it 'validates that native and abstract methods do not have a body' do
    _, method = extract['J1_nativeMethodNoBody']
    expect { method.validate }.to_not raise_error

    _, method = extract['J1_abstractMethodNoBody']
    expect { method.validate }.to_not raise_error

    _, method = extract['Je_nativeMethodWithBody']
    expect { method.validate }.to raise_error

    _, method = extract['Je_abstractMethodwithBody']
    expect { method.validate }.to raise_error
  end

  it 'validates that non-native and non-abstract methods have a body' do
    _, method = extract['J1_finalMethodWithBody']
    expect { method.validate }.to_not raise_error

    _, method = extract['Je_finalMethodNoBody']
    expect { method.validate }.to raise_error

    _, method = extract['J1_staticMethodWithBody']
    expect { method.validate }.to_not raise_error

    _, method = extract['Je_staticMethodNoBody']
    expect { method.validate }.to raise_error
  end

end
