'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:37 pm'!

FeWrapper subclass: #FeClubDescription
	instanceVariableNames: ''
	classVariableNames: 'TheClubDescriptionSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FeClubDescription comment:
'Describes the state of Club -- who is in it, which Work is its home (if it has one), and how you can login to it'!

(FeClubDescription getOrMakeCxxClassDescription)
	friends:
'/* friends for class FeClubDescription */

friend class BeClub;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeClubDescription methodsFor: 'accessing'!

{FeLockSmith CLIENT} lockSmith
	"Describes how authority for this Club is gained"
	
	(self edition includesKey: (Sequence string: 'ClubDescription:LockSmith')) ifTrue:
		[^(FeLockSmith spec wrap: ((self edition
			get: (Sequence string: 'ClubDescription:LockSmith'))
				cast: FeEdition)) cast: FeLockSmith]
	ifFalse: [^FeWallLockSmith make]!

{FeSet CLIENT of: FeClub} membership
	"The Clubs which are members of this one."
	
	(self edition includesKey: (Sequence string: 'ClubDescription:Membership')) ifTrue:
		[^(FeSet spec wrap: ((self edition
			get: (Sequence string: 'ClubDescription:Membership'))
				cast: FeEdition)) cast: FeSet]
	ifFalse: [^FeSet make]!

{FeClubDescription CLIENT} withLockSmith: lockSmith {FeLockSmith}
	"Change how authority is gained"

	^FeClubDescription construct: (self edition with: (Sequence string: 'ClubDescription:LockSmith')
		with: lockSmith edition)!

{FeClubDescription CLIENT} withMembership: members {FeSet of: FeClub}
	"Change the entire membership list"

	^FeClubDescription construct: (self edition with: (Sequence string: 'ClubDescription:Membership')
		with: members edition)! !

!FeClubDescription methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !

!FeClubDescription methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '('
		<< self lockSmith << ', '
		<< self membership << ')'! !

!FeClubDescription methodsFor: 'smalltalk: passe'!

{FeWork} home
	"The Work which is the home for this Club; blasts if it has none"
	self passe.
	^(self edition get: (Sequence string: 'ClubDescription:Home')) cast: FeWork!

{FeClubDescription} withHome: home {FeWork | NULL}
	"Change the home to different Work, or to none if NULL"
	self passe.
	home == NULL ifTrue:
		[^FeClubDescription construct: (self edition
			without: (Sequence string: 'ClubDescription:Home'))]
	ifFalse:
		[^FeClubDescription construct: (self edition
			with: (Sequence string: 'ClubDescription:Home')
			with: home edition)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeClubDescription class
	instanceVariableNames: ''!

(FeClubDescription getOrMakeCxxClassDescription)
	friends:
'/* friends for class FeClubDescription */

friend class BeClub;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeClubDescription class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	"Check that it has the right fields in the right places. Ignore other contents."
	
	((FeWrapper checkDomainIn: edition
		with: ((Sequence string: 'ClubDescription:LockSmith') asRegion
			with: (Sequence string: 'ClubDescription:Membership')))
		and: [(FeWrapper checkSubEdition: edition
			with: (Sequence string: 'ClubDescription:Membership')
			with: FeSet spec
			with: false)
		and: [FeWrapper checkSubEdition: edition
			with: (Sequence string: 'ClubDescription:LockSmith')
			with: FeLockSmith spec
			with: false]])
		ifFalse: [^false].
	(edition includesKey: (Sequence string: 'ClubDescription:Membership')) ifTrue:
		[ | sub {FeEdition} |
		sub := (edition get: (Sequence string: 'ClubDescription:Membership')) cast: FeEdition.
		sub stepper forEach: [ :r {FeRangeElement} |
			(r isKindOf: FeClub) ifFalse: [^false]]].
	^true!

{FeClubDescription} construct: edition {FeEdition}
	"Create a new wrapper and endorse it"
	
	self spec endorse: edition.
	^(self makeWrapper: edition) cast: FeClubDescription!

{FeWrapper} makeWrapper: edition {FeEdition}
	"Just create a new wrapper"
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheClubDescriptionSpec := wrap.! !

!FeClubDescription class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'ClubDescription' with: 'Wrapper' with: #FeClubDescription.!

linkTimeNonInherited

	TheClubDescriptionSpec := NULL.! !

!FeClubDescription class methodsFor: 'pseudo constructors'!

{FeClubDescription CLIENT} make: membership {(FeSet of: FeClub) | NULL}
	with: lockSmith {FeLockSmith default: NULL}

	| result {FeEdition} |
	result := FeEdition empty: SequenceSpace make.
	membership ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'ClubDescription:Membership')
			with: membership edition].
	lockSmith ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'ClubDescription:LockSmith')
			with: lockSmith edition].
	^(self spec wrap: result) cast: FeClubDescription!

{FeWrapperSpec} spec

	^TheClubDescriptionSpec! !

!FeClubDescription class methodsFor: 'smalltalk: passe'!

make: members {FeSet | NULL}
	with: lockSmith {FeLockSmith | NULL}
	with: home {FeWork | NULL}

	| result {FeEdition} |
	self passe.
	result := FeEdition empty: SequenceSpace make.
	members ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'ClubDescription:Membership')
			with: members edition].
	lockSmith ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'ClubDescription:LockSmith')
			with: lockSmith edition].
	home ~~ NULL ifTrue:
		[result := result with: (Sequence string: 'ClubDescription:Home')
			with: home].
	^(self spec wrap: result) cast: FeClubDescription! !

!FeClubDescription class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeLockSmith CLIENT} lockSmith
{FeSet CLIENT of: FeClub} membership
{FeClubDescription CLIENT} withLockSmith: lockSmith {FeLockSmith}
{FeClubDescription CLIENT} withMembership: members {FeSet of: FeClub}
"! !