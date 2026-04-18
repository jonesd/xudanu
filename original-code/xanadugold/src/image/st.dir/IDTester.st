'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:54 pm'!

RegionTester subclass: #IDTester
	instanceVariableNames: 'myConnection {Connection NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!

(IDTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!IDTester methodsFor: 'init'!

{void} destruct

	myConnection destroy.
	super destruct!

{ImmuSet of: XnRegion} initExamples

	| iDs {SetAccumulator} result {SetAccumulator}
	  backend {Sequence} base {ImmuSet}
	  s {IDSpace} |

	myConnection := Connection make: FeServer.
	myConnection bootHeaper.

	iDs := SetAccumulator make.
	backend := FeServer identifier.
	s := IDSpace make: (backend withLast: 3) with: 1.
	iDs step: (ID using: s with: backend with: 3).
	iDs step: (ID using: s with: backend with: 30).
	iDs step: (ID using: s with: (backend withLast: 7) with: 77).
	iDs step: (ID using: s with: (backend withLast: 7) with: 33).
	iDs step: (ID using: s with: (backend withLast: 5) with: 99).
	result := SetAccumulator make.
	(iDs value cast: ImmuSet) stepper forEach: [ :iD {ID} |
		result step: iD asRegion.
		result step: iD asRegion complement].
	"result step: (s iDsFromServer: backend).
	result step: (s iDsFromServer: (backend withLast: 7)).
	result step: (s iDsFromServer: (backend withLast: 9)).
	result step: (s iDsFromServer: backend) complement.
	result step: (s iDsFromServer: (backend withLast: 7))complement.
	result step: (s iDsFromServer: (backend withLast: 9))complement."
	
	base := result value cast: ImmuSet.
	base stepper forEach: [ :r {IDRegion} |
		base stepper forEach: [ :r2 {IDRegion} |
			r hashForEqual < r2 hashForEqual ifTrue:
				[result step: (r unionWith: r2).
				result step: (r intersect: r2)]]].
	^result value cast: ImmuSet! !

!IDTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	super allTestsOn: oo.
	self testImportExportOn: oo.!

{void} shouldBeEqual: oo {ostream reference}
	with: original {Heaper}
	with: imported {Heaper}
	with: importedAgain {Heaper}
	
	| oi {BooleanVar} oa {BooleanVar} ia {BooleanVar} |
	oi := original isEqual: imported.
	oa := original isEqual: importedAgain.
	ia := imported isEqual: importedAgain.
	(oi and: [oa not and: [ia not]]) ifTrue:
		[oo << '2nd import ' << importedAgain << ' is different from ' << original << '
'].
	(oa and: [oi not and: [ia not]]) ifTrue:
		[oo << 'import ' << imported << ' is different from ' << original << '
'].
	(ia and: [oa not and: [oi not]]) ifTrue:
		[oo << 'original ' << importedAgain << ' is different from ' << original << '
'].!

{void} shouldBeUnEqual: oo {ostream reference}
	with: original {Heaper}
	with: imported {Heaper}
	with: importedAgain {Heaper}
	
	(original isEqual: imported) ifTrue:
		[oo << 'original and import are the same: ' << original << '
'].
	(original isEqual: importedAgain) ifTrue:
		[oo << 'original and 2nd import are the same: ' << original << '
'].
	( imported isEqual: importedAgain) ifTrue:
		[oo << '1st and 2nd import are the same: ' << imported << '
'].!

{void} testIDOn: oo {ostream reference} with: iD {ID}
	"Test an ID"
	
	| exported {UInt8Array} exportedAgain {UInt8Array} imported {ID} importedAgain {ID} |
	exported := iD export.
	exportedAgain := iD export.
	(exported contentsEqual: exportedAgain) ifFalse:
		[oo << 'ID ' << iD << ' exported once to ' << exported << ' and then to ' << exportedAgain << '
'].
	imported := ID import: exported.
	importedAgain := ID import: exported.
	self shouldBeEqual: oo with: iD with: imported with: importedAgain.
	self shouldBeEqual: oo with: iD coordinateSpace
		with: imported coordinateSpace
		with: importedAgain coordinateSpace.
	self shouldBeUnEqual: oo
		with: (iD coordinateSpace cast: IDSpace) newID
		with: (imported coordinateSpace cast: IDSpace) newID
		with: (importedAgain coordinateSpace cast: IDSpace) newID.
	oo << 'Finished testing ID ' << iD << '

'!

{void} testIDSpaceOn: oo {ostream reference} with: space {IDSpace} with: special {IDSpace  | NULL}
	"Test an IDSpace"
	
	| exported {UInt8Array} exportedAgain {UInt8Array} imported {IDSpace} importedAgain {IDSpace} |
	exported := space export.
	exportedAgain := space export.
	(exported contentsEqual: exportedAgain) ifFalse:
		[oo << 'IDSpace ' << space << ' exported once to ' << exported << ' and then to ' << exportedAgain << '
'].
	imported := IDSpace import: exported.
	importedAgain := IDSpace import: exported.
	self shouldBeEqual: oo with: space with: imported with: importedAgain.
	self shouldBeUnEqual: oo
		with: space newID
		with: imported newID
		with: importedAgain newID.
	self testIDOn: oo with: space newID.
	[BeGrandMap] USES.
	self testIDOn: oo with: (ID
		using: special with: (CurrentGrandMap fluidGet identifier withLast: 33) with: 1).
	oo << 'Finished testing IDSpace ' << space << '
'!

{void} testImportExportOn: oo {ostream reference}
	"Test import/export of ID objects"
	
	| s {IDSpace} |
	s := IDSpace make: (CurrentGrandMap fluidGet identifier withLast: 22) with: 7.
	self testIDSpaceOn: oo with: s with: s.
	s := CurrentGrandMap fluidGet newIDSpace.
	self testIDSpaceOn: oo with: s with: s.
	self testIDSpaceOn: oo with: CurrentGrandMap fluidGet globalIDSpace with: NULL.! !

!IDTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !