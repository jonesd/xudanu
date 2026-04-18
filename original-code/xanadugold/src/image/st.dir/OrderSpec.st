'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:56 pm'!

Heaper subclass: #OrderSpec
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
OrderSpec comment:
'[documentation note: we need to hide the documentation about partial orders, but still warn that the orders may become partial]. An OrderSpec for a given coordinate space represents a partial ordering of all the Positions of that coordinate space.  The fundamental ordering relationship is "follows".  The response of Positions to isGE defines the natural, "ascending" partial order among the positions.  Every coordinate space will have at least this ascending and the corresponding descending OrderSpecs.  OrderSpecs are useful to specify in what order a stepper produced for stepping over positions should do so.'!

(OrderSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #COPY; yourself)!

!OrderSpec methodsFor: 'smalltalk: defaults'!

isFullOrder

	^self isFullOrder: NULL! !

!OrderSpec methodsFor: 'testing'!

{UInt32} actualHashForEqual

	self subclassResponsibility!

{OrderEnum} compare: x {Position} with: y {Position}
	"Say what the relative ordering relationship is between x and y"

	(self follows: x with: y)
		ifTrue: [(self follows: y with: x) ifTrue: [^#EQUAL] ifFalse: [^#GREATER.U.THAN]]
		ifFalse: [(self follows: y with: x) ifTrue: [^#LESS.U.THAN] ifFalse: [^#INCOMPARABLE]]!

{BooleanVar CLIENT} follows: x {Position} with: y {Position}
	"Essential.  Compare the two and return true if x is known to follow y in the ordering.  This message is the 'greater than or equal to' equivalent for this ordering.  It must have those properties a mathematician would demand of a '>=' on a partial order:
		os->follows(a, a)   (reflexivity)
		os->follows(a, b) && os->follows(b, c) implies os->follows(a, c)  (transitivity)
		os->follows(a, b) && os->follows(b, a) implies a->isEqual(b)  (what's the name for this?)"

	self subclassResponsibility!

{BooleanVar} followsInt: x {IntegerVar} with: y {IntegerVar}
	"See discussion in XuInteger class comment about boxed vs unboxed integers"

	^self follows: x integer with: y integer!

{BooleanVar} isEqual: other {Heaper}

	self subclassResponsibility!

{BooleanVar} isFullOrder: keys {XnRegion default: NULL}
	"Essential.  If this returns TRUE, then I define a full order over all positions in 'keys' (or all positions in the space if 'keys' is NULL).  However, if I return FALSE, that doesn't guarantee that I don't define a full ordering.  I may happen to define a full ordering without knowing it.
	
	A full ordering is one in which for each a, b in keys; either this->follows(a, b) or this->follows(b, a)."
	
	self subclassResponsibility!

{BooleanVar} preceeds: before {XnRegion} with: after {XnRegion}
	"Return true if some position in before is less than or equal to all positions in after."
	
	self subclassResponsibility! !

!OrderSpec methodsFor: 'accessing'!

{Arrangement} arrange: region {XnRegion}
	"Return an Arrangement of the positions in region according to the ordering of the receiver."
	
	^ExplicitArrangement make: ((region stepper: self) stepMany cast: PtrArray)!

{CoordinateSpace CLIENT} coordinateSpace
	"Essential.  Like Positions, Dsps, and XuRegions, an OrderSpec is specific to one coordinate space.  It is an error to use the generic protocol on objects from different coordinate spaces."

	self subclassResponsibility!

{OrderSpec CLIENT} reversed
	"Returns an OrderSpec representing the mirror image of my ordering.
	o->follows(a, b) iff o->reverse()->follows(b, a)"
	
	^ReverseOrder make: self! !

!OrderSpec methodsFor: 'smalltalk: passe'!

{PrimArray} export

	self passe! !

!OrderSpec methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OrderSpec class
	instanceVariableNames: ''!

(OrderSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #COPY; yourself)!

!OrderSpec class methodsFor: 'smalltalk: passe'!

{OrderSpec} ascending: cs {CoordinateSpace} 
	"Use CoordinateSpace::fetch/getAscending"

	self passe!

{OrderSpec} descending: cs {CoordinateSpace}
	"Use CoordinateSpace::fetch/getDescending"
	
	self passe! !

!OrderSpec class methodsFor: 'smalltalk: system'!

info.stProtocol
"{CoordinateSpace CLIENT} coordinateSpace
{BooleanVar CLIENT} follows: x {Position} with: y {Position}
{OrderSpec CLIENT} reversed
"! !