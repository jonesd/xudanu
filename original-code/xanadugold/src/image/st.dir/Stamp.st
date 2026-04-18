'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:47 pm'!

IObject subclass: #Stamp
	instanceVariableNames: '
		myBerts {MuSet of: Bert}
		myActualOrgl {ActualOrgl NOCOPY}
		myOrglRoot {OrglRoot}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(Stamp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!Stamp methodsFor: 'filtering'!

{BooleanVar} anyPasses: finder {PropFinder}

	self knownBug.	"Need to find out what happens if we are partial above.  (One facet of the backfollw-to-archive issue)"
	^(finder match: self prop) or: [self fetchHRoot ~= NULL and: [self fetchHRoot anyPasses: finder]]!

{void} checkRecorders: stamp {Stamp} 
	with: finder {PropFinder} 
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
			(RecorderChecker
				make: self orglRoot
				with: stamp
				with: newFinder
				with: scrum) schedule]! !

!Stamp methodsFor: 'testing'!

{UInt32} contentsHash

	^(super contentsHash
		bitXor: myBerts hashForEqual "since its a GrandHashSet")
		bitXor: myOrglRoot hashForEqual!

{BooleanVar} isPurgeable
	"Return false only if the object cannot be flushed to disk. This will probably 
	only be false for Stamps and the like that contain session level pointers."

	^myActualOrgl == NULL and: [super isPurgeable]! !

!Stamp methodsFor: 'accessing'!

{ImmuSet of: Bert} berts: finder {PropFinder}
	"All berts on me that pass the filter"
	| result {MuSet} |
	result _ MuSet make.
	myBerts stepper forEach: [ :bert {Bert} |
		(finder match: bert prop) ifTrue:
			[result store: bert]].
	^ result asImmuSet!

{XnRegion of: ID} endorsements
	^self prop endorsements!

{Fossil of: BackfollowRecorder} fetchRecorder
	"if there is a backfollow recorder filling this stamp, return its Fossil, else NULL"
	^self fetchFossil!

{void} inform: key {Position} with: value {Heaper as: ID | PackOBits}
	"fill in partiality with a new value"
	| hroot {HRoot} |
	[HistoryCrum] USES.
	self knownBug. "is this consistent block bounded?"
	DiskManager consistent: 20 with:
		[((value isKindOf: ID) and: [(hroot _ self grandMap fetchIDHRoot: (value basicCast: ID)) ~~ NULL])
			ifTrue: [hroot updateBCrumTo: ((self orglRoot hCrum bertCrum
					computeJoin: hroot hCrum bertCrum) cast: BertCrum)]
			ifFalse: [hroot _ self grandMap getOrMakeHRoot: value].
		self orglRoot inform: key with: hroot]!

{void} introduceBert: bert {Bert} 
	"add a new bert on the stamp"

	DiskManager consistent: 
		[myBerts introduce: bert.
		self diskUpdate].
	DiskManager consistent: 
		[(myBerts count >= 100 and: [(myBerts isKindOf: GrandHashSet) not]) ifTrue: 
			[| newBerts {MuSet} |
			newBerts _ GrandHashSet make.
			myBerts stepper forEach: 
				[:b {Bert} |
				newBerts store: b].
			myBerts _ newBerts.
			self diskUpdate].
		self propChanged: PropChange bertPropChange
			with: BertProp make
			with: bert prop]!

{Orgl} orgl
	"the orgl associated with this IObject"
	
	[myActualOrgl ~~ nil assert: 'a nil Actual Org!!'] smalltalkOnly.
	myActualOrgl == NULL
		ifTrue: 
			[myActualOrgl _ ActualOrgl make: self.
			myActualOrgl ~~ NULL assert: 'NULL ActualOrgl'.
			self
				propChanged: PropChange cannotPartializeChange
				with: BertProp make
				with: BertProp cannotPartializeProp].
	^myActualOrgl!

{OrglRoot} orglRoot
	^ myOrglRoot!

{void} propChanged: change {PropChange} with: old {Prop} with: nw {Prop} 
	"update props"
	
	| newProp {Prop} |
	
	"Attempt to apply the change directly to the current set of properties.
	 If that removes some property
	 			look at all the berts to see if we get it from somewhere else.  (BIG and not currently log.)
	 If the new properties are different than the old ones we must change, so
	 		remember the current props
	 		In a consistent block
	 			change the props on the stamp
	 			change leaf of bert canopy and create an AgendaItem to propagate the change rootward in bert canopy
	 			fetch a finder to look for recorders rung by this change in props
	 			See if just permissions decrease:
	 				If so, recorders can't be rung.  Don't bother with sensor canopy, just schedule bert canopy propagation.
	 				If not
	 					make an AgendaItem to check for recorders in the sensor canopy
	 					make and schedule a Sequencer to do the bert then the sensor canopy AgendaItems."
	
	newProp _ change changed: self prop with: self localProp.
	newProp _ change with: newProp with: nw.
	(change areEqualProps: newProp with: (change with: newProp with: old)) not
		ifTrue: [myBerts stepper forEach: [:bert {Bert} | 
				self thingToDo.  "Make it log."
				newProp _ change with: newProp with: bert prop]].
	(change areEqualProps: self prop with: newProp)
		ifFalse: 
			[| before {BertProp} finder {PropFinder} 
			   changer {AgendaItem} checker {AgendaItem} |
			before _ self prop.
			DiskManager consistent: 7 with:
				[self setProp: (newProp cast: BertProp).
				changer _ myOrglRoot propChanger: change.
				finder _ change fetchFinder: before with: self prop.
				finder == NULL
					ifTrue: [changer schedule]
					ifFalse:
						[checker _ RecorderChecker make: myOrglRoot 
								with: self 
								with: finder 
								with: NULL.
						(Sequencer make: changer with: checker) schedule]]]!

{void} removeActualOrgl: orgl {ActualOrgl} 
	"remove the orgl from the list of stamps on it"
	"Boy, could this be optimized"

	(myActualOrgl == orgl) assert: 'What are you trying to delete'.
	myActualOrgl _ NULL.
	self
		propChanged: PropChange cannotPartializeChange
		with: BertProp cannotPartializeProp
		with: BertProp make!

{void} removeBert: bert {Bert} 
	"add a new bert on the stamp"

	DiskManager consistent:
		[myBerts remove: bert.
		self diskUpdate.
		self propChanged: PropChange bertPropChange
			with: bert prop
			with: BertProp make]! !

!Stamp methodsFor: 'receiver'!

{void RECEIVE.HOOK} restartStamp: trans {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"
	[myActualOrgl == nil assert: 'attempt to reassign a non-nil orgl.'] smalltalkOnly.
	myActualOrgl _ NULL.! !

!Stamp methodsFor: 'smalltalk: smalltalk defaults'!

{void} restartStamp

	self restartStamp: NULL! !

!Stamp methodsFor: 'instance creation'!

create: gm {GrandMap} with: orglRoot {OrglRoot}
	super create: NULL with: gm.
	myBerts _ MuSet make.
	myOrglRoot _ orglRoot.
	myOrglRoot introduceStamp: self.
	
	self restartStamp.
	self newShepherd! !

!Stamp methodsFor: 'protected: protected'!

{BooleanVar} canForget
	"Return true if there are no more references onto this Stamp. 
	 References include Orgls, Berts, and HRoots."
	
	^myBerts isEmpty and: [super canForget]!

{void} dismantle
	"Disconnect me and remove me from disk."
	
	DiskManager consistent: 280 with:
		[self propChange: PropChange bertPropChange with: BertProp make.
		myOrglRoot ~~ NULL ifTrue:
			[myOrglRoot removeStamp: self.
			myOrglRoot _ NULL].
		super dismantle]! !

!Stamp methodsFor: 'smalltalk: gc'!

{void} markChildren: count {IntegerVar}
	super markChildren: count.
	myOrglRoot markInstances: count.! !

!Stamp methodsFor: 'protected: grabbing'!

{Grabber} privateReconstructGrab: gk {ActualGateKeeper}

	^Foot make: gk with: self! !

!Stamp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBerts _ receiver receiveHeaper.
	myOrglRoot _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myBerts.
	xmtr sendHeaper: myOrglRoot.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Stamp class
	instanceVariableNames: ''!

(Stamp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!Stamp class methodsFor: 'instance creation'!

make: gm {GrandMap} with: orglRoot {OrglRoot}
	^Stamp create: gm with: orglRoot! !