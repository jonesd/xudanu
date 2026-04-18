'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:17 pm'!

UpdateRecord subclass: #ToggleUR
	instanceVariableNames: 'newValueInternal {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
ToggleUR comment:
'This is the update record for a flag Toggle update event.'!

(ToggleUR getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ToggleUR methodsFor: 'create'!

create: newValue{BooleanVar}
	super create.
	newValueInternal _ newValue! !

!ToggleUR methodsFor: 'accessing'!

{Boolean} newValue
	^newValueInternal!

{Boolean} oldValue
	^newValueInternal not! !

!ToggleUR methodsFor: 'protected: creation'!

{void} destruct
	newValueInternal _ false.
	super destruct! !