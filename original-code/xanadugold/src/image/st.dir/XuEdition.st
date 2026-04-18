'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:13 pm'!

XuRangeElement subclass: #XuEdition
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuEdition comment:
'The kind of FeRangeElement that consists of an immutable organization of RangeElements, indexed by Positions in some CoordinateSpace.
 R1 prohibits cyclic containment.

Set notation is used in the comments documenting some of the methods of this class.  In each case the cleartext explanation stands alone, and the set notation is a separate, more formal, expression of the actions of the method, in terms of key(position)/label/value triples ("<k,l,v>").'!

(XuEdition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuEdition methodsFor: 'accessing'!

{XuCoordinateSpace} coordinateSpace

	"Return the space in which the positions of this Edition are positions. Equivalent to
		this->domain ()->coordinateSpace ()"
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualFeEdition coordinateSpace)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} cost: method {XuIntValue} 

	"Essential. Retiurn how much space this Edition is taking up on the disk, in bytes (but the precision may exceed the accuracy; it's simply a well-known unit). The method determines how material shared with other Editions is treated: if omitShared, it is not counted at all; if prorateShared, then it is divided evenly among the Editions sharing it; if totalShared, its entire cost is counted. This figure is only approximate, and may vary with time.
	(No permissions are required to obtain this informiation, even though it exposes sharing by Editions you can't read to traffic analysis.)"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(method isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: method].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeEdition cost:method getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} count

	"Return the number of positions in this Edition. Blasts if infinite. Equivalent to
		this->domain ()->count ()"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeEdition count)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} domain

	"Essential.  Return the region consisting of all the positions in this Edition. May be infinite, or empty.
	
	{ k | <k,l,v> in self }"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition domain)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRangeElement} get: position {XuPosition} 

	"Return the value at the given position, or blast if there is no such position (i.e. if !! this->domain ()->hasMember (position)).
	
	v : <position,l,v> in self
	requires: <position,l,v> in self"
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: position].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeEdition get: ((XuPromise getActual: position) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} hasPosition: position {XuPosition} 

	"Return whether the given position is in the Edition. Equivalent to
		this->domain ()->hasMember (position)"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: position].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition hasPosition: ((XuPromise getActual: position) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isEmpty

	"Return whether there are any positions in this Edition. Equivalent to
		this->domain ()->isEmpty ()"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition isEmpty)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isFinite

	"Return whether there are a finite number of positions in this Edition. Equivalent to
		this->domain ()->isFinite ()"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition isFinite)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} retrieve: region {XuRegion default: DefaultNull} with: order {XuOrderSpec default: DefaultNull} with: flags {XuIntValue default: DefaultZero} 

	"Essential.  This is the fundamental retrieval operation.  Return a stepper of bundles.  Each bundle is an association between a region in the domain and the range elements associated with that region.  Where the region is associated with data, for instance, the bundle contains a PrimArray of the data elements.
	If a region is given, only that subset of the Edition's contents will be returned.  If it is not given, the entire content of the Edition will be returned.
	if the ignoreTotalOrdering flag is set, then the operation can group non-contiguous regions, and can supply the bundles in any order.
	if the ignoreArrayOrdering flag is set, then ArrayBundles returned by the operation can be ordered differently from the supplied order.
	If an OrderSpec is not supplied, then the ordering will be the default order for the coordinate space, if one exists, and if none exists the returned data will be completely unordered and the Ordering flags will be ignored."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuStepper makeBrokenBy: region].
	(order isBroken) ifTrue:
		[^XuStepper makeBrokenBy: order].
	(flags isBroken) ifTrue:
		[^XuStepper makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFeEdition retrieve: ((XuPromise getActual: region) cast: XnRegion) with: ((XuPromise getActual: order) cast: OrderSpec) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuTableStepper} stepper: region {XuRegion default: DefaultNull} with: ordering {XuOrderSpec default: DefaultNull} 

	"Return a stepper for iterating over the positions and RangeElements of this Edition. If a region is specified, then it only iterates over the domain positions which are in the given region. If no ordering is specified, then the default ascending full ordering of the CoordinateSpace is used, or a random order chosen if there is no default."
	
	| retVal {XuTableStepper} |
	(self isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: region].
	(ordering isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: ordering].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTableStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTableStepper make: (self getActualFeEdition stepper: ((XuPromise getActual: region) cast: XnRegion) with: ((XuPromise getActual: ordering) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRangeElement} theOne

	"If this Edition has a single position, then return the RangeElement at that position; if not, blasts. Equivalent to
		this->get (this->domain ()->theOne ())"
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeEdition theOne)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'smalltalk: defaults'!

{XuRegion} canMakeRangeIdentical: newIdentities {XuEdition} 

	^self  canMakeRangeIdentical: newIdentities with: DefaultNull!

{XuIntValue} isRangeIdentical: other {XuEdition} 

	"This method has no comment."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition isRangeIdentical: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} makeRangeIdentical: newIdentities {XuEdition} 

	^self  makeRangeIdentical: newIdentities with: DefaultNull!

{XuEdition} notSharedWith: other {XuEdition} 

	^self  notSharedWith: other with: DefaultZero!

{XuIDRegion} rangeOwners

	^self  rangeOwners: DefaultNull!

{XuEdition} rangeTranscluders

	^self  rangeTranscluders: DefaultNull with: DefaultNull with: DefaultNull!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} 

	^self  rangeTranscluders: positions with: DefaultNull with: DefaultNull!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} 

	^self  rangeTranscluders: positions with: filter with: DefaultNull!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} with: transitiveFilter {XuFilter default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].
	(filter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: filter].
	(transitiveFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: transitiveFilter].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rangeTranscluders: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: filter) cast: Filter) with: ((XuPromise getActual: transitiveFilter) cast: Filter))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} with: directFilter {XuFilter default: DefaultNull} with: indirectFilter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} 

	^self  rangeTranscluders: positions with: directFilter with: indirectFilter with: flags with: DefaultNull!

{XuEdition} rangeWorks

	^self  rangeWorks: DefaultNull with: DefaultNull with: DefaultZero!

{XuEdition} rangeWorks: region {XuRegion default: DefaultNull} 

	^self  rangeWorks: region with: DefaultNull with: DefaultZero!

{XuEdition} rangeWorks: region {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} 

	^self  rangeWorks: region with: filter with: DefaultZero!

{XuEdition} rangeWorks: region {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} 

	"This method has no comment."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuEdition makeBrokenBy: region].
	(filter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: filter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rangeWorks: ((XuPromise getActual: region) cast: XnRegion) with: ((XuPromise getActual: filter) cast: Filter) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} retrieve

	^self  retrieve: DefaultNull!

{XuStepper} retrieve: positions {XuRegion default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuStepper makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFeEdition retrieve: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} retrieve: positions {XuRegion default: DefaultNull} with: order {XuOrderSpec default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuStepper makeBrokenBy: positions].
	(order isBroken) ifTrue:
		[^XuStepper makeBrokenBy: order].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFeEdition retrieve: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: order) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} setRangeOwners: newOwner {XuID} 

	^self  setRangeOwners: newOwner with: DefaultNull!

{XuRegion} sharedRegion: other {XuEdition} 

	^self  sharedRegion: other with: DefaultZero!

{XuEdition} sharedWith: other {XuEdition} 

	"This method has no comment."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition sharedWith: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuTableStepper} stepper

	"This method has no comment."
	
	| retVal {XuTableStepper} |
	(self isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTableStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTableStepper make: (self getActualFeEdition stepper)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuTableStepper} stepper: region {XuRegion default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuTableStepper} |
	(self isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuTableStepper makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTableStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTableStepper make: (self getActualFeEdition stepper: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'operations'!

{XuEdition} combine: other {XuEdition} 

	"Essential.  Return a new FeEdition containing the contents of boththe receiver and the argument Editions, and with the label of the receiving edition; where they share positions, they must have the same RangeElement.  Currently the two may not share positions.  It is unclear whether to elevate this from an implementation restriction to a specification.  The advantage of so specifying is that 'combine' becomes timing independent, i.e. a failing combine could otherwise succeed after the differing range elements were unified (by FeRangeElement::makeIdentical()).  See FeEdition::mapSharedOnto and FeEdition::transformedBy.
	
	{ <k,l,v> | <k,l,v> in self or <k,l,v> in other }
	requires:
		currently: { k | <k,la,v1> in self and <k,lb,v2> in other } is empty
		eventually maybe: { k | v1 not same as v2 
									and <k,la,v1> in self and <k,lb,v2> in other } is empty"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition combine: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} copy: positions {XuRegion} 

	"Return a new FeEdition which is the subset of this Edition with the domain restricted to the given set of positions  The new edition has the same label as this edition.
	
	{ <k,l,v> | k in positions and <k,l,v> in self }"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition copy: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} replace: other {XuEdition} 

	"Return a new FeEdition with the label of the current Edition and the contents of both Editions; where they share positions, use the contents and labels of the other Edition. Equivalent to
		this->copy (other->domain ()->complement ())->combine (other).
		
	{ <k,l,v> | <k,l,v> in other or (<k,l,v> in self and <k,l2,v2> not in other }"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition replace: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} transformedBy: mapping {XuMapping} 

	"Essential.  Return a new FeEdition containing the contents and label of the current Edition with the positions transformed according to the given Mapping. Where the Mapping takes several positions in the domain to a single position in the range, this Edition must have the same RangeElement and label at all the domain positions.  Currently the mapping must be 'onto', i.e., no more that one domain position may map onto any given range position.  It is unclear whether to elevate this from an implementation restriction to a specification.  See FeEdition::mapSharedOnto and FeEdition::combine.
	
	{ <k2,l1,v1> | <k1,l1,v1> in self and <k1,k2> in mapping }
	requires:
		Currently: not exists k1a, k1b : k1a !!= k1b and <k1a,k2> in mapping and <k1b,k2> in mapping.
		Maybe eventually: for all v1, v2 : <k,l1,v1> in result and <k,l2,v2> in result, v1 is same as v2"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(mapping isBroken) ifTrue:
		[^XuEdition makeBrokenBy: mapping].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition transformedBy: ((XuPromise getActual: mapping) cast: Mapping))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} with: position {XuPosition} with: value {XuRangeElement} 

	"Return a new FeEditionwith the same contents and label as this Edition, except for the addition or substitution of a RangeElement at a specified position.
	(The difference between with() and rebind() is exactly that rebind() preserves the old label at position, while with() installs the label attached to the value argument.)
	Equivalent to:
		this->replace (FeServer::current ()->makeEditionWith (position, value))"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuEdition makeBrokenBy: position].
	(value isBroken) ifTrue:
		[^XuEdition makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition with: ((XuPromise getActual: position) cast: Position) with: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} withAll: positions {XuRegion} with: value {XuRangeElement} 

	"Return a new FeEdition with the same contents and label as this Edition, except at a specified set of positions, where the old values and labels, if there are any, are superceded by the value argument.
	Equivalent to:
		this->replace (FeServer::current ()->makeEditionWithAll (positions, value))"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].
	(value isBroken) ifTrue:
		[^XuEdition makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition withAll: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} without: position {XuPosition} 

	"Return a new FeEdition with the same contents and label as this Edition, except at a specified position, where the old value and label, if there is one, is removed.
	Equivalent to:
		this->copy (position->asRegion ()->complement ())"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuEdition makeBrokenBy: position].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition without: ((XuPromise getActual: position) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} withoutAll: positions {XuRegion} 

	"Return a new FeEdition with the same contents and label as this Edition, except at a specified set of positions, where the old values and labels, if there are any, are removed.
	Equivalent to
		this->copy (positions->complement ())"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition withoutAll: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'comparing'!

{XuIntValue} isRangeIdentical: other {XuEdition} with: region {XuRegion default: DefaultNull} 

	"Whether the two Editions have the same domains, and each RangeElement isIdentical to the corresponding RangeElement in the other Edition."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: other].
	(region isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeEdition isRangeIdentical: ((XuPromise getActual: other) cast: FeEdition) with: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} mapSharedOnto: other {XuEdition} 

	"Return a mapping such that for each range element that appears in both editions, the mapping maps each of its appearances in the argument edition to some appearance in this one.  (Some of the appearances in this edition may be unmapped or mapped to multiple appearances in the argument edition.)  Like 'mapSharedTo' except that the resulting mapping is 'onto'.  This means that each range position of the resulting mapping inverse maps to at most one domain position.  Such a mapping is suitable as an argument to 'transformedBy', and represents the minimal transformation needed to make the shared part of 'other' from self.  Note that there is no unique answer.
	
	result = { <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2
							and not exists k11 : k11 !!= k1 and <k11,k2> in result }
	
Note that this is useful for optimization of FeBe communication and Frontend display updating."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuMapping makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualFeEdition mapSharedOnto: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} mapSharedTo: other {XuEdition} 

	"Essential.  Return a Mapping from each of the positions in this Edition to all of the positions in the other Edition which have the same RangeElement.
	
	{ <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuMapping makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualFeEdition mapSharedTo: ((XuPromise getActual: other) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} notSharedWith: other {XuEdition} with: flags {XuIntValue default: DefaultZero} 

	"Return a new FeEdition containing exactly the subset of this Edition whose RangeElements are not in the other Edition.
	Equivalent to:
		this->copy (this->sharedRegion (other)->complement ()).
		
	{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }
	
Note that this is useful for optimization of FeBe communication and Frontend display updating."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition notSharedWith: ((XuPromise getActual: other) cast: FeEdition) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} positionsOf: value {XuRangeElement} 

	"Return the region consisting of all the positions in this Edition at which the given RangeElement can be found.
	Equivalent to:
		this->sharedRegion (theServer ()->makeEditionWith (some position, value)).
		
	{ k | <k,l,v> in self and v is same as value }"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(value isBroken) ifTrue:
		[^XuRegion makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition positionsOf: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} rangeTranscluders: positions {XuRegion default: DefaultNull} with: directFilter {XuFilter default: DefaultNull} with: indirectFilter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} with: otherTranscluders {XuEdition default: DefaultNull} 

	"Essential.  Return a new FeEdition containing all Editions which can be read with the authority of the CurrentKeyMaster, and which transclude RangeElements in this Edition. Immediately returns with an Edition full of PlaceHolders, which will be filled in as results appear; the lookup proceeds asynchronously.
	The Server will attempt to avoid placing duplicate copies in the result, but it may still happen.
	If a Region is given, then the request only considers the subset at those positions (i.e. equivalent to this->copy (positions)->rangeTransclusions (...))
	If a directFilter is given, then the endorsements on the resulting Editions, unioned with the endorsements on any Works directly on those Editions to which the CurrentKeyMaster has read permission, must pass the filter.
	If an indirectFilter is given, then the resulting Editions must be contained, directly or indirectly, by an Edition whose endorsements (unioned with its readable Works endorsements) pass the filter. (Giving a non-NULL indirectFilter will probably not be supported in version 1.0.)
	If the directContainersOnly flag is set, then the result only includes Editions which have the material as RangeElements; otherwise, the result includes Editions which indirectly contain the material through other Editions. (Setting this flag will probably not be supported in version 1.0.)
	If the fromTransitiveContents flag is set, then the result includes transclusions of RangeElements of sub-Editions of this one, in addition to the RangeElements in this Edition. (Setting ths flag will probably not be supported in version 1.0.)
	If localPresentOnly flag is clear, a persistent request will be created, and the new FeEdition will continue to be filled in in the future.  If it is set, only those Editions which are currently known to transclude by this Backend are sure to be recorded into the Trail.  (Some, but not all, Editions which come to transclude while this request is being processed may be recorded.  If the request is followed by a FeServer::waitForConsequences(), no Editions which come to transclude after the wait completes will be recorded.)
	If otherTranscluders is given, then the results will be recorded into it. (This may increase the chance of the same Edition being recorded twice.)
	(For convenience, you can attach a TransclusionDetector to the result Edition.  See FeEdition::addFillRangeDetector()  See also FeServer::waitForConsequences().)"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].
	(directFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: directFilter].
	(indirectFilter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: indirectFilter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].
	(otherTranscluders isBroken) ifTrue:
		[^XuEdition makeBrokenBy: otherTranscluders].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rangeTranscluders: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: directFilter) cast: Filter) with: ((XuPromise getActual: indirectFilter) cast: Filter) with:flags getActualInt32 with: ((XuPromise getActual: otherTranscluders) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} rangeWorks: positions {XuRegion default: DefaultNull} with: filter {XuFilter default: DefaultNull} with: flags {XuIntValue default: DefaultZero} with: otherTranscluders {XuEdition default: DefaultNull} 

	"Essential.  Return a new FeEdition containing all Works which contain RangeElements of this Edition and can be read by the CurrentKeyMaster. Returns an IDSpace Edition full of PlaceHolders, which will be filled with Works as results come in.
	If a filter is given, then only Works whose endorsements pass the Filter are returned.
	If the localPresentOnly flag is clear, a persistent request will be created, and as new Works come to be known to the Server, they will be filled into the resulting Edition.  If it is set, only Works currently known to this Server are sure to be recorded into the Trail.  (Some, but not all, Works which become known while this request is being processed may be recorded.  If the request is followed by a FeServer::waitForConsequences(), no Works which become known after the wait completes will be recorded.)
	If the fromTransitiveContents flag is set, then the result includes Works which contain RangeElements transitively contained in this Edition. (This may not be supported in 1.0)
	If directContainersOnly is set, then only Works which are directly on Editions which are RangeElements of this Edition are returned (and not Works which are on Editions which have them as sub-Editions).
	If otherTranscluders is given, this records works into that trail.
	(For convenience, you can attach a TransclusionDetector to the result Edition.  See FeEdition::addFillRangeDetector()  See also FeServer::waitForConsequences().)
	
	{ <k,l,w> | w's contains self, w passes filter}"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].
	(filter isBroken) ifTrue:
		[^XuEdition makeBrokenBy: filter].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].
	(otherTranscluders isBroken) ifTrue:
		[^XuEdition makeBrokenBy: otherTranscluders].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rangeWorks: ((XuPromise getActual: positions) cast: XnRegion) with: ((XuPromise getActual: filter) cast: Filter) with:flags getActualInt32 with: ((XuPromise getActual: otherTranscluders) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} sharedRegion: other {XuEdition} with: flags {XuIntValue default: DefaultZero} 

	"Return the subset of the positions of this Edition which  have RangeElements that are in the other Edition.
	If nestThis flag is set, then returns not only positions of RangeElements which are in the other, but also positions of Editions which have RangeElements which are in the other, or which have other such Editions, recursively.  (This searches down to, but not across, work boundaries.)
	If nestOther flag is set, then looks not only for RangeElements which are values of the other Edition, but also those which are values of sub-Editions of the other Edition. (This option will probably not be supported in version 1.0).
	If both flags are false, then equivalent to:
		this->mapSharedTo (other)->domain ()
	
	{ k1 | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuRegion makeBrokenBy: other].
	(flags isBroken) ifTrue:
		[^XuRegion makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition sharedRegion: ((XuPromise getActual: other) cast: FeEdition) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} sharedWith: other {XuEdition} with: flags {XuIntValue default: DefaultZero} 

	"Essential.  Return a new FeEdition consisting of the subset of this Edition whose RangeElements are in the other Edition. If the same RangeElement is in this Edition at several different positions, all positions will be in the result (provided the RangeElement is also in the other Edition).
	Equivalent to:
		this->copy (this->sharedRegion (other, flags)).
		
	{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuEdition makeBrokenBy: other].
	(flags isBroken) ifTrue:
		[^XuEdition makeBrokenBy: flags].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition sharedWith: ((XuPromise getActual: other) cast: FeEdition) with:flags getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'endorsing'!

{XuVoid} endorse: additionalEndorsements {XuCrossRegion} 

	"Essential.  Adds to the endorsements on this Edition.  The region of additionalEndorsements must consist of a finite number of (club ID, token ID) pairs.  CurrentKeyMaster must hold the signature authority of all the Clubs used to endorse; the request will blast and do nothing if any of the required authority is lacking.  (Redoing an endorse() undoes a retract())"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(additionalEndorsements isBroken) ifTrue:
		[^XuVoid makeBrokenBy: additionalEndorsements].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeEdition endorse: ((XuPromise getActual: additionalEndorsements) cast: CrossRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossRegion} endorsements

	"Essential.  Return all of the endorsements which have been placed on this Edition and not retracted."
	
	| retVal {XuCrossRegion} |
	(self isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossRegion make: (self getActualFeEdition endorsements)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} retract: endorsements {XuCrossRegion} 

	"Essential.  Removes endorsements from this Edition.  This requires that the CurrentKeyMaster hold signature authority for all of the Clubs whose endorsements are in the list; will blast and do nothing if any of the required authority is lacking, even if the endorsements weren't there to be retracted.  Ignores all endorsements which you could have removed, but which don't happen to be there right now.
	
	In the current release removed endorsements aren't preserved, so they vanish forever.  Beginning in some future release removed endorsements will become inactive, but it will be possible to detect that they once had been present.  The intent is for a removed endorsement to be analogous to a signature that has been struck out.  You can express that you changed your mind, but you can't undo the past."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(endorsements isBroken) ifTrue:
		[^XuVoid makeBrokenBy: endorsements].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeEdition retract: ((XuPromise getActual: endorsements) cast: CrossRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossRegion} visibleEndorsements

	"Essential.  Return all the unretracted endorsements on this Edition along with those on any Works directly on it which the CurrentKeyMaster has permission to read."
	
	| retVal {XuCrossRegion} |
	(self isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossRegion make: (self getActualFeEdition visibleEndorsements)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'becoming'!

{XuRegion} canMakeRangeIdentical: newIdentities {XuEdition} with: positions {XuRegion default: DefaultNull} 

	"Essential.  Return the region consisting of all locations at which my RangeElements can NOT be made identical to the corresponding RangeElements in the other Edition. (This seems like the opposite of what you want, but in fact it makes it easy to check for success.)
	Does not check whether you have permissions to do so, just whether it could be done by someone with the appropriate permissions. See rangeOwners."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(newIdentities isBroken) ifTrue:
		[^XuRegion makeBrokenBy: newIdentities].
	(positions isBroken) ifTrue:
		[^XuRegion makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition canMakeRangeIdentical: ((XuPromise getActual: newIdentities) cast: FeEdition) with: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuFillRangeDetector} fillRangeDetector

	"Essential.  Return a FillRangeDetector so that when any of the PlaceHolders in this Edition become any other kind of RangeElement, then the Detector will be triggered with an Edition containing the new RangeElements (but not necessarily at the same positions, or even in the same CoordinateSpace). If there already are non-PlaceHolders, then the Detector is triggered immediately with those RangeElements.
	See FillRangeDetector::allFilled (Edition * newIdentities)."
	
	| retVal {XuFillRangeDetector} |
	(self isBroken) ifTrue:
		[^XuFillRangeDetector makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuFillRangeDetector makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuFillRangeDetector make: (self getActualFeEdition fillRangeDetector)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} makeRangeIdentical: newIdentities {XuEdition} with: positions {XuRegion default: DefaultNull} 

	"Essential.  Try to change the identity of each RangeElements of this Edition which are in the Region (or all if no Region supplied) to that of the RangeElement at the same position in the other Edition. Returns the subset of this Edition which did not end up with the new identities, because of
		- lack of ownership authority
		- different contents
		- contents of other edition unreadable
		- incompatible types
		- no corresponding new identity
		
Note that the labels on the RangeElements need not match and will NOT be changed."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(newIdentities isBroken) ifTrue:
		[^XuEdition makeBrokenBy: newIdentities].
	(positions isBroken) ifTrue:
		[^XuEdition makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition makeRangeIdentical: ((XuPromise getActual: newIdentities) cast: FeEdition) with: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIDRegion} rangeOwners: positions {XuRegion default: DefaultNull} 

	"The owners of all the RangeElements in the given Region, or in the entire 
	Edition if no Region is specified."
	
	| retVal {XuIDRegion} |
	(self isBroken) ifTrue:
		[^XuIDRegion makeBrokenBy: self].
	(positions isBroken) ifTrue:
		[^XuIDRegion makeBrokenBy: positions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIDRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIDRegion make: (self getActualFeEdition rangeOwners: ((XuPromise getActual: positions) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} setRangeOwners: newOwner {XuID} with: region {XuRegion default: DefaultNull} 

	"Changes the owner of all RangeElements in the Edition (but not the Edition itself!!); requires the authority of the current owner of each range element. If a Region is supplied, then only sets those in the region.
	Returns the subset of this Edition which is in the Region whose owners did not end up being the new Owner because of lack of authority."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(newOwner isBroken) ifTrue:
		[^XuEdition makeBrokenBy: newOwner].
	(region isBroken) ifTrue:
		[^XuEdition makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition setRangeOwners: ((XuPromise getActual: newOwner) cast: ID) with: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuEdition methodsFor: 'promise access'!

{FeEdition} getActualFeEdition
	self isBroken
		ifFalse: [^super actualThing cast: FeEdition.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuEdition methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeEdition {FeEdition}
	super create: anFeEdition.! !

!XuEdition methodsFor: 'labelling'!

{XuRegion} positionsLabelled: label {XuLabel} 

	"Return a region consisting of exactly the positions in this Edition which are associated with the given label.
	
	{ k | <k,label,v> in self }"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(label isBroken) ifTrue:
		[^XuRegion makeBrokenBy: label].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeEdition positionsLabelled: ((XuPromise getActual: label) cast: FeLabel))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuEdition} rebind: position {XuPosition} with: edition {XuEdition} 

	"Return a new FeEdition which is a copy of this Edition with the contained Edition at the given position replaced by the given Edition, but with the Label at that position unchanged.  Equivalent to
		this->with (position, edition->relabelled (this->get (position)->label ())).

	Note that rebind() is useless (and blasts) when a non-edition RangeElement is at the given position.
		
	{ <k,l,v> | ((k isEqual: position) and (v is same as edition)) 
				or (<k,l,v> in self and k !!= position) }"
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuEdition makeBrokenBy: position].
	(edition isBroken) ifTrue:
		[^XuEdition makeBrokenBy: edition].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeEdition rebind: ((XuPromise getActual: position) cast: Position) with: ((XuPromise getActual: edition) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuEdition class
	instanceVariableNames: ''!

(XuEdition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuEdition class methodsFor: 'pseudo-constructors'!

make: anFeEdition {FeEdition}
	^self create: anFeEdition!

{XuEdition} makeBroken: problem {Problem star}
	| broke {XuEdition} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuEdition} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !