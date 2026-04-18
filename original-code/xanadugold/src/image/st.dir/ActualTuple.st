'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:07 pm'!

Tuple subclass: #ActualTuple
	instanceVariableNames: 'myCoordinates {PtrArray of: Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
ActualTuple comment:
'Default implementation of position in a crossed coordinate space. NOT.A.TYPE'!

(ActualTuple getOrMakeCxxClassDescription)
	friends:
'friend class GenericCrossDsp;
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualTuple methodsFor: 'accessing'!

{XnRegion} asRegion
	
	| result {PtrArray of: XnRegion} |
	result := PtrArray nulls: myCoordinates count.
	Int32Zero almostTo: result count do: [:i {Int32} |
		result at: i store: (self coordinate: i) asRegion].
	^GenericCrossRegion make: (self coordinateSpace cast: CrossSpace) with: 1 with: result!

{PtrArray of: Position} coordinates
	
	^myCoordinates copy cast: PtrArray!

{CoordinateSpace} coordinateSpace
	
	| result {PtrArray of: CoordinateSpace} |
	result := PtrArray nulls: myCoordinates count.
	Int32Zero almostTo: result count do: [:i {Int32} |
		result at: i store: (self coordinate: i) coordinateSpace].
	^CrossSpace make: result!

{Int32} count
	^ myCoordinates count!

{Position} positionAt: dimension {Int32}
	^ (myCoordinates fetch: dimension) cast: Position! !

!ActualTuple methodsFor: 'comparing'!

{UInt32} actualHashForEqual
	
	^myCoordinates contentsHash!

{BooleanVar} isEqual: other {Heaper}

	other cast: ActualTuple into: [ :actual |
		^myCoordinates contentsEqual: actual secretCoordinates]
	cast: Tuple into: [ :tuple |
		^myCoordinates contentsEqual: tuple coordinates]
	others:
		[^false].
	^ false "compiler fodder"! !

!ActualTuple methodsFor: 'private: creation'!

create: coordinates {PtrArray of: Position}

	super create.
	myCoordinates := coordinates! !

!ActualTuple methodsFor: 'private: accessing'!

{PtrArray of: Position} secretCoordinates
	"The internal array of coordinates. Do not modify this array!!"
	
	^myCoordinates! !

!ActualTuple methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCoordinates _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCoordinates.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualTuple class
	instanceVariableNames: ''!

(ActualTuple getOrMakeCxxClassDescription)
	friends:
'friend class GenericCrossDsp;
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualTuple class methodsFor: 'pseudoconstructors'!

{Tuple} make: coordinates {PtrArray of: Position}

	^self create: coordinates! !