'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:50 pm'!

MuArray subclass: #ActualArray
	instanceVariableNames: '
		elements {PtrArray}
		tally {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(ActualArray getOrMakeCxxClassDescription)
	friends:
'/* friends for class ActualArray */
friend class AscendingArrayStepper;
friend SPTR(MuArray) MuArray::make(IntegerVar);';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualArray methodsFor: 'testing'!

{UInt32} fastHash
	^tally + #cat.U.ActualArray hashForEqual!

{BooleanVar} isEmpty
	^tally == UInt32Zero! !

!ActualArray methodsFor: 'accessing'!

{Heaper} atInt: index {IntegerVar} store: value {Heaper} 
	"store the new value at the specified position.  Note that this is an insertion iff
	the index is the same as the tally (that is, we're adding at the first empty position
	at the end of the array)."
	
	| reali {UInt32} old {Heaper} |
	value == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	(index < IntegerVar0 or: [index > tally])
		ifTrue: [Heaper BLAST: #NotInDomain].
	reali _ index DOTasLong.
	reali = tally
		ifTrue: 
			[reali >= elements count ifTrue: [self enlarge].
			tally _ tally + 1].
	old _ elements fetch: reali.
	elements at: reali store: value.
	^ old!

{CoordinateSpace} coordinateSpace

	^IntegerSpace make!

{IntegerVar} count

	^tally!

{XnRegion} domain

	^IntegerRegion make: IntegerVar0 with: tally!

{IntegerVar} highestIndex
	^ tally - 1!

{Heaper} intFetch: index {IntegerVar} 
	| idx {UInt32 register} |
	((idx _ index DOTasLong) >= tally or: [index < IntegerVar0])
		ifTrue: [^NULL]
		ifFalse: [^elements fetch: idx]!

{BooleanVar} intWipe: index {IntegerVar} 
	"Remove if the index is the last thing in the table. 
	 Blast if the index is some other element of the table.  
	 *Ignore* the request if it is any element not in the table."
	
	| reali {Int32 register} |
	reali _ index DOTasLong.
	reali == (tally - 1) ifTrue:
		[elements at: reali store: NULL.
		tally _ tally - 1.
		^true].
	"Now the error that results from a specialized implementation."
	(reali >= Int32Zero and: [reali < tally]) ifTrue: [Heaper BLAST: #IncompleteAbstraction].
	^false!

{IntegerVar} lowestIndex

	^ IntegerVar0!

{ScruTable} offsetSubTableBetween: startIndex {IntegerVar} 
	with: stopIndex {IntegerVar} 
	with: firstIndex {IntegerVar} 

	^super offsetSubTableBetween: startIndex with: stopIndex with: firstIndex!

{ScruTable} subTable: reg {XnRegion} 
	
	^self subTableBetween: (reg cast: IntegerRegion) start 
		with: (reg cast: IntegerRegion) stop!

{ScruTable} subTableBetween: start {IntegerVar} with: stop {IntegerVar} 
	| begin {IntegerVar} end {IntegerVar} newArray {MuArray} reg {XnRegion} |
	start < IntegerVar0 ifTrue: [begin _ IntegerVar0] ifFalse: [begin _ start].
	stop > self count
		ifTrue: [end _ self count]
		ifFalse: [end _ stop].
	newArray _ MuArray make.IntegerVar: end - begin.
	reg _ IntegerRegion make: begin with: end.
	reg stepper forEach: [:pos {IntegerPos} |
		newArray atInt: (pos asIntegerVar - begin)
					introduce: (self intFetch: pos asIntegerVar)].
	begin > IntegerVar0
		ifTrue: [^OffsetScruArray make: newArray with: (IntegerMapping make: begin)]
		ifFalse: [^newArray]! !

!ActualArray methodsFor: 'creation'!

{ScruTable} copy
	^ ActualArray create: (elements copy cast: PtrArray) with: tally!

{ScruTable} emptySize: size {IntegerVar unused}

	^MuArray make.IntegerVar: (elements count)! !

!ActualArray methodsFor: 'private: creation'!

create
	"The optional argument just hints at the number of elements
	 to eventually be added.  It makes no difference semantically."
	super create.
	elements _ PtrArray nulls: 4.
	tally _ UInt32Zero!

create.IntegerVar: size {IntegerVar} 
	"The optional argument just hints at the number of elements
	 to eventually be added.  It makes no difference semantically."
	| newSize {UInt32} |
	super create.
	size > 4 ifTrue: [newSize _ size DOTasLong] ifFalse: [newSize _ 4].
	elements _ PtrArray nulls: newSize.
	tally _ UInt32Zero!

create: newElems {PtrArray of: Heaper} with: newTally {UInt32} 
	super create.
	elements _ newElems.
	tally _ newTally!

{void} destruct
	elements destroy.
	elements _ NULL.
	super destruct! !

!ActualArray methodsFor: 'runs'!

{XnRegion} runAtInt: anIdx {IntegerVar} 
	| idx {IntegerVar} lastObj {Heaper} notDone {BooleanVar} |
	
	idx _ anIdx.
	(idx < IntegerVar0 or: [idx >= tally]) ifTrue:
		[ ^ IntegerRegion make ].
	lastObj _ self intGet: idx.
	notDone _ true.
	[idx < tally and: [notDone]] whileTrue:
		[((self intGet: idx) isEqual: lastObj)
			ifTrue: [ idx _ idx + 1 ]
			ifFalse: [ notDone _ false ]].
	^ IntegerRegion make: anIdx with: idx! !

!ActualArray methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name.
	self printOnWithSimpleSyntax: aStream
		with: '['
		with: ','
		with: ']'! !

!ActualArray methodsFor: 'private: private'!

{PtrArray} elementsArray
	"return the elements array for rapid processing"
	^ elements!

{UInt32} endOffset
	"return the size of the elements array for rapid processing"
	^ tally-1!

{void} enlarge
	"Enlarge the receiver to contain more slots filled with nil."

	| newElements {PtrArray of: Heaper} oldElements {PtrArray wimpy of: Heaper} |
	newElements _ (elements copyGrow: elements count) cast: PtrArray.
	"Just for the hell of it, I make this robust for asynchronous readers..."
	oldElements _ elements.
	elements _ newElements.
	oldElements destroy!

{UInt32} maxElements
	"return the size of the elements array for rapid processing"
	^ elements count!

{UInt32} startOffset
	"return the size of the elements array for rapid processing"
	^ UInt32Zero! !

!ActualArray methodsFor: 'smalltalk: private:'!

{void} inspect
	^InspectorView open: (IntegerTableInspector inspect: self)!

{IntegerVar} search: item {Integer}

	| low {IntegerVar} high {IntegerVar} curr {IntegerVar} elem {IntegerVar} |
	self isEmpty ifTrue: [^ Integer IntegerVar: 0].
	low _ self lowestIndex.
	high _ self highestIndex.
	[high >= low] whileTrue: [
		curr _ (high + low // 2).
		(item > (elem _ (self fetch: curr)))
			ifTrue: [low _ curr + 1]
			ifFalse: [item == elem 
				ifTrue: [low _ (high _ curr) + 1]
				ifFalse: [high _ curr - 1]]].
	^ high! !

!ActualArray methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL} 

	order == NULL
		ifTrue: [^AscendingArrayStepper
				make: self
				with: IntegerVar0
				with: tally - 1]
		ifFalse: [(order followsInt: 1 with: IntegerVar0)
				ifTrue: [^AscendingArrayStepper make: self]
				ifFalse: [^IntegerTableStepper make: self with: order]]! !

!ActualArray methodsFor: 'overload junk'!

{Heaper} at: key {Position} store: value {Heaper} 

	^ self atInt: (key cast: IntegerPos) asIntegerVar store: value!

{Heaper} fetch: key {Position} 

	^ self intFetch: ((key cast: IntegerPos) asIntegerVar)!

{XnRegion} runAt: anIdx {Position} 
	^ self runAtInt: ((anIdx cast: IntegerPos) asIntegerVar)!

{BooleanVar} wipe: key {Position}
	^ self intWipe: ((key cast: IntegerPos) asIntegerVar)! !

!ActualArray methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	elements _ receiver receiveHeaper.
	tally _ receiver receiveUInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: elements.
	xmtr sendUInt32: tally.! !