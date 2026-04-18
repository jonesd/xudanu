'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:12 pm'!

OExpandingLoaf subclass: #OPartialLoaf
	instanceVariableNames: '
		myOwner {ID}
		myTrailBlazer {TrailBlazer | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(OPartialLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #CONCRETE; add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #(MAY.BECOME RegionLoaf ); yourself)!

!OPartialLoaf methodsFor: 'accessing'!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition} with: globalKey {Position}
	"Make a virtual PlaceHolder."

	(self domain hasMember: key) 
		ifTrue: [^FePlaceHolder fake: edition with: globalKey] 
		ifFalse: [^NULL]!

{BeRangeElement} getBe: key {Position}
	"Get or make the BeRangeElement at the location."
	
	"My region had better be just onto the key.
	 become a RegionLoaf onto a new BePlaceHolder"
		
	| element {BeRangeElement}  domain {XnRegion}
	 hcrum {HUpperCrum} hash {UInt32} info {FlockInfo}|
	domain _ key asRegion.
	(self domain isEqual: domain) ifFalse: [Heaper BLAST: #NotInTable].
	hcrum _ self hCrum cast: HUpperCrum.
	hash _ self hashForEqual.
	info _ self fetchInfo.
	DiskManager consistent:
		[self sensorCrum removePointer: self.
		InitialOwner fluidBind: self owner
			during: [[Ent] USES. CurrentTrace fluidBind: self hCrum hCut
			during: [CurrentBertCrum fluidBind: BertCrum make
			during:
				[element _ BePlaceHolder create: myTrailBlazer.
				myTrailBlazer ~~ NULL ifTrue:
					[myTrailBlazer removeReference: self.
					myTrailBlazer := NULL]]]].
		(RegionLoaf new.Become: self)
			create: domain
			with: element 
			with: hcrum
			with: hash 
			with: info].
	^element!

{ID} owner
	"Return the owner of the atoms represented by the receiver."
	
	^myOwner!

{PrimSpec} spec
	"Return the PrimSpec that describes the representation of the data."
	
	self unimplemented.
	^PrimSpec pointer!

{XnRegion} usedDomain
	^self domain coordinateSpace emptyRegion! !

!OPartialLoaf methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec} with: globalDsp {Dsp}
	"Return a stepper of bundles according to the order."
	
	| bundleRegion {XnRegion} |
	bundleRegion _ region intersect: (globalDsp ofAll: self domain).
	bundleRegion isEmpty ifTrue: [^Stepper emptyStepper].
	^Stepper itemStepper: (FePlaceHolderBundle make: bundleRegion)!

{void} fill: keys {XnRegion} with: toArrange {Arrangement} with: toArray {PrimArray} with: dsp {Dsp} with: edition {BeEdition} 
	"Make an FeRangeElement for each position."
	
	(keys intersect: self domain) stepper forEach: 
		[:key {Position} |
		| globalKey {Position} |
		globalKey _ dsp of: key.
		toArray at: (toArrange indexOf: globalKey) DOTasLong
			storeValue: (FePlaceHolder fake: edition with: globalKey)]!

{void} informTo: orgl {OrglRoot unused}
	self unimplemented!

{Boolean} isPartial
	"Partial crums are always partial."

	^true!

{OrglRoot} setAllOwners: owner {ID} 
	"If the CurrentKeyMaster includes the owner of this loaf
		then change the owner and return NULL
		else just return self."
		
	(CurrentKeyMaster fluidGet hasAuthority: myOwner)
		ifTrue:
			[myOwner _ owner.
			^OrglRoot make: self domain coordinateSpace]
		ifFalse: [^ActualOrglRoot make: self with: self domain]! !

!OPartialLoaf methodsFor: 'protected: splay'!

{Int8} actualSoftSplay: region {XnRegion} with: limitRegion {XnRegion unused} 
	"Don't expand me in place.  Just move it closer to the top."
	
	^2!

{Int8} actualSplay: region {XnRegion} with: limitRegion {XnRegion unused} 
	"Expand my partial tree in place. The area in the region must go 
	into the leftCrum of my substitute, or the splay algorithm will fail!!"
	
	| crums {Pair of: SensorCrum} tmp1 {Loaf} tmp2 {Loaf} |
	 
	crums _ self sensorCrum expand.
	DiskManager consistent: 3 with: 
		[tmp1 _ OPartialLoaf
					create: (self domain intersect: region)
					with: (HUpperCrum make: (self hCrum cast: HUpperCrum))
					with: (crums left cast: SensorCrum)
					with: myOwner
					with: myTrailBlazer].
	DiskManager consistent: 3 with: 
		[tmp2 _ OPartialLoaf
					create: (self domain intersect: region complement)
					with: (HUpperCrum make: (self hCrum cast: HUpperCrum))
					with: (crums right cast: SensorCrum)
					with: myOwner
					with: myTrailBlazer].
	myTrailBlazer ~~ NULL ifTrue:
		[DiskManager consistent: 1 with:
			[myTrailBlazer addReference: tmp1.
			myTrailBlazer addReference: tmp2.
			myTrailBlazer removeReference: self]].
	DiskManager consistent: 5 with: 
		[| hcrum {HUpperCrum} 
		  hash {UInt32} 
		  info {FlockInfo} 
		  oldSensorCrum {CanopyCrum} |
		hcrum _ self hCrum cast: HUpperCrum.
		hash _ self hashForEqual.
		oldSensorCrum _ self sensorCrum.
		info _ self fetchInfo.
		(SplitLoaf new.Become: self)
				create: region
				with: tmp1
				with: tmp2
				with: hcrum
				with: hash
				with: info.
			"The new SplitLoaf will add itself."
			oldSensorCrum removePointer: self].
	^1! !

!OPartialLoaf methodsFor: 'create'!

create: region {XnRegion}
	
	super create: region.
	myOwner _ InitialOwner fluidFetch.
	myTrailBlazer := NULL.
	self newShepherd!

create: region {XnRegion} with: hcrum {HUpperCrum} with: scrum {SensorCrum}
	super create: region with: hcrum with: scrum.
	myOwner _ InitialOwner fluidFetch.
	myTrailBlazer := NULL.
	self newShepherd!

create: region {XnRegion}
	with: hcrum {HUpperCrum}
	with: scrum {SensorCrum}
	with: owner {ID}
	with: blazer {TrailBlazer | NULL}

	super create: region with: hcrum with: scrum.
	myOwner := owner.
	myTrailBlazer := blazer.
	self newShepherd! !

!OPartialLoaf methodsFor: 'protected: delete'!

{void} dismantle
	
	DiskManager consistent: 4 with:
		[(Heaper isConstructed: myTrailBlazer) ifTrue:
			[myTrailBlazer removeReference: self].
		super dismantle]! !

!OPartialLoaf methodsFor: 'smalltalk: passe'!

{void} inform: key {Position} with: element {BeRangeElement} with: trace {TracePosition}
	"inform a piece of partiality"
	self passe.
	[| in {XnRegion} impartial {Loaf} hcrum {HUpperCrum} hash {UInt32} info {FlockInfo} sensors {ImmuSet} |
	(self domain hasMember: key) ifFalse: [Heaper BLAST: #NotInTable].
	(self hCrum hCut isEqual: trace) ifFalse: [Heaper BLAST: #CantInform].
	in _ key asRegion.
	hcrum _ self hCrum cast: HUpperCrum.
	hash _ self hashForEqual.
	info _ self fetchInfo.
	Someone shouldImplement.
	self unimplemented.   "used to be detectors.  sensors _ mySensors."
	(in isEqual: self domain) 
		ifTrue:
			[impartial _ self.
			self sensorCrum removePointer: self.
			(RegionLoaf new.Become: self)
				create: in with: element with: (HUpperCrum make: hcrum) with: hash with: info]
		ifFalse:
			[ | partial {Loaf} |
			impartial _ Loaf make.Region: in with: (CurrentGrandMap fluidGet carrier: element).
			partial _ OPartialLoaf make: (self domain minus: in)
				with: (HUpperCrum make: hcrum)
				with: self sensorCrum.
			self sensorCrum removePointer: self.
			(SplitLoaf new.Become: self) create: in
				with: impartial
				with: partial
				with: hcrum
				with: hash
				with: info].
	"self flockInfo: info."
	Dean shouldImplement.
	"sensors stepper forEach: [ :sensor {XnSensor} |
		sensor ring: impartial]"] smalltalkOnly "so we can look at the old code"!

{void} wait: sensor {XnSensor} 
	
	self passe! !

!OPartialLoaf methodsFor: 'backfollow'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	DiskManager consistent: 2 with:
		[myTrailBlazer ~~ NULL ifTrue:
			[myTrailBlazer isAlive
				ifTrue: [Heaper BLAST: #FatalError]
				ifFalse: [myTrailBlazer removeReference: self]].
		myTrailBlazer := blazer.
		blazer addReference: self.
		self diskUpdate].
	^self domain!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	(myTrailBlazer ~~ NULL and: [myTrailBlazer isEqual: blazer]) ifFalse:
		[Heaper BLAST: #InvalidTrail].!

{TrailBlazer | NULL} fetchTrailBlazer
	
	(myTrailBlazer == NULL or: [myTrailBlazer isAlive])
		ifTrue: [^myTrailBlazer].
	"it was not successfully attached, so clean it up"
	DiskManager consistent: 2 with:
		[myTrailBlazer removeReference: self.
		myTrailBlazer := NULL.
		self diskUpdate.
		^NULL]!

{void} triggerDetector: detect {FeFillRangeDetector}
	
	"do nothing"! !

!OPartialLoaf methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myOwner _ receiver receiveHeaper.
	myTrailBlazer _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myOwner.
	xmtr sendHeaper: myTrailBlazer.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OPartialLoaf class
	instanceVariableNames: ''!

(OPartialLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #CONCRETE; add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #(MAY.BECOME RegionLoaf ); yourself)!

!OPartialLoaf class methodsFor: 'smalltalk: passe'!

{Loaf} make: region {XnRegion} 
	with: hcrum {HUpperCrum} 
	with: scrum {SensorCrum}
	
	self passe! !