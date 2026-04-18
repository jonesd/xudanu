'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:29 pm'!

CoordinateSpace subclass: #HeaperSpace
	instanceVariableNames: ''
	classVariableNames: 'TheHeaperSpace {HeaperSpace} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Unordered'!
HeaperSpace comment:
'A HeaperSpace is one whose positions represent the identity of individual Heapers.  Identity of a Heaper is determined according by its response to "isEqual" and "hashForEqual" (see "The Equality of Decisions" for a bunch of surprising issues regarding Heaper equality).  A region is a HeaperSpace is a SetRegion (see SetRegion).  As a result of having HeaperSpaces, one can use the identity of Heapers to index into hash tables, and still obey the convention that a table maps from positions in some coordinate space.
	
	HeaperSpaces cannot (yet?) be used as the domain space for Xanadu Stamps, and therefore also not as the domain space of an IndexedWaldo.  In order to do this, the Heapers in question would have to persist in a way that Xanadu doesn''t provide for.
	
	As is typical for an unordered space, the only Dsp for this space is the identity Dsp.  No type or pseudo-constructor is exported however--the Dsp is gotten by converting a HeaperSpace to a Dsp.  Similarly, no heaper-specific type or pseudo-constructor is exported for my regions.  The conversions are sufficient.  The resulting regions are guaranteed to be SetRegions.'!

(HeaperSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #PSEUDO.COPY; yourself)!

!HeaperSpace methodsFor: 'creation'!

create

	super create: HeaperRegion make
		with: HeaperRegion make complement
		with: HeaperDsp make
		with: NULL
		with: NULL! !

!HeaperSpace methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"is equal to any basic space on the same category of positions"

	^self getCategory hashForEqual + 1!

{BooleanVar} isEqual: anObject {Heaper}
	"is equal to any basic space on the same category of positions"

	^anObject getCategory == self getCategory! !

!HeaperSpace methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HeaperSpace class
	instanceVariableNames: ''!

(HeaperSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #PSEUDO.COPY; yourself)!

!HeaperSpace class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	TheHeaperSpace := self create!

linkTimeNonInherited

	TheHeaperSpace := NULL! !

!HeaperSpace class methodsFor: 'pseudo constructors'!

{HeaperSpace INLINE} make
	"Return the one instance of HeaperSpace"
	
	^TheHeaperSpace! !

!HeaperSpace class methodsFor: 'rcvr pseudo constructor'!

{Heaper} make.Rcvr: rcvr {Rcvr}
	(rcvr cast: SpecialistRcvr) registerIbid: TheHeaperSpace.
	^TheHeaperSpace! !