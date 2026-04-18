'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:08 pm'!

CrossRegion subclass: #CrossDistinction
	instanceVariableNames: '
		mySpace {CrossSpace}
		myDimension {Int32}
		mySubDistinction {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!

(CrossDistinction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!CrossDistinction methodsFor: 'enumerating'!

{IntegerVar} count
	
	| result {IntegerVar} |
	result := 1.
	Int32Zero almostTo: mySpace axisCount do: [:i {Int32} |
		result := result * (self projection: i) count].
	^result!

{ScruSet of: XnRegion} distinctions

	^ImmuSet make with: self!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL} 

	^Stepper itemStepper: self! !

!CrossDistinction methodsFor: 'private: creation'!

create: space {CrossSpace} with: dimension {Int32} with: subDistinction {XnRegion}

	super create.
	mySpace := space.
	myDimension := dimension.
	mySubDistinction := subDistinction! !

!CrossDistinction methodsFor: 'testing'!

{BooleanVar} hasMember: atPos {Position} 

	^mySubDistinction hasMember: ((atPos cast: Tuple) coordinate: myDimension)!

{BooleanVar} isEmpty

	^false!

{BooleanVar} isEnumerable: order {OrderSpec unused default: NULL}
	
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}
	
	MarkM shouldImplement!

{BooleanVar} isFinite
	
	Int32Zero almostTo: mySpace axisCount do: [:i {Int32} |
		(self projection: i) isFinite ifFalse:
			[^false]].
	^true!

{BooleanVar CLIENT} isFull

	^myDimension = -1!

{BooleanVar} isSimple
	
	^true! !

!CrossDistinction methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	^mySpace!

{Int32} distinctDimension

	^myDimension!

{PtrArray of: XnRegion} projections
	
	| result {PtrArray of: XnRegion} |
	result := PtrArray nulls: mySpace axisCount.
	Int32Zero almostTo: result count do: [:i {Int32} |
		result at: i store: (mySpace axis: i) fullRegion].
	result at: myDimension store: mySubDistinction.
	^result!

{XnRegion} subDistinction

	^mySubDistinction! !

!CrossDistinction methodsFor: 'operations'!

{XnRegion} asSimpleRegion

	^self!

{XnRegion} complement

	^CrossDistinction make: mySpace with: myDimension with: mySubDistinction complement!

{XnRegion} intersect: other {XnRegion unused} 

	MarkM shouldImplement!

{XnRegion} unionWith: other {XnRegion unused} 

	MarkM shouldImplement! !

!CrossDistinction methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 

	MarkM shouldImplement! !

!CrossDistinction methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << ${.
	Int32Zero almostTo: mySpace count do: [ :i {Int32} |
		i > Int32Zero ifTrue:
			[oo << ' x '].
		i = myDimension
			ifTrue: [oo << mySubDistinction]
			ifFalse: [oo << $*]].
	oo << $}! !

!CrossDistinction methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySpace _ receiver receiveHeaper.
	myDimension _ receiver receiveInt32.
	mySubDistinction _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySpace.
	xmtr sendInt32: myDimension.
	xmtr sendHeaper: mySubDistinction.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CrossDistinction class
	instanceVariableNames: ''!

(CrossDistinction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!CrossDistinction class methodsFor: 'pseudoconstructors'!

{CrossRegion} make: space {CrossSpace} with: dimension {Int32} with: subDistinction {XnRegion}

	((space axis: dimension) isEqual: subDistinction coordinateSpace) assert: 'Spaces must match'.
	subDistinction isDistinction assert: 'Must be distinction'.
	subDistinction isEmpty ifTrue:
		[^space emptyRegion cast: CrossRegion].
	subDistinction isFull ifTrue:
		[^space fullRegion cast: CrossRegion].
	^self create: space with: dimension with: subDistinction! !