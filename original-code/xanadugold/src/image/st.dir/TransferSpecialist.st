'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:38 pm'!

Heaper subclass: #TransferSpecialist
	instanceVariableNames: 'myCookbook {Cookbook}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(TransferSpecialist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!TransferSpecialist methodsFor: 'cookbook'!

{Category} getCategoryFor: no {IntegerVar}
	^myCookbook getCategoryFor: no!

{Recipe} getRecipe: cat {Category}
	^myCookbook getRecipe: cat!

{IntegerVar} numberOfCategory: cat {Category}
	^myCookbook numberOfCategory: cat! !

!TransferSpecialist methodsFor: 'communication'!

{Heaper} receiveHeaper: cat {Category} from: rcvr {SpecialistRcvr}
	"Return an object from the rcvr or NULL if cat
	 is not a category that we handle specially."
	"Make sure all objects created get rcvr registerIbid:
	 called on them so that the rcvr doesn't get out of sync."

	self subclassResponsibility!

{void} receiveHeaper: cat {Category} into: memory {Heaper} from: rcvr {SpecialistRcvr}
	"Return an object from the rcvr or NULL if cat is not a category that we handle specially."

	self subclassResponsibility!

{void} sendHeaper: hpr {Heaper} to: xmtr {SpecialistXmtr}
	"Transmit heapers on xmtr.  Subclasses intercept and handle special cases here."
	
	xmtr startInstance: hpr with: hpr getCategory.
	hpr sendSelfTo: xmtr.
	xmtr endInstance! !

!TransferSpecialist methodsFor: 'creation'!

create: aBook {Cookbook}
	super create.
	myCookbook _ aBook! !

!TransferSpecialist methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TransferSpecialist class
	instanceVariableNames: ''!

(TransferSpecialist getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!TransferSpecialist class methodsFor: 'creation'!

make: aBook {Cookbook}
	"Return a specialist that does nothing."
	
	^TransferGeneralist create: aBook! !