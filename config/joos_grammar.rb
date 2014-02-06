GRAMMAR = {
  rules: {
    AugmentedCompilationUnit: [
      [:CompilationUnit, :EndProgram]
    ],
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
      [:Assignment],
      [:SubExpression]
    ],
    Assignment: [
      [:SubExpression, :Equals, :SubExpression]
    ],
    Type: [
      [:ArrayType],
      [:QualifiedIdentifier],
      [:BasicType]
    ],
    ArrayType: [
      [:QualifiedIdentifier, :OpenStaple, :CloseStaple],
      [:BasicType, :OpenStaple, :CloseStaple]
    ],
    BasicType: [
      [:Byte],
      [:Char],
      [:Int],
      [:Boolean]
    ],
    ConstantExpression: [
      [:Expression]
    ],
    SubExpression: [
      [:Term, :MoreTerms],
      [:Term, :instanceof, :Type]
    ],
    MoreTerms: [
      [:Infixop, :Term, :MoreTerms],
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
    Term: [
      [:TermModifier, :Term],
      [:UnmodifiedTerm]
    ],
    UnmodifiedTerm: [
      [:OpenParen, :Expression, :CloseParen, :Term],
      [:OpenParen, :BasicType, :CloseParen, :Term],
      [:Primary, :Selectors],
      [:New, :Creator]
    ],
    TermModifier: [
      [:Not],
      [:Minus]
    ],
    Primary: [
      [:OpenParen, :Expression, :CloseParen],
      [:This],
      [:Literal],
      [:QualifiedIdentifier],
      [:QualifiedIdentifier, :IdentifierSuffix]
    ],
    Selectors: [
      [:Selector, :Selectors],
      []
    ],
    Selector: [
      [:Dot, :Identifier],
      [:Dot, :Identifier, :Arguments],
      [:Dot, :This], # COME BACK (qualified this?)
      [:OpenStaple, :Expression, :CloseStaple]
    ],
    IdentifierSuffix: [
      [:OpenStaple, :Expression, :CloseStaple], # COME BACK
      [:Arguments], # @todo What is this case? -- function call?
      [:Dot, :This], # COME BACK (qualified this?)
    ],
    Arguments: [
      [:OpenParen, :Expressions, :CloseParen]
    ],
    Expressions: [
      [:Expression, :MoreExpressions],
      []
    ],
    MoreExpressions: [
      [:Comma, :Expression, :MoreExpressions],
      []
    ],
    Creator: [
      [:ArrayCreator],
      [:QualifiedIdentifier]
    ],
    ArrayCreator: [
      [:QualifiedIdentifier, :OpenStaple, :Expression, :CloseStaple],
      [:BasicType, :OpenStaple, :Expression, :CloseStaple]
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
      [:If, :OpenParen, :Expression, :CloseParen, :Statement],
      [:If, :OpenParen, :Expression, :CloseParen, :Statement, :Else, :Statement],
      [:For, :OpenParen, :ForInit, :Semicolon, :Semicolon, :ForUpdate, :CloseParen, :Statement],
      [:For, :OpenParen, :ForInit, :Semicolon, :Expression, :Semicolon, :ForUpdate, :CloseParen, :Statement],
      [:While, :OpenParen, :Expression, :CloseParen, :Statement],
      [:Return, :Semicolon],
      [:Return, :Expression, :Semicolon],
      [:Semicolon],
      [:Assignment]
    ],
    ForInit: [
      [:Expressions],
      [:Type, :VariableDeclarator]
    ],
    ForUpdate: [
      [:Expressions]
    ],
    Modifiers: [
      [:Modifier, :Modifiers],
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
      [:Identifier, :Equals, :Expression]
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
      [:Modifier, :Modifiers, :ClassOrInterfaceDeclaration],
      [:Semicolon]
    ],
    ClassOrInterfaceDeclaration: [
      [:ClassDeclaration],
      [:InterfaceDeclaration]
    ],
    ClassDeclaration: [
      [:Class, :Identifier, :ClassBody],
      [:Class, :Identifier, :Extends, :QualifiedIdentifier, :ClassBody],
      [:Class, :Identifier, :Implements, :TypeList, :ClassBody],
      [:Class, :Identifier, :Extends, :QualifiedIdentifier, :Implements, :TypeList, :ClassBody]
    ],
    InterfaceDeclaration: [
      [:Interface, :Identifier, :InterfaceBody],
      [:Interface, :Identifier, :Extends, :TypeList, :InterfaceBody]
    ],
    TypeList: [
      [:QualifiedIdentifier, :CommaType]
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
      [:Modifier, :Modifiers, :MemberDecl]
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
      [:Equals, :Expression],
      [:MethodDeclaratorRest]
    ],
    InterfaceBodyDeclaration: [
      [:Semicolon],
      [:Modifiers, :InterfaceMemberDecl]
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
      [:OpenParen, :FormalParameter, :MoreFormalParameters, :CloseParen]
    ],
    MoreFormalParameters: [
      [:Comma, :FormalParameter, :MoreFormalParameters],
      []
    ],
    FormalParameter: [
      [:Type, :Identifier]
    ],
    MethodBody: [
      [:Block]
    ]
  },

  terminals: [:Package, :Semicolon, :Identifier, :Dot, :IntegerLiteral, :FloatingPointLiteral, :CharacterLiteral, :StringLiteral,
              :BooleanLiteral, :NullLiteral, :Equals, :instanceof, :LazyOr, :LazyAnd, :EagerOr, :EagerAnd, :Equality, :NotEqual,
              :LessThan, :GreaterThan, :LessOrEqual, :GreaterOrEqual, :Plus, :Minus, :Multiply, :Divide, :Modulo, :OpenParen,
              :CloseParen, :OpenBrace, :CloseBrace, :OpenStaple, :CloseStaple, :Byte, :Char, :Int, :Boolean, :Not, :This, :Void,
              :Class, :New, :Super, :Comma, :If, :Else, :For, :While, :Return, :Public, :Protected, :Static, :Abstract, :Final,
              :Native, :Import, :Implements, :Extends, :Interface, :EndProgram],

  non_terminals: [:CompilationUnit, :QualifiedIdentifier, :Literal, :Expression, :Type, :ConstantExpression,
                  :SubExpression, :MoreTerms, :Infixop, :Term, :Selectors, :Primary, :Assignment,
                  :IdentifierSuffix, :TermModifier, :Selector, :BasicType, :Arguments, :Expressions, :MoreExpressions,
                  :Creator, :ArrayCreator, :UnmodifiedTerm,
                  :Block, :BlockStatement, :BlockStatements, :LocalVariableDeclarationStatement, :Statement,
                  :ForInit, :ForUpdate, :Modifiers, :Modifier, :VariableDeclarator,
                  :ImportDeclarations, :ImportDeclaration,
                  :TypeDeclaration, :ClassOrInterfaceDeclaration, :ClassDeclaration, :InterfaceDeclaration, :TypeList, :CommaType, :ClassBody,
                  :ClassBodyDeclarations, :ClassBodyDeclaration, :InterfaceBody, :InterfaceBodyDeclarations, :InterfaceBodyDeclaration,
                  :MemberDecl, :MethodOrFieldDecl, :MethodOrFieldRest, :InterfaceMemberDecl, :InterfaceMethodOrFieldDecl,
                  :InterfaceMethodOrFieldRest, :MethodDeclaratorRest, :VoidMethodDeclaratorRest, :InterfaceMethodDeclaratorRest,
                  :VoidInterfaceMethodDeclaratorRest, :ConstructorDeclaratorRest, :FormalParameters, :FormalParameter,
                  :MoreFormalParameters, :MethodBody, :ArrayType, :AugmentedCompilationUnit],

  start_symbol: :AugmentedCompilationUnit
}
