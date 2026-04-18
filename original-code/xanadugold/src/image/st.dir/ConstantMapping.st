'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:52 pm'!

Mapping subclass: #ConstantMapping
	instanceVariableNames: '
		myCoordinateSpace {CoordinateSpace}
		myValues {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces'!

(ConstantMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!ConstantMapping methodsFor: 'creation'!

create: cs {CoordinateSpace} with: values {XnRegion}
	super create.
	myCoordinateSpace _ cs.
	myValues _ values! !

!ConstantMapping methodsFor: 'transforming'!

{Position} inverseOf: pos {Position unused}

	Heaper BLAST: #MultiplePreImages.
	^NULL!

{XnRegion} inverseOfAll: reg {XnRegion}

	(reg intersects: myValues)
		ifTrue: [^self domain]
		ifFalse: [^self coordinateSpace emptyRegion]!

{Position} of: pos {Position unused}

	(myValues isFinite and: [myValues count == 1])
		ifTrue: [^myValues theOne]
		ifFalse: [Heaper BLAST: #MultipleImages].
	^NULL "fodder"!

{XnRegion} ofAll: reg {XnRegion}

	reg isEmpty
		ifTrue: [^self rangeSpace emptyRegion]
		ifFalse: [^self range]! !

!ConstantMapping methodsFor: 'accessing'!

{Mapping} appliedAfter: dsp {Dsp unused}

	^self!

{CoordinateSpace} coordinateSpace

	^ myCoordinateSpace!

{XnRegion} domain
	
	^myCoordinateSpace fullRegion!

{Dsp | NULL} fetchDsp
	^ NULL!

{BooleanVar} isComplete

	^true!

{BooleanVar} isIdentity

	^false!

{Mapping} preCompose: dsp {Dsp}

	^Mapping make.CoordinateSpace: myCoordinateSpace 
		with.Region: (dsp ofAll: myValues)!

{XnRegion} range
	^myValues!

{CoordinateSpace} rangeSpace

	^myValues coordinateSpace!

{ImmuSet of: Mapping} simpleMappings
	^ ImmuSet make with: self.!

{ImmuSet of: Mapping} simpleRegionMappings

	^ ImmuSet make with: self.!

{Mapping} transformedBy: dsp {Dsp}

	^Mapping make.CoordinateSpace: myCoordinateSpace 
		with.Region: (dsp ofAll: myValues)! !

!ConstantMapping methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myValues << ')'! !

!ConstantMapping methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myCoordinateSpace hashForEqual + myValues hashForEqual!

{BooleanVar} isEqual: other {Heaper}
	other
		cast: ConstantMapping into: [:cm |
			^(cm coordinateSpace isEqual: myCoordinateSpace)
			 and: [cm values isEqual: myValues]]
		others: [^false].
	^false "fodder"! !

!ConstantMapping methodsFor: 'private: private'!

{XnRegion} values
	^myValues! !

!ConstantMapping methodsFor: 'operations'!

{Mapping} inverse

	^(Mapping make.CoordinateSpace: self rangeSpace
		with.Region: self domainSpace fullRegion) restrict: self range!

{Mapping} restrict: region {XnRegion}

	^SimpleMapping restrictTo: region with: self!

{Mapping} restrictRange: region {XnRegion}

	^Mapping make.CoordinateSpace: myCoordinateSpace
		with.Region: (myValues intersect: region)! !

!ConstantMapping methodsFor: 'protected'!

{Mapping} fetchCombine: aMapping {Mapping}

	aMapping 
		cast: ConstantMapping into: [:cm |
			^Mapping make.CoordinateSpace: self coordinateSpace
				with.Region: (myValues unionWith: cm values)]
		others: [^NULL].
	^NULL "fodder"! !

!ConstantMapping methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCoordinateSpace _ receiver receiveHeaper.
	myValues _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCoordinateSpace.
	xmtr sendHeaper: myValues.! !