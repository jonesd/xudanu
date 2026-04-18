'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:32 pm'!

FeWrapper subclass: #FeHyperRef
	instanceVariableNames: ''
	classVariableNames: 'TheHyperRefSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
FeHyperRef comment:
'Represents a single attachment to some material in context.'!

(FeHyperRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeHyperRef methodsFor: 'accessing'!

{FeWork CLIENT} originalContext
	"A Work frozen on the contents of the Work at the time the HyperRef was made"

	^(self edition get: (Sequence string: 'HyperRef:OriginalContext')) cast: FeWork!

{FePath CLIENT} pathContext
	"The path of labels down from the top-level Edition"

	^(FePath spec wrap: ((self edition
		get: (Sequence string: 'HyperRef:PathContext')) cast: FeEdition)) cast: FePath!

{FeHyperRef CLIENT} withOriginalContext: work {FeWork | NULL}
	"Change (or remove if NULL) the originalContext"

	work == NULL ifTrue:
		[^self makeNew: (self edition without: (Sequence string: 'HyperRef:OriginalContext'))]
	ifFalse:
		[(work fetchBe cast: BeWork) fetchEditClub ~~ NULL
			ifTrue: [Heaper BLAST: #MustBeFrozen].
		^self makeNew: (self edition
			with: (Sequence string: 'HyperRef:OriginalContext')
			with: work)]!

{FeHyperRef CLIENT} withPathContext: path {FePath | NULL}
	"Change (or remove if NULL) the pathContext"

	path == NULL ifTrue:
		[^self makeNew: (self edition without: (Sequence string: 'HyperRef:PathContext'))]
	ifFalse:
		[^self makeNew: (self edition
			with: (Sequence string: 'HyperRef:PathContext')
			with: path edition)]!

{FeHyperRef CLIENT} withWorkContext: work {FeWork | NULL}
	"Change (or remove if NULL) the workContext"

	work == NULL ifTrue:
		[^self makeNew: (self edition without: (Sequence string: 'HyperRef:WorkContext'))]
	ifFalse:
		[^self makeNew: (self edition
			with: (Sequence string: 'HyperRef:WorkContext')
			with: work)]!

{FeWork CLIENT} workContext
	"The Work whose state this is attached to."

	^(self edition get: (Sequence string: 'HyperRef:WorkContext')) cast: FeWork! !

!FeHyperRef methodsFor: 'protected: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec!

{FeHyperRef} makeNew: edition {FeEdition}
	"Make a new HyperRef of the same type with different contents"
	
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeHyperRef class
	instanceVariableNames: ''!

(FeHyperRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeHyperRef class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	FeWrapperSpec ABSTRACTWRAPPER: 'HyperRef' with: 'Wrapper' with: #FeHyperRef!

linkTimeNonInherited

	TheHyperRefSpec := NULL.! !

!FeHyperRef class methodsFor: 'protected: wrapping'!

{BooleanVar} check: edition {FeEdition}
	"Check that it has the right fields in the right places. Ignore other contents."
	
	^(edition coordinateSpace isEqual: SequenceSpace make)
		and: [(edition domain
			intersects: (((Sequence string: 'HyperRef:PathContext') asRegion
				with: (Sequence string: 'HyperRef:WorkContext'))
				with: (Sequence string: 'HyperRef:OriginalContext')))
		and: [(FeWrapper checkSubWork: edition
			with: (Sequence string: 'HyperRef:WorkContext')
			with: false)
		and: [(FeWrapper checkSubWork: edition
			with: (Sequence string: 'HyperRef:OriginalContext')
			with: false)
		and: [(FeWrapper checkSubEdition: edition
			with: (Sequence string: 'HyperRef:PathContext')
			with: FePath spec
			with: false)]]]]!

{void} setSpec: spec {FeWrapperSpec}

	TheHyperRefSpec := spec.! !

!FeHyperRef class methodsFor: 'pseudo constructors'!

{FeWrapperSpec} spec

	^TheHyperRefSpec! !

!FeHyperRef class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeWork CLIENT} originalContext
{FePath CLIENT} pathContext
{FeHyperRef CLIENT} withOriginalContext: work {FeWork | NULL}
{FeHyperRef CLIENT} withPathContext: path {FePath | NULL}
{FeHyperRef CLIENT} withWorkContext: work {FeWork | NULL}
{FeWork CLIENT} workContext
"! !