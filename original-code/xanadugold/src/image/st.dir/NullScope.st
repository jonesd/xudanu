'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:26 pm'!

NameScope subclass: #NullScope
	instanceVariableNames: ''
	classVariableNames: 'NullScopeInstance '
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
NullScope comment:
'I represent the null scope -- the empty outermost scope that is the outermost of every chain.'!


!NullScope methodsFor: 'accessing'!

undeclared: name from: varNode
	"We have an undeclared variable.
	If it isn't in Undeclared, create a binding."
	^UndeclaredVariable new binding:
		(Undeclared associationAt: name asSymbol ifAbsent:
			[Association key: name asSymbol value: nil])!

variableAt: name from: varNode
	"There are no definitions here."
	^nil! !

!NullScope methodsFor: 'accessing-debuggers'!

tempNames
	"This scope terminates a LocalScope chain.  It has no temporaries"

	^OrderedCollection new! !

!NullScope methodsFor: 'enumerating'!

associationsDo: aBlock
	"Do nothing"!

keysDo: aBlock
	"Do  nothing"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NullScope class
	instanceVariableNames: ''!


!NullScope class methodsFor: 'instance creation'!

new
	"Only one instance is ever needed"
	NullScopeInstance == nil ifTrue: [NullScopeInstance _ super new].
	^NullScopeInstance! !