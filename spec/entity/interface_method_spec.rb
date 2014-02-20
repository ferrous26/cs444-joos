require 'spec_helper'
require 'joos/entity/interface_method'

describe Joos::Entity::InterfaceMethod do

  it 'responds to #to_sym correctly' do
    ast  = get_ast 'J1_interfaceMethod'
    body = ast.TypeDeclaration
              .InterfaceDeclaration
              .InterfaceBody
              .InterfaceBodyDeclarations
    method_ast = body.find { |decl| decl.Modifiers }
    method     = Joos::Entity::InterfaceMethod.new(method_ast, self)
    expect(method.to_sym).to be == :InterfaceMethod
  end

  it 'validates that protected, static, final, and native are not used' do
    [
     'Je_protectedIMethod',
     'Je_staticIMethod',
     'Je_finalIMethod',
     'Je_nativeIMethod'
    ].each do |file|
      ast = get_ast file
      body = ast.TypeDeclaration
                .InterfaceDeclaration
                .InterfaceBody
                .InterfaceBodyDeclarations
      method_ast = body.find { |decl| decl.Modifiers }
      method     = Joos::Entity::InterfaceMethod.new(method_ast, self)
      expect {
        method.validate
      }.to raise_error Joos::Entity::Modifiable::InvalidModifier
    end
  end

end
