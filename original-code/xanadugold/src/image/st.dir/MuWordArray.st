'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:59 pm'!

MuArray subclass: #MuWordArray
	instanceVariableNames: ''
	classVariableNames: '
		ByteSize {IntegerVar smalltalk} 
		SignalShortBytes {Signal smalltalk} 
		WordSizeDoesntMatchSignal {signal smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
MuWordArray comment:
'XuWordArray is a special case of XuArray which maps from (zero based) integer indices to PackOBits (constrained).  All elements in a single WordArray must be of the same size, and the sizes are initially constrained to powers of 2.
	
	This is the only kind of table (currently) to impose a constraint on its range elements.  (This constraint is in addition to the domain constraint inherited from XuArray.)  There is currently controversy over whether XuWordArray should enforce this constraint by BLASTing on attempted violation, or should "become" some more general kind of table.  See XuArray and "Type Safe Become".
	
	There seems to be an additional constraint in the current code that each element must be exactly 8 bits.  If so, this will quickly be fixed.'!

(MuWordArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MuWordArray methodsFor: 'accessing'!

{Heaper} atInt: key {IntegerVar} store: value {Heaper} 

	self subclassResponsibility!

{IntegerVar} count

	self subclassResponsibility!

{XnRegion} domain

	self subclassResponsibility!

{IntegerVar} highestIndex
	self subclassResponsibility!

{Heaper} intFetch: idx {IntegerVar} 
	self subclassResponsibility!

{BooleanVar} intWipe: anIdx {IntegerVar unused}
	self subclassResponsibility!

{IntegerVar} lowestIndex
	self subclassResponsibility!

{ScruTable} offsetSubTableBetween: startIndex {IntegerVar} 
	with: stopIndex {IntegerVar} 
	with: firstIndex {IntegerVar} 
	"Return a table which contains the elements from start to stop, starting at firstIndex.
	Zero-based subclasses will blast if firstIndex is non-zero"
	self subclassResponsibility!

{ScruTable} subTable: reg {XnRegion} 

	reg cast: IntegerRegion into:
		[ :ir | ir isSimple
			ifTrue: [^self subTableBetween: ir start with: ir stop]
			ifFalse: [Heaper BLAST: #MustBeContiguousDomain]].
	^NULL "fodder"!

{ScruTable} subTableBetween: startLoc {IntegerVar} with: endLoc {IntegerVar} 
	self subclassResponsibility!

{IntegerVar} wordSize
	"How many bits must there be in each of my members. Recall that an 
	XuWordArray's members must all be PackOBits of the same size."

	self subclassResponsibility! !

!MuWordArray methodsFor: 'c-like access'!

{void star} asString
	"Low level access to the internal representation. Don't use unless you know 
	what you're doing. This comment intentionally left mysterious."

	self subclassResponsibility!

{UInt8Array} asUInt8Array
	"As an array of bytes. At the moment, it is not clearly defined what will happen if the wordSize is not 8 bits."
	self subclassResponsibility!

{void star} gutsOf
	"Low level access to the internal representation. Don't use unless you know 
	what you're doing.
	
	This returns a pointer to the data.  
	IT IS NOT NECESSARILY NULL TERMINATED!!
	YOU MUST NOT ALTER ANY BYTES (they may be shared)!!
	Use sizeOf to get the number of bytes."
	
	self subclassResponsibility!

{IntegerVar} sizeOf
	"The number of bytes in the internal representation. Whether this is the internal 
	representation as reported by 'asString' or 'gutsOf', I don't know."

	self subclassResponsibility! !

!MuWordArray methodsFor: 'creation'!

{ScruTable} copy
	self subclassResponsibility!

{ScruTable} emptySize: size {IntegerVar}

	self subclassResponsibility! !

!MuWordArray methodsFor: 'runs'!

{XnRegion} runAtInt: anIdx {IntegerVar} 
	self subclassResponsibility! !

!MuWordArray methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}

	self subclassResponsibility.! !

!MuWordArray methodsFor: 'overload junk'!

{Heaper} at: key {Position} store: value {Heaper} 

	^ self atInt: (key cast: IntegerPos) asIntegerVar store: value!

{Heaper} fetch: key {Position} 

	^ self intFetch: (key cast: IntegerPos) asIntegerVar!

{XnRegion} runAt: key {Position} 

	^self runAtInt: (key quickCast: IntegerPos) asIntegerVar!

{BooleanVar} wipe: key {Position}
	^ self intWipe: (key cast: IntegerPos) asIntegerVar! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MuWordArray class
	instanceVariableNames: ''!

(MuWordArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MuWordArray class methodsFor: 'pseudoConstructors'!

{MuWordArray} make.charVector: bits {char star} 
	"'bits' is assumed to be a normal null ('\0') terminated C string. This makes a new XuWordArray initialized with (I assume) a copy of the string--the initial count is the length of the string (not counting the null termination), and each member is a 1 byte (8 bits) PackOBits which is a character of the string."
	
	[^ ActualWordArray make.charVector: (bits basicCast: UInt8 star)] translateOnly.
	[^ActualWordArray create.charVector: bits] smalltalkOnly!

make.IntegerVar: size {IntegerVar}
	"A new XuWordArray.  'size' is a hint about how big it can be expected to grow."
	
	[^ ActualWordArray make.IntegerVar: size] translateOnly.
	[^ActualWordArray create.IntegerVar: size] smalltalkOnly!

{MuWordArray} make.UInt8Array: array {UInt8Array}
	"INLINE"
	^ActualWordArray make.UInt8Array: array!

{MuWordArray } make: wordsize {IntegerVar} with: length {IntegerVar} with: string {UInt8 star}
	"'string' points at an area of memory which can be considered to be an array 
	of fixed size bit strings. 'wordsize' is the number of bits in each bit string, and 
	(I assume) 'length' is the total number of bit strings (it may instead be the 
	total number of bits in the area of memory). Return a new XuWordArray 
	which uses this area of memory to represent its contents--each bit string 
	represents the value of a PackOBits of size 'wordSize'."
	"C++ only pseudo constructor"
	"INLINE"
	"C++ only pseudo constructor"
	^ActualWordArray make: wordsize with: length with: string! !

!MuWordArray class methodsFor: 'smalltalk: Class Initialization'!

initialize
	"WordArray.X initialize"
	ByteSize _ 8.! !

!MuWordArray class methodsFor: 'smalltalk: c function emulation'!

{void} copyBytes: toArr with: offset with: fromArr with: nBytes
	0 to: nBytes-1 do: [:i {UInt32} | toArr at: i + offset put: (fromArr at: i)].
	^ VOID!

memcmp: data with: odata with: count 
	| starting {UInt32} ending |
	(data isKindOf: UInt8Array)
		ifTrue: [starting _ 0.
			ending _ count - 1]
		ifFalse: [starting _ 1.
			ending _ count].
	starting to: ending do: [:i | (data at: i)
			= (odata at: i) ifFalse: [^i+(1-starting)]].
	^0!

{void} memcpy: toArr with: fromArr with: nBytes
	0 to: nBytes-1 do: [:i {UInt32} | toArr at: i put: (fromArr at: i)].
	^ VOID!

{char star} strncpy: a {char star} with: b {char star} with: n {UInt32}

	0 to: n-1 do: [:i {UInt32} | a at: i put: (b at: i)].
	^ a! !

!MuWordArray class methodsFor: 'smalltalk: passe'!

make.UInt1Array: array {UInt8Array}

	self passe.
	^ActualWordArray make.UInt1Array: array! !

MuWordArray initialize!
