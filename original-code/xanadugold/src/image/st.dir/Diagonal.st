'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:31 pm'!

Heaper subclass: #Diagonal
	instanceVariableNames: 'myOffset {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(Diagonal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Diagonal methodsFor: 'accessing'!

{IntegerVar} columnFor: index {IntegerVar}
	(self offset > IntegerVar0)
		ifTrue: [^index + self offset]
		ifFalse: [^index]!

{IntegerVar} rowFor: index {IntegerVar}
	(self offset < IntegerVar0)
		ifTrue: [^index - self offset]
		ifFalse: [^index]! !

!Diagonal methodsFor: 'creation'!

create: offset {IntegerVar}
	super create.
	myOffset _ offset.! !

!Diagonal methodsFor: 'protected: accessing'!

{IntegerVar} offset

	^ myOffset! !