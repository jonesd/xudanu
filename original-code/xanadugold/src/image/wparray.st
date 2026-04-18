'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:39:14 pm'!

((CxxSystemOrganization tree childNamed: #wparray) ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: #wparray) destroyFiles]!

PtrArray variableSubclass: #WeakPtrArray
	instanceVariableNames: '
		myArray {WeakArray smalltalk}
		myExecutor {XnExecutor}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(WeakPtrArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WeakPtrArray methodsFor: 'self copy methods'!

create.Rcvr: rcvr {Rcvr}
	super create.Rcvr: rcvr.
	0 to: self count - 1 do: [ :i |
		self at: i store: (rcvr receiveHeaper)]!

{void} sendSelfTo: rcvr {Rcvr}
	Heaper BLAST: #NonCopySubclass! !

!WeakPtrArray methodsFor: 'accessing'!

{void} at: index {Int32} store: pointer {Heaper | NULL}

	self at: index storeValue: pointer!

{void} at: index {Int32} storeValue: pointer {Heaper | NULL}

	myArray at: index + 1 put: pointer!

count
	^myArray count!

{XnExecutor} executor
	^myExecutor!

{Heaper | NULL} fetch: index {Int32} 
	"Retrieve a single element from the array. Does array bounds checking. 
	Non-pointer arrays box up the contents in a PrimValue object."

	^self fetchValue: index!

{Heaper | NULL} fetchValue: index {Int32}
	"Fetch a value from a PrimArray, may be a Heaper, NULL, or a PrimValue.
	Clients are expected to perform necessary casting.  It is expected that
	most PrimArray clients will want to use less abstract access methods."

	| value |
	value _ myArray at: 1 + index.
	"The following 0 test is for Smalltalk's weakArray representation.  
	 A slot whose deletion hasn't yet been reported contains 0."
	value == 0 ifTrue: [^NULL].
	^value! !

!WeakPtrArray methodsFor: 'creation'!

create: executor {XnExecutor} with: count {Int4}
	super create.
	myExecutor _ executor.
	myArray _ WeakArray new: count.
	myArray addDependent: self.
	1 to: count do: [ :j {Int4 register} | myArray at: j put: NULL]!

create: size {Int32}
	with: from {PrimIntegerArray}
	with: start {Int32}
	with: count {Int32}
	with: offset {Int32}

	super create.
	myExecutor _ from executor.
	myArray _ WeakArray new: size.
	myArray addDependent: self.
	1 to: offset do: [ :i | myArray at: i put: NULL].
	self at: offset storeMany: from with: count with: start.
	1 + count + offset to: size do: [ :i | myArray at: i put: NULL].!

destruct
	myExecutor _ NULL.
	super destruct! !

!WeakPtrArray methodsFor: 'smalltalk: updating'!

at: key
	^myArray at: key!

at: key put: value
	^myArray at: key put: value!

update: aspect
	myExecutor == NULL ifTrue: [self halt.
		myArray forAllDeadIndicesDo: [:i | ] replacingCorpsesWith: NULL
	] ifFalse: [
		myArray forAllDeadIndicesDo: [:i | myExecutor execute: i - 1] replacingCorpsesWith: NULL
	]! !

!WeakPtrArray methodsFor: 'bulk accessing'!

{void CLIENT login} at: to {Int32}
	storeMany: source {PrimArray}
	with: count {Int32 default: -1}
	with: from {Int32 default: Int32Zero}
	"Copy n elements from the source array into this one. The source array must be of a compatible type."

	|  delta {Int32} stop |
	delta _ to - from.
	count == -1 ifTrue: [stop _ source count] ifFalse: [stop _ from + count].
	(stop > source count or: [stop + delta > self count]) 
		ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	(self == source and: [from < to])
		ifTrue: [stop to: from+1 by: -1 do: [ :i | self at: i + delta put: (source at: i)]]
		ifFalse: [from+1 to: stop do: [ :i | self at: i + delta put: (source at: i)]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WeakPtrArray class
	instanceVariableNames: ''!

(WeakPtrArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WeakPtrArray class methodsFor: 'creation'!

create: len with: other with: a with: b with: c
	"myAllocations _ myAllocations + 1."
	^self new create: len with: other with: a with: b with: c!

make: executor {XnExecutor} with: count {UInt4}
	^self new create: executor with: count!

new: count
	self halt! !

!WeakPtrArray class methodsFor: 'smalltalk: smalltalk initialization'!

initTimeNonInherited
	"STArrayRecipe create: self with: (Smalltalk associationAt: #XppCuisine)"!

staticTimeNonInherited
	"STArrayRecipe create: self with: (Smalltalk associationAt: #XppCuisine)"! !

!WeakPtrArray class methodsFor: 'As yet unclassified'!

new
	^self basicNew: 0! !Heaper subclass: #XnExecutor
	instanceVariableNames: ''
	classVariableNames: 'TheNoopExecutor {XnExecutor} '
	poolDictionaries: ''
	category: 'Xanadu-wparray'!

(XnExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!XnExecutor methodsFor: 'invoking'!

{void} execute: estateIndex {Int32}
	"superclass implements a noop"! !

!XnExecutor methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XnExecutor class
	instanceVariableNames: ''!

(XnExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!XnExecutor class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	TheNoopExecutor := NULL!

TimeNonInherited
	TheNoopExecutor := XnExecutor create! !

!XnExecutor class methodsFor: 'pseudoconstructor'!

{XnExecutor} noopExecutor
	^ TheNoopExecutor! !
(CxxSystemOrganization fileNamed: 'wparray')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'wparray')
	addClass: WeakPtrArray
getOrMakeCxxClassDescription in: #public;
	addClass: XnExecutor
getOrMakeCxxClassDescription in: #public!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: #wparray value: #file) yourself))!