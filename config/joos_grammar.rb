GRAMMAR = {
  rules: {
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
      [:BasicType]
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
      [:Expression3, :Instanceof, :Type]
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
      [:This, :Arguments],
      [:Super, :SuperSuffix],
      [:Literal],
      [:New, :Creator],
      [:QualifiedIdentifier],
      [:QualifiedIdentifier, :IdentifierSuffix],
      [:BasicType, :BracketsOpt, :Dot, :Class], # COME BACK
      [:Void, :Dot, :Class] # COME BACK
    ],
    IdentifierSuffix: [
      [:OpenStaple, :CloseStaple, :BracketsOpt, :Dot, :Class],
      [:OpenStaple, :Expression, :CloseStaple],
      [:Arguments],
      [:Dot, :Class],
      [:Dot, :This], # COME BACK
      [:Dot, :Super, :Arguments], # COME BACK
      [:Dot, :New, :InnerCreator]
    ],
    PrefixOp: [
      [:Not],
      [:Minus]
    ],
    Selector: [
      [:Dot, :Identifier],
      [:Dot, :Identifier, :Arguments],
      [:Dot, :This],
      [:Dot, :Super, :SuperSuffix], # COME BACK
      [:Dot, :New, :InnerCreator],
      [:OpenStaple, :Expression, :CloseStaple]
    ],
    SuperSuffix: [
      [:Arguments],
      [:Dot, :Identifier],
      [:Dot, :Identifier, :Arguments]
    ],
    BasicType: [
      [:Byte],
      [:Char],
      [:Int],
      [:Boolean]
    ],
    ArgumentsOpt: [
      [:Arguments],
      []
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
      [:OpenStaple, :CloseStaple], # COME BACK
      []
    ],
    Creator: [
      [:QualifiedIdentifier, :ArrayCreatorRest],
      [:QualifiedIdentifier, :ClassCreatorRest]
    ],
    InnerCreator: [
      [:IdentifierSuffix, :ClassCreatorRest]
    ],
    ArrayCreatorRest: [
      [:OpenStaple, :Expression, :CloseStaple]
    ],
    ClassCreatorRest: [
      [:Arguments, :ClassBody], # Not sure if we need this - can classes be defined at run time?
      [:Arguments] # COME BACK
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
      [:ClassOrInterfaceDeclaration], # MAY NOT NEED
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
      [:Native] # COME BACK
    ],
    VariableDeclarator: [
      [:Identifier, :VariableDeclaratorRest]
    ],
    ConstantDeclarator: [
      [:Identifier, :ConstantDeclaratorRest]
    ],
    VariableDeclaratorRest: [
      [:BracketsOpt],
      [:BracketsOpt, :Equals, :VariableInitializer]
    ],
    ConstantDeclaratorRest: [
      [:BracketsOpt, :Equals, :VariableInitializer]
    ],
    VariableDeclaratorId: [
      [:Identifier, :BracketsOpt]
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
      [:Block], # COME BACK
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
  #    [:ConstantDeclaratorRest, :Semicolon], # interface fields not supported
      [:InterfaceMethodDeclaratorRest]
    ],
    MethodDeclaratorRest: [
      [:FormalParameters, :BracketsOpt, :MethodBody],
      [:FormalParameters, :BracketsOpt, :Semicolon]
    ],
    VoidMethodDeclaratorRest: [
      [:FormalParameters, :MethodBody],
      [:FormalParameters, :Semicolon]
    ],
    InterfaceMethodDeclaratorRest: [
      [:FormalParameters, :BracketsOpt, :Semicolon]
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
      [:Type, :VariableDeclaratorId],
      [:Final, :Type, :VariableDeclaratorId]
    ],
    MethodBody: [
      [:Block]
    ]
  },

  terminals: [:Package, :Semicolon, :Identifier, :Dot, :IntegerLiteral, :FloatingPointLiteral, :CharacterLiteral, :StringLiteral,
              :BooleanLiteral, :NullLiteral, :Equals, :Instanceof, :LazyOr, :LazyAnd, :EagerOr, :EagerAnd, :Equality, :NotEqual,
              :LessThan, :GreaterThan, :LessOrEqual, :GreaterOrEqual, :Plus, :Minus, :Multiply, :Divide, :Modulo, :OpenParen,
              :CloseParen, :OpenBrace, :CloseBrace, :OpenStaple, :CloseStaple, :Byte, :Char, :Int, :Boolean, :Not, :This, :Void,
              :Class, :New, :Super, :Comma, :If, :Else, :For, :While, :Return, :Public, :Protected, :Static, :Abstract, :Final,
              :Native, :Import, :Implements, :Extends, :Interface],

  non_terminals: [:CompilationUnit, :QualifiedIdentifier, :Literal, :Expression, :Type, :StatementExpression, :ConstantExpression,
                  :Expression2, :Expression2Rest, :InfixopExpression3, :Infixop, :Expression3, :NegativeInteger, :Selectors, :Primary,
                  :IdentifierSuffix, :PrefixOp, :Selector, :SuperSuffix, :BasicType, :ArgumentsOpt, :Arguments, :Expressions,
                  :BracketsOpt, :Creator, :InnerCreator, :ArrayCreatorRest, :ClassCreatorRest, :VariableInitializer, :ParExpression,
                  :Block, :BlockStatement, :BlockStatements, :LocalVariableDeclarationStatement, :Statement, :MoreStatementExpressions,
                  :ForInit, :ForUpdate, :ModifiersOpt, :Modifier, :VariableDeclarator, :ConstantDeclarator, :VariableDeclaratorRest,
                  :ConstantDeclaratorRest, :ConstructorDeclaratorRest, :VariableDeclaratorId, :ImportDeclarations, :ImportDeclaration,
                  :TypeDeclaration, :ClassOrInterfaceDeclaration, :ClassDeclaration, :InterfaceDeclaration, :TypeList, :CommaType, :ClassBody,
                  :ClassBodyDeclarations, :ClassBodyDeclaration, :InterfaceBody, :InterfaceBodyDeclarations, :InterfaceBodyDeclaration,
                  :MemberDecl, :MethodOrFieldDecl, :MethodOrFieldRest, :InterfaceMemberDecl, :InterfaceMethodOrFieldDecl,
                  :InterfaceMethodOrFieldRest, :MethodDeclaratorRest, :VoidMethodDeclaratorRest, :InterfaceMethodDeclaratorRest,
                  :VoidInterfaceMethodDeclaratorRest, :ConstructorDeclaratorRest, :FormalParameters, :FormalParameter,
                  :CommaFormalParameter, :MethodBody]
}
