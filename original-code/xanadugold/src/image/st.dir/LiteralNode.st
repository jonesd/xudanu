'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:17 pm'!

LeafNode subclass: #LiteralNode
	instanceVariableNames: '
		value {Symbol | String | Number | Array | Boolean | UndefinedObject}
		mySubLiterals {nil | (OrderedCollection of: LiteralNode)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
LiteralNode comment:
'Class LiteralNode represents an occurrence of a literal.

Instance Variables:
	value	<Object>'!



!LiteralNode methodsFor: 'initialize-release'!

value: lit
	value _ lit!

value: lit subLiterals: subLiterals {nil | (OrderedCollection of: LiteralNode)}
	
	value _ lit.
	mySubLiterals _ subLiterals! !

!LiteralNode methodsFor: 'accessing'!

booleanValue
	^(value == true or: [value == false])
		ifTrue: [value]
		ifFalse: [nil]!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^none value]!

numberValue
	^value respondsToArithmetic
		ifTrue: [value]
		ifFalse: [nil]!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[mySubLiterals ~~ nil
			ifTrue: [mySubLiterals do: [:each {ParameterNode} | 
				| result |
				result _ each properDetect: test ifNone: [nil].
				result ~~ nil ifTrue: [^result]]].
		^none value]!

selector
	"In order to be more polymorphic with MethodNode and SimpleMessageNode"
	
	(value isKindOf: Symbol) assert.
	^value!

subLiterals

	^mySubLiterals!

value
	^value! !

!LiteralNode methodsFor: 'testing'!

isInvariantIn: codeStream
	^true! !

!LiteralNode methodsFor: 'printing'!

{Interval} preferedSelection: text {Text | String}
	"Browser hack"
	
	(text at: self sourcePosition first) ~= $#
		ifTrue: [^self sourcePosition].
	Scanner new 
		tokensIn: text 
		do: [:tok :span :tokType |
			span last <= self sourcePosition last
				ifTrue: [^span first to: sourcePosition last]
				ifFalse: [^self sourcePosition first + 1 to: self sourcePosition last]]
		startingAt: sourcePosition first + 1.
	^self sourcePosition first + 1 to: self sourcePosition last!

prettyPrintOn: aStream
	aStream printLiteral: value!

printOn: aStream indent: level 
	aStream store: value! !

!LiteralNode methodsFor: 'code generation'!

emitBranch: codeStream to: label if: boolean
	codeStream mustBeSimple
		ifFalse:
			[boolean = value ifTrue: [codeStream putBranch: label.  ^self].
			boolean not = value ifTrue: [^self]].
	"If a non-boolean value, will cause an error at run time."
	super emitBranch: codeStream to: label if: boolean!

emitSend: codeStream selector: selector arguments: args
	"Literals have a fixed class,
	so we can use a no-check send."
	codeStream sendNoCheck: selector numArgs: args size!

emitStore: codeStream value: val from: var 
	codeStream
		error: #error
		with: value printString, ' is read-only '
		from: var.
	^self!

emitStorePop: codeStream value: val from: var 
	codeStream
		error: #error
		with: value printString, ' is read-only '
		from: var.
	^self!

emitValue: codeStream
	codeStream pushConstant: value! !