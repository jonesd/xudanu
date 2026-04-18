'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:28 pm'!

Stream subclass: #HxxPrintStream
	instanceVariableNames: '
		stream {WriteStream}
		indent {IntegerVar}
		precedence {IntegerVar}
		myClass {Behavior}
		methodName {Symbol}
		parsedMethod {MethodNode}
		currentSelector {Symbol}
		insideCreate {BooleanVar}
		lastCR {Integer}
		myGlobalMemberState {BooleanVar}'
	classVariableNames: '
		CxxCastArray {Array} 
		CxxCastMap {Dictionary of: Symbol and: Symbol} 
		CxxGlobalFuncs {Set of: Symbol} 
		CxxGlobalProtocolAttributes {Set} 
		CxxMacroFuncs {Set of: Symbol} 
		CxxNameArray {UNKNOWN} 
		CxxNameMap {UNKNOWN} 
		CxxOverrideArray {UNKNOWN} 
		CxxOverrideDefArray {UNKNOWN} 
		CxxOverrideDefMap {UNKNOWN} 
		CxxOverrideMap {UNKNOWN} 
		CxxPrecedenceArray {UNKNOWN} 
		CxxPrecedenceMap {UNKNOWN} 
		CxxSelectorArray {UNKNOWN} 
		CxxSelectorMap {UNKNOWN} 
		ExecutionTraceFlag {UNKNOWN} 
		FormatComments {BooleanVar} 
		GenerateCrutch {UNKNOWN} 
		InverseSelectorMap {UNKNOWN} 
		SelectorCache {UNKNOWN} 
		TargetMachine {UNKNOWN} 
		WarnedMethods {Set of: MethodRep} '
	poolDictionaries: ''
	category: 'X++ Translator'!
HxxPrintStream comment:
'Categories of messages that start with certain prefixes are treated specially: proxy, copy, private, protected, and Smalltalk.  Categories not marked otherwise are public.  Categories that start with Smalltalk are simply not translated.
The translator maps selectors using a few rules and a table.  The table is defined in maps>mapSelector.  The rules are:  all ''with:'' keywords are dropped.  the text following a ''.'' in a keyword is dropped.  '':''s are dropped and the keyword following them is capitalized.
The translator requires a certain convention for constructors.  Instance methods of the form ''create'' are recognized as constructors.  The receiver of such expressions is analyzed to determine the name for the constructor.  Instance creation methods in classes should be kept in a category that begins with Smalltalk only and should follow the same constructor pattern.
The translator recognizes the class names Vector and CharVector.  It translates them to basic c++ arrays of pointers or chars, respectively
See TypeDeclaration>baseType for the rules on type names that default to other than pointer types.

parser printing - messages sent by parse nodes.
maps & class maps - specify special handling for messages, name translation
message translations - methods that implement special handling for particular messages
definition translation - methods that implement special handling for particular definitions of methods
stream accessing - implementing the smalltalk stream protocol
crutch - spcial methods for handling crutch translations
support - random support routines.  extractTypes, etc.

7 May 1990 dean - made a general transformation for printing funtion expressions.  Changed #pow. #rounded, #min, #max, #xuInteger to use it (removing the pre-existing special transformations.  Created a psecial transformation of ''num negated'' to ''-num''.  Removed the special hacks in printFunction:rec:args: to ahndle #xuInteger and: #negated. (and simplified them).  Slightly re-grouped the pairs in mapOverride:.  Removed the unused #typeName: transformations.  Removed the even and odd translations:  they weren''t used.  

7 May 1990 dean - Renamed all the cast handlers to a form printCastxxx:args:.  This groups them in the protocol list.  I also made them share a routine for managing parentheses, and made them handle parentheses and '';'' correctly. Removed several mapSelectors for methods with special handlers.  Simplified the handling of if (there was a special handler for every case).

2 August 1990 dean - Allow create to be sent to a ''new'' expression ((Foo new: bar) create).  Also make the default create (without a new expression) expand to installation of a constructor bomb.  Since the bomb requires a c++ block, the default create expressions become statements.  We''ll have to special case ''^Foo create'' and ''bar _ Foo create'' to embed the assignment or return expression in the C++ block containing the bomb.'!



!HxxPrintStream methodsFor: 'support'!

className
	"return the name of the current class as a useable type.  If the class is meta, use the soleInstance name."
	
	self getClass isMeta
		ifTrue: [^ self getClass soleInstance cxxName]
		ifFalse: [^ self getClass cxxName]!

classRef: expr 
	"Return the name of the class referred to by the 
	expression (or nil if it doesn't refer to a class)."

	self getClass isMeta
		ifTrue: 
			[expr isSelf ifTrue: [^self className].
			expr isSuper ifTrue: [^self superName]]
		ifFalse: [(expr isMessageNode and: [(self mapSelector: expr selector) = #class])
				ifTrue: 
					[expr receiver isSelf ifTrue: [^self className]. 
					expr receiver isSuper ifTrue: [^self superName]]].
	(expr isVarNode and: [(Smalltalk at: expr name asSymbol ifAbsent: []) isBehavior])
		ifTrue: [^expr name].
	^nil!

{Set of: Symbol} classVarNamesOf: classDesc {ClassDescription}

	classDesc isMeta ifTrue: [^classDesc soleInstance classVarNames].
	^ classDesc classVarNames!

extractBlastName: expr 
	"Return the name of a blast embedded in a statement of the form: <class> 
	blast.<BlastName>"

	| sel | 
	(expr isMessageNode and: [(self classRef: expr receiver) ~= nil
			and: [sel _ expr selector.
				#('problems' 'bomb' 'blast') includes: (sel copyUpTo: $.)]])
		ifTrue: [^ HxxPrintStream stripName: (self stripBlast: sel)]
		ifFalse: [self warn: 'Blast name expected.'.
				^ '']!

extractBlockParams: methodTree 
	"selector must currently be one of: transform, criterion, binaryfn. 
	This generates a declaration for a class of the appropriate type."
	"Returns: #( name->type message->messageType outerBlock innerBlock) 
	NOTE: to parallel Smalltalk semantics, the value of the last expression must 
	be returned. If the last expression is not a ReturnNode, then it will be 
	wrapped with one."

	| type messageType outerBlock innerBlock sel refIndex tmp stmts |
	sel _ methodTree selector.
	refIndex _ #(#predicate #unaryFn #binaryFn ) indexOf: (self mapSelector: sel).
	type _ #(#Predicate #UnaryFn #BinaryFn ) at: refIndex.	
	"Determine the name of the class to be defined."
	outerBlock _ methodTree block.
	tmp _ outerBlock body statements.
	tmp size = 0 ifTrue: [self warn: 'no block definition.'].
	tmp _ tmp last.	"Note that any operations before the return of the block are 
	
	ignored. These could be used to initialize default values. 
	
	They should really get included in the constructor."
	((tmp isKindOf: ReturnNode)
		and: [tmp value isBlockNode])
		ifFalse: [self warn: 'block definition must return a block.'].
	innerBlock _ tmp value.	
	"put a return on the last statement in the block so that it translates correctly."
	"We might be able to add this inline."
	stmts _ innerBlock body statements.
	((stmts at: stmts size)
		isKindOf: ReturnNode)
		ifFalse: [stmts at: stmts size put: (ReturnNode new value: stmts last)].	
		"Determine the return type."
	messageType _ TypeDescription create.
	messageType baseType: (self mapVarName: (#('Boolean' 'Object' 'Object' ) at: refIndex)).
	^Array
		with: (self classFromSelector: sel)
				, type -> type
		with: (#(#is #of #of ) at: refIndex)
				-> messageType
		with: outerBlock
		with: innerBlock"name -> type"
	"message messageType"
	"innerBlock"!

extractType: typeExpr 
	"Return a type description object for the supplied type expression parse tree."

	^ TypeDescription fromParse: typeExpr with: self getClass!

extractTypeCollection: expr
	"Extract a list of type names from a smalltalk expression using | to separate types."
	
	expr isVarNode ifTrue: [^Array with: expr name].
	expr isMessageNode ifTrue: 
		[expr selector == #| assert: 'Separate types with |'.
		^(self extractTypeCollection: expr receiver) , (self extractTypeCollection: expr arguments first)].
	self error: 'Unknown multiple type expression'!

flushQueue
	"Print out definitions queued till the outer level was reached (nested 
	definitions).   There are none in hxx files!!"!

getClassVars

	^ (self getClass isMeta
		ifTrue: [self getClass soleInstance]
		ifFalse: [self getClass]) classVarNames!

{BooleanVar} inGlobalState

	^ myGlobalMemberState!

{BooleanVar} isGlobalFunc: selector with: cls {ClassDescription}
	
	(CxxGlobalFuncs includes: (self mapSelector: selector)) ifTrue: [^ true].
	^ cls globalProtocol: (cls organization categoryOfElement: selector)!

{BooleanVar} isInstVar: name
	"This assumes our style, that is, all instance variables are handled as private.  This will help enforce that by breaking code that doesn't work that way..."
	
	self getClass isMeta ifTrue: [^ false]. "it would a class instance var..."
	^ self getClass instVarNames includes: name asString!

{BooleanVar} isMacroFunc: selector with: cls {ClassDescription}
	
	(CxxMacroFuncs includes: (self mapSelector: selector)) ifTrue: [^ true].
	^ cls protocol: (cls organization categoryOfElement: selector) hasAttribute: #macros!

isStatement
	^precedence == (self mapPrecedence: #'*statement*')!

overrideString
	"Return the string that prefixes comments that override the definitions of blocks."

	^'cxx:'!

printArguments: arguments
	self printArguments: arguments complex: false spaces: true!

printArguments: arguments complex: complex 
	
	self printArguments: arguments complex: complex spaces: true!

printArguments: arguments complex: complex spaces: spaces
	
	"newline for big arguments; omit spaces for macros"
	
	arguments do: [:arg | (complex or: [arg isComplex])
			ifTrue: [self cr].
		arg prettyPrintOn: self]
		andBetweenDo: [spaces ifTrue: [stream << ', '] ifFalse: [stream nextPut: $,]]!

printBasicConstructor: type args: args 
	"Print just a constructor call for constructing a result of the given type (a TypeDescription)."

	| vectorFlag |
	vectorFlag _ type isVector.
	type makeCast printTypeOn: self.
	vectorFlag
		ifTrue: [self << '[']
		ifFalse: [self << '('].
	self asExpression: [self indent; printArguments: args; unindent].
	vectorFlag
		ifTrue: [self << ']']
		ifFalse: 
			[args size = 1 ifTrue: [stream << ', tcsj'].
			self << ')'].
	self checkStatement!

printBasicDefaultConstructor: type args: args 
	"Print just a constructor call for constructing a result of the given type (a TypeDescription)."

	type isVector not assert.
	(type refType ~= #var) assert.
	type makeCast printTypeOn: self.
	self << ',('.
	self asExpression: [self indent; printArguments: args; unindent].
	args size = 1 ifTrue: [stream << ', tcsj'].
	self << ')'.
	self checkStatement!

{void} printFieldMessage: selector {Symbol} args: args {Array of: ParseNode}
	"print a structure field reference or assignment"
	self nextPutAll: (selector copyFrom: 1 to: selector size - 5).
	args size > 0 ifTrue:
		[self nextPutAll: ' = '.
		self precedence: 7 do:
			[(args at: 1) prettyPrintOn: self]]!

printFunction: realSel origSel: selector recClass: recClass args: arguments
	| p cd staticFunc macro |
	p _ self mapPrecedence: realSel.
	p >= precedence ifTrue: [stream nextPut: $(].
	cd _ Smalltalk at: recClass asSymbol ifAbsent: [nil].
	cd isNil ifTrue: [self error: 'nil receiver class'. ^ VOID].
	staticFunc _ (self isGlobalFunc: selector with: cd class) not.
	macro _ self isMacroFunc: selector with: cd class.
	self indent.
	self asExpression: 
		[realSel isInfix ifTrue: [self warn: 'An infix function defined in the class?!!'].
		(staticFunc and: [macro not]) ifTrue: [self << (self stripName: recClass)].
		macro ifFalse: [self << '::'].
		self << realSel.
		self nextPut: $(; indent.
		self printArguments: arguments
			complex: false
			spaces: realSel first isLowercase.
		self unindent; nextPut: $)].
	p >= precedence ifTrue: [stream nextPut: $)].
	self unindent.
	self checkStatement!

printRealMessage: realSel rec: receiver args: arguments 
	| p  refSuper |
	p _ self mapPrecedence: realSel.
	p > precedence ifTrue: [stream nextPut: $(].
	self indent.
	self precedence: p do: 
		[receiver isSuper
			ifTrue: [refSuper _ true]
			ifFalse: 	"Don't need to lie about precedence here, since lefties can't be lvalues."
				[receiver prettyPrintOn: self.
				refSuper _ false].
		realSel isInfix
			ifTrue: 
				[p == (self mapPrecedence: #=)	
					ifTrue: "Left-associative.  Parens come out right."
						[arguments size = 1 assert: 'wrong number of arguments for operator.'.
						stream space; nextPutAll: realSel; space.
						self indent; printArguments: arguments complex: receiver isComplex; unindent]
					ifFalse:			"Right-associative.  Lie about current precedence to get the parens right."
						[self precedence: p-1 do:
							[arguments size = 1 assert: 'wrong number of arguments for operator.'.
							stream space; nextPutAll: realSel; space.
							self indent; printArguments: arguments complex: receiver isComplex; unindent]]]
			ifFalse: 
				[stream nextPutAll: (refSuper
					ifTrue: ['this->', (self mapVarName: self superName), '::']
					ifFalse: [(self testDotMessage: realSel) ifTrue: [''] ifFalse: ['->']]).
				(self testFieldSelector: realSel) ifTrue:
					[self printFieldMessage: realSel args: arguments]
				ifFalse:
					[self nextPutAll: realSel; nextPut: $(; indent.
					self asExpression: [self printArguments: arguments complex: receiver isComplex].
					self unindent; nextPut: $)]]].
	p > precedence ifTrue: [stream nextPut: $)].
	self unindent.
	self checkStatement!

printVariableName: name
	| var |
	"(self getClassVars includes: name asSymbol)
		ifTrue: [self << (self stripName: self className) << '::']."
	var _ self mapVarName: name.
	(Smalltalk at: var asSymbol ifAbsent: [nil]) isBehavior ifTrue: [stream << 'cat_'].
	stream << var.
	self checkStatement!

sendsDefaultCreate: tree 
	"Return true if tree is an expression that sends the create message. This is used 
	for wrapping returns and assignments of create expressions with constructor 
	bombs. Eventually this should be recursive."

	^tree isMessageNode 
		and: [(self mapSelector: tree selector) == #create
		and: [tree receiver isMessageNode not
				or: [| sel |
					sel _ self mapSelector: tree receiver selector.
					sel ~~ #new and: [sel ~~ #vector]]]]!

sendsSpecialCreate: tree 
	"Return true if tree is an expression that sends the create message. This is used 
	for wrapping returns and assignments of create expressions with constructor 
	bombs. Eventually this should be recursive."

	^tree isMessageNode 
		and: [(self mapSelector: tree selector) == #create
		and: [(tree receiver isMessageNode and: [tree receiver selector == #new.AllocType:])]]!

{void} setGlobalState: toState {BooleanVar}

	myGlobalMemberState _ toState!

shouldBeNOLOCK
	"Return true if I'm currently translating a message in a shpeherd class that should be NOLOCK."

	^(self getClass == Abraham or: [self getClass inheritsFrom: Abraham]) and:
		[| meth {CompileMethod} |
		meth _ self getClass compiledMethodAt: methodName.
		(NOLOCKDetector on: meth) shouldBeNOLOCK]!

superName
	"return the name of the superclass of the current class as a useable type.  If the class is meta, use the soleInstance name."
	
	self getClass isMeta
		ifTrue: [^ self getClass superclass soleInstance cxxName]
		ifFalse: [^ self getClass superclass cxxName]!

testDotMessage: sel 
	"Return true if the message is one sent to a Var type.  If so, we'll have to output a . rather than ->"

	 ^sel first = $.!

tooComplex
	"The number of arguments after which we break lines."
	^2!

{String} typeForReturnCast: typeString {Symbol}
	| ivar |
	ivar _ Parser new parseTypeExpression: typeString notifying: nil.
	^ (TypeDescription fromParse: ivar) baseType.! !

!HxxPrintStream methodsFor: 'parser printing'!

checkStatement
	self isStatement ifTrue: [self nextPut: $;]!

printAssign: varNode value: value 
	"Turn expressions like 'a _ a + 1.' into 'a += 1;'."

	| index |
	"Specially handle expression like '+='"
	(value isMessageNode and: 
		[(index _ #(+ - * / % >> << & #'^' | ) indexOf: 
			(self mapSelector: value selector)) ~= 0 and: [value receiver = varNode]])
		ifTrue: [^self
				printRealMessage: 
					(#(+= -= *= /= %= #'>>=' #'<<=' &= #'^=' #'|=' ) at: index)
				rec: varNode
				args: (Array with: value arguments first)].
	"Specially wrap returns of constructor expressions with a
	 macro that will use constructor bombs."
	(self sendsDefaultCreate: value) ifTrue:
		[self asExpression: 
			[self << 'CONSTRUCT(';
				prettyPrint: varNode; << ',';
				printBasicDefaultConstructor: (self extractType: value receiver) args: value arguments; << ')'].
		^self checkStatement].
	(self sendsSpecialCreate: value) ifTrue:
		[self asExpression:
			[self << 'CONSTRUCT_ON(';
				prettyPrint: value receiver arguments first; << ',';
				prettyPrint: varNode; << ',';
				printBasicDefaultConstructor: (self extractType: value receiver) args: value arguments; << ')'].
			^self checkStatement].
	self printRealMessage: #= rec: varNode args: (Array with: value)!

printBlockArgs: arguments body: body 
	| complex |
	complex _ precedence >= (self mapPrecedence: #'*expression*') or: [arguments size > 2 | body isComplex].
	self printBlockArguments: arguments.
	complex
		ifTrue: [self startBlock]
		ifFalse: [self indent; nextPutAll: '{'].
	self asStatement: [body prettyPrintOn: self].
	complex
		ifTrue: ["(body isComplex and: [arguments size > 0]) ifTrue: [self unindent; cr]."
			self stopBlock]
		ifFalse: [self unindent; nextPutAll: '}']!

printBlockArguments: arguments 
	arguments size = 0
		ifFalse: 
			[self warn: 'BLOCK-ARGUMENTS stuff'.
			self nextPutAll: 'BLOCK-ARGUMENTS('; indent.
			self asExpression: [arguments do: [:arg | arg prettyPrintOn: self]
					andBetweenDo: [self nextPutAll: ', ']].
			self nextPut: $); unindent]!

printCascade: messages receiver: r 
	r isMessageNode ifTrue: [self error: 'Cascade on an expression.'].
	self printComment: 'CASCADE'; cr.
	self isStatement
		ifTrue: [messages do: [:m | m prettyPrintOn: self]
				andBetweenDo: [self cr]]
		ifFalse: 
			[self nextPut: $(; indent; asStatement: [messages do: [:m | m prettyPrintOn: self]
					andBetweenDo: [self nextPutAll: ', ']].
			self nextPut: $); unindent]!

printClassVariable: nameNode type: typeExpr
	| type conditional |
	type _ self extractType: typeExpr.
	type isSmalltalk ifTrue: [^VOID].
	(type hasAttribute: #global) ifTrue: [^VOID].
	conditional _ false.
	type conditionalsDo: [ :cond :symbol |
		conditional _ true.
		self hardCR; nextPut: $#;
			emphasis: 2; nextPutAll: cond; emphasis: 1;
			space; nextPutAll: symbol].
	conditional ifTrue: [self hardCR].
	self asExpression: 
		[self << 'static '.
		type makeGlobal printTypeOn: self.
		self emphasis: 2; << nameNode name; emphasis: 1.
		type printEpilogOn: self].
	self checkStatement.
	conditional ifTrue:
		[type conditionalsDo: [ :cond :symbol |
			self hardCR; nextPut: $#;
				emphasis: 2; nextPutAll: 'endif'; emphasis: 1;
				space; printComment: symbol]]!

printComment: comment
	
	| theComment |
	"Ignore Smalltalk overrides."
	(comment testPrefix: self overrideString)
		ifTrue: [^true].
	"A very simple word-wrapping algorithm; it really should keep track of the current column"
	stream emphasis: 9.
	FormatComments ifFalse:
		[stream nextPutAll: '/* '; nextPutAll: comment; nextPutAll: ' */'; emphasis: 1.
		^false].
	theComment := ('/* ' , comment ,  ' */') readStream.
		[ | line space margin |
		line := theComment upTo: Character cr.
		[space := 70 - self column.
		line size - space < 10] whileFalse:
			[space < 10 ifTrue:
				[self cr]
			ifFalse:
				[margin := space.
				[(line at: space) isSeparator or: [margin - space > 20]] whileFalse:
					[space := space - 1].
				margin - space > 20 ifTrue: [space := margin].
				stream nextPutAll: (line copyFrom: 1 to: space).
				self cr.
				line := line copyFrom: space + 1 to: line size]].
		stream nextPutAll: line.
		theComment atEnd ifTrue:
			[stream emphasis: 1.
			^false].
		self cr]
	repeat!

printComments: comments 
	(comments == nil or: [comments isEmpty])
		ifFalse: [comments do: [:comment | 
					(self printComment: comment) ifTrue: [^true]]
				andBetweenDo: [self cr]].
	^false!

printInstVariable: nameNode type: typeExpr
	| type conditional |
	type _ self extractType: typeExpr.
	type isSmalltalk ifTrue: [^self].
	conditional _ false.
	type conditionalsDo: [ :cond :symbol |
		conditional _ true.
		self hardCR; nextPut: $#;
			emphasis: 2; nextPutAll: cond; emphasis: 1;
			space; nextPutAll: symbol].
	conditional ifTrue: [self hardCR].
	self asExpression: 
		[type makeCheck printTypeOn: self.
		self emphasis: 2; << nameNode name; emphasis: 1.
		type printEpilogOn: self].
	self checkStatement.
	conditional ifTrue:
		[type conditionalsDo: [ :cond :symbol |
			self hardCR; nextPut: $#;
				emphasis: 2; nextPutAll: 'endif'; emphasis: 1;
				space; printComment: symbol]]!

printLiteral: value 
	(value isKindOf: Number) ifTrue: 
		[value == 0 ifTrue: [self warn: 'Raw 0 in code.  Use constants!!'].
		stream store: value]
	ifFalse: [value == nil ifTrue: [self warn: 'Cannot translate nil to C++'. stream << 'NULL']
	ifFalse: [(value isKindOf: Character) 
				ifTrue: [self nextPut: $'; cxxNextPutAll: value asString; nextPut: $']
	ifFalse: [(value isKindOf: Symbol) ifTrue: [self cxxNextPutAll: (self stripName: value)]
	ifFalse: [(value isKindOf: String) ifTrue: [self nextPut: $"; cxxNextPutAll: value; nextPut: $"]
	ifFalse: [value == true ifTrue: [self nextPutAll: 'TRUE']
	ifFalse: [value == false ifTrue: [self nextPutAll: 'FALSE']
	ifFalse: [stream nextPutAll: 'LITERAL('; store: value; nextPut: $)]]]]]]].
	self checkStatement!

printMessage: selector receiver: receiver arguments: arguments 
	| realSel method recClass |

	realSel _ self mapSelector: selector.
	method _ self mapOverride: realSel.
	method == nil
		ifTrue: [(recClass _ self classRef: receiver) ~= nil "is it a function?"
				ifTrue: [self
						printFunction: realSel
						origSel: selector
						recClass: recClass
						args: arguments]
				ifFalse: [self
						printRealMessage: realSel
						rec: receiver
						args: arguments]]
		ifFalse: [self
				perform: method
				with: receiver
				with: arguments]!

printMethod: methodTree
	"This will override for various selectors."

	| realSel override |
	parsedMethod _ methodTree.
	realSel _ self mapSelector: methodTree selector.
	override _ self mapOverrideDef: realSel.
	override = nil ifTrue: [self defNormalMethod: methodTree]
		ifFalse: [self perform: override with: methodTree].
	parsedMethod _ nil "clean up to help avoid bugs..."!

printParameter: nameNode type: typeExpr
	"Hxx files print the argument name as a comment, in case the pure-virtual-bug causes inline code generation"
	
	| type conditional |
	type _ self extractType: typeExpr.
	type makeParam.
	conditional _ false.
	type conditionalsDo: [ :cond :symbol |
		conditional _ true.
		self hardCR; nextPut: $#;
			emphasis: 2; nextPutAll: cond; emphasis: 1;
			space; nextPutAll: symbol].
	conditional ifTrue: [self hardCR].
	self asExpression: 
		[type printTypeOn: self.
		self << 'ARG('.
		self emphasis: 2; << nameNode name; emphasis: 1.
		self << ')'.
		type printEpilogOn: self; printDefaultOn: self].
	self checkStatement.
	conditional ifTrue:
		[type conditionalsDo: [ :cond :symbol |
			self hardCR; nextPut: $#;
				emphasis: 2; nextPutAll: 'endif'; emphasis: 1;
				space; printComment: symbol]]!

printPattern: selector arguments: arguments type: returnType with: statements 
	| realSel |
	methodName _ selector.
	realSel _ self mapSelector: selector.
	self cr.
	realSel == #create ifTrue: [
(statements ~~ nil and: [statements count > 1]) ifTrue: [self halt].
		^self printConstructorPattern: selector
			arguments: arguments
			type: returnType
			with: statements].
	realSel == #delete ifTrue: [^self printDestructorPattern].
	"realSel == #make ifTrue: 
		[self error: 'Make should already have been converted to the appropriate message in defPseudoConstructor.'
		""^self printPseudoConstructorPattern: selector arguments: arguments""]."	
	"non-constructor methods are functions."
	(self getClass isMeta and: [self isGlobalFunc: selector with: self getClass]) ifTrue: [statements = nil assert: 'statements for constructor pattern in function?'.
		^self
			printFunctionPattern: realSel
			arguments: arguments
			type: returnType].
	self
		printNormalPattern: realSel
		arguments: arguments
		type: returnType!

printPrimitive: prim
	self nextPutAll: '/* primitive'; print: prim; nextPutAll: ' */'; cr!

printReturn: value 
	| mappedSelector {Symbol} |
	(GenerateCrutch and: [value isCrippled])
		ifTrue: [^self crippledReturn: value].
	(value isVarNode and: [value name = 'VOID'])
		ifTrue: [self << 'return;'; cr]
		ifFalse: [(self sendsDefaultCreate: value)
				ifTrue: [self asExpression:
							[self << 'RETURN_CONSTRUCT(';
							printBasicDefaultConstructor: (self extractType: value receiver)
							args: value arguments; << ');'.
							self checkStatement].
					insideCreate _ false]
				ifFalse:
				[(parsedMethod returnTypeDescription specialReturn and:
					[(value isSelf or: [(value isVarNode and: [value name = 'NULL']) or: [value isMessageNode and: 
									   [((mappedSelector _ self mapOverride: (self mapSelector: value selector))
											== #printCastMacro:args:) or:
											[mappedSelector == #printCastBasic:args:]]]]) not])
						ifTrue: 
							[(value isVarNode and: [self getClass instVarNames includes: value name])
								ifTrue:
									[|itype|
									itype _ self getClass getCxxClassDescription instVarTypeAt: value name.
									self << 'return ('
										 << (self typeForReturnCast: itype)
										 << '*) '; prettyPrint: value]
								ifFalse:
									[self asExpression:
										[parsedMethod returnTypeDescription makeWimpy printTypeOn: self.
										self tab; nextPutAll: 'returnValue;'; cr].
									self << 'returnValue = '; prettyPrint: value; cr.
									self << 'return returnValue'; checkStatement]]
						ifFalse: [self << 'return '.
							self asExpression: [self prettyPrint: value].
							self checkStatement]]].!

printSelf
	self halt.
	stream nextPutAll: 'this'!

printSuper
	self error: 'Super is not a legal variable.'!

printTemp: nameNode type: typeExpr
	| type |
	type _ self extractType: typeExpr.
	(type hasAttribute: #smalltalk) ifTrue: [ ^ VOID ].
	self asExpression: 
		[type makeStrong printTypeOn: self.
		self emphasis: 2; << nameNode name; emphasis: 1.
		type printEpilogOn: self].
	self checkStatement!

printTemps: temps 
	temps do: 
		[:temp | 
		temp prettyPrintTempOn: self.
		self cr]!

startBlock
	"The start of a method block, primarily."

	self nextPutAll: '{'; indent; cr!

stopBlock
	"The stop of a method block, primarily."

	self unindent; cr; nextPut: $}! !

!HxxPrintStream methodsFor: 'definition translations'!

defBomb: methodTree
	"Translate
		bomb.BombKind: CHARGE {ChargeType}
			^[...stuff...]
	to
		ORDER_BOMB(BombKind,ChargeType); in hxx
	and
		BUILD_BOMB_BEGIN(BombKind,ChargeType) {
			...stuff...
		} BUILD_BOMB_END(BombKind); in ixx"
 
	"Determine the name of the class to be defined."
	| sel bombType outerBlock tmp innerBlock outerVar chargeType |
	sel _ methodTree selector.
	bombType _ self classFromSelector: sel.
	outerBlock _ methodTree block.
	tmp _ outerBlock body statements.
	tmp size = 0 ifTrue: [self error: 'no block definition.'].
	tmp _ tmp last.
	((tmp isKindOf: ReturnNode)
		and: [tmp value isBlockNode])
		ifFalse: [self error: 'block definition must return a block.'].
	innerBlock _ tmp value.
	"The following is the declaration for the charge."
	outerVar _ outerBlock arguments first.
	outerVar name ~= 'CHARGE' ifTrue: [self error: 'The argument for a Bomb must be named CHARGE.'].
	innerBlock arguments size ~= 0 ifTrue: [self error: 'What do I do with arguments for a Bomb object?'].
	chargeType _ self extractType: outerVar type.
	"Print the pattern: 
	ORDER_BOMB(bombType,chargeType);"
 	self << 'ORDER_BOMB(' << bombType << ', '.
	chargeType makeStrong printTypeOn: self.
	self << ');'; cr; cr!

defConstructor: methodTree 
	self defNormalMethod: methodTree!

defDestructor: methodTree 
	self defNormalMethod: methodTree!

defInitTimeMacro: tree {MethodNode} 
	"generate the INIT_TIME macro for cxx files; declare the INIT_TIME 
	class a friend in the .hxx file"

	self inGlobalState not ifTrue: 
		[self asExpression:
			[self << 'friend class INIT_TIME_NAME(' << self className << ',' 
				 << tree selector << ');']]!

defNormalMethod: methodTree
	"This will override for various selectors."
	methodTree prettyPrintPatternOn: self!

defProblems: methodTree
	"Translate
		problems.Stuff
			^self signals: #(Foo Bar Baz)
	to
		PROBLEM_LIST(StuffFilter,3,(Foo,Bar,Baz));
	Eventually, this should change to
		DECLARE_PROBLEM_LIST(StuffFilter); in the hxx and
		DEFINE_PROBLEM_LIST(StuffFilter,3,(Foo,Bar,Baz)); in the cxx,
	but first bombs need to be changed to allow this."

	| signals |
	signals := methodTree block body statements first value arguments first value.
	self nextPutAll: 'PROBLEM_LIST(';
		nextPutAll: (self classFromSelector: methodTree selector);
		nextPutAll: 'Filter,';
		nextPutAll: signals size printString;
		nextPutAll: ',('.
	signals
		do: [ :signal | self nextPutAll: (HxxPrintStream stripDotUDot: signal)]
		andBetweenDo: [self nextPut: $,].
	self nextPutAll: '))'.!

defPseudoConstructor: methodTree
	| tNode |
	"n.b. defPseudoConstructor is still used because many pseudoConstructors do not define a return type.  This method fills in the proper return type if it is not previously defined.	heh 9 January 1992"
	
	"methodTree selector: (self makePC: class soleInstance cxxName).  this is obsolete because we use the name 'make' with static member function type pseudoConstructors"
	methodTree returnType == nil ifTrue:
		[tNode _ VariableNode new name: (self className).
		methodTree returnType: tNode].
	self defNormalMethod: methodTree!

defStaticInitializer: methodTree 
	"Print fluid variable and constant declarations"
	self inGlobalState ifTrue: [
		((methodTree block body isKindOf: SequenceNode)
			ifTrue: [methodTree block body statements]
			ifFalse: [Array with: methodTree block body])
				do: [ :statement | 
					((statement isKindOf: SimpleMessageNode)
						and: [#(	enum:with:
							enum:flags:
							defineFluid:with:
							defineFluid:with:with:
							defineClientFluid:with:with:
							definePromiseFluid:with:with:with:with:
							defineGlobal:
							defineGlobal:with:
							defineLogger:)
						includes: statement selector])
					ifTrue: [statement prettyPrintOn: self.
						self cr.]]]!

printConstructorPattern: realSel arguments: arguments type: returnType 
	| complex |
	self getClass isMeta ifTrue: [self error: 'Constructors in the class must just forward\to constructors in newly created instances.' withCRs].
	stream emphasis: 14.
	self << self className; emphasis: 1; << ' ('.
	complex _ arguments size > self tooComplex.
	self asExpression: 
		[self indent; indent; printArguments: arguments complex: complex.
		arguments size = 1 ifTrue: [stream << ', TCSJ'].
		self << ')'; unindent; unindent].
	complex ifTrue: [self cr]!

printConstructorPattern: realSel arguments: arguments type: returnType with: statements 
	| complex |
	self getClass isMeta ifTrue: [self error: 'Constructors in the class must just forward\to constructors in newly created instances.' withCRs].
	(returnType ~~ nil and: [returnType isVarNode]) ifTrue:
		[|type|
		type _ TypeDescription fromParse: returnType with: myClass.
		(type hasAttribute: #INLINE) ifTrue:
			[stream nextPutAll: 'INLINE ']].
	stream emphasis: 14.
	self << self className; emphasis: 1; << ' ('.
	complex _ arguments size > self tooComplex.
	self asExpression: 
		[self indent; indent; printArguments: arguments complex: complex.
		arguments size = 1 ifTrue: [stream << ', TCSJ'].
		self << ')'; unindent; unindent].
	complex ifTrue: [self cr]!

printDefineClientFluid: type args: arguments
	"In the hxx, translate to a DESIGN_CLIENT_FLUID(type, name) and don't care whether there's an initial value."
	
	self asExpression:
		[| td |
		self nextPutAll: 'DESIGN_CLIENT_FLUID('.
		td _ (self extractType: type).
		td printMethodPrologOn: self; printTypeNameOn: self.
		self << ','; prettyPrint: (arguments at: 1); << ')'].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDefineFluid: type args: arguments
	"In the hxx, translate to a DESIGN_FLUID(type, name) and don't care whether there's an initial value."

	self asExpression:
		[| td |
		td _ (self extractType: type).
		self nextPutAll: 'DESIGN_'.
		td refType == #var ifTrue: [self << 'PRIM_'].
		self nextPutAll: 'FLUID('.
		td printMethodPrologOn: self; printTypeNameOn: self.
		self << ','; prettyPrint: (arguments at: 1); << ')'].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDefineGlobal: type args: arguments
	self asExpression:
		[| td |
		self << 'extern '.
		td _ (self extractType: type) makeGlobal.
		td printMethodPrologOn: self; printTypeOn: self.
		self prettyPrint: (arguments at: 1)].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDefineLogger: receiver args: arguments
	
	self asExpression:
		[self << 'LOGGER('.
		self prettyPrint: (arguments at: 1).
		self << ')'].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDefinePromiseFluid: type args: arguments
	"In the hxx, translate to a DESIGN_PROMISE_FLUID(type, name) and don't care whether there's an initial value."
	
	self asExpression:
		[| td |
		self nextPutAll: 'DESIGN_PROMISE_FLUID('.
		td _ (self extractType: type).
		td printMethodPrologOn: self; printTypeNameOn: self.
		self << ','; prettyPrint: (arguments at: 1); << ')'].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDestructorPattern
	self getClass isMeta ifTrue: [self error: 'Define destructors for instances.'].
	self printPatternType; emphasis: 14.
	self nextPutAll: '~', self className; emphasis: 1; nextPutAll: ' () '!

printFriendPattern: realSel arguments: arguments type: returnType 
	| type complex |
	self << 'friend '.
	type _ self extractType: returnType.
	self printPatternType: type.
	stream emphasis: 14.
	self << self className asString; << '::'.
	realSel isInfix ifTrue: [stream << 'operator'].
	self << realSel; emphasis: 1; << ' ('.
	complex _ arguments size > self tooComplex.
	self asExpression: 
		[self indent;
			 indent;
			 printArguments: arguments complex: complex;
			 << ')'.
		type printEpilogOn: self.
		self unindent; unindent].
	complex ifTrue: [self cr]!

printFunctionPattern: realSel arguments: arguments type: returnType 
	| complex type |
	type _ self extractType: returnType.
	type printMethodPrologOn: self.
	type makeReturn printTypeOn: self.
	(type default == nil) ifFalse: [self error: 'defaults in a return type!!?'].
	stream space; emphasis: 14.
	realSel isInfix ifTrue: [stream << 'operator'].
	self << realSel; emphasis: 1; << ' ('.
	complex _ arguments size > self tooComplex.
	self asExpression:
		[self indent; indent;
			 printArguments: arguments complex: complex;
			 << ')'.
		type printEpilogOn: self.
		self unindent; unindent].
	complex ifTrue: [self cr]!

printNormalPattern: realSel arguments: arguments type: returnType 
	| type complex |
	type _ self extractType: returnType.
	self printPatternType: type.
	stream emphasis: 14.
	realSel isInfix ifTrue: [stream << 'operator'].
	self << realSel; emphasis: 1; << ' ('.
	complex _ arguments size > self tooComplex.
	self asExpression: 
		[self indent;
			 indent;
			 printArguments: arguments complex: complex;
			 << ')'.
		type printEpilogOn: self.
		self unindent; unindent].
	complex ifTrue: [self cr]!

printPatternType
	stream nextPutAll: 'virtual '!

printPatternType: type 
	"For Abrahams only"
	self shouldBeNOLOCK ifTrue: [type addAttribute: #NOLOCK].
	(self getClass isMeta)
		ifTrue: [stream nextPutAll: 'static ']
		ifFalse: [(type baseType = 'NOWAIT' or: [type hasAttribute: #INLINE])
			ifFalse: [(self isOverridden: self getClass selector: methodName)
				ifTrue: [stream nextPutAll: 'virtual ']
				ifFalse: [stream nextPutAll: 'virtual ']]]. "/*LEAF?*/ "
	type printMethodPrologOn: self.
	type makeReturn printTypeOn: self.
	type default == nil assert: 'defaults in a return type!!?'! !

!HxxPrintStream methodsFor: 'message translations'!

printAnd: cond args: args 
	"the other condition must be simple."

	| p  arguments |
	(args first isBlockWithNumArgs: 0)
		ifFalse: [self error: 'bad conditional'].
	p _ self mapPrecedence: #&&.
	p > precedence ifTrue: [stream nextPut: $(].
	self indent.
	self precedence: p do:
		[cond prettyPrintOn: self.
		arguments _ args first body statements.
		arguments size = 1 assert: 'wrong number of arguments for operator.'.
		stream space; nextPutAll: #&&; space.
		self indent; printArguments: arguments complex: cond isComplex; unindent].
	p > precedence ifTrue: [stream nextPut: $)].
	self unindent.
	self checkStatement!

printArrow: rec args: args 
	"Translate the retrieval message for Cells.  They act like pointers to other values."

	self precedence: 1 do:
		[rec prettyPrintOn: self.
		self << '->'.
		args first prettyPrintOn: self].
	self checkStatement!

printAsOop: rec args: ignored 
	"Translate asOop to taking the adress of the object."

	self printCastBasic: rec string: '(UInt32)(void *)(Heaper *)'!

printAsProblem: rec args: ignored 
	"Translate asProblem to &PROBLEM(rec)"

	self << '&PROBLEM('.
	rec prettyPrintOn: self.
	self << ')'.!

printAssert: rec args: args
	self asExpression:
		[self nextPutAll: 'if ( '.
		(rec isMessageNode and: [rec selector == #not])
			ifTrue: [rec receiver prettyPrintOn: self]
			ifFalse:
				[self nextPutAll: '!! ('.
				rec prettyPrintOn: self.
				self nextPutAll: ')'].
		self nextPutAll: ' ) {';
			indent; cr;
			nextPutAll: 'BLAST(';
			nextPutAll: (args size = 0
				ifTrue: ['Assertion_failed']
				ifFalse: [args first value collect: [ :c |
						c isAlphaNumeric ifTrue: [c] ifFalse: [$_]]]);
			nextPutAll: ');';
			unindent; cr;
			nextPutAll: '}']!

printBomb: rec args: args 
	"SomeClass bomb.BombName: charge translates to
		PLANT_BOMB(BombName,Boom);
		ARM_BOMB(Boom,charge);"

	| sel |
	sel _ currentSelector.
	self cr; nextPutAll: 'PLANT_BOMB(';
			nextPutAll: (self class stripName: (self stripBlast: sel));
			nextPutAll: ',Boom);';
		cr; nextPutAll: 'ARM_BOMB(Boom,('.
	args first prettyPrintOn: self.
	self nextPutAll: '))'.
	self checkStatement!

printBump: rec args: args pre: pre post: post
	"This is a dangerous optimization." 

	args count = 1 ifTrue:
		[self precedence: 1 do: [rec prettyPrintOn: self].
		self << $ ; << pre; << '= '.
		self precedence: (self mapPrecedence: #bump) do: [(args at: 1) prettyPrintOn: self].
		self checkStatement]
	ifFalse: [args count = 0 ifTrue:
		[| nest prec |
		prec _ self mapPrecedence: #bump.
		nest _ precedence <= prec.
		nest ifTrue: [self << $(].
		self << pre; << pre.
		self precedence: prec do: [rec prettyPrintOn: self].
		self << post; << post.
		nest ifTrue: [self << $)].
		"self checkStatement"]]!

printCast: rec args: args
	| sel |
	"Print a cast to the desired type."
	sel _ self mapSelector: currentSelector.
	self printCastBasic: rec string: ('(', (self mapCastName: sel), ')').!

printCastBasic: rec args: args
	"Print a cast to a type."

	self precedence: (self mapPrecedence: #basicCast)
		nest:
			[self << '('.
			(self extractType: args first) printTypeOn: self.
			self << ') '; prettyPrint: rec].
	self checkStatement!

printCastBasic: rec string: string
	"Print a basic cast to the type described in string.  This is called by other cast routines."

	self precedence: (self mapPrecedence: #basicCast)
		nest: [self << string.
			self space; prettyPrint: rec].
	self checkStatement!

printCastInto: rec args: args 
	"Convert the smalltalk construct:  'Expr cast: Cat into: [:Var | Body]'  to:
		`BEGIN_CHOOSE(Expr) {
			BEGIN_KIND(Cat,Var) {
				Body
			} END_KIND;
		} END_CHOOSE;'
	The KINDn cases don't use BEGIN/END"
	
	| astep |
	self << 'BEGIN_CHOOSE('; asExpression: [self indent; prettyPrint: rec; unindent]; << ') '; openBlock.
	
	astep _ args stepper.
	astep forEach: 
		[:type |
		| block |
		self cr.
		astep step.
		block _ astep fetch.
		(block == nil or: [block == NULL])
			ifTrue:
				["The else case.  type is actually the else block."
				self << 'BEGIN_OTHERS '; startBlock; prettyPrint: type body; stopBlock; << ' END_OTHERS;']
			ifFalse:
				[type isVarNode
					ifTrue: [self << 'BEGIN_KIND(' << type name << $,.
							self << block arguments first name << ') '.]
					ifFalse:
						[| types |
						type isMessageNode ifFalse: [self warn: 'Must use | to separate multiple types in CHOOSE'. ^VOID].
						types _ self extractTypeCollection: type.
						self << 'KIND' << types count << '('.
						types do: [:t | self << t << $,].
						self << block arguments first name << ', '.].
				self startBlock; prettyPrint: block body.
				self stopBlock.
				type isVarNode
					ifTrue: [self << ' END_KIND;']
					ifFalse: [self << ');']]].
	
	self stopBlock; << ' END_CHOOSE;'!

printCastMacro: rec args: args
	"Print a cast to a type."

	self asExpression: 
		[self << 'CAST('.
		(self extractType: args first) makeCast printTypeOn: self.
		self << ','; prettyPrint: rec; << ')'].
	self checkStatement!

printCategoryMessage: rec args: args
	"Some messages to categories really go to them.  This handles them.  It finds the selector from
	 currentSelector instance variable."
	
	self printRealMessage: (self mapSelector: currentSelector) rec: rec args: args!

printClass: rec args: args
	"If we get here it is an error because the class message can't be sent in c++."

	Transcript show: '''class'' message not implementable.'; cr!

printCond: cond true: trueBody false: falseBody 
	"Print conditional expression"

	self precedence: (self mapPrecedence: #'*trinary*') nest:
		[cond prettyPrintOn: self.
		self nextPutAll: ' ? '; indent.
		nil = trueBody
			ifTrue: [self nextPutAll: 'UNKNOWN'; warn: 'empty body in conditional']
			ifFalse: [trueBody body prettyPrintOn: self].
		self nextPutAll: ' : '.
		nil = falseBody
			ifTrue: [self nextPutAll: 'UNKNOWN'; warn: 'empty body in conditional']
			ifFalse: [falseBody body prettyPrintOn: self].
		self unindent].
	self checkStatement.
	self warn: 'ifTrue:ifFalse: translating to ?: may not compile'.!

printConsistent: rec args: args 
	
	| num block |
	args size = 1
		ifTrue: 
			[num _ LiteralNode new value: -1.
			block _ args at: 1]
		ifFalse: 
			[(args size = 2) assert.
			num _ args at: 1.
			block _ args at: 2].
	self asExpression: 
		[self << 'BEGIN_CONSISTENT('.
		num prettyPrintOn: self.
		self << ') '.
		block prettyPrintOn: self.
		self << ' END_CONSISTENT'].
	self checkStatement!

printConstructor: rec args: args 
	"parse the receiver for self class and class names."

	(rec isMessageNode and: [(self mapSelector: rec selector) == #new])
		ifTrue: 
			[self asExpression:
				[rec arguments isEmpty
					ifTrue:
						[| newClass |
						newClass _ Smalltalk at: rec receiver name ifAbsent: [nil].
						(newClass ~~ nil and: [newClass inheritsFrom: Heaper]) ifTrue:
							[self warn: 'Bad use of operator new.'].
						self << 'new '; printBasicConstructor: (self extractType: rec) args: args]
					ifFalse:
						[rec selector == #new.AllocType:
							ifTrue: [self << 'CONSTRUCT_ON_NO_ASSIGN(';
				 						prettyPrint: rec arguments first; << ',';
										printBasicDefaultConstructor: (self extractType: rec receiver) args: args; << ')']
							ifFalse: [rec selector ~~ #new.Become:
										ifTrue: [self warn: 'Bad use of operator new.'].
									self << 'new (';
										prettyPrint: rec arguments first; << ') ';
										printBasicConstructor: (self extractType: rec) args: args]]]]
		ifFalse:
			[| type |
			type _ self extractType: rec.
			type isVector 
				ifTrue: [self << 'new ']
				ifFalse: 
					[type refType ~= #var ifTrue: 
						[self warn: 'Default create expressions only allowed in return or asssignment statements.']].
			self printBasicConstructor: (self extractType: rec) args: args].
	self checkStatement!

printConvert: rec args: args
	"Print a cast to a type."

	self asExpression: 
		[self << 'CONVERT('.
		(self extractType: args first) makeCast printTypeOn: self.
		self << ','; prettyPrint: rec; << ')'].
	self checkStatement!

printCritical: rec args: args
	self asExpression:
		[ | critical |
		self << 'BEGIN_CRITICAL_BLOCK('.
		rec prettyPrintOn: self.
		critical _ args first.	
		critical arguments size = 0 ifFalse: [self warn: 'critical blocks don''t take arguments.'].
		self << ') '.
		(args at: 1) prettyPrintOn: self.
		self << ' END_CRITICAL_BLOCK'].
	self checkStatement!

printDelayCastMacro: rec args: args
	"Print a cast to a type."

	self asExpression: 
		[self << 'DELAY_CAST('.
		(self extractType: args first) makeCast printTypeOn: self.
		self << ','; prettyPrint: rec; << ')'].
	self checkStatement!

printDelayTry: exception args: args 
	"classReference problems.ProblemListName delayTry: [foo] catch: [:broken {Promise} | bar]
	translates to
	DELAY_TRY_BEGIN(ProbList) {
		foo
	} DELAY_CATCH(broken) {
		bar
	} DELAY_TRY_END;"

	| try catch probListName |
	try _ args first.
	catch _ args at: 2.
	probListName _ self extractBlastName: exception.
	self asExpression: 
		[
		self << ('DELAY_TRY_BEGIN(', probListName, 'Filter) '); startBlock.
		self prettyPrint: try body.
		self stopBlock; << (' DELAY_CATCH(', catch arguments first variable name, ') '); startBlock.
		self prettyPrint: catch body.
		self stopBlock; << ' DELAY_TRY_END;']!

printDelete: rec args: args
	"Print a call on a destructor."

	args isEmpty assert: 'wierd delete message'.
	self asExpression: [self nextPutAll: 'delete '; prettyPrint: rec].
	self checkStatement!

printDeref: rec args: args
	"Print a cast to a type."
	self << '(*('.
	self prettyPrint: rec; << '))'!

printDestroy: rec args: args
	"Print a call on a destructor."

	args isEmpty assert: 'wierd delete message'.
	rec isSuper
		ifTrue: [self printRealMessage: #destroy rec: rec args: args "ignore override here."]
		ifFalse:
			[rec isVarNode ifTrue: [ self openBlock ].
			self asExpression:
				[self  prettyPrint: rec; << '->destroy()'.
				(rec isVarNode and: [rec isSelf not]) ifTrue:
					[self << ';  '; prettyPrint: rec; << ' = NULL /* don''t want stale (S/CHK)PTRs */']].
			self checkStatement.
			rec isVarNode ifTrue: [ self closeBlock ]]!

printDoMain: rec args: args 
	"Initializer with: argc with: argv doMain: [stuff]  translates to
		{ 	Initializer mainInit(argc,argv);
			stuff
		}"

	args count <3 ifTrue: [self warn: 'Smalltalk only initialization expression.'.  ^self.].
	self asExpression: [self << 'Initializer mainInit('; prettyPrint: (args at: 1); << ','; prettyPrint: (args at: 2) ; << ');'; cr].
	self prettyPrint: (args at: 3) body.!

printEnum: rec args: args
	self asExpression:
		[ | first |
		first := true.
		self cr; indent.
		(args at: 2) value do: [ :tag |
			self << (first ifTrue: ['typedef enum {'] ifFalse: [$,]); cr.
			(tag isKindOf: String) ifTrue:
				[self << tag.
				first ifTrue: [self << ' = 1']]
			ifFalse:
				[self << (tag at: 1) << ' = ' << (tag at: 2)].
			first := false].
		self unindent; cr; << $}; tab; << (args at: 1) value].
	self checkStatement!

printEnumFlags: rec args: args
	self asExpression:
		[ | printit bit |
		printit := [ :name :value |
			self << '
#define ' << name << ' 0x' << (value printStringRadix: 16)].
		bit := 0.
		(args at: 2) value do: [ :each |
			(each isKindOf: Symbol) ifTrue:
				[printit value: each value: bit.
				bit := bit > 0 ifTrue: [bit * 2] ifFalse: [1]]
			ifFalse:
				[1 to: each size do: [ :i |
					printit value: (each at: i) value: (i - 1) * bit].
				bit := bit > 0
					ifTrue: [bit bitShift: (each size ceilingLog: 2)]
					ifFalse: [1]]].
			self hardCR].!

printException: exception args: args 
	"classReference blast.BlastName 
		handle: [:InstanceName | recovery.    InstanceName restart] 
		do: [body]. 
	Translates to: 
	{	INSTALL.SHIELD(InstanceName); 
		SHIELD_UP_BEGIN(InstanceName, BlastName) { 
			recovery
		} SHIELD_UP_END(InstanceName);
		body;
	}"

	| iname blastName seq break |
	iname _ args first arguments first name.
	blastName _ (self extractBlastName: exception), 'Filter'.
	seq _ args first body.
	break _ true.
	seq statements last
		cast: ReturnNode into: [:node | break _ false]
		cast: SimpleMessageNode into: 
			[:last |
			(#(restart return BLAST: handle:do:) includes: last selector) ifFalse: [self warn: 'no restart or return at end of exception block'].
			last selector == #restart ifTrue: [break _ false.  seq statements removeLast].
			last selector == #return ifTrue: [seq statements removeLast]]
		others: [self warn: 'no restart or return at end of exception block'].
	"The problem.lists have 'Filter' appended to their name."
	break ifTrue: [self << 'do '].
	self asExpression: 
		[self startBlock.
		self << 'INSTALL_SHIELD(' << iname << ');'; cr.
		self << 'SHIELD_UP_BEGIN(' << iname << ', ' << blastName << ') {'.
		self indent; cr; asStatement: 
			[self prettyPrint: seq.
			break ifTrue: [self cr; << 'break;'].
			self unindent; cr; << '} SHIELD_UP_END('; << iname; << ');'; cr.
			self prettyPrint: (args at: 2) body].
		self stopBlock].
	break ifTrue: [self << ' while (FALSE);'].!

printFetch: rec args: args 
	"This is a dangerous optimization." 

	args count = 1 ifTrue:
		[self precedence: 1 do: [rec prettyPrintOn: self].
		self nextPut: $[.
		self asExpression: [(args at: 1) prettyPrintOn: self].
		self nextPut: $].
		self checkStatement]
	ifFalse: [args count = 0 ifTrue:
		[| nest prec |
		prec _ self mapPrecedence: #indirect.
		nest _ precedence < prec.
		nest ifTrue: [self << $(].
		self nextPut: $*.
		self precedence: prec do: [rec prettyPrintOn: self].
		nest ifTrue: [self << $)].
		self checkStatement]]!

printFluidBind: fluid args: args 
	"aFluidVar bind: value during: block. 
	Translates to: 
	{	FLUID_BIND(aFluidVar,value);
		block
	}"

 	args size ~= 2 ifTrue: [self warn: 'fluidBind takes exactly two arguments.'].
 	self openBlock; tab.
 	self asExpression: [self << 'FLUID_BIND('; prettyPrint: fluid; << ','; prettyPrint: args first]; << ') '.
 	self prettyPrint: (args at: 2).
 	self stopBlock!

printFluidSet: fluid args: args 
	"aFluidVar fluidVar translates to FLUID_VAR(aFluidVar)
	aFluidVar fluidVar: value translates to FLUID_VAR(aFluidVar) = value"

	self asExpression:
 		[self prettyPrint: fluid.
 		self << '.' << (self mapSelector: currentSelector) asString << '('.
		args first prettyPrintOn: self.
		self << ')'].
	self checkStatement.!

printFluidVar: fluid args: args 
	"aFluidVar fluidVar translates to FLUID_VAR(aFluidVar)
	aFluidVar fluidVar: value translates to FLUID_VAR(aFluidVar) = value"

	self asExpression:
 		[self prettyPrint: fluid.
 		self << '.' << currentSelector asString << '()'].
	self checkStatement.!

printFor: initial args: args 
	| final block var inc |
	final _ args at: 1.
	block _ args last.
	inc _ args size > 2
				ifTrue: 
					[| arg |
					arg _ args at: 2.
					(arg isKindOf: LiteralNode)
						assert: 'Loop increments must be literal numbers.'.
					arg value]
				ifFalse: [1].
	var _ block arguments at: 1.
	self startBlock.
	self nextPutAll: (TypeDescription typeName: var type with: nil), ' LoopFinal = '; prettyPrint: final; cr.
	GenerateCrutch
		ifTrue:
			[self asExpression:
				[self prettyPrint: var; nextPutAll: ' = '; prettyPrint: initial].
			self checkStatement; cr.
			self nextPutAll: 'for (;;) '; startBlock.
			self nextPutAll: 'if ('.
			self asExpression:
				[self nextPutAll: var name , (inc >= 0
												ifTrue: [' > ']
												ifFalse: [' <= ']); nextPutAll: 'LoopFinal'].
			self nextPutAll: ')'; startBlock; nextPutAll: 'break;'; stopBlock; cr.
			self asStatement: [self printBlockArgs: #() body: block body].
			self cr; nextPutAll: var name.
			inc >= 0
				ifTrue: [self nextPutAll: ' += ' , inc printString]
				ifFalse: [self nextPutAll: ' -= ' , inc negated printString].
			self checkStatement; stopBlock]
		ifFalse:
			[self asExpression: 
				[self nextPutAll: 'for ('.
				self prettyPrint: var; nextPutAll: ' = '; prettyPrint: initial.
				self nextPutAll: '; ' , var name , (inc >= 0
							ifTrue: [' <= ']
							ifFalse: [' >= ']); nextPutAll: 'LoopFinal'.
				self nextPutAll: '; ' , var name.
				inc >= 0
					ifTrue: [self nextPutAll: ' += ' , inc printString]
					ifFalse: [self nextPutAll: ' -= ' , inc negated printString].
				self nextPutAll: ') '].
			self asStatement: [self printBlockArgs: #() body: block body]].
	self stopBlock.!

printForAlmost: initial args: args 
	| final block var inc |
	final _ args at: 1.
	block _ args last.
	inc _ args size > 2
				ifTrue: 
					[| arg |
					arg _ args at: 2.
					(arg isKindOf: LiteralNode)
						assert: 'Loop increments must be literal numbers.'.
					arg value]
				ifFalse: [1].
	var _ block arguments at: 1.
	self startBlock.
	self nextPutAll: (TypeDescription typeName: var type with: nil), ' LoopFinal = '; prettyPrint: final; cr.
	GenerateCrutch
		ifTrue:
			[self asExpression:
				[self prettyPrint: var; nextPutAll: ' = '; prettyPrint: initial].
			self checkStatement; cr.
			self nextPutAll: 'for (;;) '; startBlock.
			self nextPutAll: 'if ('.
			self asExpression:
				[self nextPutAll: var name , (inc >= 0
												ifTrue: [' >= ']
												ifFalse: [' < ']); nextPutAll: 'LoopFinal'].
			self nextPutAll: ')'; startBlock; nextPutAll: 'break;'; stopBlock; cr.
			self asStatement: [self printBlockArgs: #() body: block body].
			self cr; nextPutAll: var name.
			inc >= 0
				ifTrue: [self nextPutAll: ' += ' , inc printString]
				ifFalse: [self nextPutAll: ' -= ' , inc negated printString].
			self checkStatement; stopBlock]
		ifFalse:
			[self asExpression: 
				[self nextPutAll: 'for ('.
				self prettyPrint: var; nextPutAll: ' = '; prettyPrint: initial.
				self nextPutAll: '; ' , var name , (inc >= 0
							ifTrue: [' < ']
							ifFalse: [' >= ']); nextPutAll: 'LoopFinal'.
				self nextPutAll: '; ' , var name.
				inc >= 0
					ifTrue: [self nextPutAll: ' += ' , inc printString]
					ifFalse: [self nextPutAll: ' -= ' , inc negated printString].
				self nextPutAll: ') '].
			self asStatement: [self printBlockArgs: #() body: block body]].
		self stopBlock.!

printForDown: initial args: args 
	| final block var |
	final _ args at: 1.
	block _ args last.
	var _ block arguments at: 1.
	self startBlock.
	self nextPutAll: (TypeDescription typeName: var type with: nil), ' LoopFinal = '; prettyPrint: final; cr.
	GenerateCrutch
		ifTrue:
			[self asExpression:
				[self prettyPrint: var; nextPutAll: ' = '; prettyPrint: initial].
			self checkStatement; cr.
			self nextPutAll: 'for (;;) '; startBlock.
			self nextPutAll: 'if ('.
			self asExpression: [self nextPutAll: var name , ' < '; nextPutAll: 'LoopFinal'].
			self nextPutAll: ')'; startBlock; nextPutAll: 'break;'; stopBlock; cr.
			self asStatement: [self printBlockArgs: #() body: block body].
			self cr; nextPutAll: var name, ' -= 1'; checkStatement; stopBlock]
		ifFalse:
			[self asExpression: 
				[self nextPutAll: 'for ('.
				self prettyPrint: var; nextPutAll: ' = '; prettyPrint: initial.
				self nextPutAll: '; ' , var name , ' >= '; nextPutAll: 'LoopFinal'.
				self nextPutAll: '; ' , var name, ' -= 1'.
				self nextPutAll: ') '].
			self asStatement: [self printBlockArgs: #() body: block body]].
	self stopBlock.!

printForEach: stepper args: args
"What this actually must do is convert from a 'Stepper forEach: aBlock' to
        STEPPER forEach: [:ITVAR {TYPE} | BODY] translates to
        BEGIN_FOR_EACH(TYPE,ITVAR,(STEPPER)) {
        	BODY
        } END_FOR_EACH;
"
        | block arg |
        args size = 1 assert: 'bad collect: expression'.
        (args first isBlockNode) 
                ifFalse: ["Fallback in case a block is passed in as an argument."
                        ^self printRealMessage: #forEach rec: stepper args: args].
        block _ args first.
        self asExpression: 
                [self << 'BEGIN_FOR_EACH('.
                arg _ block arguments first.
                (self extractType: arg type) makeCast printTypeOn: self.
                self << ','; emphasis: 2; << arg name; emphasis: 1; << ',('.
                stepper prettyPrintOn: self.
                self << ')) '; startBlock.
                self asStatement: [block body prettyPrintOn: self].
                self stopBlock; << ' END_FOR_EACH;'].!

printForEachPromise: stepper args: args
"What this actually must do is convert from a 'Stepper forEach: aBlock' to
        STEPPER forEachPromise: [:ITVAR {TYPE} | BODY] translates to
        BEGIN_FOR_EACH_PROMISE(TYPE,ITVAR,(STEPPER)) {
        	BODY
        } END_FOR_EACH_PROMISE;
"
        | block arg |
        args size = 1 assert: 'bad collect: expression'.
        (args first isBlockNode) 
                ifFalse: ["Fallback in case a block is passed in as an argument."
                        ^self printRealMessage: #forEach rec: stepper args: args].
        block _ args first.
        self asExpression: 
                [self << 'BEGIN_FOR_EACH_PROMISE('.
                arg _ block arguments first.
                (self extractType: arg type) makeCast printTypeOn: self.
                self << ','; emphasis: 2; << arg name; emphasis: 1; << ',('.
                stepper prettyPrintOn: self.
                self << ')) '; startBlock.
                self asStatement: [block body prettyPrintOn: self].
                self stopBlock; << ' END_FOR_EACH_PROMISE;'].!

printForIndices: stepper args: args
"       Stepper forIndices: [:Key {IntegerVar} Value {Type2} | Body] translates to
        FOR_INDICES(Key,Type2,Value,(Stepper),{Body});
"
        | block arg |
        args size = 1 assert: 'bad collect: expression'.
        (args first isBlockNode) 
                ifFalse: ["Fallback in case a block is passed in as an argument."
                        ^self printRealMessage: #forIndices rec: stepper args: args].
        block _ args first.
        self asExpression: 
                [self << 'BEGIN_FOR_INDICES('.
                arg _ block arguments first.
                self emphasis: 2; << arg name; emphasis: 1; << $,.
                arg _ block arguments last.
                (self extractType: arg type) makeCast printTypeOn: self.
                self << ','; emphasis: 2; << arg name; emphasis: 1.
                self << ',('.
                stepper prettyPrintOn: self.
                self << ')) '; startBlock.
                self asStatement: [block body prettyPrintOn: self].
                self stopBlock; << ' END_FOR_INDICES;'].!

printForKeyValues: stepper args: args
"       Stepper forKeyValues: [:Key {Type1} Value {Type2} | Body] translates to
        FOR_POSITIONS(Type1,Key,Type2,Value,(Stepper),{Body});
"
        | block arg |
        args size = 1 assert: 'bad collect: expression'.
        (args first isBlockNode) 
                ifFalse: ["Fallback in case a block is passed in as an argument."
                        ^self printRealMessage: #forKeyValues rec: stepper args: args].
        block _ args first.
        self asExpression: 
                [self << 'BEGIN_FOR_POSITIONS('.
                arg _ block arguments first.
                (self extractType: arg type) makeCast printTypeOn: self.
                self << ','; emphasis: 2; << arg name; emphasis: 1; << $,.
                arg _ block arguments last.
                (self extractType: arg type) makeCast printTypeOn: self.
                self << ','; emphasis: 2; << arg name; emphasis: 1.
                self << ',('.
                stepper prettyPrintOn: self.
                self << ')) '; startBlock.
                self asStatement: [block body prettyPrintOn: self].
                self stopBlock; << ' END_FOR_POSITIONS;'].!

printForPositions: stepper args: args
"       Stepper forKeyValues: [:Key {Type1} Value {Type2} | Body] translates to
        FOR_POSITIONS(Type1,Key,Type2,Value,(Stepper),{Body});
"
        | block arg |
        args size = 1 assert: 'bad collect: expression'.
        (args first isBlockNode) 
                ifFalse: ["Fallback in case a block is passed in as an argument."
                        ^self printRealMessage: #forKeyValues rec: stepper args: args].
        block _ args first.
        self asExpression: 
                [self << 'BEGIN_FOR_POSITIONS('.
                arg _ block arguments first.
                (self extractType: arg type) makeCast printTypeOn: self.
                self << ','; emphasis: 2; << arg name; emphasis: 1; << $,.
                arg _ block arguments last.
                (self extractType: arg type) makeCast printTypeOn: self.
                self << ','; emphasis: 2; << arg name; emphasis: 1.
                self << ',('.
                stepper prettyPrintOn: self.
                self << ')) '; startBlock.
                self asStatement: [block body prettyPrintOn: self].
                self stopBlock; << ' END_FOR_POSITIONS;'].!

printFunction: rec args: args
	"Some smalltalk messages get translated into C++ functions (rounded, 
	 xuInteger, etc.).  This handles them.  It finds the selector from
	 currentSelector instance variable."
	
	| p sel | 
	sel _ self mapSelector: currentSelector.
	p _ self mapPrecedence: sel.
	p >= precedence ifTrue: [stream nextPut: $(].
	self indent.
	self asExpression: 
		[| complex |
		self << sel << $(.
		self prettyPrint: rec.
		complex _ rec isComplex.
		args do: [:arg |
			self << ', '.
			(complex or: [arg isComplex]) ifTrue: [self cr].
			self prettyPrint: arg].
		self << $)].
	p >= precedence ifTrue: [stream nextPut: $)].
	self unindent; checkStatement!

printHack: rec args: args

	self << '/* Hack !!!!!!!! */'; cr!

printIf: cond args: args 
	self printIf: cond
		true: (args at: 1)
		false: (args size = 2 ifTrue: [args at: 2])!

printIf: cond true: trueBody false: falseBody 
	"Print conditional expression"

	self isStatement ifFalse: [^self
			printCond: cond
			true: trueBody
			false: falseBody].
	"compensate for crippled c++ compilers that can't handle
&&."
	(GenerateCrutch and: [cond isCrippled]) ifTrue: 
		[^self crippledIf: cond true: trueBody false: falseBody].
	self indent; asExpression: 
		["negate the condition if there is a false body but no
true body."
		self nextPutAll: 'if ('.
		nil = trueBody
			ifTrue: [self printNot: cond args: #()]
			ifFalse: [cond prettyPrintOn: self].
		self nextPutAll: ') '];
		unindent.
	self asStatement: 
		["Only print else if there is a false body and a true
body."
		nil = trueBody ifFalse: 
				[trueBody prettyPrintOn: self.
				nil = falseBody ifFalse: [self nextPutAll: ' else ']].
		nil = falseBody ifFalse: [falseBody prettyPrintOn:
self]]!

printIfdef: rec args: args
	self printConditionalCompile: 'ifdef' with: rec name
		with: (args at: 1)
		with: (args count > 1 ifTrue: [args at: 2])!

printIfndef: rec args: args
	self printConditionalCompile: 'ifndef' with: rec name
		with: (args at: 1)
		with: (args count > 1 ifTrue: [args at: 2])!

printIfNot: cond args: args 
	self printIf: cond true: (args size = 2 ifTrue: [args at: 2]) false: (args at: 1)!

printIgnore: ignore args: args 
	"Don't generate any code."!

printInsistent: rec args: args 
	
	| num block |
	args size = 1
		ifTrue: 
			[num _ LiteralNode new value: -1.
			block _ args at: 1]
		ifFalse: 
			[(args size = 2) assert.
			num _ args at: 1.
			block _ args at: 2].
	self asExpression: 
		[self << 'BEGIN_INSISTENT('.
		num prettyPrintOn: self.
		self << ') '.
		block prettyPrintOn: self.
		self << ' END_INSISTENT'].
	self checkStatement!

printIntegerFunction: rec args: args
	"Some smalltalk messages get translated into C++ static member functions (xuInteger, etc.).  This handles them.  It finds the selector from currentSelector instance variable."
	
	| p sel |
	args count > 0 ifTrue: [self warn: 'Arguments to integer selector'].
	sel _ self mapSelector: currentSelector.
	p _ self mapPrecedence: sel.
	p >= precedence ifTrue: [stream nextPut: $(].
	self indent.
	self asExpression: 
		[self << 'IntegerPos::make ('.
		self prettyPrint: rec.
		self << $)].
	p >= precedence ifTrue: [stream nextPut: $)].
	self unindent; checkStatement!

printInvert: num args: args 
	"This is a little painful to do without overrides.  ~ is the only
	 'infix' operator that is a one-argument construct in c++."

	args isEmpty assert: 'What''s an infix ~ operator?'.
	0 = precedence ifTrue: [stream nextPut: $(].
	self precedence: 1 do: 
		[stream nextPut: $~.
		num prettyPrintOn: self].
	0 = precedence ifTrue: [stream nextPut: $)].
	self checkStatement!

printInvoke: rec args: args
	self precedence: 1 do:
		[self nextPutAll: '(*('.
		rec prettyPrintOn: self.
		self nextPutAll: ')) ('.
		args
			do: [ :arg | arg prettyPrintOn: self]
			andBetweenDo: [self nextPut: $,; space].
		self nextPut: $)].
	self checkStatement!

printIsKindOf: rec args: args 
	"Need to put cat_ before the class reference."

	| c |
	self precedence: 0 do: [self prettyPrint: rec].
	self nextPutAll: '->isKindOf(cat_'; asExpression: 
		[c _ self classRef: args first.
		c = nil
			ifTrue: [self error: 'bad class description for isKindOf.']
			ifFalse: [self nextPutAll: (self mapVarName: c)]].
	self nextPut: $); checkStatement!

printKnownBug: rec args: args

	self << '/* Known bug !!!!!!!! */'; cr!

printLOG: logger args: args 
	"logger LOG: [:oo | ... oo ...] translates to
	LOG(logger,oo) {
		... oo ...
	} END_LOG;"
	
	| block ooName |
	args size = 1 assert: 'Must be exactly one block as argument'.
	block _ args first.
	block arguments size = 1 assert: 'Must be exactly one block argument'.
	ooName _ block arguments first.
	self asExpression:
		[self << 'LOG('; prettyPrint: logger; << ','; << ooName name; << ') '; startBlock.
		self asStatement: [self prettyPrint: block body].
		self stopBlock; << ' END_LOG;']!

printMightNotImplement: cond args: args 
	self nextPutAll: 'BLAST(NOT_YET_IMPLEMENTED)'.
	self checkStatement!

printNegated: rec args: ignored 
	"print the selector as the name of a function rather than a message send."

	self precedence: (self mapPrecedence: (self mapSelector: currentSelector))
		nest: 
			[self << '-'.
			self prettyPrint: rec].
	self checkStatement!

printNot: cond args: args 
	"with an argument creates a negation predicate."

	args isEmpty
		ifTrue: 
			[0 = precedence ifTrue: [stream nextPut: $(].
			self precedence: 1 do: 
				[stream nextPut: $!!.
				cond prettyPrintOn: self].
			0 = precedence ifTrue: [stream nextPut: $)]]
		ifFalse: [self
				printFunction: #not
				origSel: #not
				recClass: (self classRef: cond)
				args: args].
	self checkStatement!

printNotNULL: rec args: args 
	"Convert the smalltalk construct:  'Expr notNULL: [:Var {Type} | Body] else: [Else]' (The else is optional) to:
		`BEGIN_CHOOSE(Expr) {
			BEGIN_KIND(Type,Var) {
				Body
			} END_KIND;
			BEGIN_ISNULL {
				Else
			} END_ISNULL;
		} END_CHOOSE;'
	"
	
	| block param |
	self << 'BEGIN_CHOOSE('; asExpression: [self prettyPrint: rec]; <<$); startBlock.
	block _ args first.
	param _ block arguments first.
	self << 'BEGIN_KIND(' << param type name << $,.
	self << param name << $).
	self startBlock; prettyPrint: block body.
	self stopBlock; << ' END_KIND;'.
	args size = 2 ifTrue:
		[self cr; << 'BEGIN_ISNULL '; startBlock.
		self prettyPrint: (args at: 2); stopBlock; << 'END_ISNULL'; cr].
	
	self stopBlock; << ' END_CHOOSE;'!

printNotWhile: cond args: args 
	"This should really detect repeat loops and do the right thing."

	self indent; asExpression: 
		[self nextPutAll: 'while ('.
		self printNot: cond body args: #().
		self nextPutAll: ') '];
		unindent.
	args isEmpty
		ifTrue: [self nextPutAll: '{}'; cr]
		ifFalse: [self asStatement: [(args at: 1) prettyPrintOn: self]]!

printObsolete: rec args: args

	self << '/* Obsolete !!!!!!!! */'; cr!

printOr: cond args: args 
	"the other condition must be simple."

	| p  arguments |
	(args first isBlockWithNumArgs: 0)
		ifFalse: [self error: 'bad conditional'].
	p _ self mapPrecedence: #'||'.
	p > precedence ifTrue: [stream nextPut: $(].
	self indent.
	self precedence: p do:
		[cond prettyPrintOn: self.
		arguments _ args first body statements.
		arguments size = 1 assert: 'wrong number of arguments for operator.'.
		stream space; nextPutAll: #'||'; space.
		self indent; printArguments: arguments complex: cond isComplex; unindent].
	p > precedence ifTrue: [stream nextPut: $)].
	self unindent.
	self checkStatement!

printPackMacro: rec args: args
	"Print a package extraction."

	self asExpression: 
		[self << 'PACK('.
		(self extractType: args first) makeCast printTypeOn: self.
		self << ','; prettyPrint: rec; << ')'].
	self checkStatement!

printPasse: rec args: arg
	| savedEmph |
	savedEmph _ self emphasis.
	self warn: 'method passe!!'.
	self emphasis: 2.
	self << 'BLAST(PASSE_METHOD);'; cr; emphasis: savedEmph!

printPostDec: rec args: args
	"" 

	self printBump: rec args: args pre: '' post: $-!

printPostInc: rec args: args
	"" 

	self printBump: rec args: args pre: '' post: $+!

printPreDec: rec args: args
	"" 

	self printBump: rec args: args pre: $- post: ''!

printPreInc: rec args: args
	"" 

	self printBump: rec args: args pre: $+ post: ''!

printPseudoconstructor: rec args: args 
	"parse the receiver for self class and class names."

	| type  catName |
	type _ self extractType: rec.
	catName _ self stripName: type baseType.
	self << catName << '::make ('.
	self asExpression: [self indent; printArguments: args; unindent].
	self << ')'.
	self checkStatement!

printPut: rec args: args 
	"This is a dangerous optimization."
	
	args count = 2 ifTrue:
		[self precedence: 1 do: [rec prettyPrintOn: self].
		self nextPut: $[.
		self asExpression: 
			[(args at: 1) prettyPrintOn: self.
			self nextPutAll: '] = '.
			(args at: 2) prettyPrintOn: self].
		self checkStatement]
	ifFalse: [args count = 1 ifTrue:
		[| nest prec |
		prec _ self mapPrecedence: #indirect.
		nest _ precedence <= prec.
		nest ifTrue: [self << $(].
		self nextPut: $*.
		self precedence: prec do: [rec prettyPrintOn: self].
		nest ifTrue: [self << $)].
		self nextPutAll: ' = '.
		(args at: 1) prettyPrintOn: self]]!

printReact: matriarch args: args
"What this actually must do is convert from a 'model react: aBlock' to
        MODEL react: [:ITVAR {TYPE} | BODY] translates to
        REACT(TYPE,ITVAR,(model))
        	{BODY};
        ENDREACT()
"
        | block arg |
        (args size = 0 and: [matriarch name = 'self']) 
        	ifTrue: [^self printRealMessage: #react rec: matriarch args: args]
        	ifFalse: [args size = 1 ifFalse: [self error: 'bad translation: no arguments']] .
        (args first isBlockNode) 
                ifFalse: ["Fallback in case a block is passed in as an argument."
                        ^self printRealMessage: #react: rec: matriarch args: args].
        block _ args first.
        self asExpression: 
                [self << 'REACT('.
                arg _ block arguments first.
                (self extractType: arg type) makeCast printTypeOn: self.
                self << ','; emphasis: 2; << arg name; emphasis: 1; << ',('.
                matriarch prettyPrintOn: self.
                self << ')) '; startBlock.
                self asStatement: [block body prettyPrintOn: self].
                self stopBlock; << ';'; cr; << 'ENDREACT()'; cr].!

printReanimate: rec args: args 
	"f reanimate: [:w {BackFollowRecorder} | ...] 
	should translate to 
	BEGIN_REANIMATE(f,BackFollowRecorder,w) { 
	... 
	} END_REANIMATE;"
	
	| block arg |
	args size = 1 assert: 'bad reanimate: expression'.
	args first isBlockNode
		ifFalse: ["Fallback in case a block is passed in as an argument."
			^self printRealMessage: #reanimate rec: rec args: args].
	block _ args first.
	self asExpression: 
		[self << 'BEGIN_REANIMATE('.
		rec prettyPrintOn: self.
		arg _ block arguments first.
		self << ','.
		(self extractType: arg type) makeCast printTypeOn: self.
		self << ','; emphasis: 2; << arg name; emphasis: 1.
		self << ') '; startBlock.
		self asStatement: [block body prettyPrintOn: self].
		self stopBlock; << ' END_REANIMATE;']!

printRefAssign: rec args: args 
	"Translate the assignment message for Cells.  They act like pointers to other values."

	self nextPut: $*.
	self precedence: 1 do: [rec prettyPrintOn: self].
	self asExpression: 
		[self nextPutAll: ' = '.
		(args at: 1) prettyPrintOn: self].
	self checkStatement!

printRefCreate: rec args: args 
	"Translate the creation message for Cells.  Cells act like pointers to other values."

	self nextPut: $&.
	self precedence: 1 do: [rec prettyPrintOn: self].
	self checkStatement!

printRefValue: rec args: args 
	"Translate the retrieval message for Cells.  They act like pointers to other values."

	self nextPut: $*.
	self precedence: 1 do: [rec prettyPrintOn: self].
	self checkStatement!

printRepeat: body args: args 
	self asExpression: 
		[self nextPutAll: 'for ( ; ; ) '].
	self asStatement:
		[self printBlockArgs: #() body: body]!

printRequires: rec args: args

	self << 'REQUIRES (' << (args first name copyUpTo: $.) << ')'.
	self checkStatement.!

printShouldImplement: cond args: args 
	self nextPutAll: 'BLAST(NOT_YET_IMPLEMENTED)'.
	self checkStatement!

printShouldNotImplement: cond args: args 
	self nextPutAll: 'BLAST(SHOULD_NOT_IMPLEMENT)'.
	self checkStatement!

printShowCursor: cursor args: args
	"translates Cursor x showWhile: aBlock to just the contents of the block."
	
	self prettyPrint: args first!

printStaticFunction: rec args: args
	"Some smalltalk messages get translated into C++ static member functions (xuInteger, etc.).  This handles them.  It finds the selector from currentSelector instance variable."
	
	| p sel | 
	sel _ self mapSelector: currentSelector.
	p _ self mapPrecedence: sel.
	p >= precedence ifTrue: [stream nextPut: $(].
	self indent.
	self asExpression: 
		[| complex |
		self << (self stripName: rec value staticReceiver) << '::'.
		self << sel << $(.
		self prettyPrint: rec.
		complex _ rec isComplex.
		args do: [:arg |
			self << ', '.
			(complex or: [arg isComplex]) ifTrue: [self cr].
			self prettyPrint: arg].
		self << $)].
	p >= precedence ifTrue: [stream nextPut: $)].
	self unindent; checkStatement!

printStaticMemberPointer: rec args: args
	"Translate the construction of pointers to static member functions.
		SomeClass pointerToStaticMember: #selector:with:
	becomes:
		SomeClass::selector
		
	and
		SomeClass pointerToStaticMember: #selector:with: with: '(void) (*) (int)'
	becomes:
		((void) (*) (int))SomeClass::selector"

	self asExpression:
		[args size >= 2 ifTrue:
			[self << '(' << (args at: 2) value << ')'].
		self << '&'.
		(self extractType: rec) makeCast printTypeOn: self.
		self << '::' << (self mapSelector: (args at: 1) value)].
	self checkStatement!

printThingToDo: rec args: args

	self << '/* '.
	(rec isSelf not and: [rec isVarNode]) ifTrue: [self << (rec name, ' -- ')].
	self << 'Thing to do !!!!!!!! */'; cr!

printTimesRepeat: count args: args 
	
	self startBlock.
	self asExpression:  
		[self nextPutAll: 'for (Int32 T_LoopVar = '; prettyPrint: count.
		self nextPutAll: '; T_LoopVar > 0; T_LoopVar -= 1) '].
	self asStatement: [self printBlockArgs: #() body: (args at: 1) body].
	self stopBlock.!

printTranslateOnly: rec args: args

	(rec isKindOf: LiteralNode) ifTrue:
		[self << rec value; cr]
	ifFalse: [(rec body isKindOf: SequenceNode) ifTrue:
		[rec body statements do: [ :statement |
			statement prettyPrintOn: self.
			self cr.]]
	ifFalse:
		[rec body prettyPrintOn: self]]!

printUnimplemented: cond args: args 
	self nextPutAll: 'BLAST(NOT_YET_IMPLEMENTED)'.
	self checkStatement!

printUnwind: rec args: args 
	"[stuff] valueOnUnwindDo: (SomeClass bomb.BombName: charge) translates to
		{	PLANT_BOMB(BombName,Boom);
			ARM_BOMB(Boom);
			{ stuff }
			DISARM_BOMB(Boom);
		}
	valueNowOrOnUnwindDo is similar, but without the DISARM_BOMB"

	| sel |
	self asExpression:
		[sel _ currentSelector.
		self nextPut: ${; indent.
		args first prettyPrintOn: self.
		self cr.
		rec prettyPrintOn: self.
		sel == #valueOnUnwindDo: ifTrue:
			[self cr; nextPutAll: 'DISARM_BOMB(Boom);'].
		self unindent; cr; nextPut: $}].!

printWhile: cond args: args 
	"This should really detect repeat loops and do the right thing."

	(GenerateCrutch and: [cond body statements size = 1 and: [cond body statements first isCrippled]]) 
		ifTrue: [^self printCrippledWhile: cond body statements first args: args].
	self indent; asExpression: 
		[self nextPutAll: 'while ('.
		cond body prettyPrintOn: self.
		self nextPutAll: ') '];
		unindent.
	args isEmpty
		ifTrue: [self nextPutAll: '{}'; cr]
		ifFalse: [self asStatement: [(args at: 1) prettyPrintOn: self]]!

printWillNotImplement: cond args: args 
	self nextPutAll: 'BLAST(WILL_NOT_IMPLEMENT)'.
	self checkStatement! !

!HxxPrintStream methodsFor: 'maps'!

mapCastName: name 
	"Map from smalltalk casting selectors to cxx casts."

	^ self class mapCastName: name!

mapClassVarName: name 
	"Mangle class instance variable names and change self to class name in class methods"

	(self isInstVar: name) ifTrue: [^name].			"no mangle on inst var names"
	(name = 'self')
		 ifTrue: [(self getClass isMeta) 
		 	ifTrue: [^self className]
		 	ifFalse: [^ name]].
	self getClass withAllSuperclasses do: [ :parent |
		(((self classVarNamesOf: parent) includes: name asSymbol) 
				or: [parent instVarNames includes: name]) 
			ifTrue: [^(self stripName: self className) , '::' , name]].
	^name!

mapOverride: sel
	^ self class mapOverride: sel!

mapOverrideDef: sel
	"Map from CXX selectors methods that handle them specially."

	^ self class mapOverrideDef: sel!

mapPrecedence: sel

	^ self class mapPrecedence: sel!

mapSelector: sel 
	"Map from smalltalk selectors to cxx selectors. Strip the selector, then go 
	through the map. 
	Warn the user when two selectors map to the same thing."

	currentSelector _ sel.
	^ self class mapSelector: sel!

mapVarName: name 
	"Map from smalltalk variable names to cxx variable names."

	^ self class mapVarName: (self mapClassVarName: name)! !

!HxxPrintStream methodsFor: 'version tracking'!

copyrightNotice
	"Output our copyright header"

	self nextPutAll: '/* '; emphasis: 9.
	self nextPutAll: 'Copyright Xanadu Operating Company.  All Rights Reserved. */'; cr.
	self nextPutAll: '
/******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
'.
	self nextPutAll: 'Output from ', Smalltalk version; unindent; cr.
	stream emphasis: 1; nextPutAll: '*/'.
	self cr; cr! !

!HxxPrintStream methodsFor: 'stream accessing'!

<< anObject 
	anObject isString
		ifTrue: [self nextPutAll: anObject]
		ifFalse: [anObject isCharacter
				ifTrue: [self nextPut: anObject]
				ifFalse: [self print: anObject]].
	^self!

atEnd
	^stream atEnd!

close
	^stream close!

contents
	^stream contents!

emphasis
	^stream emphasis!

emphasis: emph
	^stream emphasis: emph!

isExternalStream
	^stream isKindOf: BufferedExternalStream!

name
	(stream respondsTo: #name)
		ifFalse: [^'internal stream'].
	^stream name!

next
	^stream next!

nextPut: elem
	^stream nextPut: elem!

nextPutAll: coll
	"an optimization"
	^stream nextPutAll: coll!

position
	^stream position!

position: newPosition
	^stream position: newPosition!

prettyPrint: obj
	obj prettyPrintOn: self!

print: object
	^object printOn: self!

printOn: aStream
	aStream nextPutAll: self class name.
	aStream nextPutAll: ' on ', self name.!

reset
	stream reset!

size
	^ stream size!

space
	"Append a space character to the receiver."

	self nextPut: Character space!

store: object
	^object storeOn: self!

tab
	"Append a tab character to the receiver."

	self nextPut: Character tab!

{IntegerVar} timeStampTransientLine
	"Report which line of the 'self timeStamp' output records the current date and
	time so that this line can be excluded from compares"
	
	^18! !

!HxxPrintStream methodsFor: 'tabbing'!

column
	self thingToDo. "do something smarter here"
	^self position - lastCR!

cr
	stream crtab: indent.
	lastCR := stream position - (indent * 8 min: 40)!

crtab
	stream crtab: indent+1.
	lastCR := stream position - (((indent + 1) * 8) min: 40).!

crtab: num
	stream crtab: indent + num.
	lastCR := stream position - (8 * (num + indent) min: 40)!

hardCR
	stream cr.
	lastCR := stream position!

indent
	"increment the indent level."

	indent _ indent + 1!

unindent
	"deccrement the indent level."

	indent _ indent - 1 max: 0! !

!HxxPrintStream methodsFor: 'private:'!

asExpression: aBlock
	"Shallow bind the precedence to the precedence for statements."

	| oldp |
	oldp _ precedence.
	precedence _ self mapPrecedence: #'*expression*'.
	aBlock value.
	precedence _ oldp!

asStatement: aBlock
	"Shallow bind the precedence to the precedence for statements."

	| oldp |
	oldp _ precedence.
	precedence _ self mapPrecedence: #'*statement*'.
	aBlock value.
	precedence _ oldp!

classFromSelector: sel
	| start underSel {String} |
	underSel _ HxxPrintStream stripDotUDot: sel.
	start _ 1.
	1 to: underSel size do: [:i || aChar | aChar _ underSel at: i.
		aChar = $. ifTrue: [start _ i + 1].
		aChar = $: ifTrue: [^underSel copyFrom: start to: i - 1]].
	^underSel copyFrom: start to: underSel size!

cxxNextPutAll: aString
	| match replace i |
	match _ OrderedCollection new.
	match add: Character esc; 
		add: Character cr; 
		add: Character lf; 
		add: Character backspace; 
		add: Character newPage; 
		add: Character tab; 
		add: $\; 
		add: $'; 
		add: $"; 
		add: (Character value: 0).
	"note that both cr and lf get converted to \n"
	replace _ #($e $n $n $b $f $t $\ $' $" $0 ).
	^aString do: 
			[:aChar |
			i _ match indexOf: aChar.
			0 = i ifTrue: [stream nextPut: aChar]
				ifFalse: [stream nextPut: $\; 
							nextPut: (replace at: i)]]!

error: aString 
	methodName == nil
		ifTrue: [super error: aString]
		ifFalse: [super error: self getClass name , '>' , methodName , ': ' , aString]!

getClass
	^ myClass!

{BooleanVar} isOverridden: cls {Behavior} selector: sel {Symbol}
	cls allSubclasses do: [:c {Behavior} |
		(c includesSelector: sel)
			ifTrue: [^true]].
	^false!

{String} makePC: className {String}

	| tName |
	'char' = className ifTrue: [^'character'].
	tName _ className asString copy.
	tName at: 1 put: ((tName at: 1) asLowercase).
	^ tName!

operator: opSym
	^ ('operator', opSym) asSymbol!

precedence: p do: aBlock
	"This essentially does shwallow binding on precedence."

	| oldp |
	oldp _ precedence.
	precedence _ p max: 1.
	aBlock value.
	precedence _ oldp!

precedence: p nest: aBlock
	"For the execution of aBlock, set the precedence to p.  If this
	 increases the precedence, surround the expression by parentheses."

	| oldp nest |
	oldp _ precedence.
	precedence _ p max: 1.
	nest _ precedence >= oldp.
	nest ifTrue: [stream nextPut: $(].
	aBlock value.
	precedence _ oldp.
	nest ifTrue: [stream nextPut: $)]!

printConditionalCompile: token with: symbol with: first with: second
	self nextPut: Character cr; nextPut: $#;
		emphasis: 2; nextPutAll: (self class stripName: token); emphasis: 1;
		space; nextPutAll: symbol; cr.
	first prettyPrintOn: self.
	second ~~ nil ifTrue:
		[self nextPut: Character cr; nextPut: $#;
			emphasis: 2; nextPutAll: 'else'; emphasis: 1;
			space; printComment: symbol; cr.
		second prettyPrintOn: self].
	self nextPut: Character cr; nextPut: $#;
		emphasis: 2; nextPutAll: 'endif'; emphasis: 1;
		space; printComment: symbol; cr!

queueStream
	"Make another stream like me but onto a text.  This gets used to queue things."

	^self class on: (TextStream on: String new) class: self getClass!

setClass: c
	myClass _ c!

setStream: aStream {WriteStream} class: c {Behavior}

	stream _ aStream.
	indent _ 0.
	precedence _ self mapPrecedence: #'*statement*'.
	myClass _ c.
	insideCreate _ false.
	myGlobalMemberState _ true!

strip: sel 
	"Remove all #with: keywords, remove colons and capitalize the letter following. 
	Convert an embedded .U. into an underscore. Ignore anything else that follows 
	a period (upto the next colon). 
	If it begins with 'DOT', replace that with a '.' to signify a message to a Var"
	self passe.
	"^ self class strip: sel"!

{Symbol} stripBlast: sel {Symbol}

	sel size > 6 ifFalse: [^ sel].
	(sel testPrefix: 'bomb.') ifTrue: [^ sel copyFrom: 6 to: sel size].
	(sel testPrefix: 'blast.') ifTrue: [^ sel copyFrom: 7 to: sel size].
	(sel testPrefix: 'problems.') ifTrue: [^sel copyFrom: 10 to: sel size].
	self warn: 'no blast or bomb to strip...'.
	^ '/* Missing bomb stuff */'!

stripName: sel 
	"Remove all #with: keywords, remove colons and capitalize the letter following. 
	Convert an embedded .U. into an underscore. Ignore anything else that follows 
	a period (upto the next colon). 
	If it begins with 'DOT', replace that with a '.' to signify a message to a Var"
	^ self class stripName: sel!

{Boolean} testFieldSelector: sel {Symbol}
	^self class testFieldSelector: sel!

{void} warn: aString 

	(self getClass == nil or: [parsedMethod == nil])
		ifTrue: [Transcript show: aString; cr.
				^VOID].
	Transcript show: self getClass name , '>' , parsedMethod selector , ': ' , aString.
	Transcript cr.
	WarnedMethods = nil 
		ifTrue: [WarnedMethods _ Set new].
	WarnedMethods add: (MethodRep make: self getClass with: parsedMethod selector)! !

!HxxPrintStream methodsFor: 'crutch'!

closeBlock
	"The stop of a method block, primarily."

	self unindent; nextPut: $}!

crippledIf: cond true: trueBody false: falseBody
	"Print and if statement with no embedded and: or or: expressions."

	self openBlock; tab.
	self << 'BooleanVar crutch_Flag;'; cr.
	self indent; emphasis: 3; << '/* '.
	self asExpression: [self prettyPrint: cond]; emphasis: 1; unindent; << ' */'; cr.
	self asExpression: [self printCrippledCondition: cond; cr].
	nil = trueBody 
		ifTrue: [self nextPutAll: 'if (!!crutch_Flag) ']
		ifFalse: [self nextPutAll: 'if (crutch_Flag) '].
	self asStatement: 
		["Only print else if there is a false body and a true body."
		nil = trueBody ifFalse: 
				[trueBody prettyPrintOn: self.
				nil = falseBody ifFalse: [self nextPutAll: ' else ']].
		nil = falseBody ifFalse: [falseBody prettyPrintOn: self]].
	self stopBlock!

crippledReturn: cond
	"Print a return statement with no embedded and: or or: expressions."

	self openBlock; tab.
	self << 'BooleanVar crutch_Flag;'; cr.
	self indent; emphasis: 3; << '/* '.
	self asExpression: [self prettyPrint: cond]; emphasis: 1; unindent; << ' */'; cr.
	self asExpression: [self printCrippledCondition: cond; cr].
	self << 'return crutch_Flag;'.
	self stopBlock!

openBlock
	"The start of a method block, primarily."

	self nextPutAll: '{'; indent!

{void} printCrippledCondition: cond
	"Unroll a nested conditional computation into a series of 
	 statements that change and test a condition variable."

	cond isCrippled not ifTrue: 
		[self cr; indent; << 'crutch_Flag = '; prettyPrint: cond; nextPutAll: ';'; unindent.
		^self].
	cond selector == #not ifTrue:
		[self printCrippledCondition: cond receiver; cr.
		self << 'crutch_Flag = !!crutch_Flag;'].
	cond selector == #and: ifTrue:
		[self printCrippledCondition: cond receiver; cr.
		self << 'if(crutch_Flag) '; openBlock.
		self printCrippledCondition: cond arguments first body statements first.
		self stopBlock].
	cond selector == #or: ifTrue:
		[self printCrippledCondition: cond receiver; cr.
		self << 'if(!!crutch_Flag) '; openBlock.
		self printCrippledCondition: cond arguments first body statements first.
		self stopBlock].!

