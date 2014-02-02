GRAMMAR = {
  CompilationUnit: [
    [:ImportDeclarations],
    [:ImportDeclarations, :TypeDeclaration],
    [:Package, :QualifiedIdentifier, :Semicolon, :ImportDeclarations],
    [:Package, :QualifiedIdentifier, :Semicolon, :ImportDeclarations, :TypeDeclaration]
  ],
  QualifiedIdentifier: [
    [:Identifier, :Dot, :QualifiedIdentifier],
    [:Identifier]
  ],
  Literal: [
    [:IntegerLiteral],
    [:FloatingPointLiteral],
    [:CharacterLiteral],
    [:StringLiteral],
    [:BooleanLiteral],
    [:NullLiteral]
  ],
  Expression: [
    [:Expression2, :Equals, :Expression2],
    [:Expression2]
  ],
  Type: [
    [:QualifiedIdentifier, :BracketsOpt],
    [:BasicType] # I think :BracketsOpts should be included here...
  ],
  StatementExpression: [
    [:Expression]
  ],
  ConstantExpression: [
    [:Expression]
  ],
  Expression2: [
    [:Expression3, :Expression2Rest],
    [:Expression3]
  ],
  Expression2Rest: [
    [:InfixopExpression3],
    [:Expression3, :instanceof, :Type]
  ],
  InfixopExpression3: [
    [:Infixop, :Expression3, :InfixopExpression3],
    []
  ],
  Infixop: [
    [:LazyOr],
    [:LazyAnd],
    [:EagerOr],
    [:EagerAnd],
    [:Equality],
    [:NotEqual],
    [:LessThan],
    [:GreaterThan],
    [:LessOrEqual],
    [:GreaterOrEqual],
    [:Plus],
    [:Minus],
    [:Multiply],
    [:Divide],
    [:Modulo]
  ],
  Expression3: [
    [:NegativeInteger],
    [:PrefixOp, :Expression3],
    [:OpenParen, :Expression, :CloseParen, :Expression3],
    [:OpenParen, :Type, :CloseParen, :Expression3],
    [:Primary, :Selectors]
  ],
  NegativeInteger: [
    [:Minus, :Integer, :Selectors]
  ],
  Selectors: [
    [:Selectors, :Selector],
    []
  ],
  Primary: [
    [:OpenParen, :Expression, :CloseParen],
    [:This],
    [:Literal],
    [:New, :Creator],
    [:QualifiedIdentifier],
    [:QualifiedIdentifier, :IdentifierSuffix],
  ],
  IdentifierSuffix: [
    [:OpenStaple, :Expression, :CloseStaple], # COME BACK
    [:Arguments], # @todo What is this case?
    [:Dot, :This], # COME BACK (qualified this?)
  ],
  PrefixOp: [
    [:Not],
    [:Minus]
  ],
  Selector: [
    [:Dot, :Identifier],
    [:Dot, :Identifier, :Arguments],
    [:Dot, :This], # COME BACK (qualified this?)
    [:OpenStaple, :Expression, :CloseStaple]
  ],
  BasicType: [
    [:Byte],
    [:Char],
    [:Int],
    [:Boolean]
  ],
  Arguments: [
    [:OpenParen, :CloseParen],
    [:OpenParen, :Expressions, :CloseParen]
  ],
  Expressions: [
    [:Expression, :Comma, :Expressions],
    [:Expression]
  ],
  BracketsOpt: [
    [:OpenStaple, :CloseStaple],
    []
  ],
  Creator: [
    [:QualifiedIdentifier, :ArrayCreatorRest],
    [:QualifiedIdentifier]
  ],
  ArrayCreatorRest: [
    [:OpenStaple, :Expression, :CloseStaple]
  ],
  VariableInitializer: [
    [:Expression]
  ],
  ParExpression: [
    [:OpenParen, :Expression, :CloseParen]
  ],
  Block: [
    [:OpenBrace, :BlockStatements, :CloseBrace]
  ],
  BlockStatements: [
    [:BlockStatement, :BlockStatements],
    []
  ],
  BlockStatement: [
    [:LocalVariableDeclarationStatement],
    [:Statement]
  ],
  LocalVariableDeclarationStatement: [
    [:Type, :VariableDeclarator, :Semicolon]
  ],
  Statement: [
    [:Block],
    [:If, :ParExpression, :Statement],
    [:If, :ParExpression, :Statement, :Else, :Statement],
    [:For, :OpenParen, :ForInitOpt, :Semicolon, :Semicolon, :ForUpdateOpt, :CloseParen, :Statement],
    [:For, :OpenParen, :ForInitOpt, :Semicolon, :Expression, :Semicolon, :ForUpdateOpt, :CloseParen, :Statement],
    [:While, :ParExpression, :Statement],
    [:Return],
    [:Return, :Expression],
    [:Semicolon],
    [:ExpressionStatement]
  ],
  MoreStatementExpressions: [
    [:Comma, :StatementExpression, :MoreStatementExpressions],
    []
  ],
  ForInit: [
    [:StatementExpression, :MoreStatementExpressions],
    [:Type, :VariableDeclarator]
  ],
  ForUpdate: [
    [:StatementExpression, :MoreStatementExpressions]
  ],
  ModifiersOpt: [
    [:Modifier, :ModifiersOpt],
    []
  ],
  Modifier: [
    [:Public],
    [:Protected],
    [:Static],
    [:Abstract],
    [:Final],
    [:Native]
  ],
  VariableDeclarator: [
    [:Identifier, :VariableDeclaratorRest]
  ],
  ConstantDeclarator: [
    [:Identifier, :ConstantDeclaratorRest]
  ],
  VariableDeclaratorRest: [
    [:Equals, :VariableInitializer]
  ],
  ConstantDeclaratorRest: [
    [:Equals, :VariableInitializer]
  ],
  VariableDeclaratorId: [
    [:Identifier]
  ],
  ImportDeclarations: [
    [:ImportDeclaration, :ImportDeclarations],
    []
  ],
  ImportDeclaration: [
    [:Import, :QualifiedIdentifier, :Semicolon],
    [:Import, :QualifiedIdentifier, :Dot, :Multiply, :Semicolon]
  ],
  TypeDeclaration: [
    [:ClassOrInterfaceDeclaration],
    [:Semicolon]
  ],
  ClassOrInterfaceDeclaration: [
    [:ModifiersOpt, :ClassDeclaration],
    [:ModifiersOpt, :InterfaceDeclaration]
  ],
  ClassDeclaration: [
    [:Class, :Identifier, :ClassBody],
    [:Class, :Identifier, :Extends, :Type, :ClassBody],
    [:Class, :Identifier, :Implements, :TypeList, :ClassBody],
    [:Class, :Identifier, :Extends, :Type, :Implements, :TypeList, :ClassBody]
  ],
  InterfaceDeclaration: [
    [:Interface, :Identifier, :InterfaceBody],
    [:Interface, :Identifier, :Extends, :TypeList, :InterfaceBody]
  ],
  TypeList: [
    [:Type, :CommaType]
  ],
  CommaType: [
    [:Comma, :Type, :CommaType],
    []
  ],
  ClassBody: [
    [:OpenBrace, :ClassBodyDeclarations, :CloseBrace]
  ],
  ClassBodyDeclarations: [
    [:ClassBodyDeclaration, :ClassBodyDeclarations],
    []
  ],
  InterfaceBody: [
    [:OpenBrace, :InterfaceBodyDeclarations, :CloseBrace]
  ],
  InterfaceBodyDeclarations: [
    [:InterfaceBodyDeclaration, :InterfaceBodyDeclarations],
    []
  ],
  ClassBodyDeclaration: [
    [:Semicolon],
    [:ModifiersOpt, :MemberDecl]
  ],
  MemberDecl: [
    [:MethodOrFieldDecl],
    [:Void, :Identifier, :MethodDeclaratorRest],
    [:Identifier, :ConstructorDeclaratorRest]
  ],
  MethodOrFieldDecl: [
    [:Type, :Identifier, :MethodOrFieldRest]
  ],
  MethodOrFieldRest: [
    [:VariableDeclaratorRest],
    [:MethodDeclaratorRest]
  ],
  InterfaceBodyDeclaration: [
    [:Semicolon],
    [:ModifiersOpt, :InterfaceMemberDecl]
  ],
  InterfaceMemberDecl: [
    [:InterfaceMethodOrFieldDecl],
    [:Void, :Identifier, :VoidInterfaceMethodDeclaratorRest]
  ],
  InterfaceMethodOrFieldDecl: [
    [:Type, :Identifier, :InterfaceMethodOrFieldRest]
  ],
  InterfaceMethodOrFieldRest: [
    [:InterfaceMethodDeclaratorRest]
  ],
  MethodDeclaratorRest: [
    [:FormalParameters, :MethodBody],
    [:FormalParameters, :Semicolon]
  ],
  VoidMethodDeclaratorRest: [
    [:FormalParameters, :MethodBody],
    [:FormalParameters, :Semicolon]
  ],
  InterfaceMethodDeclaratorRest: [
    [:FormalParameters, :Semicolon]
  ],
  VoidInterfaceMethodDeclaratorRest: [
    [:FormalParameters, :Semicolon]
  ],
  ConstructorDeclaratorRest: [
    [:FormalParameters, :MethodBody]
  ],
  FormalParameters: [
    [:OpenParen, :CloseParen],
    [:OpenParen, :FormalParameter, :CommaFormalParameter, :CloseParen]
  ],
  CommaFormalParameter: [
    [:Comma, :FormalParameter, :CommaFormalParameter],
    []
  ],
  FormalParameter: [
    [:Type, :VariableDeclaratorId]
  ],
  MethodBody: [
    [:Block]
  ]
}
