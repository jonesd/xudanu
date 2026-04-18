'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:50 pm'!

Recipe subclass: #StubRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-comm'!

(StubRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!StubRecipe methodsFor: 'accessing'!

{Heaper} parseStub: rcvr {Rcvr} with: hash {UInt32}
	
	self subclassResponsibility! !

!StubRecipe methodsFor: 'protected: creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !