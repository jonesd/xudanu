'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:56 pm'!

FeBundle subclass: #FeArrayBundle
	instanceVariableNames: '
		myArray {PrimArray}
		myOrder {OrderSpec}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeArrayBundle comment:
'Describes a chunk of information represented as an array. The number of elements in the array are the same as my region, and they are ordered according to OrderSpec given to the retrieve operation which produced me.'!

(FeArrayBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeArrayBundle methodsFor: 'accessing'!

{PrimArray CLIENT} array
	"Essential. The array of elements in this bundle"
	
	^myArray copy!

{OrderSpec CLIENT} ordering
	"Essential. The order relating the elements in the array to the positions in the region."
	
	^myOrder! !

!FeArrayBundle methodsFor: 'private: create'!

create: region {XnRegion} with: array {PrimArray} with: order {OrderSpec}

	super create: region.
	myArray := array.
	myOrder _ order! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeArrayBundle class
	instanceVariableNames: ''!

(FeArrayBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeArrayBundle class methodsFor: 'create'!

make: region {XnRegion} with: array {PrimArray} with: order {OrderSpec}

	^self create: region with: array with: order! !

!FeArrayBundle class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimArray CLIENT} array
{OrderSpec CLIENT} order
"! !