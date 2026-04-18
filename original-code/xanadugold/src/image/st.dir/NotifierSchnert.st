'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:58 pm'!

XnModel subclass: #NotifierSchnert
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!

(NotifierSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NotifierSchnert methodsFor: 'create'!

create
	super create! !

!NotifierSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender
{XnModel unused}

	self changed: (NewContentsUpdate make)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NotifierSchnert class
	instanceVariableNames: ''!

(NotifierSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NotifierSchnert class methodsFor: 'pseudoConstructors'!

make
	^ self create! !