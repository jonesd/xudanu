'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:34 pm'!

Object subclass: #MethodNodeHolder
	instanceVariableNames: 'methodNode compiledMethod sourceInfo '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
MethodNodeHolder comment:
'I encapsulate a MethodNode to provide compatible protocol for the old compiler.'!


!MethodNodeHolder methodsFor: 'initialize-release'!

method: aMethod
	compiledMethod _ aMethod!

node: aMethodNode
	methodNode _ aMethodNode!

sourceInfo: aSourceInfo
	sourceInfo _ aSourceInfo! !

!MethodNodeHolder methodsFor: 'accessing'!

decompileString
	^methodNode decompileString!

selector
	^methodNode selector!

sourceMap
	^sourceInfo collect: [:info | info at: 1]!

variableMap
	^sourceInfo collect: [:info | info at: 2]! !

!MethodNodeHolder methodsFor: 'accessing TEMPORARY'!

tempNames
	"We can't compute the temp names yet"
	^nil! !

!MethodNodeHolder methodsFor: 'code generation'!

generate
	"Just return the already-compiled method"
	^compiledMethod!

generateNoQuick
	"This is needed by the debugger.
	Generate a method that has a frame."
	^compiledMethod withFrame! !