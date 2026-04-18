'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:18 pm'!

ProgramNode subclass: #MethodNode
	instanceVariableNames: 'selector primitive block returnType constructorList '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
MethodNode comment:
'Class MethodNode represents an entire method.

Instance Variables:
	selector	<Symbol>
	primitive	<nil | Integer>
	block	<BlockNode>
'!


!MethodNode methodsFor: 'initialize-release'!

selector: sel primitive: prim block: blk
	selector _ sel.
	primitive _ prim.
	block _ blk!

selector: sel primitive: prim block: blk type: type
	selector _ sel.
	primitive _ prim.
	block _ blk.
	returnType _ type!

selector: sel primitive: prim block: blk type: type constructors: constructors
	selector _ sel.
	primitive _ prim.
	block _ blk.
	returnType _ type.
	constructorList _ constructors.! !

!MethodNode methodsFor: 'accessing'!

addConstructorItem: aStmt


	constructorList = nil ifTrue: [constructorList _ OrderedCollection new].
	constructorList add: aStmt!

block
	^block!

constructorList
	^ constructorList!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[self returnType ~~ nil ifTrue:
			[^self returnType detect: test ifNone:
				[self block detect: test ifNone: none]]
		ifFalse:
			[^self block detect: test ifNone: none]]!

{CommentHolder | nil} fetchClientComment: src {String}
	"This is the client comment"
	"The rest are not"
	"(Parser new 
			parse: (MethodNode sourceCodeStringAt: #fetchClientComment:)
			class: MethodNode
			notifying: nil)
		fetchClientComment: (MethodNode sourceCodeStringAt: #fetchClientComment:)"
	
	| chs {SequenciableCollection of: CommentHolder} |
	chs _ self commentHolders.
	(chs == nil or: [chs isEmpty])
		ifTrue: [^nil].
	^chs at: 1!

fileOutSTVOn: stv {Stream}
	from: source {String}
	protocol: prot {Symbol}
	temps: temps {Array of: (SequenceNode of: ParameterNode)}
	
	"method declaration"
	returnType ~~ nil ifTrue:
		[ | start |
		returnType
			cast: MessageNode into:
				[ :mn | start := mn receiver absoluteSourcePosition]
			others:
				[start := returnType absoluteSourcePosition].
		stv nextPut: $";
			nextPutAll: (source
				copyFrom: start
				to: returnType lastSourcePosition);
			nextPutAll: '" '].
	selector isKeyword ifTrue:
		[selector keywords with: block arguments do:
			[ :kw :param | stv space;
				nextPutAll: (ProgramNode mapSTVSelector: kw);
				space.
			param fileOutSTVOn: stv from: source]]
	ifFalse: [selector isBinary ifTrue:
		[stv space; nextPutAll: selector; space.
		block parameters first fileOutSTVOn: stv from: source]
	ifFalse:
		[stv nextPutAll: (ProgramNode mapSTVSelector: selector)]].
	
	stv nextPutAll: '
	"<' ; nextPutAll: prot; nextPutAll: '>"'.
	self printCommentsUsing: [ :c |
		stv crtab; nextPut: $"; nextPutAll: c; nextPut: $"].

	stv cr.
	(block body temporaries isEmpty and: [temps isEmpty]) ifFalse:
		[stv crtab; nextPutAll: '|'.
		block body temporaries do: [ :gt |
			stv space.
			gt fileOutSTVOn: stv from: source].
		1 to: temps size do: [ :i |
			stv nextPutAll: '
		"[';
			print: i;
			nextPutAll: ']"'.
			(temps at: i) do: [ :bt |
				stv space.
				bt fileOutSTVOn: stv from: source]].
		stv nextPutAll: ' |'].
	
	block body statements do: [ :st |
		stv crtab.
		st fileOutSTVOn: stv from: source].!

{void} keywordSpansIn: aString {Text | String} do: aBlock {BlockClosure of: Interval with: Symbol}

	| parts {OrderedCollection of: String} start {Integer} end {Integer} span {Interval} |
	parts _ selector keywords.
	returnType == nil
		ifTrue: [start _ self sourcePosition first]
		ifFalse: [start _ returnType sourcePosition last +1].
	1 to: parts size do: [:i |
		block arguments size >= i
			ifTrue: [end _ (block arguments at: i) absoluteSourcePosition -1]
			ifFalse: [end _ block body absoluteSourcePosition -1].
		span _ Scanner new theTokenSpanIn: aString within: (start to: end).
		((parts at: i) = (aString copyFrom: span first to: span last) asString) assert.
		aBlock value: span value: (parts at: i) asSymbol.
		i < parts size
			ifTrue: [start _ (block arguments at: i) sourcePosition last + 1]]!

primitive
	^primitive!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^self block properDetect: test ifNone: none]!

returnType
	^returnType!

returnType: type
	returnType _ type!

returnTypeDescription
	^ TypeDescription fromParse: returnType!

selector
	^selector!

selector: sel
	selector _ sel!

transcribeSTVOn: stv {SmalltalkVTranscriber}

	| commentStart bodyStart |
	returnType ~~ nil ifTrue:
		[returnType transcribeSTVTypeOn: stv].
	self transcribeSTVSelector: selector with: block arguments on: stv.
	stv beginBody: block body sourcePosition first
		temps: block body temporaries isEmpty not.
	commentStart := stv source findString: '"'
		startingAt: (block arguments isEmpty
			ifTrue: [returnType == nil
				ifTrue: [1]
				ifFalse: [returnType lastSourcePosition]]
			ifFalse: [block arguments last lastSourcePosition]).
	block body temporaries isEmpty not ifTrue:
		[bodyStart := stv source findString: '|'
			before: block body temporaries first sourcePosition first]
	ifFalse: [bodyStart := block body sourcePosition first].
	(commentStart = 0 or: [commentStart > bodyStart]) ifTrue:
		[commentStart := bodyStart].
	stv firstComment: commentStart.!

withoutFirstStatement
	"a copy of this method without the first statement. used in translating constructors"
	
	| newBlock |
	newBlock := BlockNode new
		arguments: block arguments
		body: (SequenceNode new
			temporaries: block body temporaries
			statements: ((block body statements copy) removeFirst; yourself);
			sourcePosition: block body sourcePosition;
			comment: block body comment;
			yourself);
		sourcePosition: block sourcePosition;
		comment: block comment;
		yourself.
	^MethodNode new selector: selector
		primitive: primitive
		block: newBlock
		type:returnType
		constructors: constructorList copy;
		sourcePosition: sourcePosition;
		comment: comment;
		yourself! !

!MethodNode methodsFor: 'printing'!

diagnosticCodeOn: aStream
	(selector testPrefix: 'printOn') ifFalse:
		[aStream << 'if (!!FLUID_VAR(inPrintOn)) {'; cr.
		aStream << '	debugIndent(cerr);';cr.
		(aStream getClass isMeta or: [selector testPrefix: 'create']) not ifTrue: [
			aStream << '	cerr << this << " -> ";'; cr].
		aStream << '	cerr << "'
				  << (aStream getClass) << '::' << selector << ' ( "'.
		block arguments do: [ :ba |
			(TypeDescription fromParse: ba type) isUnused ifFalse:
				[aStream << ' << "'.
				 aStream precedence: 9 do: [ba prettyPrintOn: aStream].
				 aStream << ' = " << ' << ba variable name << ' << ", "']].
		aStream << ' << " )\n";}'; cr.
		"(self returnsVoid or: [returnType = nil or: 
			[((self returnTypeDescription) refType) = #var]]) ifFalse:
				[ aStream << 'PLANT_BOMB(printHeaperResult,result);'; cr.
				  aStream << 
				  	'if (!!FLUID_VAR(inPrintOn))
		ARM_BOMB(result,(SPTR(Heaper)*)&returnValue);'; cr]."
		aStream << 'FLUID_BIND(debugIndent, FLUID_VAR(debugIndent) + 1);'; cr]
	ifTrue: [ aStream << 'FLUID_BIND(inPrintOn,TRUE);'; cr].!

{Interval} highlightSelfIn: text {Text}
	
	self keywordSpansIn: text do: [:span {Interval} :part {Symbol} |
		text emphasizeIn: span with: 14]!

isStub
	"This is a hack for the c++ translator.  Return true if I have the STUB attribute."

	^returnType ~~ nil
		and: [nil ~~ (returnType
			detect: [ :node |
				(node isKindOf: MessageNode)
					and: [node selector == #STUB]]
			ifNone: [nil])]!

{Interval} preferedSelection: text {Text | String}
	
	| start parser |
	start _ nil.
	self keywordSpansIn: text do: [:span {Interval} :part {Symbol} |
		start == nil
			ifTrue: [start _ span first]].
	(parser _ Parser new) parseSelector: text.	
	^start to: (parser endOfLastToken min: text size)!

prettyPrintOn: aStream 
	"Check all the comments for the appropriate override string 
	(there may be different ones for different languages)."

	| override |
	aStream precedence: 9 do: [aStream
			printPattern: selector
			arguments: block arguments
			type: returnType
			with: self constructorList].
	aStream startBlock.	
	"temp hack for c++ returns with strong pointers"
	"(self returnsVoid or: [returnType = nil or: [self returnTypeDescription specialReturn not]])
		ifFalse: [aStream precedence: 9 do: [(self returnTypeDescription) makeStrong printTypeOn: aStream.
				aStream tab; nextPutAll: 'returnValue;'; cr]].  moved to HxxPrintStream printReturn"
	HxxPrintStream printExecution ifTrue: [ self diagnosticCodeOn: aStream ].
	override _ false.
	self comment size = 0 ifFalse: [override _ aStream printComments: self comment.
		aStream cr; cr].	"this should print the smalltalk as a comment"
	override
		ifTrue: [aStream printComment: 'Overridden Smalltalk'; cr; printComment: block printString]
		ifFalse: [primitive == nil ifFalse: [aStream printPrimitive: primitive; cr].
			block body isEmpty ifFalse: [block body prettyPrintOn: aStream]].
	aStream stopBlock.
	aStream flushQueue!

prettyPrintPatternOn: aStream 
	self comment size = 0 ifFalse: [aStream printComments: self comment; cr].
	aStream
		printPattern: selector
		arguments: block arguments
		type: returnType
		with: (self constructorList)!

printOn: aStream
	"For methods, and only methods,
	don't wrap the result in {}."
	self printOn: aStream indent: 0!

printOn: aStream indent: level
	returnType == nil
		ifFalse:
			[aStream nextPut: ${.
			returnType printOn: aStream indent: level + 1.
			aStream nextPutAll: '} '].
	selector precedence = 1
		ifTrue: 
			[aStream nextPutAll: selector]
		ifFalse: 
			[selector keywords with: block arguments do: 
				[:s :arg | 
				aStream nextPutAll: s; space.
				arg printOn: aStream indent: level.
				aStream space]].
	self comment == nil
		ifFalse: 
			[aStream crtab: level + 1.
			self printCommentOn: aStream indent: level + 1.
			aStream cr].
	primitive notNil
		ifTrue: 
			[aStream crtab: level + 1;
				nextPutAll: '<primitive: ';
				print: primitive;
				nextPutAll: '>'].
	block printMethodBodyOn: aStream indent: level + 1!

printPatternOn: aStream
	returnType == nil
		ifFalse:
			[aStream nextPut: ${.
			returnType printOn: aStream indent: 1.
			aStream nextPutAll: '} '].
	selector precedence = 1
		ifTrue: 
			[aStream nextPutAll: selector]
		ifFalse: 
			[selector keywords with: block arguments do: 
				[:s :arg | 
				aStream nextPutAll: s; space.
				arg printOn: aStream indent: 0.
				aStream space]].
	self comment == nil
		ifFalse: 
			[aStream crtab.
			self printCommentOn: aStream indent: 1.
			aStream cr].
	primitive notNil
		ifTrue: 
			[aStream crtab: 1;
				nextPutAll: '<primitive: ';
				print: primitive;
				nextPutAll: '>'].!

returnsVoid
	"This is a hack for the c++ translator.  Return true if my return type is void."

	^returnType ~~ nil
		and: [#('void' 'NOWAIT') includes: returnType innerReceiver name]! !

!MethodNode methodsFor: 'code generation'!

emitEffect: codeStream
	"Compile the body of a method"
	"codeStream hasn't had its local variables
	initialized yet."
	self initMethod: codeStream.
	block body emitEffect: codeStream.
	"Check for an implicit ^self at the end of the method."
	codeStream reachable ifTrue:
		[codeStream returnsNonSelf ifTrue:
			["THIS MESSAGE HAS BEEN DISABLED
			IN RESPONSE TO CUSTOMER REQUEST."
			"codeStream error: #warning with: 'Implicit ^self not allowed with explicit ^ elsewhere' from: self"].
		"We generate the code explicitly, rather than using
		emitReturn:, so we get an appropriate source map entry."
		(VariableNode new name: 'self') emitValue: codeStream.
		codeStream noteSourceNodeEnd: self.
		codeStream putMethodReturn].
	codeStream leaveScope!

emitValue: codeStream inContext: ctxt
	"Compile an expression to be evaluated."
	"codeStream hasn't had its local variables
	initialized yet."
	self initMethod: codeStream.
	ctxt isNil ifFalse: [codeStream bindRemote: block arguments first variable in: ctxt].
	block body emitReturn: codeStream from: self.
	codeStream leaveScope! !

!MethodNode methodsFor: 'private: private'!

initMethod: codeStream
	"Initialize the codeStream, and
	handle the primitive if any"
	codeStream addMethodVars.
	block initScope: codeStream.
	primitive notNil
		ifTrue:
			[codeStream putPrimitive: primitive]! !

!MethodNode methodsFor: 'smalltalk: passe'!

{CommentHolder | nil} fetchClientComment
	"This is the client comment"
	"The rest are not"
	"(Parser new 
			parse: (MethodNode sourceCodeStringAt: #fetchClientComment)
			class: MethodNode
			notifying: nil)
		fetchClientComment"
	
	self passe. "use fetchClientComment:"! !