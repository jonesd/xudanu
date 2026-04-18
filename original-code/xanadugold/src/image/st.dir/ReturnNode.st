'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:22 pm'!

StatementNode subclass: #ReturnNode
	instanceVariableNames: 'value '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
ReturnNode comment:
'Class ReturnNode represents a method return (^).

Instance Variables:
	value	<ValueNode>
'!


!ReturnNode methodsFor: 'initialize-release'!

value: val
	value _ val! !

!ReturnNode methodsFor: 'accessing'!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^self value detect: test ifNone: none]!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^self value properDetect: test ifNone: none]!

value
	^value! !

!ReturnNode methodsFor: 'printing'!

prettyPrintOn: aStream 
	value comment size = 0 ifFalse: [aStream printComments: value comment; cr].
	aStream printReturn: value.!

printOn: aStream indent: level 
	aStream nextPut: $^.
	value printOn: aStream indent: level.
	value printCommentOn: aStream indent: level! !

!ReturnNode methodsFor: 'code generation'!

emitEffect: codeStream
	value emitReturn: codeStream from: self!

emitLocalReturn: codeStream from: bodyNode
	"Avoid generating an unnecessary local return
	when the body of a block ends with a method return."
	value emitReturn: codeStream from: self!

emitReturn: codeStream from: returnNode
	"Avoid generating an unnecessary return
	in anomalous cases such as ^(x ifTrue: [^y])."
	value emitReturn: codeStream from: self!

emitValue: codeStream
	value emitReturn: codeStream from: self! !