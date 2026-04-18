'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:03 pm'!

OrglRoot subclass: #ActualOrglRoot
	instanceVariableNames: '
		myO {Loaf}
		myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(ActualOrglRoot getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #CONCRETE; yourself)!

!ActualOrglRoot methodsFor: 'backfollow'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	^myO attachTrailBlazer: blazer!

{void} checkRecorders: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	
	myO checkRecorders: finder with: scrum!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	myO checkTrailBlazer: blazer!

{void} delayedFindMatching: finder {PropFinder}
	with: fossil {RecorderFossil}
	with: recorder {ResultRecorder}
	
	| hCrumCache {HashSetCache of: HistoryCrum} |	
	
	"Cache for optimization: Frequently, in going northwards on the h-tree, one will encounter an h-crum already encountered during this very delayedFindMatching: operation.  In this case, the cache helps us avoid *much* redundant work.  We can get away with a bounded size cache because redundant work is still correct."
	hCrumCache _ HashSetCache make: 100.
	
	"Tell my O crum to do its flavor of the work.  It will tell its children recursively."
	myO delayedStoreMatching: finder with: fossil with: recorder with: hCrumCache.
	
	hCrumCache destroy.!

{TrailBlazer | NULL} fetchTrailBlazer

	^myO fetchTrailBlazer!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda}
	
	myO storeRecordingAgents: recorder with: agenda!

{void} triggerDetector: detect {FeFillRangeDetector}

	myO triggerDetector: detect!

{BooleanVar} updateBCrumTo: newBCrum {BertCrum} 
	"My bertCrum must not be leafward of newBCrum. 
	Thus it must be LE to newCrum. Otherwise correct it and recur."

	(super updateBCrumTo: newBCrum)
		ifTrue: 
			[myO updateBCrumTo: newBCrum.
			^true].
	^false! !

!ActualOrglRoot methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	"the kind of domain elements allowed"

	^myRegion coordinateSpace!

{IntegerVar} count 
	^myO count!

{XnRegion} domain
	^myO domain!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition}
	"get an individual element"

	^myO fetch: key with: edition with: key!

{Loaf} fullcrum
	^myO!

{BeRangeElement} getBe: key {Position}
	"Get or Make the BeRangeElement at the location."

	"Separate the position from the rest of the oplane with copy.  Then instantiate it."
	
	CurrentTrace fluidBind: self hCrum hCut
		during: [CurrentBertCrum fluidBind: self hCrum bertCrum
		during: [^((self copy: key asRegion) cast: ActualOrglRoot) fullcrum getBe: key]]!

{BooleanVar} isEmpty
	"ActualOrglRoots believe they have stuff beneath them."
	
	^false!

{XnRegion} keysLabelled: label {BeLabel}
	"Just search for now."

	^myO keysLabelled: label!

{Mapping} mapSharedTo: trace {TracePosition}
	"return a mapping from my data to corresponding stuff in the given trace"
	^myO compare: trace with: myRegion!

{ID} ownerAt: key {Position}
	"Return the owner for the given position in the receiver."
	
	| loaf {OExpandingLoaf} |
	loaf _ myO fetchBottomAt: key.
	loaf == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^loaf owner!

{XnRegion} rangeOwners: positions {XnRegion | NULL} 
	
	^myO rangeOwners: positions!

{OrglRoot} setAllOwners: owner {ID}
	"Recur assigning owners.  Return the portion of the receiver that
	 couldn't be assigned."
		
	^myO setAllOwners: owner!

{XnRegion} sharedRegion: trace {TracePosition}
	"Return a region for all the stuff in this orgl that can backfollow to trace."

	^myO sharedRegion: trace with: myRegion!

{XnRegion} simpleDomain
	^myRegion!

{PrimSpec} specAt: key {Position}
	"Return the owner for the given position in the receiver."
	
	| loaf {OExpandingLoaf} |
	loaf _ myO fetchBottomAt: key.
	loaf == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^loaf spec!

{Pair of: OrglRoot} tryAllBecome: other {OrglRoot}
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
	^NULL "fodder"!

{XnRegion} usedDomain
	^myO usedDomain! !

!ActualOrglRoot methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec}
	"Return a stepper of bundles according to the order."
	
	^myO bundleStepper: region with: order with: region coordinateSpace identityDsp!

{OrglRoot} combine: another {OrglRoot}
	| him {ActualOrglRoot} result {OrglRoot} |

	another isEmpty ifTrue: [^self].
	him _ another cast: ActualOrglRoot.
	result _ self fetchEasyCombine: him.
	result ~~ NULL ifTrue: [^result].
	result _ him fetchEasyCombine: self.
	result ~~ NULL ifTrue: [^result].
		
	"both Ins are non-empty & both Outs are empty"
	^myO combine: him with: myRegion with: self coordinateSpace identityDsp!

{OrglRoot} copy: region {XnRegion} 
	"Copy out each simple region and then combine them."

	region isSimple
		ifTrue: [^self copySimple: region]
		ifFalse: 
			[| result {OrglRoot} |
			result _ OrglRoot make: self coordinateSpace.
			(region disjointSimpleRegions) forEach: [:simple {XnRegion} | 
				result _ result combine: (self copySimple: simple)].
			^result]!

{OrglRoot} copyDistinction: region {XnRegion} 
	"region must be a valid thing to store as a split."

	| cnt {UInt8} |
	cnt _ self splay: region.
	Int0 == cnt ifTrue: [^OrglRoot make: self coordinateSpace]
	ifFalse: [2 == cnt ifTrue: [^self]
	ifFalse: [^ActualOrglRoot make: (myO cast: InnerLoaf) inPart with: (myRegion intersect: region)]]!

{OrglRoot} copySimple: simpleRegion {XnRegion} 
	"simpleRegion must be simple!!  Copy out each distinction."

	| result {OrglRoot} |
	[ImmuSet] USES.
	result _ self.
	simpleRegion isSimple assert: 'This must be a simple region.'.
	simpleRegion distinctions stepper forEach: 
		[:distinct {XnRegion} | 
		result isEmpty ifTrue: [^result].
		result _ (result cast: ActualOrglRoot) copyDistinction: distinct].
	^result!

{void} fill: keys {XnRegion} with: toArrange {Arrangement} with: toArray {PrimDataArray} with: dsp {Dsp} with: edition {BeEdition} 
	
	myO fill: keys with: toArrange with: toArray with: dsp with: edition!

{ActualOrglRoot} makeNew: newSplit {XnRegion} with: newIn {ActualOrglRoot} with: newOut {ActualOrglRoot}
	^ActualOrglRoot 
			make: (InnerLoaf make: newSplit with: newIn fullcrum with: newOut fullcrum) 
			with: (newIn simpleDomain simpleUnion: newOut simpleDomain)!

{OrglRoot} transformedBy: externalDsp {Dsp}
	"Return a copy with externalDsp added to the receiver's dsp."

	externalDsp isIdentity ifTrue: [^self].
	^ActualOrglRoot make: (myO transformedBy: externalDsp) with: (externalDsp ofAll: myRegion)!

{OrglRoot} unTransformedBy: externalDsp {Dsp}
	"Return a copy with externalDsp removed from the receiver's dsp."

	externalDsp isIdentity ifTrue: [^self].
	^ActualOrglRoot 
		make: (myO unTransformedBy: externalDsp) 
		with: (externalDsp inverseOfAll: myRegion)! !

!ActualOrglRoot methodsFor: 'create'!

create: fullcrum {Loaf} with: region {XnRegion} 
	super create: fullcrum sensorCrum.
	myO _ fullcrum.
	myRegion _ region.
	myO addOParent: self.
	self newShepherd! !

!ActualOrglRoot methodsFor: 'smalltalk:'!

crums
	^Array with: myO!

displayString
	^self getCategory name , (myO displayString)!

inspect
	Sensor leftShiftDown
		ifTrue: [self basicInspect]
		ifFalse: [EntView openOn: (TreeBarnacle new
					buildOn: self
					gettingChildren: [:crum | crum crums]
					gettingImage: [:crum | DisplayText text: crum displayString asText textStyle: (TextStyle styleNamed: #small)]
					at: 0 @ 0
					vertical: Sensor ctrlDown
					separation: 5 @ 10)]!

inspectTraces
	Sensor leftShiftDown
		ifTrue: [self basicInspect]
		ifFalse: [EntView openOn: (TreeBarnacle new
					buildOn: myO
					gettingChildren: [:crum | crum crums]
					gettingImage: [:crum | DisplayText text: crum hCrum hCut displayString asText textStyle: (TextStyle styleNamed: #small)]
					at: 0 @ 0
					vertical: true
					separation: 20 @ 20)]!

{BooleanVar} testChild: child {SplayEntLoaf}
	"Return true if child is a child.  Used for debugging."
	
	^myO == child!

{BooleanVar} testHChild: child {HistoryCrum}
	"Return true if child is a child.  Used for debugging."
	
	^ myO hCrum == child! !

!ActualOrglRoot methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' << myRegion << ', ' << myO << ')'! !

!ActualOrglRoot methodsFor: 'private:'!

{ActualOrglRoot | NULL} fetchEasyCombine: another {ActualOrglRoot} 
	another simpleDomain distinctions stepper
		forEach: 
			[:bound {XnRegion} | 
			| myIn {OrglRoot} myOut {OrglRoot} |
			myIn _ self copy: bound.
			myOut _ self copy: bound complement.
			myIn isEmpty ifTrue: 
				[^self makeNew: bound
					with: another
					with: (myOut cast: ActualOrglRoot)].
			myOut isEmpty not ifTrue: 
				[^self makeNew: bound
					with: ((another combine: myIn) cast: ActualOrglRoot)
					with: (myOut cast: ActualOrglRoot)]].
	^NULL!

{UInt8} splay: region {XnRegion}
	"Splay a region into its own subtree as close as possible to the root"
	^myO splay: region with: myRegion! !

!ActualOrglRoot methodsFor: 'protected: delete'!

{void} dismantle
	DiskManager consistent: 4 with:
		[(Heaper isConstructed: myO) ifTrue: [myO removeOParent: self].
		super dismantle]! !

!ActualOrglRoot methodsFor: 'testing'!

{UInt32} contentsHash

	^(super contentsHash
		bitXor: myO hashForEqual)
		bitXor: myRegion hashForEqual! !

!ActualOrglRoot methodsFor: 'smalltalk: passe'!

{void} inform: key {Position} with: value {HRoot}
	
	self passe!

{void} wait: sensor {XnSensor} 
	
	self passe! !

!ActualOrglRoot methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myO _ receiver receiveHeaper.
	myRegion _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myO.
	xmtr sendHeaper: myRegion.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualOrglRoot class
	instanceVariableNames: ''!

(ActualOrglRoot getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #CONCRETE; yourself)!

!ActualOrglRoot class methodsFor: 'creation'!

make: loaf {Loaf} with: region {XnRegion}
	"create a new orgl root"

	region isEmpty not assert: 'Attempt to make an empty ActualOrglRoot'.
	DiskManager consistent: 13 with: 
		[^ActualOrglRoot create: loaf with: region]! !