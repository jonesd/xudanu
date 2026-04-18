'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:08 pm'!

Tester subclass: #WorksTester
	instanceVariableNames: '
		myConnection {Connection NOCOPY}
		myCR {Character star NOCOPY}
		myTestID {ID NOCOPY}'
	classVariableNames: 'TheTester {WorksTester} '
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(WorksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WorksTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	
	| testID {ID} |
	myConnection := Connection make: FeServer.
	myConnection bootHeaper.
	CurrentKeyMaster fluidSet: 
		((FeServer loginByName: (WorksTester sequence: 'Test')) cast: BooLock) boo.
	CurrentKeyMaster fluidGet incorporate: FeKeyMaster makePublic.
	testID := WorksTester clubID: (WorksTester sequence: 'Test').
	InitialOwner fluidSet: testID.
	InitialReadClub fluidSet: testID.
	InitialEditClub fluidSet: testID.
	InitialSponsor fluidSet: testID.
	CurrentAuthor fluidSet: testID.
	
	self makeEditionTestOn: oo.
	self editionTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.

	self crossTestOn: oo.
	self compareTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	
	self globalIDTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self workTestOn: oo.
	self endorseTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self historyTestOn: oo.
	self sponsorTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self kmTestOn: oo.

	self transclusionsTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self transcludersBugTestOn: oo.

	self ownerTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	self labelTestOn: oo.
[CurrentPacker fluidGet destroyAbandoned] smalltalkOnly.
	
	FeServer waitForWrite: (WorksWaitDetector make: oo with: 'Test done!!').! !

!WorksTester methodsFor: 'tests'!

{void} compareTestOn: oo {ostream reference}
	"Test the various version comparision operations"
	
	| a {FeEdition} b {FeEdition} work1 {FeWork} work2 {FeWork} work3 {FeWork} edn {FeEdition} region {XnRegion} |
	a := FeEdition placeHolders: (IntegerRegion interval: Int32Zero with:100).
	b := (((a copy: (IntegerSpace make below: (IntegerPos make: 50) with: false))
		transformedBy: (IntegerSpace make translation: 100))
		combine: (FeEdition placeHolders: (IntegerSpace make interval: (IntegerPos make: Int32Zero) with: (IntegerPos make: 50))))
		combine: ((a copy: (IntegerSpace make interval: (IntegerPos make: 25) with: (IntegerPos make: 75)))
		transformedBy: (IntegerSpace make translation: 25)).
	oo << 'a sharedWith b: ' << (a sharedWith: b) << myCR
		<< 'a notSharedWith b: ' << (a notSharedWith: b) << myCR
		<< 'a sharedRegion b: ' << (a sharedRegion: b) << myCR
		<< 'a mapSharedTo b: ' << (a mapSharedTo: b) << myCR
		<< 'a sharedRegion b copy [120,130): '
			<< (a sharedRegion: (b copy: (IntegerRegion make: 120 with: 130))) << myCR
		<< 'a keysOf a[50]: ' << (a positionsOf: (a get: (IntegerPos make: 50))) << myCR
		<< 'b sharedWith a: ' << (b sharedWith: a) << myCR
		<< 'b notSharedWith a: ' << (b notSharedWith: a) << myCR
		<< 'b mapSharedTo a: ' << (b mapSharedTo: a) << myCR
		<< 'b sharedRegion a: ' << (b sharedRegion: a) << myCR
		<< 'b sharedRegion a copy [20,30): '
			<< (b sharedRegion: (a copy: (IntegerRegion make: 20 with: 30))) << myCR
		<< 'b positionsOf a[50]: ' << (b positionsOf: (a get: (IntegerPos make: 50))) << myCR.
	work1 := FeWork make: (FeText make: (UInt8Array string: 'foo')) edition.
	work2 := FeWork make: (FeEdition fromOne: Int32Zero integer with: work1).
	edn := FeEdition fromOne: Int32Zero integer with: work1.
	work3 := work2 edition theOne cast: FeWork.
	region := edn positionsOf: work3.
	oo << 'region = ' << region << myCR.!

{void} crossTestOn: oo {ostream reference}

	| four {PtrArray} is {IDSpace} cross {CrossSpace} doc {FeEdition} |
	oo << myCR << 'CrossSpace retrieval test' <<myCR.
	four := PtrArray nulls: 4.
	is := IDSpace unique.
	four at: UInt32Zero store: is.
	four at: 1 store: IntegerSpace make.
	four at: 2 store: IntegerSpace make.
	four at: 3 store: IntegerSpace make.
	cross := CrossSpace make: four.
	doc := FeEdition empty: cross.
	
	1 to: 10 do: [ :i {Int32} |
		four at: UInt32Zero store: is newID asRegion.
		four at: 1 store: (IntegerSpace make interval: (IntegerPos make: i) with: (IntegerPos make: i + 4)).
		four at: 2 store: (IntegerSpace make interval: (IntegerPos make: i) with: (IntegerPos make: 21 - i)).
		four at: 3 store: (IntegerSpace make interval: (IntegerPos make: i) with: (IntegerPos make: i + 1)).
		doc := doc combine: (FeEdition fromAll: (cross crossOfRegions: four)
			with: (FeDataHolder make: (PrimIntValue make: i)))].
	
	1 to: 3 do: [ :j {Int32} |
		oo << 'Looking for dimension ' << j << ' >= 10' << myCR.
		(doc copy: (cross extrusion: j with: (IntegerSpace make above: (IntegerPos make: 10) with: true)))
			retrieve forEach: [ :bundle {FeElementBundle} |
				oo << 'found ' << bundle element << ' at ' << bundle region << myCR]].!

{void} editionTestOn: oo {ostream reference}
	"Test the simple Edition operations"
	
	| edition {FeEdition} |
	oo << 'Testing various Edition operations' << myCR.
	edition := FeEdition empty: IntegerSpace make.
	oo << 'initially: ' << edition << myCR
		<< ' coordinateSpace: ' << edition coordinateSpace << myCR
		<< ' count: ' << edition count << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR.
	edition := edition with: (IntegerPos make: Int32Zero) with: FeRangeElement placeHolder.
	oo << 'with(0): ' << edition << myCR
		<< ' theOne: ' << edition theOne << myCR.
	edition := edition withAll: (IntegerSpace make above: (IntegerPos make: 1) with: true)
		with: (FeDataHolder make: (PrimIntValue make: 65)).
	oo << 'withAll: ' << edition << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR.
	oo << 'stepper:' << myCR.
	[ScruTable] USES.
	(edition stepper: (IntegerSpace make interval: (IntegerPos make: IntegerVarZero) with: (IntegerPos make: 2))) forPositions:
		[ :p {Position} :v {FeRangeElement} |
		oo << ' ' << p << ' -> ' << v << myCR].
	edition := edition without: (IntegerPos make: 3).
	oo << 'without 3' << edition << myCR.
	edition := edition withoutAll: (IntegerSpace make above: (IntegerPos make: 2) with: true).
	oo << 'withoutAll: ' << edition << myCR
		<< ' count: ' << edition count << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR
		<< ' get 1: ' << (edition get: (IntegerPos make: 1)) << myCR.
	
	oo << 'combined: ' << (edition combine: (FeEdition fromOne: (IntegerPos make: 5)
			with: FeRangeElement placeHolder)) << myCR.
	oo << 'replaced: ' << (edition replace: (FeEdition fromOne: (IntegerPos make: 1)
			with: FeRangeElement placeHolder)) << myCR.!

{void} endorseTestOn: oo {ostream reference}
	"Test endorsing and unendorsing Editions and Works"
	
	| e1 {FeEdition} w1 {FeWork} iD {ID} userRegion {IDRegion} |
	e1 := FeEdition empty: IntegerSpace make.
	w1 := FeWork make: e1.
	oo << 'Initial endorsements:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR << myCR.
	
	userRegion _ CurrentAuthor fluidGet asRegion cast: IDRegion.
	e1 endorse: (FeServer endorsementRegion: userRegion with: userRegion).
	iD := IDSpace global newID.
	w1 endorse: (FeServer endorsementRegion: userRegion with: (iD asRegion cast: IDRegion)).
	oo << 'After endorsing:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR.
	
	e1 retract: (FeServer endorsementRegion: userRegion with: userRegion).
	w1 retract: (FeServer endorsementRegion: userRegion with: (iD asRegion cast: IDRegion)).
	oo << 'After unendorsing:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR.!

{void} globalIDTestOn: oo {ostream reference}
	"Test assigning and retrieving by global IDs"
	
	| p1 {FeRangeElement as: FePlaceHolder} id1a {ID} id1b {ID} ids {IDRegion}
	  p2 {FeRangeElement as: FePlaceHolder} id2 {ID} ed {FeEdition} |
	p1 := FeRangeElement placeHolder.
	(ids := FeServer iDsOf: p1) isEmpty ifFalse:
		[oo << 'Newly created place holder ' << p1
			<< ' should not have had any IDs but was reported to have ' << ids << myCR].
	id1a := FeServer assignID: p1.
	((ids := FeServer iDsOf: p1) isEqual: id1a asRegion) ifFalse:
		[oo << 'PlaceHolder ' << p1
			<< ' should have IDs ' << id1a asRegion
			<< ' but was reported to have IDs ' << ids << myCR].
	id1b := FeServer assignID: p1.
	((ids := FeServer iDsOf: p1) isEqual: (id1a asRegion with: id1b)) ifFalse:
		[oo << 'PlaceHolder ' << p1
			<< ' should have IDs ' << (id1a asRegion with: id1b)
			<< ' but was reported to have IDs ' << ids << myCR].
	p2 := FeRangeElement placeHolder.
	id2 := FeServer assignID: p2.
	ed := (FeEdition fromOne: (IntegerPos make: Int32Zero) with: p1)
		combine: (FeEdition fromOne: (IntegerPos make: 1) with: p2).
	((ids := FeServer iDsOfRange: ed)
			isEqual: ((id1a asRegion with: id1b) with: id2))
		ifFalse:
			[oo << 'PlaceHolders ' << ed
				<< ' should have IDs ' << ((id1a asRegion with: id1b) with: id2)
				<< ' but was reported to have IDs ' << ids << myCR].

	oo << 'Global ID assignment test successful
'!

{void} historyTestOn: oo {ostream reference}
	| work {FeWork} |
	work _ FeWork make: (FeEdition fromArray: (WorksTester string: 'Howdy doody.')).
	work setHistoryClub: FeServer publicClubID.
	work revise: (FeEdition fromArray: (WorksTester string: 'Good bye')).
	work revise: (FeEdition fromArray: (WorksTester string: 'Much better.')).
	oo << 'The trail is: ' << work revisions << myCR.
	work revisions stepper forPositions: 
		[:position {Position} :value {FeWork} |
		oo << position << '->' << (value edition retrieve theOne cast: FeArrayBundle) array << myCR].
	
	"self halt."
	oo << myCR.!

{void} kmTestOn: oo {ostream reference}
	"Test the operation of KeyMasters"
	
	| km {FeKeyMaster} clubspec {FeWrapperSpec} test {FeClub}
	  club1 {FeClub} detect1 {FeStatusDetector} work1 {FeWork}
	  club2 {FeClub} detect2 {FeStatusDetector} work2 {FeWork}
	  desc {FeClubDescription}  |
	
	km := CurrentKeyMaster fluidGet copy.
	CurrentKeyMaster fluidBind: km during:
		[clubspec := FeWrapperSpec get: (WorksTester sequence: 'ClubDescription').
		test := (FeServer get: CurrentAuthor fluidGet) cast: FeClub.
		
		club1 := FeClub make: 
				(FeClubDescription make: FeSet make with: FeBooLockSmith make) edition.
		oo << 'Club1 ' << (FeServer iDOf: club1) << ' is initially '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'and CurrentKeyMaster is ' << km actualAuthority << myCR << myCR.

		oo << 'Logged in as ' << ((FeServer login: (FeServer iDOf: club1)) cast: BooLock) boo.
		
		club2 := FeClub make: (FeClubDescription make: FeSet make with: FeBooLockSmith make) edition.
		oo << 'Club 2 ' << (FeServer iDOf: club2) << ' is initially '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'and CurrentKeyMaster is ' << km actualAuthority << myCR << myCR.
		
		InitialEditClub fluidBind: (FeServer iDOf: club1) during:
		[InitialReadClub fluidBind: (FeServer iDOf: club1) during:
			[work1 := FeWork make: (FeEdition empty: IntegerSpace make)]].
		detect1 := (WorksTestStatusDetector make: oo with: '
Work 1').
		work1 addStatusDetector: detect1.
		oo << 'Giving Work 1 edit authority to Club 1' << myCR.
		work1 requestGrab.
		
		InitialEditClub fluidBind: (FeServer iDOf: club2) during:
			[work2 := FeWork make: (FeEdition empty: IntegerSpace make)].
		detect2 := (WorksTestStatusDetector make: oo with: '
Work 2').
		work2 addStatusDetector: detect2.
		oo << 'Giving Work 2 edit authority to Club 2' << myCR.
		work2 requestGrab.
		
		desc := (clubspec wrap: club1 edition) cast: FeClubDescription.
		club1 revise: (desc withMembership: (desc membership with: test)) edition.
		oo << 'Club 1 should now have Test as a member: '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'So CurrentKeyMaster should have Club 1 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 1 should have become grabbed: ' << work1 canRevise << myCR << myCR.
		
		desc := (clubspec wrap: club2 edition) cast: FeClubDescription.
		club2 revise: (desc withMembership: (desc membership with: club1)) edition.
		oo << 'Club 2 should now have Club 1 as a member: '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'So CurrentKeyMaster should have Club 2 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 2 should have become grabbed: ' << work2 canRevise << myCR << myCR.
		
		desc := (clubspec wrap: club2 edition) cast: FeClubDescription.
		club2 revise: (desc
			withMembership: ((desc membership
				without: club1) with: (FeServer get: FeServer publicClubID))) edition.
		oo << 'Club 2 should have Public but not Club 1 as a member: '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'So CurrentKeyMaster should retain Club 2 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 2 should remain grabbed: ' << work2 canRevise << myCR << myCR.
		
		km removeLogins: (FeServer publicClubID asRegion cast: IDRegion).
		oo << 'The combined KeyMaster should have lost Public & Club 2 authority: '
			<< ' login ' << km loginAuthority << myCR
			<< ' actual ' << km actualAuthority << myCR
			<< 'and Work 2 should have become released but readable:'
			<< ' canRevise ' << work2 canRevise
			<< ' canRead ' << work2 canRead << myCR << myCR.
		
		desc := (clubspec wrap: club1 edition) cast: FeClubDescription.
		club1 revise: (desc withMembership: (desc membership without: test)) edition.
		oo << 'Club 1 should no longer have Test as a member: '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'So CurrentKeyMaster should not have Club 1 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 1 should have become released and unreadable:'
			<< ' canRevise ' << work1 canRevise
			<< ' canRead ' << work1 canRead << myCR << myCR.
		
		"work2 removeStatusDetector: detect2."
		"work1 removeStatusDetector: detect1."
		club1 release.
		club2 release].

	self thingToDo. "Clean up persistent information in Server"!

{void} labelTestOn: oo {ostream reference}
	|    edition {FeEdition} e1 {FeEdition} e2 {FeEdition} e3 {FeEdition} 
	  e4 {FeEdition} e1prime {FeEdition} edition2 {FeEdition} |
	e1 _ FeEdition fromArray: (WorksTester string: 'First Edition').
	e2 _ FeEdition fromArray: (WorksTester string: 'Second Edition').
	e3 _ FeEdition fromArray: (WorksTester string: 'Third Edition').
	e4 _ FeEdition fromArray: (WorksTester string: 'Fourth Edition').
	
	edition _ FeEdition fromArray: (PrimSpec pointer arrayWithThree: e1 with: e2 with: (FeWork make: e1)).
	
	oo << 'Labels:' << myCR.
	oo << ' ' << e1 label << ' ' << e2 label << ' ' << e3 label << ' ' << e4 label << myCR.
	oo << 'labelled e1: '<< (edition positionsLabelled: e1 label) << myCR.
	e1prime _ ((edition fetch: (IntegerPos make: IntegerVarZero)) cast: FeEdition) with: (IntegerPos make: 1) with: FeRangeElement placeHolder.
	
	edition2 _ edition with: (IntegerPos make: IntegerVarZero) with: e1prime.
	oo << 'edit e1: ' << (edition2 positionsLabelled: e1 label) << myCR.
	
	oo << 'labelled e2: ' << (edition2 positionsLabelled: e2 label) << myCR.
	oo << 'rebind e2: ' << ((edition2 rebind: (IntegerPos make: 1) with: e3) positionsLabelled: e2 label) << myCR.
	oo << 'duplicate e1: ' << ((edition2 with: (IntegerPos make: 1) with: e1) positionsLabelled: e1 label) << myCR.
	
	oo << myCR.!

{void} makeEditionTestOn: oo {ostream reference}
	"Try making Editions in a variety of ways"
	
	| edn {FeEdition} place {FeRangeElement} data {FeDataHolder} bits {PrimArray} |
	oo << (edn := FeEdition empty: SequenceSpace make) << myCR
		<< (FeEdition empty: IntegerSpace make) << myCR.
	
	oo << (FeEdition placeHolders: (IntegerSpace make interval: (IntegerPos make: IntegerVarZero) with: (IntegerPos make: 10))) << myCR
		<< (FeEdition placeHolders: SequenceSpace make emptyRegion) << myCR
		<< (FeEdition placeHolders: SequenceSpace make fullRegion) << myCR.
	
	data := FeDataHolder make: (PrimIntValue make: 3).
	place := FeRangeElement placeHolder.
	oo << (FeEdition fromOne: (IntegerPos make: IntegerVarZero) with: edn) << myCR
		<< (FeEdition fromOne: (IntegerPos make: 1) with: place) << myCR
		<< (FeEdition fromOne: (IntegerPos make: 2) with: data) << myCR.
	
	oo << (FeEdition fromAll: (IntegerSpace make above: (IntegerPos make: 10) with: true) with: edn) << myCR
		<< (FeEdition fromAll: (IntegerSpace make below: (IntegerPos make: 100) with: false) with: place) << myCR
		<< (FeEdition fromAll: IntegerSpace make emptyRegion with: place) << myCR
		<< (FeEdition fromAll: IDSpace unique fullRegion with: data) << myCR.
	
	oo << (FeEdition fromArray: (WorksTester string: '')) << myCR.
	oo << (FeEdition fromArray: (WorksTester string: 'hello world')) << myCR.
	
	bits := WorksTester string: 'hello world!!'.
	oo << (FeEdition fromArray: bits) << myCR
		<< (FeEdition fromArray: bits with: (IntegerSpace make interval: (IntegerPos make: 10) with: (IntegerPos make: 22))) << myCR
		"<< (FeEdition fromArray: bits
			with: NULL
			with: IntegerSpace make getDescending) << myCR
		<< (FeEdition fromArray: bits
			with: (IntegerSpace make interval: (IntegerPos make: 100) with: (IntegerPos make: 113))
			with: IntegerSpace make getDescending) << myCR".
	
	oo << 'Making Editions test finished' << myCR << myCR.!

{void} ownerTestOn: oo {ostream reference}
	|  work {FeWork} club {FeClub} edition {FeEdition} |
	club := (FeServer get: FeServer publicClubID) cast: FeClub.
	oo << 'Club: ' << club << ' owned by: ' << club owner << myCR.

	InitialOwner fluidBind: CurrentAuthor fluidGet during:
		[work _ FeWork make: (FeEdition fromArray: (WorksTester string: 'The one I can change.'))].
	oo << 'Work: ' << work << ' owned by: ' << work owner << myCR.
	
	edition _ FeEdition fromArray: (PrimSpec pointer arrayWithTwo: work with: club) 
		with: ((WorksTester sequence: 'changeable') asRegion with: (WorksTester sequence: 'permanent'))
		with: SequenceSpace make ascending.
	
	oo << 'Set owners of: ' << edition << myCR.
	oo << 'result: ' << (edition setRangeOwners: FeServer publicClubID) << myCR.

	oo << 'Club: ' << club << ' owned by: ' << club owner << myCR.
	oo << 'Work: ' << work << ' owned by: ' << work owner << myCR.
	
	oo << myCR.!

{void} sponsorTestOn: oo {ostream reference}
	"Test the sponsoring mechanism"
	
	| club {FeClub} testClub {FeClub} blank {FeEdition} w1 {FeWork} w2 {FeWork} |
	testClub := (FeServer get: CurrentAuthor fluidGet) cast: FeClub.
	club := FeClub make: 
			(FeClubDescription make: 
				(FeSet make: 
					((PrimSpec pointer arrayWith: (FeServer get: CurrentAuthor fluidGet)) cast: PtrArray))
		with: FeWallLockSmith make) edition.
	
	blank := FeEdition fromArray: (UInt8Array string:'blank').
	w1 := FeWork make: blank.
	FeServer assignID: w1.
	w2 := FeWork make: blank.
	FeServer assignID: w1.
	oo << 'Initially ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	w1 sponsor: (CurrentAuthor fluidGet asRegion cast: IDRegion).
	w2 sponsor: ((CurrentAuthor fluidGet asRegion
					with: (FeServer iDOf: club)) cast: IDRegion).
	oo << 'After sponsoring ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	w1 unsponsor: (CurrentAuthor fluidGet asRegion cast: IDRegion).
	w2 unsponsor: ((CurrentAuthor fluidGet asRegion
					with: (FeServer iDOf: club)) cast: IDRegion).
	oo << 'After unsponsoring ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	
	self thingToDo. "test authority checks"
	self thingToDo. "get rid of persistent info"!

{void} transcludersBugTestOn: oo {ostream reference}
	
	|  text {FeText} refs {FeEdition} work {FeWork}
	  detector {FeFillRangeDetector} container {FeEdition}
	  text2 {FeText} values {PtrArray} |

	oo << myCR << myCR << 'Transcluders bug test' << myCR << myCR.

	"Test a bug in the transcluders mechanism:
		if E1 = {x -> E2}, then E1 transcluders will be triggered by an Edition containing E2"
	text := FeText make: ((WorksTester string: 'oops') cast: PrimDataArray).
	container := FeEdition fromOne: 1 integer with: text edition.
	refs := container transcluders: (FeWrapperSpec get: (WorksTester sequence: 'HyperRef')) filter.
	detector := WorksTestFillRangeDetector make: oo
		with: 'Should not have been transcluded by '.
	refs addFillRangeDetector: detector.
	work := FeWork make: (FeSingleRef make: text edition) edition.
	refs removeFillRangeDetector: detector.
	
	"if E1 = {x -> E2, y -> E3}, then E1 transcluders may be triggered by another separately created Edition containing E1 & E2?"
	values := PtrArray nulls: 2.
	text2 := FeText make: ((WorksTester string: 'oops') cast: PrimDataArray).
	values at: UInt32Zero store: text edition.
	values at: 1 store: text2 edition.
	container := FeEdition fromArray: values.
	refs := container transcluders: (FeWrapperSpec get: (WorksTester sequence: 'HyperRef')) filter.
	refs addFillRangeDetector: detector.
	work revise: (FeEdition fromArray: values).
	refs removeFillRangeDetector: detector.!

{void} transclusionsTestOn: oo {ostream reference}
	"Test the transclusions query"
	
	|  text {FeText} n {IntegerVar} texts {FeEdition} refs {FeEdition}
	  detector {FeFillRangeDetector} work {FeWork} interval {IntegerRegion} |

	oo << myCR << myCR << 'Transclusions test' << myCR << myCR.
	text := FeText make: ((WorksTester string: '(abcdefghijklmnopqrstuvwxyz)') cast: PrimDataArray).
	n := text count.
	work := FeWork make: (FeSingleRef make: text edition) edition.
	texts := text edition rangeTranscluders: NULL
		with: (FeWrapperSpec get: (WorksTester sequence: 'Text')) filter.
	refs := text edition rangeTranscluders: NULL
		with: (FeWrapperSpec get: (WorksTester sequence: 'HyperRef')) filter.
	detector := WorksTestFillRangeDetector make: oo with: 'Transcluded by '.
	texts addFillRangeDetector: detector.
	refs addFillRangeDetector: detector.

	interval _ IntegerSpace make interval: (IntegerPos make: (n // 2)) with: (IntegerPos make: n).
	text := text move: IntegerVarZero with: interval.
	work revise: (FeSingleRef make: text edition) edition.
	text := text extract: ((IntegerRegion integerExtent: n // 4 with: n // 4) complement cast: IntegerRegion).
	work revise: (FeSingleRef make: text edition) edition.
	text := text insert: n // 2 with: (FeText make: (((WorksTester string: '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]')) cast: PrimDataArray)).
	work revise: (FeSingleRef make: text edition) edition.
	
	texts := text edition rangeTranscluders: interval
		with: (FeWrapperSpec get: (WorksTester sequence: 'Text')) filter
		with: NULL
		with: Int32Zero
		with: texts.
	refs := text edition rangeTranscluders: interval
		with: (FeWrapperSpec get: (WorksTester sequence: 'HyperRef')) filter
		with: NULL
		with: Int32Zero
		with: refs.
	
	text := text extract: (IntegerSpace make above: (IntegerPos make: n // 2) with: true).
	work revise: (FeSingleRef make: text edition) edition.
	text := text extract: (IntegerSpace make below: (IntegerPos make: n) with: false).
	work revise: (FeSingleRef make: text edition) edition.
	text := text move: IntegerVarZero with: interval.
	work revise: (FeSingleRef make: text edition) edition.
	
	texts removeFillRangeDetector: (detector cast: FeFillRangeDetector).
	refs removeFillRangeDetector: (detector cast: FeFillRangeDetector).!

{void} workTestOn: oo {ostream reference}
	"Try the various operations on Works"
	
	| e1 {FeEdition} w1 {FeWork} km {FeKeyMaster} |
	e1 := FeEdition fromArray: (WorksTester string: 'hello world').
	w1 := FeWork make: e1.
	self dumpWorkOn: oo with: 'As newly created ' with: w1.
	
	w1 addStatusDetector: (WorksTestStatusDetector make: oo with: '
Work 1').
	w1 release.
	
	self dumpWorkOn: oo with: 'With authority restored' with: w1.
	w1 grab.
	self dumpWorkOn: oo with: 'Grabbed' with: w1.
	CurrentKeyMaster fluidBind: ((FeServer loginByName: (Sequence string: 'Test')) cast: BooLock) boo during:
		[w1 grab.
		self dumpWorkOn: oo with: 'Grabbed again' with: w1].
	w1 requestGrab.
	self dumpWorkOn: oo with: 'Grab requested again' with: w1.
	w1 release.
	self dumpWorkOn: oo with: 'Released' with: w1.

	km := FeKeyMaster makePublic.
	CurrentKeyMaster fluidBind: km during:
		[w1 requestGrab.
		self dumpWorkOn: oo with: 'Grab requested yet again' with: w1.
		km incorporate: ((FeServer loginByName: (Sequence string: 'Test')) cast: BooLock) boo.
		self dumpWorkOn: oo with: 'KeyMaster incorporated' with: w1].
	
	km removeLogins: (CurrentAuthor fluidGet asRegion cast: IDRegion).
	self dumpWorkOn: oo with: 'KeyMaster login removed' with: w1.! !

!WorksTester methodsFor: 'private:'!

{void} dumpWorkOn: oo {ostream reference} with: tag {char star} with: work {FeWork}
	"Print the state and contents of a Work"
	
	oo << myCR << tag << '['.
	work canRead ifTrue:
		[oo << work edition].
	work canRevise ifTrue:
		[oo << ' (grabbed)'].
	oo << ']'! !

!WorksTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartWorksTester: rcvr {Rcvr unused default: NULL}

	myConnection := NULL.
	myCR := '
'! !

!WorksTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartWorksTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WorksTester class
	instanceVariableNames: ''!

(WorksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WorksTester class methodsFor: 'server library'!

{ID} clubID: clubName {Sequence}
	"Looks up the ID of a named Club in the directory maintained by the System Admin Club. Requires read permission on the directory. Blasts if there is no Club with that name."
	
	^FeServer iDOf: (((FeServer get: FeServer clubDirectoryID) cast: FeWork) edition get: clubName)!

{IntegerPos} integer: val {IntegerVar}

	^ IntegerPos make: val!

{Sequence} sequence: string {char star}

	^ Sequence string: string!

{PrimArray} string: string {char star}

	^UInt8Array string: string! !

!WorksTester class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	TheTester := NULL!

staticTimeNonInherited
	"PrServer defineFluid: #ClientServer with: XuPromise emulsion with: [NULL]"! !