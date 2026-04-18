'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:04 pm'!

XnRegion subclass: #CompositeRegion
	instanceVariableNames: 'myCS {CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(CompositeRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!CompositeRegion methodsFor: 'creation'!

create: cs {CoordinateSpace}
	super create.
	myCS _ cs.! !

!CompositeRegion methodsFor: 'enumerating'!

{IntegerVar} count
	self subclassResponsibility!

{Stepper} stepper: order {OrderSpec default: NULL}
	self subclassResponsibility! !

!CompositeRegion methodsFor: 'deferred'!

{ScruSet of: XnRegion} distinctions
	
	self subclassResponsibility!

{Stepper} simpleRegions: order {OrderSpec default: NULL}
	
	self subclassResponsibility! !

!CompositeRegion methodsFor: 'operations'!

{XnRegion} complement
	
	self subclassResponsibility!

{XnRegion} intersect: other {XnRegion unused}
	self subclassResponsibility!

{XnRegion} simpleUnion: other {XnRegion unused}
	self subclassResponsibility!

{XnRegion} subtractedFrom: other {CompositeRegion}
	"other minus: self -- arranged this way for modularity"
	self subclassResponsibility!

{XnRegion} unionWith: other {XnRegion unused}
	self subclassResponsibility! !

!CompositeRegion methodsFor: 'testing'!

{UInt32} hashForEqual
	self subclassResponsibility!

{BooleanVar} hasMember: atPos {Position unused}
	self subclassResponsibility!

{BooleanVar} isEmpty
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}
	self subclassResponsibility!

{BooleanVar} isFinite
	self subclassResponsibility!

{BooleanVar} isFull	

	self subclassResponsibility!

{BooleanVar} isSimple
	self subclassResponsibility! !

!CompositeRegion methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	^myCS!

{XnRegion} subRegion: key {Position}
	"the region in a subspace"
	self subclassResponsibility! !

!CompositeRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCS _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCS.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CompositeRegion class
	instanceVariableNames: ''!

(CompositeRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!CompositeRegion class methodsFor: 'pseudo constructors'!

{CompositeRegion} compositeGapRegion: cs {CoordinateSpace} with: key {Position} with: region {XnRegion}
	region isFull ifTrue:
		[^FullCompositeRegion create: cs]
	ifFalse: [((cs cast: CompositeSpace) subSpaces count = 2 and: [region isEmpty]) ifTrue:
		[ | otherkey {Position} |
		otherkey _ ((cs cast: CompositeSpace) subSpaces domain
				minus: (key asRegion)) stepper get cast: Position.
		^CompositeSliceRegion create: cs
			with: otherkey
			with: (((cs cast: CompositeSpace) subSpaces get: otherkey) emptyRegion)]
	ifFalse:
		[^CompositeGapRegion create: cs with: key with: region]]!

{CompositeRegion} compositeSliceRegion: cs {CoordinateSpace} with: key {Position} with: region {XnRegion}
	region isEmpty
		ifTrue: [^EmptyCompositeRegion create: cs]
		ifFalse: [^CompositeSliceRegion create: cs with: key with: region]!

{CompositeRegion} compositeTwoGapRegion: cs {CoordinateSpace} with: key1 {Position} with: region1 {XnRegion} with: key2 {Position} with: region2 {XnRegion}
	| keys {TableStepper} table {MuTable} |
	region1 isFull
		ifTrue: [^CompositeRegion compositeGapRegion: cs with: key2 with: region2].
	region2 isFull
		ifTrue: [^CompositeRegion compositeGapRegion: cs with: key1 with: region1].
	table _ MuTable make: (cs cast: CompositeSpace) subSpaces coordinateSpace.
	(keys _ (cs cast: CompositeSpace) subSpaces stepper) forEach: [ :sub {CoordinateSpace} |
		((keys position isEqual: key1) not and: [(keys position isEqual: key2) not]) ifTrue:
			[table at: keys position introduce: sub fullRegion]].
	table at: key1 introduce: region1.
	table at: key2 introduce: region2.
	^CompositeRegion make: cs with: table asImmuTable!

{CompositeRegion} compositeTwoSliceRegion: cs {CoordinateSpace} with: key1 {Position} with: region1 {XnRegion} with: key2 {Position} with: region2 {XnRegion}
	| keys {TableStepper} table {MuTable} |
	region1 isEmpty
		ifTrue: [^CompositeRegion compositeSliceRegion: cs with: key2 with: region2].
	region2 isEmpty
		ifTrue: [^CompositeRegion compositeSliceRegion: cs with: key1 with: region1].
	table _ MuTable make: (cs cast: CompositeSpace) subSpaces coordinateSpace.
	(keys _ (cs cast: CompositeSpace) subSpaces stepper) forEach: [ :sub {CoordinateSpace} |
		((keys position isEqual: key1) not and: [(keys position isEqual: key2) not]) ifTrue:
			[table at: keys position introduce: sub emptyRegion]].
	table at: key1 introduce: region1.
	table at: key2 introduce: region2.
	^CompositeRegion make: cs with: table asImmuTable!

{CompositeRegion} emptyCompositeRegion: cs {CoordinateSpace}
	^EmptyCompositeRegion create: cs!

{CompositeRegion} fullCompositeRegion: cs {CoordinateSpace}
	^FullCompositeRegion create: cs!

make: cs {CoordinateSpace} with: regions {ImmuTable of: XnRegion}
	| empties {IntegerVar} fulls {IntegerVar} empty {Position} full {Position} neither {Position} subs {TableStepper} |
	empties _ fulls _ IntegerVar0.
	empty _ full _ neither _ NULL.
	(subs _ regions stepper) forEach: [ :sub {XnRegion} |
		sub isEmpty ifTrue:
			[empties _ empties + 1. empty _ subs position]
		ifFalse: [sub isFull ifTrue:
			[fulls _ fulls + 1. full _ subs position]
		ifFalse: [neither == NULL ifTrue:
			[neither _ subs position]
		ifFalse:
			[^ActualCompositeRegion create: cs with: regions]]]].
	neither == NULL ifTrue:
		[empties = IntegerVar0 ifTrue:
			[^FullCompositeRegion create: cs].
		fulls = IntegerVar0 ifTrue:
			[^EmptyCompositeRegion create: cs].
		fulls = 1 ifTrue:
			[^CompositeSliceRegion create: cs with: full with: ((regions get: full) cast: XnRegion)].
		empties = 1 ifTrue:
			[^CompositeGapRegion create: cs with: empty with: ((regions get: empty) cast: XnRegion)].
		^ActualCompositeRegion create: cs with: regions].
	empties = IntegerVar0 ifTrue:
		[^CompositeGapRegion create: cs with: neither with: ((regions get: neither) cast: XnRegion)].
	fulls = IntegerVar0 ifTrue:
		[^CompositeSliceRegion create: cs with: neither with: ((regions get: neither) cast: XnRegion)].
	^ActualCompositeRegion create: cs with: regions! !