'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:26 pm'!

XnExecutor subclass: #PrimPtrTableExecutor
	instanceVariableNames: '
		myTable {PrimPtrTable}
		myFollower {XnExecutor | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!

(PrimPtrTableExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimPtrTableExecutor methodsFor: 'invoking'!

{void} execute: estateIndex {Int32}
	myTable weakRemove: estateIndex with: myFollower! !

!PrimPtrTableExecutor methodsFor: 'protected: create'!

create: table {PrimPtrTable} with: follower {XnExecutor | NULL}
	super create.
	myTable := table.
	myFollower := follower.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimPtrTableExecutor class
	instanceVariableNames: ''!

(PrimPtrTableExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimPtrTableExecutor class methodsFor: 'create'!

make: table {PrimPtrTable} with: follower {XnExecutor | NULL}
	^ self create: table with: follower! !