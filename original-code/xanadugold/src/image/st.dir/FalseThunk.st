'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:15 pm'!

Thunk subclass: #FalseThunk
	instanceVariableNames: 'myBooleanModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(FalseThunk getOrMakeCxxClassDescription)
	friends:
'/* friends for class FalseThunk */
friend SPTR(FalseThunk)  falseThunk (BooleanModel * onModel);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FalseThunk methodsFor: 'private: creation'!

create: onModel {BooleanModel}

	super create.
	myBooleanModel _ onModel! !

!FalseThunk methodsFor: 'action'!

{void} execute

	myBooleanModel setValue: false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FalseThunk class
	instanceVariableNames: ''!

(FalseThunk getOrMakeCxxClassDescription)
	friends:
'/* friends for class FalseThunk */
friend SPTR(FalseThunk)  falseThunk (BooleanModel * onModel);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FalseThunk class methodsFor: 'make'!

make: onModel {BooleanModel}

	^ self create: onModel! !