'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:00 pm'!

CanopyCrum subclass: #SensorCrum
	instanceVariableNames: 'myBackfollowRecorders {ImmuSet of: RecorderFossil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SensorCrum comment:
'This implementation is the same as BertCrums.  This will require 
pointers into the ent to implement delete (for archiving).  Canopy 
reorganization could be achieved by removing several orgls, then 
re-adding them (archive then restore).'!

(SensorCrum getOrMakeCxxClassDescription)
	friends:
'friend class RecorderHoister;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SensorCrum methodsFor: 'private: creation'!

create
	"Make a canopyCrum for a root:  it has no children."
	super create: UInt32Zero.
	myBackfollowRecorders _ ImmuSet make.
	self newShepherd!

create: flags {UInt32}

	"Make a canopyCrum for a root:  it has no children."
	super create: flags.
	myBackfollowRecorders _ ImmuSet make.
	self newShepherd! !

!SensorCrum methodsFor: 'smalltalk:'!

{CanopyCrum} another
	"SensorCrum create verify2."

	^SensorCrum create!

displayString
	^String
		streamContents: 
			[:aStream | 
			aStream print: self maxHeight.
			self maxHeight == self minHeight 
				ifFalse: [aStream nextPut: $-; print: self minHeight]]!

inspectMenuArray
	^#(
		('inspect oparts'	inspectOParts		''))!

inspectOParts
	| owners |
	owners _ self allOwners select: [ :each | each isKindOf: OPart].
	owners isEmpty ifTrue:
		[Transcript show: 'Nobody'; cr]
	ifFalse: [owners size = 1 ifTrue:
		[owners first inspect]
	ifFalse:
		[owners inspect]]!

{void} printOn: aStream 
	[myBackfollowRecorders == nil ifTrue: [
		aStream << self getCategory name << '(nil)'. ^ VOID]] smalltalkOnly.
		
	aStream << self getCategory name << '(' << (self flags printStringRadix: 2) << ')'.
	myBackfollowRecorders isEmpty ifFalse:
		[aStream << ' *']! !

!SensorCrum methodsFor: 'protected:'!

{CanopyCache wimpy} canopyCache
	"should have one per Ent"
	^CurrentSensorCanopyCache fluidGet!

{CanopyCrum} makeNew

	Dean thingToDo. "is this right? I want to preserve the partiality flag when a partial loaf splits /ravi/5/7/92/"
	self isPartial ifTrue:
		[^SensorCrum create: SensorCrum isPartialFlag]
	ifFalse:
		[^SensorCrum create]! !

!SensorCrum methodsFor: 'accessing'!

{PropFinder} checkRecorders: finder {PropFinder} 
	with: scrum {SensorCrum | NULL} 
	
	"Set off all recorders that respond to the change either in me or in any of my ancestors up to but not including sCrum
	(If I am the same as sCrum, skip me as well.)
	(If sCrum is null, search through all my ancestors to a root of the sensor canopy.)
	return simplest finder for looking at children"
	
	| next {SensorCrum | NULL} |
	
	"from self rootward until told to stop (at sCrum or the root)
		trigger any matching recorders
	return a simplified finder for examining children."
	
	next := self.
	[next ~~ NULL] whileTrue:
		[next := next fetchNextAfterTriggeringRecorders: finder with: scrum].
	^finder pass: self!

{SensorCrum | NULL} fetchNextAfterTriggeringRecorders: finder {PropFinder} 
	with: sCrum {SensorCrum | NULL}
	
	"Set off all recorders in me that respond to the change, if appropriate
	(If I am the same as sCrum, skip me.)
	If sCrum is null or not me, return my parent so caller can iterate through my ancestors to sCrum or a root."
	
	|  |
	
	"One step of the leafward walk of the O-plane, triggering recorders:
	Walk rootward on the sensor canopy, where many steps may correspond to this single leafward step."
	
	"If we're the designated sCrum (where this work was already done)
	 	return without doing anything.  We're done.
	For each of our recorders
		if it hasn't gone extinct
			reanimate it long enough to
				trigger it, recording stamp if finder matches.
	Return a pointer to our parent (so caller can iterate this operation rootward)."
	
	(sCrum ~~ NULL and: [self isEqual: sCrum]) ifTrue:
		[^NULL].
	myBackfollowRecorders stepper forEach: [ :fossil {RecorderFossil} |
		fossil isExtinct ifFalse:
			[fossil reanimate: [:recorder {ResultRecorder} |
				recorder triggerIfMatching: finder with: fossil]]].
	^self fetchParent cast: SensorCrum.!

{BooleanVar} isPartial

	^(self flags bitAnd: SensorCrum isPartialFlag) ~= UInt32Zero!

{ImmuSet of: RecorderFossil} recorders
	^myBackfollowRecorders!

{AgendaItem} recordingAgent: recorder {RecorderFossil}
	"NOTE: The AgendaItem returned is not yet scheduled.  Doing so is up to my caller."
	
	|  |
	
	"If the recorder we're adding isn't already present here
		pack up the fossil for shipment to the hoister
		atomically
			Install the recorder here
			return a RecorderHoister to propagate the side-effects and anneal the canopy
			(The RecorderHoister will update myFlags)
	return an empty agenda (to satisfy our contract)"
	
	(myBackfollowRecorders hasMember: recorder) ifFalse:
		[ | cargo {ImmuSet of: RecorderFossil} |
		cargo := ImmuSet make with: recorder.
		DiskManager consistent: 2 with:
			[self installRecorders: cargo.
			self diskUpdate.
			^RecorderHoister make: self with: cargo]].
	^Agenda make!

{void} removeRecorders: recorders {ImmuSet of: RecorderFossil}
	"Remove recorders because they have migrated rootward.
	Recalculate myOwnFlags and myFlags."
	
	| f {UInt32} |
	myBackfollowRecorders _ myBackfollowRecorders minus: recorders.
	self diskUpdate.
	f := UInt32Zero.
	myBackfollowRecorders stepper forEach: [ :fossil {RecorderFossil} |
		fossil isExtinct ifFalse:
			[fossil reanimate: [:recorder {ResultRecorder} |
				f := f bitOr: recorder sensorProp flags]]].
	self setOwnFlags: f.
	self changeCanopy! !

!SensorCrum methodsFor: 'private:'!

{void} installRecorders: recorders {ImmuSet of: RecorderFossil}
	"Installs the recorders in my set and updates myOwnProp accordingly.
	The caller has already checked that none of these recorders are already installed here.
	The caller also handles updating myFlags.
	The caller also handles all issues of rootward propagation of these changes.
	The caller also does the 'diskUpdate'.
	
	This is a separate method because it's called once by the code that installs a new recorder, and again by the code that recursively hoists recurders up the canopy.
	
	add the new recorders to my set
	for each new recorder
		if it hasn't gone extinct
			extract its properties
			union them into my own"

	myBackfollowRecorders _ myBackfollowRecorders unionWith: recorders.
	recorders stepper forEach: [ :fossil {RecorderFossil} |
		fossil isExtinct ifFalse: [ | prop {Prop} |
			fossil reanimate: [:recorder {ResultRecorder} |
				prop := recorder sensorProp].
			self setOwnFlags: (self ownFlags bitOr: prop flags)]]! !

!SensorCrum methodsFor: 'protected'!

{CanopyCrum} makeNewParent: first {CanopyCrum} with: second {CanopyCrum}

	DiskManager consistent: 3 with:
		[^SensorCrum create: (first cast: SensorCrum)
	 		with: (second cast: SensorCrum)]! !

!SensorCrum methodsFor: 'smalltalk: passe'!

{PropFinder} checkRecorders: stamp {BeEdition} 
	with: finder {PropFinder} 
	with: sCrum {SensorCrum | NULL}
	
self passe "fewer args"!

{SensorCrum | NULL} fetchNextAfterTriggeringRecorders: stamp {BeEdition} 
	with: finder {PropFinder} 
	with: sCrum {SensorCrum | NULL}
	
	self passe "fewer args"!

{void} record: recorder {RecorderFossil}
	
	self passe. "equivalent to '(self recordingAgent: recorder) schedule"!

{void} triggerRecorders: stamp {Stamp} 
	with: finder {PropFinder} 
	with: sCrum {SensorCrum | NULL}
	
	self passe.	"Use fetchNextAfterTriggeringRecorders:with:with:"! !

!SensorCrum methodsFor: 'instance creation'!

create: first {SensorCrum} with: second {SensorCrum}
	"Create a new parent for two SensorCrums.
	This constructor just makes a new parent whose properties are empty. My client must bring my properties up to date."
	| |
	"Have the super do the basic creation."
	
	super create: UInt32Zero with: first with: second.
	self newShepherd.
	myBackfollowRecorders _ ImmuSet make.
	self canopyCache updateCache: self fetchChild1 forParent: self.
	self canopyCache updateCache: self fetchChild2 forParent: self! !

!SensorCrum methodsFor: 'smalltalk: suspended'!

changeCanopy: f!

{PropChange} fullChange
	^PropChange sensorPropChange! !

!SensorCrum methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBackfollowRecorders _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myBackfollowRecorders.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SensorCrum class
	instanceVariableNames: ''!

(SensorCrum getOrMakeCxxClassDescription)
	friends:
'friend class RecorderHoister;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!SensorCrum class methodsFor: 'smalltalk: init'!

staticTimeNonInherited
	
	CanopyCache defineFluid: #CurrentSensorCanopyCache with: DiskManager emulsion with: [CanopyCache make]! !

!SensorCrum class methodsFor: 'pseudo constructors'!

make
	DiskManager consistent: 2 with: [
		^SensorCrum create]!

{SensorCrum} partial
	DiskManager consistent: 1 with: [
		^SensorCrum create: SensorCrum isPartialFlag]! !

!SensorCrum class methodsFor: 'flags'!

{UInt32} flagsFor: permissions {IDRegion | NULL}
	with: endorsements {CrossRegion | NULL}
	with: isPartial {BooleanVar}
	"The flag word corresponding to the given props"
	
	| result {UInt32} |
	result := UInt32Zero.
	permissions ~~ NULL ifTrue:
		[result := result bitOr: (CanopyCrum permissionsFlags: permissions)].
	endorsements ~~ NULL ifTrue:
		[result := result bitOr: (CanopyCrum endorsementsFlags: endorsements)].
	isPartial ifTrue:
		[result := result bitOr: self isPartialFlag].
	^result!

{UInt32 constFn} isPartialFlag
	"Flag bit for existence of partiality" 
	^16r08000000! !