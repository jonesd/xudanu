'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:31 pm'!

FeWrapper subclass: #FeHyperLink
	instanceVariableNames: ''
	classVariableNames: 'TheHyperLinkSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
FeHyperLink comment:
'Contains a named table of HyperRefs and a set of Works which describe the usage and/or format of the link.'!

(FeHyperLink getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeHyperLink methodsFor: 'accessing'!

{FeHyperRef CLIENT} endAt: name {Sequence}
	"Get the HyperRef at the given name; blast if none there"

	(name isEqual: (Sequence string: 'Link:LinkTypes')) ifTrue:
		[Heaper BLAST: #MustUseDifferentLinkEndKey].
	^(FeHyperRef spec wrap: ((self edition get: name) cast: FeEdition)) cast: FeHyperRef!

{SequenceRegion CLIENT} endNames
	"The names of all of the ends of this link"
	
	^(self edition domain without: (Sequence string: 'HyperLink:LinkTypes')) cast: SequenceRegion!

{FeSet CLIENT of: FeWork} linkTypes
	"The various type documents describing this kind of Link. These documents are typically Editions with descriptions at each linkEnd key describing what is at that Link End.
	The reason for having several is to allow type hierarchies to be constructed and searched for, by including all super types of a link in its link type list.
	The Link should be endorsed with all the IDs of all the types.
	What if someone endorses it further (or unendorses it?)"

	^(FeSet spec wrap: ((self edition
		get: (Sequence string: 'Link:LinkTypes')) cast: FeEdition)) cast: FeSet!

{FeHyperLink CLIENT} withEnd: name {Sequence} with: linkEnd {FeHyperRef}
	"Change/add a Link end"

	(name isEqual: (Sequence string: 'Link:LinkTypes')) ifTrue:
		[Heaper BLAST: #MustUseDifferentLinkEndName].
	^FeHyperLink construct: (self edition with: name with: linkEnd edition)!

{FeHyperLink CLIENT} withLinkTypes: types {FeSet of: FeWork}
	"Replace the set of type documents describing this kind of Link"

	^FeHyperLink construct: (self edition
		with: (Sequence string: 'Link:LinkTypes') with: types edition)!

{FeHyperLink CLIENT} withoutEnd: name {Sequence}
	"Remove a Link end"

	(name isEqual: (Sequence string: 'Link:LinkTypes')) ifTrue:
		[Heaper BLAST: #MustUseDifferentLinkEndName].
	^FeHyperLink construct: (self edition without: name)! !

!FeHyperLink methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeHyperLink class
	instanceVariableNames: ''!

(FeHyperLink getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeHyperLink class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	"Check that it has the right fields in the right places. Ignore other contents."
	
	((FeWrapper checkDomainHas: edition
			with: (Sequence string: 'Link:LinkTypes') asRegion)
		and: [(FeWrapper checkSubEdition: edition
			with: (Sequence string: 'Link:LinkTypes')
			with: FeSet spec
			with: false)
		and: [FeWrapper checkSubEditions: edition
			with: (edition domain without: (Sequence string: 'Link:LinkTypes'))
			with: FeHyperRef spec
			with: true]])
		ifFalse: [^false].
	(edition includesKey: (Sequence string: 'Link:LinkTypes')) ifTrue:
		[ | sub {FeEdition} |
		sub := (edition get: (Sequence string: 'Link:LinkTypes')) cast: FeEdition.
		sub stepper forEach: [ :r {FeRangeElement} |
			((r isKindOf: FeEdition) and: [FeHyperRef spec certify: (r cast: FeEdition)])
				ifFalse: [^false]]].
	^true!

{FeHyperLink} construct: edition {FeEdition}

	self spec endorse: edition.
	edition endorse: (FeServer
		endorsementRegion: (CurrentAuthor fluidGet asRegion cast: IDRegion)
		with: (FeServer iDsOfRange: ((edition get: (Sequence string: 'Link:LinkTypes')) cast: FeEdition))).
	^(self makeWrapper: edition) cast: FeHyperLink!

{FeWrapper} makeWrapper: edition {FeEdition}
	"Just create a new wrapper"
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheHyperLinkSpec := wrap.! !

!FeHyperLink class methodsFor: 'pseudo constructors'!

{Filter} linkFilter: types {IDRegion}
	"A Filter for links of the specified types"
	
	self unimplemented.
	^NULL "fodder"!

{FeHyperLink CLIENT} make: types {FeSet}
	with: leftEnd {FeHyperRef}
	with: rightEnd {FeHyperRef}
	"Make a standard two-ended link"
	
	| values {PtrArray of: FeEdition} |
	types stepper forEach: [ :t {FeRangeElement} |
		(t isKindOf: FeWork) ifFalse:
			[Heaper BLAST: #InvalidParameter]].
	values := PtrArray nulls: 3.
	"Put the values in the array in alphabetical order of keys"
	values at: Int32Zero store: leftEnd edition.
	values at: 1 store: types edition.
	values at: 2 store: rightEnd edition.
	^self construct: (FeEdition
		fromArray: values
		with: (((Sequence string: 'Link:LinkTypes') asRegion
			with: (Sequence string: 'Link:LeftEnd'))
			with: (Sequence string: 'Link:RightEnd'))
		with: SequenceSpace make getAscending)!

{FeWrapperSpec} spec

	^TheHyperLinkSpec! !

!FeHyperLink class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'HyperLink' with: 'Wrapper' with: #FeHyperLink.!

linkTimeNonInherited

	TheHyperLinkSpec := NULL.! !

!FeHyperLink class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeHyperRef CLIENT} endAt: name {Sequence}
{SequenceRegion CLIENT} endNames
{FeSet CLIENT of: FeWork} linkTypes
{FeHyperLink CLIENT} withEnd: name {Sequence} with: linkEnd {FeHyperRef}
{FeHyperLink CLIENT} withLinkTypes: types {FeSet of: FeWork}
{FeHyperLink CLIENT} withoutEnd: name {Sequence}
"! !