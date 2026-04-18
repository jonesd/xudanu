'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:19 pm'!

Recorder subclass: #HopRecorder
	instanceVariableNames: '
		lastStampID {ID}
		myFinder {PropFinder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-hoprec'!

(HopRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; yourself)!

!HopRecorder methodsFor: 'recording'!

{BooleanVar} match: prop {BertProp}
	^myFinder match: prop!

{void} record: hop {ActualHopRecord}
	| table {MuTable} used {IntegerRegion} |
	used _ self foot orgl usedDomain cast: IntegerRegion.
	used isEmpty ifFalse:
		[lastStampID == NULL ifTrue:
			[ | orgl {ActualOrgl} |
			orgl _ (self foot orgl fetch: (used stop - 1) integer) cast: ActualOrgl.
			(orgl ~~ NULL) assert.
			lastStampID _ ((XuServer currentServer
					wrap: (Sequence string: 'HopRecord')
					with: (Hand
						make.KeyMaster: self keyMaster
						with.Orgl: orgl))
				cast: ActualHopRecord) whatHand editionID].
		(lastStampID isEqual: hop whatHand editionID) ifTrue:
			[^VOID]].
	lastStampID _ hop whatHand editionID.
	table _ MuTable make: IntegerSpace make.
	used isEmpty
		ifTrue: [table atInt: IntegerVar0 store: hop editionID]
		ifFalse: [table atInt: used stop store: hop editionID].
	self foot inform: table! !

!HopRecorder methodsFor: 'receiver'!

{void RECEIVE.HOOK} restartHopRecorder: trans {Rcvr unused default: NULL}
	lastStampID _ NULL! !

!HopRecorder methodsFor: 'creation'!

create: wrapped {Manipulator} with: holder {Manipulator default: NULL}
	super create: wrapped with: holder.
	myFinder _ PropFinder backfollowFinder: (self keyMaster cast: GateKeeper) permissionsFilter.
	self restartHopRecorder: NULL! !

!HopRecorder methodsFor: 'protected: protected accessing'!

{BooleanVar} canCertify

	| used {IntegerRegion} unused {IntegerRegion} |
	used _ self foot orgl usedDomain cast: IntegerRegion.
	unused _ self foot orgl unusedDomain cast: IntegerRegion.
	^super canCertify
		and: [used isSimple
		and: [(used isEmpty or: [used stop = unused start])
		and: [(used unionWith: unused) isEqual: (IntegerRegion after: IntegerVar0)]]]!

{Foot} foot
	^self wrapped cast: Foot! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HopRecorder class
	instanceVariableNames: ''!

(HopRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; yourself)!

!HopRecorder class methodsFor: 'pseudo constructors'!

make: gk {ActualGateKeeper}
	"Return a new HopRecorder onto a new Foot onto a partial stamp"
	| aFoot {Foot} | 
	aFoot _ Foot grabNewWithFoot: gk
		with: (IntegerRegion after: IntegerVar0).
	^(XuServer currentServer wrap: (Sequence string: 'HopRecorder') with: aFoot) cast: HopRecorder! !