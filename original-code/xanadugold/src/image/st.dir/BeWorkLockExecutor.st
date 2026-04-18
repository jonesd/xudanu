'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:31 pm'!

XnExecutor subclass: #BeWorkLockExecutor
	instanceVariableNames: 'myWork {BeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-brange2'!

(BeWorkLockExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BeWorkLockExecutor methodsFor: 'invoking'!

{void} execute: estateIndex {Int32 unused}
	"The work's locking pointer will already be NULL, so we only have to update"
	myWork updateFeStatus! !

!BeWorkLockExecutor methodsFor: 'create'!

create: work {BeWork}
	super create.
	myWork := work! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeWorkLockExecutor class
	instanceVariableNames: ''!

(BeWorkLockExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BeWorkLockExecutor class methodsFor: 'pseudoconstructors'!

make: work {BeWork}
	^ BeWorkLockExecutor create: work! !