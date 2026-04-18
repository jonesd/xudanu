'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:17 pm'!

Thunk subclass: #TrueThunk
	instanceVariableNames: 'myBooleanModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(TrueThunk getOrMakeCxxClassDescription)
	friends:
'/* friends for class TrueThunk */
friend SPTR(TrueThunk)  trueThunk (BooleanModel * onModel);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TrueThunk methodsFor: 'private: creation'!

create: onModel {BooleanModel}

	super create.
	myBooleanModel _ onModel! !

!TrueThunk methodsFor: 'action'!

{void} execute

	myBooleanModel setValue: true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TrueThunk class
	instanceVariableNames: ''!

(TrueThunk getOrMakeCxxClassDescription)
	friends:
'/* friends for class TrueThunk */
friend SPTR(TrueThunk)  trueThunk (BooleanModel * onModel);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TrueThunk class methodsFor: 'make'!

make: onModel {BooleanModel}

	^ self create: onModel! !