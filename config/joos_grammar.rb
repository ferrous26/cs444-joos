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
      [:Primary, :Selectors]
    ],
    TermModifier: [
      [:Not],
      [:Minus]
    ],
    Primary: [
      [:OpenParen, :Expression, :CloseParen],
      [:This],
      [:Literal],
      [:New, :Creator],
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
      [:Comma, :Expression, :MoreExpressions]
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
      [:ClassOrInterfaceDeclaration],
      [:Semicolon]
    ],
    ClassOrInterfaceDeclaration: [
      [:ClassDeclaration],
      [:InterfaceDeclaration]
    ],
    ClassDeclaration: [
      [:Modifiers, :Class, :Identifier, :ClassBody],
      [:Modifiers, :Class, :Identifier, :Extends, :Type, :ClassBody],
      [:Modifiers, :Class, :Identifier, :Implements, :TypeList, :ClassBody],
      [:Modifiers, :Class, :Identifier, :Extends, :Type, :Implements, :TypeList, :ClassBody]
    ],
    InterfaceDeclaration: [
      [:Modifiers, :Interface, :Identifier, :InterfaceBody],
      [:Modifiers, :Interface, :Identifier, :Extends, :TypeList, :InterfaceBody]
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
      [:Modifiers, :MemberDecl]
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

  non_terminals: [:CompilationUnit, :QualifiedIdentifier, :Literal, :Expression, :Type, :StatementExpression, :ConstantExpression,
                  :SubExpression, :MoreTerms, :Infixop, :Term, :NegativeInteger, :Selectors, :Primary, :Assignment,
                  :IdentifierSuffix, :TermModifier, :Selector, :BasicType, :ArgumentsOpt, :Arguments, :Expressions, :MoreExpressions,
                  :Creator, :InnerCreator, :ArrayCreator, :ClassCreatorRest, :UnmodifiedTerm,
                  :Block, :BlockStatement, :BlockStatements, :LocalVariableDeclarationStatement, :Statement, :MoreStatementExpressions,
                  :ForInit, :ForUpdate, :Modifiers, :Modifier, :VariableDeclarator,
                  :ConstructorDeclaratorRest, :ImportDeclarations, :ImportDeclaration,
                  :TypeDeclaration, :ClassOrInterfaceDeclaration, :ClassDeclaration, :InterfaceDeclaration, :TypeList, :CommaType, :ClassBody,
                  :ClassBodyDeclarations, :ClassBodyDeclaration, :InterfaceBody, :InterfaceBodyDeclarations, :InterfaceBodyDeclaration,
                  :MemberDecl, :MethodOrFieldDecl, :MethodOrFieldRest, :InterfaceMemberDecl, :InterfaceMethodOrFieldDecl,
                  :InterfaceMethodOrFieldRest, :MethodDeclaratorRest, :VoidMethodDeclaratorRest, :InterfaceMethodDeclaratorRest,
                  :VoidInterfaceMethodDeclaratorRest, :ConstructorDeclaratorRest, :FormalParameters, :FormalParameter,
                  :MoreFormalParameters, :MethodBody, :ArrayType, :AugmentedCompilationUnit],

  start_symbol: :AugmentedCompilationUnit
}
