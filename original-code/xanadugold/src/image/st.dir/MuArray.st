'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:57 pm'!

IntegerTable subclass: #MuArray
	instanceVariableNames: ''
	classVariableNames: 'MustBeContiguousDomainSignal {Signal smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
MuArray comment:
'The class XuArray is intended to model zero-based arrays with integer keys (indices).
	
	This makes them like the array primitive in C and C++.  There is an additional constraint, which is they are to have simple domains.  Therefore they should not be constructed with non-contiguous sections.  This is not currently enforced.  Given that it is enforced, an XuArray with count N would have as its domain exactly the integers from 0 to N-1.
	
	There is some controversy over whether XuArray should be a type and enforce this contraint (by BLASTing if an attempt is made to violate the constraint), or whether XuArray is just a specialized implementation for when an IntegerTable happens to meet this constraint; in which case it should "become" a more general implementation when an attempt is made to violate the constraint (see "Type Safe Become").  In the latter case, XuArray will probably be made a private class as well.  Please give us your opinion.
	
	XuArray provides no additional protocol.'!

(MuArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MuArray methodsFor: 'accessing'!

{Heaper} atInt: key {IntegerVar} store: value {Heaper} 

	self subclassResponsibility!

{CoordinateSpace} coordinateSpace

	^ IntegerSpace make!

{IntegerVar} count

	self subclassResponsibility.!

{XnRegion} domain

	self subclassResponsibility.!

{IntegerVar} highestIndex
	self subclassResponsibility!

{Heaper} intFetch: key {IntegerVar}
	self subclassResponsibility!

{BooleanVar} intWipe: anIdx {IntegerVar}
	self subclassResponsibility!

{IntegerVar} lowestIndex
	self subclassResponsibility!

{ScruTable} offsetSubTableBetween: startIndex {IntegerVar} 
	with: stopIndex {IntegerVar} 
	with: firstIndex {IntegerVar unused} 
	"Return a table which contains the elements from start to stop, starting at firstIndex.
	Zero-based subclasses will blast if firstIndex is non-zero"

	^ self subTableBetween: startIndex with: stopIndex!

{ScruTable} subTable: region {XnRegion} 

	self subclassResponsibility!

{ScruTable} subTableBetween: startLoc {IntegerVar} with: endLoc {IntegerVar} 
	self subclassResponsibility!

{ScruTable} transformedBy: dsp {Dsp} 

	(dsp inverse isEqual: dsp) 
		ifTrue: [^self]
		ifFalse: [^MuArray offsetScruArray: self with: dsp]! !

!MuArray methodsFor: 'creation'!

{ScruTable} copy
	self subclassResponsibility!

{ScruTable} emptySize: size {IntegerVar}

	self subclassResponsibility! !

!MuArray methodsFor: 'testing'!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^aKey >= IntegerVar0 and: [aKey < self count]!

{BooleanVar} isEmpty
	^self count = IntegerVar0! !

!MuArray methodsFor: 'runs'!

{XnRegion} runAtInt: key {IntegerVar}
	self subclassResponsibility! !

!MuArray methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	"Return a stepper on this table."

	self subclassResponsibility!

{Heaper} theOne
	self count ~~ 1 ifTrue:
		[ Heaper BLAST: #NotOneElement ].
	^ self intFetch: IntegerVar0! !

!MuArray methodsFor: 'bulk operations'!

{void} wipeAll: region {XnRegion} 
	"I 'wipe' from myself all associations whose key 
	is in 'region'. See MuTable::wipe"

	(region coordinateSpace isEqual: self coordinateSpace)
		ifFalse: [Heaper BLAST: #WrongCoordSpace].
	self isEmpty ifTrue: [^VOID].
	region isSimple ifFalse: [Heaper BLAST: #NotSimple].
	((region intersect: self domain)
		stepper: (IntegerSpace make getDescending))
		forEach: [:p {IntegerPos} | self intWipe: p asIntegerVar]! !

!MuArray methodsFor: 'overload junk'!

{Heaper} at: key {Position} store: value {Heaper} 

	^ self atInt: (key cast: IntegerPos) asIntegerVar store: value!

{Heaper} fetch: key {Position} 

	^ self intFetch: ((key cast: IntegerPos) asIntegerVar)!

{BooleanVar} includesKey: aKey {Position}
	^self includesIntKey: ((aKey cast: IntegerPos) asIntegerVar)!

{XnRegion} runAt: key {Position} 

	^self runAtInt: ((key quickCast: IntegerPos) asIntegerVar)!

{BooleanVar} wipe: key {Position}
	^ self intWipe: ((key cast: IntegerPos) asIntegerVar)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MuArray class
	instanceVariableNames: ''!

(MuArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MuArray class methodsFor: 'creation'!

{MuArray INLINE} array
	"A new empty XnArray"
	
	^MuArray make.IntegerVar: 1!

{MuArray} array: obj0 {Heaper}
	"A new XnArray initialized with a single element, 'obj0', stored at index 0."
	
	| table {MuArray} |
	table _ MuArray make.IntegerVar: 1.
	table atInt: IntegerVar0 store: obj0.
	^table!

{MuArray} array: obj0 {Heaper} with: obj1 {Heaper}
	"A new XnArray initialized with a two elements stored at indicies 0 and 1."
	
	| table {MuArray} |
	table _ MuArray make.IntegerVar: 2.
	table atInt: IntegerVar0 store: obj0.
	table atInt: 1 store: obj1.
	^table!

{MuArray} array: obj0 {Heaper} with: obj1 {Heaper} with: obj2 {Heaper}
	"A new XuArray initialized with a three elements stored at indicies 0, 1, and 2."
	
	| table {MuArray} |
	table _ MuArray make.IntegerVar: 3.
	table atInt: IntegerVar0 store: obj0.
	table atInt: 1 store: obj1.
	table atInt: 2 store: obj2.
	^table!

{MuArray} array: obj0 {Heaper} 
	with: obj1 {Heaper} 
	with: obj2 {Heaper} 
	with: obj3 {Heaper}
	"A new XuArray initialized with a four elements stored at indicies 0 through 3."
	
	| table {MuArray} |
	table _ MuArray make.IntegerVar: 4.
	table atInt: IntegerVar0 store: obj0.
	table atInt: 1 store: obj1.
	table atInt: 2 store: obj2.
	table atInt: 3 store: obj3.
	^table!

{TableAccumulator} arrayAccumulator
	"Returns an Accumulator which will produce an XuArray of the elements 
	accumulated into it in order of accumulation. See XuArray. Equivalent to 
	'tableAccumulator()'. Eventually either he or I should be declared obsolete."

	^ ArrayAccumulator make: MuArray array!

{TableAccumulator} arrayAccumulator: onArray {MuArray} 
	"An accumulator which will accumulate by appending elements onto the end of 
	'onArray'. It is an error for anyone else to modify 'onArray' between creating 
	this accumulator and accumulating into it. acc->value() will return 'onArray' 
	itself."

	^ArrayAccumulator make: onArray!

make.IntegerVar: someSize {IntegerVar} 
	"'someSize' is a hint about how big we should expect the array to need to grow."

	^ActualArray create.IntegerVar: someSize!

{ScruTable} offsetScruArray: array {MuArray} with: dsp {Dsp} 
	"The resulting ScruTable is a view onto 'array'. It is a view in which each key 
	is offset by 'dsp' from where it is in 'array'. By saying it is a view, we mean 
	that as 'array' is modified, the view tracks the changes."

	^OffsetScruArray make: array with: dsp! !