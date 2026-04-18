'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:24 pm'!

LeafNode subclass: #VariableNode
	instanceVariableNames: 'name '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
VariableNode comment:
'Class VariableNode represents a variable - argument, temporary, instance, class, pool, or global.

Instance Variables:
	name	<String>
'!


!VariableNode methodsFor: 'initialize-release'!

name: aSymbol
	name _ aSymbol! !

!VariableNode methodsFor: 'accessing'!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^none value]!

fetchTypeClass
	"the class of objects of this type"
	(name = 'void') ifTrue: [^nil].
	^name asSymbol!

name
	"for building name scopes"
	^name!

sourcePosition
	"VariableNodes just store the initial position,
	not the Interval."
	^sourcePosition to: sourcePosition + name size - 1! !

!VariableNode methodsFor: 'testing'!

isInvariantIn: codeStream
	"Ask the codeStream if this variable
	has an invariant binding"
	^codeStream variableIsInvariant: name!

isSelf
	"Check if this is the special variable 'self'"
	^name = 'self'!

isSuper
	"Check if this is the (non-variable) 'super'.
	It's easier to do this than to detect 'super'
	syntactically."
	^name = 'super'!

isVarNode
	"Return true if the receiver represents a variable reference."
	^true! !

!VariableNode methodsFor: 'printing'!

prettyPrintOn: aStream
	"name = 'self' ifTrue: [^aStream printSelf]."
	name = 'super' ifTrue: [^aStream printSuper].
	aStream printVariableName: name!

printOn: aStream indent: level 
	aStream nextPutAll: name! !

!VariableNode methodsFor: 'code generation'!

emitSend: codeStream selector: selector arguments: args
	"Emit different send code if the receiver is 'super',
	or if the receiver is 'self' and we can tell that the
	receiver cannot be an immediate object."
	self isSelf
		ifTrue:
			[codeStream isForNonImmediate
				ifTrue: [codeStream sendNonImmediate: selector numArgs: args size]
				ifFalse: [codeStream send: selector numArgs: args size]]
		ifFalse:
			[self isSuper
				ifTrue: [codeStream sendSuper: selector numArgs: args size]
				ifFalse: [codeStream send: selector numArgs: args size]]!

emitStore: codeStream value: value from: assignment
	codeStream codeStore: name value: value from: self in: assignment!

emitStorePop: codeStream value: value from: assignment
	codeStream codeStorePop: name value: value from: self in: assignment!

emitValue: codeStream
	codeStream codeLoad: name from: self! !