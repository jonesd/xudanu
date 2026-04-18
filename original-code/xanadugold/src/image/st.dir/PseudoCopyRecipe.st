'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:12 pm'!

CopyRecipe subclass: #PseudoCopyRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(PseudoCopyRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PseudoCopyRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !

!PseudoCopyRecipe methodsFor: 'accessing'!

{void} parse: rcvr {Rcvr}
	"Pseudo-copy recipes register themselves."
	| result {Heaper} |
	result _ self categoryOfDish new.
	result _ result class make.Rcvr: rcvr.
	^ result.!

{void} parse: rcvr {Rcvr} into: memory {void star}
	self shouldNotImplement! !