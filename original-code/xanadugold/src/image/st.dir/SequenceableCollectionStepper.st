'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:22 pm'!

Stepper subclass: #SequenceableCollectionStepper
	instanceVariableNames: 'myCollection curIdx '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Abstract'!


!SequenceableCollectionStepper methodsFor: 'creation'!

copy
	^ SequenceableCollectionStepper create: myCollection with: curIdx!

create: aCollection {SequenceableCollection} 
	myCollection _ aCollection.
	aCollection isEmpty
		ifTrue: [curIdx _ 0]
		ifFalse: [curIdx _ myCollection identityIndexOf: myCollection first]!

create: aCollection {SequenceableCollection} with: starting {IntegerVar}
	myCollection _ aCollection.
	curIdx _ starting! !

!SequenceableCollectionStepper methodsFor: 'operation'!

fetch
	(curIdx < 1 or: [curIdx > myCollection size]) ifTrue: [^ nil].
	^ myCollection at: curIdx!

hasValue
	^curIdx <= myCollection size and: [curIdx > 0 and: [(myCollection at: curIdx) ~~ nil]]!

step
	curIdx _ curIdx + 1.
	self verifyEntry! !

!SequenceableCollectionStepper methodsFor: 'private: private'!

verifyEntry
	| notDone {BooleanVar} |
	notDone _ true.
	[notDone]
		whileTrue: [curIdx <= myCollection size
				ifTrue: [(myCollection at: curIdx) == nil
						ifTrue: [curIdx _ curIdx + 1]
						ifFalse: [notDone _ false]]
				ifFalse: [notDone _ false]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SequenceableCollectionStepper class
	instanceVariableNames: ''!


!SequenceableCollectionStepper class methodsFor: 'pseudoConstructors'!

make: aCollection
	^ self create: aCollection!

make: aCollection with: start
	^ self create: aCollection with: start! !