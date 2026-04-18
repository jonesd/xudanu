'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:28 pm'!

XnExecutor subclass: #PrimSetExecutor
	instanceVariableNames: 'mySet {PrimSet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!

(PrimSetExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimSetExecutor methodsFor: 'protected: create'!

create: set {PrimSet}
	super create.
	mySet := set! !

!PrimSetExecutor methodsFor: 'execution'!

{void} execute: estateIndex {Int32}
	mySet weakRemove: estateIndex! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimSetExecutor class
	instanceVariableNames: ''!

(PrimSetExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimSetExecutor class methodsFor: 'pseudoconstructor'!

make: set {PrimSet}
	^ self create: set! !