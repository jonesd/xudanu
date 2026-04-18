'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:16 pm'!

Thunk subclass: #MultiThunk
	instanceVariableNames: 'myThunks {ScruTable of: Thunk}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(MultiThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!MultiThunk methodsFor: 'creation'!

create: onTable {ScruTable of: Thunk}

	super create.
	myThunks _ onTable! !

!MultiThunk methodsFor: 'action'!

{void} execute
	myThunks stepper forEach: [:thunk {Thunk} | thunk execute]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiThunk class
	instanceVariableNames: ''!

(MultiThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!MultiThunk class methodsFor: 'make'!

{Thunk} make: onTable {ScruTable of: Thunk}

	^ self create: onTable! !