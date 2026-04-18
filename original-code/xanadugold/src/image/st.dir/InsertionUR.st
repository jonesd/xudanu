'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:15 pm'!

UpdateRecord subclass: #InsertionUR
	instanceVariableNames: '
		posInternal {Position}
		myCount {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
InsertionUR comment:
'This is used to indicate the insertion of a new element into a model. 
The position of the insertion and the number of elements inserted is recorded.'!

(InsertionUR getOrMakeCxxClassDescription)
	friends:
'/* friends for class InsertionUR */
friend SPTR(InsertionUR) insertionUR (Position * withPos);
friend SPTR(InsertionUR) insertionUR (Position * withPos, IntegerVar count);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertionUR methodsFor: 'creation'!

create: posInserted {Position}

	super create.
	posInternal _ posInserted.
	myCount _ 1!

create: posInserted {Position} with: count {IntegerVar}

	super create.
	posInternal _ posInserted.
	myCount _ count! !

!InsertionUR methodsFor: 'accessing'!

{IntegerVar INLINE} count
	"The number of elements inserted."
	
	^ myCount!

{IntegerVar} index
	^ (posInternal cast: IntegerPos) asIntegerVar!

{Position INLINE} position
	"The first position where the insertion happened. Note that InsertionURs are 
	only sensible for coordinate spaces for which first position and count are 
	sufficient descriptions of where an insertion happened. This may be a sensible 
	restriction as it may be only in such spaces that the notion of ""insertion"" is 
	itself sensible."

	^ posInternal! !

!InsertionUR methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << posInternal << ' len: ' << myCount << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InsertionUR class
	instanceVariableNames: ''!

(InsertionUR getOrMakeCxxClassDescription)
	friends:
'/* friends for class InsertionUR */
friend SPTR(InsertionUR) insertionUR (Position * withPos);
friend SPTR(InsertionUR) insertionUR (Position * withPos, IntegerVar count);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertionUR class methodsFor: 'pseudo constructors'!

make: withPos {Position} 
	"An UpdateRecord for notification of the insertion of a single element at 
	'withPos'."

	^InsertionUR create: withPos!

make: withPos {Position} with: count {IntegerVar}
	"For notification of an insertion of 'count' elements starting at 'withPos'."
	
	^ InsertionUR create: withPos with: count! !