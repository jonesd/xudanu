'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:35 pm'!

Orgl subclass: #ActualOrgl
	instanceVariableNames: 'myStamp {Stamp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(ActualOrgl getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; add: #EQ; yourself)!

!ActualOrgl methodsFor: 'accessing'!

{ScruTable of: PackOBits} asDataTable
	"return a table of the data only"

	^ self orglRoot asDataTable!

{ScruTable} asTable
	"return a table of the contents"
	| result {MuTable} keys {TableStepper} |
	result _ self orglRoot asTable asMuTable.
	(keys _ result stepper) forEach: [ :value {Heaper} |
		result at: keys position store: (self mapValue: value)].
	^ result!

{ImmuSet of: (ID of: Bert)} berts: gk {GateKeeper} with: filter {Filter}
	"all berts currently on this orgl"
	^ myStamp berts: (PropFinder backfollowFinder: gk permissionsFilter with: filter).!

{Orgl} combine: other {Orgl}
	"return a new orgl which combines two non-overlapping orgls"
	^self makeDerivedOrgl: (self orglRoot combine: (other cast: ActualOrgl) orglRoot)!

{Mapping} compare: other {Orgl}
	"return a mapping from my domain to the region that other shares with me"
	^self orglRoot compare: (other cast: ActualOrgl) orglRoot hCut!

{CoordinateSpace} coordinateSpace
	"coordinate space"

	^ self orglRoot coordinateSpace!

{Orgl} copy: region {XnRegion}
	"return subset of this orgl which lies in the region"
	^self makeDerivedOrgl: (self orglRoot copy: region)!

{IntegerVar} count
	"the number of elements known to be in the orgl"
	^ self orglRoot count!

{Orgl} delayedExtendFindMatching: gk {ActualGateKeeper} with: stampID {ID}
	| stamp {Stamp} recorder {Fossil of: BackfollowRecorder} |
	
	"Permission system hole:  Reuses old recorder's permissions even though >I< may not have that set of permissions."
	
	"Unlike delayedFindMatching:with:, which can drop the partially constructed object if things crash in the middle, this modifies existing stuff, so error are visible after the crash.  Also, storeRecordingAgent doesn't restart to finish planting recording agents after the crash.  (Missing agenda item.)"
	
	"The whole mechanism is going away, so we're not going to bother fixing these bugs.  We could fix them by scheduling an AgendaItem to retry the scheduleDelayedBackfollow: after crashes."
	
	(gk canEdit: stampID)
		ifFalse: [Heaper BLAST: #CannotEdit].
	self thingToDo. "More extensive permissions check  Actually:  Just throw it all out."
	
	stamp _ gk grandMap fetchStamp: stampID with: gk permissionsFilter.
	(stamp == NULL or: [(recorder _ stamp fetchRecorder) == NULL])
		ifTrue: [Heaper BLAST: #NoRecorder].
	self scheduleDelayedBackfollow: recorder.
	^stamp orgl!

{Orgl} delayedFindMatching: gk {ActualGateKeeper} 
	with: endorsementsFilter {Filter of: (XnRegion of: ID)}
	
	| recorder {BackfollowRecorder} 
	  fossil {Fossil of: BackfollowRecorder} 
	  result {Orgl} |
	  
	"Returns Orgl on recorder results.
	 gk:  user's current permissions (to be to build the Recorder's permissions Filter)
	
	Create the Recorder (the Waldo on a Foot holding the results Orgl) whose Fossil we're making.
	get the Foot, extract the Orgl for later return.
	make a Fossil of the Recorder, destroying the Foot and the Recorder.
	drop dangling reference to the Recorder
	schedule a delayed backfollow.
	return the Orgl."
	  
	recorder := BackfollowRecorder make: gk
		with: gk permissionsFilter with: endorsementsFilter.
	result := (recorder tip cast: Foot) orgl.
	fossil := Fossil make: recorder.
	recorder := NULL.
	self scheduleDelayedBackfollow: fossil.
	^result!

{XnRegion} domain
	"a region of all the keys in this orgl"
	^self orglRoot domain!

{XnRegion of: ID} endorsements
	^myStamp endorsements!

{Heaper} fetch: key {Position}
	"look up an element, return NULL if not there"
	^ self mapValue: (self orglRoot fetch: key)!

{Orgl} findMatching: gk {GateKeeper} 
	with: endorsementsFilter {Filter of: (XnRegion of: ID)}
	^gk makeOrglFromTable: (self 
			mapBackReference: gk
			with: (self orglRoot 
					findMatching: (PropFinder 
						backfollowFinder: gk permissionsFilter 
						with: endorsementsFilter))).!

{BooleanVar} isKnownEmpty
	^ self orglRoot isKnownEmpty!

{XnRegion} knownSharedRegion: other {Orgl}
	"return the region in this orgl that leads to data in the other orgl"
	^ self orglRoot sharedRegion: (other cast: ActualOrgl) orglRoot hCut!

{XnRegion} simpleDomain
	"a region of all the keys in this orgl"
	^self orglRoot simpleDomain!

{ID} stampID
	^ myStamp iD!

{Orgl} transform: mapping {Mapping}
	"return an orgl with the coordinates transformed"
	
	| resultRoot {OrglRoot} 
	  domain {XnRegion} 
	  table {MuTable} |
	  
	mapping 
		cast: Dsp into: [:dsp |
			^self makeDerivedOrgl: (self orglRoot transformedBy: dsp)]
		others: [].
	domain _ self orglRoot simpleDomain.
	table _ MuTable make: mapping rangeSpace.
	resultRoot _ self grandMap newOrglRootFromTable: table.
	mapping simpleMappings stepper forEach:
		[:simple {Mapping} | 
		| common {XnRegion} |
		common _ domain intersect: simple domain.
		common isEmpty ifFalse:
			[ | dsp {Dsp} |
			(dsp _ simple fetchDsp) ~~ NULL ifTrue:
				[resultRoot _ resultRoot combine: ((self orglRoot copy: common) 
												transformedBy: dsp)]
			ifFalse:
				[self unimplemented.
				" | hroots {TableStepper of: HRoot} |
				self thingToDo. ""extend this to handle 3D &c""
				hroots _ (self orglRoot copy: common) asHRootTable stepper.
				hroots forEach: [ :hroot {HRoot} |
					table at: (simple of: hroots key) introduce: hroot]"]]].
	table isEmpty ifFalse:
		[resultRoot _ resultRoot combine: (self grandMap newOrglRootFromTable: table)].
	^self makeDerivedOrgl: resultRoot!

{XnRegion} unusedDomain
	"a region of all the keys in this orgl"
	^self orglRoot unusedDomain!

{XnRegion} usedDomain
	"a region of all the keys in this orgl"
	^self orglRoot usedDomain!

{void} wait: sensor {XnSensor}
	"ring the sensor when partiality gets filled in"
	self orglRoot wait: (BackfollowSensor make: self stamp with: sensor)!

{Orgl} with: gk {GateKeeper} 
	with: key {Position} 
	with: value {Heaper as: (Manipulator | ActualOrgl | ID | Sequence)} 

	| table {MuTable} oRoot {OrglRoot} |
	table _ MuTable make: key coordinateSpace.
	table at: key store: value.
	self hack.
	"only create a stamp for PackOBits values -- awaiting 
	DataThingie resolution"
	"MSM: I don't think this is a hack.  I think it is correct."
	(value isKindOf: Sequence) 
		ifTrue: [^(self without: key) combine: (gk makeOrglFromTable: table)]
		ifFalse: [
			oRoot _ (self orglRoot copy: key asRegion complement)
				combine: (self grandMap newOrglRootFromTable: table).
			^self makeDerivedOrgl: oRoot].!

{Orgl} without: key {Position}
	"return subset of this orgl without anything at the given position"
	^self copy: key asRegion complement!

{Orgl} withoutAll: region {XnRegion}
	"return subset of this orgl without anything at the given positions"
	^ self copy: region complement! !

!ActualOrgl methodsFor: 'instance creation'!

create: stamp {Stamp}
	super create.
	myStamp _ stamp.!

{void} destroy
	"do nothing"! !

!ActualOrgl methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name.
	myStamp == NULL 
		ifTrue: [oo << ' deleted']
		ifFalse: [oo << '(' << self stampID << ', ' << self domain << ')']! !

!ActualOrgl methodsFor: 'actual only'!

{GrandMap} grandMap
	^ myStamp grandMap!

{OrglRoot} orglRoot
	^ myStamp orglRoot!

{BertProp} prop
	"the property list on this orgl"
	^ myStamp prop!

{Stamp} stamp
	"the corresponding stamp"
	^ myStamp! !

!ActualOrgl methodsFor: 'private: private'!

{Heaper} mapValue: value {Heaper}

	value cast: Stamp into: [:stamp |
			^stamp orgl]
		others: [^value]! !

!ActualOrgl methodsFor: 'protected: destruct'!

{void} destruct
	(myStamp isKindOf: Stamp)
		ifTrue: [myStamp removeActualOrgl: self].
	super destruct! !

!ActualOrgl methodsFor: 'private'!

{Orgl} makeDerivedOrgl: orglRoot {OrglRoot}

	^(self grandMap makeStamp: orglRoot) orgl.!

{ScruTable of: ID} mapBackReference: gk {GateKeeper} 
	with: direct {ScruTable of: Stamp}
	"map a table of stamps into a table of IDs of stamps containing stamps.  As a 
	convenience, the containing stamps are made readable."
	| result {MuTable} step {TableStepper} |
	result _ MuTable make: direct coordinateSpace.
	(step _ direct stepper) forEach: [ :stamp {Stamp} | 
		| table {IntegerTable} | 
		table _ IntegerTable make: 1.
		table atInt: IntegerVar0 store: stamp.
		result 
			at: step position 
			store: ((gk cast: ActualGateKeeper) makeReadableOrgl: table) stampID].
	^result!

{void} scheduleDelayedBackfollow: fossil {Fossil of: BackfollowRecorder}

	"Walk down orgl's O-tree (onto range elements of interest) planting pointers to a Fossil of BackfollowRecorder in the sensor canopy and collecting agenda items to propagate their endorsement and permission filtering info rootward in the sensor canopy.
	Create and schedule a structure of AgendaItems to:
		- First:  Do the filtering info propagation.
		- Second: Find and record any currently matching stamps.
	
	This is done in this order so collection of the future part of recorder information is completed before the present part is extracted, keeping significant information from falling through the crack."
	  	
	| rAgents {Agenda} 
	  matcher {AgendaItem} |
	  
	"Create an empty Agenda.
	Do the walk and collect PropChangers in the new Agenda.
	Reanimate the Fossil long enough to
		make a Matcher AgendaItem
			from the filtering information extracted from the Fossil
	Make and schedule a Sequencer that first runs the Agenda that propagates filtering info, then runs the Matcher."

	fossil isExtinct ifTrue:
		[^VOID].
	rAgents _ Agenda make.
	self orglRoot storeRecordingAgents: fossil with: rAgents.
	fossil reanimate: [:waldo {BackfollowRecorder} |
		matcher _ Matcher 
				make: myStamp 
				with: (PropFinder 
						backfollowFinder: waldo permissionsFilter 
						with: waldo endorsementsFilter)
				with: fossil].
	(Sequencer make: rAgents with: matcher) schedule! !

!ActualOrgl methodsFor: 'smalltalk: passe'!

{Orgl} makeDerivedOrgl: orglRoot {OrglRoot} with: km {KeyMaster default: NULL}
	
	self passe. "use makeDerivedOrgl:"! !

!ActualOrgl methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualOrgl class
	instanceVariableNames: ''!

(ActualOrgl getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; add: #EQ; yourself)!

!ActualOrgl class methodsFor: 'instance creation'!

make: stamp {Stamp}
	^self create: stamp! !