'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:23 pm'!

Heaper subclass: #FeWrapper
	instanceVariableNames: '
		myEdition {FeEdition}
		myInner {FeWrapper | NULL}
		mySpec {FeWrapperSpec}'
	classVariableNames: 'TheWrapperSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
FeWrapper comment:
'An object which wraps an Edition, providing additional functionality for manipulating it and enforcing invariants on the format.

Implementation note:

The fact that you cannot get the spec of a Wrapper is deliberate. You can merely check that it is a kind of Edition you know, but no more; this makes it easy to compatibly add new leaf classes below existing ones.'!

(FeWrapper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!FeWrapper methodsFor: 'accessing'!

{FeEdition CLIENT} edition
	"Essential. The primitive Edition this is wrapping."
	
	^myEdition!

{FeWrapper CLIENT} inner
	"Essential. The next Wrapper inside this one; blasts if this wraps an Edition directly."
	myInner == NULL ifTrue: [Heaper BLAST: #NoInnerWrapper].
	^myInner!

{BooleanVar} isWrapperOf: spec {FeWrapperSpec}
	"Essential. Return TRUE if this is wrapped as the given spec, or any one of its subtypes"
	
	^mySpec isSubSpecOf: spec! !

!FeWrapper methodsFor: 'protected: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}
	super create.
	myEdition := edition.
	myInner := NULL.
	mySpec := spec.!

create: edition {FeEdition} with: inner {FeWrapper} with: spec {FeWrapperSpec}
	super create.
	myEdition := edition.
	myInner := inner.
	mySpec := spec.! !

!FeWrapper methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeWrapper class
	instanceVariableNames: ''!

(FeWrapper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!FeWrapper class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	FeWrapperSpec ABSTRACTWRAPPER: 'Wrapper' with: NULL with: #FeWrapper!

linkTimeNonInherited

	TheWrapperSpec := NULL.! !

!FeWrapper class methodsFor: 'private: wrapping'!

{void} setSpec: spec {FeWrapperSpec}

	TheWrapperSpec := spec.! !

!FeWrapper class methodsFor: 'accessing'!

{FeWrapperSpec} spec

	^TheWrapperSpec! !

!FeWrapper class methodsFor: 'protected: checking'!

{BooleanVar} checkDomainHas: edition {FeEdition}
	with: required {XnRegion}
	"Checks that the domain is in the right coordinate space and is a superset of the given region"
	
	^(edition coordinateSpace isEqual: required coordinateSpace)
		and: [required isSubsetOf: edition domain]!

{BooleanVar} checkDomainIn: edition {FeEdition}
	with: limit {XnRegion}
	"Checks that the domain is in the right coordinate space and a subset of the given region"
	
	^(edition coordinateSpace isEqual: limit coordinateSpace)
		and: [edition domain isSubsetOf: limit]!

{BooleanVar} checkSubEdition: parent {FeEdition}
	with: key {Position}
	with: spec {FeWrapperSpec | NULL}
	with: required {BooleanVar}
	"If there is a SubEdition at a key in an edition, and if a spec is supplied, that it can be certified as the given type"
	
	| value {FeRangeElement} |
	value := parent fetch: key.
	value == NULL ifTrue: [^required not].
	^(value isKindOf: FeEdition)
		and: [spec == NULL
			or: [spec certify: (value cast: FeEdition)]]!

{BooleanVar} checkSubEditions: parent {FeEdition}
	with: keys {XnRegion}
	with: spec {FeWrapperSpec}
	with: required {BooleanVar}
	"Check that everything in the region is an Edition, which can be certified with the given type"
	
	keys stepper forEach:
		[ :key {Position} |
		(self checkSubEdition: parent with: key with: spec with: required) ifFalse:
			[^false]].
	^true!

{BooleanVar} checkSubSequence: edition {FeEdition} with: key {Position} with: required {BooleanVar}
	"Whether there is an Edition there which can be successfully converted into a zero based Sequence"
	
	| value {FeRangeElement} |
	Ravi hack. "zones"
	value := edition fetch: key.
	value == NULL ifTrue: [^required not].
	^(value isKindOf: FeEdition)
		and: [((value cast: FeEdition) coordinateSpace isEqual: IntegerSpace make)
		and: [((value cast: FeEdition) domain cast: IntegerRegion) isCompacted
		"and: [((value cast: FeEdition) zoneOf: PrimSpec uInt8) domain
			isEqual: (value cast: FeEdition) domain]"]]!

{BooleanVar} checkSubWork: parent {FeEdition} with: key {Position} with: required {BooleanVar}
	"If there is a SubWork at a key in an edition"
	
	| value {FeRangeElement} |
	value := parent fetch: key.
	value == NULL ifTrue: [^required not].
	^value ~~ NULL and: [value isKindOf: FeWork]! !

!FeWrapper class methodsFor: 'smalltalk: passe'!

{BooleanVar} checkSubSetEdition: parent {FeEdition}
	with: key {Position}
	with: spec {FeWrapperSpec | NULL}
	with: required {BooleanVar}
	"If there is a SubEdition at a key in an edition, that it can be wrapped as a Set, and if a spec is supplied, that it only contains the given type"
	
	| value {FeRangeElement} set {FeSet} |
	self passe.
	
	value := parent fetch: key.
	value == NULL ifTrue: [^required not].
	((value isKindOf: FeEdition) and: [FeSet spec certify: (value cast: FeEdition)])
		ifFalse: [^false].
	set := (FeSet spec wrap: (value cast: FeEdition)) cast: FeSet.
	^spec == NULL or: [set count = (set count: spec)]! !

!FeWrapper class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeEdition CLIENT} edition
{FeWrapper CLIENT} inner
{BooleanVar CLIENT} isWrappedAs: spec {FeWrapperSpec}
"! !