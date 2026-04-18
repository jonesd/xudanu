'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:28 pm'!

Thunk subclass: #LinkMakerThunk
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!
LinkMakerThunk comment:
'creates a LinkMakerWindowModel and opens it.'!

(LinkMakerThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkMakerThunk methodsFor: 'operate'!

{void} execute
	"create and open a LinkMaker window"

	LinkMakerWindowModel make open! !

!LinkMakerThunk methodsFor: 'creation'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkMakerThunk class
	instanceVariableNames: ''!

(LinkMakerThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkMakerThunk class methodsFor: 'pseudo constructors'!

make
	^ self create! !