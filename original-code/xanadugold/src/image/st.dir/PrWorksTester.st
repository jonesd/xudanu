'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:06 pm'!

Tester subclass: #PrWorksTester
	instanceVariableNames: '
		myConnection {Connection NOCOPY}
		myServer {PrServer NOCOPY}
		myCR {Character NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(PrWorksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #SMALLTALK.ONLY; yourself)!

!PrWorksTester methodsFor: 'private:'!

{void} dumpWorkOn: oo {ostream reference} with: tag {char star} with: work {PrWork}
	"Print the state and contents of a Work"
	
	oo << tag << $[.
	work canRead value ifTrue:
		[oo << work edition].
	work canRevise value ifTrue:
		[oo << ' (grabbed)'].
	oo << $]! !

!PrWorksTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartWorksTester: rcvr {Rcvr unused default: NULL}

	myServer _ NULL.
	myConnection := NULL.
	myCR := Character cr.! !

!PrWorksTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	
	| gk {XuServer} testID {XuID} |
	myConnection := Connection make: XuServer.
	gk := myConnection bootHeaper cast: XuServer.
	XuCurrentKeyMaster fluidSet: 
		((gk loginByName: (PrWorksTester sequence: 'Test'))
			delayCast: XuBooLock) boo.
	PrCurrentServer fluidSet: myServer.
	XuCurrentKeyMaster fluidGet incorporate: XuKeyMaster make.
	testID := PrWorksTester clubID: (PrWorksTester sequence: 'Test').
	XuInitialOwner fluidSet: testID.
	XuInitialReadClub fluidSet: testID.
	XuInitialEditClub fluidSet: testID.
	XuInitialSponsor fluidSet: testID.
	XuCurrentAuthor fluidSet: testID.
	
	self makeEditionTestOn: oo.
	self editionTestOn: oo.
	self compareTestOn: oo.
	
	self globalIDTestOn: oo.
	self workTestOn: oo.
	self endorseTestOn: oo.
	self historyTestOn: oo.
	self sponsorTestOn: oo.
	self kmTestOn: oo.

	"self transclusionsTestOn: oo."

	self ownerTestOn: oo.
	self labelTestOn: oo.
	
	XuServer waitForWrite: (WorksWaitDetector create: oo with: 'Test done!!').! !

!PrWorksTester methodsFor: 'tests'!

{void} compareTestOn: oo {ostream reference}
	"Test the various version comparision operations"
	
	| a {XuEdition} b {XuEdition} |
	a := myServer newPlaceHolders: (myServer integerSpace interval: (XuInteger make: Int32Zero) with: (XuInteger make: 100)).
	b := (((a copy: (myServer integerSpace below: (XuInteger make: 50) with: (XuInteger make: false)))
		transformedBy: (myServer integerSpace translation: (XuInteger make: 100)))
		combine: (myServer newPlaceHolders: (myServer integerSpace interval: (XuInteger make: Int32Zero) with: (XuInteger make: 50))))
		combine: ((a copy: (myServer integerSpace interval: (XuInteger make: 25) with: (XuInteger make: 75)))
		transformedBy: (myServer integerSpace translation: (XuInteger make: 25))).
	oo << 'a sharedWith b: ' << (a sharedWith: b) << myCR
		<< 'a notSharedWith b: ' << (a notSharedWith: b) << myCR
		<< 'a sharedRegion b: ' << (a sharedRegion: b) << myCR
		<< 'a mapSharedTo b: ' << (a mapSharedTo: b) << myCR
		<< 'a keysOf a[50]: ' << (a positionsOf: (a get: (PrWorksTester integer: 50))) << myCR
		<< 'b sharedWith a: ' << (b sharedWith: a) << myCR
		<< 'b notSharedWith a: ' << (b notSharedWith: a) << myCR
		<< 'b mapSharedTo a: ' << (b mapSharedTo: a) << myCR
		<< 'b sharedRegion a: ' << (b sharedRegion: a) << myCR
		<< 'b positionsOf a[50]: ' << (b positionsOf: (a get: (PrWorksTester integer: 50))) << myCR.!

{void} editionTestOn: oo {ostream reference}
	"Test the simple Edition operations"
	
	| edition {XuEdition} |
	oo << 'Testing various Edition operations' << myCR.
	edition := myServer newEmptyEdition: myServer integerSpace.
	oo << 'initially: ' << edition << myCR
		<< ' coordinateSpace: ' << edition coordinateSpace << myCR
		<< ' count: ' << edition count << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR.
	edition := edition with: (PrWorksTester integer: Int32Zero) with: myServer newPlaceHolder.
	oo << 'with(0): ' << edition << myCR
		<< ' theOne: ' << edition theOne << myCR.
	edition := edition withAll: (myServer integerSpace above: (XuInteger make: 1) with: (XuInteger make: true))
		with: (myServer newDataHolder: (PrWorksTester uInt8Spec value: (XuInteger make: 65))).
	oo << 'withAll: ' << edition << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR.
	oo << 'stepper:' << myCR.
	(edition stepper: (myServer integerSpace interval: (XuInteger make: IntegerVarZero) with: (XuInteger make: 2))) forPromisedPairs:
		[ :k {Position} :v {XuRangeElement} |
		oo << ' ' << k << ' -> ' << v << myCR].
	edition := edition without: (PrWorksTester integer: 3).
	oo << 'without 3' << edition << myCR.
	edition := edition withoutAll: (myServer integerSpace above: (XuInteger make: 2) with: (XuInteger make: true)).
	oo << 'withoutAll: ' << edition << myCR
		<< ' count: ' << edition count << myCR
		<< ' domain: ' << edition domain << myCR
		<< ' isEmpty: ' << edition isEmpty << myCR
		<< ' isFinite: ' << edition isFinite << myCR
		<< ' get 1: ' << (edition get: (PrWorksTester integer: 1)) << myCR.
	
	oo << 'combined: ' << (edition combine: (myServer
			newEditionWith: (PrWorksTester integer: 5)
			with: myServer newPlaceHolder)) << myCR.
	oo << 'replaced: ' << (edition replace: (myServer
			newEditionWith: (PrWorksTester integer: 1)
			with: myServer newPlaceHolder)) << myCR.!

{void} endorseTestOn: oo {ostream reference}
	"Test endorsing and unendorsing Editions and Works"
	
	| e1 {PrEdition} w1 {PrWork} iD {PrID} userRegion {PrIDRegion} |
	e1 := myServer newEmptyEdition: myServer integerSpace.
	w1 := myServer newWork: e1.
	oo << 'Initial endorsements:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR << myCR.
	
	userRegion _ PrCurrentAuthor fluidGet asRegion delayCast: PrIDRegion.
	e1 endorse: (myServer endorsementRegion: userRegion with: userRegion).
	iD := XuIDSpace global newID.
	w1 endorse: (myServer endorsementRegion: userRegion with: (iD asRegion delayCast: PrIDRegion)).
	oo << 'After endorsing:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR.
	
	e1 retract: (myServer endorsementRegion: userRegion with: userRegion).
	w1 retract: (myServer endorsementRegion: userRegion with: (iD asRegion delayCast: PrIDRegion)).
	oo << 'After unendorsing:' << myCR
		<< '  on Edition: ' << e1 endorsements << myCR
		<< '  on Work: ' << w1 endorsements << myCR.!

{void} globalIDTestOn: oo {ostream reference}
	"Test assigning and retrieving by global IDs"
	
	| p1 {PrPlaceHolder} id1a {PrID} id1b {PrID} ids {PrIDRegion}
	  p2 {PrPlaceHolder} id2 {PrID} ed {PrEdition} |
	p1 := myServer newPlaceHolder.
	(ids := myServer iDsOf: p1) isEmpty value ifFalse:
		[oo << 'Newly created place holder ' << p1
			<< ' should not have had any IDs but was reported to have ' << ids << myCR].
	id1a := myServer assignID: p1.
	((ids := myServer iDsOf: p1) areActualsEqual: id1a asRegion) value ifFalse:
		[oo << 'PlaceHolder ' << p1
			<< ' should have IDs ' << id1a asRegion
			<< ' but was reported to have IDs ' << ids << myCR].
	id1b := myServer assignID: p1.
	((ids := myServer iDsOf: p1) areActualsEqual: (id1a asRegion with: id1b)) value ifFalse:
		[oo << 'PlaceHolder ' << p1
			<< ' should have IDs ' << (id1a asRegion with: id1b)
			<< ' but was reported to have IDs ' << ids << myCR].
	p2 := myServer newPlaceHolder.
	id2 := myServer assignID: p2.
	ed := (myServer newEditionWith: (PrWorksTester integer: Int32Zero) with: p1)
		combine: (myServer newEditionWith: (PrWorksTester integer: 1) with: p2).
	((ids := myServer iDsOfRange: ed)
			areActualsEqual: ((id1a asRegion with: id1b) with: id2)) value
		ifFalse:
			[oo << 'PlaceHolders ' << ed
				<< ' should have PrIDs ' << ((id1a asRegion with: id1b) with: id2)
				<< ' but was reported to have IDs ' << ids << myCR].

	oo << 'Global ID assignment test successful
'!

{void} historyTestOn: oo {ostream reference}
	| work {PrWork} |
	work _ myServer newWork: (myServer newEdition: (PrWorksTester string: 'Howdy doody.')).
	work setHistoryClub: myServer publicClubID.
	work revise: (myServer newEmptyEdition: myServer integerSpace).
	work revise: (myServer newEdition: (PrWorksTester string: 'Much better.')).
	oo << 'The trail is: ' << work revisions << myCR.
	work revisions stepper forPromisedPairs: 
		[:key {Position} :value {PrWork} |
		oo << key << '->' << value edition retrieve << myCR].
	
	"self halt."
	oo << myCR.!

{void} kmTestOn: oo {ostream reference}
	"Test the operation of KeyMasters"
	
	| km {PrKeyMaster} s {PrServer} clubspec {PrWrapperSpec} test {PrClub}
	  club1 {PrClub} detect1 {FeStatusDetector} work1 {PrWork}
	  club2 {PrClub} detect2 {FeStatusDetector} work2 {PrWork}
	  desc {PrClubDescription} |
	
	km := PrCurrentKeyMaster fluidGet copy.
	PrCurrentKeyMaster fluidBind: km during:
		[s := myServer.
		clubspec := s wrapperSpec: (PrWorksTester sequence: 'ClubDescription').
		test := (s get: PrCurrentAuthor fluidGet) delayCast: PrClub.
		
		club1 := s newClub: (s
			newClubDescription: s newSet
			with: s newBooLockSmith) edition.
		oo << 'Club1 is initially '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'and CurrentKeyMaster is ' << km << myCR << myCR.

		club2 := s newClub: (s
			newClubDescription: s newSet
			with: s newBooLockSmith) edition.
		oo << 'Club 2 is initially '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'and CurrentKeyMaster is ' << km << myCR << myCR.
		
		PrInitialEditClub fluidBind: (s iDOf: club1) during:
			[work1 := s newWork: (s newEmptyEdition: s integerSpace)].
		detect1 := (WorksTestStatusDetector make: oo with: '
Work 1').
		work1 addStatusDetector: detect1.
		oo << 'Giving Work 1 edit authority to Club 1' << myCR.
		work1 requestGrab.
		
		PrInitialEditClub fluidBind: (s iDOf: club2) during:
			[work2 := s newWork: (s newEmptyEdition: s integerSpace)].
		detect2 := (WorksTestStatusDetector make: oo with: '
Work 2').
		work2 addStatusDetector: detect2.
		oo << 'Giving Work 2 edit authority to Club 2' << myCR.
		work2 requestGrab.
		
		desc := (clubspec wrap: club1 edition) delayCast: PrClubDescription.
		club1 revise: (desc withMembership: (desc membership with: test)) edition.
		oo << 'Club 1 should now have Test as a member: '
			<< (clubspec wrap: club1 edition) << myCR
			<< 'So CurrentKeyMaster should have Club 1 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 1 should have become grabbed: ' << work1 canRevise << myCR << myCR.
		
		desc := (clubspec wrap: club2 edition) delayCast: PrClubDescription.
		club2 revise: (desc withMembership: (desc membership with: club1)) edition.
		oo << 'Club 2 should now have Club 1 as a member: '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'So CurrentKeyMaster should have Club 2 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 2 should have become grabbed: ' << work2 canRevise << myCR << myCR.
		
		desc := (clubspec wrap: club2 edition) delayCast: PrClubDescription.
		club2 revise: (desc withMembership: ((desc membership without: club1) with: test)) edition.
		oo << 'Club 2 should have Public but not Club 1 as a member: '
			<< (clubspec wrap: club2 edition) << myCR
			<< 'So CurrentKeyMaster should retain Club 2 authority: '
			<< km actualAuthority << myCR
			<< 'and Work 2 should remain grabbed: ' << work2 canRevise << myCR << myCR.
		
		km removeLogins: s publicClubID asRegion.
		oo << 'The combined KeyMaster should have lost Public & Club 2 authority: '
			<< km loginAuthority << myCR
			<< km actualAuthority << myCR
			<< 'and Work 2 should have become released but unreadable:'
			<< ' canRevise ' << work2 canRevise
			<< ' canRead ' << work2 canRead << myCR << myCR.
		
		desc := (clubspec wrap: club1 edition) delayCast: PrClubDescription.
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
	| s {PrServer}   edition {PrEdition} e1 {PrEdition} e2 {PrEdition} e3 {PrEdition} 
	  e4 {PrEdition} e1prime {PrEdition} edition2 {PrEdition} |
	s _ myServer.
	e1 _ s newEdition: (PrWorksTester string: 'First Edition').
	e2 _ s newEdition: (PrWorksTester string: 'Second Edition').
	e3 _ s newEdition: (PrWorksTester string: 'Third Edition').
	e4 _ s newEdition: (PrWorksTester string: 'Fourth Edition').
	
	edition _ s newEdition: (myServer pointerSpec arrayWithThree: e1 with: e2 with: (s newWork: e1)).
	
	oo << 'Labels:' << myCR.
	oo << ' ' << e1 label << ' ' << e2 label << ' ' << e3 label << ' ' << e4 label << myCR.
	oo << 'labelled e1: '<< (edition positionsLabelled: e1 label) << myCR.
	e1prime _ (edition fetch: (PrWorksTester integer: IntegerVarZero)) with: (PrWorksTester integer: 1) with: s newPlaceHolder.
	
	edition2 _ edition with: (PrWorksTester integer: IntegerVarZero) with: e1prime.
	oo << 'edit e1: ' << (edition2 positionsLabelled: e1 label) << myCR.
	
	oo << 'labelled e2: ' << (edition2 positionsLabelled: e2 label) << myCR.
	oo << 'rebind e2: ' << ((edition2 rebind: (PrWorksTester integer: 1) with: e3) positionsLabelled: e2 label) << myCR.
	oo << 'duplicate e1: ' << ((edition2 with: (PrWorksTester integer: 1) with: e1) positionsLabelled: e1 label) << myCR.
	
	oo << myCR.!

{void} makeEditionTestOn: oo {ostream reference}
	"Try making Editions in a variety of ways"
	
	| edn {PrEdition} place {PrRangeElement} data {PrDataHolder} bits {PrPrimArray} |
	oo << (edn := myServer newEmptyEdition: myServer sequenceSpace) << myCR
		<< (myServer newEmptyEdition: myServer integerSpace) << myCR.
	
	oo << (myServer newPlaceHolders: (myServer integerSpace interval: (PrInteger make: IntegerVarZero) with: (PrInteger make: 10))) << myCR
		<< (myServer newPlaceHolders: myServer sequenceSpace fullRegion) << myCR.
	
	data := myServer newDataHolder: ((myServer uIntSpec: (PrInteger make: 32)) value: (PrInteger make: 3)).
	place := myServer newPlaceHolder.
	oo << (myServer newEditionWith: (PrWorksTester integer: IntegerVarZero) with: edn) << myCR
		<< (myServer newEditionWith: (PrWorksTester integer: 1) with: place) << myCR
		<< (myServer newEditionWith: (PrWorksTester integer: 2) with: data) << myCR.
	
	oo << (myServer newEditionWithAll: (myServer integerSpace above: (PrInteger make: 10) with: (PrBoolean make: true)) with: edn) << myCR
		<< (myServer newEditionWithAll: (myServer integerSpace below: (PrInteger make: 100) with: (PrBoolean make: false)) with: place) << myCR
		<< (myServer newEditionWithAll: myServer newIDSpace fullRegion with: data) << myCR.
	
	oo << (myServer newEdition: (PrWorksTester string: 'hello world')) << myCR.
	
	bits := PrWorksTester string: 'hello world!!'.
	oo << (myServer newEdition: bits) << myCR
		<< (myServer newEdition: bits with: (myServer integerSpace interval: (PrInteger make: 10) with: (PrInteger make: 22))) << myCR
		"<< (myServer newEdition: bits
			with: NULL
			with: myServer integerSpace getDescending) << myCR
		<< (myServer newEdition: bits
			with: (myServer integerSpace interval: (PrInteger make: 100) with: (PrInteger make: 112))
			with: myServer integerSpace getDescending) << myCR".
	
	oo << 'Making Editions test finished' << myCR << myCR.!

{void} ownerTestOn: oo {ostream reference}
	| s {PrServer} work {PrWork} club {PrClub} edition {PrEdition} |
	s _ myServer.
	club := (s get: s publicClubID) delayCast: PrClub.
	oo << 'Club: ' << club << ' owned by: ' << club owner << myCR.

	PrInitialOwner fluidBind: PrCurrentAuthor fluidGet during:
		[work _ s newWork: (s newEdition: (PrWorksTester string: 'The one I can change.'))].
	oo << 'Work: ' << work << ' owned by: ' << work owner << myCR.
	
	edition _ s newEdition: (myServer pointerSpec arrayWithTwo: work with: club) 
		with: ((PrWorksTester sequence: 'changeable') asRegion with: (PrWorksTester sequence: 'permanent'))
		with: XuSequenceSpace make ascending.
	
	oo << 'Set owners of: ' << edition << myCR.
	oo << 'result: ' << (edition setRangeOwners: s publicClubID) << myCR.

	oo << 'Club: ' << club << ' owned by: ' << club owner << myCR.
	oo << 'Work: ' << work << ' owned by: ' << work owner << myCR.
	
	oo << myCR.!

{void} sponsorTestOn: oo {ostream reference}
	"Test the sponsoring mechanism"
	
	| club {PrClub} testClub {PrClub} blank {PrEdition} w1 {PrWork} w2 {PrWork} |
	testClub := (myServer get: PrCurrentAuthor fluidGet) delayCast: PrClub.
	club := myServer 
		newClub: 
			(myServer newClubDescription: 
				(myServer newSet: 
					(myServer pointerSpec arrayWith: (myServer get: PrCurrentAuthor fluidGet)))
		with: myServer newWallLockSmith) edition.
	
	blank := myServer newEmptyEdition: myServer integerSpace.
	w1 := myServer newWork: blank.
	myServer assignID: w1.
	w2 := myServer newWork: blank.
	myServer assignID: w1.
	oo << 'Initially ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	w1 sponsor: PrCurrentAuthor fluidGet asRegion.
	w2 sponsor: (PrCurrentAuthor fluidGet asRegion
			with: (myServer iDOf: club)).
	oo << 'After sponsoring ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	w1 unsponsor: PrCurrentAuthor fluidGet asRegion.
	w2 unsponsor: (PrCurrentAuthor fluidGet asRegion
			with: (myServer iDOf: club)).
	oo << 'After unsponsoring ' << myCR
		<< 'sponsored by Test: ' << testClub sponsoredWorks << myCR
		<< 'sponsored by new: ' << club sponsoredWorks << myCR
		<< 'work 1 sponsors: ' << w1 sponsors << myCR
		<< 'work 2 sponsors: ' << w2 sponsors << myCR.
	
	self thingToDo. "test authority checks"
	self thingToDo. "get rid of persistent info"!

{void} transclusionsTestOn: oo {ostream reference}
	"Test the transclusions query"
	
	| s {PrServer} text {PrText} n {IntegerVar} texts {PrEdition} refs {PrEdition}
	  detector {FeFillDetector} work {PrWork} |
	
	oo << myCR << myCR << 'Transclusions test' << myCR << myCR.
	s := myServer.
	text := s newText: (PrWorksTester string: '(abcdefghijklmnopqrstuvwxyz)').
	n := 28.
	texts := text edition rangeTranscluders: NULL
		with: (s wrapperSpec: (PrWorksTester sequence: 'Text')) filter.
	refs := text edition rangeTranscluders: NULL
		with: (s wrapperSpec: (PrWorksTester sequence: 'HyperRef')) filter.
	detector := WorksTestFillDetector make: oo with: 'Transcluded by '.
	texts addFillRangeDetector: detector.

	work := s newWork: (s newSingleRef: text edition) edition.
	text := text move: (PrInteger make: IntegerVarZero)
		with: (myServer integerSpace
			interval: (PrInteger make: n // 2) with: (PrInteger make: n)).
	work revise: (s newSingleRef: text edition) edition.
	text := text extract: (myServer integerSpace
		interval: (PrInteger make: n // 4)
		with: (PrInteger make: n // 2)) complement.
	work revise: (s newSingleRef: text edition) edition.
	text := text insert: (PrInteger make: n // 2)
		with: (s newText: (PrWorksTester
			string: '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]')).
	work revise: (s newSingleRef: text edition) edition.
	
	texts := text edition
		rangeTranscluders: (myServer integerSpace
			interval: (PrInteger make: n // 2) with: (PrInteger make: n))
		with: (s wrapperSpec: (PrWorksTester sequence: 'Text')) filter
		with: NULL
		with: (PrInteger make: IntegerVarZero)
		with: texts.
	refs := text edition
		rangeTranscluders: (myServer integerSpace
			interval: (PrInteger make: n // 2) with: (PrInteger make: n))
		with: (s wrapperSpec: (PrWorksTester sequence: 'HyperRef')) filter
		with: NULL
		with: (PrInteger make: IntegerVarZero)
		with: refs.
	refs addFillRangeDetector: detector. "put this in a different place just"
	
	text := text extract: (myServer integerSpace
		above: (PrInteger make: n // 2) with: (PrBoolean make: true)).
	work revise: (s newSingleRef: text edition) edition.
	text := text extract: (myServer integerSpace
		below: (PrInteger make: n) with: (PrBoolean make: false)).
	work revise: (s newSingleRef: text edition) edition.
	text := text move: (PrInteger make: IntegerVarZero)
		with: (myServer integerSpace
			interval: (PrInteger make: n // 2 )with: (PrInteger make: n)).
	work revise: (s newSingleRef: text edition) edition.
	
	self knownBug. "need to intern promises for Detectors so that they can be removed"
	"texts removeFillRangeDetector: detector.
	refs removeFillRangeDetector: detector."!

{void} workTestOn: oo {ostream reference}
	"Try the various operations on Works"
	
	| e1 {PrEdition} w1 {PrWork} |
	e1 := myServer newEdition: (PrWorksTester string: 'hello world').
	w1 := myServer newWork: e1.
	self dumpWorkOn: oo with: 'As newly created ' with: w1.
	
	w1 addStatusDetector: (WorksTestStatusDetector make: oo with: '
Work 1').
	w1 release.
	
	self dumpWorkOn: oo with: 'With authority restored' with: w1.
	w1 grab.
	self dumpWorkOn: oo with: 'Grabbed' with: w1.
	w1 release.
	self dumpWorkOn: oo with: 'Released' with: w1.

	
	PrCurrentKeyMaster fluidBind: PrKeyMaster make during:
		[w1 requestGrab].! !

!PrWorksTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartWorksTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrWorksTester class
	instanceVariableNames: ''!

(PrWorksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #SMALLTALK.ONLY; yourself)!

!PrWorksTester class methodsFor: 'server library'!

{PrID} clubID: clubName {PrSequence}
	"Looks up the ID of a named Club in the directory maintained by the System Admin Club. Requires read permission on the directory. Blasts if there is no Club with that name."
	
	| s {PrServer} |
	s _ PrCurrentServer fluidGet.
	^s iDOf: (((s get: s clubDirectoryID) delayCast: PrWork) edition get: clubName)!

{PrXuInteger} integer: val {IntegerVar}

	^PrIntegerSpace make position: (PrInteger make: val)!

{PrSequence} sequence: string {char star}

	^XuSequenceSpace make position: (self uInt8Spec string: string)!

{PrPrimArray} string: string {char star}

	^self uInt8Spec string: string!

{PrPrimSpec} uInt8Spec

	self passe! !

!PrWorksTester class methodsFor: 'smalltalk: init'!

staticTimeNonInherited
	"XuServer defineFluid: #ClientServer with: XuPromise emulsion with: [NULL]"! !