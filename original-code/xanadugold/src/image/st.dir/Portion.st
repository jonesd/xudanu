'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:04 pm'!

Heaper subclass: #Portion
	instanceVariableNames: '
		myBounds {IntegerRegion}
		myRate {Float}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Multi'!
Portion comment:
'Instances represent some portion of a rectangular area.  The fixed region is the area that the receiver requires as a minimum.  The relative area is the chunk it would like from the area remaining after all the fixed zones have been allocated.  One of these will often be 0.  This is used to represent Pane sizes for layout.
	
	myBounds is an IntegerRegion that represents the minimum and maximum
	extents for this portion.  If the region is not bounded right, then the maximum
	is infinity.  The region must be bounded left.
	
	myRate is the fractional rate to allocate to this portion after minimums
	have been satisfied.

To allocate space to a bunch of Portions, allocate to each their fixed request.  The divvy up the remainder in proportion with the fractional requests.  What is the basis for the fractional amounts?  This should only allocate space up to their bounding enclosure extent.'!

(Portion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Portion methodsFor: 'accessing'!

{Float} fractionalRate
	^myRate!

{BooleanVar} hasMaximum
	^myBounds isBoundedAbove!

{IntegerVar} maxEnclosure
	myBounds isBoundedAbove
		ifFalse: [Heaper BLAST: #InvalidRequest].
	^ myBounds stop!

{IntegerVar} minEnclosure
	^ myBounds start! !

!Portion methodsFor: 'create'!

create: bounds {IntegerRegion} with: rate {Float} 
	super create.
	bounds isBoundedBelow assert: 'Portion must have a minimum size GE 0'.
	myBounds _ bounds.
	myRate _ rate! !

!Portion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myBounds << ' @ ' << myRate << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Portion class
	instanceVariableNames: ''!

(Portion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Portion class methodsFor: 'pseudo constructors'!

make: bounds {IntegerRegion} with: rate {Float} 
	^self create: bounds with: rate! !