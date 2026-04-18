'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:00 pm'!

ScruTable subclass: #OffsetScruArray
	instanceVariableNames: '
		myArray {MuArray}
		myDsp {Dsp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(OffsetScruArray getOrMakeCxxClassDescription)
	friends:
'friend class XuArray;';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!OffsetScruArray methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^myArray coordinateSpace!

{IntegerVar} count

	^myArray count!

{XnRegion} domain

	^myDsp ofAll: myArray domain!

{Heaper} fetch: anIndex {Position} 

	^myArray intFetch: (myDsp inverseOfInt: (anIndex cast: IntegerPos) asIntegerVar)!

{Heaper} intFetch: idx {IntegerVar} 
	^myArray intFetch: (myDsp inverseOfInt: idx)!

{ScruTable} subTable: encl {XnRegion}

	| lr {IntegerRegion} |
	lr _ encl cast: IntegerRegion.
	^myArray
		subTableBetween: (myDsp inverseOfInt: lr start)
			with: (myDsp inverseOfInt: lr stop)!

{ScruTable} subTableBetween: startLoc {IntegerVar} with: endLoc {IntegerVar} 
	^OffsetScruArray make: ((myArray
			subTableBetween: (myDsp inverseOfInt: startLoc)
			with: (myDsp inverseOfInt: endLoc)) cast: MuArray)
		with: myDsp!

{ScruTable} transformedBy: dsp {Dsp} 

	(myDsp inverse isEqual: dsp) 
		ifTrue: [^myArray]
		ifFalse: [^OffsetScruArray make: myArray with: (dsp compose: myDsp)]! !

!OffsetScruArray methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 

	^self runAtInt: (key quickCast: IntegerPos) asIntegerVar!

{XnRegion} runAtInt: anIdx {IntegerVar} 
	^myDsp ofAll: (myArray runAtInt: (myDsp inverseOfInt: anIdx))! !

!OffsetScruArray methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^#cat.U.OffsetScruArray hashForEqual + myArray hashForEqual + myDsp hashForEqual!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^myArray includesIntKey: (myDsp inverseOfInt: aKey)!

{BooleanVar} includesKey: aKey {Position}
	
	^ self includesIntKey: ((aKey cast: IntegerPos) asIntegerVar)!

{BooleanVar} isEmpty
	^myArray isEmpty!

{BooleanVar} isEqual: other {Heaper} 

	other 
		cast: OffsetScruArray into: [:osa |
			^(osa innerArray isEqual: myArray)
			 and: [osa innerArray isEqual: myArray]]
		others: [^false].
	^false "fodder"! !

!OffsetScruArray methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << myDsp << ', ' << myArray << ')'! !

!OffsetScruArray methodsFor: 'protected: create'!

create: array {MuArray} with: dsp {Dsp}
	super create.
	myArray _ array.
	myDsp _ dsp! !

!OffsetScruArray methodsFor: 'creation'!

{ScruTable} copy
	^ OffsetScruArray make: (myArray copy cast: MuArray) with: myDsp!

{ScruTable} empty
	^ myArray emptySize: 4!

{ScruTable} emptySize: size {IntegerVar}

	^ myArray emptySize: size! !

!OffsetScruArray methodsFor: 'conversion'!

{ImmuTable} asImmuTable

	^ ImmuTable offsetImmuTable: myArray asImmuTable with: myDsp!

{MuTable} asMuTable
	| newArray {MuTable} s {TableStepper} |
	newArray _ (myArray emptySize: myArray count) asMuTable.
	(s _ myArray stepper) forEach: [ :e {Heaper} |
		newArray atInt: (myDsp ofInt: s index) store: e].
	^ newArray! !

!OffsetScruArray methodsFor: 'smalltalk: private'!

{TableStepper} stepper
	^ OffsetArrayStepper make: (myArray stepper) with: myDsp! !

!OffsetScruArray methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL} 

	^OffsetArrayStepper make: (myArray stepper: order) with: myDsp! !

!OffsetScruArray methodsFor: 'private: private'!

{MuArray} innerArray
	^myArray!

{Dsp} innerDsp
	^myDsp! !

!OffsetScruArray methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myArray _ receiver receiveHeaper.
	myDsp _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myArray.
	xmtr sendHeaper: myDsp.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OffsetScruArray class
	instanceVariableNames: ''!

(OffsetScruArray getOrMakeCxxClassDescription)
	friends:
'friend class XuArray;';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!OffsetScruArray class methodsFor: 'create'!

{ScruTable} make: array {MuArray} with: dsp {Dsp}
	^ self create: array with: dsp! !