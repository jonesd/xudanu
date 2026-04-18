'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:57 pm'!

FeRangeElement subclass: #FeEdition
	instanceVariableNames: '
		myBeEdition {BeEdition}
		myLabel {FeLabel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeEdition comment:
'The kind of FeRangeElement that consists of an immutable organization of RangeElements, indexed by Positions in some CoordinateSpace.
 R1 prohibits cyclic containment.

Set notation is used in the comments documenting some of the methods of this class.  In each case the cleartext explanation stands alone, and the set notation is a separate, more formal, expression of the actions of the method, in terms of key(position)/label/value triples ("<k,l,v>").'!

(FeEdition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeEdition methodsFor: 'operations'!

{FeEdition CLIENT} combine: other {FeEdition}
	"Essential.  Return a new FeEdition containing the contents of boththe receiver and the argument Editions, and with the label of the receiving edition; where they share positions, they must have the same RangeElement.  Currently the two may not share positions.  It is unclear whether to elevate this from an implementation restriction to a specification.  The advantage of so specifying is that 'combine' becomes timing independent, i.e. a failing combine could otherwise succeed after the differing range elements were unified (by FeRangeElement::makeIdentical()).  See FeEdition::mapSharedOnto and FeEdition::transformedBy.
	
	{ <k,l,v> | <k,l,v> in self or <k,l,v> in other }
	requires:
		currently: { k | <k,la,v1> in self and <k,lb,v2> in other } is empty
		eventually maybe: { k | v1 not same as v2 
									and <k,la,v1> in self and <k,lb,v2> in other } is empty"
	
	^FeEdition on: (myBeEdition combine: other beEdition) with: myLabel!

{FeEdition CLIENT} copy: positions {XnRegion}
	"Return a new FeEdition which is the subset of this Edition with the domain restricted to the given set of positions  The new edition has the same label as this edition.
	
	{ <k,l,v> | k in positions and <k,l,v> in self }"
	
	^FeEdition on: (myBeEdition copy: positions) with: myLabel!

{FeEdition CLIENT} replace: other {FeEdition}
	"Return a new FeEdition with the label of the current Edition and the contents of both Editions; where they share positions, use the contents and labels of the other Edition. Equivalent to
		this->copy (other->domain ()->complement ())->combine (other).
		
	{ <k,l,v> | <k,l,v> in other or (<k,l,v> in self and <k,l2,v2> not in other }"
		
	^FeEdition on: (myBeEdition replace: other beEdition) with: myLabel!

{FeEdition CLIENT} transformedBy: mapping {Mapping}
	"Essential.  Return a new FeEdition containing the contents and label of the current Edition with the positions transformed according to the given Mapping. Where the Mapping takes several positions in the domain to a single position in the range, this Edition must have the same RangeElement and label at all the domain positions.  Currently the mapping must be 'onto', i.e., no more that one domain position may map onto any given range position.  It is unclear whether to elevate this from an implementation restriction to a specification.  See FeEdition::mapSharedOnto and FeEdition::combine.
	
	{ <k2,l1,v1> | <k1,l1,v1> in self and <k1,k2> in mapping }
	requires:
		Currently: not exists k1a, k1b : k1a !!= k1b and <k1a,k2> in mapping and <k1b,k2> in mapping.
		Maybe eventually: for all v1, v2 : <k,l1,v1> in result and <k,l2,v2> in result, v1 is same as v2"
	
	^FeEdition on: (myBeEdition transformedBy: mapping) with: myLabel!

{FeEdition CLIENT} with: position {Position} with: value {FeRangeElement}
	"Return a new FeEditionwith the same contents and label as this Edition, except for the addition or substitution of a RangeElement at a specified position.
	(The difference between with() and rebind() is exactly that rebind() preserves the old label at position, while with() installs the label attached to the value argument.)
	Equivalent to:
		this->replace (FeServer::current ()->makeEditionWith (position, value))"
		
	^FeEdition on: (myBeEdition with: position with: value carrier) with: myLabel!

{FeEdition CLIENT} withAll: positions {XnRegion} with: value {FeRangeElement}
	"Return a new FeEdition with the same contents and label as this Edition, except at a specified set of positions, where the old values and labels, if there are any, are superceded by the value argument.
	Equivalent to:
		this->replace (FeServer::current ()->makeEditionWithAll (positions, value))"
		
	^FeEdition on: (myBeEdition withAll: positions with: value carrier) with: myLabel!

{FeEdition CLIENT} without: position {Position}
	"Return a new FeEdition with the same contents and label as this Edition, except at a specified position, where the old value and label, if there is one, is removed.
	Equivalent to:
		this->copy (position->asRegion ()->complement ())"
		
	^FeEdition on: (myBeEdition without: position) with: myLabel!

{FeEdition CLIENT} withoutAll: positions {XnRegion}
	"Return a new FeEdition with the same contents and label as this Edition, except at a specified set of positions, where the old values and labels, if there are any, are removed.
	Equivalent to
		this->copy (positions->complement ())"
		
	^FeEdition on: (myBeEdition withoutAll: positions) with: myLabel! !

!FeEdition methodsFor: 'accessing'!

{CoordinateSpace CLIENT} coordinateSpace
	"Return the space in which the positions of this Edition are positions. Equivalent to
		this->domain ()->coordinateSpace ()"
	^myBeEdition coordinateSpace!

{IntegerVar CLIENT} cost: method {Int32}
	"Essential. Retiurn how much space this Edition is taking up on the disk, in bytes (but the precision may exceed the accuracy; it's simply a well-known unit). The method determines how material shared with other Editions is treated: if omitShared, it is not counted at all; if prorateShared, then it is divided evenly among the Editions sharing it; if totalShared, its entire cost is counted. This figure is only approximate, and may vary with time.
	(No permissions are required to obtain this informiation, even though it exposes sharing by Editions you can't read to traffic analysis.)"
	
	Someone shouldImplement.
	^IntegerVarZero "fodder"!

{IntegerVar CLIENT} count
	"Return the number of positions in this Edition. Blasts if infinite. Equivalent to
		this->domain ()->count ()"
		
	^myBeEdition count!

{XnRegion CLIENT} domain
	"Essential.  Return the region consisting of all the positions in this Edition. May be infinite, or empty.
	
	{ k | <k,l,v> in self }"
	
	^myBeEdition domain!

{FeRangeElement CLIENT} get: position {Position}
	"Return the value at the given position, or blast if there is no such position (i.e. if !! this->domain ()->hasMember (position)).
	
	v : <position,l,v> in self
	requires: <position,l,v> in self"
	
	^myBeEdition get: position!

{BooleanVar CLIENT} hasPosition: position {Position}
	"Return whether the given position is in the Edition. Equivalent to
		this->domain ()->hasMember (position)"
	
	self thingToDo. "rename Be protocol"
	^myBeEdition includesKey: position!

{BooleanVar CLIENT} isEmpty
	"Return whether there are any positions in this Edition. Equivalent to
		this->domain ()->isEmpty ()"
	
	^myBeEdition isEmpty!

{BooleanVar CLIENT} isFinite
	"Return whether there are a finite number of positions in this Edition. Equivalent to
		this->domain ()->isFinite ()"
	
	^myBeEdition isFinite!

{(Stepper of: Bundle) CLIENT} retrieve: region {XnRegion default: NULL}
	with: order {OrderSpec default: NULL}
	with: flags {Int32 default: Int32Zero}
	"Essential.  This is the fundamental retrieval operation.  Return a stepper of bundles.  Each bundle is an association between a region in the domain and the range elements associated with that region.  Where the region is associated with data, for instance, the bundle contains a PrimArray of the data elements.
	If a region is given, only that subset of the Edition's contents will be returned.  If it is not given, the entire content of the Edition will be returned.
	if the ignoreTotalOrdering flag is set, then the operation can group non-contiguous regions, and can supply the bundles in any order.
	if the ignoreArrayOrdering flag is set, then ArrayBundles returned by the operation can be ordered differently from the supplied order.
	If an OrderSpec is not supplied, then the ordering will be the default order for the coordinate space, if one exists, and if none exists the returned data will be completely unordered and the Ordering flags will be ignored."
	
	self thingToDo.  "The above comment is still horribly insufficient."
	
	^myBeEdition retrieve: region with: order with: flags!

{TableStepper CLIENT of: FeRangeElement} stepper: region {XnRegion default: NULL}
	with: ordering {OrderSpec default: NULL}
	"Return a stepper for iterating over the positions and RangeElements of this Edition. If a region is specified, then it only iterates over the domain positions which are in the given region. If no ordering is specified, then the default ascending full ordering of the CoordinateSpace is used, or a random order chosen if there is no default."
	
	| theRegion {XnRegion} |
	theRegion := self domain.
	region ~~ NULL
		ifTrue: [theRegion := theRegion intersect: region].
	^EditionStepper create: (theRegion stepper: ordering) with: self!

{FeRangeElement CLIENT} theOne
	"If this Edition has a single position, then return the RangeElement at that position; if not, blasts. Equivalent to
		this->get (this->domain ()->theOne ())"
		
	^myBeEdition theOne! !

!FeEdition methodsFor: 'comparing'!

{BooleanVar CLIENT} isRangeIdentical: other {FeEdition}
	with: region {XnRegion default: NULL}
	"Whether the two Editions have the same domains, and each RangeElement isIdentical to the corresponding RangeElement in the other Edition."
	
	Someone shouldImplement.
	^false "fodder"!

{Mapping CLIENT} mapSharedOnto: other {FeEdition}
	"Return a mapping such that for each range element that appears in both editions, the mapping maps each of its appearances in the argument edition to some appearance in this one.  (Some of the appearances in this edition may be unmapped or mapped to multiple appearances in the argument edition.)  Like 'mapSharedTo' except that the resulting mapping is 'onto'.  This means that each range position of the resulting mapping inverse maps to at most one domain position.  Such a mapping is suitable as an argument to 'transformedBy', and represents the minimal transformation needed to make the shared part of 'other' from self.  Note that there is no unique answer.
	
	result = { <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2
							and not exists k11 : k11 !!= k1 and <k11,k2> in result }
	
Note that this is useful for optimization of FeBe communication and Frontend display updating."

	Someone shouldImplement.
	^NULL "fodder"!

{Mapping CLIENT} mapSharedTo: other {FeEdition}
	"Essential.  Return a Mapping from each of the positions in this Edition to all of the positions in the other Edition which have the same RangeElement.
	
	{ <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	^myBeEdition mapSharedTo: other beEdition!

{FeEdition CLIENT} notSharedWith: other {FeEdition}
	with: flags {Int32 default: Int32Zero}
	"Return a new FeEdition containing exactly the subset of this Edition whose RangeElements are not in the other Edition.
	Equivalent to:
		this->copy (this->sharedRegion (other)->complement ()).
		
	{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }
	
Note that this is useful for optimization of FeBe communication and Frontend display updating."
		
	^FeEdition on: (myBeEdition
			notSharedWith: other beEdition with: flags)
		with: myLabel!

{XnRegion CLIENT} positionsOf: value {FeRangeElement}
	"Return the region consisting of all the positions in this Edition at which the given RangeElement can be found.
	Equivalent to:
		this->sharedRegion (theServer ()->makeEditionWith (some position, value)).
		
	{ k | <k,l,v> in self and v is same as value }"
	
	self thingToDo. "rename Be protocol"
	^myBeEdition keysOf: value!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	with: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTranscluders {FeEdition default: NULL}
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
	
	| theOther {BeEdition} theDirectFilter {Filter} theIndirectFilter {Filter} |
	otherTranscluders == NULL
		ifTrue: [theOther := NULL]
		ifFalse: [theOther := otherTranscluders beEdition].
	directFilter == NULL
		ifTrue: [theDirectFilter := FeServer endorsementFilterSpace fullRegion cast: Filter]
		ifFalse: [theDirectFilter := directFilter].
	indirectFilter == NULL
		ifTrue: [theIndirectFilter := FeServer endorsementFilterSpace fullRegion cast: Filter]
		ifFalse: [theIndirectFilter := indirectFilter].
	^FeEdition on: 
		(myBeEdition
			rangeTranscluders: positions
			with: theDirectFilter
			with: theIndirectFilter
			with: flags
			with: theOther)!

{FeEdition CLIENT} rangeWorks: positions {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTranscluders {FeEdition default: NULL}
	"Essential.  Return a new FeEdition containing all Works which contain RangeElements of this Edition and can be read by the CurrentKeyMaster. Returns an IDSpace Edition full of PlaceHolders, which will be filled with Works as results come in.
	If a filter is given, then only Works whose endorsements pass the Filter are returned.
	If the localPresentOnly flag is clear, a persistent request will be created, and as new Works come to be known to the Server, they will be filled into the resulting Edition.  If it is set, only Works currently known to this Server are sure to be recorded into the Trail.  (Some, but not all, Works which become known while this request is being processed may be recorded.  If the request is followed by a FeServer::waitForConsequences(), no Works which become known after the wait completes will be recorded.)
	If the fromTransitiveContents flag is set, then the result includes Works which contain RangeElements transitively contained in this Edition. (This may not be supported in 1.0)
	If directContainersOnly is set, then only Works which are directly on Editions which are RangeElements of this Edition are returned (and not Works which are on Editions which have them as sub-Editions).
	If otherTranscluders is given, this records works into that trail.
	(For convenience, you can attach a TransclusionDetector to the result Edition.  See FeEdition::addFillRangeDetector()  See also FeServer::waitForConsequences().)
	
	{ <k,l,w> | w's contains self, w passes filter}"
		
	| theOther {BeEdition} theFilter {Filter} |
	otherTranscluders == NULL
		ifTrue: [theOther := NULL]
		ifFalse: [theOther := otherTranscluders beEdition].
	filter == NULL
		ifTrue: [theFilter := FeServer endorsementFilterSpace fullRegion cast: Filter]
		ifFalse: [theFilter := filter].
	^FeEdition on: 
		(myBeEdition
			rangeWorks: positions
			with: theFilter
			with: flags
			with: theOther)!

{XnRegion CLIENT} sharedRegion: other {FeEdition}
	with: flags {Int32 default: Int32Zero}
	"Return the subset of the positions of this Edition which  have RangeElements that are in the other Edition.
	If nestThis flag is set, then returns not only positions of RangeElements which are in the other, but also positions of Editions which have RangeElements which are in the other, or which have other such Editions, recursively.  (This searches down to, but not across, work boundaries.)
	If nestOther flag is set, then looks not only for RangeElements which are values of the other Edition, but also those which are values of sub-Editions of the other Edition. (This option will probably not be supported in version 1.0).
	If both flags are false, then equivalent to:
		this->mapSharedTo (other)->domain ()
	
	{ k1 | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
	
	^myBeEdition sharedRegion: other beEdition with: flags!

{FeEdition CLIENT} sharedWith: other {FeEdition}
	with: flags {Int32 default: Int32Zero}
	"Essential.  Return a new FeEdition consisting of the subset of this Edition whose RangeElements are in the other Edition. If the same RangeElement is in this Edition at several different positions, all positions will be in the result (provided the RangeElement is also in the other Edition).
	Equivalent to:
		this->copy (this->sharedRegion (other, flags)).
		
	{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is same as v2 }"
		
	^FeEdition on: (myBeEdition
			sharedWith: other beEdition with: flags)
		with: myLabel! !

!FeEdition methodsFor: 'endorsing'!

{void CLIENT} endorse: additionalEndorsements {CrossRegion}
	"Essential.  Adds to the endorsements on this Edition.  The region of additionalEndorsements must consist of a finite number of (club ID, token ID) pairs.  CurrentKeyMaster must hold the signature authority of all the Clubs used to endorse; the request will blast and do nothing if any of the required authority is lacking.  (Redoing an endorse() undoes a retract())"
	
	FeRangeElement validateEndorsement: additionalEndorsements with: CurrentKeyMaster fluidGet.
	myBeEdition endorse: additionalEndorsements!

{CrossRegion CLIENT} endorsements
	"Essential.  Return all of the endorsements which have been placed on this Edition and not retracted."
	
	^myBeEdition endorsements!

{void CLIENT} retract: endorsements {CrossRegion}
	"Essential.  Removes endorsements from this Edition.  This requires that the CurrentKeyMaster hold signature authority for all of the Clubs whose endorsements are in the list; will blast and do nothing if any of the required authority is lacking, even if the endorsements weren't there to be retracted.  Ignores all endorsements which you could have removed, but which don't happen to be there right now.
	
	In the current release removed endorsements aren't preserved, so they vanish forever.  Beginning in some future release removed endorsements will become inactive, but it will be possible to detect that they once had been present.  The intent is for a removed endorsement to be analogous to a signature that has been struck out.  You can express that you changed your mind, but you can't undo the past."
	
	FeRangeElement validateEndorsement: endorsements with: CurrentKeyMaster fluidGet.
	myBeEdition retract: endorsements!

{CrossRegion CLIENT} visibleEndorsements
	"Essential.  Return all the unretracted endorsements on this Edition along with those on any Works directly on it which the CurrentKeyMaster has permission to read."
	
	^myBeEdition visibleEndorsements! !

!FeEdition methodsFor: 'becoming'!

{void} addFillRangeDetector: detector {FeFillRangeDetector}
	"Essential.  Connect a FillRangeDetector to the underlying BeEdition so that when any of the PlaceHolders in that Edition become any other kind of RangeElement, then the Detector will be triggered with an Edition containing the new RangeElements (but not necessarily at the same positions, or even in the same CoordinateSpace). If there already are non-PlaceHolders, then the Detector is triggered immediately with those RangeElements.
	See FillRangeDetector::allFilled (Edition * newIdentities)."
	
	myBeEdition addDetector: detector!

{XnRegion CLIENT} canMakeRangeIdentical: newIdentities {FeEdition}
	with: positions {XnRegion default: NULL}
	"Essential.  Return the region consisting of all locations at which my RangeElements can NOT be made identical to the corresponding RangeElements in the other Edition. (This seems like the opposite of what you want, but in fact it makes it easy to check for success.)
	Does not check whether you have permissions to do so, just whether it could be done by someone with the appropriate permissions. See rangeOwners."
	
	Dean shouldImplement.
	^NULL "fodder"!

{FeFillRangeDetector CLIENT} fillRangeDetector
	"Essential.  Return a FillRangeDetector so that when any of the PlaceHolders in this Edition become any other kind of RangeElement, then the Detector will be triggered with an Edition containing the new RangeElements (but not necessarily at the same positions, or even in the same CoordinateSpace). If there already are non-PlaceHolders, then the Detector is triggered immediately with those RangeElements.
	See FillRangeDetector::allFilled (Edition * newIdentities)."
	
	Dean shouldImplement.
	self addFillRangeDetector: NULL.
	^NULL "fodder"!

{FeEdition CLIENT} makeRangeIdentical: newIdentities {FeEdition}
	with: positions {XnRegion default: NULL}
	"Essential.  Try to change the identity of each RangeElements of this Edition which are in the Region (or all if no Region supplied) to that of the RangeElement at the same position in the other Edition. Returns the subset of this Edition which did not end up with the new identities, because of
		- lack of ownership authority
		- different contents
		- contents of other edition unreadable
		- incompatible types
		- no corresponding new identity
		
Note that the labels on the RangeElements need not match and will NOT be changed."
	
	| never {BeEdition} maybe {BeEdition} trial {BeEdition} result {Pair of: BeEdition} theRegion {XnRegion} |
	"Keep trying the primitive routine until it says it can't do any more"
	self knownBug. "put loop into server loop"
	(self coordinateSpace isEqual: newIdentities coordinateSpace) ifFalse:
		[^self].
	never := CurrentGrandMap fluidGet newEmptyEdition: self coordinateSpace.
	maybe := myBeEdition.
	theRegion := maybe domain.
	positions ~~ NULL ifTrue:
		[theRegion := theRegion intersect: positions].
	trial := newIdentities beEdition copy: theRegion.
	[(result := maybe tryAllBecome: trial) fetchRight ~~ NULL]
		whileTrue:
			[never := never combine: (result left cast: BeEdition).
			maybe := result right cast: BeEdition.
			trial := trial copy: maybe domain].
	^FeEdition on: never with: myLabel!

{IDRegion CLIENT} rangeOwners: positions {XnRegion default: NULL} 
	"The owners of all the RangeElements in the given Region, or in the entire 
	Edition if no Region is specified."

	^myBeEdition rangeOwners: positions!

{void} removeFillRangeDetector: detector {FeFillRangeDetector}
	"Essential.  Remove a Detector which had been added to this Edition. You should remove every Detector you add, although they will go away automatically when a client session terminates."
	
	(Heaper isDestructed: myBeEdition) ifFalse:
		[myBeEdition removeDetector: detector]!

{FeEdition CLIENT} setRangeOwners: newOwner {ID} with: region {XnRegion default: NULL}
	"Changes the owner of all RangeElements in the Edition (but not the Edition itself!!); requires the authority of the current owner of each range element. If a Region is supplied, then only sets those in the region.
	Returns the subset of this Edition which is in the Region whose owners did not end up being the new Owner because of lack of authority."
	
	| theRegion {XnRegion} |
	region == NULL
		ifTrue: [theRegion := self domain]
		ifFalse: [theRegion := region].
	^FeEdition on: (myBeEdition setRangeOwners: newOwner with: theRegion) with: myLabel! !

!FeEdition methodsFor: 'labelling'!

{FeLabel} label

	^myLabel!

{XnRegion CLIENT} positionsLabelled: label {FeLabel}
	"Return a region consisting of exactly the positions in this Edition which are associated with the given label.
	
	{ k | <k,label,v> in self }"
	
	self thingToDo. "rename Be protocol"
	^myBeEdition keysLabelled: (label fetchBe cast: BeLabel)!

{FeEdition CLIENT} rebind: position {Position} with: edition {FeEdition}
	"Return a new FeEdition which is a copy of this Edition with the contained Edition at the given position replaced by the given Edition, but with the Label at that position unchanged.  Equivalent to
		this->with (position, edition->relabelled (this->get (position)->label ())).

	Note that rebind() is useless (and blasts) when a non-edition RangeElement is at the given position.
		
	{ <k,l,v> | ((k isEqual: position) and (v is same as edition)) 
				or (<k,l,v> in self and k !!= position) }"
	
	^self class fromOne: position with: (edition relabelled: ((self get: position) cast: FeEdition) label)!

{FeRangeElement} relabelled: label {FeLabel}

	^FeEdition on: myBeEdition with: label! !

!FeEdition methodsFor: 'server accessing'!

{BeEdition} beEdition
	^myBeEdition!

{BeCarrier} carrier
	"Return an object that wraps up any run-time state that might be needed inside the Be system.  Right now that means labels."
	
	^BeCarrier make: (myLabel getOrMakeBe cast: BeLabel) with: myBeEdition!

{FeRangeElement} fetch: position {Position}
	"The value at the position, or NULL if there is none"
	^myBeEdition fetch: position!

{BeRangeElement | NULL} fetchBe

	^myBeEdition!

{BeRangeElement} getOrMakeBe

	^myBeEdition! !

!FeEdition methodsFor: 'client implementation'!

{FeRangeElement} again
	"These don't change as long as someone has a handle on them."
	
	^self!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented]! !

!FeEdition methodsFor: 'private: create'!

create: beEdition {BeEdition} with: label {FeLabel}

	super create.
	myBeEdition := beEdition.
	myLabel _ label.! !

!FeEdition methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	| before {char star} |
	self isEmpty ifTrue: [oo << 'Edition()'. ^VOID].
	before := 'Edition('.
	(self retrieve: NULL with: NULL with: FeEdition IGNORE.U.TOTAL.U.ORDERING) forEach:
		[ :bundle {FeBundle} |
		oo << before << bundle region << ' -> '.
		bundle cast: FeArrayBundle into:
			[ :array | oo << array array]
		cast: FeElementBundle into:
			[ :range | oo << range element]
		cast: FePlaceHolderBundle into:
			[ :place | oo << '{...}'].
		before := ', '].
	oo << ')'! !

!FeEdition methodsFor: 'smalltalk: defaults'!

{XnRegion CLIENT} canMakeRangeIdentical: newIdentities {FeEdition}

	^self canMakeRangeIdentical: newIdentities with: NULL!

{BooleanVar CLIENT} isRangeIdentical: other {FeEdition}

	^self isRangeIdentical: other with: NULL!

{FeEdition CLIENT} makeRangeIdentical: newIdentities {FeEdition}

	^self makeRangeIdentical: newIdentities with: NULL!

{FeEdition CLIENT} notSharedWith: other {FeEdition}

	^self notSharedWith: other with: 0!

{FeEdition CLIENT} rangeTranscluders
	
	^self rangeTranscluders: NULL with: NULL with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	
	^self rangeTranscluders: positions with: NULL with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	
	^self rangeTranscluders: positions with: filter with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	with: transitiveFilter {Filter default: NULL}
	
	^self rangeTranscluders: positions with: filter with: transitiveFilter with: Int32Zero with: NULL!

{FeEdition CLIENT} rangeTranscluders: positions {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	with: transitiveFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	
	^self rangeTranscluders: positions with: filter with: transitiveFilter with: flags with: NULL!

{FeEdition CLIENT} rangeWorks
	^self rangeWorks: NULL with: NULL with: 0 with: NULL!

{FeEdition CLIENT} rangeWorks: region {XnRegion default: NULL}
	^self rangeWorks: region with: NULL with: 0 with: NULL!

{FeEdition CLIENT} rangeWorks: region {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	^self rangeWorks: region with: filter with: 0 with: NULL!

{FeEdition CLIENT} rangeWorks: region {XnRegion default: NULL}
	with: filter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	
	^self rangeWorks: region with: filter with: flags with: NULL!

{(Stepper of: Bundle) CLIENT} retrieve

	^self retrieve: NULL with: NULL with: 0!

{(Stepper of: Bundle) CLIENT} retrieve: positions {XnRegion default: NULL}

	^self retrieve: positions with: NULL with: 0!

{(Stepper of: Bundle) CLIENT} retrieve: positions {XnRegion default: NULL} with: order {OrderSpec default: NULL}

	^self retrieve: positions with: order with: 0!

{FeEdition CLIENT} setRangeOwners: newOwner {ID}

	^self setRangeOwners: newOwner with: NULL!

{XnRegion CLIENT} sharedRegion: other {FeEdition}
	^self sharedRegion: other with: 0!

{FeEdition CLIENT} sharedWith: other {FeEdition}
	^self sharedWith: other with: 0!

{TableStepper CLIENT of: FeRangeElement} stepper
	^self stepper: NULL with: NULL!

{TableStepper CLIENT of: FeRangeElement} stepper: region {XnRegion default: NULL}
	^self stepper: region with: NULL! !

!FeEdition methodsFor: 'smalltalk: passe'!

{void} addCompletionDetector: detector {FeCompletionDetector}
	self passe!

{void} addFillInDetector: detector {FeFillInDetector}

	self passe!

{FeEdition} allBecome: newIdentities {FeEdition} with: positions {XnRegion default: NULL}

	self passe "makeRangeIdentical"!

{PrimArray} asArray: positions {XnRegion default: NULL}
	with: ordering {OrderSpec default: NULL}

	self passe "use retrieve"!

{XnRegion} keysLabelled: label {FeLabel}

	self passe!

{FeEdition} parcelAt: position {Position}
	"Some subset of this Edition, containing the given position, all with the same owner
	
	{ <k,l,v> | <k,l,v> in self and <position,l2,v2> in self and v.owner == v2.owner }"
	
self passe!

{FeEdition of: ID and: FeEdition} parcels
	"Divides this Edition into pieces each of whose RangeElements are all owned by a single Club.
	
	{ <k1, { <k2,v2> } > | <k2,v2> in self and k1 == v2's owner }"
	
	self passe!

{void} removeCompletionDetector: detector {FeCompletionDetector}
self passe!

{void} removeFillInDetector: detector {FeFillInDetector}

	self passe!

{FeEdition} reorganize: oldRegion {XnRegion | NULL}
	with: oldOrder {OrderSpec | NULL}
	with: newRegion {XnRegion | NULL}
	with: newOrder {OrderSpec | NULL}
	"Rearrange the positions of this Edition to lie in the given region, with the given ordering. Equivalent to server->makeEdition (this->asArray (oldRegion, oldOrder), newRegion, newOrder, NULL), except that it doesn't require everything to be in the same zone (and is of course more efficient).
	
	This message is tentative and may be removed from the protocol."
	
	^FeEdition on: (myBeEdition
			reorganize: oldRegion with: oldOrder with: newRegion with: newOrder) with: myLabel!

{FeEdition} setAllOwners: newOwner {ID} with: region {XnRegion default: NULL}

	self passe "setRangeOwners"!

{FeEdition} transclusions: positions {XnRegion default: NULL}
	with: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTransclusions {FeEdition default: NULL}

	self passe "rangeTranscluders"!

{void} unendorse: endorsements {CrossRegion}

	self passe "retract"!

{Pair of: PrimSpec and: FeEdition} zoneAt: position {Position}
	"Essential.  A zone containing the given position, all with the same kind of RangeElements."
	
	| result {Pair} |
	self passe.
	self thingToDo. "get rid of BeEdition protocol"
	result := myBeEdition zoneAt: position.
	^Pair make: result left
		with: (FeEdition on: (result left cast: BeEdition) with: myLabel)!

{FeEdition} zoneOf: values {PrimSpec}

	self passe!

{TwoStepper of: PrimSpec and: FeEdition} zones: ordering {OrderSpec default: NULL}
	"Divides this Edition up into pieces all of whose RangeElements have the same PrimSpec. If no ordering is given, then uses the default full ordering for this CoordinateSpace."
	
	self passe! !

!FeEdition methodsFor: 'obsolete:'!

{BooleanVar} includesKey: position {Position}
	"Whether the given position is in the Edition. Equivalent to
		this->domain ()->hasMember (position)"
	
	^myBeEdition includesKey: position!

{XnRegion} keysOf: value {FeRangeElement}
	"All of the keys in this Edition at which the given RangeElement can be found. Equivalent to
		this->sharedRegion (theServer ()->makeEditionWith (some position, value)).
		
	{ k | <k,l,v> in self and v is same as value }"
	
	^myBeEdition keysOf: value! !

!FeEdition methodsFor: 'destruct'!

{void} destruct

	myBeEdition removeFeRangeElement: self.
	super destruct.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeEdition class
	instanceVariableNames: ''!

(FeEdition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeEdition class methodsFor: 'smalltalk: defaults'!

{FeEdition CLIENT} fromArray: values {PrimArray of: FeRangeElement}
	"Essential.  Creates an Edition mapping from a Region of keys to the values in an array. The ordering specifies the correspondance between  the keys and the indices in the array.
	If a Region is given, then it must have the same count as the array.  If no Region is given, then it is taken to be the IntegerRegion from 0  to the size of the array. If no OrderSpec is given, then it is the default ascending full ordering for that CoordinateSpace."
			
	^self fromArray: values with: NULL with: NULL!

{FeEdition CLIENT} fromArray: values {PrimArray of: FeRangeElement}
	with: keys {XnRegion default: NULL}
	"Essential.  Creates an Edition mapping from a Region of keys to the values in an array. The ordering specifies the correspondance between  the keys and the indices in the array.
	If a Region is given, then it must have the same count as the array.  If no Region is given, then it is taken to be the IntegerRegion from 0  to the size of the array. If no OrderSpec is given, then it is the default ascending full ordering for that CoordinateSpace."
			
	^self fromArray: values with: keys with: NULL! !

!FeEdition class methodsFor: 'creation'!

{FeEdition CLIENT} empty: keySpace {CoordinateSpace}
	"An empty Edition, with the given CoordinateSpace but no contents."

	^FeEdition on: (CurrentGrandMap fluidGet newEmptyEdition: keySpace)!

{FeEdition CLIENT} fromAll: keys {XnRegion} with: value {FeRangeElement}
	"Essential.  A singleton Edition mapping from a Region of keys (potentially infinite) to a single value."

	^FeEdition on: 
		(CurrentGrandMap fluidGet
			newEditionWithAll: keys
			with: value carrier)!

{FeEdition CLIENT} fromArray: values {PrimArray of: FeRangeElement}
	with: keys {XnRegion default: NULL}
	with: ordering {OrderSpec default: NULL}
	"Essential.  Creates an Edition mapping from a Region of keys to the values in an array. The ordering specifies the correspondance between  the keys and the indices in the array.
	If a Region is given, then it must have the same count as the array.  If no Region is given, then it is taken to be the IntegerRegion from 0  to the size of the array. If no OrderSpec is given, then it is the default ascending full ordering for that CoordinateSpace."
			
	| theKeys {XnRegion} theOrdering {OrderSpec} |
	keys == NULL
		ifTrue: [theKeys := IntegerRegion make: IntegerVar0 with: values count]
		ifFalse: [theKeys := keys].
	ordering == NULL
		ifTrue: [theOrdering := theKeys coordinateSpace getAscending]
		ifFalse: [theOrdering := ordering].
	values
		cast: PrimDataArray into: 
			[ :data |
			^FeEdition on: 
				(CurrentGrandMap fluidGet
					newDataEdition: data
					with: theKeys 
					with: theOrdering )]
		cast: PtrArray into: 
			[ :ptr | 
			^FeEdition on: 
				(CurrentGrandMap fluidGet
					newValueEdition: ptr 
					with: theKeys 
					with: theOrdering)].
	^NULL "fodder"!

{FeEdition CLIENT} fromOne: key {Position} with: value {FeRangeElement}
	"A singleton Edition mapping from a single key to a single value."
	
	^FeEdition on: (CurrentGrandMap fluidGet newEditionWith: key with: value carrier)!

{FeEdition} on: be {BeEdition} 

	| result {FeEdition} |
	result := self create: be with: FeLabel fake.
	be addFeRangeElement: result.
	^result!

{FeEdition} on: be {BeEdition} with: label {FeLabel}

	| result {FeEdition} |
	result := self create: be with: label.
	be addFeRangeElement: result.
	^result!

{FeEdition CLIENT} placeHolders: keys {XnRegion} 
	"Essential.  Create a new Edition mapping from each key in the Region to a new, unique PlaceHolder. The owner will have the capability to make them become something else."
	
	^FeEdition on: (CurrentGrandMap fluidGet newPlaceHolders: keys)! !

!FeEdition class methodsFor: 'constants'!

{Int32 constFn INLINE CLIENT} DIRECT.U.CONTAINERS.U.ONLY
	"For transcluders and works queries - only return objects which directly contain the sources of the query (i.e. excludes those which only contain it transitively through intermediate Editions)"
	^4!

{Int32 constFn INLINE CLIENT} FROM.U.OTHER.U.TRANSITIVE.U.CONTENTS
	"For sharedWith/sharedRegion/notSharedWith - look for RangeElements contained transitively within the other Edition"

	^8!

{Int32 constFn INLINE CLIENT} FROM.U.TRANSITIVE.U.CONTENTS
	"For transcluders, and works queries - consider RangeElements contained transitively inside the Edition, as well as just its immediate RangeElements"
	^2!

{Int32 constFn INLINE CLIENT} IGNORE.U.ARRAY.U.ORDERING
	"Used for retrieve.  Allow the ArrayBundles in retrieve to be organized according to a different ordering."
	
	^2!

{Int32 constFn INLINE CLIENT} IGNORE.U.TOTAL.U.ORDERING
	"Used for retrieve.  Allow non-contiguous chunks to be grouped together on retrieve, and allow the bundles to be presented in any order."
	
	^1!

{Int32 constFn INLINE CLIENT} LOCAL.U.PRESENT.U.ONLY
	"For transcluders and works queries - only guarantee to return items which are currently known to this server"
	^1!

{Int32 constFn INLINE CLIENT} OMIT.U.SHARED
	"For cost - omit the cost of shared material"
	
	^1!

{Int32 constFn INLINE CLIENT} otherTransitiveContents
	"For sharedWith/sharedRegion/notSharedWith"

	^2!

{Int32 constFn INLINE CLIENT} PRORATE.U.SHARED
	"For cost - prorate the cost of shared material among Editions sharing it"
	
	^2!

{Int32 constFn INLINE CLIENT} SEPARATE.U.OWNERS
	"For retrieve - ensure that each Bundle in a retrieve has a single owner"
	
	^32!

{Int32 constFn INLINE CLIENT} thisTransitiveContents
	"Used for version comparison."

	^1!

{Int32 constFn INLINE CLIENT} TO.U.TRANSITIVE.U.CONTENTS
	"For sharedRegion, sharedWith, notSharedWith queries - look down towards transitively contained material"
	^2!

{Int32 constFn INLINE CLIENT} TOTAL.U.SHARED
	"For cost - count the entire cost of shared material"
	
	^3! !

!FeEdition class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Int32 constFn INLINE CLIENT} DIRECT.U.CONTAINERS.U.ONLY
{Int32 constFn INLINE CLIENT} FROM.U.OTHER.U.TRANSITIVE.U.CONTENTS
{Int32 constFn INLINE CLIENT} FROM.U.TRANSITIVE.U.CONTENTS
{Int32 constFn INLINE CLIENT} IGNORE.U.ARRAY.U.ORDERING
{Int32 constFn INLINE CLIENT} IGNORE.U.TOTAL.U.ORDERING
{Int32 constFn INLINE CLIENT} LOCAL.U.PRESENT.U.ONLY
{Int32 constFn INLINE CLIENT} OMIT.U.SHARED
{Int32 constFn INLINE CLIENT} PRORATE.U.SHARED
{Int32 constFn INLINE CLIENT} SEPARATE.U.OWNERS
{Int32 constFn INLINE CLIENT} TO.U.TRANSITIVE.U.CONTENTS
{Int32 constFn INLINE CLIENT} TOTAL.U.SHARED
{void CLIENT} addFillRangeDetector: detector {PrFillRangeDetector}
{XuRegion CLIENT} canMakeRangeIdentical: newIdentities {FeEdition} with: positions {XuRegion default: NULL}
{FeEdition CLIENT} combine: other {FeEdition}
{CoordinateSpace CLIENT} coordinateSpace
{FeEdition CLIENT} copy: positions {XuRegion}
{IntegerVar CLIENT} cost: method {Int32}
{IntegerVar CLIENT} count
{XuRegion CLIENT} domain
{void CLIENT} endorse: endorsements {CrossRegion}
{CrossRegion CLIENT} endorsements
{FeRangeElement CLIENT} get: position {Position}
{BooleanVar CLIENT} hasPosition: position {Position}
{BooleanVar CLIENT} isEmpty
{BooleanVar CLIENT} isFinite
{BooleanVar CLIENT} isRangeIdentical: other {FeEdition}
{BooleanVar CLIENT} isRangeIdentical: other {FeEdition} with: region {XuRegion default: NULL}
{FeEdition CLIENT} makeRangeIdentical: newIdentities {FeEdition} with: positions {XuRegion default: NULL}
{Mapping CLIENT} mapSharedOnto: other {FeEdition}
{Mapping CLIENT} mapSharedTo: other {FeEdition}
{FeEdition CLIENT} notSharedWith: other {FeEdition} with: flags {Int32 default: Int32Zero}
{XuRegion CLIENT} positionsLabelled: label {FeLabel}
{XuRegion CLIENT} positionsOf: value {FeRangeElement}
{IDRegion CLIENT} rangeOwners: positions {XuRegion default: NULL}
{FeEdition CLIENT} rangeTranscluders: positions {XuRegion default: NULL} with: directFilter {Filter default: NULL} with: indirectFilter {Filter default: NULL} with: flags {Int32 default: Int32Zero} with: otherTrail {FeEdition default: NULL}
{FeEdition CLIENT} rangeWorks: positions {XuRegion default: NULL} with: filter {Filter default: NULL} with: flags {Int32 default: Int32Zero} with: otherTrail {FeEdition default: NULL}
{FeEdition CLIENT} rebind: position {Position} with: edition {FeEdition}
{void CLIENT} removeFillRangeDetector: detector {PrFillRangeDetector}
{FeEdition CLIENT} replace: other {FeEdition}
{void CLIENT} retract: endorsements {CrossRegion}
{(Stepper of: Bundle) CLIENT} retrieve: positions {XuRegion default: NULL} with: order {OrderSpec default: NULL} with: flags {Int32 default: Int32Zero}
{FeEdition CLIENT} setRangeOwners: newOwner {ID} with: positions {XuRegion default: NULL}
{XuRegion CLIENT} sharedRegion: other {FeEdition} with: flags {Int32 default: Int32Zero}
{FeEdition CLIENT} sharedWith: other {FeEdition} with: flags {Int32 default: Int32Zero}
{TableStepper CLIENT of: FeRangeElement} stepper: region {XuRegion default: NULL} with: order {OrderSpec default: NULL}
{FeRangeElement CLIENT} theOne
{FeEdition CLIENT} transformedBy: mapping {Mapping}
{CrossRegion CLIENT} visibleEndorsements
{FeEdition CLIENT} with: position {Position} with: value {FeRangeElement}
{FeEdition CLIENT} withAll: positions {XuRegion} with: value {FeRangeElement}
{FeEdition CLIENT} without: position {Position}
{FeEdition CLIENT} withoutAll: positions {XuRegion}
"! !