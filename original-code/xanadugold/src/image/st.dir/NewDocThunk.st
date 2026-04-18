'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:28 pm'!

Thunk subclass: #NewDocThunk
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!

(NewDocThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NewDocThunk methodsFor: 'operate'!

{void} execute
	"open a new window "
	|  tmp {XuText} docid{ID}  |
	[KeyMaster] USES.
	tmp _ ((Application fluidGet user keyMaster)
		makePersistentWaldo: (Sequence string: 'XuText')) cast: XuText.
	 docid _ tmp getID.
	 tmp destroy.
	Application fluidGet openWindow: (Application fluidGet getDocument: docid).! !

!NewDocThunk methodsFor: 'create'!

create 
	super create.! !

!NewDocThunk methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NewDocThunk class
	instanceVariableNames: ''!

(NewDocThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NewDocThunk class methodsFor: 'psuedoconstructors'!

make
	^NewDocThunk create! !