'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:02 pm'!

PrimArray subclass: #PrimDataArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-parray'!
PrimDataArray comment:
'A common superclass for primitive arrays of basic data types (i.e. bits of some kind)'!

(PrimDataArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PrimDataArray methodsFor: 'bulk testing'!

{Int32} compare: other {PrimDataArray}
	with: count {Int32 default: -1}
	with: here {UInt32 default: Int32Zero}
	with: there {Int32 default: Int32Zero}
	"Return -1, 0, or +1 according to whether the elements in the specified span of this array are lexically less than, equal to, or greater than the specified span of the other. The other array must be of a compatible type. If the count is negative or goes beyond the end of either array, then the shorter array is considered to be extended with zeros.
	NOTE: Because of zero extension, this is not the same as elementsEqual; it is possible that a->compare (b) == 0 even though !! a->contentsEqual (b)"
	
	| n {Int32} longer index |
	n := (other basicSize - there) min: (self basicSize - here).
	(count >= 0 and: [count < n])
		ifTrue: [n := count].
	1 to: n do: [ :i | | a b |
		(a := self basicAt: here + i) < (b := other basicAt: there + i)
			ifTrue: [^-1].
		a > b ifTrue: [^1]].
	"past the end. check if a count was specified or if they are the same length"
	(count = n or: [(other basicSize - there) = (self basicSize - here)])
		ifTrue: [^0].
	"figure out which is longer and look for a nonzero element"
	n = (other basicSize - there) ifTrue:
		[longer := self.
		index := here + n + 1]
	ifFalse:
		[longer := other.
		index := there + n + 1].
	count >= Int32Zero
		ifTrue: [n := (count - n + index) min: longer basicSize]
		ifFalse: [n := longer basicSize].
	[index <= n] whileTrue:
		[ | val |
		(val := longer basicAt: index) < 0 ifTrue:
			[^longer == self ifTrue: [-1] ifFalse: [1]].
		val > 0 ifTrue:
			[^longer == self ifTrue: [1] ifFalse: [-1]].
		index := index + 1].
	^0!

{BooleanVar} elementsEqual: here {Int32}
	with: other {PrimArray}
	with: there {Int32 default: Int32Zero}
	with: count {Int32 default: -1}
	
	| n {Int32} |
	n := (other basicSize - there) min: (self basicSize - here).
	count > n ifTrue:
		[Heaper BLAST: #IndexOutOfBounds].
	count >= 0
		ifTrue: [n := count].
	1 to: n do: [ :i |
		(self basicAt: here + i) = (other basicAt: there + i) ifFalse:
			[^false]].
	^true!

{UInt32} elementsHash: count {Int32 default: -1} with: start {Int32 default: Int32Zero}
	"A hash of the range of values out of the array"
	
	self subclassResponsibility! !

!PrimDataArray methodsFor: 'smalltalk: defaults'!

{void} at: to {Int32}
	addElements: other {PrimDataArray}
	
	^self at: to addElements: other with: -1 with: 0!

{void} at: to {Int32}
	addElements: other {PrimDataArray}
	with: count {Int32 default: -1}
	
	^self at: to addElements: other with: count with: 0!

{void} at: to {Int32}
	subtractElements: other {PrimDataArray}
	
	^self at: to subtractElements: other with: -1 with: 0!

{void} at: to {Int32}
	subtractElements: other {PrimDataArray}
	with: count {Int32 default: -1}
	
	^self at: to subtractElements: other with: count with: 0!

{Int32} compare: other {PrimArray}

	^self compare: other with: -1 with: 0 with: 0!

{Int32} compare: other {PrimArray}
	with: count {Int32 default: -1}
	
	^self compare: other with: count with: 0 with: 0!

{Int32} compare: other {PrimArray}
	with: count {Int32 default: -1}
	with: here {UInt32 default: Int32Zero}
	
	^self compare: other with: count with: here with: 0! !

!PrimDataArray methodsFor: 'testing'!

{BooleanVar} contentsEqual: other {PrimArray}
	
	self basicSize = other basicSize ifFalse: [^false].
	1 to: self basicSize do: [ :i |
		(self basicAt: i) = (other basicAt: i)
			ifFalse: [^false]].
	^true! !

!PrimDataArray methodsFor: 'bulk accessing'!

{void} at: to {Int32}
	addElements: other {PrimDataArray}
	with: count {Int32 default: -1}
	with: from {Int32 default: Int32Zero}
	
	| n {Int32} |
	n := (other basicSize - from) min: (self basicSize - to).
	count > n ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	count >= 0 ifTrue: [n := count].
	1 to: n do: [ :i | self basicAt: to + i
		put: (other basicAt: from + i) + (self basicAt: to + i)]!

{void} at: to {Int32}
	subtractElements: other {PrimDataArray}
	with: count {Int32 default: -1}
	with: from {Int32 default: Int32Zero}
	
	| n {Int32} |
	n := (other basicSize - from) min: (self basicSize - to).
	count > n ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	count >= 0 ifTrue: [n := count].
	1 to: n do: [ :i | self basicAt: to + i
		put: (self basicAt: to + i) - (other basicAt: from + i)]! !