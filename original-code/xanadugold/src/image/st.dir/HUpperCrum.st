'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:08 pm'!

HistoryCrum subclass: #HUpperCrum
	instanceVariableNames: '
		hcut {TracePosition}
		hcrums {MuSet of: OPart}
		myBertCrum {BertCrum}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(HUpperCrum getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!HUpperCrum methodsFor: 'testing'!

{BooleanVar} inTrace: trace {TracePosition} 
	"Return true if the receiver can backfollow to trace."
	"This chase up the htree could terminate early if the trace equalled 
	the trace in the receiver. This would be correct except that 
	oplanes can be created with a particular trace, only part of which 
	actually get included in the real orgl with that trace."

	(hcut isLE: trace) ifTrue: 
		[hcrums stepper forEach: 
			[:oc {OPart} |
			(oc hCrum inTrace: trace) ifTrue: [^true]]]. 
	^false!

{BooleanVar} isEmpty
	"Return true if their are no upward pointers.  This is used
	 by OParts to determine if they can be forgotten."
	
	^hcrums isEmpty!

{Boolean} propagateBCrum: newBCrum {BertCrum} 
	"If bertCrum is leafward of newBCrum then change it and return true, 
	otherwise return false."

	(myBertCrum isLE: newBCrum)
		ifTrue: [^false]
		ifFalse: 
			[[(newBCrum isLE: myBertCrum) assert: 'Unrelated bertsCrums!!  Call dean.'] smalltalkOnly.
			myBertCrum _ newBCrum.
			^true]! !

!HUpperCrum methodsFor: 'accessing'!

{BertCrum} bertCrum
	"find the canopyCrum that goes with this hCrum."

	^myBertCrum!

{TracePosition} hCut
	^hcut!

{Mapping} mappingTo: trace {TracePosition} with: initial {Mapping}
	"return the mapping into the domain space of the given trace"
	| result {Mapping} |
	result _ Mapping make: initial coordinateSpace with: initial rangeSpace.
	(self inTrace: trace) ifTrue:
		[hcrums stepper forEach: [ :each {OPart} |
			result _ result combine: (each mappingTo: trace with: initial)]].
	^result!

{ImmuSet of: OPart} oParents
	^hcrums asImmuSet! !

!HUpperCrum methodsFor: 'updating'!

{void} addOParent: newCrum {OPart} 
	"If this hcrum represents a fork, then it must get its own canopy crum."
	"This routine could be drastically improved for orgl creation."

	self hack.
	[newCrum testHChild: self] smalltalkOnly.
	self updateBertCanopy: newCrum hCrum bertCrum.
	hcrums store: newCrum!

{void} removeOParent: newCrum {OPart} 
	"Make a history crum with no upward pointers."

	hcrums remove: newCrum.! !

!HUpperCrum methodsFor: 'filtering'!

{void} actualDelayedStoreBackfollow: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	"Apply filter on canopy"
	
	| newFinder {PropFinder} |
	
	"Simplify finder (to cut out no longer reachable tests)."
	newFinder _ finder pass: myBertCrum.
	
	"If things are still findable, recur on each child."
	newFinder isEmpty ifFalse:
		[hcrums stepper forEach: [:loaf {OPart} |
			loaf hCrum delayedStoreBackfollow: newFinder
				with: fossil
				with: recorder
				with: hCrumCache]]!

{BooleanVar} anyPasses: finder {PropFinder}
	(finder doesPass: myBertCrum) 
		ifTrue: [hcrums stepper forEach: 
					[:loaf {OPart} |
					(loaf hCrum anyPasses: finder)
						ifTrue: [^true]]].
	^false!

{void} ringDetectors: edition {FeEdition}

	self bertCrum isSensorWaiting ifTrue:
		[self oParents stepper forEach: [ :o {OPart} |
			o hCrum ringDetectors: edition]]! !

!HUpperCrum methodsFor: 'private:'!

{void} updateBertCanopy: bCrum {BertCrum} 
	"Make my bertCrum the join of its current value and bCrum."
	(myBertCrum isLE: bCrum) ifFalse: 
			[| oldBCrum {BertCrum} |
			oldBCrum _ myBertCrum.
			myBertCrum _ (myBertCrum computeJoin: bCrum) cast: BertCrum.
			(myBertCrum basicCast: BertCrum) ~~ (oldBCrum basicCast: BertCrum) ifTrue:
				[myBertCrum addPointer: self.
				oldBCrum removePointer: self]]! !

!HUpperCrum methodsFor: 'create'!

create: trace {TracePosition} with: canopy {BertCrum}
	super create.
	hcut _ trace.
	myBertCrum _ canopy.
	myBertCrum addPointer: self.
	hcrums _ MuSet make!

create: first {OPart} with: second {OPart} with: trace {TracePosition} 
	| set {MuSet} |
	super create.
	hcut _ trace.
	"self halt."
	set _ MuSet make: 2.
	set introduce: first.
	set introduce: second.
	hcrums _ set.
	myBertCrum _ first hCrum bertCrum.
	self updateBertCanopy: second hCrum bertCrum.
	myBertCrum addPointer: self! !

!HUpperCrum methodsFor: 'smalltalk:'!

inspectOrgls
	hcrums count == 1
		ifTrue: [hcrums stepper get inspect]
		ifFalse: [hcrums asOrderedCollection inspect]! !

!HUpperCrum methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	hcut _ receiver receiveHeaper.
	hcrums _ receiver receiveHeaper.
	myBertCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: hcut.
	xmtr sendHeaper: hcrums.
	xmtr sendHeaper: myBertCrum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HUpperCrum class
	instanceVariableNames: ''!

(HUpperCrum getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!HUpperCrum class methodsFor: 'smalltalk: create'!

make: something {Heaper}
	(something isKindOf: HUpperCrum) ifTrue: [^self make.HUpperCrum: something].
	(something isKindOf: BertCrum) ifTrue: [^self make.BertCrum: something].
	Heaper BLAST: #FatalError! !

!HUpperCrum class methodsFor: 'instance creation'!

make
	[Ent] USES.
	DiskManager consistent: [
	^HUpperCrum create: CurrentTrace fluidGet with: CurrentBertCrum fluidGet].
	^ NULL "Compiler fodder"!

make.BertCrum: bertCrum {BertCrum}
	^HUpperCrum create: CurrentTrace fluidGet with: bertCrum!

make.HUpperCrum: hcrum {HUpperCrum}
	^HUpperCrum create: hcrum hCut with: hcrum bertCrum! !