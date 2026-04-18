'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:43 pm'!

IdentityDictionary variableSubclass: #DependentsDictionary
	instanceVariableNames: 'length fullTally '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Support'!
DependentsDictionary comment:
'A DependentsDictionary holds the dependents for objects that are the keys of the instance.  The values are either the sole dependent of an object or a DependentsCollection of dependents.

Instance Variables:
	length		<SmallInteger>   the basicSize of the instance 
	fullTally	<SmallInteger>   the amount the instance can hold before growing is necessary 
'!


!DependentsDictionary methodsFor: 'access'!

at: anObject add: aDependentObject
	"Add aDependentObject to anObject's dependents."

	| deps indx obj |
	indx _ self findKeyOrNil: anObject.
	(obj _ self basicAt: indx) == nil
		ifTrue:
			[tally _ tally + 1.
			self basicAt: indx put: anObject.
			deps _ aDependentObject]
		ifFalse:
			[deps _ (valueArray at: indx) asDependentsWith: aDependentObject].
	valueArray at: indx put: deps.
	obj == nil ifTrue: [self fullCheck].
	^aDependentObject!

at: anObject remove: aDependentObject
	"Remove aDependentObject from anObject's dependents."

	| deps indx |
	indx _ self findKeyOrNil: anObject.
	(self basicAt: indx) == nil
		ifTrue: [^aDependentObject].
	deps _ (valueArray at: indx) asDependentsWithout: aDependentObject.
	deps == nil
		ifTrue:
			[self removeAndCleanUpAtIndex: indx.
			^aDependentObject].
	valueArray at: indx put: deps.
	^aDependentObject!

atOrNil: anObject
	"Answer a nil, singleton, or DependentsCollection of the objects that are dependent on the receiver, that is, the objects that should be notified if the receiver changes."

	"^self at: anObject ifAbsent: [nil]"

	| index probe start |
	index _ anObject identityHash \\ length + 1.
	start _ index.
	[(probe _ self basicAt: index) == nil
		ifTrue: [^nil].
	probe == anObject
		ifTrue: [^valueArray at: index].
	(index _ index + 1) <= length] whileTrue.
	index _ 1.
	[(probe _ self basicAt: index) == nil
		ifTrue: [^nil].
	probe == anObject
		ifTrue: [^valueArray at: index].
	(index _ index + 1) < start] whileTrue.
	^nil!

collectionAt: anObject
	"Answer a Collection of the objects that are dependent on the receiver, that is, the objects that should be notified if the receiver changes."

	| index probe start |
	index _ anObject identityHash \\ length + 1.
	start _ index.
	[(probe _ self basicAt: index) == nil ifTrue: [^#()].
	probe == anObject
		ifTrue: [^(valueArray at: index) asDependentsAsCollection].
	(index _ index + 1) <= length] whileTrue.
	index _ 1.
	[(probe _ self basicAt: index) == nil ifTrue: [^#()].
	probe == anObject
		ifTrue: [^(valueArray at: index) asDependentsAsCollection].
	(index _ index + 1) < start] whileTrue.
	^#()!

removeKeyNoError: anObject
	"Remove anObject as a key from the receiver."

	self removeKey: anObject ifAbsent: []! !

!DependentsDictionary methodsFor: 'private: private'!

findKeyOrNil: key 
	"Look for the key in the receiver.  If it is found, answer the index of 
	the key, otherwise answer the index of the first unused slot."

	| index probe pass |
	pass _ 1.
	index _ key identityHash \\ length + 1.
	[(probe _ self basicAt: index) == nil or: [probe == key]]
		whileFalse: [(index _ index + 1) > length
				ifTrue: 
					[index _ 1.
					pass _ pass + 1.
					pass > 2 ifTrue: [^self grow findKeyOrNil: key]]].
	^index!

fullCheck
	"Check the receiver to see if growing is necessary."

	tally >= fullTally
		ifTrue: [self grow]!

setTally
	"Initialize tally and other instance variables."

	super setTally.
	length _ self basicSize.
	fullTally _ length - (length // 4)! !