'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:22 pm'!

FeWrapper subclass: #FeSet
	instanceVariableNames: ''
	classVariableNames: 'TheSetSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
FeSet comment:
'An undifferentiated set of RangeElements.'!

(FeSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeSet methodsFor: 'private:'!

{IDSpace} iDSpace
	^self edition coordinateSpace cast: IDSpace! !

!FeSet methodsFor: 'accessing'!

{IntegerVar CLIENT} count
	"The number of elements in the set"
	
	^self edition count!

{BooleanVar CLIENT} includes: value {FeRangeElement}
	"Whether the set includes the given RangeElement"
	
	^(self edition keysOf: value) isEmpty not!

{FeSet CLIENT} intersect: other {FeSet}
	"Return those elements which are in both sets"
	
	^FeSet construct: (self edition
		sharedWith: other edition)!

{FeSet CLIENT} minus: other {FeSet}
	"Remove some RangeElements from the set"
	
	^FeSet construct: (self edition
		notSharedWith: other edition)!

{Stepper of: FeRangeElement} stepper
	"A stepper over the elements in the set"
	
	^self edition stepper!

{FeRangeElement CLIENT} theOne
	"If there is exactly one element, then return it"
	
	^self edition theOne!

{FeSet CLIENT} unionWith: other {FeSet}
	"Return those elements which are in either set"
	
	| added {FeEdition} result {FeEdition} stepper {Stepper} more {PrimArray} |
	"Need to assign new IDs to avoid collisions"
	added := other edition notSharedWith: self edition.
	added isEmpty ifTrue: [^self].
	result := self edition.
	stepper := added stepper.
	[stepper hasValue] whileTrue:
		[more := stepper stepMany.
		result := result combine: (FeEdition
			fromArray: more
			with: ((self edition coordinateSpace cast: IDSpace)
				newIDs: more count))].
	^FeSet construct: result!

{FeSet CLIENT} with: value {FeRangeElement}
	"Add a RangeElement to the set"
	
	(self includes: value)
		ifTrue: [^self]
		ifFalse: [^FeSet construct: (self edition
			with: self iDSpace newID
			with: value)]!

{FeSet CLIENT} without: value {FeRangeElement}
	"Remove a RangeElement from the set"
	
	^FeSet construct: 
		(self edition notSharedWith: 
			(FeEdition fromOne: IntegerVar0 integer with: value))! !

!FeSet methodsFor: 'smalltalk: passe'!

{IntegerVar} count: spec {PrimSpec default: NULL}
	"How many elements in the set; if a spec is given, then how many elements of the given spec are in the set"
	
	self passe.
	
	spec == NULL
		ifTrue: [^self edition count]
		ifFalse: [^(self edition zoneOf: spec) count]!

{IntegerVar} countEditions: spec {FeWrapperSpec default: NULL}
	"How many elements in the set are Editions; if a spec is given, then how many of them satisfy the given spec"
	
	| editions {FeEdition} result {IntegerVar} |
	self passe.
	
	result := IntegerVarZero.
	editions := self edition zoneOf: (PrimSpec pointer: FeEdition).
	spec == NULL
		ifTrue: [^editions count].
	editions stepper forEach: [ :sub {FeEdition} |
		(spec certify: sub) ifTrue:
			[result := result + 1]].
	^result!

{IDRegion} iDs

	self passe "globalIDs"! !

!FeSet methodsFor: 'protected: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !

!FeSet methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	| count {IntegerVar} |
	oo << self getCategory name << '('.
	count := IntegerVarZero.
	self stepper forEach: [ :object {FeRangeElement} |
		count > IntegerVarZero ifTrue:
			[oo << ', '.
			count > 5 ifTrue:
				[oo << '...)'.
				^VOID]].
		oo << object].
	oo << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeSet class
	instanceVariableNames: ''!

(FeSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeSet class methodsFor: 'pseudo constructors'!

{FeSet CLIENT} make

	^self construct: (FeEdition empty: IDSpace unique)!

{FeSet CLIENT} make: works {PtrArray of: FeRangeElement}

	^(self spec wrap: (FeEdition
		fromArray: works
		with: (IDSpace unique newIDs: works count))) cast: FeSet!

{FeWrapperSpec} spec

	^TheSetSpec! !

!FeSet class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}

	^(edition coordinateSpace isKindOf: IDSpace) and: [edition isFinite]!

{FeSet} construct: edition {FeEdition}

	self spec endorse: edition.
	^(self makeWrapper: edition) cast: FeSet!

{FeWrapper} makeWrapper: edition {FeEdition}

	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheSetSpec := wrap.! !

!FeSet class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'Set' with: 'Wrapper' with: #FeSet.!

linkTimeNonInherited

	TheSetSpec := NULL.! !

!FeSet class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IntegerVar CLIENT} count
{BooleanVar CLIENT} includes: value {FeRangeElement}
{FeSet CLIENT} intersect: other {FeSet}
{FeSet CLIENT} minus: other {FeSet}
{FeRangeElement CLIENT} theOne
{FeSet CLIENT} unionWith: other {FeSet}
{FeSet CLIENT} with: value {FeRangeElement}
{FeSet CLIENT} without: value {FeRangeElement}
"! !