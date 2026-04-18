'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:22 pm'!

Abraham subclass: #RecorderFossil
	instanceVariableNames: '
		myLoginAuthority {IDRegion}
		myTrailBlazer {TrailBlazer | NULL}
		myRecorder {ResultRecorder NOCOPY | NULL}
		myRecorderCount {IntegerVar NOCOPY}
		myAgendaCount {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
RecorderFossil comment:
'A Fossil for a ResultRecorder, which also stores its permissions, filters, and a cache of the results which have already been recorded.'!

(RecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!RecorderFossil methodsFor: 'accessing'!

{void} addItem: item {AgendaItem unused}

	DiskManager insistent: 1 with:
		[myAgendaCount _ myAgendaCount + 1.
		self diskUpdate.
		self memoryCheck]!

{void} extinguish: trailBlazer {TrailBlazer}
	"Should only be called from BeEdition::fossilRelease().  Results in my becoming extinct."
	
	myTrailBlazer == NULL
		ifTrue: [Heaper BLAST: #AlreadyExtinct].
	(myTrailBlazer isEqual: trailBlazer) not
		ifTrue: [Heaper BLAST: #WhoSays].
	myRecorderCount ~= Int32Zero
		ifTrue: [Heaper BLAST: #RecordersStillOutstanding].
	myRecorder ~~ NULL
		ifTrue:
			[myRecorder destroy.
			myRecorder _ NULL].
	DiskManager insistent: 1 with:
		[myTrailBlazer _ NULL.
		self diskUpdate.
		self memoryCheck]!

{void} releaseRecorder
	"As a premature optimization, we don't destroy the waldo when the count goes to zero, but rather when we consider purging while the count is zero."
	
	(myRecorderCount >= 1) assert.
	myRecorderCount _ myRecorderCount - 1!

{void} removeItem: item {AgendaItem unused}

	(myAgendaCount >= 1) assert.
	DiskManager insistent: 1 with:
		[myAgendaCount _ myAgendaCount - 1.
		self diskUpdate.
		self memoryCheck]!

{ResultRecorder} secretRecorder
	"The Recorder of which this Fossil is the imprint. If necessary, reconstruct it using the information stored in the imprint.
	Should only be called if I am not extinct
	Should only be called from the reanimate macro."
	| |
	
	"If I'm extinct, somebody goofed.
		Blow 'em up.
	If we haven't already reanimated a recorder (because this is the outermost reanimate for this fossil)
		bind a new current KeyMaster (recovering the fossilized permissions)
					make a recorder implicitly using the fossilized permissions
						and explicitly using the fossilized endorsements
						and trail.
	bump the refcount on myRecorder
	return myRecorder"
	
	self isExtinct
		ifTrue: [Heaper BLAST: #FossilExtinct].
	myRecorder == NULL ifTrue:
		[CurrentKeyMaster fluidBind: (FeKeyMaster makeAll: myLoginAuthority)
			during: [myRecorder := self actualRecorder]].

	myRecorderCount := myRecorderCount + 1.
	^myRecorder! !

!RecorderFossil methodsFor: 'smalltalk: reanimation'!

{void} reanimate: aBlock {BlockClosure of: RecorderFossil}
	"Should only be called if I am not extinct.
	
	f reanimate: [:w {RecorderFossil} | ...]
		should translate to
	BEGIN_REANIMATE(f,RecorderFossil,w) {
		...
	} END_REANIMATE;"
	
	[aBlock value: self secretRecorder]
		valueNowOrOnUnwindDo: (RecorderFossil bomb.ReleaseRecorder: self)! !

!RecorderFossil methodsFor: 'testing'!

{BooleanVar} isExtinct
	"A Fossil (unlike a Grabber or an Orgl) does not prevent the grabbed IObject from being dismantled.  Instead, if the IObject does get dismantled, then the Fossil is considered extinct.  A waldo may not be gotten from an extinct fossil (if the species is really extinct, then it cannot be revived from its remaining fossils)."
	 
	^myTrailBlazer == NULL!

{BooleanVar} isPurgeable
	"I can`t go to disk while someone has my WaldoSocket and might be doing 
	something with the Waldo in it."
	
	(super isPurgeable and: [myRecorderCount == Int32Zero])
		ifTrue: 
			[myRecorder ~~ NULL
				ifTrue: 
					[myRecorder destroy.
					myRecorder _ NULL].
			^true]
		ifFalse: [^false]! !

!RecorderFossil methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartRecorderFossil: rcvr {Rcvr unused default: NULL}

	myRecorder _ NULL.
	myRecorderCount _ Int32Zero! !

!RecorderFossil methodsFor: 'protected: destruction'!

{void} dismantle

	(myRecorderCount = Int32Zero) assert.
	"(myAgendaCount = Int32Zero) assert."
	myRecorder ~~ NULL ifTrue:
		[myRecorder destroy.
		myRecorder _ NULL].
	DiskManager consistent: 2 with:
		[(Heaper isConstructed: myTrailBlazer) ifTrue:
			[myTrailBlazer removeReference: self].
		myTrailBlazer := NULL.
		super dismantle]! !

!RecorderFossil methodsFor: 'protected: accessing'!

{ResultRecorder} actualRecorder
	"Make the right kind of Recorder for this fossil"
	
	self subclassResponsibility!

{void} memoryCheck

	(myTrailBlazer == NULL "and: [myAgendaCount = Int32Zero]")
		ifTrue: [self forget]
		ifFalse: [self remember]!

{TrailBlazer} trailBlazer

	myTrailBlazer == NULL ifTrue:
		[Heaper BLAST: #FatalError]. "should have already been checked"
	^myTrailBlazer! !

!RecorderFossil methodsFor: 'create'!

create: loginAuthority {IDRegion}
	with: trailBlazer {TrailBlazer}
	
	super create.
	myLoginAuthority := loginAuthority.
	myTrailBlazer := trailBlazer.
	myTrailBlazer addReference: self.
	
	myAgendaCount _ Int32Zero.
	self restartRecorderFossil: NULL.! !

!RecorderFossil methodsFor: 'backfollow'!

{void} storeDataRecordingAgents: sensorCrum {SensorCrum}
	with: agenda {Agenda}
	"Store recording agents into a SensorCrum on data in the original Edition that was a source of the query"
	
	agenda registerItem: (sensorCrum recordingAgent: self) "default behaviour"!

{void} storePartialityRecordingAgents: sensorCrum {SensorCrum}
	with: agenda {Agenda}
	"Store recording agents into a SensorCrum on partiality in the original Edition that was a source of the query"
	
	agenda registerItem: (sensorCrum recordingAgent: self) "default behaviour"!

{void} storeRangeElementRecordingAgents: rangeElement {BeRangeElement unused}
	with: sensorCrum {SensorCrum}
	with: agenda {Agenda}
	"Store recording agents into a SensorCrum on a RangeElement in the original Edition that was a source of the query"
	
	agenda registerItem: (sensorCrum recordingAgent: self) "default behaviour"! !

!RecorderFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myLoginAuthority _ receiver receiveHeaper.
	myTrailBlazer _ receiver receiveHeaper.
	myAgendaCount _ receiver receiveIntegerVar.
	self restartRecorderFossil: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myLoginAuthority.
	xmtr sendHeaper: myTrailBlazer.
	xmtr sendIntegerVar: myAgendaCount.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RecorderFossil class
	instanceVariableNames: ''!

(RecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!RecorderFossil class methodsFor: 'create'!

{RecorderFossil} transcluders: isDirectOnly {BooleanVar} 
	with: loginAuthority {IDRegion}
	with: directFilter {Filter of: (Tuple of: ID with: ID)}
	with: indirectFilter {Filter of: (Tuple of: ID with: ID)}
	with: trailBlazer {TrailBlazer} 
	DiskManager consistent: 2 with:
		[isDirectOnly
			ifTrue: [^DirectEditionRecorderFossil
					create: loginAuthority
					with: directFilter
					with: indirectFilter
					with: trailBlazer]
			ifFalse: [^IndirectEditionRecorderFossil
					create: loginAuthority
					with: directFilter
					with: indirectFilter
					with: trailBlazer]]!

{RecorderFossil} works: isDirectOnly {BooleanVar}
	with: loginAuthority {IDRegion}
	with: endorsementsFilter {Filter of: (Tuple of: ID with: ID)}
	with: trailBlazer {TrailBlazer}
	DiskManager consistent: 2 with:
		[isDirectOnly
			ifTrue: [^DirectWorkRecorderFossil create: loginAuthority
				with: endorsementsFilter
				with: trailBlazer]
			ifFalse: [^IndirectWorkRecorderFossil create: loginAuthority
				with: endorsementsFilter
				with: trailBlazer]]! !

!RecorderFossil class methodsFor: 'exceptions: exceptions'!

bomb.ReleaseRecorder: CHARGE {RecorderFossil}

	^[CHARGE releaseRecorder]! !

!RecorderFossil class methodsFor: 'smalltalk: passe'!

make: loginAuthority {IDRegion}
	with: eFilter {Filter of: (Tuple of: ID with: ID)}
	with: trail {BeEdition}

	self passe! !