'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:38 pm'!

TransferSpecialist subclass: #TransferGeneralist
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(TransferGeneralist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TransferGeneralist methodsFor: 'create'!

create: aBook {Cookbook}
	super create: aBook.! !

!TransferGeneralist methodsFor: 'communication'!

{Heaper} receiveHeaper: cat {Category} from: rcvr {SpecialistRcvr}
	"No special cases.  Punt to the rcvr."
	
	^rcvr basicReceive: (self getRecipe: cat)!

{void} receiveHeaper: cat {Category} into: memory {Heaper} from: rcvr {SpecialistRcvr}
	"No special cases.  Punt to the rcvr."
	
	rcvr basicReceive: (self getRecipe: cat) into: memory! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TransferGeneralist class
	instanceVariableNames: ''!

(TransferGeneralist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TransferGeneralist class methodsFor: 'creation'!

{TransferSpecialist} make: aBook {Cookbook}
	^self create: aBook! !