'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:52 pm'!

Mapping subclass: #EmptyMapping
	instanceVariableNames: '
		myCS {CoordinateSpace}
		myRS {CoordinateSpace}'
	classVariableNames: '
		LastEmptyMapping {Mapping} 
		LastEmptyMappingCoordinateSpace {CoordinateSpace} 
		LastEmptyMappingRangeSpace {CoordinateSpace} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces'!

(EmptyMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class EmptyMapping */
friend SPTR(Mapping) emptyMapping (CoordinateSpace * cs, CoordinateSpace * rs);
';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!EmptyMapping methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^myCS!

{XnRegion} domain

	^ self coordinateSpace emptyRegion.!

{Dsp | NULL} fetchDsp
	^NULL!

{BooleanVar} isComplete

	^true!

{BooleanVar} isIdentity

	^false!

{XnRegion} range
	^ self rangeSpace emptyRegion.!

{CoordinateSpace} rangeSpace

	^myRS!

{ImmuSet of: Mapping} simpleMappings

	^ ImmuSet make!

{ImmuSet of: Mapping} simpleRegionMappings

	^ ImmuSet make with: self.! !

!EmptyMapping methodsFor: 'transforming'!

{Position} inverseOf: pos {Position unused}

	Heaper BLAST: #NotInRange.
	^ NULL!

{XnRegion} inverseOfAll: reg {XnRegion unused}

	^ self coordinateSpace emptyRegion.!

{Position} of: pos {Position unused}

	Heaper BLAST: #NotInDomain.
	^ NULL!

{XnRegion} ofAll: reg {XnRegion unused}

	^self rangeSpace emptyRegion.! !

!EmptyMapping methodsFor: 'private: private creation'!

create: cs {CoordinateSpace} with: rs {CoordinateSpace}
	super create.
	myCS _ cs.
	myRS _ rs.! !

!EmptyMapping methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << self getCategory name.
	stream << '()'! !

!EmptyMapping methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^#cat.U.EmptyMapping hashForEqual!

{BooleanVar} isEqual: other {Heaper}
	"This, and the CompositeMapping version, don't check CoordinateSpaces.  Should they?"
	^(other isKindOf: EmptyMapping)! !

!EmptyMapping methodsFor: 'operations'!

{Mapping} appliedAfter: dsp {Dsp unused}

	^self!

{Mapping} inverse

	^Mapping make.CoordinateSpace: self rangeSpace
		with.CoordinateSpace: self domainSpace!

{Mapping} preCompose: dsp {Dsp unused}

	^ self!

{Mapping} restrict: region {XnRegion unused}

	^self!

{Mapping} restrictRange: region {XnRegion unused}

	^self!

{Mapping} transformedBy: dsp {Dsp unused}

	^ self! !

!EmptyMapping methodsFor: 'protected: protected'!

{Mapping} fetchCombine: mapping {Mapping}

	^ mapping! !

!EmptyMapping methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCS _ receiver receiveHeaper.
	myRS _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCS.
	xmtr sendHeaper: myRS.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EmptyMapping class
	instanceVariableNames: ''!

(EmptyMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class EmptyMapping */
friend SPTR(Mapping) emptyMapping (CoordinateSpace * cs, CoordinateSpace * rs);
';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!EmptyMapping class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	LastEmptyMapping _ NULL.
	LastEmptyMappingCoordinateSpace _ NULL.
	LastEmptyMappingRangeSpace _ NULL.! !

!EmptyMapping class methodsFor: 'pseudoconstructor'!

{Mapping} make: cs {CoordinateSpace} with: rs {CoordinateSpace}
	(LastEmptyMapping == NULL
	 or: [(cs isEqual: LastEmptyMappingCoordinateSpace) not
	 or: [(rs isEqual: LastEmptyMappingRangeSpace) not]])
		ifTrue:
			[LastEmptyMappingCoordinateSpace _ cs.
			LastEmptyMappingRangeSpace _ rs.
			LastEmptyMapping _ EmptyMapping create: cs with: rs].
	^ LastEmptyMapping! !