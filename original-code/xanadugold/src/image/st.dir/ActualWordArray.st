'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:52 pm'!

MuWordArray subclass: #ActualWordArray
	instanceVariableNames: '
		myString {char star NOCOPY}
		myOffset {IntegerVar NOCOPY}
		myCount {IntegerVar NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!

(ActualWordArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); add: #NOT.A.TYPE; yourself)!

!ActualWordArray methodsFor: 'accessing'!

{Heaper} atInt: key {IntegerVar} store: bits {Heaper} 
	"Store the contents of the PackOBits into the wordArray."
	
	| arrayLength {long} old |
	arrayLength _ myString size - myOffset.
	key > arrayLength ifTrue: [Heaper BLAST: #AbstractionViolation].
	key = arrayLength ifTrue: [self grow. myCount _ myCount + 1].
	old _ myString at: (key+myOffset+1).
	myString at: (key+myOffset+1) put: bits asChar.
	^ old!

{IntegerVar} count

	^ myCount!

{XnRegion} domain

	myString size = 0
		ifTrue: [^IntegerRegion make]
		ifFalse: [^IntegerRegion make: 0 with: myCount]!

{IntegerVar} highestIndex
	^ myCount - 1!

{Heaper} intFetch: idx {IntegerVar} 
	"This works because Smalltalk characters support 
	most of the protocol for PackOBits."

	^(idx < IntegerVar0 or: [idx >= myCount])
		ifTrue: [NULL]
		ifFalse: [PrimSpec uInt8 value: (myString at: idx + myOffset + 1)]!

{BooleanVar} intWipe: anIdx {IntegerVar}

	anIdx == (myCount - 1) ifFalse: [Heaper BLAST: #InvalidRequest. ^ false].
	myCount _ anIdx.
	^ true!

{IntegerVar} lowestIndex
	^ myOffset!

{ScruTable} offsetSubTableBetween: startIndex {IntegerVar} 
	with: stopIndex {IntegerVar} 
	with: firstIndex {IntegerVar} 
	"Return a table which contains the elements from start to stop, starting at firstIndex.
	Zero-based subclasses will blast if firstIndex is non-zero"
	| table {MuArray} |
	table _ ActualWordArray create: myString with: (myOffset + startIndex) with: (stopIndex - startIndex).
	firstIndex ~~ IntegerVar0
		ifTrue: [^ MuArray offsetScruArray: table with: (IntegerMapping make: firstIndex)]
		ifFalse: [^ table]!

{ScruTable} subTable: reg {XnRegion} 

	| tReg {XnRegion} |
	(tReg _ reg intersect: self domain) isEmpty ifTrue:
		[^MuWordArray make].
	tReg cast: IntegerRegion into:
		[ :ir | ir isSimple
			ifTrue: [^self offsetSubTableBetween: ir start with: ir stop with: ir start]
			ifFalse: [Heaper BLAST: #MustBeContiguousDomain]]!

{ScruTable} subTableBetween: startLoc {IntegerVar} with: endLoc {IntegerVar} 
	^self
		offsetSubTableBetween: startLoc
		with: endLoc
		with: startLoc!

{void} wipeAll: region {XnRegion}
	
	| ir {IntegerRegion} |
	(region == NULL or: [region isEmpty]) ifTrue: [^ VOID].
	ir _ region cast: IntegerRegion.
	
	(ir isSimple not or: 
		[ir isBoundedBelow not or: 
			[ir isBoundedAbove and: [ir stop >= myCount]]]) 
		ifTrue: [Heaper BLAST: #InvalidRequest].
	myCount _ ir start!

{IntegerVar} wordSize
	^ByteSize! !

!ActualWordArray methodsFor: 'c-like access'!

{void star} asString
	^self gutsOf!

{UInt8Array} asUInt8Array

	(myOffset = 0 and: [myString size = myCount]) ifTrue:
		[^UInt8Array string: myString].
	^UInt8Array string: (myString copyFrom: myOffset + 1 to: myOffset + myCount)!

{void star} gutsOf

	^myString copyFrom: myOffset + 1 to: myOffset + myCount!

{IntegerVar} sizeOf
	^ myCount! !

!ActualWordArray methodsFor: 'creation'!

{ScruTable} copy
	
	^ActualWordArray create: myString copy with: myOffset with: myCount!

{ScruTable} emptySize: size {IntegerVar}

	self unimplemented
	
	"What's this for?"! !

!ActualWordArray methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << '"' << self gutsOf << '"'! !

!ActualWordArray methodsFor: 'runs'!

{XnRegion} runAtInt: anIdx {IntegerVar} 
	self unimplemented.
	"idx _ anIdx.
	(idx < 0 or: [idx >= arrayLength])
		ifTrue: [^LinearRegion nullInterval].
	lastObj _ self get: idx.
	notDone _ true.
	[idx < arrayLength and: [notDone]]
		whileTrue: [((self get: idx) isEqual: lastObj)
				ifTrue: [idx _ idx + 1]
				ifFalse: [notDone _ false]].
	^LinearRegion discreteInterval: anIdx with: idx"! !

!ActualWordArray methodsFor: 'testing'!

{BooleanVar} contentsEqual: other {ScruTable} 

	(other isKindOf: ActualWordArray)
		ifTrue: [^ self gutsOf = other gutsOf]
		ifFalse: [^super contentsEqual: other]!

{UInt32} fastHash
	^(#cat.U.WordArray hashForEqual + self gutsOf hash)!

{BooleanVar} includesIntKey: key {IntegerVar}
	^key >= myOffset and: [key < myCount]!

{BooleanVar} isEmpty
	^ myCount == IntegerVar0! !

!ActualWordArray methodsFor: 'private: private'!

{void} grow
	"Grow by exactly one element."
	
	| newBits {ByteString} |
	newBits _ ByteString create: myCount + 1.
	newBits replaceFrom: myOffset + 1 to: myCount with: myString startingAt: 1.
	myString _ newBits!

{void} growBy: nElems {UInt32} 
	"Grow by exactly one element."
	
	| newBits {ByteString} |
	newBits _ ByteString create: self count + nElems.
	newBits replaceFrom: 1 to: myString size with: myString startingAt: 1.
	myString _ newBits! !

!ActualWordArray methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveAWA: rcvr {Rcvr}
	(rcvr receiveIntegerVar = ByteSize) assert.
	myCount _ rcvr receiveIntegerVar.
	myString _ String new: myCount.
	myOffset _ IntegerVar0.
	rcvr receiveData: (UInt8Array string: myString)!

{void SEND.HOOK} sendAWA: xmtr {Xmtr}
	xmtr sendUInt32: ByteSize.
	xmtr sendIntegerVar: myCount.
	xmtr sendUInt8Data: ((PrimSpec uInt8 arrayFromBuffer: myCount with: self gutsOf) cast: UInt8Array)! !

!ActualWordArray methodsFor: 'enumerating'!

{Stepper} stepper: order {OrderSpec default: NULL} 

	^IntegerTableStepper make: self with: order! !

!ActualWordArray methodsFor: 'protected: creation'!

create.charVector: string {char star}
	super create.
	myString _ string.
	myOffset _ IntegerVar0.
	myCount _ string size!

create.IntegerVar: size {IntegerVar}
	super create.
	myString _ ByteString create: size.
	myOffset _ IntegerVar0.
	myCount _ size!

create: onString {Character star} with: offset {IntegerVar} with: size {IntegerVar}
	super create.
	myString _ onString.
	myOffset _ offset.
	myCount _ size!

{void} destruct
	myString _ NULL.
	super destruct! !

!ActualWordArray methodsFor: 'bulk operations'!

{void} introduceAll: other {ScruTable} 
	with: dsp {Dsp default: NULL} 
	with: restrict {XnRegion default: NULL}
	
	(other isKindOf: ActualWordArray) ifFalse: [Heaper BLAST: #OhHelpMe].
	dsp translation == myCount ifFalse: [Heaper BLAST: #InvalidRequest].
	(myOffset + myCount) < myString count ifTrue: [
		myString _ myString copyFrom: myOffset + 1 to: (myOffset + myCount).
		myOffset _ 0].
	myString _ myString, (other gutsOf).
	myCount _ myCount + other count!

{void} storeAll: table {ScruTable} 
	with: dsp {Dsp default: NULL} 
	with: region {XnRegion default: NULL} 
	
	| offset {Int32} start {Int32} numToCopy {Int32} |
	dsp ~~ NULL
		ifTrue: [ offset _ (dsp cast: IntegerMapping) translation DOTasLong ]
		ifFalse: [ offset _ Int32Zero ].
	region ~~ NULL
		ifTrue:
			[ | localRegion {IntegerRegion star} |
			localRegion _ region cast: IntegerRegion.
			start _ localRegion start DOTasLong + 1.
			offset _ offset + start - 1.
			numToCopy _ localRegion stop DOTasLong - start + 1]
		ifFalse:
			[start _ 1.
			numToCopy _ table count].
	numToCopy + offset >= self count ifTrue:
		[ self growBy: offset + (numToCopy - self count) DOTasLong].
	(table isKindOf: ActualWordArray) ifFalse:
		[super storeAll: table with: dsp.
		^ VOID].
	myString replaceFrom: offset + 1 to: offset + numToCopy with: table asString startingAt: start! !

!ActualWordArray methodsFor: 'smalltalk: defaults'!

{void} introduceAll: table

	self introduceAll: table with: NULL with: NULL!

{void} introduceAll: table with: dsp

	self introduceAll: table with: dsp with: NULL! !

!ActualWordArray methodsFor: 'smalltalk: passe'!

{UInt1Array} asUInt1Array

	self passe.
	(myOffset = 0 and: [myString size = myCount]) ifTrue:
		[^UInt8Array string: myString].
	^UInt8Array string: (myString copyFrom: myOffset + 1 to: myOffset + myCount)!

{MuWordArray} with: another {ScruTable}
	"(XuWordArray make.charVector: 'hello ') with: (XuWordArray make.charVector: 'world')"
	"^ ActualWordArray create: (myString, (another cast: ActualWordArray) gutsOf)"
	
	self passe! !

!ActualWordArray methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self receiveAWA: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	self sendAWA: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualWordArray class
	instanceVariableNames: ''!

(ActualWordArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); add: #NOT.A.TYPE; yourself)!

!ActualWordArray class methodsFor: 'Smalltalk instance creation'!

create.charVector: c
	^self new create.charVector: c!

create.IntegerVar: i
	^self new create.IntegerVar: i! !

!ActualWordArray class methodsFor: 'stubble'!

{void} create.Rcvr: rcvr {Rcvr}
	((rcvr receiveIntegerVar) = ByteSize) assert.
	rcvr receiveIntegerVar.
	^self create: (rcvr receiveData) asString! !

!ActualWordArray class methodsFor: 'pseudo constructors'!

make.UInt8Array: array {UInt8Array}

	^self create.charVector: array asString! !

!ActualWordArray class methodsFor: 'smalltalk: passe'!

make.UInt1Array: array {UInt1Array}
	self passe.
	^self create.charVector: array asString! !