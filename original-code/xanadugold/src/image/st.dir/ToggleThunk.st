'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:16 pm'!

Thunk subclass: #ToggleThunk
	instanceVariableNames: 'myBooleanModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(ToggleThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ToggleThunk methodsFor: 'creation'!

create: onModel {BooleanModel}
	super create.
	myBooleanModel _ onModel! !

!ToggleThunk methodsFor: 'action'!

{void} execute
	"self halt."
	myBooleanModel setValue: myBooleanModel getValue not! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ToggleThunk class
	instanceVariableNames: ''!

(ToggleThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ToggleThunk class methodsFor: 'pseudoconstructors'!

make: onModel {BooleanModel}
	^ self create: onModel! !