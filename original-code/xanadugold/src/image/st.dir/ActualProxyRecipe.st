'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:49 pm'!

ProxyRecipe subclass: #ActualProxyRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-comm'!

(ActualProxyRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActualProxyRecipe methodsFor: 'accessing'!

{void} parseProxy: rcvr {Rcvr} with: rpcs {RPCSpecialist} into: memory {void star}

	(self categoryOfDish new.Become: memory) create: rcvr with: rpcs! !

!ActualProxyRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !