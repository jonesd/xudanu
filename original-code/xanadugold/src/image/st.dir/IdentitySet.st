'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:27 pm'!

Set variableSubclass: #IdentitySet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Unordered'!
IdentitySet comment:
'The class IdentitySet is just like Set, but uses == instead of = for comparisons.

Instance Variables: *indexed*'!


!IdentitySet methodsFor: 'conversion'!

asIdentitySet
	"Answer a new instance of Set whose elements are the unique elements of
	the receiver."

	^self! !

!IdentitySet methodsFor: 'private: private'!

findElementOrNil: anObject  
	"Answer the index of the argument anObject or answer nil."

	"Copied from Set with equality check changed to identity."

	| index length probe pass |
	length _ self basicSize.
	pass _ 1.
	index _ anObject identityHash \\ length + 1.
	[(probe _ self basicAt: index) == nil or: [probe == anObject]]
		whileFalse: [(index _ index + 1) > length
				ifTrue: 
					[index _ 1.
					pass _ pass + 1.
					pass > 2 ifTrue: [^self grow findElementOrNil: anObject]]].
	^index! !