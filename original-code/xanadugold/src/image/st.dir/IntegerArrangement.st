'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:14 pm'!

Arrangement subclass: #IntegerArrangement
	instanceVariableNames: '
		myOrdering {OrderSpec}
		myRegion {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!

(IntegerArrangement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!IntegerArrangement methodsFor: 'accessing'!

{void} copyElements: toArray {PrimArray} with: toDsp {Dsp}
	with: fromArray {PrimArray} with: fromArrange {Arrangement} with: fromRegion {XnRegion}
	
	| other {IntegerArrangement} start {Int32} stop {Int32} toStart {Int32} |
	other _ fromArrange cast: IntegerArrangement.
	(myOrdering isEqual: other ordering) ifFalse: [self unimplemented].
	(myRegion isSimple and: [other region isSimple and: [fromRegion isSimple]]) ifFalse: [self unimplemented].
	self knownBug.  "Assume ascending for the moment."
	start _ (fromArrange indexOf: (fromRegion chooseOne: myOrdering)) DOTasLong.
	stop _ (fromArrange indexOf: (fromRegion chooseOne: myOrdering reversed)) DOTasLong.
	toStart _ (self indexOf: (toDsp of: (fromRegion chooseOne: myOrdering))) DOTasLong.
	"stop < start ifTrue: [| tmp {Int32} | tmp _ start.  start _ stop.  stop _ tmp]."
	toArray at: toStart
		storeMany: fromArray 
		with: stop + 1 - start
		with: start!

{IntegerVar} indexOf: position {Position}
	"Return the index of position into my Region according to my OrderSpec."

	| sum {IntegerVar} intPos {IntegerVar} |
	sum _ IntegerVar0.
	intPos _ (position cast: IntegerPos) asIntegerVar.
	(myRegion simpleRegions: myOrdering) forEach: 
		[:region {IntegerRegion} |
		(region hasIntMember: intPos)
			ifTrue: [^sum + (intPos - ((region chooseOne: myOrdering) cast: IntegerPos) asIntegerVar) abs]
			ifFalse: [sum _ sum + region count]].
	Heaper BLAST: #NotInTable.
	^ -1 "compiler fodder"!

{IntegerRegion} indicesOf: region {XnRegion}
	"Return the region of all the indices corresponding to positions in region."

	Someone shouldImplement.
	^NULL "fodder"!

{XnRegion} keysOf: start {Int32} with: stop {Int32}
	"Return the region that corresponds to a range of indices."

	| offset {Int32} left {Int32} right {Int32} | 
	offset _ start.
	left _ -1.
	(myRegion simpleRegions: myOrdering) forEach: 
		[:region {XnRegion} |
		region count <= offset 
			ifTrue: [offset _ offset - region count DOTasLong]
			ifFalse:
				[left == -1 
					ifTrue: 
						[left _ ((region chooseOne: myOrdering) cast: IntegerPos) asIntegerVar DOTasLong + offset.
						offset _ stop - (start - offset).
						offset <= region count DOTasLong ifTrue: 
							[^IntegerRegion make: left 
									with: (((region chooseOne: myOrdering) cast: IntegerPos) asIntegerVar + offset)]]
					ifFalse:
						[right _ ((region chooseOne: myOrdering) cast: IntegerPos) asIntegerVar DOTasLong + offset.
						^IntegerRegion make: left with: right]]].
	Heaper BLAST: #NotInTable.
	^ NULL "compiler fodder"!

{OrderSpec} ordering
	^myOrdering!

{XnRegion} region
	^myRegion! !

!IntegerArrangement methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myRegion << ', ' << myOrdering << ')'! !

!IntegerArrangement methodsFor: 'protected: creation'!

create: region {XnRegion} with: ordering {OrderSpec}
	super create.
	region isFinite ifFalse: [Heaper BLAST: #MustBeFinite].
	myRegion _ region cast: IntegerRegion.
	myOrdering _ ordering! !

!IntegerArrangement methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^ myOrdering hashForEqual + myRegion hashForEqual!

{UInt32} hashForEqual
	^ myOrdering hashForEqual + myRegion hashForEqual!

{BooleanVar} isEqual: other {Heaper}
	other cast: IntegerArrangement
		  into: [:o {IntegerArrangement} |
		  	^ (myOrdering isEqual: o ordering) and: [myRegion isEqual: o region]]
		  others: [^ false].
	^ false "fodder"! !

!IntegerArrangement methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myOrdering _ receiver receiveHeaper.
	myRegion _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myOrdering.
	xmtr sendHeaper: myRegion.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerArrangement class
	instanceVariableNames: ''!

(IntegerArrangement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!IntegerArrangement class methodsFor: 'creation'!

make: region {XnRegion} with: ordering {OrderSpec} 
	^self create: region with: ordering! !