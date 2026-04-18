'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:38 pm'!

BeRangeElement subclass: #BeEdition
	instanceVariableNames: '
		myOrglRoot {OrglRoot}
		myWorks {MuSet of: BeWork}
		myOwnProp {BertProp}
		myProp {BertProp}
		myDetectors {(PrimSet NOCOPY of: FeFillRangeDetector)
	| NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(BeEdition getOrMakeCxxClassDescription)
	friends:
'friend class Matcher;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeEdition methodsFor: 'operations'!

{BeEdition} combine: other {BeEdition}
	"An Edition with the contents of both Editions; where they share keys, they must have the same RangeElement."
	
	other isEmpty ifTrue: [^self].
	self isEmpty ifTrue: [^other].
	"Eventually trace coordinates should be delayed."
	[HistoryCrum] USES.
	[TracePosition] USES.
	[Ent] USES.
	CurrentTrace fluidBind: (self hCrum hCut newSuccessorAfter: other hCrum hCut)
		during: [CurrentBertCrum fluidBind: BertCrum make 
		during: [^BeEdition make: (myOrglRoot combine: other orglRoot)]]!

{BeEdition} copy: keys {XnRegion}
	"A new Edition with the domain restricted to the given set of keys."
	
	CurrentTrace fluidBind: self hCrum hCut newSuccessor 
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [^BeEdition make: (myOrglRoot copy: keys)]]!

{BeEdition} replace: other {BeEdition}
	"An Edition with the contents of both Editions; where they share keys, use the contents of the other Edition. Equivalent to
		this->copy (other->domain ()->complement ())->combine (other)"
	
	self thingToDo.  "This should be implemented directly."
	^(self copy: other domain complement) combine: other!

{BeEdition} transformedBy: mapping {Mapping}
	"An Edition with the keys transformed according to the given Mapping. Where the Mapping takes several keys in the domain to a single key in the range, this Edition must have the same RangeElement at all the domain keys."
	
	| resultRoot {OrglRoot} domain {XnRegion} |
	mapping 
		cast: Dsp into: 
			[:dsp | dsp isIdentity ifTrue: [^self].
			CurrentTrace fluidBind: self hCrum hCut newSuccessor during: 
			[CurrentBertCrum fluidBind: BertCrum make during: 
				[^BeEdition make: (myOrglRoot transformedBy: dsp)]]]
		others: ["The rest of the method"].
	CurrentTrace fluidBind: self hCrum hCut newSuccessor during: 
	[CurrentBertCrum fluidBind: BertCrum make during: 
		[domain _ myOrglRoot simpleDomain. 
		resultRoot _ OrglRoot make.CoordinateSpace: mapping rangeSpace.
		mapping simpleMappings stepper forEach:
			[:simple {Mapping} | 
			| common {XnRegion} |
			common _ domain intersect: simple domain.
			common isEmpty ifFalse:
				[ | dsp {Dsp} |
				(dsp _ simple fetchDsp) ~~ NULL 
					ifTrue:
						[resultRoot _ 
							resultRoot combine: ((myOrglRoot copy: common) transformedBy: dsp)]
					ifFalse: [self unimplemented]]].
		^BeEdition make: resultRoot]]!

{BeEdition} with: key {Position} with: value {BeCarrier}
	"A new Edition with a RangeElement at a specified key. The old value, if there is one, is superceded. Equivalent to
		this->replace (theServer ()->makeEditionWith (key, value))"
		
	^self replace: (CurrentGrandMap fluidGet newEditionWith: key with: value)!

{BeEdition} withAll: keys {XnRegion} with: value {BeCarrier}
	"A new Edition with a RangeElement at a specified set of keys. The old values, if there are any, are superceded. Equivalent to
		this->replace (theServer ()->makeEditionWithAll (keys, value))"
		
	^self replace: (CurrentGrandMap fluidGet newEditionWithAll: keys with: value)!

{BeEdition} without: key {Position}
	"A new Edition without any RangeElement at a specified key. The old value, if there is one, is removed. Equivalent to
		this->copy (key->asRegion ()->complement ())"
		
	^self copy: key asRegion complement!

{BeEdition} withoutAll: keys {XnRegion}
	"A new Edition without any RangeElements at the specified keys. The old values, if there are any, are removed. Equivalent to
		this->copy (keys->complement ())"
		
	^self copy: keys complement! !

!BeEdition methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	"The space from which the keys of this Edition are taken. Equivalent to
		this->domain ()->coordinateSpace ()"
		
	^myOrglRoot coordinateSpace!

{IntegerVar} count
	"The number of keys in this Edition. Blasts if infinite. Equivalent to
		this->domain ()->count ()"
	
	^myOrglRoot count!

{XnRegion} domain
	"All the keys in this Edition. May be infinite, or empty."
	
	^myOrglRoot domain!

{FeRangeElement | NULL} fetch: key {Position}
	"Create a front end representation for what is at the given key."
	
	^myOrglRoot fetch: key with: self!

{FeRangeElement} get: key {Position}
	"The value at the given key, or blast if there is no such key (i.e. if !! this->domain ()->hasMember (key))."
	
	| result {FeRangeElement | NULL} |
	result _ self fetch: key.
	result == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^result!

{BooleanVar} includesKey: key {Position}
	"Whether the given key is in the Edition. Equivalent to
		this->domain ()->hasMember (key)"
		
	^(myOrglRoot fetch: key with: self) ~~ NULL!

{BooleanVar} isEmpty
	"Whether there are any keys in this Edition. Equivalent to
		this->domain ()->isEmpty ()"
	
	^myOrglRoot isEmpty!

{BooleanVar} isFinite
	"Whether there is a finite number of keys in this Edition. Equivalent to
		this->domain ()->isFinite ()"
	
	^myOrglRoot simpleDomain isFinite or: [myOrglRoot domain isFinite]!

{BooleanVar} isPurgeable
	^super isPurgeable and: [myDetectors == NULL]!

{FeRangeElement} makeFe: label {BeLabel | NULL}

	^FeEdition on: self with: (FeLabel on: label)!

{IDRegion} rangeOwners: positions {XnRegion default: NULL} 
	"The owners of all the RangeElements in the given Region, or in the entire 
	Edition if no Region is specified."

	^(myOrglRoot rangeOwners: positions) cast: IDRegion!

{(Stepper of: Bundle) CLIENT} retrieve: region {XnRegion default: NULL}
	with: order {OrderSpec default: NULL}
	with: flags {Int32 default: Int32Zero}
	"Essential.  This is the fundamental retrieval operation.  Return a stepper of bundles.  Each bundle is an association between a region in the domain and the range elements associated with that region.  Where the region is associated with data, for instance, the bundle contains a PrimArray of the data elements.
	If no Region is given, then reads out the whole thing."
	
	| theRegion {XnRegion} theOrder {OrderSpec} result {Accumulator} |
	self thingToDo.  "The above comment is horribly insufficient."
	self thingToDo.  "This desperately needs to splay the region."
	region == NULL
		ifTrue: [theRegion _ myOrglRoot simpleDomain]
		ifFalse: [theRegion _ region].
	theRegion isEmpty ifTrue: [^Stepper emptyStepper].
	order == NULL
		ifTrue: [theOrder := theRegion coordinateSpace getAscending]
		ifFalse: [theOrder := order].
	"generate everything at once to avoid problems with the data structures changing as the client steps"
	result := Accumulator ptrArray.
	(myOrglRoot bundleStepper: theRegion with: theOrder)
		forEach: [:bundle {Heaper} | result step: bundle].
	^TableStepper ascending: (result value cast: PtrArray)!

{FeRangeElement} theOne
	"If this Edition has a single key, then the value at that key; if not, blasts. Equivalent to
		this->get (this->domain ()->theOne ())"
	
	^self get: self domain theOne!

{CrossRegion} visibleEndorsements
	"All of the endorsements on this Edition and all Works which the CurrentKeyMaster can read."
	
	| result {XnRegion} |
	result := myOwnProp endorsements.
	myWorks stepper forEach: [ :work {BeWork} |
		(work canBeReadBy: CurrentKeyMaster fluidGet) ifTrue:
			[result := result unionWith: work endorsements]].
	^result cast: CrossRegion! !

!BeEdition methodsFor: 'props'!

{void} endorse: endorsements {CrossRegion}
	"Adds to the endorsements on this Edition. The set of endorsements must be a finite number of (club ID, token ID) pairs."
	
	endorsements isEmpty
		ifTrue: [^VOID].
	DiskManager consistent: 8 with:
		[self 
			propChange: PropChange endorsementsChange 
			with: (BertProp endorsementsProp: (endorsements unionWith: myProp endorsements))]!

{CrossRegion} endorsements
	"All of the endorsements on this Edition."
	
	^myOwnProp endorsements cast: CrossRegion!

{BertProp} prop

	^myProp!

{void} propChange: change {PropChange} with: nw {Prop} 
	
	| old {Prop} |
	old _ myOwnProp.
	(change areEqualProps: old with: nw) not
		ifTrue: 
			[DiskManager consistent: 6 with:
				[myOwnProp _ (change changed: old with: nw) cast: BertProp.
				self diskUpdate.
				self propChanged: change with: old with: nw]]!

{void} propChanged: change {PropChange}
	with: old {Prop}
	with: nw {Prop}
	with: oldFinder {PropFinder default: NULL}
	"update props"
	
	| newProp {Prop} |
	
	"Attempt to apply the change directly to the current set of properties.
	 If that removes some property
	 			look at all the berts to see if we get it from somewhere else.  (BIG and not currently log.)
	 If the new properties are different than the old ones we must change, so
	 		remember the current props
	 		In a consistent block
	 			change the props on the stamp
	 			change leaf of bert canopy and create an AgendaItem to propagate the chage through bert canopy
	 			fetch a finder to look for recorders rung by this change in props
	 			See if permissions decrease:
	 				If so, recorders can't be rung.  Don't bother with sensor canopy, just schedule bert canopy propagation.
	 				If not
	 					make an AgendaItem to check for recorders in the sensor canopy
	 					make and schedule a Sequencer to do the bert then the sensor canopy AgendaItems."
	
	newProp _ change changed: myProp with: myOwnProp.
	newProp _ change with: newProp with: nw.
	(change areEqualProps: newProp with: (change with: newProp with: old)) not
		ifTrue: [myWorks stepper forEach: [:work {BeWork} | 
				self thingToDo.  "Make it log."
				newProp _ change with: newProp with: work localProp]].
	(change areEqualProps: myProp with: newProp)
		ifFalse: 
			[| before {BertProp} finder {PropFinder} 
			   changer {AgendaItem} checker {AgendaItem} |
			before _ myProp.
			DiskManager consistent: 9 with:
				[myProp _ (newProp cast: BertProp).
				self diskUpdate.
				changer _ myOrglRoot propChanger: change.
				finder _ change fetchFinder: before with: myProp with: self with: oldFinder.
				finder == NULL
					ifTrue: [changer schedule]
					ifFalse:
						[checker _ SouthRecorderChecker make: myOrglRoot 
								with: finder 
								with: (myOrglRoot sensorCrum fetchParent cast: SensorCrum).
						oldFinder == NULL ifTrue:
							[(Sequencer make: changer with: checker) schedule]
						ifFalse:
							[ | workChecker {AgendaItem} |
							workChecker := NorthRecorderChecker make: self with: finder.
							"the sequence of workChecker vs checker doesn't matter"
							(Sequencer make: changer
								with: (Sequencer make: workChecker with: checker)) schedule]]]]!

{void} retract: endorsements {CrossRegion}
	"Removes endorsements from this Edition. Ignores all endorsements which you could have removed, but which don't happen to be there right now."
	
	endorsements isEmpty
		ifTrue: [^VOID].
	DiskManager consistent: 4 with:
		[self 
			propChange: PropChange endorsementsChange 
			with: (BertProp endorsementsProp: (myOwnProp endorsements minus: endorsements))]!

{CrossRegion} totalEndorsements
	"All of the endorsements on this Edition and all Works directly on it"
	
	| result {XnRegion} |
	result := myOwnProp endorsements.
	myWorks stepper forEach: [ :work {BeWork} |
		result := result unionWith: work endorsements].
	^result cast: CrossRegion! !

!BeEdition methodsFor: 'becoming'!

{void} addDetector: detect {FeFillRangeDetector}
	"Add a detector which will be triggered with a FeEdition when a PlaceHolder becomes a non-PlaceHolder"
	
	myDetectors == NULL ifTrue:
		[myDetectors := PrimSet weak: 7 with: (BeEditionDetectorExecutor make: self).
		self propChange: PropChange detectorWaitingChange
			with: BertProp detectorWaitingProp].
	myDetectors introduce: detect.
	myOrglRoot triggerDetector: detect.!

{ID} ownerAt: key {Position}
	"Return the owner for the given position in the receiver."
		
	^myOrglRoot ownerAt: key!

{void} removeDetector: detect {FeFillRangeDetector}
	"Remove a previously added detector"
	
	(Heaper isDestructed: myDetectors) ifTrue:
		[^VOID].
	myDetectors == NULL ifTrue:
		[Heaper BLAST: #NeverAddedDetector].
	Ravi knownBug. "if we're in GC, we may be dealing with a partially unconstructed web of objects"
	myDetectors remove: detect.
	myDetectors isEmpty ifTrue:
		[myDetectors := NULL.
		self propChange: PropChange detectorWaitingChange
			with: BertProp make]!

{void} removeLastDetector
	"Notify the edition that there are no remaining detectors on it."
	
	myDetectors := NULL.
	self propChange: PropChange detectorWaitingChange with: BertProp make!

{void} ringDetectors: newIdentities {FeEdition}
	"Ring all my detectors with the given Edition as an argument"
	
	myDetectors ~~ NULL ifTrue:
		[myDetectors stepper forEach: [ :det {FeFillRangeDetector} |
			det rangeFilled: newIdentities]]!

{BeEdition} setRangeOwners: newOwner {ID} with: region {XnRegion}
	"Changes the owner of all RangeElements; requires the authority of the current owner.
	Returns the subset of this Edition whose owners did not get changed because of lack of authority."
	
	self knownBug.  "Must be a loop in ServerLoop."
	self thingToDo. "propagate region down through the algorithm?"
	CurrentTrace fluidBind: self hCrum hCut newSuccessor 
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [^BeEdition make: ((myOrglRoot copy: region) setAllOwners: newOwner)]]!

{Pair of: BeEdition} tryAllBecome: newIdentities {BeEdition}
	"Change the identities of the RangeElements of this Edition to those at the same key in the other Edition. The left piece of the result contains those object which are know to not be able to become, because of
		- lack of ownership authority
		- different contents
		- incompatible types
		- no corresponding new identity
	The right piece of the result is NULL if there is nothing more that might be done, or else the remainder of the receiver on which we might be able to proceed. This material might fail at a later time because of any of the reasons above; or it might succeed , even though it failed this time because of
		- synchronization problem
		- just didn't feel like it
	This is always required to make progress if it can, although it isn't required to make all the progress that it might. Returns right=NULL when it can't make further progress."

	
	Dean shouldImplement.
	^NULL "fodder"! !

!BeEdition methodsFor: 'labelling'!

{XnRegion} keysLabelled: label {BeLabel}
	"The keys in this Edition at which there are Editions with the given label."
	
	^myOrglRoot keysLabelled: label!

{BeEdition} rebind: key {Position} with: edition {BeEdition}
	"Replace the Edition at the given key, leaving the Label the same. Equivalent to
		this->store (key, edition->labelled (CAST(FeEdition,this->get (key))->label ()))"
	self mightNotImplement.
	^NULL "fodder"! !

!BeEdition methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartE: rcvr {Rcvr unused}
	myDetectors _ NULL! !

!BeEdition methodsFor: 'protected:'!

{OrglRoot} orglRoot
	^myOrglRoot! !

!BeEdition methodsFor: 'be accessing'!

{void} addOParent: oparent {Loaf} 
	"add oparent to the set of upward pointers.  Editions may
	 also have to propagate BertCrum change downward."

	| bCrum {BertCrum} newBCrum {BertCrum} |
	[HistoryCrum] USES.
	bCrum _ self hCrum bertCrum.
	super addOParent: oparent.
	newBCrum _ self hCrum bertCrum.
	(bCrum isLE: newBCrum) 
		ifFalse: [myOrglRoot updateBCrumTo: newBCrum]!

{BooleanVar} anyPasses: finder {PropFinder}

	| next {PropFinder} |
	next := finder findPast: self.
	^next isFull or: [super anyPasses: next]!

{void} checkRecorders: finder {PropFinder} 
	with: scrum {SensorCrum | NULL} 
	
	| newFinder {PropFinder} |
	"Get a new finder which remembers to check if recorders will newly find me"
	newFinder _ finder findPast: self.
	"replace endorsements with those in the prop"
	newFinder isEmpty
		ifFalse: 
			["keep looking down, with my stamp as the new reference point"
			self thingToDo.
			"Use the new finder to check all recorders beneath me, checking whether they record all stamps from me all the way up to the stamp passed in as an argument"
			Ravi knownBug. "using scrum's parent records things twice"
			(SouthRecorderChecker
				make: myOrglRoot
				with: newFinder
				with: (scrum fetchParent cast: SensorCrum)) schedule]!

{ImmuSet of: BeWork} currentWorks
	"The Works currently on this Edition"
	
	^myWorks asImmuSet!

{BeRangeElement} getOrMakeBe: key {Position}
	"An actual, non-virtual FE range element at that key. Used by become operation to get something to pass into BeRangeElement::become ()"
	
	^myOrglRoot getBe: key!

{void} introduceWork: work {BeWork} 
	"A Work has been newly revised to point at me."

	DiskManager consistent: 
		[myWorks introduce: work.
		self diskUpdate.
		self propChanged: PropChange bertPropChange
			with: BertProp make
			with: work prop
			with: (PropChange bertPropChange
				fetchFinder: BertProp make
				with: work prop
				with: work
				with: NULL)].
	(myWorks count >= 100 and: [(myWorks isKindOf: GrandHashSet) not]) ifTrue: 
		[| newWorks {MuSet} |
		newWorks _ GrandHashSet make.
		myWorks stepper forEach: [:b {BeWork} | newWorks store: b].
		DiskManager consistent: 1 with:
			[myWorks _ newWorks.
			self diskUpdate]].!

{void} removeWork: work {BeWork} 
	"The Work is no longer onto this Edition.  Remove the backpointer."

	DiskManager consistent:
		[myWorks remove: work.
		self diskUpdate.
		self propChanged: PropChange bertPropChange
			with: work prop
			with: BertProp make]!

{BooleanVar} updateBCrumTo: newBCrum {BertCrum} 
	"My bertCrum must not be leafward of newBCrum. 
	Thus it must be LE to newCrum. Otherwise correct it and recur."

	(super updateBCrumTo: newBCrum) ifTrue: 
		[myOrglRoot updateBCrumTo: newBCrum.
		^true].
	^false! !

!BeEdition methodsFor: 'comparing'!

{XnRegion} keysOf: value {FeRangeElement}
	"All of the keys in this Edition at which the given RangeElement can be found. Equivalent to
		this->sharedRegion (theServer ()->makeEditionWith (some position, value))"
	
	[BeGrandMap] USES.
	^self sharedRegion: (CurrentGrandMap fluidGet
			newEditionWith: IntegerPos zero with: value carrier)!

{Mapping} mapSharedTo: other {BeEdition}
	"A Mapping from each of the keys in this Edition to all of the keys in the other Edition which have the same RangeElement."
	
	^myOrglRoot mapSharedTo: other hCrum hCut!

{BeEdition} notSharedWith: other {BeEdition}
	with: flags {Int32 default: Int32Zero}
	"The subset of this Edition whose RangeElements are not in the other Edition. Equivalent to
		this->copy (this->sharedRegion (other, flags)->complement ())"	
	
	^self copy: (self sharedRegion: other with: flags) complement!

{XnRegion} sharedRegion: other {BeEdition}
	with: flags {Int32 default: Int32Zero}
	"The subset of the keys of this Edition which  have RangeElements that are in the other Edition. If both flags are false, then equivalent to
		this->mapSharedTo (other)->domain ()
	If nestThis, then returns not only keys of RangeElements which are in the other, but also keys of Editions which lead to RangeElements which are in the other.
	If nestOther, then looks not only for RangeElements which are values of the other Edition, but also those which are values of sub-Editions of the other Edition. (This option will probably not be supported in version 1.0)"
	
	flags ~= Int32Zero ifTrue: [self unimplemented].
	^myOrglRoot sharedRegion: other hCrum hCut!

{BeEdition} sharedWith: other {BeEdition}
	with: flags {Int32 default: Int32Zero}
	"The subset of this Edition whose RangeElements are in the other Edition. If the same RangeElement is in this Edition at several different keys, all keys will be in the result (provided the RangeElement is also in the other Edition). Equivalent to
		this->copy (this->sharedRegion (other, flags))"
	
	^self copy: (self sharedRegion: other with: flags)!

{BeEdition} works: permissions {IDRegion}
	with: endorsementsFilter {Filter}
	with: flags {Int32}

	| result {Accumulator} iDSpace {IDSpace} region {XnRegion} |
	flags = (FeEdition LOCAL.U.PRESENT.U.ONLY bitOr: FeEdition DIRECT.U.CONTAINERS.U.ONLY) ifFalse:
		[^super works: permissions with: endorsementsFilter with: flags].
	result := Accumulator ptrArray.
	myWorks stepper forEach: [ :work {BeWork} |
		(endorsementsFilter match: work endorsements) ifTrue:
			[result step: (work makeFe: NULL)]].
	iDSpace := CurrentGrandMap fluidGet newIDSpace.
	region := (iDSpace newIDs: ((result value cast: PtrArray) count)).
	^(CurrentGrandMap fluidGet newPlaceHolders: region complement)
		combine:(CurrentGrandMap fluidGet
			newValueEdition: (result value cast: PtrArray)
			with: region
			with: iDSpace ascending)! !

!BeEdition methodsFor: 'creation'!

create: root {OrglRoot}
	super create: root sensorCrum.
	
	Dean knownBug. "this should not have the same SensorCrum as my OrglRoot"
	myOrglRoot _ root.
	myWorks _ MuSet make.  "This should maybe just start out NULL."
	myOwnProp _ myProp _ BertProp make.
	myDetectors _ NULL.
	DiskManager consistent: 5 with:
		[myOrglRoot introduceEdition: self.
		self newShepherd]!

{void} dismantle
	DiskManager consistent: "2 with: (need to recalculate for adding propChange)"
		[self propChange: PropChange bertPropChange with: BertProp make.
		(Heaper isConstructed: myOrglRoot) 
			ifTrue: [myOrglRoot removeEdition: self].
		myOrglRoot _ NULL.
		super dismantle]! !

!BeEdition methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myOrglRoot << ')'! !

!BeEdition methodsFor: 'transclusions'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	"Attach the TrailBlazer to this Edition, and return the region of partiality it is attached to"
	
	^myOrglRoot attachTrailBlazer: blazer!

{void} fossilRelease: oldGrabber {RecorderFossil}

	MarkM thingToDo.
	"myGrabbersFossil == NULL ifTrue:
		[Heaper BLAST: #NotGrabbed]
	ifFalse: [myGrabbersFossil ~~ oldGrabber ifTrue:
		[Heaper BLAST: #WhoIsReleasingMe]
	ifFalse:
		[DiskManager consistent: 2 with:
			[myGrabbersFossil := NULL.
			oldGrabber extinguish: self.
			self diskUpdate]]]"!

{TrailBlazer} getOrMakeTrailBlazer
	"Get or make a TrailBlazer for recording results into this Edition. Blast if there is already more than one"
	
	| result {TrailBlazer} |
	result := myOrglRoot fetchTrailBlazer.
	result == NULL
		ifTrue: [^TrailBlazer make: self].
	myOrglRoot checkTrailBlazer: result.
	^result!

{BeEdition} rangeTranscluders:  region {XnRegion | NULL}
	with: directFilter {Filter}
	with: indirectFilter {Filter}
	with: flags {Int32}
	with: otherTrail {BeEdition | NULL}
	"See FeEdition"
	
	| fossil {RecorderFossil} 
	  result {BeEdition} |
	
	"Reject all the unimplemented cases.
	
	if a trail isn't given
		make a new one
	else
		use it as the result.
		
	Make a fossilized recorder 
		snapshotting the current login authority
		filtered by the endorsementsFilter
		for recording into the trail
	Set the transclusions request in motion
	Return the trail"  
	  
	(flags bitAnd: (FeEdition DIRECT.U.CONTAINERS.U.ONLY
			bitOr: FeEdition LOCAL.U.PRESENT.U.ONLY) bitInvert) ~~ Int32Zero
		ifTrue: [self unimplemented].
	
	otherTrail == NULL 
		ifTrue: [result := CurrentGrandMap fluidGet 
				newPlaceHolders: CurrentGrandMap fluidGet newIDSpace fullRegion]
		ifFalse: [result := otherTrail].
		
	fossil := RecorderFossil 
		transcluders: (flags bitAnd: FeEdition DIRECT.U.CONTAINERS.U.ONLY) ~~ Int32Zero
		with: CurrentKeyMaster fluidFetch loginAuthority 
		with: directFilter
		with: indirectFilter
		with: result getOrMakeTrailBlazer.
	
	(flags bitAnd: FeEdition LOCAL.U.PRESENT.U.ONLY) ~~ Int32Zero
		ifTrue: [self scheduleImmediateBackfollow: fossil with: region]
		ifFalse: [(flags bitAnd: FeEdition DIRECT.U.CONTAINERS.U.ONLY) ~~ Int32Zero
				ifTrue: [self unimplemented].
			self scheduleDelayedBackfollow: fossil with: region].
	^result!

{BeEdition} rangeWorks: region {XnRegion | NULL}
	with: filter {Filter}
	with: flags {Int32}
	with: otherTrail {BeEdition | NULL}
	"See FeEdition"
	
	| fossil {RecorderFossil} result {BeEdition} |
	
	"Reject all the unimplemented cases.
	
	if a trail isn't given
		make a new one
	else
		use it as the result.
		
	Make a fossilized recorder 
		snapshotting the current login authority
		filtered by the endorsementsFilter
		for recording into the trail
	Set the transclusions request in motion
	Return the trail"  
	  
	(flags bitAnd: (FeEdition DIRECT.U.CONTAINERS.U.ONLY
			bitOr: FeEdition LOCAL.U.PRESENT.U.ONLY) bitInvert) ~~ Int32Zero
		ifTrue: [self unimplemented].
	
	otherTrail == NULL 
		ifTrue: [result := CurrentGrandMap fluidGet 
				newPlaceHolders: CurrentGrandMap fluidGet newIDSpace fullRegion]
		ifFalse: [result := otherTrail].
		
	fossil := RecorderFossil 
		works: (flags bitAnd: FeEdition DIRECT.U.CONTAINERS.U.ONLY) ~~ Int32Zero
		with: CurrentKeyMaster fluidGet loginAuthority 
		with: filter
		with: result getOrMakeTrailBlazer.
	
	(flags bitAnd: FeEdition LOCAL.U.PRESENT.U.ONLY) ~~ Int32Zero
		ifTrue: [self scheduleImmediateBackfollow: fossil with: region]
		ifFalse: [(flags bitAnd: FeEdition DIRECT.U.CONTAINERS.U.ONLY) ~~ Int32Zero
				ifTrue: [self unimplemented].
			self scheduleDelayedBackfollow: fossil with: region].
	^result!

{void} scheduleDelayedBackfollow: fossil {RecorderFossil} with: region {XnRegion | NULL}

	"Walk down orgl's O-tree (onto range elements of interest) planting pointers to a Fossil of BackfollowRecorder in the sensor canopy and collecting agenda items to propagate their endorsement and permission filtering info rootward in the sensor canopy.
	Create and schedule a structure of AgendaItems to:
		- First:  Do the filtering info propagation.
		- Second: Find and record any currently matching stamps.
	
	This is done in this order so collection of the future part of recorder information is completed before the present part is extracted, keeping significant information from falling through the crack."
	  	
	| rAgents {Agenda} matcher {AgendaItem} oroot {OrglRoot} |
	  
	"Create an empty Agenda.
	Do the walk and collect PropChangers in the new Agenda.
	Reanimate the Fossil long enough to
		make a Matcher AgendaItem
			from the filtering information extracted from the Fossil
	Make and schedule a Sequencer that first runs the Agenda that propagates filtering info, then runs the Matcher."

	fossil isExtinct ifTrue:
		[^VOID].
	rAgents _ Agenda make.
	region == NULL ifTrue:
		[oroot := myOrglRoot]
	ifFalse:
		[CurrentTrace fluidBind: self hCrum hCut newSuccessor 
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [oroot := myOrglRoot copy: region]]].
	oroot storeRecordingAgents: fossil with: rAgents.
	fossil reanimate: [:recorder {ResultRecorder} |
		matcher _ Matcher make: oroot
			with: recorder bertPropFinder
			with: fossil].
	(Sequencer make: rAgents with: matcher) schedule!

{void} scheduleImmediateBackfollow: fossil {RecorderFossil} with: region {XnRegion | NULL}

	"Find and record any currently matching Editions."

	| oroot {OrglRoot} |
	 
	MarkM thingToDo. "When we are actually leaving AgendaItems on the queue, make sure that all necessary canopy propagation is done before the Matcher excutes"
	
	region == NULL ifTrue:
		[oroot := myOrglRoot]
	ifFalse:
		[CurrentTrace fluidBind: self hCrum hCut newSuccessor 
		during: [CurrentBertCrum fluidBind: BertCrum make
		during: [oroot := myOrglRoot copy: region]]].

	fossil reanimate: [:recorder {ResultRecorder} |
		(Matcher make: oroot
			with: recorder bertPropFinder
			with: fossil) schedule]! !

!BeEdition methodsFor: 'smalltalk: defaults'!

{void} propChanged: change {PropChange} with: old {Prop} with: nw {Prop} 

	self propChanged: change with: old with: nw with: NULL!

{XnRegion} sharedRegion: other {BeEdition}

	^self sharedRegion: other with: 0! !

!BeEdition methodsFor: 'smalltalk: passe'!

{MuSet of: FeFillRangeDetector} detectors

	self passe!

{BeRangeElement | NULL} fetchOrMakeBeRangeElement: key {Position}
	"An actual, non-virtual FE range element at that key. Used by become operation to get something to pass into BeRangeElement::become ()"
	self passe "no implementation, senders, or polymorphs - /ravi/10/7/92/"!

{BeEdition} parcelAt: key {Position}

	self passe!

{BeEdition} parcels

	self passe!

{BeEdition PROXY} reorganize: oldRegion {XnRegion | NULL}
	with: oldOrder {OrderSpec | NULL}
	with: newRegion {XnRegion | NULL}
	with: newOrder {OrderSpec | NULL}
	"Rearrange the keys of this Edition to lie in the given region, with the given ordering. Equivalent to server->makeEdition (this->asArray (oldRegion, oldOrder), newRegion, newOrder, NULL), except that it doesn't require everything to be in the same zone (and is of course more efficient)."
	self unimplemented!

{void} scheduleDelayedBackfollow: fossil {RecorderFossil}

	self passe!

{void} scheduleImmediateBackfollow: fossil {RecorderFossil}

	self passe!

{BeEdition} setAllOwners: newOwner {ID} 

	self passe!

{BeEdition} setAllOwners: newOwner {ID} with: region {XnRegion}

	self passe "setRangeOwners"!

{void} unendorse: endorsements {CrossRegion}

	self passe "retract"!

{void} wait: sensor {XnSensor}
	
	self passe! !

!BeEdition methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myOrglRoot _ receiver receiveHeaper.
	myWorks _ receiver receiveHeaper.
	myOwnProp _ receiver receiveHeaper.
	myProp _ receiver receiveHeaper.
	self restartE: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myOrglRoot.
	xmtr sendHeaper: myWorks.
	xmtr sendHeaper: myOwnProp.
	xmtr sendHeaper: myProp.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeEdition class
	instanceVariableNames: ''!

(BeEdition getOrMakeCxxClassDescription)
	friends:
'friend class Matcher;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeEdition class methodsFor: 'creation'!

make: oroot {OrglRoot}
	DiskManager consistent: 5 with:
		[^self create: oroot]! !