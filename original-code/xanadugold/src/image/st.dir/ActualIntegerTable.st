'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:51 pm'!

OberIntegerTable subclass: #ActualIntegerTable
	instanceVariableNames: '
		elements {PtrArray}
		start {IntegerVar}
		elemCount {UInt32}
		firstElem {UInt32}
		lastElem {UInt32}
		tally {UInt32}
		domainIsSimple {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
ActualIntegerTable comment:
'The IntegerTable class is intended to provide an integer indexed
table which is not constrained to be zero based.'!

(ActualIntegerTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class ActualIntegerTable */
friend class ITAscendingStepper;
friend class ITDescendingStepper;
friend class ITGenericStepper;';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualIntegerTable methodsFor: 'testing'!

{UInt32} fastHash
	^(((start DOTasLong bitXor: firstElem) bitXor: tally) bitXor: lastElem) + #cat.U.ActualIntegerTable hashForEqual!

{BooleanVar} includesIntKey: aKey {IntegerVar} 
	(aKey < self lowestIndex or: [aKey > self highestIndex])
		ifTrue: [^false]
		ifFalse: [domainIsSimple
				ifTrue: [^true]
				ifFalse: [^(elements fetch: aKey DOTasLong - start DOTasLong) ~~ NULL]]!

{BooleanVar} isEmpty
	^tally == UInt32Zero! !

!ActualIntegerTable methodsFor: 'accessing'!

{Heaper} atInt: index {IntegerVar} store: value {Heaper} 
	| reali {Int32} old {Heaper} |
	value == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	tally == UInt32Zero ifTrue: [start _ index].
	index - start >= elemCount
		ifTrue: [self enlargeAfter: index]
		ifFalse: [index < start ifTrue: [self enlargeBefore: index]].
	reali _ (index - start) DOTasLong.
	(old _ elements fetch: reali) == NULL ifTrue: [tally _ tally + 1].
	reali < firstElem ifTrue: [
		(firstElem - reali) > 1 ifTrue: [domainIsSimple _ false].
		firstElem _ reali].
	reali > lastElem ifTrue: [
		(reali - lastElem) > 1 ifTrue: [domainIsSimple _ false].
		lastElem _ reali].
	elements at: reali store: value.
	^ old!

{CoordinateSpace} coordinateSpace

	^IntegerSpace make!

{IntegerVar} count

	^tally!

{XnRegion} domain
	""
	"The domainIsSimple flag is used as an optimization in this method.  When it is True, I 
	stop looking after the first simple domain I find.  Therefore, when True, it MUST BE 
	CORRECT.  When it is False, I do a complete search, and set the flag if the domain
	turns out to be simple."

	| newReg {XnRegion} |
	self isEmpty
		ifTrue: [^IntegerRegion make]
		ifFalse: [domainIsSimple
				ifTrue: 
					[^IntegerRegion make: self lowestIndex with: self highestIndex + 1]
				ifFalse: 
					[newReg _ self generateDomain.
					newReg isSimple ifTrue: [domainIsSimple _ true].
					^newReg]]!

{IntegerVar} highestIndex
	tally == UInt32Zero ifTrue: [^start].
	^ start + lastElem!

{Heaper} intFetch: index {IntegerVar} 

	| idx {UInt32}|
	((idx _ (index-start) DOTasLong) >= elemCount or: [index < start])
		ifTrue: [^NULL]
		ifFalse: [^elements fetch: idx]!

{BooleanVar} intWipe: index {IntegerVar} 
	| reali {UInt32} wiped {BooleanVar} |
	wiped _ false.
	reali _ (index - start) DOTasLong.
	(reali > lastElem or: [reali < firstElem])
		ifFalse: 
			[(elements fetch: reali) ~~ NULL ifTrue: [tally _ tally - 1. wiped _ true].
			elements at: reali store: NULL.
			reali == firstElem
				ifTrue: [firstElem _ self firstElemAfter: reali]
				ifFalse: [reali == lastElem
						ifTrue: [lastElem _ self lastElemBefore: reali]
						ifFalse: [domainIsSimple _ false]]].
	^ wiped!

{IntegerVar} lowestIndex

	tally == UInt32Zero ifTrue: [^start].
	^ start + firstElem! !

!ActualIntegerTable methodsFor: 'creation'!

{ScruTable} copy
	^ ActualIntegerTable 
		create: (elements copy cast: PtrArray)
		with: start
		with: elemCount
		with: firstElem
		with: lastElem
		with: tally
		with: domainIsSimple!

create
	"The optional argument just hints at the number of elements
	 to eventually be added.  It makes no difference semantically."
	super create.
	elements _ PtrArray nulls: 8.
	start _ IntegerVar0.
	firstElem _ 7.
	lastElem _ UInt32Zero.
	elemCount _ 8.
	tally _ UInt32Zero.
	domainIsSimple _ true.!

create.IntegerVar: size {IntegerVar} 
	"The optional argument just hints at the number of elements
	 to eventually be added.  It makes no difference semantically."

	super create.
	size > IntegerVar0 ifTrue: [elemCount _ size DOTasLong] ifFalse: [elemCount _ 4].
	elements _ PtrArray nulls: elemCount.
	start _ IntegerVar0.
	tally _ UInt32Zero.
	firstElem _ elemCount - 1.
	lastElem _ UInt32Zero.
	domainIsSimple _ true.!

create: begin {IntegerVar} with: end {IntegerVar} 
	"Hint at the domain to be accessed (inclusive, exclusive)."

	super create.
	start _ begin.
	elemCount _ (end - start) DOTasLong.
	elemCount < 4 ifTrue: [elemCount _ 4].
	elements _ PtrArray nulls: elemCount.
	firstElem _ elemCount - 1.
	lastElem _ UInt32Zero.
	tally _ UInt32Zero.
	domainIsSimple _ true!

create: array {PtrArray} with: begin {IntegerVar} with: count {UInt32} with: first {UInt32} with: last {UInt32} with: aTally {UInt32} with: simple {BooleanVar}
	super create.
	elements  := array.
	start := begin.
	elemCount := count.
	firstElem := first.
	lastElem := last.
	tally := aTally.
	domainIsSimple := simple!

{void} destroy
	self getNextCOW == NULL ifTrue:
		[super destroy]!

{ScruTable} emptySize: size {IntegerVar unused}

	^IntegerTable make.IntegerVar: (self lowestIndex) with: (self highestIndex + 1)!

{ScruTable} offsetSubTableBetween: startIndex {IntegerVar} 
	with: stopIndex {IntegerVar} 
	with: firstIndex {IntegerVar} 
	"Copy the given range into a new IntegerTable. 
	The range is startIndex (inclusive) to stopIndex (exclusive)
	The first element in the sub table will be at firstIndex"

	| table {IntegerTable} theEnd {IntegerVar} |
	theEnd _ firstIndex + stopIndex - startIndex - 1.
	table _ IntegerTable make.IntegerVar: firstIndex with: theEnd.
	firstIndex to: theEnd do: 
		[:i {IntegerVar} | 
		| val {Heaper wimpy} |
		val _ self intFetch: i + startIndex - firstIndex.
		val == NULL ifFalse: [table atInt: i introduce: val]].
	^table!

{ScruTable} subTable: reg {XnRegion} 

	| subRegion {IntegerRegion} |
	subRegion _ (reg intersect: self domain asSimpleRegion)
				cast: IntegerRegion.
	subRegion isEmpty ifTrue: [^ self emptySize: (self count max: 1)].
	^self subTableBetween: subRegion start with: subRegion stop!

{ScruTable} subTableBetween: startIndex {IntegerVar} with: stopIndex {IntegerVar}
	"Hack for C++ overloading problem"
	^self offsetSubTableBetween: startIndex with: stopIndex with: startIndex! !

!ActualIntegerTable methodsFor: 'runs'!

{XnRegion} runAtInt: anIdx {IntegerVar} 
	| idx {UInt32} lastObj {Heaper} notDone {BooleanVar} |
	idx _ (anIdx - start) DOTasLong.
	tally == UInt32Zero ifTrue: [^ IntegerRegion make].
	(idx < firstElem or: [idx > lastElem])
		ifTrue: [^IntegerRegion make: anIdx with: anIdx].
	notDone _ true.
	(lastObj _ elements fetch: idx) == NULL
		ifTrue: [[idx <= lastElem and: [notDone]]
				whileTrue: [(elements fetch: idx) == NULL
						ifTrue: [idx _ idx + 1]
						ifFalse: [notDone _ false]]]
		ifFalse: [[idx <= lastElem and: [notDone]]
				whileTrue: [(elements fetch: idx) ~~ NULL
						ifTrue: [((elements fetch: idx) isEqual: lastObj)
								ifTrue: [idx _ idx + 1]
								ifFalse: [notDone _ false]]
						ifFalse: [notDone _ false]]].
	^IntegerRegion make: anIdx with: (start + idx)! !

!ActualIntegerTable methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name.
	self printOnWithSimpleSyntax: aStream
		with: '['
		with: ','
		with: ']'! !

!ActualIntegerTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL} 
	"ignore order spec for now"
	"Note that this method depends on the ITAscendingStepper NOT copying the table."
	order == NULL
		ifTrue: [tally == UInt32Zero
				ifTrue: [^IntegerTableStepper
						make: self
						with: start
						with: start]
				ifFalse: [^ITAscendingStepper
						create: (self copy cast: OberIntegerTable)
						with: start + firstElem "self lowestIndex"
						with: start + lastElem "self highestIndex"]]
		ifFalse: [^IntegerTableStepper make: self with: order]!

{Heaper} theOne
	self count ~~ 1 ifTrue:
		[ Heaper BLAST: #NotOneElement ].
	^ self intFetch: self lowestIndex! !

!ActualIntegerTable methodsFor: 'private:'!

{IntegerRegion} contigDomainStarting: anIdx {UInt32} 
	| begin {UInt32} tIdx {UInt32} |
	tIdx _ begin _ anIdx.
	[tIdx <= lastElem and: [(elements fetch: tIdx) ~~ NULL]]
		whileTrue: [tIdx _ tIdx + 1].
	tIdx > begin
		ifTrue: [^IntegerRegion make: start + begin with: start + tIdx]
		ifFalse: [^IntegerRegion make: anIdx with: anIdx]!

{PtrArray} elementsArray
	"return the elements array for rapid processing"
	^ elements!

{UInt32} endOffset
	"return the size of the elements array for rapid processing"
	^ lastElem!

{void} enlargeAfter: toMinimum {IntegerVar}
	"Enlarge the receiver to contain more slots filled with nil."

	| newElements{PtrArray} oldElements {PtrArray wimpy} tmp {UInt32} newSize {UInt32} |
	newSize _ elemCount * 2.
	newSize < 4 ifTrue: [newSize _ 4].
	(newSize < (tmp _ (toMinimum - start) DOTasLong + 1)) ifTrue: [newSize _ tmp].
	newElements _ PtrArray nulls: newSize.
	UInt32Zero almostTo: elemCount do: [:i {UInt32} | 
		newElements at: i store: (elements fetch: i)].
	"Just for the hell of it, I make this robust for asynchronous readers..."
	oldElements _ elements.
	elements _ newElements.
	oldElements destroy.
	elemCount _ newSize.
	tally == UInt32Zero ifTrue: [firstElem _ elements count - 1]!

{void} enlargeBefore: toMinimum {IntegerVar} 
	"Enlarge the receiver to contain more slots filled with nil."

	| newSize {UInt32} newElements {PtrArray} oldElements {PtrArray wimpy} offset {UInt32} tmp {UInt32} stop {IntegerVar} |
	stop _ start + elemCount.
	newSize _ elemCount * 2.
	newSize < 4 ifTrue: [newSize _ 4].
	newSize < (tmp _ (stop - toMinimum) DOTasLong + 1) ifTrue: [newSize _ tmp].
	newElements _ PtrArray nulls: newSize.
	offset _ newSize - elemCount.
	UInt32Zero almostTo: elemCount do: [:i {UInt32} | 
		newElements at: i + offset store: (elements fetch: i)].
	oldElements _ elements.
	elements _ newElements.
	oldElements destroy.
	start _ stop - newSize.
	firstElem _ firstElem + offset.
	lastElem _ lastElem + offset.
	elemCount _ newSize!

{UInt32} firstElemAfter: index {UInt32}

	"This method returns the first table entry that is not NULL after index."
	 
	| idx {UInt32} |
	(tally == UInt32Zero) ifTrue: [^elemCount].
	idx _ index + 1.
	[(idx < lastElem) and: [(elements fetch: idx) == NULL]] whileTrue: [idx _ idx + 1].
	^ idx!

{IntegerRegion} generateDomain
	| begin {UInt32} resReg {IntegerRegion} nextReg {IntegerRegion} |
	resReg _ IntegerRegion make.
	tally == UInt32Zero ifTrue: [^resReg].
	begin _ firstElem.
	[begin <= lastElem]
		whileTrue: 
			[nextReg _ self contigDomainStarting: begin.
			nextReg isEmpty
				ifTrue: [nextReg _ self nullDomainStarting: begin]
				ifFalse: [resReg _ (resReg unionWith: nextReg)
								cast: IntegerRegion].
			begin _ (nextReg stop - start) DOTasLong].
	^resReg!

{UInt32} lastElemBefore: index {UInt32}

	"This method returns the first table entry that is not NULL after index."
	 
	| idx {UInt32} |
	(tally == UInt32Zero) ifTrue: [^UInt32Zero].
	idx _ index - 1.
	[(idx > firstElem) and: [(elements fetch: idx) == NULL]] whileTrue: [idx _ idx - 1].
	^ idx!

{UInt32} maxElements
	"return the size of the elements array for rapid processing"
	^ elemCount!

{IntegerRegion} nullDomainStarting: anIdx {UInt32} 
	| begin {UInt32} tIdx {UInt32} |
	tIdx _ begin _ anIdx.
	[tIdx <= lastElem and: [(elements fetch: tIdx) == NULL]]
		whileTrue: [tIdx _ tIdx + 1].
	tIdx > begin
		ifTrue: [^IntegerRegion make: start + begin with: start + tIdx]
		ifFalse: [^IntegerRegion make: anIdx with: anIdx]!

{IntegerVar} startIndex
	"return the size of the elements array for rapid processing"
	^ start!

{UInt32} startOffset
	"return the size of the elements array for rapid processing"
	^ firstElem! !

!ActualIntegerTable methodsFor: 'smalltalk: private:'!

fixup
	super fixup.
	[((elements fetch: lastElem) == NULL) and: [lastElem > 0]] whileTrue: [
		Transcript show: 'd'.
		lastElem _ lastElem - 1]!

{void} inspect
	^InspectorView open: (IntegerTableInspector inspect: self)! !

!ActualIntegerTable methodsFor: 'protected: destruct'!

{void} destruct
	elements destroy.
	elements _ NULL.
	super destruct! !

!ActualIntegerTable methodsFor: 'protected: COW stuff'!

{void} becomeCloneOnWrite: where {Heaper}
	| tmp {IntegerTable} source {TableStepper} |
	tmp _ (ActualIntegerTable new.Become: where) create: start with: (start + lastElem).
	tally == UInt32Zero ifTrue: [^ VOID].
	source _ ITAscendingStepper create: self with: start + firstElem with: start + lastElem.
	source forEach: [ :tableElem {Heaper} |
		tmp at: source position store: tableElem].! !

!ActualIntegerTable methodsFor: 'overload junk'!

{Heaper} at: key {Position} store: value {Heaper} 

	^ self atInt: (key cast: IntegerPos) asIntegerVar store: value!

{Heaper} fetch: key {Position} 

	^ self intFetch: ((key cast: IntegerPos) asIntegerVar)!

{BooleanVar} includesKey: aKey {Position}
	^ self includesIntKey: ((aKey cast: IntegerPos) asIntegerVar)!

{XnRegion} runAt: anIdx {Position} 
	^ self runAtInt: ((anIdx cast: IntegerPos) asIntegerVar)!

{BooleanVar} wipe: key {Position}
	^ self intWipe: ((key cast: IntegerPos) asIntegerVar)! !

!ActualIntegerTable methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	elements _ receiver receiveHeaper.
	start _ receiver receiveIntegerVar.
	elemCount _ receiver receiveUInt32.
	firstElem _ receiver receiveUInt32.
	lastElem _ receiver receiveUInt32.
	tally _ receiver receiveUInt32.
	domainIsSimple _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: elements.
	xmtr sendIntegerVar: start.
	xmtr sendUInt32: elemCount.
	xmtr sendUInt32: firstElem.
	xmtr sendUInt32: lastElem.
	xmtr sendUInt32: tally.
	xmtr sendBooleanVar: domainIsSimple.! !