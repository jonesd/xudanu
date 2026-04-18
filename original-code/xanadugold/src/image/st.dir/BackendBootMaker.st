'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:41 pm'!

BootMaker subclass: #BackendBootMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fbtest'!

(BackendBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!BackendBootMaker methodsFor: 'accessing'!

{Category} bootCategory
	^BeGrandMap! !

!BackendBootMaker methodsFor: 'protected:'!

{Heaper} bootHeaper

	^BeGrandMap make! !

!BackendBootMaker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BackendBootMaker class
	instanceVariableNames: ''!

(BackendBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!BackendBootMaker class methodsFor: 'creation'!

{BootPlan} make
	^self create! !

!BackendBootMaker class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	[FeServer, Recipe] USES.
	Cookbook declareCookbook: 'disk' with: BeGrandMap with: DiskCuisine with: XppCuisine with: FebeCuisine! !