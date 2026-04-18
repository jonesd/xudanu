'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:23 pm'!

ValueNode subclass: #SimpleMessageNode
	instanceVariableNames: 'receiver selector arguments precedence '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
SimpleMessageNode comment:
'Class SimpleMessageNode represents a message in a program - a real message, not a possibly expandable special message.

We delay expansion of special messages until code generation time, so that (in the future) we can generate code from the same tree with different expansion rules.

Instance Variables:
	receiver	<ValueNode>
	selector	<Symbol>
	arguments	<Seq of: ValueNode>
	precedence	<nil | Integer>

'!


!SimpleMessageNode methodsFor: 'initialize-release'!

receiver: rcvr selector: sel arguments: args
	receiver _ rcvr.
	selector _ sel.
	arguments _ args.
	precedence _ nil  "compute on demand"! !

!SimpleMessageNode methodsFor: 'accessing'!

absoluteSourcePosition
	"Answer the sourcePosition of the first child-node of this node.
	For messages, this is the sourcePosition of the message's receiver"

	^receiver absoluteSourcePosition!

arguments
	^arguments!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^self receiver detect: test ifNone:
			[self arguments do: [ :each | | result |
				result := each detect: test ifNone: [nil].
				result ~~ nil ifTrue: [^result]].
			^none value]]!

fetchTypeClass
	"the class of objects of this type"
	^receiver fetchTypeClass!

{void} keywordSpansIn: aString {Text | String} do: aBlock {BlockClosure of: Interval with: Symbol}

	| parts {OrderedCollection of: String} start {Integer} end {Integer} span {Interval} |
	parts _ selector keywords.
	start _ self sourcePosition first.
	1 to: parts size do: [:i |
		arguments size >= i
			ifTrue: [end _ (arguments at: i) absoluteSourcePosition -1]
			ifFalse: [end _ self sourcePosition last].
		span _ Scanner new theTokenSpanIn: aString within: (start to: end).
		((parts at: i) = (aString copyFrom: span first to: span last) asString) assert.
		aBlock value: span value: (parts at: i) asSymbol.
		i < parts size
			ifTrue: [start _ (arguments at: i) sourcePosition last + 1]]!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^self receiver properDetect: test ifNone:
			[self arguments do: [ :each | | result |
				result _ each properDetect: test ifNone: [nil].
				result ~~ nil ifTrue: [^result]].
			^none value]]!

receiver
	"for cascading"
	^receiver!

selector
	^selector!

transcribeSTVOn: stv {SmalltalkVTranscriber}

	self transcribeSTVSelector: selector with: arguments on: stv.! !

!SimpleMessageNode methodsFor: 'printing'!

{void} highlightSelfIn: text {Text}
	
	text 
		emphasizeFrom: receiver absoluteSourcePosition
		to: receiver sourcePosition last
		with: 3.
	arguments do: [:arg {ValueNode} |
		text 
			emphasizeFrom: arg absoluteSourcePosition
			to: arg sourcePosition last 
			with: 3].
	self keywordSpansIn: text do: [:span {Interval} :part {Symbol} |
		text 
			emphasizeIn: span
			with: 15]!

precedence
	precedence == nil ifTrue: [precedence _ selector precedence].
	^precedence!

prettyPrintOn: aStream
	aStream printMessage: selector receiver: receiver arguments: arguments!

printMessageOn: aStream indent: level 
	| prev arg indent thisKey keywords |
	arguments size = 0 
		ifTrue: [aStream space; nextPutAll: selector. ^self].
	keywords _ selector keywords.
	prev _ receiver.
	1 to: arguments size do:
		[:part | arg _ arguments at: part.
		thisKey _ keywords at: part.
		((prev isKindOf: BlockNode) or:
		 [((prev isKindOf: SimpleMessageNode) and: [prev precedence >= 3]) or:
		  [((arg isKindOf: BlockNode) and: [arg isComplex and: [thisKey ~= #do:]]) or:
		   [(arguments size > 2) or:
		    [(selector == #ifTrue:ifFalse:)]]]])
			ifTrue: [aStream crtab: level+1. indent _ 1] "newline after big arguments"
			ifFalse: [aStream space. indent _ 0].
		aStream nextPutAll: thisKey; space.
		arg
			printOn: aStream
			indent: level + 1 + indent
			precedence: (self precedence = 2 ifTrue: [1] ifFalse: [self precedence]).
		prev _ arg]!

printOn: aStream indent: level 
	receiver
		printOn: aStream
		indent: level
		precedence: self precedence.
	self
		printMessageOn: aStream
		indent: level!

printOn: strm indent: level precedence: p 
	| parenthesize |
	parenthesize _ 
		self precedence > p or: [p = 3 and: [self precedence = 3 "both keywords"]].
	parenthesize ifTrue: [strm nextPut: $(].
	self printOn: strm indent: level.
	parenthesize ifTrue: [strm nextPut: $)]! !

!SimpleMessageNode methodsFor: 'code generation'!

emitExceptReceiver: codeStream
	"Cascades use this to emit each message"
	arguments do: [:arg | arg emitValue: codeStream].
	"Let the receiver decide what kind of send to use."
	codeStream noteSourceNode: self.
	receiver emitSend: codeStream selector: selector arguments: arguments!

emitValue: codeStream
	receiver emitValue: codeStream.
	self emitExceptReceiver: codeStream! !

!SimpleMessageNode methodsFor: 'testing'!

isComplex
	^arguments size > 2!

isCrippled
	"Return true if this parsenode can't be handled as a conditional by crippled
	 c++ compilers.  Specific examples are 'and:' in if statements."
	
	^(selector == #not and: [receiver isCrippled])
		or: [selector == #and:
		or: [selector == #or:]]!

isMessageNode
	"Retrun true if the receiver represents a message send."
	^true! !

!SimpleMessageNode methodsFor: 'private: private'!

{StatementNode} innerReceiver

	^receiver innerReceiver!

transcribeSTVTypeOn: stv

	stv change: (self receiver absoluteSourcePosition - 1) asInterval to: '"'.
	stv change: (self lastSourcePosition + 1) asInterval to: '"'.! !