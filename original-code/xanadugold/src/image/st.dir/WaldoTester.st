'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:22 pm'!

FebeTester subclass: #WaldoTester
	instanceVariableNames: ''
	classVariableNames: '
		WaldoText1 {MuWordArray} 
		WaldoText2 {MuWordArray} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Waldos'!

(WaldoTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WaldoTester methodsFor: 'private: functions'!

{XuText} buildText: km {KeyMaster} with: wa {MuWordArray unused} 
	| doc {XuText} |
	doc := (km makePersistentWaldo: (Sequence string: 'XuText')) cast: XuText.
	doc insert: IntegerVar0 with: WaldoText1.
	^doc!

{XuLink} makeLink: km {KeyMaster} with: type {ID} with: doc1 {XuText} with: doc2 {XuText} with: label1 {XuText} with: label2 {XuText} with: end1Reg {XnRegion} with: end2Reg {XnRegion}

	
	^ XuLink make: km
		with: (ImmuSet make with: 
			(LinkEnd make: km
				with: end1Reg
				with: doc1))
		with: label1
		with: (ImmuSet make with: 
			(LinkEnd make: km
				with: end2Reg
				with: doc2))
		with: label2
		with: type
		with: true!

{XnRegion} pathFor: one {Waldo} with: two {Waldo}
	"Compute a PathRegion for the change in state"

	| table {MuTable of: XnRegion} |
	table _ MuTable make: IDSpace make.
	table at: (ID key: 'One') store: (IDRegion make.ID: one editionID).
	table at: (ID key: 'Two') store: (IDRegion make.ID: two editionID).
	^PathRegion make: table asImmuTable!

{TestSensor} setupWaitSensor: km {KeyMaster} with: back1 {IndirectRecord} with: back2 {IndirectRecord} with: changes {XnRegion}
	|  both {IndexedWaldo} sensor {TestSensor} |

	both := (km makeEmptyWaldo: (Sequence string: 'SimpleRecord')
		 with: IDSpace make) cast: IndexedWaldo.
	both at: (ID key: 'One') store: back1.
	both at: (ID key: 'Two') store: back2.
	sensor := TestSensor create: changes.
	both wait: sensor.
	^ sensor! !

!WaldoTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"WaldoTester runTest"

	"self robBugTestOn: oo.
	self iDMapTestOn: oo.
	self intMapTestOn: oo.
	self iDSetTestOn: oo.
	self iDMultiMapTestOn: oo.
	self directRecordTestOn: oo.
	self mappedRecordTestOn: oo."
	self docLinkTestOn: oo.
	self hopTestOn: oo.
	self backRefTestOn: oo.
	self waitForWrapTestOn: oo.
	XuServer currentServer purge.! !

!WaldoTester methodsFor: 'tests'!

{void} backRefTestOn: oo {ostream reference}
	"Test the delayedBackReference operation"
	"WaldoTester runTest: #backRefTestOn:"
	
	| record {IndexedWaldo} text {XuText}
	  record2 {IndexedWaldo} text2 {XuText}
	  back1 {IndirectRecord} back2 {IndirectRecord} 
	  changes {XnRegion} sensor {TestSensor}
	  first {XnRegion}
	  n {IntegerVar} m {IntegerVar}
	  pr {PathRegion} 
	  km {KeyMaster} |
	 
	km _ self keyMaster.
	record := (km makePersistentWaldo: (Sequence string: 'DirectRecord')) cast: IndexedWaldo.
	text := (record getOrMake: (ID key: 'stuff') with: (Sequence string: 'XuText')) cast: XuText.
	text insert: IntegerVar0 with: WaldoText1.
	n := text count.

	"XuServer currentServer purge."

	back1 := text delayedBackReference: (XuServer currentServer waldoFilter: (Sequence string: 'DirectRecord')).
	back2 := text delayedBackReference: (XuServer currentServer waldoFilter: (Sequence string: 'XuText')).
	changes := (PathSpace make: IDSpace make) emptyRegion.
	sensor _ self setupWaitSensor: km with: back1 with: back2 with: changes.
	
	first := (PathRegion make: (IDRegion make: (ID key: 'One')) with: back1 usedDomain)
		unionWith: (PathRegion make: (IDRegion make: (ID key: 'Two')) with: back2 usedDomain).
	text rearrange: IntegerVar0 with: n // 2 with: n.
	changes := changes unionWith: (self pathFor: record with: text).
	text deflate: (IntegerRegion integerExtent: n // 4 with: n // 4).
	changes := changes unionWith: (self pathFor: record with: text).
	text insert: n // 2 with: WaldoText2.
	changes := changes unionWith: (self pathFor: record with: text).
	
	m := WaldoText2 count.
	text delayedExtendBackReference: back1 with: (IntegerRegion make: n // 2 with: n // 2 + (m // 2)).
	text delayedExtendBackReference: back2 with: (IntegerRegion make: n // 2 with: n // 2 + (m // 2)).
	
	record2 := (record copy: true) cast: IndexedWaldo.
	text2 := (record2 get: (ID key: 'stuff')) cast: XuText.
	text2 deflate: (IntegerRegion integerExtent: IntegerVar0 with: n // 2).
	changes := changes unionWith: (self pathFor: record2 with: text2).
	text2 deflate: (IntegerRegion integerExtent: m with: text2 count - m).
	changes := changes unionWith: (self pathFor: record2 with: text2).
	text2 rearrange: IntegerVar0 with: m // 2 with: m.
	changes := changes unionWith: (self pathFor: record2 with: text2).

	"XuServer currentServer purge."
	
	pr := (first unionWith: changes) cast: PathRegion.
	(back1 usedDomain isEqual: (pr getSubRegion: (ID key: 'One')))
		assert: 'delayed backReference problem'.
	(back2 usedDomain isEqual: (pr getSubRegion: (ID key: 'Two')))
		assert: 'delayed backReference problem'.
	(sensor region isEqual: changes)
		assert: 'sensor problem'.
		
	back1 indirectTable stepper forEach: [ :each {IndexedWaldo} |
		| eachText {XuText} |
		eachText := (each get: (ID key: 'stuff')) cast: XuText.
		oo << 'Used in ' << each << ' = '.
		oo << eachText asDataTable << '
'].
	back2 indirectTable stepper forEach: [ :each {XuText} |
		oo << 'Used in ' << each << ' = ' << each asDataTable << '
']!

{void} compareTestOn: oo {ostream reference}
	"Test the version comparision operation"
	"WaldoTester runTest: #compareTestOn:"
	
	| text1 {XuText} text2 {XuText} map1 {IndexedWaldo} map2 {IndexedWaldo} |
	
	text1 := (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')) cast: XuText.
	text2 := (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'Apple Banana Cherry Durian Grape').
	text2 := (text1 copy: true) cast: XuText.
	text2 insert: IntegerVar0 with: (MuWordArray make.charVector: 'Zero ').
	text2 vcopy: text2 count with: text1 with: (IntegerRegion integerExtent: 12 with: 19).
	text2 rearrange: 11 with: 18 with: 25.
	text2 move: text2 count with: text2 with: (IntegerRegion integerExtent: 31 with: 37).
	text2 insert: text2 count with: (MuWordArray make.charVector: ' Melon').
	text1 vcopy: text1 count with: text1 with: (IntegerRegion integerExtent: 5 with: 12).
	
	oo << (text1 asDataTable asMuTable cast: MuWordArray) << ' compare: '
		<< (text2 asDataTable asMuTable cast: MuWordArray) << ' = '
		<< (text1 compare: text2) << '
'.
	oo << (text2 asDataTable asMuTable cast: MuWordArray) << ' compare: '
		<< (text1 asDataTable asMuTable cast: MuWordArray) << ' = '
		<< (text2 compare: text1) << '
'.
		
	map1 := (self keyMaster makeEmptyWaldo: (Sequence string: 'SimpleRecord')
		with: IntegerSpace make) cast: IndexedWaldo.
	map2 := (self keyMaster makeEmptyWaldo: (Sequence string: 'SimpleRecord')
		with: IntegerSpace make) cast: IndexedWaldo.
	
	map1 at: Integer0 store: (ID key: 'Apple').
	map1 at: 1 integer store: (ID key: 'Banana').
	map1 at: 2 integer store: (ID key: 'Cherry').
	map1 at: 3 integer store: (ID key: 'Durian').
	map1 at: 4 integer store: (ID key: 'Grape').
	map1 at: 5 integer store: (ID key: 'Apple').
	map1 at: 6 integer store: (ID key: 'Banana').
	
	map2 at: (ID key: 'Apple') store: (ID key: 'Apple').
	map2 at: (ID key: 'Pie') store: (ID key: 'Apple').
	map2 at: (ID key: 'Banana') store: (ID key: 'Banana').
	map2 at: (ID key: 'Cherry') store: (ID key: 'Cherry').
	map2 at: (ID key: 'Grape') store: (ID key: 'Grape').
	map2 at: (ID key: 'Soda') store: (ID key: 'Grape').
	map2 at: (ID key: 'Elephant') store: (ID key: 'Elephant').
	
	oo << map1 asTable << ' compare: ' << map2 asTable << ' = '
		<< (map1 compare: map2) << '
'.
	oo << map2 asTable << ' compare: ' << map1 asTable << ' = '
		<< (map2 compare: map1) << '
'.!

{void} directRecordTestOn: oo {ostream reference}
	"Test the operation of DirectRecords"
	
	| record {IndexedWaldo}
	 set {IDSet} members {ScruSet}
	 multi {IDMultiMap} apple {ScruSet} banana {ScruSet}
	 map {IndexedWaldo} table {ScruTable} |
	 
	record := (self keyMaster makeEmptyWaldo: (Sequence string: 'DirectRecord')) cast: IndexedWaldo.
	set := (record getOrMake: (ID key: 'set') with: (Sequence string: 'IDSet')) cast: IDSet.
	multi := (record getOrMake: (ID key: 'multi') with: (Sequence string: 'IDMultiMap')) cast: IDMultiMap.
	map := (self keyMaster makeEmptyWaldo: (Sequence string: 'SimpleRecord')
		with: IntegerSpace make) cast: IndexedWaldo.
	record at: (ID key: 'map') store: map.
	map := (record get: (ID key: 'map')) cast: IndexedWaldo.
	
	set storeID: (ID key: 'cat').
	set storeID: (ID key: 'dog').
	members := set asSet.
	
	multi place: (ID key: 'apple') with: (ID key: 'red').
	multi place: (ID key: 'apple') with: (ID key: 'crunchy').
	multi place: (ID key: 'banana') with: (ID key: 'yellow').
	apple := multi values: (ID key: 'apple').
	banana := multi values: (ID key: 'banana').
	
	map at: Integer0 store: (Sequence string: 'zero').
	map at: 1 integer store: (Sequence string: 'one').
	map at: 2 integer store: (ID key: 'two').
	table := map asTable.
	
	(record domain isEqual: (((IDRegion make: (ID key: 'set'))
			unionWith: (IDRegion make: (ID key: 'multi')))
			unionWith: (IDRegion make: (ID key: 'map'))))
		assert: 'domain wrong'.
		
	record := record copy cast: IndexedWaldo.
	(((record get: (ID key: 'set')) cast: IDSet) asSet contentsEqual: members)
		assert: 'set wrong'.
	((((record get: (ID key: 'multi')) cast: IDMultiMap) values: (ID key: 'apple')) contentsEqual: apple)
		assert: 'multi map wrong'.
	((((record get: (ID key: 'multi')) cast: IDMultiMap) values: (ID key: 'banana')) contentsEqual: banana)
		assert: 'multi map wrong'.
	(((record get: (ID key: 'map')) cast: IndexedWaldo) asTable contentsEqual: table)
		assert: 'table wrong'.

	oo << 'DirectRecord test successful
'!

{void} docLinkTestOn: oo {ostream reference}
	"Test the Docs & Links operations"
	"WaldoTester runTest: #docLinkTestOn:"
	
	| km {KeyMaster}
	 doc1 {XuText} doc2 {XuText} doc3 {XuText}
	  count1 {IntegerVar} count2 {IntegerVar}
	  type {ID} lend1LReg {XnRegion} lend1RReg {XnRegion}
	  link1 {XuLink} link2 {XuLink}
	  leftset {LinkEndSet} leftend {LinkEnd} 
	  rightset {LinkEndSet} rightend {LinkEnd}
	  back {IndirectRecord} |
	 
	 km _ self keyMaster.
	doc1 _ self buildText: km with: WaldoText1.
	count1 := WaldoText1 count.
	
	doc2 := self buildText: km with: WaldoText2.
	count2 := WaldoText2 count.
	
	doc3 := (km makePersistentWaldo: (Sequence string: 'XuText')) cast: XuText.
	doc3 vcopy: IntegerVar0 with: doc1 with: (IntegerRegion make: IntegerVar0 with: count1).
	doc3 move: count1 // 2 with: doc2 with: (IntegerRegion make: IntegerVar0 with: count2 // 2).
	
	type := LinkTypeDescription linkType: XuServer currentServer publicKeyMaster
		with: (XuText make: km with.charVector: 'left')
		with: (XuText make: km with.charVector: 'right').

	lend1LReg _ IntegerRegion make: count1 // 2 with: count1.
	lend1RReg _ IntegerRegion make: IntegerVar0 with: count2 // 4.
	link1 := self makeLink: km with: type with: doc1 with: doc2 
					with: (XuText make: km with: 'hi there') 
					with: (XuText make: km with: 'hello yourself') 
					with: lend1LReg 
					with: lend1RReg.

	link2 := self makeLink: km with: type with: doc2 with: doc3
					with: (XuText make: km with: 'goodbye')
					with: (XuText make: km with: 'see ya')
					with: (IntegerRegion make: count2 // 4 with: count2 // 2)
					with: (IntegerRegion make: IntegerVar0 with: count1 // 4).
	
	leftset := (link1 endsets get: XuLink leftID) cast: LinkEndSet.
	((leftset getDescriptor cast: XuText) asDataTable
			contentsEqual: (MuWordArray make.charVector: 'hi there'))
		assert: 'descriptor wrong'.
	leftend := leftset linkEnds theOne cast: LinkEnd.
	(((leftend follow: NULL with: OpenTemporaryVariant) cast: XuText) asDataTable
			contentsEqual: doc1 asDataTable)
		assert: 'follow wrong'.
	((doc1 sharedWith: (leftend getEndContext cast: IndexedWaldo))
			isEqual: (lend1LReg))
		assert: 'follow region wrong'.
	
	rightset := (link1 endsets get: XuLink rightID) cast: LinkEndSet.
	((rightset getDescriptor cast: XuText) asDataTable
			contentsEqual: (MuWordArray make.charVector: 'hello yourself'))
		assert: 'descriptor wrong'.
	rightend := rightset linkEnds theOne cast: LinkEnd.
	(((rightend follow: NULL with: OpenTemporaryVariant) cast: XuText) asDataTable
			contentsEqual: doc2 asDataTable)
		assert: 'follow wrong'.
	((doc2 sharedWith: (rightend getEndContext cast: IndexedWaldo))
			isEqual: (lend1RReg))
		assert: 'follow region wrong'.

	back := doc1 backReference: (XuServer currentServer waldoFilter: (Sequence string: 'XuLink')).

	(back usedDomain isEqual: ((IDRegion make: link1 editionID) unionWith: (IDRegion make: link2 editionID)))
		assert: 'back reference wrong'.
		
	back indirectTable stepper
		forEach: [ :each {Heaper} |
			(each isKindOf: XuLink) assert: 'back reference wrong'].
	
	back := doc2 backReference: (XuServer currentServer waldoFilter: (Sequence string: 'XuLink'))
			with: (lend1RReg).

	(back usedDomain isEqual: (IDRegion make: link1 editionID))
		assert: 'back reference wrong'.
	
	back indirectTable stepper
		forEach: [ :each {Heaper} |
			(each isKindOf: XuLink) assert: 'back reference wrong'].
	
	oo << 'Docs & Links test succeeded
'!

{void} hopTestOn: oo {ostream reference}
	"Test HopRecorders"
	"WaldoTester runTest: #hopTestOn:"
	
	| doc {XuText} recorder {IndirectRecord} sensor {TestSensor} |
	
	doc := (self keyMaster makePersistentWaldo: (Sequence string: 'XuText')) cast: XuText.
	recorder := doc recordChanges.
	sensor := TestSensor create: IntegerRegion make.
	recorder wait: sensor.
	
	"XuServer currentServer purge."
	
	doc insert: IntegerVar0 with: (MuWordArray make.charVector: 'hello world').
	doc insert: 6 with: (MuWordArray make.charVector: 'xanadu ').
	doc vcopy: IntegerVar0 with: doc with: (IntegerRegion make: 6 with: 13).

	"XuServer currentServer purge."
	
	(recorder usedDomain isEqual: sensor region)
		assert: 'sensor and recorder disagree'.
		
	recorder indirectTable stepper forEach: [ :hop {HopRecord} |
		oo << 'Changed to ' << (hop what cast: XuText) asDataTable
			<< ' by ' << hop who << '
']!

{void} iDBackRefTestOn: oo {ostream reference}
	"Test backReference from IDs"
	"WaldoTester runTest: #iDBackRefTestOn:"
	
	| record {IndexedWaldo} ids {IDSet}
	  back1 {IndirectRecord} back2 {IndirectRecord} 
	  both {IndexedWaldo} sensor {TestSensor}
	  first {XnRegion} changes {XnRegion} |
	  
	record := (self keyMaster makeEmptyWaldo: (Sequence string: 'DirectRecord')) cast: IndexedWaldo.
	ids := (record getOrMake: (ID key: 'stuff') with: (Sequence string: 'IDSet')) cast: IDSet.
	ids storeID: (ID key: 'apple').
	ids storeID: (ID key: 'banana').
	
	back1 := ids delayedBackReference: (XuServer currentServer waldoFilter: (Sequence string: 'DirectRecord')).
	back2 := ids delayedBackReference: (XuServer currentServer waldoFilter: (Sequence string: 'IDSet')).
	both := (self keyMaster makeEmptyWaldo: (Sequence string: 'SimpleRecord')
		with: IDSpace make) cast: IndexedWaldo.
	both at: (ID key: 'One') store: back1.
	both at: (ID key: 'Two') store: back2.
	changes := (PathSpace make: IDSpace make) emptyRegion.
	sensor := TestSensor create: changes.
	both wait: sensor.
	
	first := (PathRegion make: (IDRegion make: (ID key: 'One')) with: back1 usedDomain)
		unionWith: (PathRegion make: (IDRegion make: (ID key: 'Two')) with: back2 usedDomain).
	ids storeID: (ID key: 'cherry').
	changes := changes unionWith: (self pathFor: record with: ids).
	ids storeID: (ID key: 'durian').
	changes := changes unionWith: (self pathFor: record with: ids).
	
	(back1 usedDomain isEqual: (((first unionWith: changes) cast: PathRegion)
			getSubRegion: (ID key: 'One')))
		assert: 'delayed backReference problem'.
	(back2 usedDomain isEqual: ((((first unionWith: changes) cast: PathRegion)
			getSubRegion: (ID key: 'Two'))))
		assert: 'delayed backReference problem'.
	(sensor region isEqual: changes)
		assert: 'sensor problem'.
		
	back1 asTable stepper forEach: [ :each {IndexedWaldo} |
		oo << 'Used in ' << each << ' = ' << ((each get: (ID key: 'stuff')) cast: IndexedWaldo) asDataTable << '
'].
	back2 asTable stepper forEach: [ :each {IndexedWaldo} |
		oo << 'Used in ' << each << ' = ' << each asDataTable << '
']!

{void} iDMapTestOn: oo {ostream reference}
	"Test ID-indexed maps"
	
	| map1 {IndexedWaldo} map2 {IndexedWaldo}
	 common {XnRegion} common1 {XnRegion} common2 {XnRegion} |
	[Filter] USES.
	map1 := (self keyMaster makeEmptyWaldo: (Sequence string: 'SimpleRecord')
		with: IDSpace make) cast: IndexedWaldo.
	map1 keyMaster == (self keyMaster cast: KeyMaster) assert: 'wrong key master'.
	map1 fetchParent == NULL assert: 'thinks its a part'.
	((XuServer currentServer withSuperTypes: map1 workType) hasMember: (Sequence string: 'SimpleRecord')) assert: 'work type wrong'.
	((XuServer currentServer waldoFilter: (Sequence string: 'SimpleRecord'))
			match: map1 endorsements)
		assert: 'work type endorsement wrong'.
	map1 top == (map1 cast: IndexedWaldo) assert: 'wrong top'.
	map1 domain isEmpty assert: 'not empty'.

	map1 at: (ID key: 'foo') store: (Sequence string: 'FOO').
	map1 at: (ID key: 'bar') store: (ID key: 'baz').
	map1 remember: (IDRegion make: (ID key: 'memories')).
	map2 := (map1 copy: true) cast: IndexedWaldo.
	(map2 editionID isEqual: map1 editionID) assert: 'edition IDs unequal'.
	map1 at: (ID key: 'bang') store: (ID key: 'Bang').
	map1 at: (ID key: 'other') store: map2.
	common1 := map1 domain.
	map1 at: (ID key: 'bing') store: (Sequence string: 'Bing').
	
	((map1 get: (ID key: 'foo')) isEqual: (Sequence string: 'FOO')) assert: 'get wrong'.
	((map1 get: (ID key: 'bar')) isEqual: (ID key: 'baz')) assert: 'get wrong'.
	(((map1 get: (ID key: 'other')) cast: Manipulator) editionID isEqual: map2 editionID) assert: 'get wrong'.
	((map1 get: (ID key: 'bang')) isEqual: (ID key: 'Bang')) assert: 'get wrong'.
	((map1 get: (ID key: 'bing')) isEqual: (Sequence string: 'Bing')) assert: 'get wrong'.
	
	map2 at: (ID key: 'me') store: map2.
	map2 at: (ID key: 'click') store: (ID key: 'Bang').
	common2 := map2 domain.
	map2 at: (ID key: 'bing') store: (Sequence string: 'Bing').
	
	common := map1 domain intersect: map2 domain.
	((map1 asTable: common) asImmuTable isEqual: (map2 asTable: common) asImmuTable) assert: 'contents dont match'.
	((map1 sharedWith: map2) isEqual: common1) assert: 'sharing wrong'.
	((map2 sharedWith: map1) isEqual: common2) assert: 'sharing wrong'.
	
	"map2 wipeAll: common2 complement.
	map2 transform: (map1 compare: map1).
	map2 introduceAll: map1 with: common1 complement.
	(map1 asTable contentsEqual: map2 asTable) assert: 'transform/compare wrong'."

	oo << 'ID Map test completed succesfully
'!

{void} iDMultiMapTestOn: oo {ostream reference}
	"Test IDMultiMaps"
	
	| map {IDMultiMap} |
	map := (self keyMaster makeEmptyWaldo: (Sequence string: 'IDMultiMap')) cast: IDMultiMap.
	map place: (ID key: 'apple') with: (ID key: 'red').
	map place: (ID key: 'cherry') with: (ID key: 'red').
	map place: (ID key: 'apple') with: (ID key: 'crunchy').
	
	(map isInTable: (ID key: 'apple') with: (ID key: 'red')) assert: 'not in table'.
	(map isInTable: (ID key: 'cherry') with: (ID key: 'red')) assert: 'not in table'.
	(map isInTable: (ID key: 'apple') with: (ID key: 'crunchy')) assert: 'not in table'.
	
	(map isInTable: (ID key: 'cherry') with: (ID key: 'crunchy')) not assert: 'in table'.
	(map isInTable: (ID key: 'orange') with: (ID key: 'red')) not assert: 'in table'.

	((map values: (ID key: 'cherry')) contentsEqual: (ImmuSet make with: (ID key: 'red'))) assert: 'values wrong'.
	((map values: (ID key: 'apple')) contentsEqual: ((ImmuSet make with: (ID key: 'red')) with: (ID key: 'crunchy'))) assert: 'values wrong'.
	(map values: (ID key: 'orange')) isEmpty assert: 'values wrong'.
	
	map wipeAssociation: (ID key: 'cherry') with: (ID key: 'red').
	map wipeAssociation: (ID key: 'apple') with: (ID key: 'crunchy').

	((map values: (ID key: 'apple')) contentsEqual: (ImmuSet make with: (ID key: 'red'))) assert: 'values wrong'.
	(map values: (ID key: 'cherry')) isEmpty assert: 'values wrong'.

	oo << 'IDMultiMap test completed succesfully
'!

{void} iDSetTestOn: oo {ostream reference}
	"Test IDSets"
	
	| set {IDSet} |
	set := (self keyMaster makeEmptyWaldo: (Sequence string: 'IDSet')) cast: IDSet.
	set introduce: (ID key: 'cat').
	set introduce: (ID key: 'dog').
	set storeID: (ID key: 'dog').
	set storeID: (ID key: 'mouse').
	set storeID: (ID key: 'gerbil').

	set remove: (ID key: 'gerbil').
	set wipe: (ID key: 'gerbil').	
	set wipe: (ID key: 'mouse').
	
	(set hasMember: (ID key: 'cat')) assert: 'doesnt have member'.
	(set hasMember: (ID key: 'dog')) assert: 'doesnt have member'.
	
	(set hasMember: (ID key: 'mouse')) not assert: 'has member'.
	(set hasMember: (ID key: 'gerbil')) not assert: 'has member'.

	(set asSet contentsEqual: ((ImmuSet make with: (ID key: 'dog')) with: (ID key: 'cat'))) assert: 'members wrong'.
	
	oo << 'IDSet test successfully completed
'!

{void} intMapTestOn: oo {ostream reference}
	"Tests Integer-indexed Maps"
	
	| map1 {IndexedWaldo} map2 {IndexedWaldo}
	 common {XnRegion} common1 {XnRegion} common2 {XnRegion} |
	map1 := (self keyMaster makeEmptyWaldo: (Sequence string: 'SimpleRecord')
		with: IntegerSpace make) cast: IndexedWaldo.
	map1 keyMaster == (self keyMaster cast: KeyMaster) assert: 'wrong key master'.
	map1 fetchParent == NULL assert: 'thinks its a part'.
	((XuServer currentServer withSuperTypes: map1 workType) hasMember: (Sequence string: 'SimpleRecord')) assert: 'work type wrong'.
	((XuServer currentServer waldoFilter: (Sequence string: 'SimpleRecord'))
			match: map1 endorsements)
		assert: 'work type endorsement wrong'.
	map1 top == (map1 cast: IndexedWaldo) assert: 'wrong top'.
	map1 domain isEmpty assert: 'not empty'.

	map1 at: Integer0 store: (Sequence string: 'FOO').
	map1 at: 1 integer store: (ID key: 'baz').
	map1 remember: (IntegerRegion make: 42).
	map2 := (map1 copy: true) cast: IndexedWaldo.
	(map2 editionID isEqual: map1 editionID) assert: 'edition IDs unequal'.
	map1 at: 2 integer store: (ID key: 'Bang').
	map1 at: 3 integer store: map2.
	common1 := map1 domain.
	map1 at: 4 integer store: (Sequence string: 'Bing').
	
	((map1 get: Integer0) isEqual: (Sequence string: 'FOO')) assert: 'get wrong'.
	((map1 get: 1 integer) isEqual: (ID key: 'baz')) assert: 'get wrong'.
	(((map1 get: 3 integer) cast: Manipulator) editionID isEqual: map2 editionID) assert: 'get wrong'.
	((map1 get: 2 integer) isEqual: (ID key: 'Bang')) assert: 'get wrong'.
	((map1 get: 4 integer) isEqual: (Sequence string: 'Bing')) assert: 'get wrong'.
	
	map2 at: 5 integer store: map2.
	map2 at: 6 integer store: (ID key: 'Bang').
	common2 := map2 domain.
	map2 at: 4 integer store: (Sequence string: 'Bing').
	
	common := map1 domain intersect: map2 domain.
	((map1 asTable: common) asImmuTable isEqual: (map2 asTable: common) asImmuTable) assert: 'contents dont match'.
	((map1 sharedWith: map2) isEqual: common1) assert: 'sharing wrong'.
	((map2 sharedWith: map1) isEqual: common2) assert: 'sharing wrong'.
	
	"map2 wipeAll: common2 complement.
	map2 transform: (map1 compare: map1).
	map2 introduceAll: map1 with: common1 complement.
	(map1 asTable contentsEqual: map2 asTable) assert: 'transform/compare wrong'."

	oo << 'Integer Map test completed succesfully
'!

{void} mappedRecordTestOn: oo {ostream reference}
	"Test MappedRecords"
	
	| record {IndexedWaldo} record2 {IndexedWaldo} set {IDSet} members {ScruSet}
	 multi {IDMultiMap} apple {ScruSet} banana {ScruSet}
	 map {IndexedWaldo} table {ScruTable} |
	 
	record := (self keyMaster makeEmptyWaldo: (Sequence string: 'MappedRecord')
		with: IntegerSpace make) cast: IndexedWaldo.
	set := (record getOrMake: Integer0 with: (Sequence string: 'IDSet')) cast: IDSet.
	multi := (record getOrMake: 1 integer with: (Sequence string: 'IDMultiMap')) cast: IDMultiMap.
	map := (self keyMaster makeEmptyWaldo: (Sequence string: 'SimpleRecord')
		with: IntegerSpace make) cast: IndexedWaldo.
	record at: 2 integer store: map.
	map := (record get: 2 integer) cast: IndexedWaldo.
	
	set storeID: (ID key: 'cat').
	set storeID: (ID key: 'dog').
	members := set asSet.
	
	multi place: (ID key: 'apple') with: (ID key: 'red').
	multi place: (ID key: 'apple') with: (ID key: 'crunchy').
	multi place: (ID key: 'banana') with: (ID key: 'yellow').
	apple := multi values: (ID key: 'apple').
	banana := multi values: (ID key: 'banana').
	
	map at: Integer0 store: (Sequence string: 'zero').
	map at: 1 integer store: (Sequence string: 'one').
	map at: 2 integer store: (ID key: 'two').
	table := map asTable.
	
	(record domain isEqual: (IntegerRegion make: IntegerVar0 with: 3))
		assert: 'domain wrong'.
		
	record := record copy cast: IndexedWaldo.
	(((record get: Integer0) cast: IDSet) asSet contentsEqual: members)
		assert: 'set wrong'.
	((((record get: 1 integer) cast: IDMultiMap) values: (ID key: 'apple')) contentsEqual: apple)
		assert: 'multi map wrong'.
	((((record get: 1 integer) cast: IDMultiMap) values: (ID key: 'banana')) contentsEqual: banana)
		assert: 'multi map wrong'.
	(((record get: 2 integer) cast: IndexedWaldo) asTable contentsEqual: table)
		assert: 'table wrong'.

	record2 := (self keyMaster makeWaldoFromTable: record workType
		with: record asTable) cast: IndexedWaldo.
	(((record2 get: Integer0) cast: IDSet) asSet contentsEqual: members)
		assert: 'set wrong'.
	((((record2 get: 1 integer) cast: IDMultiMap) values: (ID key: 'apple')) contentsEqual: apple)
		assert: 'multi map wrong'.
	((((record2 get: 1 integer) cast: IDMultiMap) values: (ID key: 'banana')) contentsEqual: banana)
		assert: 'multi map wrong'.
	(((record2 get: 2 integer) cast: IndexedWaldo) asTable contentsEqual: table)
		assert: 'table wrong'.
		
	oo << 'MappedRecord test successful
'!

{void} robBugTestOn: oo {ostream reference}

	| pub {KeyMaster} waldo {XuText} copy {XuText} |
	pub := self keyMaster.
	waldo := XuText make: pub with.charVector: 'Yow Baby!!'.
	oo << 'Testing Rob Jellinghaus` bug...
'.
	oo << 'waldo count: ' << waldo count << '
waldo asDataTable count: ' << waldo asDataTable count <<'
'.
	copy := waldo copy cast: XuText.
	oo << 'copy count: ' << copy count << '
copy asDataTable count: ' << copy asDataTable count <<'
'.
	copy deflate: (IntegerRegion make: 1 with: 3).
	oo << 'Deflate!!' <<'
'.
	oo << 'waldo count: ' << waldo count << '
waldo asDataTable count: ' << waldo asDataTable count << '
copy count: ' << copy count << '
copy asDataTable count: ' << copy asDataTable count <<'
'.!

{void} waitForWrapTestOn: oo {ostream reference}
	"test that the wait for wrap operation works"
	"this may not be deterministic"
	| first {Waldo} sensor {WaitTestSensor} |
	first _ (XuText make: self keyMaster with: 'hello world') copy: true.
	sensor _ WaitTestSensor make.
	self keyMaster waitForWrap: first getID with: (Sequence string: 'XuText') with: sensor.
	first destroy.
	"is there any way to ensure that the sensor is going to go off here?"
	sensor fetchContents ~~ NULL ifTrue:
		[oo << 'The sensor now contains ' << ((sensor getContents cast: XuText) asDataTable) << '
']! !

!WaldoTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WaldoTester class
	instanceVariableNames: ''!

(WaldoTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WaldoTester class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	self REQUIRES: MuWordArray.
	WaldoText1 _ MuWordArray make.charVector: '(abcdefghijklmnopqrstuvwxyz)'.
	WaldoText2 _ MuWordArray make.charVector: '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]'!

linkTimeNonInherited
	WaldoText1 _ NULL.
	WaldoText2 _ NULL! !