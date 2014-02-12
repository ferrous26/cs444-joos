GRAMMAR = {
  rules: {
    AugmentedCompilationUnit: [
      [:CompilationUnit, :EndProgram]
    ],
    CompilationUnit: [
      [:ImportDeclarations], # @todo This case may not be valid in Joos (ASK)
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
      [:Boolean],
      [:Short]
    ],
    ConstantExpression: [
      [:Expression]
    ],
    SubExpression: [
      [:Term, :MoreTerms],
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
      [:Modulo],
      [:Instanceof]
    ],
    Term: [
      [:TermModifier, :Term],
      [:UnmodifiedTerm]
    ],
    UnmodifiedTerm: [
      [:OpenParen, :Expression, :OpenStaple, :CloseStaple, :CloseParen, :Term],
      [:OpenParen, :Expression, :CloseParen, :Term],
      [:OpenParen, :BasicType, :OpenStaple, :CloseStaple, :CloseParen, :Term],
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
      [:QualifiedIdentifier],
      [:QualifiedIdentifier, :IdentifierSuffix],
      [:New, :Creator]
    ],
    Selectors: [
      [:Selector, :Selectors],
      []
    ],
    Selector: [
      [:Dot, :Identifier],
      [:Dot, :Identifier, :Arguments],
      [:OpenStaple, :Expression, :CloseStaple]
    ],
    IdentifierSuffix: [
      [:OpenStaple, :Expression, :CloseStaple], # COME BACK
      [:Arguments]
    ],
    Arguments: [
      [:OpenParen, :Expressions, :CloseParen]
    ],
    Expressions: [
      [:Expression, :MoreExpressions],
      []
    ],
    # @todo I think we can clean this up
    MoreExpressions: [
      [:Comma, :Expression, :MoreExpressions],
      []
    ],
    Creator: [
      [:ArrayCreator],
      [:QualifiedIdentifier],
      [:QualifiedIdentifier, :Arguments]
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
      [:Expression, :Semicolon],
      [:Semicolon],
    ],
    ForInit: [
      [],
      [:Expression],
      [:Type, :VariableDeclarator]
    ],
    ForUpdate: [
      [],
      [:Expression],
      [:VariableDeclarator]
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
      [:Import, :QualifiedImportIdentifier, :Semicolon]
    ],
    QualifiedImportIdentifier: [
      [:Identifier],
      [:Identifier, :Dot, :QualifiedImportIdentifier],
      [:Identifier, :Dot, :Multiply]
    ],
    TypeDeclaration: [
      [:Modifiers, :ClassDeclaration],
      [:Modifiers, :InterfaceDeclaration],
      [:Semicolon] # @note I think this case is dumb, but we handle it
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
      [:QualifiedIdentifier],
      [:QualifiedIdentifier, :Comma, :TypeList]
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
      # Field
      [:Modifiers, :Type, :Identifier, :Semicolon],
      [:Modifiers, :Type, :Identifier, :Equals, :Expression, :Semicolon],
      # Methods
      [:Modifiers, :Void, :Identifier, :MethodDeclaratorRest],
      [:Modifiers, :Type, :Identifier, :MethodDeclaratorRest],
      # Constructor
      [:Modifiers, :Identifier, :ConstructorDeclaratorRest]
    ],
    InterfaceBodyDeclaration: [
      [:Semicolon],
      [:Modifiers, :InterfaceMemberDecl]
    ],
    InterfaceMemberDecl: [
      [:Type, :InterfaceMemberDeclRest],
      [:Void, :InterfaceMemberDeclRest]
    ],
    InterfaceMemberDeclRest: [
      [:Identifier, :FormalParameters, :Semicolon]
    ],
    MethodDeclaratorRest: [
      [:FormalParameters, :MethodBody],
      [:FormalParameters, :Semicolon]
    ],
    ConstructorDeclaratorRest: [
      [:FormalParameters, :MethodBody]
    ],
    FormalParameters: [
      [:OpenParen, :CloseParen],
      [:OpenParen, :FormalParameterList, :CloseParen]
    ],
    FormalParameterList: [
      [:FormalParameter],
      [:FormalParameter, :Comma, :FormalParameterList]
    ],
    FormalParameter: [
      [:Type, :Identifier]
    ],
    MethodBody: [
      [:Block]
    ]
  },

  terminals: [:Package, :Semicolon, :Identifier, :Dot, :IntegerLiteral, :CharacterLiteral, :StringLiteral,
              :BooleanLiteral, :NullLiteral, :Equals, :Instanceof, :LazyOr, :LazyAnd, :EagerOr, :EagerAnd, :Equality, :NotEqual,
              :LessThan, :GreaterThan, :LessOrEqual, :GreaterOrEqual, :Plus, :Minus, :Multiply, :Divide, :Modulo, :OpenParen,
              :CloseParen, :OpenBrace, :CloseBrace, :OpenStaple, :CloseStaple, :Byte, :Char, :Int, :Boolean, :Not, :This, :Void,
              :Class, :New, :Super, :Comma, :If, :Else, :For, :While, :Return, :Public, :Protected, :Static, :Abstract, :Final,
              :Native, :Import, :Implements, :Extends, :Interface, :Short, :EndProgram],

  non_terminals: [:CompilationUnit, :QualifiedIdentifier, :Literal, :Expression, :Type, :ConstantExpression,
                  :SubExpression, :MoreTerms, :Infixop, :Term, :Selectors, :Primary, :Assignment,
                  :IdentifierSuffix, :TermModifier, :Selector, :BasicType, :Arguments, :Expressions, :MoreExpressions,
                  :Creator, :ArrayCreator, :UnmodifiedTerm,
                  :Block, :BlockStatement, :BlockStatements, :LocalVariableDeclarationStatement, :Statement,
                  :ForInit, :ForUpdate, :Modifiers, :Modifier, :VariableDeclarator,
                  :ImportDeclarations, :ImportDeclaration,
                  :TypeDeclaration, :ClassDeclaration, :InterfaceDeclaration, :TypeList, :ClassBody,
                  :ClassBodyDeclarations, :ClassBodyDeclaration, :InterfaceBody, :InterfaceBodyDeclarations, :InterfaceBodyDeclaration,
                  :InterfaceMemberDecl,
                  :MethodDeclaratorRest, :InterfaceMemberDeclRest, :QualifiedImportIdentifier,
                  :ConstructorDeclaratorRest, :FormalParameters, :FormalParameter,
                  :FormalParameterList, :MethodBody, :ArrayType, :AugmentedCompilationUnit],

  start_symbol: :AugmentedCompilationUnit
}
