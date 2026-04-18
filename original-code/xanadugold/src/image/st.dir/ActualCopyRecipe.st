'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:06 pm'!

CopyRecipe subclass: #ActualCopyRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(ActualCopyRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActualCopyRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !

!ActualCopyRecipe methodsFor: 'accessing'!

{void} parse: rcvr {Rcvr}
	| result {Heaper} |
	result _ self categoryOfDish new.
	rcvr registerIbid: result.
	^result create.Rcvr: rcvr!

{void} parse: rcvr {Rcvr} into: memory {void star}

	(self categoryOfDish new.Become: memory) create.Rcvr: rcvr! !