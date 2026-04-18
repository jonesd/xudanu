'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:28 pm'!

NameScope subclass: #StaticScope
	instanceVariableNames: 'dictionaryBlock '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
StaticScope comment:
'I represent a name scope for static variables -- a class pool, a shared pool, or a global dictionary like Smalltalk.  Eventually this will include workspace-relative variables as well.

The dictionary is represented by a block, rather than a reference to the dictionary itself, because the dictionary might get created on the fly.  The only time this happens right now is when declaring new class variables interactively.  The "block" may actually be an Association, since it only has to respond to the value message.'!


!StaticScope methodsFor: 'accessing'!

variableAt: name from: varNode
	| sym |
	sym _ Symbol findInterned: name.
	sym notNil ifTrue:
		[| assoc |
		assoc _ dictionaryBlock value associationAt: sym ifAbsent:
			[^outerScope variableAt: name from: varNode].
		^StaticVariable new binding: assoc].
	^outerScope variableAt: name from: varNode! !

!StaticScope methodsFor: 'enumerating'!

associationsDo: aBlock
	dictionaryBlock value associationsDo: aBlock.
	outerScope associationsDo: aBlock!

keysDo: aBlock
	dictionaryBlock value keysDo: aBlock.
	outerScope keysDo: aBlock.! !

!StaticScope methodsFor: 'private: private'!

setBlock: aBlock
	dictionaryBlock _ aBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StaticScope class
	instanceVariableNames: ''!


!StaticScope class methodsFor: 'instance creation'!

classVariables: aClass
	^self new setBlock: [aClass classPool]!

variables: aDictionary
	^self new setBlock: (Association key: nil value: aDictionary)! !