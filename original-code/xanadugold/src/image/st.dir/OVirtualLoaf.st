'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:13 pm'!

OExpandingLoaf subclass: #OVirtualLoaf
	instanceVariableNames: '
		myOwner {ID}
		myData {SharedData}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(OVirtualLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!OVirtualLoaf methodsFor: 'accessing'!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition} with: globalKey {Position}
	"Make a virtual DataHolder."

	(self domain hasMember: key) 
		ifTrue: 
			[^FeDataHolder fake: ((myData fetch: key) cast: PrimValue)
				with: globalKey
				with: edition] 
		ifFalse: [^NULL]!

{BeRangeElement} getBe: key {Position}
	"Get or make the BeRangeElement at the location."
	
	"My region had better be just onto the key.
	 become a RegionLoaf onto a new BeDataHolder containing the 
	 data extracted from my SharedData object."
		
	| element {BeRangeElement}  domain {XnRegion}
	 hcrum {HUpperCrum} hash {UInt32} info {FlockInfo}|
	domain _ key asRegion.
	(self domain isEqual: domain) ifFalse: [Heaper BLAST: #NotInTable].
	hcrum _ self hCrum cast: HUpperCrum.
	hash _ self hashForEqual.
	info _ self fetchInfo.
	DiskManager consistent:
		[| oldSensorCrum {CanopyCrum} |
		oldSensorCrum _ self sensorCrum.
		[Ent] USES.
		InitialOwner fluidBind: self owner
			during: [CurrentTrace fluidBind: self hCrum hCut
			during: [CurrentBertCrum fluidBind: BertCrum make
			during:
				[element _ BeDataHolder create: ((myData fetch: key) cast: PrimValue)]]].
		(RegionLoaf new.Become: self)
			create: domain
			with: element 
			with: hcrum
			with: hash 
			with: info.
		oldSensorCrum removePointer: self].
	^element!

{ID} owner
	"Return the owner of the atoms represented by the receiver."
	
	^myOwner!

{PrimSpec} spec
	"Return the primSpec for my data."
	
	^myData spec!

{XnRegion} usedDomain
	^self domain! !

!OVirtualLoaf methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec} with: globalDsp {Dsp} 
	"Return a stepper of bundles according to the order."

	| bundleRegion {XnRegion} array {PrimArray} |
	bundleRegion _ region intersect: (globalDsp ofAll: self domain).
	bundleRegion isEmpty ifTrue: [^Stepper emptyStepper].
	array _ myData spec array: bundleRegion count DOTasLong.
	myData fill: bundleRegion with: (order arrange: bundleRegion) with: array with: globalDsp.
	^Stepper itemStepper: 
		(FeArrayBundle 
			make: bundleRegion 
			with: array
			with: order)!

{void} fill: keys {XnRegion} with: toArrange {Arrangement} with: toArray {PrimArray} with: dsp {Dsp} with: edition {BeEdition} 
	
	myData fill: (keys intersect: self domain) with: toArrange with: toArray with: dsp!

{void} informTo: orgl {OrglRoot unused}
	self unimplemented!

{OrglRoot} setAllOwners: owner {ID} 
	"If the CurrentKeyMaster includes the owner of this loaf
		then change the owner and return NULL
		else just return self."
		
	(CurrentKeyMaster fluidGet hasAuthority: myOwner)
		ifTrue:
			[myOwner _ owner.
			^OrglRoot make: self domain coordinateSpace]
		ifFalse: [^ActualOrglRoot make: self with: self domain]! !

!OVirtualLoaf methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' << "(myData table subTable: self domain) <<" ', ' << self hCrum hCut << ')'! !

!OVirtualLoaf methodsFor: 'protected: splay'!

{Int8} actualSoftSplay: region {XnRegion} with: limitRegion {XnRegion unused} 
	"Don't expand my virtual tree in place.  Just move it closer to the top."
	
	^2!

{Int8} actualSplay: region {XnRegion} with: limitRegion {XnRegion unused} 
	"Expand my partial tree in place. The area in the region must go 
	into the leftCrum of my substitute, or the splay algorithm will fail!!"
	
	| crums {Pair of: SensorCrum} tmp1 {Loaf} tmp2 {Loaf} |
	crums _ self sensorCrum expand.
	InitialOwner fluidBind: self owner during:
	[DiskManager consistent: 3 with:
		[tmp1 _ OVirtualLoaf
					create: (self domain intersect: region)
					with: myData  
					with: (HUpperCrum make: (self hCrum cast: HUpperCrum))
					with: (crums left cast: SensorCrum)].
	DiskManager consistent: 3 with:
		[tmp2 _ OVirtualLoaf
					create: (self domain intersect: region complement)
					with: myData 
					with: (HUpperCrum make: (self hCrum cast: HUpperCrum))
					with: (crums right cast: SensorCrum)].
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
		oldSensorCrum removePointer: self]].
	^1! !

!OVirtualLoaf methodsFor: 'create'!

create: region {XnRegion} with: data {SharedData}
	super create: region.
	myData _ data.
	myOwner _ InitialOwner fluidFetch.
	self newShepherd!

create: region {XnRegion} with: data {SharedData} with: hcrum {HUpperCrum} with: scrum {SensorCrum}
	super create: region with: hcrum with: scrum.
	myData _ data.
	myOwner _ InitialOwner fluidFetch.
	self newShepherd! !

!OVirtualLoaf methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myData contentsHash! !

!OVirtualLoaf methodsFor: 'smalltalk:'!

showOn: oo
	oo << myData! !

!OVirtualLoaf methodsFor: 'smalltalk: passe'!

{void} wait: sensor {XnSensor}
	
	self passe! !

!OVirtualLoaf methodsFor: 'backfollow'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	^self domain coordinateSpace emptyRegion!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	"it's OK"!

{TrailBlazer | NULL} fetchTrailBlazer
	
	^NULL!

{void} triggerDetector: detect {FeFillRangeDetector}
	
	detect rangeFilled: self asFeEdition! !

!OVirtualLoaf methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myOwner _ receiver receiveHeaper.
	myData _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myOwner.
	xmtr sendHeaper: myData.! !