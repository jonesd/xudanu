'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:18 pm'!

Heaper subclass: #RegionDelta
	instanceVariableNames: '
		myBefore {XnRegion}
		myAfter {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filter'!
RegionDelta comment:
'A RegionDelta represents a change in the state of a Region, holding the state before and after some change. They are in some sense complementary to Joints: In the same way that you can use Filters to examine Joints, you can use RegionDeltas to examine Filters. See also Filter::isSwitchedBy(RegionDelta *) and related methods.'!

(RegionDelta getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!RegionDelta methodsFor: 'creation'!

create: before {XnRegion} with: after {XnRegion}
	super create.
	myBefore _ before.
	myAfter _ after! !

!RegionDelta methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myBefore hashForEqual + myAfter hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: RegionDelta into: [:rd |
			^(rd before isEqual: myBefore)
			 and: [rd after isEqual: myAfter]]
		others: [^false].
	^false "fodder"!

{BooleanVar INLINE} isSame
	"if the before and after are the same"
	^myBefore isEqual: myAfter! !

!RegionDelta methodsFor: 'accessing'!

{XnRegion INLINE} after
	"The region after the change."
	
	^myAfter!

{XnRegion INLINE} before
	"The region before the change."
	
	^myBefore! !

!RegionDelta methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBefore _ receiver receiveHeaper.
	myAfter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myBefore.
	xmtr sendHeaper: myAfter.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RegionDelta class
	instanceVariableNames: ''!

(RegionDelta getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!RegionDelta class methodsFor: 'pseudo constructors'!

make: before {XnRegion} with: after {XnRegion}
	^RegionDelta create: before with: after! !