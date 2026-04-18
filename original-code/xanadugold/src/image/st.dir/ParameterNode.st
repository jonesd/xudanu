'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:19 pm'!

ProgramNode subclass: #ParameterNode
	instanceVariableNames: 'type variable '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
ParameterNode comment:
'Class ParameterNode represents a variable binding (method argument, block argument, or temporary variable).

Instance Variables:
	type	<nil | Symbol>
	variable	<VariableNode>
'!


!ParameterNode methodsFor: 'initialize-release'!

variable: var type: t
	type _ t.
	variable _ var! !

!ParameterNode methodsFor: 'accessing'!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[self type ~~ nil
			ifTrue: [^self type detect: test ifNone: none]
			ifFalse: [^none value]]!

name
	^variable name!

sourcePosition
	^sourcePosition isNil
		ifTrue: [variable sourcePosition]
		ifFalse: [sourcePosition]!

transcribeSTVOn: stv {SmalltalkVTranscriber}

	type ~~ nil ifTrue:
		[type transcribeSTVTypeOn: stv]!

type
	^type!

variable
	"Needed for getting last var to return from empty block,
	and for building name scopes"
	^variable! !

!ParameterNode methodsFor: 'printing'!

prettyPrintClassVarOn: aStream
	aStream printClassVariable: variable type: type!

prettyPrintInstVarOn: aStream
	aStream printInstVariable: variable type: type!

prettyPrintOn: aStream
	aStream printParameter: variable type: type!

prettyPrintTempOn: aStream
	aStream printTemp: variable type: type!

printOn: aStream indent: level
	variable printOn: aStream indent: level.
	type == nil
		ifFalse:
			[aStream nextPutAll: ' {'.
			type printOn: aStream indent: level + 1.
			aStream nextPut: $}]! !