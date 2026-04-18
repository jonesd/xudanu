'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:40 pm'!

Stepper subclass: #DisjointRegionStepper
	instanceVariableNames: '
		myValue {XnRegion}
		myRegion {XnRegion}
		myOrder {OrderSpec}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(DisjointRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DisjointRegionStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	^myValue!

{BooleanVar} hasValue
	^myValue ~~ NULL!

{void} step
	myValue _ (myRegion simpleRegions: myOrder) fetch cast: XnRegion.
	myValue == NULL
		ifTrue: [myRegion isEmpty 
					ifFalse: [Heaper BLAST: #RegionReturnedNullStepperEvenThoughNonEmpty]]
		ifFalse: [myRegion _ myRegion minus: myValue]! !

!DisjointRegionStepper methodsFor: 'instance creation'!

{Stepper} copy
	^DisjointRegionStepper make: (myValue unionWith: myRegion) with: myOrder!

create: region {XnRegion} with: order {OrderSpec}
	super create.
	myValue _ NULL.
	myRegion _ region.
	myOrder _ order.
	myRegion isEmpty ifFalse:
		[self step].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DisjointRegionStepper class
	instanceVariableNames: ''!

(DisjointRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DisjointRegionStepper class methodsFor: 'instance creation'!

{Stepper} make: region {XnRegion} with: order {OrderSpec}
	^DisjointRegionStepper create: region with: order! !