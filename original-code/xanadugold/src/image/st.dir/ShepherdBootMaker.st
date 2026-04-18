'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:42 pm'!

BootMaker subclass: #ShepherdBootMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fbtest'!

(ShepherdBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!ShepherdBootMaker methodsFor: 'accessing'!

{Category} bootCategory
	^Counter! !

!ShepherdBootMaker methodsFor: 'protected:'!

{Heaper} bootHeaper
	^Counter make.! !

!ShepherdBootMaker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShepherdBootMaker class
	instanceVariableNames: ''!

(ShepherdBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!ShepherdBootMaker class methodsFor: 'creation'!

{BootPlan} make
	^self create! !