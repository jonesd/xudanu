'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:14 pm'!

Thunk subclass: #AssignmentThunk
	instanceVariableNames: '
		myVarModel {VariableModel}
		myAssignee {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!
AssignmentThunk comment:
'This thunk, when invoked, assigns a particular
object to a variableModel.'!

(AssignmentThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AssignmentThunk methodsFor: 'creation'!

create: onModel {VariableModel} with: thingy {Heaper}

	super create.
	myVarModel _ onModel.
	myAssignee _ thingy! !

!AssignmentThunk methodsFor: 'action'!

{void} execute
	myVarModel setValue: myAssignee! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AssignmentThunk class
	instanceVariableNames: ''!

(AssignmentThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AssignmentThunk class methodsFor: 'pseudoConstructors'!

make: onModel {VariableModel} with: thing {Heaper}
	^ self create: onModel with: thing! !