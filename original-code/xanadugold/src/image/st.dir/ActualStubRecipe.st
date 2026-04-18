'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:49 pm'!

StubRecipe subclass: #ActualStubRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-comm'!

(ActualStubRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActualStubRecipe methodsFor: 'accessing'!

{Heaper} parse: rcvr {Rcvr} with: rpcs {RPCSpecialist} with: hash {UInt32}
	
	^ShepherdStub create: hash with: self categoryOfDish! !

!ActualStubRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualStubRecipe class
	instanceVariableNames: ''!

(ActualStubRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActualStubRecipe class methodsFor: 'pcreate'!

make: cl {Category}
	^self create: cl! !