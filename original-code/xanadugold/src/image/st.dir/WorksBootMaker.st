'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:42 pm'!

BootMaker subclass: #WorksBootMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fbtest'!

(WorksBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!WorksBootMaker methodsFor: 'accessing'!

{Category} bootCategory
	^FeServer! !

!WorksBootMaker methodsFor: 'protected:'!

{Heaper} bootHeaper

	GrandConnection fluidFetch == NULL ifTrue:
		["CurrentGrandMap fluidFetch == NULL ifFalse: [Heaper BLAST: #GrandMapWithoutConnection]."
		GrandConnection fluidSet: (Connection make: BeGrandMap).
		CurrentGrandMap fluidSet: (GrandConnection fluidGet bootHeaper cast: BeGrandMap).
		"force agenda items to be invoked - they were commented out in getInitialFlock /ravi/10/22/92/"
		DiskManager consistent: []].
	^FeServer make! !

!WorksBootMaker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksBootMaker class
	instanceVariableNames: ''!

(WorksBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!WorksBootMaker class methodsFor: 'smalltalk: init'!

staticTimeNonInherited

	Connection defineFluid: #GrandConnection with: Emulsion globalEmulsion with: [NULL].! !