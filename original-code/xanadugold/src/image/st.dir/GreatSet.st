'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:25 pm'!

Set variableSubclass: #GreatSet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Unordered'!



!GreatSet methodsFor: 'removing'!

- aSet
	"Answer those elements present in the receiver and absent from aSet."

	^self reject: [ :i | aSet includes: i ]!

remove: oldObject ifAbsent: anExceptionBlock   
	"Remove oldObject as one of the receiver's elements.  If several of the
	elements are equal to oldObject, only one is removed. If no element is equal to
	oldObject, answer the result of evaluating anExceptionBlock.  Otherwise,
	answer the argument, oldObject."
	| obj |
	obj _ (self fetchSub: oldObject) 
		remove: oldObject ifAbsent: anExceptionBlock.
	tally _ self calcSize.
	^ obj! !

!GreatSet methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance variable."

	^super deepCopy rehash! !

!GreatSet methodsFor: 'private: private'!

fullCheck
	| subMax |
	tally < (self basicSize * 900) ifTrue: [^ VOID].
	subMax _ self basicCollection inject: 0 into: [:dMax :set |
		dMax max: set size].
	subMax > 1024 ifTrue: [self grow]!

growSize
	"Answer an amount by which the receiver should grow 
	to make room for more elements."

	^ ((self basicSize * 2) + 1) sieve last!

noCheckAdd: anObject 
	"Assume that the association is in the receiver and add it
	without checking to make sure."

	(self fetchSub: anObject) noCheckAdd: anObject.
	tally _ tally + 1!

rehash
	| newSelf |
	newSelf _ self species new: self basicSize.
	self do: [:each | newSelf noCheckAdd: each].
	self become: newSelf! !

!GreatSet methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	stream storeRecordOfClass: self class.
	stream nextPut: self size.
	self do: [:value | stream nextPut: value]! !

!GreatSet methodsFor: 'user interface'!

inspect
	"Create and schedule a SetInspector in which the user can examine the
	receiver's variables."

	Cursor wait showWhile: [InspectorView open: (SetInspector inspect: self)]! !

!GreatSet methodsFor: 'private: greatness'!

basicCollection
	| col |
	col _ Array new: (self basicSize).
	1 to: self basicSize do: [:i | col at: i put: (self basicAt: i)].
	^ col!

basicSubSize

	^ self basicCollection inject: 0 into: [:sum :set | sum + set basicSize]!

bucketFor: anObject

	^ (anObject hash \\ self basicSize) + 1!

calcSize

	^ self basicCollection inject: 0 into: [:sum :set | sum + set size]!

{Set} fetchSub: key

	^ (self basicAt: (self bucketFor: key))!

initialize

	1 to: self basicSize do: [:i | 
		self basicAt: i put: (Set new: 512)]! !

!GreatSet methodsFor: 'enumerating'!

collect: aBlock 
	"Evaluate aBlock with each of the values of the receiver as the 
	argument. Collect the resulting values into a Set that is like 
	the receiver. Answer the new Set."
	"Override the general method, so that we make a big enough set and 
	avoid growing."

	tally = 0 ifTrue: [^Set new: 2].
	^self basicCollection inject: (GreatSet new: self size)
		into: [:new :subset | new addAll: (subset collect: aBlock)]!

do: aBlock   
	"Evaluate aBlock with each of the receiver's elements as the argument."

	tally = 0 ifTrue: [^self].
	1 to: self basicSize do: 
		[:index | (self basicAt: index) do: aBlock].
	^ self! !

!GreatSet methodsFor: 'testing'!

includes: anObject 
	"Answer whether anObject is one of the receiver's elements."

	^(self fetchSub: anObject) includes: anObject! !

!GreatSet methodsFor: 'adding'!

add: newObject 
	"Include newObject as one of the receiver's elements.  Answer newObject."

	| subset oldSize |
	newObject == nil ifTrue: [^newObject].
	oldSize _ (subset _ self fetchSub: newObject) size.
	subset add: newObject.
	"increment tally if object was not previously in the set"
	subset size > oldSize ifTrue: [tally _ tally + 1].
	self fullCheck.
	^ newObject! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GreatSet class
	instanceVariableNames: ''!



!GreatSet class methodsFor: 'instance creation'!

new
	"Create an instance of a Set."

	^(self new: 2) initialize!

new: anInteger 
	"Create an instance of a Set."
	| next |
	next _ (anInteger max: 3) sieve last.
	^((super new: next) initialize) setTally!

newForSize: numElems

	^ self new: ((numElems // 400) + 1)! !

!GreatSet class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag
	"Answer object appearing next in stream."

	| size set |
	size _ stream next.  "integer"
	set _ self newForSize: (size max: 1).
	stream register: set id: tag.
	1 to: size do:
		[:i | set add: stream next].
	^set! !