'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:34 pm'!

CopyRecipe subclass: #STArrayRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(STArrayRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SMALLTALK.ONLY; yourself)!

!STArrayRecipe methodsFor: 'accessing'!

{void} parse: rcvr {SpecialistRcvr}
	| count {UInt32} result {Heaper} |
	count _ rcvr receiveUInt32.
	result _ self categoryOfDish new: count.
	rcvr registerIbid: result.
	^result create.Rcvr: rcvr!

{void} parse: rcvr {SpecialistRcvr} into: memory {void star}

	Heaper BLAST: #NotBecomable! !

!STArrayRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STArrayRecipe class
	instanceVariableNames: ''!

(STArrayRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SMALLTALK.ONLY; yourself)!

!STArrayRecipe class methodsFor: 'creation'!

make: cat {Category} with: cuisine {Recipe star vector}
	^self create: cat with: cuisine! !

!STArrayRecipe class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	self REQUIRES: Recipe.
	"STArrayRecipe make: IntegerVarArray with: XppCuisine.
	STArrayRecipe make: PtrArray with: XppCuisine.
	STArrayRecipe make: UInt32Array with: XppCuisine.
	STArrayRecipe make: WeakPtrArray with: XppCuisine. BOGUS and OBSOLETE"! !