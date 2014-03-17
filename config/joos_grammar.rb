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
    BooleanLiteral: [
      [:True],
      [:False]
    ],
    Expression: [
      [:Assignment],
      [:SubExpression]
    ],
    Assignment: [
      [:SubExpression, :Equals, :Expression]
    ],
    Type: [
      [:ArrayType],
      [:QualifiedIdentifier],
      [:BasicType]
    ],
    BasicType: [
      [:Byte],
      [:Char],
      [:Int],
      [:Boolean],
      [:Short]
    ],
    ArrayType: [
      [:BasicType, :OpenStaple, :CloseStaple],
      [:QualifiedIdentifier, :OpenStaple, :CloseStaple]
    ],
    SubExpression: [
      # after parsing, all Term nodes will be wrapped in a SubExpression
      # as if the only two rules would be:
      # [SubExpression]
      # [SubExpression, Infixop, SubExpression]
      # except that there will still have to be the terminating case of a Term
      # at some point
      [:Term],
      [:Term, :Infixop, :SubExpression],

      # these cases are transformed into the regular Term-Infixop-SubExpr
      # form during runtime and ArrayType/QualifiedIdentifier are Type wrapped
      [:Term, :Instanceof, :QualifiedIdentifier],
      [:Term, :Instanceof, :QualifiedIdentifier, :Infixop, :SubExpression],
      [:Term, :Instanceof, :ArrayType],
      [:Term, :Instanceof, :ArrayType, :Infixop, :SubExpression]
    ],
    Infixop: [
      # Boolean -> Boolean -> Boolean
      [:LazyOr],
      [:LazyAnd],
      [:EagerOr],
      [:EagerAnd],

      # Anything -> Anything -> Boolean
      [:Equality],
      [:NotEqual],

      # Reference -> Type -> Boolean
      # :Instanceof

      # Numeric -> Numeric -> Int || String -> Anything -> String
      [:Plus],

      # Numeric -> Numeric -> Int
      [:Minus],
      [:Multiply],
      [:Divide],
      [:Modulo],

      # Numeric -> Numeric -> Boolean
      [:LessThan],
      [:GreaterThan],
      [:LessOrEqual],
      [:GreaterOrEqual]
    ],
    Term: [
      [:TermModifier, :Term],

      # These 3 cases all handle casting, so the Expression on the inside
      # has to be a single QualifiedIdentifier
      [:OpenParen, :Expression, :CloseParen, :Term],
      [:OpenParen, :ArrayType,  :CloseParen, :Term],
      [:OpenParen, :BasicType,  :CloseParen, :Term],

      [:Primary, :Selectors],

      # Type does not normall belong here, but in the case of an instanceof
      # call, the right hand operator of instance (which is a Type) will be
      # pushed down into here
      # [:Type]

      [:QualifiedIdentifier],

      # These cases arises from method calls to "this" or local variable
      # array access, and will be transformed into Primary-Selectors and
      # QualifiedIdentifier-Selectors at runtime
      [:QualifiedIdentifier, :Arguments,  :Selectors],
      [:QualifiedIdentifier, :OpenStaple, :Expression,  :CloseStaple, :Selectors]
    ],
    TermModifier: [
      [:Not],
      [:Minus]
    ],
    Primary: [
      [:OpenParen, :Expression, :CloseParen],
      [:This],
      [:New, :Creator],
      [:Literal]
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
    Arguments: [
      [:OpenParen, :CloseParen],
      [:OpenParen, :Expressions, :CloseParen]
    ],
    Expressions: [
      [:Expression],
      [:Expression, :Comma, :Expressions]
    ],
    Creator: [
      [:BasicType, :ArrayCreator],
      [:QualifiedIdentifier, :ArrayCreator],
      [:QualifiedIdentifier, :Arguments]
    ],
    ArrayCreator: [
      [:OpenStaple, :Expression, :CloseStaple]
    ],
    Block: [
      [:OpenBrace, :CloseBrace],
      [:OpenBrace, :BlockStatements, :CloseBrace]
    ],
    BlockStatements: [
      [:BlockStatement],
      [:BlockStatement, :BlockStatements]
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
      [:Semicolon]
    ],
    ForInit: [
      [],
      [:Expression],
      [:Type, :VariableDeclarator]
    ],
    ForUpdate: [
      [],
      [:Expression]
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
      [:Modifiers, :Type, :Identifier, :InterfaceMemberDeclRest],
      [:Modifiers, :Void, :Identifier, :InterfaceMemberDeclRest]
    ],
    InterfaceMemberDeclRest: [
      [:FormalParameters, :Semicolon]
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

  terminals: [:Package, :Semicolon, :Identifier, :Dot, :IntegerLiteral, :CharacterLiteral, :StringLiteral, :True, :False,
              :NullLiteral, :Equals, :Instanceof, :LazyOr, :LazyAnd, :EagerOr, :EagerAnd, :Equality, :NotEqual,
              :LessThan, :GreaterThan, :LessOrEqual, :GreaterOrEqual, :Plus, :Minus, :Multiply, :Divide, :Modulo, :OpenParen,
              :CloseParen, :OpenBrace, :CloseBrace, :OpenStaple, :CloseStaple, :Byte, :Char, :Int, :Boolean, :Not, :This, :Void,
              :Class, :New, :Super, :Comma, :If, :Else, :For, :While, :Return, :Public, :Protected, :Static, :Abstract, :Final,
              :Native, :Import, :Implements, :Extends, :Interface, :Short, :EndProgram],

  non_terminals: [:CompilationUnit, :QualifiedIdentifier, :Literal, :Expression, :Type, :BooleanLiteral,
                  :SubExpression, :Infixop, :Term, :Selectors, :Primary, :Assignment,
                  :TermModifier, :Selector, :BasicType, :Arguments, :Expressions,
                  :Creator, :ArrayCreator,
                  :Block, :BlockStatement, :BlockStatements, :LocalVariableDeclarationStatement, :Statement,
                  :ForInit, :ForUpdate, :Modifiers, :Modifier, :VariableDeclarator,
                  :ImportDeclarations, :ImportDeclaration,
                  :TypeDeclaration, :ClassDeclaration, :InterfaceDeclaration, :TypeList, :ClassBody,
                  :ClassBodyDeclarations, :ClassBodyDeclaration, :InterfaceBody, :InterfaceBodyDeclarations, :InterfaceBodyDeclaration,

                  :MethodDeclaratorRest, :InterfaceMemberDeclRest, :QualifiedImportIdentifier,
                  :ConstructorDeclaratorRest, :FormalParameters, :FormalParameter, :ArrayType,
                  :FormalParameterList, :MethodBody, :AugmentedCompilationUnit],

  start_symbol: :AugmentedCompilationUnit
}
