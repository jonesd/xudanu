'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:32 pm'!

FeHyperRef subclass: #FeMultiRef
	instanceVariableNames: ''
	classVariableNames: 'TheMultiRefSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
FeMultiRef comment:
'An undifferentiated set of HyperRefs'!

(FeMultiRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeMultiRef methodsFor: 'private:'!

{FeEdition} refsEdition
	"The Edition holding the HyperRefs"
	
	^(self edition get: (Sequence string: 'MultiRef:Refs')) cast: FeEdition!

{FeMultiRef} withRefsEdition: edition {FeEdition}
	"With a different refs Edition"
	
	Ravi thingToDo. "check about preserving labels"
	^FeMultiRef construct: (self edition
		with: (Sequence string: 'MultiRef:Refs')
		with: edition)! !

!FeMultiRef methodsFor: 'accessing'!

{FeMultiRef CLIENT} intersect: other {FeMultiRef}
	"Remove those not in the other Refs from the set."

	^self withRefsEdition: (self refsEdition sharedWith: other refsEdition)!

{FeMultiRef CLIENT} minus: other {FeMultiRef}
	"Remove the other Refs from the set."

	^self withRefsEdition: (self refsEdition notSharedWith: other refsEdition)!

{Stepper CLIENT of: FeHyperRef} refs
	"All the HyperRefs in the collection"

	Ravi shouldImplement.
	^NULL "fodder"!

{FeMultiRef CLIENT} unionWith: other {FeMultiRef}
	"Add the other Refs into the set."
	
	| added {FeEdition} result {FeEdition} stepper {Stepper} more {PrimArray} |
	added := other refsEdition notSharedWith: self refsEdition.
	added isEmpty ifTrue: [^self].
	result := self refsEdition.
	stepper := added stepper.
	[stepper hasValue] whileTrue:
		[more := stepper stepMany.
		result := result combine: (FeEdition
			fromArray: more
			with: ((self refsEdition coordinateSpace cast: IDSpace)
				newIDs: more count))].
	^self withRefsEdition: result!

{FeMultiRef CLIENT} with: ref {FeHyperRef}
	"Add a Ref to the set"
	
	(self refsEdition positionsOf: ref edition) isEmpty
		ifTrue: [^self withRefsEdition: (self refsEdition
			with: (self refsEdition coordinateSpace cast: IDSpace) newID
			with: ref edition)]
		ifFalse: [^self]!

{FeMultiRef CLIENT} without: ref {FeHyperRef}
	"Add a Ref to the set"
	
	| keys {XnRegion} |
	(keys := self refsEdition positionsOf: ref edition) isEmpty
		ifTrue: [^self]
		ifFalse: [^self withRefsEdition: (self refsEdition copy: keys complement)]! !

!FeMultiRef methodsFor: 'protected:'!

{FeHyperRef} makeNew: edition {FeEdition}
	"Make a new HyperRef of the same type with different contents"
	
	^FeMultiRef construct: edition! !

!FeMultiRef methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeMultiRef class
	instanceVariableNames: ''!

(FeMultiRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeMultiRef class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	"Check that it has the right fields in the right places. Ignore other contents."
	
	| refs {FeEdition} |
	^(FeHyperRef check: edition)
		and: [(FeWrapper checkSubEdition: edition
			with: (Sequence string: 'MultiRef:Refs')
			with: NULL
			with: true)
		and: [((refs := (edition get: (Sequence string: 'MultiRef:Refs')) cast: FeEdition) coordinateSpace isKindOf: IDSpace)
		and: [FeWrapper checkSubEditions: refs
			with: refs domain
			with: FeHyperRef spec
			with: true]]]!

{FeMultiRef} construct: edition {FeEdition}
	"Create a new wrapper and endorse it"
	
	self spec endorse: edition.
	^(self makeWrapper: edition) cast: FeMultiRef.!

{FeWrapper} makeWrapper: edition {FeEdition}
	"Just create a new wrapper"
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheMultiRefSpec := wrap.! !

!FeMultiRef class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'MultiRef'
		with: 'HyperRef'
		with: #FeMultiRef.!

linkTimeNonInherited

	TheMultiRefSpec := NULL.! !

!FeMultiRef class methodsFor: 'creation'!

{FeMultiRef CLIENT} make: refs {PtrArray | NULL of: FeHyperRef}
	with: workContext {FeWork default: NULL}
	with: originalContext {FeWork default: NULL}
	with: pathContext {FePath default: NULL}
	"Make a new MultiRef. At least one of the parameters must be non-NULL. The originalContext, if supplied,  must be a frozen Work."
	
	| result {FeEdition} refEdition {FeEdition} |
	(refs == NULL and: [workContext == NULL
			and: [originalContext == NULL and: [pathContext == NULL]]])
		ifTrue: [Heaper BLAST: #MustSupplySomeHyperRefInformation].
	
	(originalContext ~~ NULL
			and: [(originalContext fetchBe cast: BeWork) fetchEditClub ~~ NULL])
		ifTrue: [Heaper BLAST: #OriginalContextMustBeFrozen].
	refs == NULL ifTrue:
		[refEdition := FeEdition empty: IDSpace unique]
	ifFalse:
		[ | array {PtrArray of: FeEdition} |
		array := PtrArray nulls: refs count.
		Int32Zero almostTo: refs count do: [ :i {Int32} |
			array at: i store: ((refs get: i) cast: FeHyperRef) edition].
		refEdition := FeEdition fromArray: array
			with: (IDSpace unique newIDs: array count)].
	result := FeEdition fromOne: (Sequence string: 'MultiRef:Refs') with: refEdition.
	workContext ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'HyperRef:WorkContext')
			with: workContext].
	originalContext ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'HyperRef:OriginalContext')
			with: originalContext].
	pathContext ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'HyperRef:PathContext')
			with: pathContext edition].
	^self construct: result!

{FeWrapperSpec} spec

	^TheMultiRefSpec! !

!FeMultiRef class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeMultiRef CLIENT} intersect: other {FeMultiRef}
{FeMultiRef CLIENT} minus: other {FeMultiRef}
{Stepper CLIENT of: FeHyperRef} refs
{FeMultiRef CLIENT} unionWith: other {FeMultiRef}
{FeMultiRef CLIENT} with: ref {FeHyperRef}
{FeMultiRef CLIENT} without: ref {FeHyperRef}
"! !

!FeMultiRef class methodsFor: 'smalltalk: defaults'!

{FeMultiRef CLIENT} make: refs {PtrArray | NULL of: FeHyperRef}
	"Make a new SingleRef. At least one of the parameters must be non-NULL. The originalContext, if supplied,  must be a frozen Work."

	^self make: refs with: NULL with: NULL with: NULL!

{FeMultiRef CLIENT} make: refs {PtrArray | NULL of: FeHyperRef}
	with: workContext {FeWork default: NULL}
	"Make a new SingleRef. At least one of the parameters must be non-NULL. The originalContext, if supplied,  must be a frozen Work."

	^self make: refs with: workContext with: NULL with: NULL!

{FeMultiRef CLIENT} make: refs {PtrArray | NULL of: FeHyperRef}
	with: workContext {FeWork default: NULL}
	with: originalContext {FeWork default: NULL}
	"Make a new SingleRef. At least one of the parameters must be non-NULL. The originalContext, if supplied,  must be a frozen Work."

	^self make: refs with: workContext with: originalContext with: NULL! !