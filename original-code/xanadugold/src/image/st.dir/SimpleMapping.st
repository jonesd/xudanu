'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:57 pm'!

Mapping subclass: #SimpleMapping
	instanceVariableNames: '
		myRegion {XnRegion}
		myMapping {Mapping}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!

(SimpleMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class SimpleMapping */
friend SPTR(Mapping) restrictTo (XnRegion*, Mapping*);
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SimpleMapping methodsFor: 'accessing'!

{Mapping} appliedAfter: dsp {Dsp}

	^SimpleMapping restrictTo: (dsp inverseOfAll: myRegion)
		with: (myMapping appliedAfter: dsp)!

{CoordinateSpace} coordinateSpace

	^myRegion coordinateSpace!

{XnRegion} domain
	^ myRegion!

{Dsp | NULL} fetchDsp
	^ myMapping fetchDsp!

{BooleanVar} isComplete

	^myMapping isComplete!

{BooleanVar} isIdentity

	^false!

{Mapping} preCompose: dsp {Dsp}

	^SimpleMapping restrictTo: myRegion with: (myMapping preCompose: dsp)!

{XnRegion} range
	^ myMapping ofAll: myRegion!

{CoordinateSpace} rangeSpace
	
	^ myMapping rangeSpace!

{ImmuSet of: Mapping} simpleMappings

	^ ImmuSet make with: self!

{ImmuSet of: Mapping} simpleRegionMappings

	myMapping domain isSimple 
		ifTrue:
			[^ImmuSet make with: myMapping]
		ifFalse:
			[ | simpleMappings {MuSet} | 
			simpleMappings _ MuSet make.
			myMapping domain simpleRegions forEach: [:simpleRegion {XnRegion} |
				simpleMappings store: (myMapping restrict: simpleRegion)].
			^ImmuSet make.MuSet: simpleMappings]!

{Mapping} transformedBy: dsp {Dsp}

	^SimpleMapping restrictTo: myRegion
		with: (myMapping transformedBy: dsp)! !

!SimpleMapping methodsFor: 'transforming'!

{Position} inverseOf: pos {Position}

	| result {Position} |
	result _ myMapping inverseOf: pos.
	(myRegion hasMember: result)
		ifTrue: [^result]
		ifFalse: [Heaper BLAST: #NotInRange].
	^NULL "fodder"!

{XnRegion} inverseOfAll: reg {XnRegion}

	^(myMapping inverseOfAll: reg) intersect: myRegion!

{Position} of: pos {Position}

	(self domain hasMember: pos)
		ifTrue: [^ myMapping of: pos]
		ifFalse: [Heaper BLAST: #NotInDomain].
	^NULL "fodder"!

{XnRegion} ofAll: reg {XnRegion}

	^myMapping ofAll: (self domain intersect: reg)! !

!SimpleMapping methodsFor: 'operations'!

{Mapping} inverse

	^myMapping inverse restrictRange: myRegion!

{Mapping} restrict: region {XnRegion}
	
	^SimpleMapping restrictTo: (myRegion intersect: region) with: myMapping!

{Mapping} restrictRange: region {XnRegion}
	
	^SimpleMapping restrictTo: myRegion with: (myMapping restrictRange: region)! !

!SimpleMapping methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << myMapping << ' on ' << myRegion! !

!SimpleMapping methodsFor: 'private: private creation'!

create: region {XnRegion} with: mapping {Mapping}
	super create.
	myRegion _ region.
	myMapping _ mapping.! !

!SimpleMapping methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myRegion hashForEqual + myMapping hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: SimpleMapping into: [:sm |
			^(sm domain isEqual: myRegion)
			 and: [sm mapping isEqual: myMapping]]
		others: [^false].
	^false "fodder"! !

!SimpleMapping methodsFor: 'private: private'!

{Mapping} mapping
	^myMapping! !

!SimpleMapping methodsFor: 'protected'!

{Mapping} fetchCombine: mapping {Mapping}

	(mapping isEqual: myMapping) ifTrue: [^mapping].
	mapping
		cast: SimpleMapping into: [:other |
			| both {Mapping} |
			(other mapping isEqual: myMapping) ifTrue:
				[^SimpleMapping restrictTo: (other domain unionWith: myRegion) with: myMapping]
			ifFalse: [((other domain isEqual: myRegion)
					and: [(both _ myMapping fetchCombine: other mapping) ~~ NULL]) ifTrue:
				[^SimpleMapping restrictTo: myRegion with: both]]]
		others: [].
	^NULL! !

!SimpleMapping methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRegion _ receiver receiveHeaper.
	myMapping _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRegion.
	xmtr sendHeaper: myMapping.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SimpleMapping class
	instanceVariableNames: ''!

(SimpleMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class SimpleMapping */
friend SPTR(Mapping) restrictTo (XnRegion*, Mapping*);
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SimpleMapping class methodsFor: 'pseudo constructors'!

{Mapping} restrictTo: region {XnRegion} with: mapping {Mapping}
	region isEmpty
		ifTrue: [^EmptyMapping make: mapping domainSpace
								 with: mapping rangeSpace]
		ifFalse: [^SimpleMapping create: region with: mapping]! !