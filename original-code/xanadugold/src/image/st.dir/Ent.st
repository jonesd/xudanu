'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:05 pm'!

Abraham subclass: #Ent
	instanceVariableNames: '
		oroots {MuTable NOCOPY smalltalk of: TracePosition and: OrglRoot}
		fulltrace {DagWood}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(Ent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!Ent methodsFor: 'orgl creation'!

{TracePosition} newTrace
	^fulltrace newPosition! !

!Ent methodsFor: 'instance creation'!

create
	super create.
	[oroots _ MuTable make: HeaperSpace make] smalltalkOnly.
	fulltrace _ DagWood create.
	self newShepherd.
	self remember! !

!Ent methodsFor: 'smalltalk:'!

inspect
	Sensor leftShiftDown ifTrue: [self basicInspect]
		ifFalse: [self inspectFrom: fulltrace root]!

inspectFrom: tracePos 
	| seen trace |
	seen _ Set new.
	EntView openOn: (TreeBarnacle new
			buildOn: (self makeHandleFor: tracePos)
			gettingChildren: 
				[:handle | 
				trace _ handle tracePos.
				(seen includes: trace)
					ifTrue: [OrderedCollection new]
					ifFalse: [seen add: trace.
							trace successors asOrderedCollection collect: [:tp | self makeHandleFor: tp]]]
			gettingImage: [:handle | handle displayString asDisplayText]
			at: 0 @ 0
			vertical: false
			separation: 10 @ 10)!

{void} installORoot: root {OrglRoot}
	"oroots at: (HeaperAsPosition make: root hCut) store: root"!

makeHandleFor: tracePos 
	"These traceHandles are to hold a place in the ent inspection view.  
	They are not used for ent behavior at all!!"

	^RootHandle tracePos: tracePos ent: self!

{OrglRoot} oRootAt: tpos {TracePosition}
	^(oroots fetch: (HeaperAsPosition make: tpos)) cast: OrglRoot! !

!Ent methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: fulltrace hashForEqual! !

!Ent methodsFor: 'smalltalk: passe'!

{Pair of: TracePosition and: BertCrum} mapJoin: table {ScruTable of: (ID | ActualOrgl | IObject | PackOBits)} with: gm {BeGrandMap}
	"compute the join of the existing traces and bert crums in the table"
	"make new ones if there are none"
	self passe.
"	| n {IntegerVar} trace {TracePosition} crum {BertCrum} |
	[HistoryCrum] USES.
	n _ IntegerVar0.
	(table isKindOf: XnWordArray) ifFalse:
		[table stepper forEach: [ :each {Heaper} | | hroot {HRoot} |
			hroot _ NULL.
			(each isKindOf: ID) ifTrue:
				[hroot _ gm fetchIDHRoot: (each quickCast: ID)]
			ifFalse: [(each isKindOf: ActualOrgl) ifTrue:
				[hroot _ (each quickCast: ActualOrgl) stamp fetchHRoot]
			ifFalse: [(each isKindOf: IObject) ifTrue:
				[hroot _ (each quickCast: IObject) fetchHRoot]]].
			hroot ~~ NULL ifTrue:
				[ | newtrace {TracePosition} newcrum {BertCrum} |
				newtrace _ hroot hCrum hCut.
				newcrum _ hroot hCrum bertCrum.
				n = IntegerVar0 ifTrue:
					[trace _ newtrace.
					crum _ newcrum]
				ifFalse:
					[trace _ trace newSuccessorAfter: newtrace.
					crum _ (crum computeJoin: newcrum) cast: BertCrum].
				n _ n + 1]]].
	n = IntegerVar0 ifTrue: [^Pair make: fulltrace newPosition with: BertCrum make].
	n = 1 ifTrue: [^Pair make: trace newSuccessor with: crum].
	^Pair make: trace with: crum"!

{ScruTable of: HRoot} mapTable: table {ScruTable of: (ID | ActualOrgl | IObject | PackOBits)} with: gm {BeGrandMap}
	"map the elements in the table to just HRoots"
	self passe.
	
"	| result {MuTable} stepper {TableStepper} |
self passe.	(table isKindOf: XnWordArray) ifTrue:
		[^ table].
	result _ MuTable make: table coordinateSpace.
	(stepper _ table stepper) forEach: [ :value {Heaper} |
		DiskManager consistent: 11 with:
			[result at: stepper key store: (gm getOrMakeHRoot: value)]].
	^ result"!

{OrglRoot} newOrglRoot: table {ScruTable of: FeRangeElement} with: gm {BeGrandMap}
	
	"compute the join of the existing traces and bert crums in the table"
	"make new ones if there are none"
	self passe.!

{OrglRoot} newPartialOrglRoot: region {XnRegion} 
	"create a new partial orgl root on a region"
	
	self passe.
	CurrentTrace
		fluidBind: fulltrace newPosition
		during: 
			[| newCrum {BertCrum} |
			newCrum _ BertCrum create.
			CurrentBertCrum
				fluidBind: newCrum
				during: 
					[| newRoot {OrglRoot} |
					newRoot _ OrglRoot make.Region: region.
					"oroots at: (HeaperAsPosition make: newRoot hCut) introduce: newRoot."
					^newRoot]]! !

!Ent methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	fulltrace _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: fulltrace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Ent class
	instanceVariableNames: ''!

(Ent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!Ent class methodsFor: 'instance creation'!

{Ent} make
	^ Ent create! !

!Ent class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited

	TracePosition defineFluid: #CurrentTrace with: DiskManager emulsion with: [NULL].
	BertCrum defineFluid: #CurrentBertCrum with: DiskManager emulsion with: [NULL].! !

!Ent class methodsFor: 'magic numbers'!

{IntegerVar INLINE} tableSegmentMaxSize
	"When we are making an orgl out of a table, we break the table up into pieces which should be no larger than this, so that they each fit into a snarf."

	^16384! !