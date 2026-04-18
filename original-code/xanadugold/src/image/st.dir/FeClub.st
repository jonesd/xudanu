'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:56 pm'!

FeWork subclass: #FeClub
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeClub comment:
'A persistent Club on the Server.'!

(FeClub getOrMakeCxxClassDescription)
	friends:
'/* friends for class FeClub */

friend class BeClub;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeClub methodsFor: 'signing'!

{void CLIENT} removeSignatureClub
	"Essential.  Irrevocably remove signature authority for this Club. Requires ownership authority."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	self beClub setSignatureClub: NULL!

{void CLIENT} setSignatureClub: club {ID | NULL}
	"Essential.  Change who has signature authority for this Club. Requires ownership authority.
	 Aborts if the Work doesn't have a signature Club."
	
	Ravi knownBug. "need to updateStatus on Works which are designating me as Author"
	club == NULL ifTrue: [Heaper BLAST: #MustNotBeNull].
	(CurrentKeyMaster fluidGet hasAuthority: self owner) 
		ifFalse: [Heaper BLAST: #MustBeOwner].
	self beClub fetchSignatureClub == NULL
		ifTrue: [Heaper BLAST: #SignatureClubIrrevocablyRemoved].
	self beClub setSignatureClub: club!

{ID CLIENT} signatureClub
	"Essential. The Club which has 'signature authority' for this Club. Members of this Club are allowed to endorse with the ID of this Club, and are allowed to use it to sponsor resources. BLASTs if it has been removed"
	
	| result {ID} |
	result := self beClub fetchSignatureClub.
	result == NULL ifTrue: [Heaper BLAST: #SignatureClubIrrevocablyRemoved].
	^result! !

!FeClub methodsFor: 'server'!

{BeClub} beClub

	^self fetchBe cast: BeClub! !

!FeClub methodsFor: 'smalltalk: defaults'!

{FeEdition CLIENT} sponsoredWorks

	^self sponsoredWorks: NULL! !

!FeClub methodsFor: 'managing storage'!

{FeEdition CLIENT} sponsoredWorks: filter {Filter default: NULL}
	"Essential.  All of the Works sponsored by this Club. If a Filter is given, then restricts the result to Works which pass the filter. The result can be wrapped with a Set. This does not require any permissions."
	
	| iDSpace {IDSpace} array {PtrArray of: FeWork} index {Int32} |
	array := PtrArray nulls: self beClub sponsored count DOTasLong.
	index := Int32Zero.
	self beClub sponsored stepper forEach: [ :be {BeWork} |
		(filter == NULL or: [filter match: be endorsements]) ifTrue:
			[array at: index store: (FeWork on: be).
			index := index + 1]].
	iDSpace := IDSpace unique.
	index < array count ifTrue:
		[array := (array copy: index) cast: PtrArray].
	^FeEdition on: (CurrentGrandMap fluidGet
		newValueEdition: array
		with: (iDSpace newIDs: array count)
		with: iDSpace getAscending)! !

!FeClub methodsFor: 'private: create'!

create: be {BeClub}

	super create: be.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeClub class
	instanceVariableNames: ''!

(FeClub getOrMakeCxxClassDescription)
	friends:
'/* friends for class FeClub */

friend class BeClub;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeClub class methodsFor: 'creation'!

{FeClub CLIENT} make: status {FeEdition}
	"Essential.  Create a new Club whose initial status is described in the given ClubDescription Edition. The reader, editor and owner are taken from the current settings. If the KeyMaster has edit permission, then the Club Work is initially grabbed by it. The Club Work is initially sponsored by the CurrentSponsor.
	Note: Unlike ordinary Works, a newly created Club is assigned a global ID."
	
	FeKeyMaster assertSponsorship.
	FeKeyMaster assertSignatureAuthority.
	^(CurrentGrandMap fluidGet newClub: status) makeLockedFeWork cast: FeClub!

{FeClub} on: be {BeClub}

	| result {FeClub} |
	result := self create: be.
	be addFeRangeElement: result.
	^result! !

!FeClub class methodsFor: 'smalltalk: system'!

info.stProtocol
"{void CLIENT} removeSignatureClub
{void CLIENT} setSignatureClub: club {ID}
{ID CLIENT} signatureClub
{FeEdition CLIENT} sponsoredWorks: filter {Filter default: NULL}
"! !