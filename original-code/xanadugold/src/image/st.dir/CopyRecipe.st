'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:48 pm'!

Recipe subclass: #CopyRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-OtherClass'!

(CopyRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CopyRecipe methodsFor: 'accessing'!

{Heaper} parse: rcvr {SpecialistRcvr}
	"create a new object from the information in the transceiver"

	| result {void star} |	
	
	' 
	result = Heaper::operator new (0, xcsj, this->categoryOfDish());' translateOnly.
	
	[result _ DeletedHeaper create] smalltalkOnly.
	
	rcvr registerIbid: (result basicCast: Heaper).
	self parse: rcvr into: result.
	^ result basicCast: Heaper.!

{void} parse: rcvr {Rcvr} into: memory {void star} 
	"create a new object from the information in the rcvr and give it the identity 
	of memory. The c++ version of this builds the first object received into the 
	area of supplied memory."
	
	self subclassResponsibility! !

!CopyRecipe methodsFor: 'protected: creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !