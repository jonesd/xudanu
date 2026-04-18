'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:13 pm'!

LeafNode subclass: #BlockNode
	instanceVariableNames: 'arguments body '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
BlockNode comment:
'Class BlockNode represents a block, with or without arguments.  Local temporaries, if any, are bound in the SequenceNode which is the body.

Instance Variables:
	arguments	<Array of: ParameterNode>
	body		<ValueNode>  normally, but not necessarily, a SequenceNode
'!


!BlockNode methodsFor: 'initialize-release'!

arguments: args body: seq
	arguments _ args.
	body _ seq!

body: seq
	arguments _ #().
	body _ seq! !

!BlockNode methodsFor: 'accessing'!

arguments
	"for printing method header,
	checking numArgs for control messages,
	and binding remote variables"
	^arguments!

body
	"for de-blocking args of conditionals, loops,
	and methods"
	^body!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	| |
	(test value: self) ifFalse:
		[self arguments do: [ :arg |
			(test value: arg) ifTrue:
				[^arg]].
		^self body detect: test ifNone: none]!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	| |
	(test value: self) ifFalse:
		[self arguments do: [ :each {ParameterNode} | 
			| result |
			result _ each properDetect: test ifNone: [nil].
			result ~~ nil ifTrue: [^result]].
		^self body properDetect: test ifNone: none]!

transcribeSTVOn: stv {SmalltalkVTranscriber}

	stv blockTemporaries: body temporaries! !

!BlockNode methodsFor: 'testing'!

isBlockNode
	"Return true if this node is a block.  The default is false."
	^true!

isBlockWithNumArgs: nargs
	^arguments size = nargs!

isComplex
	^body isComplex! !

!BlockNode methodsFor: 'transforming'!

arithmeticLoopFrom: initial by: increment almostTo: limit
	"I am a block of the form [:var | body],
	the body of an arithmetic loop.
	Generate an ArithmeticLoopNode."
	^ArithmeticLoopNode new
		variable: (arguments at: 1) variable
		initialValue: initial
		increment: increment
		almostTo: limit
		body: body!

arithmeticLoopFrom: initial by: increment to: limit
	"I am a block of the form [:var | body],
	the body of an arithmetic loop.
	Generate an ArithmeticLoopNode."
	^ArithmeticLoopNode new
		variable: (arguments at: 1) variable
		initialValue: initial
		increment: increment
		limit: limit
		body: body!

forEachLoopFrom: stepExpr
	"I am a block of the form [:var | body], the body of a forEach loop.
	Generate an ForEachLoopNode."
	^ForEachLoopNode new
		stepper: stepExpr
		variable: (arguments at: 1) variable
		body: body!

forKeyValuesLoopFrom: stepExpr
	"I am a block of the form [:key :value | body], the body of a forKeyValues loop.
	Generate an ForKeyValueLoopNode."
	^ForKeyValueLoopNode new
		stepper: stepExpr
		key: (arguments at: 1) variable
		value: (arguments at: 2) variable
		body: body! !

!BlockNode methodsFor: 'printing'!

prettyPrintOn: aStream
	aStream printBlockArgs: arguments body: body!

printArgumentsOn: aStream indent: level 
	arguments size = 0
		ifFalse: 
			[arguments do: 
				[:arg | 
				aStream nextPut: $:.
				arg printOn: aStream indent: level.
				aStream space].
			aStream nextPutAll: '| ']!

printMethodBodyOn: aStream indent: level
	"Print the temps and body of a method"
	body isEmpty ifFalse:
		[aStream crtab: level.
		body printOn: aStream indent: level]!

printOn: aStream indent: level 
	body isComplex ifTrue: [aStream crtab: level].
	aStream nextPut: $[.
	self printArgumentsOn: aStream indent: level.
	"If >0 temps or >1 statement, put all statements on separate lines"
	(body isComplex and: [arguments size > 0])
		ifTrue: [aStream crtab: level].
	body printOn: aStream indent: level.
	aStream nextPut: $]! !

!BlockNode methodsFor: 'code generation'!

emitBody: codeStream
	"The codeStream invokes this to compile
	the body of the block,
	including the final return."
	(body isEmpty and: [arguments isEmpty not])
		ifTrue: [arguments last variable emitLocalReturn: codeStream from: body]
		ifFalse: [body emitLocalReturn: codeStream from: body]!

emitSend: codeStream selector: selector arguments: args
	"Blocks (closures) have a fixed class,
	so we can use a no-check send."
	codeStream sendNoCheck: selector numArgs: args size!

emitValue: codeStream
	"This is handled specially, so that the codeStream
	can choose its block implementation strategy."
	codeStream codeBlock: self!

emitValue: codeStream forAssignment: assignNode
	"This is handled specially, because the variable
	represented by varNode should be treated
	as if it had already received a value."
	codeStream noteStore: assignNode variable.
	self emitValue: codeStream!

initScope: codeStream
	"Give the codeStream the variables"
	codeStream topNode: self.  "do this first in case of error"
	codeStream arguments: arguments! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BlockNode class
	instanceVariableNames: ''!


!BlockNode class methodsFor: 'instance creation'!

body: seq
	^self new arguments: #() body: seq! !