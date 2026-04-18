'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:50 pm'!

Recipe subclass: #ProxyRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-comm'!

(ProxyRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ProxyRecipe methodsFor: 'accessing'!

{void} parseProxy: rcvr {Rcvr} with: rpcs {RPCSpecialist} into: memory {void star} 
	"Create a proxy and build all the copy part."
	
	self subclassResponsibility! !

!ProxyRecipe methodsFor: 'protected: creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !