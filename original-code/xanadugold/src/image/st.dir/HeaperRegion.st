'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:20 pm'!

SetRegion subclass: #HeaperRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-hspace'!

(HeaperRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!HeaperRegion methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	^HeaperSpace make! !

!HeaperRegion methodsFor: 'protected: protected'!

{XnRegion} makeNew: isComplement {BooleanVar} with: positions {ImmuSet of: Position}
	^HeaperRegion create: isComplement with: positions! !

!HeaperRegion methodsFor: 'testing'!

{BooleanVar} isEnumerable: order {OrderSpec default: NULL}

	^false! !

!HeaperRegion methodsFor: 'creation'!

create: isComplement {BooleanVar} with: positions {ImmuSet of: HeaperAsPosition}
	super create: isComplement with: positions! !

!HeaperRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HeaperRegion class
	instanceVariableNames: ''!

(HeaperRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!HeaperRegion class methodsFor: 'pseudo constructors'!

{SetRegion} allHeaperAsPositions
	^HeaperRegion create: true with: ImmuSet make!

{SetRegion} make
	^HeaperRegion create: false with: ImmuSet make!

{SetRegion} make.HeaperAsPosition: heaper {HeaperAsPosition}
	^HeaperRegion create: false with: (ImmuSet make with: heaper)!

{SetRegion} make.ScruSet: heapers {ScruSet of: HeaperAsPosition}
	^HeaperRegion create: false with: heapers asImmuSet! !