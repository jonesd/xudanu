'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:37 pm'!

Scanner subclass: #Parser
	instanceVariableNames: '
		builder {ProgramNodeBuilder}
		requestor {nil | CompilerErrorHandler | ByteCodeStream}
		oldLanguage {Boolean}
		newLanguage {Boolean}
		extendedLanguage {Boolean}
		parseNode {ProgramNode | Symbol | String | Number | Array | Boolean | UndefinedObject}
		failBlock {BlockClosure}
		endTemps {Integer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Public Access'!
Parser comment:
'The Parser parses Smalltalk syntax and creates a parse tree.  It looks one token ahead, i.e. token and tokenType contain the next token to be inspected.

Instance Variables:
	builder		<ProgramBuilder>   for building parse nodes 
	requestor	<Object>   object from which parsing was invoked.  If not nil, this object will be sent error:with:from: or error:with:at: prior to evaluating the failBlock 
	oldLanguage	<Boolean>   if true, accept the "Blue" Book syntax 
	newLanguage	<Boolean>   if true, accept the 1987 standard syntax 
	extendedLanguage	<Boolean>   if true, accept ParcPlace Systems extensions (currently, just type declarations) 
	parseNode	<ParseNode>   result of current (recursive descent) parse 
	failBlock	<BlockContext>   to be evaluated in case of parse errors 
	endTemps	<Integer>   mark of last temp; points to vert bar, or last char of pattern if no temps declared 
'!



!Parser methodsFor: 'initialize-release'!

initScanner
	super initScanner.
	typeTable _ TypeTable.
	"Default language choice:"
	oldLanguage _ true.
	newLanguage _ true.
	extendedLanguage _ true! !

!Parser methodsFor: 'public access'!

parse: sourceStream class: class noPattern: noPattern context: ctxt
	notifying: req builder: aBuilder saveComments: savec ifFail: aBlock
	"Answer with a parse tree.  noPattern is true for doIts (Compiler evaluate)."

	| meth |
	self
		init: sourceStream
		notifying: req
		saveComments: savec
		failBlock: [^aBlock value].
	builder _ aBuilder.
	failBlock _ aBlock.
	meth _ self method: noPattern context: ctxt.
	builder _ failBlock _ requestor _ parseNode _ nil. "break cycles & mitigate refct overflow"
	^meth!

parse: sourceStream class: class noPattern: noPattern context: ctxt notifying: req ifFail: aBlock
	"Answer with a parse tree.  noPattern is true for doIts (Compiler evaluate)."

	^self
		parse: sourceStream
		class: class
		noPattern: noPattern
		context: ctxt
		notifying: req
		builder: ProgramNodeBuilder new
		saveComments: true
		ifFail: aBlock!

parse: aString class: class notifying: req 
	"Answer with a parse tree."
	"Parser new 
		parse: (Parser sourceCodeStringAt: #parse:class:notifying:)
		class: Parser
		notifying: nil"
	
	^self
		parse: (ReadStream on: aString asString)
		class: class
		noPattern: false
		context: nil
		notifying: req
		builder: ProgramNodeBuilder new
		saveComments: true
		ifFail: [^nil]!

parseArgsAndTemps: aString notifying: req 
	"(for explainer) parse the string and answer with an Array of Strings (the arg and temp names)"

	^self
		initPattern: aString
		notifying: req
		saveComments: false
		return: [:pattern |
			self primitive: [:n].  "skip primitive if any"
			((pattern at: 2) , self temporaries) collect: [:param | param name asString]]!

parseMethodComment: aString setPattern: aBlock 
	"Answer with the method comment for this string."

	self
		initPattern: aString
		notifying: nil
		saveComments: true
		return: aBlock.
	currentComment == nil
		ifTrue: [^OrderedCollection new]
		ifFalse: [^currentComment]!

parsePattern: aString 
	"Answer with the selector for this method string"

	^self
		initPattern: aString
		notifying: nil
		saveComments: true
		return: [:pattern | pattern]!

parseSelector: aString 
	"Answer with the selector for this method string"

	^self
		initPattern: aString
		notifying: (SilentCompilerErrorHandler new failBlock: [])
		saveComments: false
		return: [:pattern | pattern at: 1]!

parseTypedVars: aString notifying: req 
	"For instance variable types."

	| vars  |
	self init: (ReadStream on: aString asString)
		notifying: req
		saveComments: true
		failBlock: [^nil].
	builder _ ProgramNodeBuilder new.
	vars _ OrderedCollection new.
	[tokenType == #word]
		whileTrue: [vars add: self argument].
	builder _ failBlock _ nil.  "break cycles"
	^vars!

parseTypeExpression: aString notifying: req 
	"For instance variable types."

	| result  |
	self init: (ReadStream on: aString asString)
		notifying: req
		saveComments: true
		failBlock: [^nil].
	builder _ ProgramNodeBuilder new.
	result _ self typeExpression.
	builder _ failBlock _ nil.  "break cycles"
	^result! !

!Parser methodsFor: 'expression types-true/false'!

constant
	"Recognize a constant (named, number, character,
	string, or quoted).  Leave the constant value in parseNode."
	| size |
	tokenType == #word
		ifTrue: 
			["Special check for nil / true / false"
			size _ token size.
			size = 5
				ifTrue: [token = 'false' ifTrue: [self scanToken.  parseNode _ false.  ^true]]
				ifFalse:
					[size = 4
						ifTrue: [token = 'true' ifTrue: [self scanToken.  parseNode _ true.  ^true]]
						ifFalse:
							[size = 3
								ifTrue: [token = 'nil' ifTrue: [self scanToken.  parseNode _ nil.  ^true]]]].
			^false].
	(tokenType == #string or: [tokenType == #number or: [tokenType == #character]])
		ifTrue: 
			[parseNode _ token.
			self scanToken.
			^true].
	(token == #- and: [hereChar notNil and: [hereChar isDigit]])
		ifTrue: 
			[self scanToken.  "skip the -, read the number"
			parseNode _ token negated.
			self scanToken.
			^true].
	tokenType == #literalQuote
		ifFalse:
			[^false].
	"This is a quoted literal"
	self scanToken.  "skip the #"
	(tokenType == #word or: [tokenType == #binary or: [tokenType == #verticalBar or: [newLanguage and: [tokenType == #string]]]])
		ifTrue:
			[parseNode _ token asSymbol.  self scanToken.  ^true].
	tokenType == #keyword
		ifTrue:
			["Scan a multi-keyword literal."
			parseNode _ token.
			[hereChar notNil and: [hereChar isLetter]]
				whileTrue:
					[self scanToken.
					parseNode _ parseNode , token].
			self scanToken.
			parseNode _ parseNode asSymbol.
			^true].
	tokenType == #leftParenthesis
		ifTrue:
			[self scanToken.
			self arrayLiteral.
			^true].
	^self expected: 'word, binary, keyword, or ('!

expression
	"Recognize an expression."
	| start |
	tokenType == #word
		ifTrue:
			[self primaryExpression.
			start _ mark.
			tokenType == #leftArrow
				ifTrue:
					[self assignment: parseNode startingAt: start.
					^true]
				ifFalse:
					[(tokenType == #colon and: [hereChar = $= and: [newLanguage]])
						ifTrue:
							[self step.  "skip the ="
							self assignment: parseNode startingAt: start.
							^true]]]
		ifFalse:
			[self primaryExpression ifFalse: [^false]].
	(self messagePart: 3 repeat: true)
		ifTrue:
			[tokenType == #semicolon ifTrue: [self cascade]].
	^true!

primaryExpression
	| start |
	tokenType == #word
		ifTrue: 
			[start _ mark.
			self constant  "check for nil / true / false"
				ifTrue:
					[self parseNode: (self newLiteralAt: start)]
				ifFalse:
					[self parseNode: (builder newVariableName: token).
					parseNode sourcePosition: mark.
					self scanToken].
			^true].
	tokenType == #leftBracket
		ifTrue: 
			[self blockExpression.
			^true].
	tokenType == #leftParenthesis
		ifTrue: 
			[self scanToken.
			self expression ifFalse: [^self expected: 'expression'].
			tokenType == #rightParenthesis
				ifFalse: [^self expected: 'right parenthesis'].
			self scanToken.
			^true].
	start _ mark.
	self constant
		ifTrue:
			[self parseNode: (self newLiteralAt: start).
			^true].
	^false!

superMessage
	(self messagePart: 3 repeat: true)
		ifFalse: [self expected: 'Message'].
	tokenType == #semicolon ifTrue: [].
	^true! !

!Parser methodsFor: 'expression types-success/error'!

arrayLiteral
	| s |
	s _ WriteStream on: (Array new: 16).
	[tokenType = #rightParenthesis]
		whileFalse: 
			[tokenType == #doIt ifTrue:
				[^self expected: 'array element or right parenthesis'].
			self arrayLiteralElement.
			s nextPut: parseNode].
	parseNode _ s contents.
	self scanToken!

arrayLiteralElement
	"It's just too hard to accept both
	syntaxes.  New takes precedence."
	newLanguage ifTrue:
		[self constant ifTrue: [^self]].
	oldLanguage ifFalse:
		[^self expected: 'array element'].
	tokenType = #leftParenthesis ifTrue:
		[self scanToken.
		self arrayLiteral.
		^self].
	self scanLitToken.
	parseNode _ token.
	self scanToken!

assignment: var startingAt: start
	"variable $_ (':=') expression => AssignmentNode"
	| leftArrow |
	leftArrow _ token = $_.
	self scanToken.  "skip the _ or :="
	self expression ifFalse: [^self expected: 'Expression'].
	self parseNode: (builder 
				newAssignmentVariable: var
				value: parseNode
				leftArrow: leftArrow).
	parseNode sourcePosition: (start to: self endOfLastToken)!

blockExpression
	"$[ ($: var)* temporaries statements $] => BlockNode"

	| start argNodes statementComment | 
	start _ mark.
	self scanToken.  "skip ]"
	argNodes _ #().
	[tokenType == #colon
	"gather any arguments"]
		whileTrue: 
			[self scanToken.
			argNodes _ argNodes copyWith: self argument].
	(argNodes size > 0 and: [tokenType ~~ #rightBracket and: [(self match: #verticalBar) not]])
		ifTrue: [^self expected: 'Vertical bar'].
	statementComment _ currentComment.
	currentComment _ nil.
	self statementsArgs: argNodes temps: (newLanguage ifTrue: [nil] ifFalse: [#()]).
	tokenType == #rightBracket
		ifFalse: [^self expected: 'Period or right bracket'].
	"restore the current comment for the statement."
	currentComment == nil 
		ifTrue: [currentComment _ statementComment] 
		ifFalse: [currentComment _ statementComment addAll: currentComment].
	self scanToken.
	parseNode sourcePosition: (start to: self endOfLastToken)!

cascade
	" {; message} => CascadeNode"

	| rcvr msgs |
	rcvr _ parseNode receiver.
	msgs _ OrderedCollection with: parseNode.
	[self match: #semicolon]
		whileTrue: 
			[self parseNode: rcvr.
			(self messagePart: 3 repeat: false)
				ifFalse: [^self expected: 'Cascade'].
			msgs addLast: parseNode].
	self parseNode: (builder newCascadeReceiver: rcvr messages: msgs)!

statementsArgs: argNodes temps: oldTemps
	"oldTemps is nil if temps should be parsed.
	This is for compatibility with the old language,
	so that temps can be parsed before the
	primitive specification."
	| tempNodes stmts start blockComment returnStart |
	oldTemps == nil
		ifTrue:
			[tempNodes _ self temporaries]
		ifFalse:
			[tempNodes _ oldTemps].
	stmts _ OrderedCollection new.
	"give initial comment to block, since others trail statements"
	blockComment _ currentComment.
	currentComment _ nil.
	start _ endTemps.
	[tokenType == #upArrow
		ifTrue: 
			[returnStart _ mark.
			self scanToken.
			self expression
				ifFalse: [^self expected: 'Expression to return'].
			self addComment.
			self parseNode: (builder newReturnValue: parseNode).
			parseNode sourcePosition: (returnStart to: self endOfLastToken).
			stmts addLast: parseNode.
			self match: #period.  "allow optional trailing . after ^"
			false]
		ifFalse: 
			[self expression
				ifTrue: 
					[self addComment.
					stmts addLast: parseNode.
					self match: #period]
				ifFalse: 
					[self addComment.
					false]]]
		whileTrue: [].
	(stmts size = 1 
	 and: [blockComment == nil 
	 and: [self parseNode: (stmts first).  parseNode sourcePosition == nil 
	 and: [tempNodes isEmpty]]])
		ifTrue:
			["No point in building a sequence"]
		ifFalse:
			[self parseNode: (builder newSequenceTemporaries: tempNodes statements: stmts).
			parseNode comment: blockComment].
	parseNode sourcePosition: (start to: self endOfLastToken+1).
	self parseNode: (builder newBlockArguments: argNodes body: parseNode)!

temporaries
	"[ '|' (variable) ]  (variable, ..., variable)* "

	| vars |
	(self match: #verticalBar)
		ifFalse: [endTemps _ mark.  ^#()].	"no temps"
	vars _ OrderedCollection new.
	[tokenType == #word]
		whileTrue: [vars addLast: self argument].
	endTemps _ mark.  "stream position of vertical bar"
	(self match: #verticalBar)
		ifTrue: [^vars].
	^self expected: 'Vertical bar'! !

!Parser methodsFor: 'expression types-^value/error'!

argument
	| arg argType node startPos |
	tokenType == #word
		ifFalse: [^self expected: 'Argument name'].
	arg _ builder newVariableName: token.
	arg sourcePosition: (startPos _ mark).
	self scanToken.
	argType _ self typeExpression.
	node _ builder newParameterVariable: arg type: argType.
	node sourcePosition: (startPos to: self endOfLastToken).
	^node!

method: fromDoIt context: ctxt 
	"pattern [ | temporaries ] block => MethodNode"

	| start pat block prim messageComment methodNode tempNodes |
	start _ mark.
	pat _ fromDoIt 
		ifTrue: 
			[ctxt == nil
				ifTrue: [Array with: #DoIt with: #() with: nil]
				ifFalse: [Array 
							with: #DoItIn: 
							with: (Array with:
									(builder newParameterVariable:
										(builder newVariableName: 'DOITCONTEXT')))
							with: nil]]
		ifFalse:
			[self typedPattern].
	"pat={selector, arguments}"
	messageComment _ currentComment.
	currentComment _ nil.
	"Parse temporaries before primitive,
	to allow for old language."
	tempNodes _ tokenType == #verticalBar
		ifTrue: [self temporaries]
		ifFalse:
			[newLanguage
				ifTrue: [nil]
				ifFalse: [#()]].
	fromDoIt ifFalse: [self primitive: [:n |
		(tempNodes notNil and: [oldLanguage not])
			ifTrue: [^self notify: 'Primitive must precede temps'].
		prim _ n]].
	self statementsArgs: (pat at: 2) temps: tempNodes.
	block _ parseNode.
	tokenType == #doIt ifFalse: [^self expected: 'Nothing more'].
	methodNode _ builder
		newMethodSelector: (pat at: 1)
		primitive: prim
		block: block
		type: (pat at: 3).
	methodNode comment: messageComment.
	methodNode sourcePosition: (start to: self endOfLastToken).
	^methodNode!

pattern
	"unarySelector | binarySelector arg | keyword arg {keyword arg} => 
	{selector, arguments}"

	| args selector |
	tokenType == #word 
		ifTrue:
			[selector _ token asSymbol.
			self scanToken.
			^Array with: selector with: #()].
	(tokenType == #binary or: [tokenType == #verticalBar])
		ifTrue: 
			[selector _ token asSymbol.
			self scanToken.
			args _ Array with: self argument.
			^Array with: selector with: args].
	tokenType == #keyword
		ifTrue: 
			[selector _ token.
			self scanToken.
			args _ Array with: self argument.
			[tokenType == #keyword]
				whileTrue: 
					[selector _ selector , token.
					self scanToken.
					args _ args copyWith: self argument].
			^Array with: selector asSymbol with: args].
	^self expected: 'Message pattern'!

primitive: resultBlock
	| n |
	(self matchToken: #<)
		ifFalse: [^nil].
	(self matchToken: 'primitive:')
		ifFalse: [^self expected: 'primitive:'].
	((tokenType == #number and: [token isInteger])
	  or: [newLanguage and: [tokenType == #string]])
		ifTrue: [n _ token.  self scanToken]
		ifFalse:
			[newLanguage
				ifTrue: [^self expected: 'Integer or string']
				ifFalse: [^self expected: 'Integer']].
	(self matchToken: #>)
		ifFalse: [^self expected: '>'].
	^resultBlock value: n!

typedPattern
	"unarySelector | binarySelector arg | keyword arg {keyword arg} => 
	{selector, arguments}"

	| args selector type |
	type _ self typeExpression.
	tokenType == #word
		ifTrue: 
			[selector _ token asSymbol.
			self scanToken.
			^Array
				with: selector
				with: #()
				with: type].
	(tokenType == #binary or: [tokenType == #verticalBar])
		ifTrue: 
			[selector _ token asSymbol.
			self scanToken.
			args _ Array with: self argument.
			^Array
				with: selector
				with: args
				with: type].
	tokenType == #keyword
		ifTrue: 
			[selector _ token.
			self scanToken.
			args _ Array with: self argument.
			[tokenType == #keyword]
				whileTrue: 
					[selector _ selector , token.
					self scanToken.
					args _ args copyWith: self argument].
			^Array
				with: selector asSymbol
				with: args
				with: type].
	^self expected: 'Message pattern'!

typeExpression
	| argType |
	argType _ nil.
	(extendedLanguage and: [self match: #leftCurly])
		ifTrue: 
			[self expression ifFalse: [self expected: 'Type expression'].
			argType _ parseNode.
			(self match: #rightCurly)
				ifFalse: [self expected: '}']].
	^argType! !

!Parser methodsFor: 'comparing'!

match: type 
	"Answer with true if next tokens type matches."

	tokenType == type
		ifTrue: 
			[self scanToken.
			^true].
	^false!

matchToken: thing 
	"Matches the token, not its type."

	token = thing ifTrue: [self scanToken. ^true].
	^false! !

!Parser methodsFor: 'scanning'!

endOfLastToken
	"Answer the position of end of last expression parsed."

	^prevEnd! !

!Parser methodsFor: 'error handling'!

abort
	| exitBlock |
	builder == nil
		ifFalse: [builder release. builder _ nil]. "break cycle"
	exitBlock _ failBlock.
	failBlock _ nil.
	^exitBlock value!

expected: aString 
	"Notify that there is a problem at current token."

	^ self notify: aString , ' expected' at: mark!

notify: aString 
	"Notify problem at token before current token."

	^self notify: aString at: mark!

notify: string at: location 
	requestor error: #syntax with: string , ' ->' at: location.
	self abort!

offEnd: aString 
	"Notify a problem beyond 'here' (in lookAhead token).  Don't be offEnded!!"

	^ self notify: aString at: mark! !

!Parser methodsFor: 'protected:'!

addComment
	parseNode notNil
		ifTrue: 
			[parseNode comment: currentComment.
			currentComment _ nil]!

{ProgramNode} fetchParseNode

	(parseNode isKindOf: ProgramNode)
		ifTrue: [^parseNode]
		ifFalse: [^nil]!

init: sourceStream notifying: req saveComments: savec failBlock: aBlock 
	requestor _ req.
	failBlock _ aBlock.
	saveComments _ savec.
	super scan: sourceStream!

initPattern: aString notifying: req saveComments: savec return: aBlock
	| result |
	self
		init: (ReadStream on: aString asString)
		notifying: req
		saveComments: savec 
		failBlock: [^nil].
	builder _ ProgramNodeBuilder new.
	result _ aBlock value: self typedPattern.
	builder _ failBlock _ nil.  "break cycles"
	^result!

makeNewSymbol: aString startingAt: start withPositions: positionsOrNil
	| sym |
	sym _ Symbol findInterned: aString.
	sym notNil ifTrue: [^sym].
	requestor ~~ nil ifTrue: [requestor
		error: #newSelector
		with: aString
		at: (Array with: (start to: mark - 1) with: positionsOrNil)].
	^aString asSymbol!

{LiteralNode} newLiteralAt: start {Integer}

	| result |
	result _ (builder newLiteralValue: parseNode).
	result sourcePosition: (start to: self endOfLastToken).
	^result!

{void} parseNode: pn {ProgramNode}

	(pn == nil or: [pn isKindOf: ProgramNode]) assert.
	parseNode _ pn.! !

!Parser methodsFor: 'private: private-expression types'!

messagePart: level repeat: repeat 
	| start end receiver selector args keywordPositions |

	[receiver _ parseNode.
	(tokenType == #keyword and: [level >= 3])
		ifTrue: 
			[start _ mark.
			"The accumulation algorithm is quadratic,
			but it is faster to do it this way for 1 or 2 arguments,
			which account for almost all cases."
			selector _ token.
			self scanToken.
			self primaryExpression ifFalse: [^self expected: 'Argument'].
			self messagePart: 2 repeat: true.
			args _ Array with: parseNode.
			tokenType == #keyword
				ifTrue:
					[keywordPositions _ Array with: start with: mark.
					[selector _ selector , token.
					self scanToken.
					self primaryExpression ifFalse: [^self expected: 'Argument'].
					self messagePart: 2 repeat: true.
					args _ args copyWith: parseNode.
					tokenType == #keyword]
						whileTrue:
							[keywordPositions _ keywordPositions copyWith: mark]]
				ifFalse:
					[keywordPositions _ nil].
			selector _ self
				makeNewSymbol: selector
				startingAt: start
				withPositions: keywordPositions.
			end _ self endOfLastToken]
		ifFalse: [((tokenType == #binary or: [tokenType == #verticalBar])
				and: [level >= 2])
				ifTrue: 
					[start _ mark.
					selector _ token asSymbol.
					self scanToken.
					self primaryExpression ifFalse: [^self expected: 'Argument'].
					self messagePart: 1 repeat: true.
					args _ Array with: parseNode.
					end _ self endOfLastToken]
				ifFalse: [tokenType == #word
						ifTrue: 
							[start _ mark.
							end _ mark + token size - 1.
							selector _ token.
							self scanToken.
							selector _ self
								makeNewSymbol: selector
								startingAt: start
								withPositions: nil.
							args _ #()]
						ifFalse:
							[receiver isSuper
								ifTrue: [self expected: 'message'].
							^args notNil]]].
	self parseNode: (builder
				newMessageReceiver: receiver
				selector: (builder newSelectorName: selector)
				arguments: args).
	parseNode sourcePosition: (start to: end).
	repeat]
		whileTrue: [].
	^true! !