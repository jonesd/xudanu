'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:33 pm'!

FeHyperRef subclass: #FeSingleRef
	instanceVariableNames: ''
	classVariableNames: 'TheSingleRefSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
FeSingleRef comment:
'Represents a single attachment to some material in the context of a Work, and maybe a Path beneath it.'!

(FeSingleRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeSingleRef methodsFor: 'accessing'!

{FeEdition CLIENT} excerpt
	"The material to which this HyperRef is attached."

	^(self edition get: (Sequence string: 'HyperRef:Excerpt')) cast: FeEdition!

{FeSingleRef CLIENT} withExcerpt: excerpt {FeEdition}
	"Make this Ref point at different material."

	^FeSingleRef construct: (self edition with: (Sequence string: 'HyperRef:Excerpt') with: excerpt)! !

!FeSingleRef methodsFor: 'protected:'!

{FeHyperRef} makeNew: edition {FeEdition}
	"Make a new HyperRef of the same type with different contents"
	
	^FeSingleRef construct: edition! !

!FeSingleRef methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeSingleRef class
	instanceVariableNames: ''!

(FeSingleRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeSingleRef class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	"Check that it has the right fields in the right places. Ignore other contents."
	
	^(FeHyperRef check: edition)
		and: [FeWrapper checkSubEdition: edition
			with: (Sequence string: 'HyperRef:AttachedMaterial')
			with: NULL
			with: false]!

{FeSingleRef} construct: edition {FeEdition}
	"Create a new wrapper and endorse it"
	
	self spec endorse: edition.
	^(self makeWrapper: edition) cast: FeSingleRef!

{FeWrapper} makeWrapper: edition {FeEdition}
	"Just create a new wrapper"
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheSingleRefSpec := wrap.! !

!FeSingleRef class methodsFor: 'creation'!

{FeSingleRef CLIENT} make: material {FeEdition | NULL}
	with: workContext {FeWork default: NULL}
	with: originalContext {FeWork default: NULL}
	with: pathContext {FePath default: NULL}
	"Make a new SingleRef. At least one of the parameters must be non-NULL. The originalContext, if supplied,  must be a frozen Work."
	
	| result {FeEdition} |
	(material == NULL and: [workContext == NULL
			and: [originalContext == NULL and: [pathContext == NULL]]])
		ifTrue: [Heaper BLAST: #MustSupplySomeHyperRefInformation].
	(originalContext ~~ NULL
			and: [(originalContext fetchBe cast: BeWork) fetchEditClub ~~ NULL])
		ifTrue: [Heaper BLAST: #OriginalContextMustBeFrozen].

	result := FeEdition empty: SequenceSpace make.
	workContext ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'HyperRef:WorkContext')
			with: workContext].
	originalContext ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'HyperRef:OriginalContext')
			with: originalContext].
	material ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'HyperRef:Excerpt')
			with: material].
	pathContext ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'HyperRef:PathContext')
			with: pathContext edition].
	^self construct: result!

{FeWrapperSpec} spec

	^TheSingleRefSpec! !

!FeSingleRef class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'SingleRef'
		with: 'HyperRef'
		with: #FeSingleRef.!

linkTimeNonInherited

	TheSingleRefSpec := NULL.! !

!FeSingleRef class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeEdition CLIENT} excerpt
"! !

!FeSingleRef class methodsFor: 'smalltalk: defaults'!

{FeSingleRef CLIENT} make: material {FeEdition | NULL}
	"Make a new SingleRef. At least one of the parameters must be non-NULL. The originalContext, if supplied,  must be a frozen Work."

	^self make: material with: NULL with: NULL with: NULL!

{FeSingleRef CLIENT} make: material {FeEdition | NULL}
	with: workContext {FeWork default: NULL}
	"Make a new SingleRef. At least one of the parameters must be non-NULL. The originalContext, if supplied,  must be a frozen Work."

	^self make: material with: workContext with: NULL with: NULL!

{FeSingleRef CLIENT} make: material {FeEdition | NULL}
	with: workContext {FeWork default: NULL}
	with: originalContext {FeWork default: NULL}
	"Make a new SingleRef. At least one of the parameters must be non-NULL. The originalContext, if supplied,  must be a frozen Work."

	^self make: material with: workContext with: originalContext with: NULL! !