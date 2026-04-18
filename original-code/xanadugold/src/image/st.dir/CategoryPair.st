'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:11 pm'!

Object subclass: #CategoryPair
	instanceVariableNames: '
		myLeft {Category}
		myRight {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Classes'!



!CategoryPair methodsFor: 'operations'!

{TypePair} | type {Category | CategoryPair}
	^CategoryPair create: self with: type! !

!CategoryPair methodsFor: 'testing'!

{BooleanVar} isSuperTo: cat {Class}

	^cat == myLeft 
		or: [cat == myRight 
		or: [(myLeft isSuperTo: cat) 
		or: [myRight isSuperTo: cat]]]! !

!CategoryPair methodsFor: 'creation'!

create: cat1 {Category} with: cat2 {Category}
	super create.
	myLeft _ cat1.
	myRight _ cat2! !