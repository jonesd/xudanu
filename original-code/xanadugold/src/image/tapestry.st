'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 January 1998 at 6:13:49 pm'!

((CxxSystemOrganization tree childNamed: 'tapestry') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'tapestry') destroyFiles]!

Heaper subclass: #AddSelectedUsers2MembersThunk
	instanceVariableNames: '
		myULPM {ListPaneModel}
		myPM {PermissionsModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(AddSelectedUsers2MembersThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AddSelectedUsers2MembersThunk methodsFor: 'action'!

{void} execute!

{void} invoke! !

!AddSelectedUsers2MembersThunk methodsFor: 'creation'!

create: onPane {ListPaneModel} with: target {PermissionsModel}

	super create.
	myULPM _ onPane.
	myPM _ target! !

!AddSelectedUsers2MembersThunk methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^Heaper takeOop! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AddSelectedUsers2MembersThunk class
	instanceVariableNames: ''!

(AddSelectedUsers2MembersThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AddSelectedUsers2MembersThunk class methodsFor: 'make'!

make: onPane {ListPaneModel} with: target {PermissionsModel}

	^ self create: onPane with: target! !Heaper subclass: #AddSelectedUsers2TargetThunk
	instanceVariableNames: '
		myULPM {ListPaneModel}
		myUDM {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(AddSelectedUsers2TargetThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AddSelectedUsers2TargetThunk methodsFor: 'creation'!

create: onPane {ListPaneModel} with: target {UserDirectoryModel}

	super create.
	myULPM _ onPane.
	myUDM _ target! !

!AddSelectedUsers2TargetThunk methodsFor: 'action'!

{void} execute!

{void} invoke! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AddSelectedUsers2TargetThunk class
	instanceVariableNames: ''!

(AddSelectedUsers2TargetThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AddSelectedUsers2TargetThunk class methodsFor: 'make'!

make: onPane {ListPaneModel} with: target {UserDirectoryModel}

	^ self create: onPane with: target! !XnModel subclass: #ClubManagerPaneModel
	instanceVariableNames: '
		myClubID {VariableModel of: PackOBits}
		myUDM {UserDirectoryModel}
		myPermissionsModel {PermissionsModel}
		myNamePack {VariableModel of: PackOBits}
		myNameText {VariableModel of: AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(ClubManagerPaneModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ClubManagerPaneModel methodsFor: 'accessing'!

{Sequence} namePack

	^Sequence numbers: ((myNameText getValue cast: AttributedTextModel)
			asArray cast: PrimIntegerArray)!

{UserDirectoryModel} userDirectoryModel
	^ myUDM! !

!ClubManagerPaneModel methodsFor: 'private: building'!

{FMScaffold} nameScaffold 
	| scafTab {MuTable} |
	scafTab _ MuTable make: HeaperSpace make.
	scafTab at: (HeaperAsPosition make: SelectedTextModel)
		introduce: (FMTextEditBuilder make).
	scafTab at: (HeaperAsPosition make: AttributedTextModel)
		introduce: (STMBuilder make).
	^FMScaffold make: scafTab with: Scaffold fluidGet! !

!ClubManagerPaneModel methodsFor: 'buildings'!

{FMBuilding} building
	^ self nameEditBuilding!

{FMBuilding} nameEditBuilding
	| build {FMBuilding} | 
	Scaffold fluidBind: self nameScaffold during: 
		[build _ Scaffold  fluidGet build: (myNameText convert: AttributedTextModel)].
	^build! !

!ClubManagerPaneModel methodsFor: 'creation'!

create: onUDM {UserDirectoryModel} with: idM {VariableModel of: ID}
	super create.
	myUDM _ onUDM.
	myClubID _ idM.
	myClubID addDependent: self.
	myPermissionsModel _ NULL.
	myNamePack _ VariableModel make.
	myNameText _ VariableModel make.
	PackOBit2ATMSchnert make: myNamePack with: myNameText.
	ID2PackOBitSchnert make: myUDM with: myClubID with: myNamePack.! !

!ClubManagerPaneModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused} 
	myClubID fetchValue == NULL
		ifTrue: [myPermissionsModel _ NULL.
			myNamePack setValue: (Sequence string: '')]
		ifFalse: [myPermissionsModel ~~ NULL 
			ifTrue: [(myPermissionsModel iD isEqual: (myClubID getValue cast: ID))
					ifFalse: [myPermissionsModel _ NULL]].
			myPermissionsModel _ PermissionsModel 
							fetchPermissionsModel: myUDM keyMaster 
							with: (myClubID getValue cast: ID)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClubManagerPaneModel class
	instanceVariableNames: ''!

(ClubManagerPaneModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ClubManagerPaneModel class methodsFor: 'make'!

make: onUDM {UserDirectoryModel} with: idM {VariableModel of: ID}

	idM == NULL	
		ifTrue: [^ self create: onUDM with: (VariableModel make)]
		ifFalse: [^ self create: onUDM with: idM]! !

!ClubManagerPaneModel class methodsFor: 'smalltalk: make'!

make: onUDM {UserDirectoryModel}
	^ self make: onUDM with: NULL! !FebeTester subclass: #ComparatorTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(ComparatorTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!ComparatorTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"ComparatorTester runTest"

	self crazyDogTestOn: oo.
	self arrangeMovesTestOn: oo.
	self sodaTestOn: oo.! !

!ComparatorTester methodsFor: 'smalltalk: tests'!

{void} interactiveTestOn: oo {ostream reference}
	"ComparatorTester runTest: #interactiveTestOn:"
	| text1 {XuText} text2 {XuText} text3 {XuText} |
	text1 _ (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')  with: NULL with: true) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'Apple Banana Cherry Durian Elderberry Grape ').
	text1 vcopy: text1 count with: text1 with: (IntegerRegion make: 13 with: 20).
	text2 _ (text1 copy: true) cast: XuText.
	text2 insert: IntegerVar0 with: (MuWordArray make.charVector: 'Zero ').
	text2 vcopy: text2 count with: text1 with: (IntegerRegion make: 13 with: 20).
	text2 rearrange: 12 with: 18 with: 39.
	text2 move: text2 count with: text2 with: (IntegerRegion make: 26 with: 33).
	text2 deflate: (IntegerRegion integerExtent: 32 with: 5).
	text2 insert: text2 count with: (MuWordArray make.charVector: 'Melon ').
self halt.

text3 _ (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')) cast: XuText.
text3 insert: IntegerVar0 with:  (MuWordArray make.charVector: '<').
text3 vcopy: text3 count with: text2 with: (IntegerRegion make: IntegerVar0 with: 5).
text3 insert: text3 count with:  (MuWordArray make.charVector: '>').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: IntegerVar0 with: 7).
text3 insert: text3 count with:  (MuWordArray make.charVector: '[(a)').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 7 with: 13).
text3 insert: text3 count with:  (MuWordArray make.charVector: ']').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 13 with: 27).
text3 insert: text3 count with:  (MuWordArray make.charVector: '[(b)').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 27 with: 34).
text3 insert: text3 count with:  (MuWordArray make.charVector: ']').
text3 insert: text3 count with:  (MuWordArray make.charVector: '[').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 34 with: 39).
text3 insert: text3 count with:  (MuWordArray make.charVector: ']').
text3 insert: text3 count with:  (MuWordArray make.charVector: '<(a)>').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 39 with: 51).
text3 insert: text3 count with:  (MuWordArray make.charVector: '<').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 44 with: 51).
text3 insert: text3 count with:  (MuWordArray make.charVector: '>').
text3 insert: text3 count with:  (MuWordArray make.charVector: '<(b)>').
text3 insert: text3 count with:  (MuWordArray make.charVector: '<').
text3 vcopy: text3 count with: text2 with: (IntegerRegion make: 58 with: 64).
text3 insert: text3 count with:  (MuWordArray make.charVector: '>').
^text3 asDataTable asMuTable cast: MuWordArray! !

!ComparatorTester methodsFor: 'tests'!

{void} arrangeMovesTestOn: oo {ostream reference}
	"ComparatorTester runTest: #arrangeMovesTestOn:"
	| text1 {XuText} text2 {XuText} |
	[KeyMaster] USES.
	text1 _ (self keyMaster makeEmptyWaldo: (ID key: 'XuText') with: NULL with: true) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'Apple Banana Cherry Durian Elderberry Grape ').
	text1 vcopy: text1 count with: text1 with: (IntegerRegion integerExtent: 13 with: 20).
	text2 _ (text1 copy: true) cast: XuText.
	text2 insert: IntegerVar0 with: (MuWordArray make.charVector: 'Zero ').
	text2 vcopy: text2 count with: text1 with: (IntegerRegion integerExtent: 13 with: 20).
	text2 rearrange: 12 with: 18 with: 39.
	text2 move: text2 count with: text2 with: (IntegerRegion integerExtent: 26 with: 33).
	text2 deflate: (IntegerRegion integerExtent: 32 with: 5).
	text2 insert: text2 count with: (MuWordArray make.charVector: 'Melon ').

	[EditSequence] USES.
	oo << (MoveMaker make: ((TextComparator  make: text1 with: text2) findLCS allSequences)) sequences << '
'!

{void} crazyDogTestOn: oo {ostream reference}
	"ComparatorTester runTest: #crazyDogTestOn:"
	| text1 {XuText} text2 {XuText} |
	[KeyMaster] USES.
	text1 _ (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')  with: NULL with: true) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'The crazy brown fox jumped over the uqick dog').
	text2 _ (text1 copy: true) cast: XuText.
	text2 rearrange: 4 with: (IntegerRegion integerExtent: 36 with: 41).
	text2 rearrange: 10 with: (IntegerRegion integerExtent: 16 with: 41).
	text2 rearrange: 4 with: (IntegerRegion integerExtent: 5 with: 6).
	text2 deflate: (IntegerRegion integerExtent: 36 with: 2).
	text2 insert: 36 with: (MuWordArray make.charVector: 'l').
	[EditSequence] USES.
	oo << (TextComparator  make: text1 with: text2) findLCS allSequences!

{void} sodaTestOn: oo {ostream reference}
	"ComparatorTester runTest: #sodaTestOn:"
	| text1 {XuText} text2 {XuText} |
	[KeyMaster] USES.
	text1 _ (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')  with: NULL with: true) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'ABCDEFGHIJKL grape root beer doctor pepper sprite sevenup').
	text2 _ (text1 copy: true) cast: XuText.
	text2 rearrange: IntegerVar0 with: 3 with: 7.
	text2 rearrange: 2 with: 9 with: 12.
	text2 rearrange: IntegerVar0 with: 12 with: 57.
	
	oo << (TextComparator  make: text1 with: text2) findLCS << '
'.! !

!ComparatorTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !Heaper subclass: #CompareFragment
	instanceVariableNames: 'size {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
CompareFragment comment:
'CompareFragment and its subclasses represent ranges of a document that is being compared with another.  The different subclasses represent fragments that are shared in different ways.  DeleteFragments and InsertFragments are in only one of the documents.  PrimFragments are in 
both, and know all the locations in each document that they occupy.  CompositeFragments hold onto more than one other Fragment to represent moving them as a unit in a comparison display.'!

(CompareFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CompareFragment methodsFor: 'creation'!

create: s {IntegerVar}
	super create.
	size _ s.! !

!CompareFragment methodsFor: 'accessing'!

{ IntegerVar } count
	^size!

{IntegerRegion} finalLocations
	"the locations where this string starts in the final document"
	self subclassResponsibility!

{IntegerRegion} startLocations
	"The locations where this string begins in the original document"
	self subclassResponsibility! !

!CompareFragment methodsFor: 'obsolete'!

{BooleanVar} contiguousInFinal: aFragment {CompareFragment}
	|myFinal {IntegerRegion} otherFinal {IntegerRegion} |
	myFinal _ self finalLocations.
	otherFinal _ aFragment finalLocations.
	((myFinal isEmpty) or: [otherFinal isEmpty]) 
		ifTrue: [^true].  "deletions can be included in a composite"
	(myFinal start == otherFinal stop)
		ifTrue: [^true].
	(myFinal stop == otherFinal start)
		ifTrue: [^true].
	^false! !

!CompareFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	self subclassResponsibility!

{BooleanVar} simpleMove
	"Am I a simple move from one location to one other?"
	^false! !CompareFragment subclass: #DeleteFragment
	instanceVariableNames: 'srcLocs {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(DeleteFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeleteFragment methodsFor: 'accessing'!

{IntegerRegion} finalLocations
	^IntegerRegion make!

{IntegerRegion} startLocations
	^srcLocs! !

!DeleteFragment methodsFor: 'creation'!

create: s {IntegerVar} with: sLocs {IntegerRegion}
	super create: s.
	srcLocs _ sLocs.! !

!DeleteFragment methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << 'del[' << srcLocs << ']'.! !

!DeleteFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DeleteFragment class
	instanceVariableNames: ''!

(DeleteFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeleteFragment class methodsFor: 'pseudoConstructors'!

{DeleteFragment} make: s {IntegerVar} with: srcLoc {IntegerRegion}

	^DeleteFragment create: s with: srcLoc! !CompareFragment subclass: #InsertFragment
	instanceVariableNames: 'destLocs {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(InsertFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	^false! !

!InsertFragment methodsFor: 'accessing'!

{IntegerRegion} finalLocations
	^destLocs!

{IntegerRegion} startLocations
	^IntegerRegion make! !

!InsertFragment methodsFor: 'creation'!

create: s {IntegerVar} with: dLocs {IntegerRegion}
	super create: s.
	destLocs _ dLocs.! !

!InsertFragment methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << 'Insert[' << destLocs << ']'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InsertFragment class
	instanceVariableNames: ''!

(InsertFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertFragment class methodsFor: 'pseudoConstructors'!

{InsertFragment} make: s {IntegerVar} with: dLoc {IntegerRegion}

	^InsertFragment create: s with: dLoc! !CompareFragment subclass: #PrimFragment
	instanceVariableNames: '
		srcLocs {IntegerRegion}
		destLocs {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(PrimFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimFragment methodsFor: 'creation'!

create: s {IntegerVar} with: sLocs {IntegerRegion} with: dLocs {IntegerRegion}
	super create: s.
	srcLocs _ sLocs.
	destLocs _ dLocs.! !

!PrimFragment methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << 'prim[' << self count << ', ' .
	stream << srcLocs << ' --> '.
	stream << destLocs << ']'.! !

!PrimFragment methodsFor: 'merging'!

{Pair of: PrimFragment} breakAt: length { IntegerVar }
	"Break a move at length, returning the two pieces."
	^Pair make: (PrimFragment make: length with: self startLocations with: self finalLocations) 
		with: (self withoutFirst: length)!

{Pair of: PrimFragment} merge: aMove { PrimFragment }
	"merge two PrimFragments, returning one if their sizes are the same, and two otherwise."
	^Pair make: (self overlapFromMerge: aMove) with: (self overhangFromMerge: aMove)!

{IntegerTable of: PrimFragment} mergeInto:  moves {IntegerTable of: PrimFragment} 
	with: position {IntegerVar}
	"add to a table at a position.  Cascade additions as necessary.  Don't check for overlap"
	
	((moves intFetch: position) == NULL)
		ifTrue:
			[moves atInt: position store: self.
			^moves]
		ifFalse:  [
			| newMoves {"Pair of:" PrimFragment} overlap {PrimFragment} overhang {PrimFragment} |
			newMoves _ (moves intFetch: position) cast: PrimFragment.
			overlap _ newMoves overlapFromMerge: self.
			overhang _ newMoves overhangFromMerge: self.
			"newMoves _ ((moves fetch.IntegerVar: position) cast: PrimFragment) merge: self."
			moves atInt: position replace: overlap.
			(overhang == NULL) 
				ifFalse: [^overhang mergeInto: moves with: (position + overlap count)]
				ifTrue: [^moves]]!

{PrimFragment} overhangFromMerge: aMove {PrimFragment}
	"merge with aMove, returning a Move representing the non-common part."
	(self count == aMove count)
		ifTrue: [^NULL]
		ifFalse: [self count < aMove count
			ifFalse: [^self withoutFirst: aMove count]
			ifTrue: [^aMove withoutFirst: self count]]!

{PrimFragment} overlapFromMerge: aMove {PrimFragment}
	"merge two PrimFragments, return a PrimFragment representing their common beginning"
	| newStarts {IntegerRegion} newDests {IntegerRegion} |
	newStarts _ (aMove startLocations unionWith: self startLocations) cast: IntegerRegion.
	newDests _ (aMove finalLocations unionWith: self finalLocations) cast: IntegerRegion.
	((self count min: aMove count) == IntegerVar0) ifTrue: [^NULL].
	^PrimFragment make: (self count min: aMove count) with: newStarts with: newDests!

{PrimFragment} withoutFirst: minuend { IntegerVar }
	"return a PrimFragment representing this move with the front lopped off"
	^PrimFragment make: self count - minuend
			with: (((IntegerMapping make: minuend) ofAll: self startLocations) cast: IntegerRegion)
			with: (((IntegerMapping make: minuend) ofAll: self finalLocations) cast: IntegerRegion)! !

!PrimFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	^true!

{BooleanVar} simpleMove
	"Am I a simple move from one location to one other?"
	^(srcLocs count == 1) and: [destLocs count == 1]! !

!PrimFragment methodsFor: 'accessing'!

{IntegerRegion} finalLocations
	^destLocs!

{IntegerRegion} startLocations
	^srcLocs! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimFragment class
	instanceVariableNames: ''!

(PrimFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimFragment class methodsFor: 'smalltalk: smalltalk only'!

{PrimFragment} make: s {IntegerVar} with: sLocs {Heaper} with: dLocs {Heaper}

	^(sLocs isKindOf: IntegerVar)
		ifTrue: [(dLocs isKindOf: IntegerVar)
			ifTrue: [PrimFragment make: s with.IntegerVar: sLocs with.IntegerVar: dLocs]
			ifFalse: [PrimFragment make: s with.IntegerVar: sLocs with.IntegerRegion: dLocs]]
		ifFalse: [(dLocs isKindOf: IntegerVar)
			ifTrue: [PrimFragment make: s with.IntegerRegion: sLocs with.IntegerVar: dLocs]
			ifFalse: [PrimFragment make: s with.IntegerRegion: sLocs with.IntegerRegion: dLocs]]! !

!PrimFragment class methodsFor: 'pseudoConstructors'!

{PrimFragment} make: s {IntegerVar} with.IntegerRegion: sLocs {IntegerRegion} with.IntegerRegion: dLocs {IntegerRegion}

	^PrimFragment create: s with: sLocs with: dLocs!

{PrimFragment} make: s {IntegerVar} with.IntegerRegion: sLocs {IntegerRegion} with.IntegerVar: dLoc {IntegerVar}

	^PrimFragment create: s with: sLocs with: (IntegerRegion make: dLoc)!

{PrimFragment} make: s {IntegerVar} with.IntegerVar: sLoc {IntegerVar} with.IntegerRegion: dLocs {IntegerRegion}

	^PrimFragment create: s with: (IntegerRegion make: sLoc) with: dLocs!

{PrimFragment} make: s {IntegerVar} with.IntegerVar: sLoc {IntegerVar} with.IntegerVar: dLoc {IntegerVar}

	^PrimFragment create: s with: (IntegerRegion make: sLoc) with: (IntegerRegion make: dLoc)! !Heaper subclass: #Diagonal
	instanceVariableNames: 'myOffset {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(Diagonal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Diagonal methodsFor: 'accessing'!

{IntegerVar} columnFor: index {IntegerVar}
	(self offset > IntegerVar0)
		ifTrue: [^index + self offset]
		ifFalse: [^index]!

{IntegerVar} rowFor: index {IntegerVar}
	(self offset < IntegerVar0)
		ifTrue: [^index - self offset]
		ifFalse: [^index]! !

!Diagonal methodsFor: 'creation'!

create: offset {IntegerVar}
	super create.
	myOffset _ offset.! !

!Diagonal methodsFor: 'protected: accessing'!

{IntegerVar} offset

	^ myOffset! !Diagonal subclass: #LCSDiagonal
	instanceVariableNames: '
		myEntries {IntegerTable of: IntegerPos}
		myScript {IntegerTable of: EditSequence}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
LCSDiagonal comment:
'LCSDiagonal is used in the computation of Longest Common Sequences by LCSFinder.  See LCSFinder for a more elaborate comment.'!

(LCSDiagonal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSDiagonal methodsFor: 'creation'!

create: offset {IntegerVar}
	super create: offset.
	myEntries _ IntegerTable make.
	myScript _ IntegerTable make.! !

!LCSDiagonal methodsFor: 'accessing'!

{BooleanVar} addDeleteEntryAt: index {IntegerVar} with: entry {IntegerVar} with: editSeq {EditSequence} with: newFragment {CompareFragment}
	"The return value tells whether the argument entry was added, and therefore better.  If it was then my caller will want to propogate it, otherwise it won't have any effect on the table values, and will be forgotten."
	| oldEntry {IntegerPos} |
	oldEntry _ (myEntries intFetch: index) cast: IntegerPos.
	oldEntry == NULL
		ifTrue: [myEntries atInt: index introduce: (IntegerPos make: entry).
				myScript atInt: index introduce: (editSeq copy addDeletion: newFragment).
				^true]
		ifFalse: [(oldEntry asIntegerVar < entry)  "if oldEntry is smaller, do nothing"
			ifFalse: [(entry < oldEntry asIntegerVar)
				ifTrue: [myEntries atInt: index replace: (IntegerPos make: entry).
						myScript atInt: index replace: (editSeq copy addDeletion: newFragment).
						^true]
				ifFalse:
					[((myScript intFetch: index) cast: EditSequence) addSequence: (editSeq copy addDeletion: newFragment).
					^false "Already added to stack, not acted on yet"]]].
	^false!

{BooleanVar} addEntryAt: index {IntegerVar} with: entry {IntegerVar} with: editSeq {EditSequence}
	"The return value tells whether the argument entry was added, and therefore better.  If it was then my caller will want to propogate it, otherwise it won't have any effect on the table values, and will be forgotten."
	| oldEntry {IntegerPos} |
	oldEntry _ (myEntries intFetch: index) cast: IntegerPos.
	oldEntry == NULL
		ifTrue: [myEntries atInt: index introduce: (IntegerPos make: entry).
				myScript atInt: index introduce: editSeq.
				^true]
		ifFalse: [(oldEntry asIntegerVar < entry)  "if oldEntry is smaller, do nothing"
			ifFalse: [(entry < oldEntry asIntegerVar)
				ifTrue: [myEntries atInt: index replace: (IntegerPos make: entry).
						myScript atInt: index replace: editSeq.
						^true]
				ifFalse:
					[((myScript fetch: index) cast: EditSequence) addSequence: editSeq.
					^false "Already added to stack, not acted on yet"]]].
	^false!

{BooleanVar} addInsertEntryAt: index {IntegerVar} with: entry {IntegerVar} with: editSeq {EditSequence} with: newFragment {CompareFragment}
	"The return value tells whether the argument entry was added, and therefore better.  If it was then my caller will want to propogate it, otherwise it won't have any effect on the table values, and will be forgotten."
	| oldEntry {IntegerPos} |
	oldEntry _ (myEntries intFetch: index) cast: IntegerPos.
	oldEntry == NULL
		ifTrue: [myEntries atInt: index introduce: (IntegerPos make: entry).
				myScript atInt: index introduce: (editSeq copy addInsertion: newFragment).
				^true]
		ifFalse: [(oldEntry asIntegerVar < entry)  "if oldEntry is smaller, do nothing"
			ifFalse: [(entry < oldEntry asIntegerVar)
				ifTrue: [myEntries atInt: index replace: (IntegerPos make: entry).
						myScript atInt: index replace: (editSeq copy addInsertion: newFragment).
						^true]
				ifFalse:
					[((myScript intFetch: index) cast: EditSequence) addSequence: (editSeq copy addInsertion: newFragment).
					^false "Already added to stack, not acted on yet"]]].
	^false!

{BooleanVar} addShareEntryAt: index {IntegerVar} with: entry {IntegerVar} with: editSeq {EditSequence} with: newFragment {CompareFragment}
	"The return value tells whether the argument entry was added, and therefore better.  If it was then my caller will want to propogate it, otherwise it won't have any effect on the table values, and will be forgotten."
	| oldEntry {IntegerPos} |
	oldEntry _ (myEntries intFetch: index) cast: IntegerPos.
	oldEntry == NULL
		ifTrue: [myEntries atInt: index introduce: (IntegerPos make: entry).
				myScript atInt: index introduce: (editSeq copy addShare: newFragment).
				^true]
		ifFalse: [(oldEntry asIntegerVar < entry)  "if oldEntry is smaller, do nothing"
			ifFalse: [(entry < oldEntry asIntegerVar)
				ifTrue: [myEntries atInt: index replace: (IntegerPos make: entry).
						myScript atInt: index replace: (editSeq copy addShare: newFragment).
						^true]
				ifFalse:
					[((myScript fetch: index) cast: EditSequence) addSequence: (editSeq copy addShare: newFragment).
					^false "Already added to stack, not acted on yet"]]].
	^false!

{IntegerVar} entryAt: index {IntegerVar}
	| entry {IntegerPos} |
	entry _ (myEntries intFetch: index) cast: IntegerPos.
	(entry == NULL) 
		ifTrue: [^NULL]
		ifFalse: [^entry asIntegerVar]!

{EditSequence} scriptFor: index {IntegerVar}
	^(myScript intFetch: index) cast: EditSequence! !

!LCSDiagonal methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'D[' << self offset << ']'.
	myEntries isEmpty ifFalse: [myEntries printOnWithSimpleSyntax: oo with: '(' with: ',' with: ')']! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LCSDiagonal class
	instanceVariableNames: ''!

(LCSDiagonal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSDiagonal class methodsFor: 'pseudoConstructors'!

{LCSDiagonal} make: offset {IntegerVar}
	^LCSDiagonal create: offset! !Heaper subclass: #DiagonalMatrix
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(DiagonalMatrix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DiagonalMatrix methodsFor: 'accessing'!

{IntegerVar} columns
	self subclassResponsibility!

{LCSDiagonal} fetch: index {IntegerVar}
	self subclassResponsibility!

{IntegerVar} rows
	self subclassResponsibility! !DiagonalMatrix subclass: #LCSDiagonalMatrix
	instanceVariableNames: '
		myRows {IntegerVar}
		myColumns {IntegerVar}
		myDiagonals {IntegerTable of: LCSDiagonal}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
LCSDiagonalMatrix comment:
'LCSDiagonalMatrix is used in the computation of Longest Common Sequences by LCSFinder.  See LCSFinder for a more elaborate comment.'!

(LCSDiagonalMatrix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSDiagonalMatrix methodsFor: 'creation'!

create: colCount {IntegerVar} with: rowCount {IntegerVar}
	super create.
	myRows _ rowCount.
	myColumns _ colCount.
	myDiagonals _ MuArray make: rowCount + colCount + 1.
	rowCount negated to: colCount do: [:index {IntegerVar} | | newDiag {LCSDiagonal} |
		newDiag _ LCSDiagonal create: index.
		myDiagonals atInt: index + rowCount introduce: newDiag]! !

!LCSDiagonalMatrix methodsFor: 'accessing'!

{IntegerVar} columns
	^myColumns!

{LCSDiagonal} fetch: index {IntegerVar}
	^(myDiagonals intFetch: myRows + index) cast: LCSDiagonal!

{IntegerVar} rows
	^myRows! !

!LCSDiagonalMatrix methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	myDiagonals isEmpty ifFalse: [myDiagonals printOnWithSimpleSyntax: oo with: '(' with: '
' with: ')']! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LCSDiagonalMatrix class
	instanceVariableNames: ''!

(LCSDiagonalMatrix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSDiagonalMatrix class methodsFor: 'creation'!

{LCSDiagonalMatrix} make: rowCount {IntegerVar} with: colCount {IntegerVar}

	^LCSDiagonalMatrix create: rowCount with: colCount! !Heaper subclass: #EditOperation
	instanceVariableNames: '
		myStartPosition {IntegerVar}
		myFinalPosition {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
EditOperation comment:
'EditOperation and its subclasses represent the operations that map one document to another to show a comparison.'!

(EditOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!EditOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	self subclassResponsibility! !

!EditOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar}
	super create.
	myStartPosition _ s.
	myFinalPosition _ f.! !

!EditOperation methodsFor: 'deferred accessing'!

{IntegerVar} count
	self subclassResponsibility!

{IntegerRegion} finalLocations
	self subclassResponsibility!

{IntegerRegion} startLocations
	self subclassResponsibility! !

!EditOperation methodsFor: 'accessing'!

{IntegerVar} finalPosition
	"return the position in the final document of this operation"
	^myFinalPosition!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	self subclassResponsibility!

{IntegerVar} startPosition
	"return the position in the start document of this operation"
	^myStartPosition! !

!EditOperation methodsFor: 'obsolete'!

{BooleanVar} contiguousInFinal: anOp {EditOperation}
	"Am I adjacent to anOp in the final doc if we're both present there?"
	|myFinal {IntegerRegion} otherFinal {IntegerRegion} |
	myFinal _ self finalLocations.
	otherFinal _ anOp finalLocations.
	((myFinal isEmpty) or: [otherFinal isEmpty]) 
		ifTrue: [^true].  "deletions can be included in a composite"
	(myFinal start == otherFinal stop)
		ifTrue: [^true].
	(myFinal stop == otherFinal start)
		ifTrue: [^true].
	^false! !

!EditOperation methodsFor: 'testing'!

{BooleanVar} isInsertMove
	"Am I an insertion of text which comes from somewhere else?"
	^false!

{BooleanVar} isPureDelete
	"am I a delete of some text which couldn't be a move."
	^false!

{BooleanVar} isPureInsert
	"am I an insert of some text which couldn't be a move."
	^false! !EditOperation subclass: #MoveOperation
	instanceVariableNames: 'myOperations {IntegerTable of: EditOperations}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(MoveOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MoveOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: ops {IntegerTable of: EditOperations}
	super create: s with: f.
	myOperations _ ops.! !

!MoveOperation methodsFor: 'accessing'!

{IntegerVar} count
	| size {IntegerVar} |
	size _ UInt32Zero.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		size _ size + ((myOperations fetch: opIndex) cast: EditOperation) count].
	^size!

{IntegerRegion} finalLocations
	| locs {IntegerRegion} |
	locs _ IntegerRegion make.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		locs _ (locs unionWith: ((myOperations fetch: opIndex) cast: EditOperation) finalLocations) cast: IntegerRegion].
	^locs!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	self subclassResponsibility!

{IntegerRegion} startLocations
	| locs {IntegerRegion} |
	locs _ IntegerRegion make.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		locs _ (locs unionWith: ((myOperations fetch: opIndex) cast: EditOperation) startLocations) cast: IntegerRegion].
	^locs! !

!MoveOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	self subclassResponsibility! !

!MoveOperation methodsFor: 'protected: protected accessing'!

{IntegerTable of: EditOperations} operations
	^myOperations! !MoveOperation subclass: #MoveInOperation
	instanceVariableNames: 'myMoveFromPosition {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(MoveInOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MoveInOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'MoveIn[' << myMoveFromPosition << ']'! !

!MoveInOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: ops {IntegerTable of: EditOperations} with: from {IntegerVar}
	super create: s with: f with: ops.
	myMoveFromPosition _ from! !

!MoveInOperation methodsFor: 'scoring'!

{IntegerVar} moveDistance
	| dist {IntegerVar} |
	dist _ self finalPosition - self startPosition.
	(dist < IntegerVar0) ifTrue: [dist _ dist negated].
	^dist - self count.! !

!MoveInOperation methodsFor: 'accessing'!

{IntegerVar} fromPosition
	^myMoveFromPosition!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	^1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MoveInOperation class
	instanceVariableNames: ''!

(MoveInOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MoveInOperation class methodsFor: 'pseudoConstructors'!

{MoveInOperation} make.IntegerTable: ops {IntegerTable of: EditOperation} with: from {IntegerVar}
	| start {IntegerRegion} final {IntegerRegion} stepper {Stepper} |
	stepper _ ops domain stepper.
	start _ ((ops fetch: (stepper fetch cast: IntegerPos)) cast: EditOperation) startLocations.
	final _ ((ops fetch: (stepper fetch cast: IntegerPos)) cast: EditOperation) finalLocations.
	stepper forEach: [:index {IntegerPos} |
		start _ (start unionWith: ((ops fetch: index) cast: EditOperation) startLocations) cast: IntegerRegion.
		final _ (final unionWith: ((ops fetch: index) cast: EditOperation) finalLocations) cast: IntegerRegion].
	^MoveInOperation create: start start with: final start with: ops with: from!

{MoveInOperation} make: insert {InsertOperation} with: from {IntegerVar}
	| t {IntegerTable of: EditOperation} |
	t _ IntegerTable make.
	t at: UInt32Zero introduce: insert.
	^MoveInOperation create: insert startPosition with: insert finalPosition with: t with: from! !MoveOperation subclass: #MoveOutOperation
	instanceVariableNames: 'myMoveToPosition {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(MoveOutOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MoveOutOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: ops {IntegerTable of: EditOperations} with: to {IntegerVar}
	super create: s with: f with: ops.
	myMoveToPosition _ to! !

!MoveOutOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'MoveOut[(' << self startPosition << ',' << self finalPosition << ')->' << myMoveToPosition << ','.
	self operations isEmpty ifFalse:
		[self operations printOnWithSimpleSyntax: oo with: '
	(' with: '
	' with: ')'].

	oo << ']'! !

!MoveOutOperation methodsFor: 'accessing'!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	^self count! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MoveOutOperation class
	instanceVariableNames: ''!

(MoveOutOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MoveOutOperation class methodsFor: 'pseudoConstructors'!

{MoveOutOperation} make.IntegerTable: ops {IntegerTable of: EditOperations} with: to {IntegerVar}
	| start {IntegerRegion} final {IntegerRegion} stepper {Stepper} |
	stepper _ ops domain stepper.
	start _ ((ops fetch: (stepper fetch cast: IntegerPos) asIntegerVar) cast: EditOperation) startLocations.
	final _ ((ops fetch: (stepper fetch cast: IntegerPos) asIntegerVar) cast: EditOperation) finalLocations.
	stepper forEach: [:index {IntegerPos} |
		start _ (start unionWith: ((ops fetch: index) cast: EditOperation) startLocations) cast: IntegerRegion.
		final _ (final unionWith: ((ops fetch: index) cast: EditOperation) finalLocations) cast: IntegerRegion].
	^MoveOutOperation create: start start with: final start with: ops with: to!

{MoveOutOperation} make: del {DeleteOperation} with: to {IntegerVar}
	| t {IntegerTable of: EditOperation} |
	t _ IntegerTable make.
	t at: UInt32Zero introduce: del.
	^MoveOutOperation create: del startPosition with: del finalPosition with: t with: to! !EditOperation subclass: #PrimOperation
	instanceVariableNames: 'myFragment {CompareFragment}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(PrimOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PrimOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: frag {CompareFragment}
	super create: s with: f.
	myFragment _ frag.! !

!PrimOperation methodsFor: 'deferred accessing'!

{IntegerVar} nextFinalPosition
	"return the position in the final document of the operation that will follow this one"
	self subclassResponsibility!

{IntegerVar} nextStartPosition
	"return the position in the start document of the operation that will follow this one"
	self subclassResponsibility! !

!PrimOperation methodsFor: 'accessing'!

{IntegerVar} count
	^myFragment count!

{IntegerRegion} finalLocations
	^myFragment finalLocations!

{CompareFragment} fragment
	^myFragment!

{BooleanVar} sameFragmentAs: op {PrimOperation}
	^myFragment == (op fragment cast: CompareFragment)!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	^myFragment count!

{IntegerRegion} startLocations
	^myFragment startLocations! !

!PrimOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	self subclassResponsibility! !PrimOperation subclass: #DeleteOperation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(DeleteOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeleteOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}
	super create: s with: f with: aFragment! !

!DeleteOperation methodsFor: 'smalltalk: printing'!

{void} printTextOn: oo {TextStream reference}
	
	oo emphasis: 13.
	oo << myFragment text! !

!DeleteOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'Delete[' << self startPosition << ',' << self finalPosition << ',' << self fragment << ']'.! !

!DeleteOperation methodsFor: 'accessing'!

{IntegerVar} nextFinalPosition
	"return the position in the final document of the operation that will follow this one"
	^self finalPosition!

{IntegerVar} nextStartPosition
	"return the position in the start document of the operation that will follow this one"
	^self startPosition + self count! !

!DeleteOperation methodsFor: 'testing'!

{BooleanVar} isPureDelete
	^self fragment isShared not! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DeleteOperation class
	instanceVariableNames: ''!

(DeleteOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeleteOperation class methodsFor: 'pseudoConstructors'!

{DeleteOperation} make: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}

	^DeleteOperation create: s with: f with: aFragment! !PrimOperation subclass: #InsertOperation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(InsertOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}
	super create: s with: f with: aFragment! !

!InsertOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'Insert[' << self startPosition << ',' << self finalPosition << ','  << self fragment << ']'.! !

!InsertOperation methodsFor: 'accessing'!

{IntegerVar} nextFinalPosition
	"return the position in the final document of the operation that will follow this one"
	^self finalPosition + self count!

{IntegerVar} nextStartPosition
	"return the position in the start document of the operation that will follow this one"
	^self startPosition! !

!InsertOperation methodsFor: 'testing'!

{BooleanVar} isInsertMove
	"Am I an insertion of text which comes from somewhere else?"
	^self fragment isShared!

{BooleanVar} isPureInsert
	^self fragment isShared not! !

!InsertOperation methodsFor: 'smalltalk: printing'!

{void} printTextOn: oo {TextStream reference}
	
	oo emphasis: 2.
	oo << myFragment text! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InsertOperation class
	instanceVariableNames: ''!

(InsertOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertOperation class methodsFor: 'pseudoConstructors'!

{InsertOperation} make: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}

	^InsertOperation create: s with: f with: aFragment! !PrimOperation subclass: #ShareOperation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(ShareOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ShareOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'Share[' << self startPosition << ',' << self finalPosition << ',' << self fragment << ']'.! !

!ShareOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}
	super create: s with: f with: aFragment! !

!ShareOperation methodsFor: 'accessing'!

{IntegerVar} nextFinalPosition
	"return the position in the final document of the operation that will follow this one"
	^self finalPosition + self count!

{IntegerVar} nextStartPosition
	"return the position in the start document of the operation that will follow this one"
	^self startPosition + self count! !

!ShareOperation methodsFor: 'smalltalk: printing'!

{void} printTextOn: oo {TextStream reference}
	
	oo emphasis: 0.
	oo << myFragment! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShareOperation class
	instanceVariableNames: ''!

(ShareOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ShareOperation class methodsFor: 'pseudoConstructors'!

{ShareOperation} make: s {IntegerVar} with: f {IntegerVar} with:  aFragment {CompareFragment}

	^ShareOperation create: s with: f with: aFragment! !XnModel subclass: #Editors2SelSchnert
	instanceVariableNames: '
		myEditorsModel {PermissionsModel}
		myEditorSelection {BooleanModel}
		myEditorsList {ScruSet of: PackOBits}
		mySelectionModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!
Editors2SelSchnert comment:
'This schnert is used look at an editors permission model and detect when any of a list of possible editors are permitted to edit.  The schnert updates a boolean model to reflect the permissions.'!

(Editors2SelSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Editors2SelSchnert */
friend SPTR(Editors2SelSchnert)  editors2SelSchnert (PermissionsModel * pm, BooleanModel * checkB, BooleanModel * selected, ScruSet OF1(ID) * ids);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Editors2SelSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused} 
	self updateModel!

{void} updateModel
	| tmp {BooleanVar} |
	tmp _ myEditorsModel members intersects: myEditorsList.
	tmp _ tmp and: [myEditorSelection getValue not].
	mySelectionModel setValue: tmp! !

!Editors2SelSchnert methodsFor: 'private: create'!

create: editors {PermissionsModel} with: editSel {BooleanModel} with: model {BooleanModel} with: clubList {ScruSet of: ID}

	super create.
	myEditorsModel _ editors.
	myEditorsModel addDependent: self.
	myEditorSelection _ editSel.
	myEditorsList _ clubList.
	mySelectionModel _ model.
	self updateModel!

{void} destruct

	myEditorsModel removeDependent: self.
	myEditorsModel _ NULL.
	myEditorsList _ NULL.
	mySelectionModel _ NULL.
	myEditorSelection _ NULL.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Editors2SelSchnert class
	instanceVariableNames: ''!

(Editors2SelSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Editors2SelSchnert */
friend SPTR(Editors2SelSchnert)  editors2SelSchnert (PermissionsModel * pm, BooleanModel * checkB, BooleanModel * selected, ScruSet OF1(ID) * ids);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Editors2SelSchnert class methodsFor: 'make'!

make: pm {PermissionsModel} with: checkB {BooleanModel} with: selected {BooleanModel} with: ids {ScruSet of: ID}

	^ self create: pm with: checkB with: selected with: ids! !Heaper subclass: #EditSequence
	instanceVariableNames: '
		myOperations {IntegerTable of: EditOperation}
		myNextSequence {EditSequence}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
EditSequence comment:
'EditSequence holds a sequence of EditOperations to represent a mapping from one document to another in a comparison.  EditSequences are built by LCSFinder, which adds operations one at time as it searches for a longest common sequence between two documents.'!

(EditSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EditSequence methodsFor: 'scoring'!

{IntegerVar} countMoves
	| count {IntegerVar} |
	count _ IntegerVar0.
	myOperations stepper forEach: [:op {EditOperation} |
		(op isKindOf: MoveOperation) ifTrue: [count _ count + 1]].
	^count!

{IntegerVar} moveDistanceFor: moveIndex {IntegerVar}
	| count {IntegerVar} |
	count _ IntegerVar0.
	((myOperations fetch: moveIndex) isKindOf: MoveInOperation) ifTrue:
		[ | op {MoveInOperation} |
		op _ (myOperations fetch: moveIndex) cast: MoveInOperation.
		moveIndex to: op fromPosition do: [:index {IntegerVar} |
			((myOperations intFetch: index) == NULL) ifFalse:
				[count _ count + ((myOperations intFetch: index) cast: EditOperation) sizeInMerge]]].
	^count!

{IntegerVar} moveSizeXDist
	| count {IntegerVar} |
	count _ IntegerVar0.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		((myOperations fetch: opIndex) isKindOf: MoveInOperation) ifTrue:
			[count _ count + ((self moveDistanceFor: opIndex asIntegerVar) 
							* ((myOperations fetch: opIndex) cast: MoveInOperation) count)]].
	^count!

{IntegerVar} totalMoveDistances
	| count {IntegerVar} |
	count _ IntegerVar0.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		((myOperations fetch: opIndex) isKindOf: MoveInOperation) ifTrue:
			[count _ count + (self moveDistanceFor: opIndex asIntegerVar)]].
	^count! !

!EditSequence methodsFor: 'moves'!

{EditSequence} editSequenceForMove: source {IntegerTable of: EditOperation} with: dest {IntegerTable of: EditOperation}
	| s {IntegerTable of: CompareOperation} f {IntegerTable of: CompareOperation} |
	s _ IntegerTable make.
	(self operationsSubTable: (source domain cast: IntegerRegion)) stepper forEach: [:each {PrimOperation} |
		s at: each startPosition introduce: each fragment].
	f _ IntegerTable make.
	(self operationsSubTable: (dest domain cast: IntegerRegion)) stepper forEach: [:each {PrimOperation} |
		f at: each finalPosition introduce: each fragment].
	[LCSFinder] USES.
	^(TextComparator make.IntegerTable: f with.IntegerTable: s) findLCS!

{void} makeMove: from {IntegerVar} with: to {IntegerVar}

	| fromOp {EditOperation} toOp {EditOperation} |
	(((self fetchOperation: from) == NULL) or: [(self fetchOperation: to) == NULL])
		ifTrue: [^VOID].
	fromOp _ self fetchOperation: from.
	toOp _ self fetchOperation: to.
	(((fromOp isKindOf: DeleteOperation) and: [toOp isKindOf: InsertOperation])
	   and: [(fromOp cast: DeleteOperation) sameFragmentAs: (toOp cast: InsertOperation)])
		ifFalse: [^VOID].
	myOperations at: to store: (MoveInOperation make: (toOp cast: InsertOperation) with: from).
	myOperations at: from store: (MoveOutOperation make: (fromOp cast: DeleteOperation) with: to).!

{void} rearrange: range {IntegerRegion} with: move {MoveOperation}
	range stepper forEach: [:r {IntegerPos} | myOperations wipe: r].
	myOperations at: range start introduce: move.
	^VOID! !

!EditSequence methodsFor: 'adding'!

{EditSequence} addDeleteOperation: del {DeleteOperation}
	myOperations atInt: myOperations count store: del.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addDeleteOperation: del].
	^self!

{EditSequence} addDeletion: aFragment {CompareFragment}
	| del {DeleteOperation} startPosition {IntegerVar} finalPosition {IntegerVar} |
	(myOperations count == IntegerVar0)
		ifTrue: [startPosition _ finalPosition _ UInt32Zero]
		ifFalse: [startPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextStartPosition.
				finalPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextFinalPosition].
	del _ DeleteOperation make: startPosition with: finalPosition with: aFragment.
	myOperations atInt: myOperations count store: del.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addDeleteOperation: del].
	^self!

{EditSequence} addInsertion: aFragment {CompareFragment}
	| insert {InsertOperation} startPosition {IntegerVar} finalPosition {IntegerVar} |
	(myOperations count == IntegerVar0)
		ifTrue: [startPosition _ finalPosition _ UInt32Zero]
		ifFalse: [startPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextStartPosition.
				finalPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextFinalPosition].
	insert _ InsertOperation make: startPosition with: finalPosition with: aFragment.
	myOperations atInt: myOperations count store: insert.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addInsertOperation: insert].
	^self!

{EditSequence} addInsertOperation: insert {InsertOperation}
	myOperations atInt: myOperations count store: insert.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addInsertOperation: insert].
	^self!

{void} addSequence: aSequence {EditSequence}
	(myNextSequence == NULL) 
		ifTrue: [myNextSequence _ aSequence]
		ifFalse: [(self isEqual: myNextSequence)
					ifFalse: [myNextSequence addSequence: aSequence]]!

{EditSequence} addShare: aFragment {CompareFragment}
	| share {ShareOperation} startPosition {IntegerVar} finalPosition {IntegerVar} |
	(myOperations count == IntegerVar0)
		ifTrue: [startPosition _ finalPosition _ UInt32Zero]
		ifFalse: [startPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextStartPosition.
				finalPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextFinalPosition].
	share _ ShareOperation make: startPosition with: finalPosition with: aFragment.
	myOperations atInt: myOperations count store: share.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addShareOperation: share].
	^self!

{EditSequence} addShareOperation: share {ShareOperation}
	myOperations atInt: myOperations count store: share.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addShareOperation: share].
	^self! !

!EditSequence methodsFor: 'smalltalk: displaying'!

{Text} asText
	^Text streamContents: [:aStream |
		myOperations stepper forEach: [:op {PrimOperation} |
			op printTextOn: aStream]]! !

!EditSequence methodsFor: 'accessing'!

{MuSet of: EditSequence} allSequences
	(myNextSequence == NULL) 
		ifTrue:
			[^MuSet make.Heaper: self]
		ifFalse:
			[| seq {MuSet of: EditSequence} |
			seq _ myNextSequence allSequences.
			seq store: self.
			^seq]!

{IntegerTable of: EditOperation} contiguousDeletes: index {IntegerVar}
	"make a table of DeleteOperations which are contiguous with index."
	| contig {IntegerTable of: EditOperation} lowerBound {IntegerVar} upperBound {IntegerVar} nextOp {EditOperation} |
	contig _ IntegerTable make.
	contig at: index store: (self fetchOperation: index).

	lowerBound _ index.
	[((nextOp _ self fetchOperation: lowerBound - 1) ~= NULL)
			and: [(nextOp isKindOf: DeleteOperation)
			 and: [(nextOp cast: DeleteOperation) isPureDelete not]]]
	whileTrue:
		[contig at: lowerBound - 1 store: nextOp.
		lowerBound _ lowerBound - 1].

	upperBound _ index.
	[((nextOp _ self fetchOperation: upperBound + 1) ~= NULL)
			and: [(nextOp isKindOf: DeleteOperation)
			 and: [(nextOp cast: DeleteOperation) isPureDelete not]]]
	whileTrue:
		[contig at: upperBound + 1 store: nextOp.
		upperBound _ upperBound + 1].
	^contig!

{IntegerTable of: EditOperation} contiguousInserts: index {IntegerVar} with: deleteOps {IntegerTable of: EditOperation}
	| contig {IntegerTable of: EditOperation} lowerBound {IntegerVar} upperBound {IntegerVar} deleteStarts {IntegerTable} nextOp {EditOperation} op {EditOperation} deleteLoc {IntegerVar} | 
	contig _ IntegerTable make.
	contig at: index store: (self fetchOperation: index).
	deleteStarts _ IntegerTable make.
	deleteOps domain stepper forEach: [:del {IntegerPos} |
		op _ (deleteOps fetch: del) cast: EditOperation.
		deleteStarts at: op startLocations start store: op].

	lowerBound _ index.
	[((nextOp _ self fetchOperation: lowerBound - 1) ~= NULL)
		and: [(nextOp isInsertMove)
		 and: [(deleteStarts fetch: (deleteLoc _ nextOp startLocations start)) ~= NULL]]]
	whileTrue:
		[contig at: lowerBound - 1 store: nextOp.
		deleteStarts intRemove: deleteLoc.
		lowerBound _ lowerBound - 1].

	upperBound _ index.
	[((nextOp _ self fetchOperation: upperBound + 1) ~= NULL)
		and: [(nextOp isInsertMove)
		 and: [(deleteStarts fetch: (deleteLoc _ nextOp startLocations start)) ~= NULL]]]
	whileTrue:
		[contig at: upperBound + 1 store: nextOp.
		deleteStarts intRemove: deleteLoc.
		upperBound _ upperBound + 1].
	^contig!

{IntegerVar} count
	^myOperations count!

{EditOperation} fetchOperation: index {IntegerVar}
	^(myOperations intFetch: index) cast: EditOperation!

{UInt32} hashForEqual
	^myOperations hashForEqual!

{BooleanVar}isEqual: other{Heaper}
	"Return true if the two objects are equal."
	^ self hashForEqual = other hashForEqual!

{IntegerTable of: EditOperation} operations
	^myOperations!

{IntegerTable of: EditOperations} operationsSubTable: reg {XnRegion}
	^(myOperations subTable: reg) cast: IntegerTable! !

!EditSequence methodsFor: 'creation'!

create
	super create.
	myNextSequence _ NULL.
	myOperations _ IntegerTable make.!

create: ops {IntegerTable of: CompareFragment}
	super create.
	myNextSequence _ NULL.
	myOperations _ ops.!

create: ops {IntegerTable of: CompareFragment} with: seq {EditSequence}
	super create.
	myNextSequence _ seq.
	myOperations _ ops.! !

!EditSequence methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	myOperations isEmpty
		ifTrue: [oo << 'EditSequence(empty)']
		ifFalse: [myOperations printOnWithSimpleSyntax: oo with: '(' with: '
' with: ')'].
	(myNextSequence == NULL)  ifFalse: 
			[oo << '
EditSequences . . .'].! !

!EditSequence methodsFor: 'copying'!

{EditSequence} copy
	(myNextSequence == NULL )
		ifFalse: [^EditSequence make: (myOperations copy cast: IntegerTable)
							with: myNextSequence copy]
		ifTrue: [^EditSequence make: (myOperations copy cast: IntegerTable)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EditSequence class
	instanceVariableNames: ''!

(EditSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EditSequence class methodsFor: 'pseudoConstructors'!

{EditSequence} make
	^EditSequence create!

{EditSequence} make: ops {IntegerTable of: CompareFragment}
	^EditSequence create: ops!

{EditSequence} make: ops {IntegerTable of: CompareFragment} with: seq {EditSequence}
	^EditSequence create: ops with: seq!

{EditSequence}  makeShare: aFragment {CompareFragment}
	| table {IntegerTable} |
	table _ IntegerTable make: 1.
	table at: 1 introduce: (ShareOperation make: IntegerVar0 with: IntegerVar0 with: aFragment).
	^EditSequence create: table! !XnDependent subclass: #EndList2DescriptionListSchnert
	instanceVariableNames: '
		myEndModel {LinkEndsModel}
		myDescriptionListModel {ListModel of: AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-linkmkr'!
EndList2DescriptionListSchnert comment:
'This class maintains the relationship of the visible list of linkends (the description list) with the actual list (a LinkEndsModel)'!

(EndList2DescriptionListSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class EndList2DescriptionListSchnert */
friend SPTR(EndList2DescriptionListSchnert) endList2DescriptionListSchnert (
													LinkEndsModel * onEndList, 
													ListModel * descriptions);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EndList2DescriptionListSchnert methodsFor: 'private: creation'!

create: linkEnds {LinkEndsModel} with: descList {ListModel}
	super create.
	myEndModel _ linkEnds.
	myDescriptionListModel _ descList.
	myEndModel addDependent: self.
	myDescriptionListModel addDependent: self!

{void} destruct

	myEndModel removeDependent: self.
	myDescriptionListModel removeDependent: self.
	myEndModel _ NULL.
	myDescriptionListModel _ NULL.
	super destruct! !

!EndList2DescriptionListSchnert methodsFor: 'private: actions'!

{void} insertEndUpdate: index {IntegerVar} 
	myDescriptionListModel removeDependent: self.
	myDescriptionListModel insert: index with: (myEndModel fetchDescription: index).
	myDescriptionListModel addDependent: self!

{void} removeDescriptionUpdate: region {XnRegion}
	"disconnect the dependency during the op so we don't get an infinite cycle."
	
	myEndModel removeDependent: self.
	myEndModel wipe: region.
	myEndModel addDependent: self!

{void} removeEndUpdate: region {XnRegion} 
	"disconnect dependency while updating the other so we don't get 
	infinite cycle"

	myDescriptionListModel removeDependent: self.
	myDescriptionListModel wipe: region.
	myDescriptionListModel addDependent: self! !

!EndList2DescriptionListSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}
	sender == myEndModel
		ifTrue: [(ur isKindOf: InsertionUR)
			ifTrue: [self insertEndUpdate: (ur basicCast: InsertionUR) index]
		ifFalse: [(ur isKindOf: DeletionUR)
			ifTrue: [self removeEndUpdate: (ur basicCast: DeletionUR) region]
		ifFalse: [Heaper BLAST: #INVALID.U.UPDATE.U.RECORD]]]
	ifFalse: [(sender == myDescriptionListModel)
		ifTrue: [(ur isKindOf: DeletionUR)
			ifTrue: [self removeDescriptionUpdate: (ur basicCast: DeletionUR) region]
			ifFalse: [Heaper BLAST: #INVALID.U.UPDATE.U.RECORD]]
	ifFalse: [Heaper BLAST: #WhyDidIGetThis.U.Interogative]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EndList2DescriptionListSchnert class
	instanceVariableNames: ''!

(EndList2DescriptionListSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class EndList2DescriptionListSchnert */
friend SPTR(EndList2DescriptionListSchnert) endList2DescriptionListSchnert (
													LinkEndsModel * onEndList, 
													ListModel * descriptions);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EndList2DescriptionListSchnert class methodsFor: 'pseudo constructors'!

make: onEndList {LinkEndsModel} with: descriptions {ListModel}

	^ self create: onEndList with: descriptions! !XnDependent subclass: #Filter2ReferencesSchnert
	instanceVariableNames: '
		myFilter {VariableModel of: ReferenceFilter}
		myDocument {DocumentModel}
		myReferences {SetModel of: Reference}
		myNewModel {XnModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
Filter2ReferencesSchnert comment:
'Updates the reference list when the filter changes. Each time this happens, updates the NewModel so that the existing sensor knows to disappear.'!

(Filter2ReferencesSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Filter2ReferencesSchnert */
friend SPTR(Filter2ReferencesSchnert) filter2ReferencesSchnert (
											VariableModel OF1(ReferenceFilter) * filter,
											DocumentModel * document,
											SetModel OF1(Reference) * references);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Filter2ReferencesSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel} 
	(model == myFilter 
		or: [model == myDocument 
			and: [change isKindOf: NewContentsUpdate]])
		ifTrue: [self updateReferences]! !

!Filter2ReferencesSchnert methodsFor: 'private: creation'!

{void} destruct
	myFilter removeDependent: self.
	myDocument removeDependent: self.
	myFilter removeDependent: self.
	myDocument removeDependent: self.
	myNewModel destroy.
	myFilter _ NULL.
	myDocument _ NULL.
	myNewModel _ NULL.
	myReferences _ NULL.
	super destruct! !

!Filter2ReferencesSchnert methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo <<  self getCategory name << ' Filter' << myFilter << 'myDocument = ' << myDocument  
		<< ' MyReferences = ' << myReferences  
		<< 'myNewModel'  << myNewModel! !

!Filter2ReferencesSchnert methodsFor: 'private: private updating'!

{void} updateReferences
	myNewModel changed: NewContentsUpdate make.
	(myFilter getValue cast: TapestryFilter) watchReferences: myDocument
		with: myReferences
		with: myNewModel! !

!Filter2ReferencesSchnert methodsFor: 'smalltalk: passe'!

create: filter {VariableModel of: TapestryFilter} 
	with: document {DocumentModel} 
	with: references {SetModel of: Reference}
	
	super create.
	myFilter _ filter.
	myFilter addDependent: self.
	myDocument _ document.
	myDocument addDependent: self.
	myReferences _ references.
	"myNewModel _ XuModel connectorModel."
	self passe.

	myFilter addDependent: self.
	myDocument addDependent: self.
	self updateReferences! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Filter2ReferencesSchnert class
	instanceVariableNames: ''!

(Filter2ReferencesSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Filter2ReferencesSchnert */
friend SPTR(Filter2ReferencesSchnert) filter2ReferencesSchnert (
											VariableModel OF1(ReferenceFilter) * filter,
											DocumentModel * document,
											SetModel OF1(Reference) * references);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Filter2ReferencesSchnert class methodsFor: 'make'!

make: filter {VariableModel of: TapestryFilter} with: document {DocumentModel} with: references {SetModel of: Reference}
	^self create: filter with: document with: references! !Heaper subclass: #FilterStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
FilterStream comment:
'XuFilterStream represents a filter (or set thereof) on waldos.  A filter stream accepts input waldos (through a stream) and produces an output stream of waldos.  The stream protocol used is the stepper protocol.  All filter streams are zero to many input and one output.'!

(FilterStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!FilterStream methodsFor: 'streaming'!

{ID} fetch

	"This method returns the current Waldo on the stream, or NULL if hasValue is FALSE.  The fetch does NOT affect the state of the stream."
	
	self subclassResponsibility!

{Waldo} get

	"This method returns the current Waldo on the stream.  This method will BLAST if hasValue is FALSE.  The get does NOT affect the state of the stream."
	
	self fetch == NULL ifTrue: [Heaper BLAST: #EmptyFilterStream].
	^ self fetch!

{BooleanVar} hasValue

	"This method returns TRUE iff a fetch on the stream will produce a Waldo"
	
	self subclassResponsibility!

{void} step

	"This method advances the stream to the next Waldo.  This is a valid operation iff hasValue is TRUE, it will blast otherwise."
	
	self subclassResponsibility! !

!FilterStream methodsFor: 'accessing'!

{PackOBits} pattern

	"This method returns a 'signature' for the filter stream that identifies it for the purpose of combining filter streams into more efficient, code-supported filters (primitive filters)."
	
	self subclassResponsibility! !

!FilterStream methodsFor: 'creation'!

{FilterStream} copy

	"This method returns a copy of the stream in its current state.  A stream and it's copy should return the same sequence of ids regardless of the order they are stepped over."
	
	self subclassResponsibility! !

!FilterStream methodsFor: 'protected: patterns'!

{PackOBits} concat: first {MuWordArray} with: rest {MuWordArray}

	| nuPart  {MuWordArray} |
	nuPart _ first copy.
	nuPart introduceAll: rest 
				with: (IntegerMapping make: nuPart count) 
				with: NULL.
	^ Sequence string: nuPart asString!

{MuWordArray} wrap: middle {PackOBits}

	| middleStr {MuWordArray} concatted {MuWordArray} |
	middleStr _ (middle convert: MuWordArray) cast: MuWordArray.
	concatted _ MuWordArray make.charVector: '('.
	concatted introduceAll: middleStr 
					with: (IntegerMapping make: concatted count) 
					with: NULL.
	concatted introduceAll: (MuWordArray make.charVector: ')') 
					with: (IntegerMapping make: concatted count) 
					with: NULL.
	middleStr destroy.
	^ Sequence string: concatted asString! !

!FilterStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !FilterStream subclass: #EndorsedBackfollowFilter
	instanceVariableNames: '
		myInputStream {FilterStream}
		myEndorsements {Filter of: PackOBits}
		myNext {Waldo}
		myCurrentBackfollow {Stepper of: Waldo}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
EndorsedBackfollowFilter comment:
'EndorsedBackfollowFilter is a primitive filter that backfollows from each Waldo on the input stream, filtered by the endorsements, and steps over the result.  Uniqueness of output Waldos is NOT guaranteed.'!

(EndorsedBackfollowFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EndorsedBackfollowFilter methodsFor: 'accessing'!

{PackOBits} pattern

	"This method returns a 'signature' for the filter stream that identifies it for the purpose of combining filter streams into more efficient, code-supported filters (primitive filters)."
	
	^ self concat: (MuWordArray make.charVector: 'Endorsement')
			with: (self wrap: 
					(self concat: (MuWordArray make.charVector: 'Backfollow')
						with: (self wrap: (myInputStream pattern))))! !

!EndorsedBackfollowFilter methodsFor: 'streaming'!

{ID} fetch

	"This method returns the current ID on the stream, or NULL if hasValue is FALSE.  The fetch does NOT affect the state of the stream."
	
	^ myCurrentBackfollow fetch!

{BooleanVar} hasValue

	"This method returns TRUE iff a fetch on the stream will produce an ID"
	
	^ myCurrentBackfollow hasValue!

{void} step

	"This method advances the stream to the next ID.  This is a valid operation iff hasValue is TRUE, it will blast otherwise."
	
	myCurrentBackfollow step.
	myCurrentBackfollow hasValue
		ifFalse: [self skipToNext]! !

!EndorsedBackfollowFilter methodsFor: 'creation'!

create: onStream {FilterStream} with: endorsements {ImmuSet of: ID}

	super create.
	myInputStream _ onStream.
	myEndorsements _ Filter supersetFilter: FeServer endorsementFilterSpace
		with: (IDRegion make.ScruSet: endorsements).
	self skipToNext! !

!EndorsedBackfollowFilter methodsFor: 'private: filtering'!

{void} skipToNext

	myInputStream hasValue
		ifTrue: [| tmp {IndirectRecord} |
			tmp _ myInputStream fetch backReference: myEndorsements with: NULL.
			myCurrentBackfollow _ (tmp indirectTable: NULL) stepper.
			myInputStream step]
		ifFalse: [myCurrentBackfollow _ (MuSet make) stepper]! !FilterStream subclass: #EndorsedBFIDFilter
	instanceVariableNames: '
		myInputStream {FilterStream}
		myEndorsements {ImmuSet of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
EndorsedBFIDFilter comment:
'EndorsedBFIDFilter is a primitive filter that backfollows from the ID of each Waldo on the input stream, filtered by the endorsements, and steps over the result.  Uniqueness of output Waldos is NOT guaranteed.'!

(EndorsedBFIDFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!FilterStream subclass: #EndorsementFilter
	instanceVariableNames: '
		myInputStream {FilterStream}
		myEndorsements {ImmuSet of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
EndorsementFilter comment:
'EndorsementFilter is a primitive filter that removes Waldos from the input stream that do not have all of the specified endorsements.'!

(EndorsementFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EndorsementFilter methodsFor: 'streaming'!

{ID} fetch

	"This method returns the current ID on the stream, or NULL if hasValue is FALSE.  The fetch does NOT affect the state of the stream."
	
	self subclassResponsibility!

{BooleanVar} hasValue

	"This method returns TRUE iff a fetch on the stream will produce an ID"
	
	self subclassResponsibility!

{void} step

	"This method advances the stream to the next ID.  This is a valid operation iff hasValue is TRUE, it will blast otherwise."
	
	self subclassResponsibility! !

!EndorsementFilter methodsFor: 'private: creation'!

create: inputStream {FilterStream} with: endorsements {ImmuSet of: ID}

	super create.
	myInputStream _ inputStream.
	myEndorsements _ endorsements! !

!EndorsementFilter methodsFor: 'accessing'!

{PackOBits} pattern

	^ self concat: (MuWordArray make.charVector: 'Endorsement')
			with: (self wrap: myInputStream pattern)! !FilterStream subclass: #UniqueFilter
	instanceVariableNames: '
		myInputStream {FilterStream}
		myCollection {MuSet of: PackOBits}
		myNext {Waldo}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
UniqueFilter comment:
'This filter guarantees that the output stream will return each ID in the input stream once and only once.'!

(UniqueFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UniqueFilter methodsFor: 'accessing'!

{PackOBits} pattern

	"This method returns a 'signature' for the filter stream that identifies it for the purpose of combining filter streams into more efficient, code-supported filters (primitive filters)."
	
	^ self concat: (MuWordArray make.charVector: 'Unique')
			with: (self wrap: (myInputStream pattern))! !

!UniqueFilter methodsFor: 'streaming'!

{ID} fetch

	"This method returns the current ID on the stream, or NULL if hasValue is FALSE.  The fetch does NOT affect the state of the stream."
	
	^ myNext!

{BooleanVar} hasValue

	"This method returns TRUE iff a fetch on the stream will produce an ID"
	
	^ myNext == NULL!

{void} step

	"This method advances the stream to the next ID.  This is a valid operation iff hasValue is TRUE, it will blast otherwise."
	
	self skipToNext! !

!UniqueFilter methodsFor: 'private: filtering'!

{void} skipToNext
	| seeking {BooleanVar} |
	seeking _ true.
	[seeking and: [myInputStream hasValue]] whileTrue: [
		myNext _ myInputStream fetch.
		(myCollection hasMember: myNext) not
			ifTrue: [myCollection addMember: myNext.
				seeking _ false]].
	seeking ifTrue: [myNext _ NULL]! !

!UniqueFilter methodsFor: 'creation'!

create: onInput {FilterStream}
	super create.
	myInputStream _ onInput.
	myCollection _ MuSet make.
	myNext _ NULL.
	self skipToNext! !MoveMaker subclass: #FirstFitMaker
	instanceVariableNames: '
		oldSequences {MuSet of: EditSequences}
		newSequences {MuSet of: EditSequences}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(FirstFitMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FirstFitMaker methodsFor: 'accessing'!

{void} makeSequences
	oldSequences count == 1 ifTrue: 
		[newSequences _ oldSequences cast: MuSet].
	oldSequences stepper forEach: [:eachSeq {EditSequence} |
		self arrange: eachSeq].
	self pickBest: oldSequences.!

{MuSet of: EditSequences} sequences
	newSequences == NULL
		ifTrue: [self makeSequences].
	^newSequences! !

!FirstFitMaker methodsFor: 'scoring'!

{MuSet of: EditSequences} lowestMoveCount: set {MuSet of: EditSequences}
	| scoreTable {IntegerTable of: (MuSet of: EditSequences)} score {IntegerVar} |
	scoreTable _ IntegerTable make.
	set stepper forEach: [:eachSeq {EditSequence} |
		score _ eachSeq countMoves.
		(scoreTable fetch: score) == NULL
			ifTrue: [scoreTable at: score introduce: (MuSet make.Heaper: eachSeq)]
			ifFalse: [((scoreTable fetch: score) cast: MuSet) store: eachSeq]].
	^(scoreTable fetch: (scoreTable domain cast: IntegerRegion) start) cast: MuSet!

{void} pickBest: set {MuSet of: EditSequences}
	"newSequences _ self lowestMoveCount: set."
	newSequences _ self shortestMoves: set.
	"newSequences _ self smallShortMoves: newSequences."!

{MuSet of: EditSequences} shortestMoves: set {MuSet of: EditSequences}
	| scoreTable {IntegerTable of: (MuSet of: EditSequences)} score {IntegerVar} |
	scoreTable _ IntegerTable make.
	set stepper forEach: [:eachSeq {EditSequence} |
		score _ eachSeq totalMoveDistances.
		(scoreTable intFetch: score) == NULL
			ifTrue: [scoreTable atInt: score introduce: (MuSet make.Heaper: eachSeq)]
			ifFalse: [((scoreTable intFetch: score) cast: MuSet) store: eachSeq]].
	^(scoreTable intFetch: (scoreTable domain cast: IntegerRegion) start) cast: MuSet!

{MuSet of: EditSequences} smallShortMoves: set {MuSet of: EditSequences}
	| scoreTable {IntegerTable of: (MuSet of: EditSequences)} score {IntegerVar} |
	scoreTable _ IntegerTable make.
	set stepper forEach: [:eachSeq {EditSequence} |
		score _ eachSeq moveSizeXDist.
		(scoreTable fetch: score) == NULL
			ifTrue: [scoreTable at: score introduce: (MuSet make.Heaper: eachSeq)]
			ifFalse: [((scoreTable fetch: score) cast: MuSet) store: eachSeq]].
	^(scoreTable fetch: (scoreTable domain cast: IntegerRegion) start) cast: MuSet! !

!FirstFitMaker methodsFor: 'arranging Sequences'!

{EditSequence} arrange: aSeq {EditSequence}
	"rearrange the operations in aSeq (by turning some inserts and deletes into moves)"
	| inserts {IntegerTable of: IntegerPos} deletes {IntegerTable of: IntegerPos} editStart {IntegerVar} ops {MuTable of: editOperations} |
	inserts _ IntegerTable make.
	deletes _ IntegerTable make.
	ops _ aSeq operations.
	IntegerVar0 to: aSeq count do: [:index {IntegerVar} | | edit {EditOperation} |
		edit _ (ops intFetch: index) cast: EditOperation.
		(edit == NULL) ifFalse: 
		  [((edit isKindOf: DeleteOperation)
		    and: [edit isPureDelete not]) ifTrue:
			[editStart _ edit startLocations start.
		  	(inserts intFetch: editStart) == NULL
				ifTrue: [deletes at: editStart store: index integer]
				ifFalse: [self arrangeMove: aSeq with: index with: ((inserts intFetch: editStart) cast: IntegerPos) asIntegerVar]].
		  ((edit isKindOf: InsertOperation)
		    and: [edit isPureInsert not]) ifTrue:
			[editStart _ edit startLocations start.
		  	(deletes intFetch: editStart) == NULL
				ifTrue: [inserts at: editStart store: index integer]
				ifFalse: [self arrangeMove: aSeq with: ((deletes intFetch: editStart) cast: IntegerPos) asIntegerVar with: index]].
		 (edit isKindOf: MoveOperation) ifTrue:
			["deal with moves later"]]].
	^aSeq!

{void} arrangeComplexMove: aSeq {EditSequence} with: deletes {IntegerTable of: EditOperation} with: inserts {IntegerTable of: EditOperation}

	| smallSeq {EditSequence} moveIn {MoveInOperation} moveOut {MoveOutOperation} |
	smallSeq _ aSeq editSequenceForMove: deletes with: inserts.
	self arrange: smallSeq.
	moveIn _ MoveInOperation make.IntegerTable: smallSeq operations with: (deletes domain cast: IntegerRegion) start.
	moveOut _ MoveOutOperation make.IntegerTable: smallSeq operations with: (inserts domain cast: IntegerRegion) start.
	aSeq rearrange: (deletes domain cast: IntegerRegion) with: moveOut.
	aSeq rearrange: (inserts domain cast: IntegerRegion) with: moveIn.
	^VOID!

{void} arrangeMove: aSeq {EditSequence} with: from {IntegerVar} with: to {IntegerVar}
	"rearrange the operations in aSeq by turning matching inserts (around 'to') and deletes (around 'from') into moves"
	| fromPiece {EditOperation} toPiece {EditOperation} inserts {IntegerTable of: EditOperation} deletes {IntegerTable of: EditOperation} |
	fromPiece _ aSeq fetchOperation: from.
	toPiece _ aSeq fetchOperation: to.
	((fromPiece isKindOf: DeleteOperation)
	   and: [(toPiece isKindOf: InsertOperation)
		and: [(fromPiece quickCast: DeleteOperation) sameFragmentAs: (toPiece quickCast: InsertOperation)]])
		ifFalse: [^VOID].
	deletes _ aSeq contiguousDeletes: from.
	inserts _ aSeq contiguousInserts: to with: deletes.
	((deletes count == 1) or: [inserts count == 1]) ifTrue:
		[aSeq makeMove: from with: to.
		^VOID].
	self arrangeComplexMove: aSeq with: deletes with: inserts.
	^VOID! !

!FirstFitMaker methodsFor: 'creation'!

create: seqs {MuSet of: EditSequence}
	super create.
	oldSequences _ seqs.
	newSequences _ NULL.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FirstFitMaker class
	instanceVariableNames: ''!

(FirstFitMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FirstFitMaker class methodsFor: 'pseudoConstructors'!

{FirstFitMaker} make: seqs {MuSet of: EditSequence}

	^FirstFitMaker create: seqs! !Thunk subclass: #FollowThunk
	instanceVariableNames: 'myWindow {DocumentWindowModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!
FollowThunk comment:
'Follows a reference and opens a window on the other end when invoked, selecting the appropriate contents

		myReferences {ListModel of: Reference}
			The references which might be followed
		mySelection {SelectionObject}
			Uses the selection point to determine which of the references to follow'!

(FollowThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FollowThunk methodsFor: 'create'!

create: window {DocumentWindowModel}
	super create.
	myWindow _ window! !

!FollowThunk methodsFor: 'operate'!

{void} execute
	"open a new window on the other end of the link"
	|  result {Pair of: ID and: Reference} doc {DocumentModel} |
	[Cursor wait showWhile: [
		result _ self follow]] smalltalkOnly.
	[result _ self follow] translateOnly.
	doc _ Application fluidGet getDocument: (result left cast: ID).
	Application fluidGet openWindowAt: doc
		with: ((result right cast: Reference) regionIn: doc)! !

!FollowThunk methodsFor: 'private: private'!

{Pair of: ID and: Reference} follow
	"choose a reference and follow it"
	self thingToDo. "menu for multiple endsets and ends"
	^((myWindow references
		get: (myWindow referencesSelection selectionPoint
			cast: IntegerPos) asIntegerVar)
	cast: Reference) follow: myWindow document! !

!FollowThunk methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<<  'myWindow = ' <<  myWindow! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FollowThunk class
	instanceVariableNames: ''!

(FollowThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FollowThunk class methodsFor: 'pseudo constructors'!

make: window {DocumentWindowModel}
	^self create: window! !FMBuilder subclass: #FullReferenceBuilder
	instanceVariableNames: ''
	classVariableNames: 'FullReferencePortions {ListModel of: Portion} '
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
FullReferenceBuilder comment:
'Builds a view onto a reference.
*Eventually, will be a director that has a model
describing the format of the view'!

(FullReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FullReferenceBuilder */
friend SPTR(FullReferenceBuilder)  fullReferenceBuilder
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FullReferenceBuilder methodsFor: 'private: creation'!

create! !

!FullReferenceBuilder methodsFor: 'build'!

{FMBuilding} build: what {Heaper unused}

	self unimplemented.
	^ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FullReferenceBuilder class
	instanceVariableNames: ''!

(FullReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FullReferenceBuilder */
friend SPTR(FullReferenceBuilder)  fullReferenceBuilder
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FullReferenceBuilder class methodsFor: 'make'!

make
	^ self create! !XnModel subclass: #ID2LockSchnert
	instanceVariableNames: '
		myKeyMaster {KeyMaster}
		myIDModel {VariableModel of: PackOBits}
		myLockModel {VariableModel of: Lock}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-loginpn'!
ID2LockSchnert comment:
'This schnert watches an ID model and gets the corresponding lock for a user of that ID'!

(ID2LockSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!ID2LockSchnert methodsFor: 'create'!

create: km {KeyMaster} with: onIDModel {VariableModel of: ID} with: lockModel {VariableModel of: Lock}

	super create.
	myKeyMaster _ km.
	myIDModel _ onIDModel.
	myIDModel addDependent: self.
	myLockModel _ lockModel!

{void} destruct

	myIDModel removeDependent: self.
	myIDModel _ NULL.
	myLockModel _ NULL.
	myKeyMaster _ NULL.
	super destruct! !

!ID2LockSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	| anID {ID} |
	[VariableModel] USES.
	anID _ (myIDModel fetchValue cast: ID).
	anID == NULL ifTrue: [myLockModel setValue: NULL.
		^ VOID].
	myLockModel setValue: (XuServer currentServer login: anID)! !

!ID2LockSchnert methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ID2LockSchnert class
	instanceVariableNames: ''!

(ID2LockSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!ID2LockSchnert class methodsFor: 'make'!

make: km {KeyMaster} with: onIDModel {VariableModel of: ID} with: lockModel {VariableModel of: Lock}

	^ self create: km with: onIDModel with: lockModel! !XnModel subclass: #ID2PackOBitSchnert
	instanceVariableNames: '
		myUDM {UserDirectoryModel}
		myIDModel {VariableModel of: PackOBits}
		myPackModel {VariableModel of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(ID2PackOBitSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ID2PackOBitSchnert */
friend SPTR(ID2PackOBitSchnert)  iD2PackOBitSchnert (UserDirectoryModel * udm, VariableModel OF1(ID) * varID, VariableModel OF1(PackOBits) * varPack);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ID2PackOBitSchnert methodsFor: 'private: creation'!

create: udm {UserDirectoryModel} with: varID {VariableModel of: ID} with: varPack {VariableModel of: PackOBits}

	super create.
	myUDM _ udm.
	myIDModel _ varID.
	myPackModel _ varPack.
	myIDModel addDependent: self.
	self updatePack! !

!ID2PackOBitSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	self updatePack! !

!ID2PackOBitSchnert methodsFor: 'private: updating'!

{void} updatePack
	myIDModel fetchValue == NULL
		ifTrue: [myPackModel setValue: (Sequence string: '')]
		ifFalse: [myPackModel setValue: (myUDM fetchName: (myIDModel fetchValue cast: ID))]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ID2PackOBitSchnert class
	instanceVariableNames: ''!

(ID2PackOBitSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ID2PackOBitSchnert */
friend SPTR(ID2PackOBitSchnert)  iD2PackOBitSchnert (UserDirectoryModel * udm, VariableModel OF1(ID) * varID, VariableModel OF1(PackOBits) * varPack);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ID2PackOBitSchnert class methodsFor: 'make'!

make: udm {UserDirectoryModel} with: varID {VariableModel of: ID} with: varPack {VariableModel of: PackOBits}

	^ self create: udm with: varID with: varPack! !Thunk subclass: #ImportThunk
	instanceVariableNames: 'myWindow {DocumentModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!

(ImportThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ImportThunk methodsFor: 'create'!

create: window {DocumentModel}
	super create.
	
	myWindow _ window! !

!ImportThunk methodsFor: 'operate'!

{void} execute
 "for now will cheat and just read in a precanned document"
 
 [
Filesys readFile:  myWindow contents with: (UInt8Array string:  'foo'  ) with: (UInt8Array string: 'bar'  ) as: 1 .
  
 ] smalltalkOnly! !

!ImportThunk methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<<  'myWindow = ' <<  myWindow! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ImportThunk class
	instanceVariableNames: ''!

(ImportThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ImportThunk class methodsFor: 'pseudo constructors'!

make: window {DocumentModel}
	^self create: window! !Heaper subclass: #LCSFinder
	instanceVariableNames: '
		myStartOrder {IntegerTable of: CompareFragment}
		myEndOrder {IntegerTable of: CompareFragment}
		myNextDiagonals {IntegerTable of: (MuSet of: (Pair of: IntegerPos))}
		myDiagonals {LCSDiagonalMatrix}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
LCSFinder comment:
'LCSFinder finds Longest Common Sequences between two documents.  Its algorithm is based on the one in "A File Comparison Program" by W. Miller and E. W. Myers which appeared in Software Practice & Experience V15 #11 in November 1985.  Please see the paper for an explanation of the basic algorithm.  

There are some modifications used because I have been provided with a pre-computed comparison of the documents.  This allows me to check whole ranges of text with a single operation, and so I increase the costs by the size of the regions rather than 1 as they did.  (They compared a character or line at a time, and so their costs were constant.)

Since my regions have different sizes, I can''t expand the frontier the same way they do either.  I keep track of a current lowerBound, and at any point all entries less than the lowerBound have already been propogated, and so only higher values can appear.  

Because of the way I''m expanding the frontiers, I don''t know that I''ll get each entry correct the first time I store something in it.  I therefore check when adding an entry, and if the new value is lower, I continue propogating, and otherwise just discard the value.

I use a DiagonalMatrix to store the intermediate values as Miller & Myers did.  This is not really necessary; I can''t expand only at the frontier so I have to store a cost and editSequence with each entry.  I''ve kept the DiagonalMatrix around because it understands how to store and provide access to the cost and editSequence at each matrix element.'!

(LCSFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSFinder methodsFor: 'creation'!

create: start {IntegerTable of: CompareFragment} with: finish {IntegerTable of: CompareFragment}
	super create.
	myStartOrder _ start.
	myEndOrder _ finish.
	myNextDiagonals _ IntegerTable make.
	self initializeDiagonals!

{void} initializeDiagonals
	myDiagonals _ LCSDiagonalMatrix make: myStartOrder count with: myEndOrder count.
	(myDiagonals fetch: IntegerVar0)
		addEntryAt: IntegerVar0 with: IntegerVar0 with: EditSequence make.
	self propogateDiagonally: IntegerVar0 with: IntegerVar0.! !

!LCSFinder methodsFor: 'propogating values'!

{void} addToQueue: offset {IntegerVar} with: index {IntegerVar}
	| curEntry {IntegerVar} pair {Pair of: IntegerPos} |
	curEntry _ (myDiagonals fetch: offset) entryAt: index.
	pair _ Pair make: (IntegerPos make: offset) with: (IntegerPos make: index).
	(myNextDiagonals intFetch: curEntry) == NULL
		ifTrue: 
			[ | newSet {MuSet of: (Pair of: IntegerPos)} |
			newSet _ MuSet make.Heaper: pair.
			myNextDiagonals atInt: curEntry introduce: newSet]
		ifFalse:
			[((myNextDiagonals intFetch: curEntry) cast: MuSet) store: pair]!

{void} propogate: offset {IntegerVar} with: index {IntegerVar}
	self propogateRight: offset with: index.
	self propogateDown: offset with: index.!

{void} propogateDiagonally: offset { IntegerVar} with: index {IntegerVar}
	| diagonal {LCSDiagonal} row {IntegerVar} column {IntegerVar} valueIsNew {BooleanVar} bumpCount {IntegerVar}|
	diagonal _ myDiagonals fetch: offset.
	row _ diagonal rowFor: index.
	column _ diagonal columnFor: index.
	valueIsNew _ true.
	bumpCount _ 1.
	[valueIsNew
		and: [((myStartOrder intFetch: column + bumpCount) == NULL) not
			and: [((myStartOrder intFetch: column + bumpCount) cast: CompareFragment)
				== ((myEndOrder intFetch: row + bumpCount) cast: CompareFragment)]]]
	   whileTrue:
		[ | nextFragment {CompareFragment} |
		nextFragment _ (myStartOrder intFetch: column + bumpCount) cast: CompareFragment.
		valueIsNew _ diagonal 
			addShareEntryAt: index + bumpCount
			with: (diagonal entryAt: index)
			with: ((diagonal scriptFor: index + bumpCount - 1) cast: EditSequence)
			with: nextFragment.
		bumpCount _ bumpCount + 1].
	valueIsNew ifTrue:
		[self addToQueue: offset with: index + bumpCount - 1]
		"The final test could be moved inside the loop if you want to find more paths."!

{void} propogateDown: offset {IntegerVar} with: index {IntegerVar}

	| diagonal {LCSDiagonal} nextIndex {IntegerVar} nextFragment {CompareFragment} |
	diagonal _ myDiagonals fetch: offset.
	(offset > IntegerVar0) ifTrue: [nextIndex _ index + 1] ifFalse: [nextIndex _ index].
	((diagonal rowFor: index + 1) > myDiagonals rows) ifTrue: [^VOID].
	nextFragment _ (myEndOrder intFetch: (diagonal rowFor: index + 1)) cast: CompareFragment.
	((myDiagonals fetch: offset - 1)
		addInsertEntryAt: nextIndex
		with: (diagonal entryAt: index) + nextFragment count
		with: ((diagonal scriptFor: index) cast: EditSequence)
		with: nextFragment)
	    ifTrue:
		[self propogateDiagonally: offset - 1 with: nextIndex].!

{void} propogateRight: offset {IntegerVar} with: index {IntegerVar}

	| diagonal {LCSDiagonal} nextIndex {IntegerVar} nextFragment {CompareFragment} |
	diagonal _ myDiagonals fetch: offset.
	(offset < IntegerVar0)
		ifTrue: [nextIndex _ index + 1]
		ifFalse: [nextIndex _ index].
	((diagonal columnFor: index + 1) > myDiagonals columns)
		ifTrue: [^VOID].
	nextFragment _ (myStartOrder intFetch: (diagonal columnFor: index + 1)) cast: CompareFragment.
	((myDiagonals fetch: offset + 1)
		addDeleteEntryAt: nextIndex
		with: (diagonal entryAt: index) + nextFragment count
		with: ((diagonal scriptFor: index) cast: EditSequence)
		with: nextFragment)
	   ifTrue:
		[self propogateDiagonally: offset + 1 with: nextIndex].! !

!LCSFinder methodsFor: 'computing commonSequence'!

{void} advanceLowerBound
	| curValue {IntegerVar} |
	curValue _ (myNextDiagonals domain cast: IntegerRegion) start.
	((myNextDiagonals intFetch: curValue) cast: MuSet) stepper forEach: 
		[:each {Pair of: IntegerPos} | | l {IntegerVar} r {IntegerVar} |
		l _ (each left cast: IntegerPos) asIntegerVar.
		r _ (each right cast: IntegerPos) asIntegerVar.
		(((myDiagonals fetch: l) entryAt: r) == curValue)
			ifTrue: [self propogate: l with: r]].
	myNextDiagonals intWipe: curValue.!

{EditSequence} fillInTable
	| finalDiagonal {LCSDiagonal} finalIndex {IntegerVar} |
	finalDiagonal _ myDiagonals fetch: (myStartOrder count - myEndOrder count).
	finalIndex _ myStartOrder count min: myEndOrder count.
	[(myNextDiagonals domain isEmpty) not
		and: [((finalDiagonal entryAt: finalIndex) == NULL) 
		or: [(myNextDiagonals domain cast: IntegerRegion) start <= (finalDiagonal entryAt: finalIndex)]]]
	whileTrue:
		[self advanceLowerBound].
	^(finalDiagonal scriptFor: finalIndex) cast: EditSequence! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LCSFinder class
	instanceVariableNames: ''!

(LCSFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSFinder class methodsFor: 'pseudoConstructors'!

{LCSFinder} make: start {IntegerTable of: CompareFragment} with: finish {IntegerTable of: CompareFragment}

	^LCSFinder create: start with: finish! !XnModel subclass: #LinkEndsModel
	instanceVariableNames: '
		myApplication {TapestryAppModel}
		myEnds {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
LinkEndsModel comment:
'A list of link ends that keeps track of the last entry. '!

(LinkEndsModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkEndsModel */
friend SPTR(LinkEndsModel) linkEndsModel (IntegerTable * onTable);
friend SPTR(LinkEndsModel) linkEndsModel ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkEndsModel methodsFor: 'accessing'!

{ListModel of: AttributedTextModel} descriptionList
	| furniture {Accumulator} |
	furniture _ MuArray arrayAccumulator.
	myEnds asTable stepper forEach: [:end {LinkEnd} | | desc
{XuText} |
		desc _ end fetchDescriptor cast: XuText.
		desc == NULL ifTrue: [desc _ end getEndContext cast:
XuText].
		furniture step: (WaldoTextModel
attributedTextModel.Text: desc)].
	^ListModel make.IntegerTable: (furniture value cast:
IntegerTable)!

{LinkEnd} fetch: index {IntegerVar} 
	^ (myEnds fetch: index) cast: LinkEnd!

{AttributedTextModel} fetchDescription: index {IntegerVar} 
	| end {LinkEnd} desc {XuText} |
	end _ (myEnds fetch: index) cast: LinkEnd.
	end == NULL ifTrue: [^NULL].
	desc _ end fetchDescriptor cast: XuText.
	desc == NULL ifTrue: [desc _ end getEndContext cast: XuText].
	^WaldoTextModel attributedTextModel.Text: desc!

{LinkEnd} lastEnd
	"the link end last inserted into the list"
	myEnds count == IntegerVar0
		ifTrue: [Heaper BLAST: #NoLinkEnds].
	^(myEnds get: (myEnds count - 1)) cast: LinkEnd!

{void} store: end {LinkEnd}
	"store a new link end at the end of the list"

	myEnds insert: myEnds count with: end! !

!LinkEndsModel methodsFor: 'manipulating'!

{void} insert: index {IntegerVar} with: insertee {Heaper}

	myEnds insert: index with: (insertee cast: LinkEnd)!

{void} replace: index {IntegerVar} with: insertee {Heaper}

	myEnds replace: index with: (insertee cast: LinkEnd)!

{void} wipe: area {XnRegion}

	myEnds wipe: area! !

!LinkEndsModel methodsFor: 'private: create'!

create

	super create.
	myEnds _ ListModel make.
	myEnds addDependent: self!

create: onTable {IntegerTable}

	super create.
	myEnds _ ListModel make: onTable.
	myEnds addDependent: self!

{void} destruct

	myEnds removeDependent: self.
	myEnds _ NULL.
	super destruct! !

!LinkEndsModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	sender == (myEnds basicCast: XnModel) ifTrue: [self changed: ur]! !

!LinkEndsModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	 oo <<  self getCategory name << '(' << '  myApplication' << myApplication << ' myEnds ' <<	myEnds  << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkEndsModel class
	instanceVariableNames: ''!

(LinkEndsModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkEndsModel */
friend SPTR(LinkEndsModel) linkEndsModel (IntegerTable * onTable);
friend SPTR(LinkEndsModel) linkEndsModel ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkEndsModel class methodsFor: 'pseudo constructors'!

make
	^self create!

make: onTable {IntegerTable}
	^self create: onTable! !Thunk subclass: #LinkMakerThunk
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!
LinkMakerThunk comment:
'creates a LinkMakerWindowModel and opens it.'!

(LinkMakerThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkMakerThunk methodsFor: 'operate'!

{void} execute
	"create and open a LinkMaker window"

	LinkMakerWindowModel make open! !

!LinkMakerThunk methodsFor: 'creation'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkMakerThunk class
	instanceVariableNames: ''!

(LinkMakerThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkMakerThunk class methodsFor: 'pseudo constructors'!

make
	^ self create! !XnSensor subclass: #LinkReferenceSensor
	instanceVariableNames: '
		myDocument {DocumentModel}
		myReferences {SetModel of: Reference}
		myMap {IndirectRecord}
		myDestroy {XnModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
LinkReferenceSensor comment:
'Puts new references that are found by a BackReference into the reference list.
Destroys self when the Destry model changes'!

(LinkReferenceSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkReferenceSensor methodsFor: 'updating'!

{void} update: change {UpdateRecord} with: model {Heaper}
	(myDestroy == model and: [change isKindOf: NewContentsUpdate]) ifTrue:
		[myDestroy removeDependent: self.
		self destroy]! !

!LinkReferenceSensor methodsFor: 'create'!

create: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndirectRecord} with: destroy {XnModel | NULL}
	super create.
	myDocument _ document.
	myReferences _ references.
	myMap _ map.
	myDestroy _ destroy.
	myDestroy ~~ NULL ifTrue:
		[myDestroy addDependent: self]! !

!LinkReferenceSensor methodsFor: 'ringing'!

{NOWAIT PROXY} ring: a {Heaper}
	"add a reference to the set"
	| references {MuSet of: Reference} |
	references _ MuSet make.
	(a cast: IDRegion) stepper forEach: [ :each {ID} |
		references storeAll: (Reference
			linkReferences: ((myMap indirectGet: each) cast: XuLink)
			with: myDocument)].
	myReferences storeAll: references! !

!LinkReferenceSensor methodsFor: 'protected: creation'!

{void} destruct
	myDestroy ~~ NULL ifTrue:
		[myDestroy removeDependent: self].
	super destruct! !

!LinkReferenceSensor methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
  
  oo <<  self getCategory name << ' myDocument = ' << myDocument <<
		' myReferences = '  << myReferences  
		<< 'mymap = ' << myMap  
		<< 'myDestroy = ' << myDestroy! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkReferenceSensor class
	instanceVariableNames: ''!

(LinkReferenceSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkReferenceSensor class methodsFor: 'make'!

make: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndirectRecord} with: destroy {XnModel default: NULL}
	^self create: document with: references with: map with: destroy! !

!LinkReferenceSensor class methodsFor: 'smalltalk: defaults'!

make: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndexedWaldo}
	^self make: document with: references with: map with: NULL! !XnDependent subclass: #LinkTypeList2WordArrayListSchnert
	instanceVariableNames: '
		myLinkTypeList {ListModel of: PackOBits}
		myLinkTypeNameList {ListModel of: MuWordArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-linkmkr'!
LinkTypeList2WordArrayListSchnert comment:
'This class maintains a list of readable link types from the linkType list in the UserModel'!

(LinkTypeList2WordArrayListSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkTypeList2WordArrayListSchnert */
friend SPTR(LinkTypeList2WordArrayListSchnert)
	 linkTypeList2WordArrayListSchnert (ListModel * a, ListModel * b);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkTypeList2WordArrayListSchnert methodsFor: 'private: creation'!

create: onLinkTypes {ListModel} with: linkTypeDescriptions {ListModel}

	super create.
	myLinkTypeList _ onLinkTypes.
	myLinkTypeNameList _ linkTypeDescriptions! !

!LinkTypeList2WordArrayListSchnert methodsFor: 'updating'!

{void} syncLists

	myLinkTypeNameList wipe: (myLinkTypeNameList domain).
	IntegerVar0 almostTo: myLinkTypeList count do: [:index {IntegerVar} |
		myLinkTypeNameList insert: index with: (self extractAndConvertToWordArray: index)].!

{void} update: ur {UpdateRecord} from: sender {XnModel}
	sender == myLinkTypeList
		ifTrue: [(ur isKindOf: InsertionUR)
			ifTrue: [self insertLinkUpdate: (ur basicCast:
InsertionUR) index]
		ifFalse: [(ur isKindOf: DeletionUR)
			ifTrue: [self removeLinkUpdate: (ur basicCast:
DeletionUR) region]
		ifFalse: [Heaper BLAST: #INVALID.U.UPDATE.U.RECORD]]]
	ifFalse: [(sender == myLinkTypeNameList)
		ifTrue: ["nada fer now"]
	ifFalse: [Heaper BLAST: #WhyDidIGetThis.U.Interogative]]! !

!LinkTypeList2WordArrayListSchnert methodsFor: 'private: schnerting'!

{Pair of: MuWordArray and: MuWordArray} extractAndConvertToWordArray: index {IntegerVar} 
	| linkTypeDoc {LinkTypeDescription} res {MuWordArray}
	 left {MuWordArray} right {MuWordArray} first {MuWordArray} |
	linkTypeDoc _ LinkTypeDescription
		defaultDescription: Application fluidGet user keyMaster
		with: ((myLinkTypeList get: index) cast: ID).
	left _ (linkTypeDoc leftLabel cast: XuText) asDataTable asMuTable cast: MuWordArray.
	right _ (linkTypeDoc rightLabel cast: XuText) asDataTable asMuTable cast: MuWordArray.
	res _ left copy cast: MuWordArray.
	res introduceAll: (MuWordArray make.charVector: ' ... ') with: (IntegerMapping make: res count).
	res introduceAll: right with: (IntegerMapping make: res count).
	first _ res.
	res _ right copy cast: MuWordArray.
	res introduceAll: (MuWordArray make.charVector: ' ... ') with: (IntegerMapping make: res count).
	res introduceAll: left with: (IntegerMapping make: res count).

	linkTypeDoc destroy.
	^Pair make: first with: res!

{void} insertLinkUpdate: where {IntegerVar}

	myLinkTypeNameList insert: where with: (self extractAndConvertToWordArray: where)!

{void} removeLinkUpdate: where {XnRegion}

	myLinkTypeNameList wipe: where! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkTypeList2WordArrayListSchnert class
	instanceVariableNames: ''!

(LinkTypeList2WordArrayListSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkTypeList2WordArrayListSchnert */
friend SPTR(LinkTypeList2WordArrayListSchnert)
	 linkTypeList2WordArrayListSchnert (ListModel * a, ListModel * b);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkTypeList2WordArrayListSchnert class methodsFor: 'pseudoConstructors'!

make: a {ListModel} with: b {ListModel}
	^ self create: a with: b! !XnDependent subclass: #List2ListLookupSchnert
	instanceVariableNames: '
		myFromList {ListModel}
		myToList {ListModel}
		myLookup {LookupTool}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!

(List2ListLookupSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!List2ListLookupSchnert methodsFor: 'creation'!

create: fromList {ListModel} with: toList {ListModel} with: lookup {LookupTool}

	super create.
	myFromList _ fromList.
	myToList _ toList.
	myLookup _ lookup.
	myFromList addDependent: self.
	self updateSingleReplace! !

!List2ListLookupSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	(ur isKindOf: SingleReplaceUR)
		ifTrue: [self updateSingleReplace]
	ifFalse: [(ur isKindOf: DeletionUR)
		ifTrue: [self updateDeletion: (ur basicCast: DeletionUR) region]
	ifFalse: [(ur isKindOf: InsertionUR)
		ifTrue: [self updateInsertion: (ur basicCast: InsertionUR) position
					with: (ur basicCast: InsertionUR) count]
	ifFalse: [(ur isKindOf: RearrangeUpdate)
		ifTrue: [| ra {RearrangeUpdate wimpy} |
			ra _ ur basicCast: RearrangeUpdate.
			self updateRearrange: ra cut1 with: ra cut2 with: ra cut3]
	ifFalse: [(ur isKindOf: RegionUR)
		ifTrue: [self updateReplace: (ur basicCast: RegionUR) region]]]]]! !

!List2ListLookupSchnert methodsFor: 'private: updating'!

{void} updateDeletion: region {XnRegion}
	"update a deletion in one list"
	myToList wipe: region!

{void} updateInsertion: pos {Position} with: count {IntegerVar}

	| iPos {IntegerVar} |
	count ~= 1 ifTrue: [self unimplemented. ^ VOID].
	iPos _ (pos cast: IntegerPos) asIntegerVar.
	myToList insert: iPos with: (myLookup lookup: (myFromList get: iPos))!

{void} updateRearrange: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}
	"propagate a rearrange"
	myToList rearrange: cut1 with: cut2 with: cut3!

{void} updateReplace: region {XnRegion} 
	"elements have been replaced"

	| fromPos {IntegerVar} |
	(region count = 1 and: [region isKindOf: IntegerRegion])
		ifFalse: [self unimplemented].
	fromPos _ (region basicCast: IntegerRegion) start.
	myToList replace: fromPos with: (myLookup lookup: (myFromList get: fromPos))!

{void} updateSingleReplace
	"the entire contents have been replaced"

	myToList wipe: myToList domain.
	myFromList domain stepper forEach: [ :key {Position} |
		myToList replace: (key cast: IntegerPos) asIntegerVar with: 
			(myLookup lookup: (myFromList get: (key cast: IntegerPos) asIntegerVar))]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

List2ListLookupSchnert class
	instanceVariableNames: ''!

(List2ListLookupSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!List2ListLookupSchnert class methodsFor: 'make'!

make: from {ListModel} with: to {ListModel} with: look {LookupTool}
	^ self create: from with: to with: look! !XnDependent subclass: #LoginSchnert
	instanceVariableNames: '
		myApp {TapestryAppModel}
		myKM {VariableModel of: KeyMaster}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(LoginSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LoginSchnert methodsFor: 'create'!

create: kmVar {VariableModel of: KeyMaster} with: app {TapestryAppModel}

	super create.
	myApp _ app.
	myKM _ kmVar.
	myKM addDependent: self!

{void} destruct

	myApp _ NULL.
	myKM removeDependent: self.
	myKM _ NULL.
	super destruct.! !

!LoginSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	myKM fetchValue == NULL ifTrue: [^ VOID].
	myApp setKeyMaster: (myKM fetchValue cast: KeyMaster)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LoginSchnert class
	instanceVariableNames: ''!

(LoginSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LoginSchnert class methodsFor: 'make'!

make: kmVar {VariableModel of: KeyMaster} with: app {TapestryAppModel}

	^ self create: kmVar with: app! !Heaper subclass: #LookupTool
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!

(LookupTool getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!LookupTool methodsFor: 'deferred: accessing'!

{Heaper} lookup: item {Heaper}
	"I respond by looking up the input item and returning a corresponding heaper"
	self subclassResponsibility! !LookupTool subclass: #ID2ClubNameLookup
	instanceVariableNames: 'myDirectoryModel {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!

(ID2ClubNameLookup getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ID2ClubNameLookup methodsFor: 'accessing'!

{Heaper} lookup: item {Heaper} 
	| name {PackOBits} |
	name _ myDirectoryModel fetchName: (item cast: ID).
	name == NULL
		ifTrue: [^Sequence string: 'UNKNOWN']
		ifFalse: [^name]! !

!ID2ClubNameLookup methodsFor: 'creation'!

create: onUDM {UserDirectoryModel}

	super create.
	myDirectoryModel _ onUDM.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ID2ClubNameLookup class
	instanceVariableNames: ''!

(ID2ClubNameLookup getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ID2ClubNameLookup class methodsFor: 'make'!

make: udm {UserDirectoryModel}

	^ self create: udm! !XnModel subclass: #ModifyEditorsSchnert
	instanceVariableNames: '
		myPermissionsModel {PermissionsModel}
		myBoolean {BooleanModel}
		myPermissionsID {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(ModifyEditorsSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ModifyEditorsSchnert */
friend SPTR(ModifyEditorsSchnert)  modifyEditorsSchnert (PermissionsModel * editP, BooleanModel * editB, ID * id);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ModifyEditorsSchnert methodsFor: 'private: create'!

create: onPerm {PermissionsModel} with: onBool2Watch {BooleanModel} with: anID {ID}

	super create.
	myPermissionsModel _ onPerm.
	myBoolean _ onBool2Watch.
	myBoolean addDependent: self.
	myPermissionsID _ anID!

{void} destruct

	myBoolean removeDependent: self.
	myPermissionsModel _ NULL.
	myBoolean _ NULL.
	myPermissionsID _ NULL.
	super destruct! !

!ModifyEditorsSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	self updateModel!

{void} updateModel

	myBoolean getValue
		ifTrue: [(myPermissionsModel members hasMember: myPermissionsID)
			ifFalse: [myPermissionsModel addMember: myPermissionsID]]
		ifFalse: [(myPermissionsModel members hasMember: myPermissionsID)
			ifTrue: [myPermissionsModel removeMember: myPermissionsID]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModifyEditorsSchnert class
	instanceVariableNames: ''!

(ModifyEditorsSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ModifyEditorsSchnert */
friend SPTR(ModifyEditorsSchnert)  modifyEditorsSchnert (PermissionsModel * editP, BooleanModel * editB, ID * id);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ModifyEditorsSchnert class methodsFor: 'make'!

make: editP {PermissionsModel} with: editB {BooleanModel} with: id {ID}

	^ self create: editP with: editB with: id! !XnModel subclass: #ModifyReadersSchnert
	instanceVariableNames: '
		myReadersModel {PermissionsModel}
		myReaderB {BooleanModel}
		myEditorB {BooleanModel}
		myPermissionsID {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(ModifyReadersSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ModifyReadersSchnert */
friend SPTR(ModifyReadersSchnert)  modifyReadersSchnert (PermissionsModel * readP, BooleanModel * editB, BooleanModel * readB, ID * id);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ModifyReadersSchnert methodsFor: 'private: create'!

create: onPerm {PermissionsModel} with: editB {BooleanModel} with: readB {BooleanModel} with: anID {ID}

	super create.
	myReadersModel _ onPerm.
	myEditorB _ editB.
	myEditorB addDependent: self.
	myReaderB _ readB.
	myReaderB addDependent: self.
	myPermissionsID _ anID!

{void} destruct

	myReaderB removeDependent: self.
	myReadersModel _ NULL.
	myReaderB _ NULL.
	myEditorB _ NULL.
	myPermissionsID _ NULL.
	super destruct! !

!ModifyReadersSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	self updateModel!

{void} updateModel

	myReaderB getValue
		ifTrue: [myEditorB getValue
			ifFalse: [(myReadersModel members hasMember: myPermissionsID)
				ifFalse: [myReadersModel addMember: myPermissionsID]]]
		ifFalse: [(myReadersModel members hasMember: myPermissionsID)
			ifTrue: [myReadersModel removeMember: myPermissionsID]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModifyReadersSchnert class
	instanceVariableNames: ''!

(ModifyReadersSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ModifyReadersSchnert */
friend SPTR(ModifyReadersSchnert)  modifyReadersSchnert (PermissionsModel * readP, BooleanModel * editB, BooleanModel * readB, ID * id);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ModifyReadersSchnert class methodsFor: 'make'!

make: readP {PermissionsModel} with: editB {BooleanModel} with: readB {BooleanModel} with: id {ID}

	^ self create: readP with: editB with: readB with: id! !Thunk subclass: #MultiThunk
	instanceVariableNames: 'myThunks {ScruTable of: Thunk}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(MultiThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!MultiThunk methodsFor: 'creation'!

create: onTable {ScruTable of: Thunk}

	super create.
	myThunks _ onTable! !

!MultiThunk methodsFor: 'action'!

{void} execute
	myThunks stepper forEach: [:thunk {Thunk} | thunk execute]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiThunk class
	instanceVariableNames: ''!

(MultiThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!MultiThunk class methodsFor: 'make'!

{Thunk} make: onTable {ScruTable of: Thunk}

	^ self create: onTable! !Thunk subclass: #NewDocThunk
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!

(NewDocThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NewDocThunk methodsFor: 'operate'!

{void} execute
	"open a new window "
	|  tmp {XuText} docid{ID}  |
	[KeyMaster] USES.
	tmp _ ((Application fluidGet user keyMaster)
		makePersistentWaldo: (Sequence string: 'XuText')) cast: XuText.
	 docid _ tmp getID.
	 tmp destroy.
	Application fluidGet openWindow: (Application fluidGet getDocument: docid).! !

!NewDocThunk methodsFor: 'create'!

create 
	super create.! !

!NewDocThunk methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NewDocThunk class
	instanceVariableNames: ''!

(NewDocThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NewDocThunk class methodsFor: 'psuedoconstructors'!

make
	^NewDocThunk create! !XnModel subclass: #NotifierSchnert
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!

(NotifierSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NotifierSchnert methodsFor: 'create'!

create
	super create! !

!NotifierSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender
{XnModel unused}

	self changed: (NewContentsUpdate make)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NotifierSchnert class
	instanceVariableNames: ''!

(NotifierSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NotifierSchnert class methodsFor: 'pseudoConstructors'!

make
	^ self create! !XnModel subclass: #PackOBit2ATMSchnert
	instanceVariableNames: '
		myPackModel {VariableModel of: PackOBits}
		myATMModel {VariableModel of: AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(PackOBit2ATMSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class PackOBit2ATMSchnert */
friend SPTR(PackOBit2ATMSchnert)  packOBit2ATMSchnert (VariableModel OF1(PackOBits) * packM, VariableModel OF1(AttributedTextModel) * atmM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PackOBit2ATMSchnert methodsFor: 'private: creation'!

create: onPackM {VariableModel of: PackOBits} with: atmM {VariableModel of: AttributedTextModel}

	super create.
	myPackModel _ onPackM.
	myATMModel _ atmM.
	myPackModel addDependent: self! !

!PackOBit2ATMSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}
	self updateATM! !

!PackOBit2ATMSchnert methodsFor: 'private: updating'!

{void} updateATM
	myPackModel fetchValue == NULL
		ifTrue: [myATMModel setValue: NULL]
		ifFalse: [myATMModel setValue: ((myPackModel fetchValue convert: MuWordArray)
					convert: AttributedTextModel)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PackOBit2ATMSchnert class
	instanceVariableNames: ''!

(PackOBit2ATMSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class PackOBit2ATMSchnert */
friend SPTR(PackOBit2ATMSchnert)  packOBit2ATMSchnert (VariableModel OF1(PackOBits) * packM, VariableModel OF1(AttributedTextModel) * atmM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PackOBit2ATMSchnert class methodsFor: 'make'!

make: packM {VariableModel of: PackOBits} with: atmM {VariableModel of: AttributedTextModel}

	^ self create: packM with: atmM! !FMBuilder subclass: #PassageBuilder
	instanceVariableNames: 'mySelection {SelectionRange}'
	classVariableNames: 'GlobalActionTable {MuTable of: PackOBits and: Thunk} '
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
PassageBuilder comment:
'Builds a window onto the text contents of a passage

	mySelection {SelectionRange}
		The selection object to be used to edit the text'!

(PassageBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageBuilder methodsFor: 'build'!

{FMBuilding} build: something {Heaper as: PassageModel} 
	| dBuilding {FMBuilding} dMenus {FMController} |
	 
	dBuilding _ Scaffold fluidGet build: (SelectedTextModel make: ((something quickCast: PassageModel) contents quickCast: AttributedTextModel)
					with: mySelection).
					
	dMenus _ FMHighLevelAction make: (UInt8Array string: 'MENU')
				with: (self actionTableFor: (something cast: PassageModel)).
	dBuilding controller == NULL
		ifTrue: [^FMBuilding make: dBuilding view with: dMenus]
		ifFalse: [^FMBuilding make: dBuilding view with: (MultiController make: (MuArray array: dBuilding controller with: dMenus))]! !

!PassageBuilder methodsFor: 'create'!

create: selection {SelectionRange}
	super create.
	mySelection _ selection! !

!PassageBuilder methodsFor: 'private: building'!

{ScruTable of: PackOBits and: Thunk} actionTable
	| menuActions {MuTable of: PackOBits and: Thunk} |
	
	menuActions _ MuTable make: SequenceSpace make.
	GlobalActionTable _ menuActions.
	menuActions at: (Sequence string: 'saveAs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'save as') with: NULL).
	menuActions at: (Sequence string: 'setDescription') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'set description') with: NULL).
	menuActions at: (Sequence string: 'linkMaker') introduce:
(LinkMakerThunk make). 
menuActions at: (Sequence string: 'undo') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'undo') with: NULL).	
menuActions at: (Sequence string: 'redo') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'redo') with: NULL).	
menuActions at: (Sequence string: 'traceForward') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'traceForward') with: NULL).	
menuActions at: (Sequence string: 'traceBack') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'traceBack') with: NULL).	
	 menuActions at: (Sequence string: 'move') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'move') with: NULL).
 menuActions at: (Sequence string: 'cut') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'cut') with: NULL).
 menuActions at: (Sequence string: 'paste') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paste') with: NULL).

 menuActions at: (Sequence string: 'clear') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'clear') with: NULL).

 menuActions at: (Sequence string: 'selectAll') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'selectAll') with: NULL).

 menuActions at: (Sequence string: 'itemSelectFileLinks') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'itemSelectFileLinks') with: NULL).

 menuActions at: (Sequence string: 'new') introduce: 
		(NewDocThunk make ).
 menuActions at: (Sequence string: 'open') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'open') with: NULL).
 menuActions at: (Sequence string: 'close') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'close') with: NULL).
 
 menuActions at: (Sequence string: 'revertToSaved') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'revertToSaved') with: NULL).

 menuActions at: (Sequence string: 'rename') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'rename') with: NULL).

 menuActions at: (Sequence string: 'bullshitDeleteItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'bullshitDeleteItem') with: NULL).

 menuActions at: (Sequence string: 'previousVersionsDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'previousVersionsDocument') with: NULL).

 menuActions at: (Sequence string: 'thisVersionDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'thisVersionDocument') with: NULL).

 menuActions at: (Sequence string: 'allVersionsDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allVersionsDocument') with: NULL).


 menuActions at: (Sequence string: 'allButThisVersionDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allButThisVersionDocument') with: NULL).


 menuActions at: (Sequence string: 'previousVersionsReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'previousVersionsReferences:') with: NULL).

 menuActions at: (Sequence string: 'thisVersionReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'thisVersionReferences:') with: NULL).

 menuActions at: (Sequence string: 'allVersionsReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allVersionsReferences:') with: NULL).

 menuActions at: (Sequence string: 'DeleteLinks') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'DeleteLinks') with: NULL).

 menuActions at: (Sequence string: 'allButThisVersionReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allButThisVersionReferences:') with: NULL).
 
 
 
 
 menuActions at: (Sequence string: 'export') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'export') with: NULL).
 menuActions at: (Sequence string: 'import') introduce: 
		 (TranscriptThunk make: (MuWordArray make.charVector:
'import') with: NULL)	" (ImportThunk make:  mumbleWindow)".	
			
 menuActions at: (Sequence string: 'itemExperimental') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'itemExperimental') with: NULL).
 menuActions at: (Sequence string: 'newInclusionList') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newInclusionList') with: NULL).	

 menuActions at: (Sequence string: 'containSelectionItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'containSelectionItem') with: NULL).
 menuActions at: (Sequence string: 'convertPassageToIL') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'convertPassageToIL') with: NULL).	
									 
	
 menuActions at: (Sequence string: 'referenceSelection') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'referenceSelection') with: NULL).
 menuActions at: (Sequence string: 'editFilters') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'editFilters') with: NULL).	
	
 menuActions at: (Sequence string: 'debuggingItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'debuggingItem') with: NULL).
 menuActions at: (Sequence string: 'password') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'password') with: NULL).	
		
 menuActions at: (Sequence string: 'filter') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'filter') with: NULL).
 menuActions at: (Sequence string: 'linkTypes') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'linkTypes') with: NULL).	
														  	 
	
 menuActions at: (Sequence string: 'groups') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'groups') with: NULL).
 menuActions at: (Sequence string: 'depth1') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1') with: NULL).	
	
 menuActions at: (Sequence string: 'depth2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2') with: NULL).
 menuActions at: (Sequence string: 'depth3') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3') with: NULL).	
		 menuActions at: (Sequence string: 'depth4') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth4') with: NULL).	
	menuActions at: (Sequence string: 'depth5') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth5') with: NULL).	
		 menuActions at: (Sequence string: 'infinity') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'infinity') with: NULL).	
															 
	menuActions at: (Sequence string: 'edge') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'edge') with: NULL).	
		 menuActions at: (Sequence string: 'panel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'panel') with: NULL).	
  	menuActions at: (Sequence string: 'end') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'end') with: NULL).	
		 menuActions at: (Sequence string: 'walkersStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'walkersStyle') with: NULL).	
 	menuActions at: (Sequence string: 'changeBars') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'changeBars') with: NULL).	
		 menuActions at: (Sequence string: 'parallelTextFace') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'parallelTextFace') with: NULL).	
   		 menuActions at: (Sequence string: 'markUp') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'markUp') with: NULL).	
 	menuActions at: (Sequence string: 'expandHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'expandHeadlines') with: NULL).	
		 menuActions at: (Sequence string: 'collapseHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'collapseHeadlines') with: NULL).	
   		 menuActions at: (Sequence string: 'showHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'showHeadlines') with: NULL).	
 	menuActions at: (Sequence string: 'hideHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'hideHeadlines') with: NULL).	
		 menuActions at: (Sequence string: 'showReferenceStatusBar') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'showReferenceStatusBar') with: NULL).	
   	 menuActions at: (Sequence string: 'hideReferenceStatusBar') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'hideReferenceStatusBar') with: NULL).	
 	 menuActions at: (Sequence string: 'refutedByRefutes') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutedByRefutes') with: NULL).	
   	 menuActions at: (Sequence string: 'refutesRefutedBy') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutesRefutedBy') with: NULL).	
  	 menuActions at: (Sequence string: 'citedByCites') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citedByCites') with: NULL).	
  	 menuActions at: (Sequence string: 'citesCitedby') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citesCitedby') with: NULL).	
  	 menuActions at: (Sequence string: 'refutedByRefutes2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutedByRefutes2') with: NULL).	
     	 menuActions at: (Sequence string: 'refutesRefutedBy2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutesRefutedBy2') with: NULL).	
  	 menuActions at: (Sequence string: 'citedByCites2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citedByCites2') with: NULL).	
   	 menuActions at: (Sequence string: 'citesCitedby2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citesCitedby2') with: NULL).	
  	 menuActions at: (Sequence string: 'newSensorItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newSensorItem') with: NULL).	
            menuActions at: (Sequence string: 'newLinkEnd') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newLinkEnd') with: NULL).	
         	 menuActions at: (Sequence string: 'depth1Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1Compose') with: NULL).	
            menuActions at: (Sequence string: 'depth2Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2Compose') with: NULL).	
   	 menuActions at: (Sequence string: 'depth3Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3Compose') with: NULL).	
            menuActions at: (Sequence string: 'depth1IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1IncludeLinkEnds') with: NULL).	
  	 menuActions at: (Sequence string: 'depth2IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2IncludeLinkEnds') with: NULL).	
            menuActions at: (Sequence string: 'depth3IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3IncludeLinkEnds') with: NULL).	
             menuActions at: (Sequence string: 'includeTarget') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'includeTarget') with: NULL).	
  	 menuActions at: (Sequence string: 'switchToContainment') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'switchToContainment') with: NULL).	
            menuActions at: (Sequence string: 'switchToReference') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'switchToReference') with: NULL).	
                 menuActions at: (Sequence string: 'chicagoFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'chicagoFontMarcs') with: NULL).	
  	 menuActions at: (Sequence string: 'genivaFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'genivaFontMarcs') with: NULL).	
            menuActions at: (Sequence string: 'courierFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'courierFontMarcs') with: NULL).	
                                                                        
                 menuActions at: (Sequence string: 'size9Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size9Marcs') with: NULL).	
  	 menuActions at: (Sequence string: 'size10Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size10Marcs') with: NULL).	
            menuActions at: (Sequence string: 'size12Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size12Marcs') with: NULL).	
                                
                      menuActions at: (Sequence string: 'size14Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size14Marcs') with: NULL).	
  	 menuActions at: (Sequence string: 'boldStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'boldStyleMarcs') with: NULL).	
            menuActions at: (Sequence string: 'italicStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'italicStyleMarcs') with: NULL).	
        	 menuActions at: (Sequence string: 'underlineStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'underlineStyleMarcs') with: NULL).	
            menuActions at: (Sequence string: 'fontPanel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'fontPanel') with: NULL).	                                           
          	 menuActions at: (Sequence string: 'larger') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'larger') with: NULL).	
            menuActions at: (Sequence string: 'smaller') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'smaller') with: NULL).	                                           
              menuActions at: (Sequence string: 'heavier') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'heavier') with: NULL).	                                           
          	 menuActions at: (Sequence string: 'lighter') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'lighter') with: NULL).	
            menuActions at: (Sequence string: 'paragraphStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paragraphStyle') with: NULL).	                                           
            menuActions at: (Sequence string: 'fooDocumentStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'fooDocumentStyle') with: NULL).	                                           
          menuActions at: (Sequence string: 'paragraphStyles') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paragraphStyles') with: NULL).	                                           
          menuActions at: (Sequence string: 'printPanel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'printPanel') with: NULL).	                                           
                                                  
       menuActions at: (Sequence string: 'comparisonItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'comparisonItem') with: NULL).	                                           
      
          menuActions at: (Sequence string: 'Hide') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'Hide') with: NULL).	   
         menuActions at: (Sequence string: 'Quit') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'Quit') with: NULL).	                                           
       

	^ menuActions!

{ScruTable of: PackOBits and: Thunk} actionTableFor: something {  PassageModel}
	| menuActions {MuTable of: PackOBits and: Thunk} |
 
	menuActions _ MuTable make: SequenceSpace make.
	GlobalActionTable _ menuActions.
	menuActions at: (Sequence string: 'saveAs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'save as') with: NULL).
	menuActions at: (Sequence string: 'setDescription') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'set description') with: NULL).
	menuActions at: (Sequence string: 'linkMaker') introduce:
(LinkMakerThunk make). 
menuActions at: (Sequence string: 'undo') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'undo') with: NULL).	
menuActions at: (Sequence string: 'redo') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'redo') with: NULL).	
menuActions at: (Sequence string: 'traceForward') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'traceForward') with: NULL).	
menuActions at: (Sequence string: 'traceBack') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'traceBack') with: NULL).	
	 menuActions at: (Sequence string: 'move') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'move') with: NULL).
 menuActions at: (Sequence string: 'cut') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'cut') with: NULL).
 menuActions at: (Sequence string: 'paste') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paste') with: NULL).

 menuActions at: (Sequence string: 'clear') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'clear') with: NULL).

 menuActions at: (Sequence string: 'selectAll') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'selectAll') with: NULL).

 menuActions at: (Sequence string: 'itemSelectFileLinks') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'itemSelectFileLinks') with: NULL).

 menuActions at: (Sequence string: 'new') introduce: 
		(NewDocThunk make ).
 menuActions at: (Sequence string: 'open') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'open') with: NULL).
 menuActions at: (Sequence string: 'close') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'close') with: NULL).
 
 menuActions at: (Sequence string: 'revertToSaved') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'revertToSaved') with: NULL).

 menuActions at: (Sequence string: 'rename') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'rename') with: NULL).

 menuActions at: (Sequence string: 'bullshitDeleteItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'bullshitDeleteItem') with: NULL).

 menuActions at: (Sequence string: 'previousVersionsDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'previousVersionsDocument') with: NULL).

 menuActions at: (Sequence string: 'thisVersionDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'thisVersionDocument') with: NULL).

 menuActions at: (Sequence string: 'allVersionsDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allVersionsDocument') with: NULL).


 menuActions at: (Sequence string: 'allButThisVersionDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allButThisVersionDocument') with: NULL).


 menuActions at: (Sequence string: 'previousVersionsReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'previousVersionsReferences:') with: NULL).

 menuActions at: (Sequence string: 'thisVersionReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'thisVersionReferences:') with: NULL).

 menuActions at: (Sequence string: 'allVersionsReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allVersionsReferences:') with: NULL).

 menuActions at: (Sequence string: 'DeleteLinks') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'DeleteLinks') with: NULL).

 menuActions at: (Sequence string: 'allButThisVersionReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allButThisVersionReferences:') with: NULL).
 
 
 
 
 menuActions at: (Sequence string: 'export') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'export') with: NULL).
 menuActions at: (Sequence string: 'import') introduce: 
		  (ImportThunk make:  something).	
			
 menuActions at: (Sequence string: 'itemExperimental') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'itemExperimental') with: NULL).
 menuActions at: (Sequence string: 'newInclusionList') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newInclusionList') with: NULL).	

 menuActions at: (Sequence string: 'containSelectionItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'containSelectionItem') with: NULL).
 menuActions at: (Sequence string: 'convertPassageToIL') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'convertPassageToIL') with: NULL).	
									 
	
 menuActions at: (Sequence string: 'referenceSelection') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'referenceSelection') with: NULL).
 menuActions at: (Sequence string: 'editFilters') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'editFilters') with: NULL).	
	
 menuActions at: (Sequence string: 'debuggingItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'debuggingItem') with: NULL).
 menuActions at: (Sequence string: 'password') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'password') with: NULL).	
		
 menuActions at: (Sequence string: 'filter') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'filter') with: NULL).
 menuActions at: (Sequence string: 'linkTypes') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'linkTypes') with: NULL).	
														  	 
	
 menuActions at: (Sequence string: 'groups') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'groups') with: NULL).
 menuActions at: (Sequence string: 'depth1') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1') with: NULL).	
	
 menuActions at: (Sequence string: 'depth2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2') with: NULL).
 menuActions at: (Sequence string: 'depth3') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3') with: NULL).	
		 menuActions at: (Sequence string: 'depth4') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth4') with: NULL).	
	menuActions at: (Sequence string: 'depth5') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth5') with: NULL).	
		 menuActions at: (Sequence string: 'infinity') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'infinity') with: NULL).	
															 
	menuActions at: (Sequence string: 'edge') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'edge') with: NULL).	
		 menuActions at: (Sequence string: 'panel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'panel') with: NULL).	
  	menuActions at: (Sequence string: 'end') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'end') with: NULL).	
		 menuActions at: (Sequence string: 'walkersStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'walkersStyle') with: NULL).	
 	menuActions at: (Sequence string: 'changeBars') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'changeBars') with: NULL).	
		 menuActions at: (Sequence string: 'parallelTextFace') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'parallelTextFace') with: NULL).	
   		 menuActions at: (Sequence string: 'markUp') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'markUp') with: NULL).	
 	menuActions at: (Sequence string: 'expandHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'expandHeadlines') with: NULL).	
		 menuActions at: (Sequence string: 'collapseHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'collapseHeadlines') with: NULL).	
   		 menuActions at: (Sequence string: 'showHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'showHeadlines') with: NULL).	
 	menuActions at: (Sequence string: 'hideHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'hideHeadlines') with: NULL).	
		 menuActions at: (Sequence string: 'showReferenceStatusBar') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'showReferenceStatusBar') with: NULL).	
   	 menuActions at: (Sequence string: 'hideReferenceStatusBar') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'hideReferenceStatusBar') with: NULL).	
 	 menuActions at: (Sequence string: 'refutedByRefutes') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutedByRefutes') with: NULL).	
   	 menuActions at: (Sequence string: 'refutesRefutedBy') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutesRefutedBy') with: NULL).	
  	 menuActions at: (Sequence string: 'citedByCites') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citedByCites') with: NULL).	
  	 menuActions at: (Sequence string: 'citesCitedby') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citesCitedby') with: NULL).	
  	 menuActions at: (Sequence string: 'refutedByRefutes2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutedByRefutes2') with: NULL).	
     	 menuActions at: (Sequence string: 'refutesRefutedBy2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutesRefutedBy2') with: NULL).	
  	 menuActions at: (Sequence string: 'citedByCites2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citedByCites2') with: NULL).	
   	 menuActions at: (Sequence string: 'citesCitedby2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citesCitedby2') with: NULL).	
  	 menuActions at: (Sequence string: 'newSensorItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newSensorItem') with: NULL).	
            menuActions at: (Sequence string: 'newLinkEnd') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newLinkEnd') with: NULL).	
         	 menuActions at: (Sequence string: 'depth1Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1Compose') with: NULL).	
            menuActions at: (Sequence string: 'depth2Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2Compose') with: NULL).	
   	 menuActions at: (Sequence string: 'depth3Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3Compose') with: NULL).	
            menuActions at: (Sequence string: 'depth1IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1IncludeLinkEnds') with: NULL).	
  	 menuActions at: (Sequence string: 'depth2IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2IncludeLinkEnds') with: NULL).	
            menuActions at: (Sequence string: 'depth3IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3IncludeLinkEnds') with: NULL).	
             menuActions at: (Sequence string: 'includeTarget') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'includeTarget') with: NULL).	
  	 menuActions at: (Sequence string: 'switchToContainment') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'switchToContainment') with: NULL).	
            menuActions at: (Sequence string: 'switchToReference') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'switchToReference') with: NULL).	
                 menuActions at: (Sequence string: 'chicagoFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'chicagoFontMarcs') with: NULL).	
  	 menuActions at: (Sequence string: 'genivaFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'genivaFontMarcs') with: NULL).	
            menuActions at: (Sequence string: 'courierFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'courierFontMarcs') with: NULL).	
                                                                        
                 menuActions at: (Sequence string: 'size9Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size9Marcs') with: NULL).	
  	 menuActions at: (Sequence string: 'size10Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size10Marcs') with: NULL).	
            menuActions at: (Sequence string: 'size12Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size12Marcs') with: NULL).	
                                
                      menuActions at: (Sequence string: 'size14Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size14Marcs') with: NULL).	
  	 menuActions at: (Sequence string: 'boldStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'boldStyleMarcs') with: NULL).	
            menuActions at: (Sequence string: 'italicStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'italicStyleMarcs') with: NULL).	
        	 menuActions at: (Sequence string: 'underlineStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'underlineStyleMarcs') with: NULL).	
            menuActions at: (Sequence string: 'fontPanel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'fontPanel') with: NULL).	                                           
          	 menuActions at: (Sequence string: 'larger') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'larger') with: NULL).	
            menuActions at: (Sequence string: 'smaller') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'smaller') with: NULL).	                                           
              menuActions at: (Sequence string: 'heavier') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'heavier') with: NULL).	                                           
          	 menuActions at: (Sequence string: 'lighter') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'lighter') with: NULL).	
            menuActions at: (Sequence string: 'paragraphStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paragraphStyle') with: NULL).	                                           
            menuActions at: (Sequence string: 'fooDocumentStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'fooDocumentStyle') with: NULL).	                                           
          menuActions at: (Sequence string: 'paragraphStyles') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paragraphStyles') with: NULL).	                                           
          menuActions at: (Sequence string: 'printPanel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'printPanel') with: NULL).	                                           
                                                  
       menuActions at: (Sequence string: 'comparisonItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'comparisonItem') with: NULL).	                                           
      
          menuActions at: (Sequence string: 'Hide') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'Hide') with: NULL).	   
         menuActions at: (Sequence string: 'Quit') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'Quit') with: NULL).	                                           
       

	^ menuActions!

{ScruTable of: PackOBits and: Thunk} actionTableSaved
	| menuActions {MuTable of: PackOBits and: Thunk} |

	menuActions _ MuTable make: SequenceSpace make.
	menuActions at: (Sequence string: 'saveAs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'save as') with: NULL).
	menuActions at: (Sequence string: 'setDescription') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'set description') with: NULL).
	menuActions at: (Sequence string: 'linkMaker') introduce:
(LinkMakerThunk make).
	^ menuActions! !

!PassageBuilder methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<< 'mySelection = ' <<  mySelection! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PassageBuilder class
	instanceVariableNames: ''!

(PassageBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageBuilder class methodsFor: 'pseudo constructors'!

make: selection {SelectionRange}
	^self create: selection! !

!PassageBuilder class methodsFor: 'random'!

{MuTable of: ID and: Thunk} globalActionTable
	 ^ GlobalActionTable! !

!PassageBuilder class methodsFor: 'smalltalk: smalltalk init'!

cleanupGarbage
	GlobalActionTable _ NULL!

linkTimeNonInherited
	GlobalActionTable _ NULL! !Converter subclass: #PassageModel2Window
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(PassageModel2Window getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageModel2Window methodsFor: 'converting'!

{Heaper} convert: value {Heaper}
	^PassageWindowModel make: (value quickCast: PassageModel)!

create
	super create: PassageModel with: WindowModel! !

!PassageModel2Window methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
 oo<<  self getCategory name! !FMBuilder subclass: #PermissionsBuilder
	instanceVariableNames: 'myUserDirectory {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(PermissionsBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionsBuilder methodsFor: 'create'!

create: ud {UserDirectoryModel}

	super create.
	myUserDirectory _ ud! !

!PermissionsBuilder methodsFor: 'private: build'!

{FMScaffold} scaffold: pp {Pair}
 
	| scafTab {MuTable} |
	scafTab _ MuTable make: HeaperSpace make.
	scafTab at: (HeaperAsPosition make: UInt8Array) 
		introduce: (PermissionSelectBuilder make: pp with: myUserDirectory).
	scafTab at: (HeaperAsPosition make: ListModel)
		introduce: (FMListBuilder make: (BoundingListComp make: ListStyle defaultVertical)).
	^ FMScaffold make: scafTab with: Scaffold fluidGet! !

!PermissionsBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper} 

	| myListB {FMBuilding} |
	Scaffold fluidBind: (self scaffold: (obj cast: Pair)) during: [
		myListB _ Scaffold fluidGet build: myUserDirectory clubIDs].
	^ myListB! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PermissionsBuilder class
	instanceVariableNames: ''!

(PermissionsBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionsBuilder class methodsFor: 'make'!

make: onDir {UserDirectoryModel}

	^ self create: onDir! !FMBuilder subclass: #PermissionSelectBuilder
	instanceVariableNames: '
		myEditorsModel {PermissionsModel}
		myReadersModel {PermissionsModel}
		myUserDirectory {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(PermissionSelectBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class PermissionSelectBuilder */
friend SPTR(PermissionSelectBuilder)  permissionSelectBuilder (Pair OF1(PermissionsModel) * pp, UserDirectoryModel * ud);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionSelectBuilder methodsFor: 'private: creation'!

create: permPair {Pair} with: directory {UserDirectoryModel}

	super create.
	myEditorsModel _ permPair left cast: PermissionsModel.
	myReadersModel _ permPair right cast: PermissionsModel.
	myUserDirectory _ directory! !

!PermissionSelectBuilder methodsFor: 'private: building'!

{Pair of: FMBuilding} buildCheckPanes: id {ID}

	| editB {BooleanModel} readB {BooleanModel} 
	  editSel {BooleanModel} readSel {BooleanModel}
	  editP {Viewer} readP{Viewer} 
	  editC {FMController} readC {FMController} |
	  
	editB _ BooleanModel make: (myEditorsModel members hasMember: id).
	readB _ BooleanModel make: 
		((myEditorsModel members asImmuSet unionWith: myReadersModel members) hasMember: id).
	ModifyEditorsSchnert make: myEditorsModel with: editB with: id.
	ModifyReadersSchnert make: myReadersModel with: editB with: readB with: id.
	editSel _ BooleanModel make.
	readSel _ BooleanModel make.
	Editors2SelSchnert make: myEditorsModel 
						with: editB with: editSel 
						with: (myUserDirectory superClubsOf: id).
	editP _ self buildSelPane: editB with: editSel.
	Readers2SelSchnert make: myEditorsModel with: myReadersModel 
						with: readB with: readSel
						with: (myUserDirectory superClubsOf: id).
	readP _ self buildSelPane: readB with: readSel.
	editC _ self buildControl: editB with: readB with: editP with: true.
	readC _ self buildControl: readB with: editB with: readP with: false.
	^ Pair make: (FMBuilding make: editP with: editC)
			with: (FMBuilding make: readP with: readC)!

{FMController} buildControl: bool2toggle {BooleanModel} with: bool2Set {BooleanModel} with: vu {Viewer} with: tf {Boolean}

	| toggle {Thunk} tfthunk {Thunk} mt {Thunk} |
	toggle _ ToggleThunk make: bool2toggle.
	tf 
		ifTrue: [tfthunk _ TrueThunk make: bool2Set]
		ifFalse: [tfthunk _ FalseThunk make: bool2Set].
	mt _ MultiThunk make: (MuArray array: toggle with: tfthunk).
	^ SelectionGate make: vu with: (ClickAction make: mt)!

{Viewer} buildSelPane: imageB {BooleanModel} with: sel {BooleanModel}

	| imageM {VariableModel of: Image} vuPane {Viewer} 
	  hi {VariableModel of: Highlight} selPane {Viewer} |
	[FMResourceManager] USES.
	imageM _ VariableModel make.
	BoolM2ImageSchnert make: imageB with: imageM with: 
		(Pair make: (Resources fluidGet getImage: 'checkedBox') 
			  with: (Resources fluidGet getImage: 'box')).
	vuPane _ VariableImageViewer make: imageM.
	hi _ VariableModel make: HighlightAll make.
	selPane _ ItemSelectionViewer make: vuPane with: sel with: hi.
	^ selPane!

{FMBuilding} buildTextSide: ofClub {ID} with: selM {BooleanModel}
 
	| aHighM {VariableModel of: Highlight} aTextM {AttributedTextModel}
	 aTextV {Viewer} aHighV {Viewer} |
	 [Converter] USES.
	aHighM _ VariableModel make: HighlightAll make.
	aTextM _ (((myUserDirectory getName: ofClub) convert: MuWordArray) 
			convert: AttributedTextModel) cast: AttributedTextModel.
	aTextV _ (Scaffold fluidGet build: aTextM) view.
	aHighV _ ItemSelectionViewer make: aTextV with: selM with: aHighM.
	^ FMBuilding make: aHighV with: NULL!

{FMScaffold} scaffold 
	^FMScaffold
		make: AttributedTextModel
		with: (FMTextBuilder make: (ExtentLayout make: (PointPos make: 2000 with: 12)))
		with: Scaffold fluidGet! !

!PermissionSelectBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper} 

	| checkSide {Pair} editBldg {FMBuilding} readBldg {FMBuilding}
	  readVu {ItemSelectionViewer} readSelM {BooleanModel}
	  textSide {FMBuilding} vuz {ListModel} lmv {Viewer} cz {MuArray}
	  mc {FMController} |
	  [Converter] USES.
	Scaffold fluidBind: self scaffold during: [
	checkSide _ self buildCheckPanes: (obj basicCast: ID).
	editBldg _ checkSide left cast: FMBuilding.
	readBldg _ checkSide right cast: FMBuilding.
	readVu _ readBldg view cast: ItemSelectionViewer.
	readSelM _ readVu selectionModel.
	textSide _ self buildTextSide: (obj basicCast: ID) with: readSelM.
	vuz _ (MuArray array: editBldg view with: readVu with: textSide view) convert: ListModel.
	lmv _ ListMultiViewer make: vuz with: 
				(BoundingListComp make: ListStyle defaultHorizontal).
	cz _ MuArray array: editBldg controller with: readBldg controller.
	mc _ MultiController make: cz].
	^ FMBuilding make: lmv with: mc! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PermissionSelectBuilder class
	instanceVariableNames: ''!

(PermissionSelectBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class PermissionSelectBuilder */
friend SPTR(PermissionSelectBuilder)  permissionSelectBuilder (Pair OF1(PermissionsModel) * pp, UserDirectoryModel * ud);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionSelectBuilder class methodsFor: 'make'!

make: pp {Pair of: PermissionsModel} with: ud {UserDirectoryModel}

	^ self create: pp with: ud! !XnModel subclass: #Readers2SelSchnert
	instanceVariableNames: '
		myReadersModel {PermissionsModel}
		myEditorsModel {PermissionsModel}
		myReaderSelection {BooleanModel}
		myReadersList {ScruSet of: ID}
		mySelectionModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-permwin'!

(Readers2SelSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Readers2SelSchnert */
friend SPTR(Readers2SelSchnert)  readers2SelSchnert (
		PermissionsModel * edit, 
		PermissionsModel * read, 
		BooleanModel * checkB, 
		BooleanModel * selected, 
		ScruSet OF1(ID) * ids);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Readers2SelSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused} 
	self updateModel!

{void} updateModel
	| tmp {ScruSet} |
	tmp _ (myReadersModel members cast: ImmuSet) unionWith: 
		myEditorsModel members.
	mySelectionModel setValue: 
		(myReaderSelection getValue not and: [tmp intersects: myReadersList])! !

!Readers2SelSchnert methodsFor: 'private: create'!

create: editors {PermissionsModel} with: readers {PermissionsModel} with: readSel {BooleanModel} with: model {BooleanModel} with: clubList {ScruSet of: ID}

	super create.
	myEditorsModel _ editors.
	myEditorsModel addDependent: self.
	myReadersModel _ readers.
	myReadersModel addDependent: self.
	myReaderSelection _ readSel.
	myReadersList _ clubList.
	mySelectionModel _ model.
	self updateModel!

{void} destruct

	myEditorsModel removeDependent: self.
	myEditorsModel _ NULL.
	myReadersModel removeDependent: self.
	myReadersModel _ NULL.
	myReadersList _ NULL.
	mySelectionModel _ NULL.
	myReaderSelection _ NULL.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Readers2SelSchnert class
	instanceVariableNames: ''!

(Readers2SelSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class Readers2SelSchnert */
friend SPTR(Readers2SelSchnert)  readers2SelSchnert (
		PermissionsModel * edit, 
		PermissionsModel * read, 
		BooleanModel * checkB, 
		BooleanModel * selected, 
		ScruSet OF1(ID) * ids);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Readers2SelSchnert class methodsFor: 'make'!

make: edit {PermissionsModel} with: read {PermissionsModel} with: checkB {BooleanModel} with: selected {BooleanModel} with: ids {ScruSet of: ID}

	^ self create: edit with: read with: checkB with: selected with: ids! !Heaper subclass: #Reference
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
Reference comment:
'A reference appearing in the link pane of a Tapestry application. Coalesces them into some common protocol'!

(Reference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Reference methodsFor: 'accessing'!

{Waldo} descriptor
	"a descriptor for this reference"
	self subclassResponsibility!

{Pair of: ID and: Reference} follow: from {DocumentModel default: NULL} with: key {Position default: NULL}
	"take one of the follow choices and give the document and the area within the document"
	self subclassResponsibility!

{ScruTable of: MuWordArray} followChoiceNames
	"make up a table of choices for following this link"
	| result {MuTable of: MuWordArray} waldos {TableStepper} |
	result _ MuTable make: IDSpace make.
	(waldos _ self followChoices stepper) forEach: [ :waldo {Waldo} |
		waldo 
			cast: XuText into: [:xut |
				result at: waldos position
					introduce: (xut asDataTable: (IntegerRegion before: 20)) asMuTable]
			others: 
				[result at: waldos position
					introduce: (MuWordArray make.charVector: waldo getCategory name)]].
	^result!

{ScruTable of: Waldo} followChoices
	"make up a table of choices for following this link"
	self subclassResponsibility!

{BooleanVar} isAfterOrEqual: reference {Reference} with: document {DocumentModel}
	"define a full ordering according to position within the document"
	self subclassResponsibility!

{MuWordArray} kind
	"something describing the category of references this belongs to"
	self subclassResponsibility!

{Waldo} label
	"a read-only waldo describing this reference"
	self subclassResponsibility!

{XnRegion} regionIn: document {DocumentModel}
	"the region referred to in the contents of the model"
	self subclassResponsibility! !

!Reference methodsFor: 'smalltalk: defaults'!

follow
	^self follow: NULL with: NULL!

follow: from
	^self follow: from with: NULL! !

!Reference methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo<< self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Reference class
	instanceVariableNames: ''!

(Reference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Reference class methodsFor: 'pseudo constructors'!

{ScruSet of: Reference} linkReferences: link {XuLink} with: document {DocumentModel}
	"make a set of references matching the ways in which the link attaches to the document"
	| endsets {TableStepper} result {MuSet of: Reference} |
	result _ MuSet make.
	(endsets _ link endsets asTable stepper) forEach: [ :endset {LinkEndSet} |
		(self endset: endset refersTo: document) ifTrue:
			[result store: (LinkReference make: link with: (endsets position cast: ID))]].
	^result!

{ScruSet of: Reference} variantReferences: waldo {Waldo}
	"make a set of references for all the different documents on the given waldo"
	| result {MuSet of: Reference} |
	result _ MuSet make.
	waldo getDuplicates stepper forEach:
		[ :bert {ID} | | variant {DocumentModel} |
		variant _ Application fluidGet fetchDocument: bert.
		variant ~~ NULL ifTrue:
			[result store: (VariantReference make: variant)]].
	^result! !

!Reference class methodsFor: 'private: private functions'!

{BooleanVar} endset: endset {LinkEndSet} refersTo: document {DocumentModel}
	"whether any end in the endset refers to the document"
	endset linkEnds stepper forEach:
		[ :end {LinkEnd} |
		| doc {ID} endContext {IndexedWaldo} |
		(((doc := end fetchDocumentContext) ~~ NULL
				and: [doc isEqual: document iD])
			or: [(endContext _ end fetchEndContext cast: IndexedWaldo) ~~ NULL
				and: [(endContext
					sharedWith: (document contentsWaldo cast: IndexedWaldo)) isEmpty not]])
			ifTrue: [^true]].
	^false! !Reference subclass: #LinkReference
	instanceVariableNames: '
		myLink {XuLink}
		myEndsetID {ID}'
	classVariableNames: 'LinkKind {MuWordArray} '
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
LinkReference comment:
'A reference in one endset of a link'!

(LinkReference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkReference methodsFor: 'private: private'!

{ImmuSet of: LinkEnd} ends
	^self endset linkEnds!

{LinkEndSet} endset
	^(myLink endsets get: myEndsetID) cast: LinkEndSet!

{XuLink} link
	^myLink!

{BooleanVar} privateAfterOrEqual: other {LinkReference}
	"do a bottom-level comparision when all else fails"
	self unimplemented "isAfterOrEqual passe"
	"^(self link iD isAfterOrEqual: other link iD)
		or: [(self link iD isEqual: other link iD)
			and: [self endsetID isAfterOrEqual: other endsetID]]"! !

!LinkReference methodsFor: 'accessing'!

{Waldo} descriptor
	"a descriptor for this reference"
	^self endset getDescriptor!

{ID} endsetID
	^myEndsetID!

{Pair of: ID and: Reference} follow: from {DocumentModel unused default: NULL} with: key {Position default: NULL}
	"take one of the follow choices and give the document and the area within the document"
	| id {ID} end {LinkEnd} |
	key == NULL
		ifTrue: [self hack  "id _ (self link endsets domain minus: (IDRegion make: self endsetID)) stepper get cast: ID"]
		ifFalse: [id _ key cast: ID].
	self hack. "should really look at all the ends in an endset"
	end _ ((self link endsets get: id) cast: LinkEndSet) linkEnds stepper get cast: LinkEnd.
	^Pair make: end getDocumentContext with: (LinkReference make: self link with: id)!

{ScruTable of: Waldo} followChoices
	"make up a table of choices for following this link"
	| result {MuTable of: Waldo} endsets {TableStepper} |
	self hack. "should really look at all the ends in an endset"
	result _ MuTable make: IDSpace make.
	(endsets _ self link endsets asTable stepper) forEach: [ :endset {LinkEndSet} |
		(endsets position isEqual: self endsetID) ifFalse:
			[result at: endsets position introduce: endset getDescriptor]].
	^result!

{BooleanVar} isAfterOrEqual: reference {Reference} with: document {DocumentModel}
	"define a full ordering according to position within the document"
	
	reference 
		cast: LinkReference into: [:other |
			| compare {Int32} |
			(self refersToEntire: document) ifTrue:
				[^(other refersToEntire: document) and: [self privateAfterOrEqual: other]].
			(other refersToEntire: document) ifTrue:
				[^true].
			compare _ document compare: (self regionIn: document) with: (other regionIn: document).
			compare == Int32Zero
				ifTrue: [^self privateAfterOrEqual: other]
				ifFalse: [^compare > Int32Zero]]
		others: [^true]!

{MuWordArray} kind
	"something describing the category of references this belongs to"
	^LinkKind!

{Waldo} label
	"a read-only waldo describing this reference"
	^((LinkTypeDescription defaultDescription: self link keyMaster
			with: self link linkType)
		labels get: self endsetID) cast: Waldo!

{ID} linkID
	^myLink iD!

{BooleanVar} refersToEntire: document {DocumentModel}
	"whether this refers to the entire document as such, or to pieces of it"
	self ends stepper forEach: [ :end {LinkEnd} |
		(end fetchDocumentContext ~~ NULL
				and: [(end getDocumentContext isEqual: document iD)
				and: [end fetchEndContext == NULL
				and: [end fetchPathContext == NULL]]])
			ifTrue: [^true]].
	^false!

{XnRegion} regionIn: document {DocumentModel}
	"the region occupied by my endset in the contents of the model"
	| result {XnRegion} |
	result _ (document contentsWaldo cast: IndexedWaldo) coordinateSpace emptyRegion.
	self ends stepper forEach: [ :end {LinkEnd} | | context {IndexedWaldo} |
		(context _ end fetchEndContext cast: IndexedWaldo) ~~ NULL ifTrue:
			[result _ result unionWith: ((document contentsWaldo cast: IndexedWaldo) sharedWith: context)]].
	^result! !

!LinkReference methodsFor: 'testing'!

{UInt32} hashForEqual
	^self link iD hashForEqual bitXor: self endset hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: LinkReference into: [:lr |
			^(lr linkID isEqual: self linkID)
			 and: [lr endsetID isEqual: self endsetID]]
		others: [^false]! !

!LinkReference methodsFor: 'create'!

create: link {XuLink} with: endset {ID}
	super create.
	myLink _ link.
	myEndsetID _ endset! !

!LinkReference methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
  oo <<  self getCategory name

 << 'myLink = ' << myLink  
		<< 'myEndset = ' << myEndsetID! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkReference class
	instanceVariableNames: ''!

(LinkReference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkReference class methodsFor: 'pseudo constructors'!

make: link {XuLink} with: endset {ID}
	^self create: link with: endset! !

!LinkReference class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: MuWordArray.
	LinkKind _ MuWordArray make.charVector: 'Link'!

linkTimeNonInherited
	LinkKind _ NULL! !

!LinkReference class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage

	self linkTimeNonInherited! !Reference subclass: #VariantReference
	instanceVariableNames: 'myDocument {DocumentModel}'
	classVariableNames: 'VariantKind {MuWordArray} '
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(VariantReference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariantReference methodsFor: 'create'!

create: doc {DocumentModel}
	super create.
	myDocument _ doc! !

!VariantReference methodsFor: 'testing'!

{UInt32} hashForEqual
	^myDocument hashForEqual bitXor: 12489673!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: VariantReference into: [:vr |
			^myDocument isEqual: vr document]
		others: [^false]! !

!VariantReference methodsFor: 'private: private'!

{DocumentModel} document
	^myDocument!

{BooleanVar} privateAfterOrEqual: other {VariantReference}
	"do a bottom-level comparision when all else fails"
	self unimplemented "isAfterOrEqual passe"
	"^self document iD isAfterOrEqual: other document iD"! !

!VariantReference methodsFor: 'accessing'!

{Waldo} descriptor
	"a descriptor for this reference"
	^myDocument name!

{Pair of: ID and: Reference} follow: from {DocumentModel default: NULL} with: key {Position default: NULL}
	"take one of the follow choices and give the document and the area within the document"
	from == NULL
		ifTrue: [^Pair make: myDocument iD with: self]
		ifFalse: [^Pair make: myDocument iD with: (VariantReference make: from)]!

{ScruTable of: Waldo} followChoices
	"make up a table of choices for following this link"
	^MuArray array: self descriptor!

{BooleanVar} isAfterOrEqual: reference {Reference} with: document {DocumentModel}
	"define a full ordering according to position within the document"
	
	reference 
		cast: VariantReference into: [:other |
			| compare {Int32} |
			compare _ document compare: (self regionIn: document) with: (other regionIn: document).
			compare == Int32Zero
				ifTrue: [^self privateAfterOrEqual: other]
				ifFalse: [^compare > Int32Zero]]
		others: [^false]!

{MuWordArray} kind
	"something describing the category of references this belongs to"
	^VariantKind!

{Waldo} label
	"a read-only waldo describing this reference"
	self hack. "This should be cleaner"
	[TapestryAppModel, UserModel, PermissionsModel] USES.
	^XuText make: Application fluidGet user keyMaster
		with.XuWordArray: (self document fetchEditPermissions clubName convert: MuWordArray)!

{XnRegion} regionIn: document {DocumentModel}
	"the region occupied by my endset in the contents of the model"
	^(document contentsWaldo cast: IndexedWaldo)
		sharedWith: (self document contentsWaldo cast: IndexedWaldo)! !

!VariantReference methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

oo<<  self getCategory name<< 'myDocument = ' << myDocument! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VariantReference class
	instanceVariableNames: ''!

(VariantReference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariantReference class methodsFor: 'pseudo constructors'!

make: doc {DocumentModel}
	^self create: doc! !

!VariantReference class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: MuWordArray.
	VariantKind _ MuWordArray make.charVector: 'Variant'!

linkTimeNonInherited
	VariantKind _ NULL! !

!VariantReference class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage
	
	self linkTimeNonInherited! !Converter subclass: #ReferenceFilter2Tapestry
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-filters'!

(ReferenceFilter2Tapestry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ReferenceFilter2Tapestry methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	| filter {ReferenceFilter} |
	filter _ value basicCast: ReferenceFilter.
	(filter workType isEqual: (Sequence string: 'LinkFilter')) ifTrue:
		[^TapestryLinkFilter create: filter]
	ifFalse: [(filter workType isEqual: (Sequence string: 'VariantFilter')) ifTrue:
		[^TapestryVariantFilter create: filter]
	ifFalse:
		[Heaper BLAST: #CantConvert]]!

create
	"super create: ReferenceFilter with: TapestryFilter"! !FMBuilder subclass: #ReferenceListBuilder
	instanceVariableNames: 'myWindow {DocumentWindowModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
ReferenceListBuilder comment:
'Builds a vertical list of reference views, along with a DoubleClickAction to follow links and a MultiSelectionController to select them

	mySelection {SelectionObject}
		The selection model for selecting the references'!

(ReferenceListBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ReferenceListBuilder methodsFor: 'build'!

{FMBuilding} build: model {Heaper as: (ListModel of: Reference)} 
	"build a link pane view for a text doc."
 
	| viewers {TableAccumulator of: Viewer} viewer {ListMultiViewer} controller {FMController} multi {MultiController} viewList {ListModel of: Viewer} listD {FMListDirector} |
	viewers _ MuArray arrayAccumulator.
	(model cast: ListModel) asTable stepper forEach: [:ref {Reference} |
		viewers step: (Scaffold fluidGet build: ref) view].
	viewer _ ListMultiViewer make: (viewList _ ListModel make: (viewers value cast: IntegerTable))
							  with: (BoundingListComp make: ListStyle defaultVertical).
	controller _
		SelectionGate make: viewer
					   with: (multi _ MultiController make:
					   		  (MuArray array: (MultiSelectionController make: viewer
					   		  											with: myWindow referencesSelection)
										with: (DoubleClickAction make: (FollowThunk make: myWindow)))).
	controller _ MultiController make: (MuArray array: controller
												with: (FMHighLevelAction make: (UInt8Array string: 'MENU')
																		  with: self actionTable)).
	listD _ FMListDirector
				make: (model basicCast: ListModel)
				with: viewList
				with: multi.
	^FMDirectorBuilding
		make: (MultiSelectionViewer
				make: viewer
				with: myWindow referencesSelection
				with: (VariableModel make: HighlightAll make))
		with: controller
		with: listD! !

!ReferenceListBuilder methodsFor: 'create'!

create: window {DocumentWindowModel}
	super create.
	myWindow _ window! !

!ReferenceListBuilder methodsFor: 'private: structures'!

{ScruTable of: PackOBits and: Thunk} actionTable
	| menuActions {MuTable of: PackOBits and: Thunk} "tThunk
{Thunk}" theVarModel {VariableModel of: FMBuilder} |

	menuActions _ MuTable make: SequenceSpace make.
	theVarModel _ (myWindow referenceBuilder cast:
FMDeferredBuilder) builderModel.
	menuActions at: (Sequence string: 'twoLineFormat') introduce: 
		(AssignmentThunk make: theVarModel with:
TwoLineReferenceBuilder make).
	menuActions at: (Sequence string: 'fullLinkFormat') introduce:
		(AssignmentThunk make: theVarModel with:
FullReferenceBuilder make).
	menuActions at: (Sequence string: 'shortLinkFormat') introduce:
		(AssignmentThunk make: theVarModel with:
ShortReferenceBuilder make).
	menuActions at: (Sequence string: 'readerLinkFormat') introduce: 
		(AssignmentThunk make: theVarModel with:
TwoLineReferenceBuilder make).
	^ menuActions
	
	"menuActions at: (PackOBits make: #twoLineFormat) introduce: 
		(MultiThunk make: 
			(XuArray array: (tThunk _ AssignmentThunk make:
theVarModel with: TwoLineReferenceBuilder make)
						with: (TranscriptThunk make: 'setting format to '
with: tThunk))).
	menuActions at: (PackOBits make: #fullLinkFormat) introduce:
		(MultiThunk make: 
			(XuArray array: (tThunk _ AssignmentThunk make:
theVarModel with: FullReferenceBuilder make)
						with: (TranscriptThunk make: 'setting format to '
with: tThunk))).
	menuActions at: (PackOBits make: #shortLinkFormat) introduce:
		(MultiThunk make: 
			(XuArray array: (tThunk _ AssignmentThunk make:
theVarModel with: ShortReferenceBuilder make)
						with: (TranscriptThunk make: 'setting format to '
with: tThunk))).
	menuActions at: (PackOBits make: #readerLinkFormat) introduce: 
		(MultiThunk make: 
			(XuArray array: (tThunk _ AssignmentThunk make:
theVarModel with: TwoLineReferenceBuilder make)
						with: (TranscriptThunk make: 'setting format to '
with: tThunk)))."! !

!ReferenceListBuilder methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<< 'myWindow = '  << myWindow! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReferenceListBuilder class
	instanceVariableNames: ''!

(ReferenceListBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ReferenceListBuilder class methodsFor: 'make'!

make: window {DocumentWindowModel}
	^self create: window! !SorterSchnert subclass: #ReferenceSorter
	instanceVariableNames: 'myDocument {DocumentModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
ReferenceSorter comment:
'Sorts references according to the beginning of the material they refer to in a document'!

(ReferenceSorter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ReferenceSorter methodsFor: 'protected: protected comparing'!

{BooleanVar} isAfterOrEqual: one {Heaper} with: other {Heaper}
	"defines a full ordering"
	"those referring to the entire document come first,
	then those with no reference and then by order within the document"
	^(one quickCast: Reference) isAfterOrEqual: (other quickCast: Reference) with: myDocument! !

!ReferenceSorter methodsFor: 'create'!

create: set {SetModel of: Reference} with: list {ListModel of: Reference} with: document {DocumentModel}
	super create: set with: list.
	myDocument _ document.
	self reSort! !

!ReferenceSorter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
oo<<  self getCategory name << 'myDocument = ' << myDocument! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReferenceSorter class
	instanceVariableNames: ''!

(ReferenceSorter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ReferenceSorter class methodsFor: 'make'!

make: set {SetModel of: Reference} with: list {ListModel of: Reference} with: document {DocumentModel}
	^self create: set with: list with: document! !XnDependent subclass: #Refs2DocSelectionSchnert
	instanceVariableNames: 'myWindow {DocumentWindowModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
Refs2DocSelectionSchnert comment:
'When the referencesSelection changes, changes the documentSelection to the referenced material'!

(Refs2DocSelectionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Refs2DocSelectionSchnert methodsFor: 'create'!

create: window {DocumentWindowModel}
	super create.
	myWindow _ window.
	myWindow referencesSelection addDependent: self!

{void} destruct

	myWindow referencesSelection removeDependent: self.
	super destruct! !

!Refs2DocSelectionSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model
{XnModel} 
	(myWindow referencesSelection basicCast: XnModel) ==
model 
		ifTrue: [self updateSelection]! !

!Refs2DocSelectionSchnert methodsFor: 'private: private'!

{void} updateSelection
	| result {XnRegion} |
	result _ myWindow documentSelection selection coordinateSpace emptyRegion.
	myWindow referencesSelection selection stepper forEach: [ :i {IntegerPos} |
		result _ result unionWith: (((myWindow references get: i asIntegerVar) cast: Reference)
			regionIn: myWindow document)].
	myWindow documentSelection select: result! !

!Refs2DocSelectionSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
	<< 'myWindow = '  << myWindow  << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Refs2DocSelectionSchnert class
	instanceVariableNames: ''!

(Refs2DocSelectionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Refs2DocSelectionSchnert class methodsFor: 'pseudo constructors'!

make: window {DocumentWindowModel}
	^self create: window! !XnModel subclass: #ScrollerSchnert
	instanceVariableNames: '
		myViewer {Viewer}
		myExtent {VariableModel of: PointPos}
		myOffset {VariableModel of: PointPos}
		myVisible {VariableModel of: XnRegion}
		myDesired {VariableModel of: XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
ScrollerSchnert comment:
'This schnert manages the scrolling of a window referring to data that is organized by some coordinate space.

		myViewer {Viewer}
			The FM Viewer displaying the information
		myExtent {VariableModel of: XuPoint}
			The size of the window
			Typically set from information supplied by the window system
		myOffset {VariableModel of: XuPoint}
			The offset from the origin at which the window is shown
			Typically set by the scroll bar
		myVisible {VariableModel of: XuRegion}
			The region of the model that is actually visible in the window
			Set by the ScrollerSchnert after a change in offset or extent
		myDesired {VariableModel of: XuRegion}
			A change in this causes the scroller to try and make this area
			visible in the window by changing the offset, causing the visible
			region to be updated as well'!

(ScrollerSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ScrollerSchnert */
friend SPTR(ScrollerSchnert) scrollerSchnert (Viewer * view);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ScrollerSchnert methodsFor: 'accessing'!

{VariableModel of: XnRegion} desired
	^myDesired!

{VariableModel of: PointPos} extent
	^myExtent!

{VariableModel of: PointPos} offset
	^myOffset!

{Viewer} viewer
	^myViewer!

{VariableModel of: XnRegion} visible
	^myVisible! !

!ScrollerSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model
{XnModel} 
	"update my models according to what has changed"

	model == (myDesired basicCast: XnModel)
		ifTrue: [self updateOffset]
		ifFalse: [(model == (myOffset basicCast: XnModel) 
					or: [model == (myExtent basicCast: XnModel)])
				ifTrue: [self updateVisible]]! !

!ScrollerSchnert methodsFor: 'private: updating'!

{void} updateOffset
	myOffset setValue: (myViewer offsetFor: (myDesired getValue cast: XnRegion))!

{void} updateVisible
	myVisible setValue: (myViewer
		selectionIn: (PointRegion
			regionExtent: (myOffset getValue cast: PointPos)
			with: (myExtent getValue cast: PointPos)))! !

!ScrollerSchnert methodsFor: 'private: creation'!

create: view {Viewer}
	super create.
	myViewer _ view.
	myExtent _ VariableModel make: PointPos make.
	myOffset _ VariableModel make: PointPos make.
	myVisible _ VariableModel make.
	myDesired _ VariableModel make.
	
	myExtent addDependent: self.
	myOffset addDependent: self.
	myDesired addDependent: self!

{void} destruct

	myExtent removeDependent: self.
	myOffset removeDependent: self.
	myDesired removeDependent: self.
	myExtent destroy.
	myVisible destroy.
	myOffset destroy.
	myDesired destroy.
	myViewer _ NULL.
	myExtent _ NULL.
	myOffset _ NULL.
	myVisible _ NULL.
	myDesired _ NULL.
	super destruct! !

!ScrollerSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
	      << 'myViewer'  << myViewer 
		<< 'myExtent' << myExtent  
		<< 'myOffset'  << myOffset
		<< 'myVisible'  << myVisible
		<< 'myDesired' << myDesired << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScrollerSchnert class
	instanceVariableNames: ''!

(ScrollerSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ScrollerSchnert */
friend SPTR(ScrollerSchnert) scrollerSchnert (Viewer * view);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ScrollerSchnert class methodsFor: 'make'!

make: view {Viewer.X}
	^self create: view! !FMBuilder subclass: #ShortReferenceBuilder
	instanceVariableNames: ''
	classVariableNames: 'ReferencePortions {ListModel of: Portion} '
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
ShortReferenceBuilder comment:
'Builds a view onto a reference.
*Eventually, will be a director that has a model describing the format of the view'!

(ShortReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class ShortReferenceBuilder */
friend SPTR(ShortReferenceBuilder)  shortReferenceBuilder
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ShortReferenceBuilder methodsFor: 'build'!

{FMBuilding} build: something {Heaper as: Reference} 
	| reference {Reference} kind {FMBuilding} label {FMBuilding} descriptor {FMBuilding}
	  style {ListStyle} txtBuilder {FMTextBuilder} | 
	reference _ something cast: Reference.
	txtBuilder _ FMTextBuilder make: (ExtentLayout make: (PointPos make: 2000 with: 12)).
	Scaffold fluidBind: (FMScaffold
			make: AttributedTextModel
			with: txtBuilder
			with: Scaffold fluidGet)
		during: 
			[kind _ Scaffold fluidGet build: reference kind.
			label _ Scaffold fluidGet build: reference label.
			descriptor _ Scaffold fluidGet build: reference descriptor].
	style _ ListStyle defaultHorizontal.
	style setSpacing: 4.
	^FMBuilding make: (ListMultiViewer make: (ListModel make: (MuArray
					array: kind view
					with: label view
					with: descriptor view))
			with: (PortionListComp make: style with: ReferencePortions))
		with: NULL! !

!ShortReferenceBuilder methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<< 'ReferencePortions = ' << ReferencePortions! !

!ShortReferenceBuilder methodsFor: 'private: creation'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShortReferenceBuilder class
	instanceVariableNames: ''!

(ShortReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class ShortReferenceBuilder */
friend SPTR(ShortReferenceBuilder)  shortReferenceBuilder
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ShortReferenceBuilder class methodsFor: 'smalltalk: initialization'!

cleanupGarbage

	self linkTimeNonInherited!

initTimeNonInherited
	self REQUIRES: IntegerRegion.
	self REQUIRES: MuArray.
	self REQUIRES: ListModel.
	self REQUIRES: Portion.
	ReferencePortions _ ListModel make: (MuArray
		array: (Portion make: (IntegerRegion after: 12) with: 0.25)
		with: (Portion make: (IntegerRegion after: 12) with: 0.3)
		with: (Portion make: (IntegerRegion after: 12) with: 0.45))!

linkTimeNonInherited
	ReferencePortions _ NULL! !

!ShortReferenceBuilder class methodsFor: 'make'!

make
	^self create! !XnModel subclass: #TableTopModel
	instanceVariableNames: '
		myHome {WaldoModel of: IndexedWaldo}
		myTrailingWindowCount {VariableModel of: IntegerPos}
		myWindows {IntegerTable of: WindowModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
TableTopModel comment:
'Manages a table top of windows, keeping track of the layering, size, and position.
Maintains a specific number of trailing windows

		myHome {HomeDocumentModel}
			The home document that contains the user''s last table top.
			*Eventually update this as the windows move and change, and
			use it to set up from.
		myTrailingWindowCount {VariableModel of: XuInteger}
			The number of unpinned windows to leave behind the top one.
		myWindows {MuTable of: WindowModel}
			An ordered list of windows, from front to back'!

(TableTopModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TableTopModel methodsFor: 'create'!

create: home {HomeDocumentModel}
	super create.
	myHome _ home.
	myHome addDependent: self.
	myTrailingWindowCount _ VariableModel make: Integer0.
	myTrailingWindowCount addDependent: self.
	myWindows _ IntegerTable make!

{void} destruct

	myHome removeDependent: self.
	"n.b. this is after removeDependent so home document is NOT updated as we close these windows."
	myWindows stepper forEach: [:win {WindowModel} |
		win close].
	myTrailingWindowCount removeDependent: self.
	myTrailingWindowCount destroy.
	myHome _ NULL.
	myTrailingWindowCount _ NULL.
	myWindows destroy.
	super destruct! !

!TableTopModel methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel} 
	"change pin status or window open/close/front"

	| wins {TableStepper} |
	[BooleanModel] USES.
	model == (self trailingWindowCount basicCast: XnModel) 
		ifTrue: [self closeTrailingWindows.
			^VOID].
	(wins _ myWindows stepper) forEach: [:win {WindowModel} |
		model == (win basicCast: XnModel)
			ifTrue: [(change isKindOf: WindowCloseUpdate)
					ifTrue: [self deleteWindow: wins index]
					ifFalse: [(change isKindOf: WindowFrontUpdate)
							ifTrue: [self deleteWindow: wins index.
								self insertWindow: win with: IntegerVar0]].
				^VOID]
			ifFalse: [model == (win pinStatus basicCast: XnModel) 
				ifTrue: [self closeTrailingWindows.
					^VOID]]]! !

!TableTopModel methodsFor: 'accessing'!

{void} addWindow: window {WindowModel}
	"add a window to the table top and open it"
	self insertWindow: window with: IntegerVar0.
	window addDependent: self.
	window pinStatus addDependent: self.
	window pinStatus getValue ifFalse:
		[self closeTrailingWindows]!

{void} openSaved
	"This method is used to recall the documents (and their windows) 
	from the last session and reopen them at their old positions (if 
	possible)."


	| doc1 {XuText} doc2 {XuText} docid {ID} lt {ID} km {KeyMaster} |
	[TapestryAppModel, UserModel,ListModel] USES.
	self hack. "since we are not storing anything yet. create a sample document"
	[Transcript nextPutAll: 'building test document'; cr; endEntry] smalltalkOnly.
	km _ Application fluidGet user keyMaster.
	doc1 _ (km makePersistentWaldo: (Sequence string: 'XuText')) cast: XuText.
	doc1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'This was an old man. Not an incredibly old man; obsolete, spavined; not as worn as the sway-backed stone steps ascending the Pyramid of the Sun to an ancient temple; not yet a relic. But even so, a very old man, this old man perched on an antique shooting stick, its handles open to form a seat, its spike thrust at an angle into the soft ground and trimmed grass of the cemetery.').
	doc2 _ (km makePersistentWaldo: (Sequence string: 'XuText')) cast: XuText.
	doc2 insert: IntegerVar0 with: (MuWordArray  make.charVector:
		'I saw a young man ').
	doc2 vcopy: doc2 count with: doc1 with: (IntegerRegion make: 111 with: 164).
	doc2 insert: doc2 count with: (MuWordArray make.charVector:
		'. He looked back wistfully at ').
	doc2 vcopy: doc2 count with: doc1 with: (IntegerRegion make: 330 with: 363).
	doc2 insert: doc2 count with: (MuWordArray make.charVector:
		' behind him, but continued on with resignation.').
	"lt _ (Application fluidVar user linkTypes fetch: IntegerVar0) cast: ID.
	((XuLink make: km
		with: (ImmuSet make with: 
			(LinkEnd make: km with: (IntegerRegion make: 8 with: 17) with: doc2))
		with: (XuText make: km with: 'youth')
		with: (ImmuSet make with: 
			(LinkEnd make: km with: (IntegerRegion make: 12 with: 19) with: doc1))
		with: (XuText make: km with: 'age')
		with: lt) copy: true) destroy."
	docid _ doc1 getID.
	doc1 destroy.
	doc2 destroy.
	[Transcript nextPutAll: 'onward!!'; cr; endEntry] smalltalkOnly.
	Application fluidVar openWindow: (Application fluidVar getDocument: docid)!

{VariableModel of: IntegerPos} trailingWindowCount
	"the number of windows kept behind the current one (pinned ones excluded)"
	^myTrailingWindowCount!

{ListModel of: WindowModel} windows

	^ ListModel make: myWindows! !

!TableTopModel methodsFor: 'private: private'!

{void} closeTrailingWindows
	"close any trailing windows"
	| limit {IntegerVar} count {IntegerVar} index {IntegerVar} closed {MuSet of: WindowModel} |
	limit _ (self trailingWindowCount getValue cast: IntegerPos) asIntegerVar + 1.
	limit == IntegerVar0 ifTrue: [^VOID].
	count _ index _ IntegerVar0.
	[index < myWindows count and: [count < limit]] whileTrue:
		[(self windowAt: index) pinStatus getValue
			ifTrue: [count _ count + 1].
		index _ index + 1].
	"save the windows to be closed into a set
	 because they will vanish out of the array as they get closed"
	closed _ MuSet make.
	[index < myWindows count] whileTrue:
		[(self windowAt: index) pinStatus getValue ifFalse:
			[closed store: (self windowAt: index)].
		index _ index + 1].
	closed stepper forEach: [ :window {WindowModel} |
		window close]!

{void} deleteWindow: key {IntegerVar}
	key + 1 almostTo: myWindows count do: [ :i {IntegerVar} |
		myWindows atInt: i - 1 store: (myWindows intGet: i)].
	myWindows intWipe: myWindows count - 1!

{void} insertWindow: window {WindowModel} with: key {IntegerVar}
	myWindows count to: key + 1 by: -1 do: [ :i {IntegerVar} |
		myWindows atInt: i store: (myWindows intGet: i - 1)].
	myWindows atInt: key store: window!

{WindowModel} windowAt: index {IntegerVar}
	^(myWindows intGet: index) cast: WindowModel! !

!TableTopModel methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '
	myHome: ' << myHome << '
	myTrailingWindowCount: ' << myTrailingWindowCount << '
	myWindows: ' << myWindows! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TableTopModel class
	instanceVariableNames: ''!

(TableTopModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TableTopModel class methodsFor: 'pseudo constructors'!

make: home {HomeDocumentModel}
	^self create: home! !XnModel subclass: #TapestryAppModel
	instanceVariableNames: '
		myPublicDirectory {UserDirectoryModel}
		myKeyMaster {KeyMaster}
		myUser {UserModel}
		myLinkEnds {LinkEndsModel}
		myDocuments {MuTable of: PackOBits and: DocumentModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
TapestryAppModel comment:
'The central model for an active application
Maintains a list of active document models to avoid duplication or grab failure
Kept in the fluid "Application"

		myUser {UserModel}
			The user model
		myLinkEnds {LinkEndsModel}
			A list of link ends
		myDocuments {MuTable of: ID and: DocumentModel}
			A mapping from bert IDs to active document models'!

(TapestryAppModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TapestryAppModel methodsFor: 'accessing'!

{DocumentModel} fetchDocument: id {ID}
	"get the model for the given ID; return existing model if there is one"

	| waldo {Waldo} result {DocumentModel} |
	(self documents includesKey: id)
		ifTrue: [^(self documents get: id) cast: DocumentModel].
	KeyMaster problems.OpenFailed
		handle: [ :boom | ^NULL]
		do: [waldo := self user keyMaster open: id].
	(Converter fetchConverter: waldo getCategory with: DocumentModel) == NULL 
		ifTrue: [waldo destroy. ^NULL].
	result := waldo convert: DocumentModel.
	self documents at: waldo getID introduce: result.
	^result!

{DocumentModel} getDocument: id {ID}
	"get the model for the given ID; return existing model if there is one"

	| result {DocumentModel} |
	result _ self fetchDocument: id.
	result == NULL
		ifTrue: [Heaper BLAST: #CouldNotGetDocument].
	^result!

{LinkEndsModel} linkEnds
	"the link end document model"
	^myLinkEnds!

{UserDirectoryModel} publicDirectory
	^ myPublicDirectory!

{UserModel} user
	(myUser == NULL) ifTrue: [Heaper BLAST: #NotLoggedIn. ^ NULL].
	^myUser! !

!TapestryAppModel methodsFor: 'operations'!

{void} createLink: left {LinkEnd} with: right {LinkEnd} with: type {ID} with: permissions {ID}
	"create a new link"
	self hack. "permissions ignored"
	((XuLink make: self keyMaster
		with: (ImmuSet make with: left)
		with: (self computeDescriptor: left
			with: XuLink leftID
			with: type)
		with: (ImmuSet make with: right)
		with: (self computeDescriptor: right
			with: XuLink rightID
			with: type)
		with: type) copy: true) destroy!

{OutlineModel} createOutline: permissions {ID unused}
	"create a new, empty outline"
	self unimplemented.
	^NULL!

{PassageModel} createPassage: permissions {ID unused}
	"create a new, empty passage"
	self hack. "ignoring permissions"
	^(self getDocument: (self user keyMaster
		makeEmptyWaldo: (Sequence string: 'XuText')  with: NULL with: true)
			editionID) cast: PassageModel!

{PassageModel} createPassage: editors {ScruSet default: NULL} with: readers {ScruSet default: NULL} 
	"create a new, empty passage"

	^(self createDocModel: (Sequence string: 'XuText')
		with: editors
		with: readers)
		cast: PassageModel!

{void} openWindow: model {Heaper}
	"open a window on some kind of model "
	(model convert: WindowModel) open!

{void} openWindowAt: model {Heaper} with: initial {XnRegion}
	"open a window on some kind of model with an initial selection "
	| window {WindowModel} |
	"MessageTally mySpy: ["
		window _ model convert: WindowModel.
		window
			cast: DocumentWindowModel into: [:dwm |
				[SelectionObject, SelectionRange] USES.
				dwm documentSelection select: initial]
			others: []"]".
	window open! !

!TapestryAppModel methodsFor: 'protections'!

{void} login
	"This method presents a login window to the user to allow them to 
	select an id and provide authentication."

	| kmVar {VariableModel of: KeyMaster} loginWindow {WindowModel} |
	kmVar _ VariableModel make: NULL.
	LoginSchnert make: kmVar with: self.
	loginWindow _ LoginWindowModel
				make: self keyMaster
				with: kmVar
				with: myPublicDirectory.
	[loginWindow open] translateOnly.
	[[loginWindow open] fork] smalltalkOnly!

{void} setKeyMaster: newKM {KeyMaster} 
	"This method is used to change the keymaster, and therefore the 
	current user of the application."
	[TableTopModel] USES.
	
	"First, cleanup any old login stuff."
	myUser == NULL ifFalse: [myUser destroy].
	myLinkEnds destroy.
	myDocuments stepper forEach: [:doc {DocumentModel} | doc destroy].
	myDocuments _ MuTable make: FeServer current globalIDSpace.
	myKeyMaster destroy.
	myKeyMaster _ newKM combine: XuServer currentServer publicKeyMaster.
	"do the new login stuff"
	myUser _ UserModel make: myKeyMaster.
	myLinkEnds _ LinkEndsModel make.
	myUser tableTop openSaved! !

!TapestryAppModel methodsFor: 'private: private'!

{XuText} computeDescriptor: end {LinkEnd} with: which {ID} with: type {ID}
	"compute a simple descriptor from the contents"
	| result {XuText} context {XuText} typeDoc {LinkTypeDescription} |
	typeDoc _ LinkTypeDescription
		defaultDescription: self user keyMaster
		with: type.
	result _ ((typeDoc labels get: which) cast: Waldo) copy cast: XuText.
	result insert: result count with: (MuWordArray make.charVector: ': ').
	end fetchEndContext == NULL ifTrue:
		[result insert: result count with: (MuWordArray make.charVector: 'EVERYTHING')]
	ifFalse: [(end getEndContext isKindOf: XuText) not ifTrue:
		[result insert: result count with: (MuWordArray make.charVector: 'NON-TEXT')]
	ifFalse: [(context _ end getEndContext quickCast: XuText) usedDomain isEmpty ifTrue:
		[result insert: result count with: (MuWordArray make.charVector: 'NOTHING')]
	ifFalse:
		[result vcopy: result count
			with: context
			with: (IntegerRegion
				integerExtent: (context usedDomain cast: IntegerRegion) start
				with: 20)]]].
	^result!

{DocumentModel} createDocModel: ofType {PackOBits} with: editors {ScruSet default: NULL} with: readers {ScruSet default: NULL}
	
	"Create a new document model of the type specified and enter it into my list of documents.  This is done to keep a waldo on the document in case there is no bert on the document (and therefore making it inaccessible, except through the original waldo)."
	
	| newWaldo {Waldo} docModel {DocumentModel} |
	newWaldo _ self user keyMaster makePersistentWaldo: ofType.
	docModel _ newWaldo convert: DocumentModel.
	(editors ~~ NULL and: [editors isEmpty not]) 
		ifTrue: [docModel getEditPermissions addAll: editors].
	(readers ~~ NULL and: [readers isEmpty not])
		ifTrue: [docModel getReadPermissions addAll: readers].
	self documents at: docModel iD introduce: docModel.
	^ docModel!

{MuTable of: PackOBits and: DocumentModel} documents
	^myDocuments!

{KeyMaster} keyMaster
	^myKeyMaster! !

!TapestryAppModel methodsFor: 'create'!

create: km {KeyMaster} 

	super create.
	myPublicDirectory _ UserDirectoryModel
		make: (DirectoryModel make: km
			with: XuDirectory userDirectoryID
			with: true)
		with: NULL
		with: NULL.
	myKeyMaster _ km.
	myUser _ NULL.
	myLinkEnds _ LinkEndsModel make.
	myDocuments _ MuTable make: FeServer current globalIDSpace! !

!TapestryAppModel methodsFor: 'smalltalk: defaults'!

{DocumentModel} createDocModel: ofType {PackOBits}

	^ self createDocModel: ofType with: NULL with: NULL!

{DocumentModel} createDocModel: ofType {PackOBits} with: editors {ScruSet default: NULL}

	^ self createDocModel: ofType with: editors with: NULL!

createLink: end1 with: end2 with: type
	^self createLink: end1 with: end2 with: type with: NULL!

{PassageModel} createPassage
	"create a new, empty passage"
	
	^ self createPassage: NULL with: NULL! !

!TapestryAppModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '(' 
		<< ' MyUser = ' << myUser 
		<< ' link ends = ' << myLinkEnds 
		<< ' MyDocuments = ' << myDocuments << ')'! !

!TapestryAppModel methodsFor: 'clubs'!

{PermissionsModel} makeUserClub: km {KeyMaster}

	| nuClub {ClubManager} nuDir {XuDirectory}
	  nuHome {Waldo} nuID {ID} |
	nuClub _ km makeClub.
	nuClub lockSmith: (LockSmith booLockSmith: km).
	nuDir _ XuDirectory userDirectory: km with: nuClub getID.
	nuDir destroy.
	nuHome _ km makePersistentWaldo: (Sequence string: 'DirectRecord').
	nuClub homeDocID: nuHome getID.
	nuHome destroy.
	nuID _ nuClub getID.
	nuClub destroy.
	^PermissionsModel fetchPermissionsModel: km with: nuID! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TapestryAppModel class
	instanceVariableNames: ''!

(TapestryAppModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TapestryAppModel class methodsFor: 'pseudo constructors'!

make: km {KeyMaster}
	^self create: km! !

!TapestryAppModel class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage
	"TapestryAppModel cleanupGarbage"
	Application _ nil! !

!TapestryAppModel class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited

	TapestryAppModel
		defineFluid: #Application
		with: Emulsion globalEmulsion
		with: [NULL]! !Heaper subclass: #TapestryFilter
	instanceVariableNames: 'myFilter {ReferenceFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!

(TapestryFilter getOrMakeCxxClassDescription)
	friends:
'/* friends for class TapestryFilter */
friend class TapestryFilter2Reference;';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!TapestryFilter methodsFor: 'accessing'!

{XuText} name

	^ myFilter name!

{void} watchReferences: document {DocumentModel} with: references {SetModel of: Reference} with: destroy {XnModel default: NULL}
	"put all current references from the document into the set,
	then create sensors to put new references in there
	an update to the destroy model should get rid of the sensors"
	self subclassResponsibility! !

!TapestryFilter methodsFor: 'protected: protected operations'!

{Filter} filter

	^ myFilter filter!

{IndirectRecord} findReferences: document {DocumentModel} with: filter {Filter}

	| result {IndirectRecord} |
	result := document contentsWaldo delayedBackReference: filter.
	self referenceFilter keyMaster delayedExtendBackReferenceID: document iD
		with: result.
	^result!

{ReferenceFilter} referenceFilter

	^ myFilter! !

!TapestryFilter methodsFor: 'smalltalk: smalltalk defaults'!

{void} watchReferences: document {DocumentModel} with: references {SetModel of: Reference}
	^self watchReferences: document with: references with: NULL! !

!TapestryFilter methodsFor: 'create'!

create: filter {ReferenceFilter}
	super create.
	myFilter _ filter! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TapestryFilter class
	instanceVariableNames: ''!

(TapestryFilter getOrMakeCxxClassDescription)
	friends:
'/* friends for class TapestryFilter */
friend class TapestryFilter2Reference;';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!TapestryFilter class methodsFor: 'pseudo constructors'!

{TapestryFilter} tapestryLinkFilter: km {KeyMaster} with: descriptor {MuWordArray} with: filter {Filter of: ID}
	^TapestryLinkFilter create: (ReferenceFilter linkFilter: km with: descriptor with: filter)!

{TapestryFilter} tapestryVariantFilter: km {KeyMaster} with: descriptor {MuWordArray} with: filter {Filter of: ID}
	^TapestryLinkFilter create: (ReferenceFilter variantFilter: km with: descriptor with: filter)! !TapestryFilter subclass: #TapestryLinkFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-filters'!

(TapestryLinkFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TapestryLinkFilter methodsFor: 'create'!

create: filter {ReferenceFilter}
	super create: filter! !

!TapestryLinkFilter methodsFor: 'accessing'!

{void} watchReferences: document {DocumentModel} 
        with: references {SetModel of: Reference} 
        with: destroy {XnModel default: NULL}
        "put all current references from the document into the set,
        then create sensors to put new references in there
        a NewContentsUpdate to the destroy model should get rid of the sensors"
        
        | map {IndirectRecord} sensor {LinkReferenceSensor} result {MuSet of: Reference} |
        map _ (self findReferences: document
                	with: ((self filter intersect: 
                		(XuServer currentServer waldoFilter: (Sequence string: 'XuLink'))) cast: Filter)) 
                cast: IndirectRecord.
        sensor _ LinkReferenceSensor make: document with: references with: map with: destroy.
        map wait: sensor.
        self hack. "synchronization -- what if sensor rings now?"
        result _ MuSet make.
        map usedDomain stepper forEach: [ :link {ID} |
                (Reference linkReferences: ((map get: link) cast: XuLink) with: document) stepper
                        forEach: [ :ref {Reference} |
                                result store: ref]].
        references replaceWith: result! !TapestryFilter subclass: #TapestryVariantFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-filters'!

(TapestryVariantFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TapestryVariantFilter methodsFor: 'accessing'!

{void} watchReferences: document {DocumentModel} 
	with: references {SetModel of: Reference} 
	with: destroy {XnModel default: NULL}
	"Put all current variants of the document into the set, then create sensors to put new variants in there.
	A NewContentsUpdate to the destroy model should get rid of the sensors."
	
	| map {IndirectRecord} sensor {VariantReferenceSensor}
	  result {MuSet of: Reference} |
	map := self findReferences: document with: self filter.
	sensor := VariantReferenceSensor make: document
		with: references with: map with: destroy.
	map wait: sensor.
	self hack. "synchronization -- what if sensor rings now?"
	result := MuSet make.
	map usedDomain stepper forEach: [ :each {ID} |
		result storeAll: (Reference variantReferences: ((map indirectGet: each) cast: Waldo))].
	references replaceWith: result! !

!TapestryVariantFilter methodsFor: 'create'!

create: filter {ReferenceFilter}
	super create: filter! !Converter subclass: #TapestryFilter2Reference
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-filters'!

(TapestryFilter2Reference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TapestryFilter2Reference methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	^(value basicCast: TapestryFilter) referenceFilter! !

!TapestryFilter2Reference methodsFor: 'create'!

create
	super create: TapestryFilter with: ReferenceFilter! !FebeTester subclass: #TapestryTester
	instanceVariableNames: 'myPublic {KeyMaster NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(TapestryTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!TapestryTester methodsFor: 'create'!

create
	super create.
	myPublic _ NULL! !

!TapestryTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"TapestryTester runTest"
	
	myPublic _ self keyMaster.
	[Transcript nextPutAll: 'building Application'; cr; endEntry] smalltalkOnly.
	Application fluidSet: (TapestryAppModel make: myPublic).
	[Transcript nextPutAll: 'Logging in'; cr; endEntry] smalltalkOnly.
	Application fluidGet login.
	"[STWindowModel windowsGone wait] smalltalkOnly"! !

!TapestryTester methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' (myPublic = ' << myPublic << ')'! !

!TapestryTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartTapestryTester: rcvr {Rcvr unused default: NULL}
	myPublic _ NULL! !

!TapestryTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartTapestryTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !Heaper subclass: #TextComparator
	instanceVariableNames: '
		myStartMoves {IntegerTable of: PrimFragment}
		myFinalMoves {IntegerTable of: PrimFragment}
		myInsertions {IntegerTable of: CompareFragment}
		myDeletions {IntegerTable of: CompareFragment}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
TextComparator comment:
'TextComparator takes in a mapping from one document to another, and constructs tables of CompareFragments representing the parts of the documents that are shared in different ways.  '!

(TextComparator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextComparator methodsFor: 'comparison'!

{EditSequence} findLCS
	| startArray {IntegerTable of: Move} startTable {IntegerTable of: CompareFragment}
	  endArray {IntegerTable of: Move} endTable {IntegerTable of: CompareFragment} |

	startTable _ myStartMoves copy cast: IntegerTable.
	startTable storeAll: myDeletions.
	startArray _ IntegerTable make: myStartMoves count.
	startTable stepper forEach: [:eachMove {CompareFragment} |
			startArray atInt: startArray count + 1 store: eachMove].

	endTable _ myFinalMoves copy cast: IntegerTable.
	endTable storeAll: myInsertions.
	endArray _ IntegerTable make: myFinalMoves count.
	endTable stepper forEach: [:eachMove {CompareFragment} |
			endArray atInt: endArray count + 1 store: eachMove].
	^(LCSFinder make: startArray with: endArray) fillInTable! !

!TextComparator methodsFor: 'initialize'!

{IntegerTable of: PrimFragment} copyMovesByDestination: inputMoves {IntegerTable of: PrimFragment}
	"return a table of all of the moves with each stored at all of the destinations it specifies"
	| moves {IntegerTable of: PrimFragment} |
	moves _ IntegerTable make.
	inputMoves stepper forEach: [:eachMove {PrimFragment} |
		eachMove finalLocations stepper forEach: [:eachDest {IntegerPos} |
			moves _ eachMove mergeInto: moves with: eachDest asIntegerVar]].
	^moves!

{IntegerTable of: PrimFragment} copyMovesByOrigin: inputMoves {IntegerTable of: PrimFragment}
	"return a table of all of the moves with each stored at all of the origins it specifies"
	| moves {IntegerTable of: PrimFragment} |
	moves _ IntegerTable make.
	inputMoves stepper forEach: [:eachMove {PrimFragment} |
		eachMove startLocations stepper forEach: [:eachStart {IntegerPos} |
			moves _ eachMove mergeInto: moves with: eachStart asIntegerVar]].
	^moves!

{IntegerTable of: PrimFragment} fixOverlapsIn: inputMoves {IntegerTable of: PrimFragment}
	"iterate through the table, making sure that none of the PrimFragments overlaps with the next."

	| moves {IntegerTable of: PrimFragment} lowerBound {IntegerVar} curMove {PrimFragment} overlapRegion {IntegerRegion} |
	moves _ inputMoves copy cast: IntegerTable.
	lowerBound _ moves lowestIndex.
	[(moves intFetch: lowerBound) == NULL] whileFalse: 
		[curMove _ (moves intFetch: lowerBound) cast: PrimFragment.
		overlapRegion _ ((IntegerRegion make: lowerBound + 1 with: lowerBound + curMove count)
								intersect: moves domain) cast: IntegerRegion. "use firstElemAfter: if possible"
		overlapRegion isEmpty
			ifFalse: [ | newMoves {Pair of: PrimFragment} |
				newMoves _ curMove breakAt: overlapRegion start - lowerBound.
				moves atInt: lowerBound replace: newMoves left.
				moves _ (newMoves right cast: PrimFragment) mergeInto: moves with: overlapRegion start.
				lowerBound _ overlapRegion start]
			ifTrue: [ | nextRegion { IntegerRegion} |
				nextRegion _ ((IntegerRegion after: lowerBound + curMove count) 
								intersect: moves domain) cast: IntegerRegion.  "use firstElemAfter: if possible"
				nextRegion isEmpty 
					ifTrue: [lowerBound _ lowerBound + curMove count "move past the end"]
					ifFalse: [lowerBound _ nextRegion start]]].
	^moves

	"I'd bet that all of the time in this routine is in the region intersections.  What I really want 
	to know is firstElemAfter:, but it's a private method.    --cth  9/14/90"!

{void} setDeletionsFrom: dRegion {IntegerRegion} with: size {IntegerVar}
	| deleteRegion {IntegerRegion} |

	deleteRegion _ ((IntegerRegion make: IntegerVar0 with: size) intersect: dRegion) cast: IntegerRegion.
	myDeletions _ IntegerTable make.
	deleteRegion simpleRegions forEach: [:simple {IntegerRegion} |
		myDeletions atInt: simple start introduce: (DeleteFragment make: simple count with: simple)]!

{void} setInsertionsFrom: iRegion {IntegerRegion} with: size {IntegerVar}
	| insertRegion {IntegerRegion} |

	insertRegion _ ((IntegerRegion make: IntegerVar0 with: size) intersect: iRegion) cast: IntegerRegion.
	myInsertions _ IntegerTable make.
	insertRegion simpleRegions forEach: [:simple {IntegerRegion} |
		myInsertions atInt: simple start introduce: (InsertFragment make: simple count with: simple)]!

{void} setUpFromDocs: orig {XuText} with: final {XuText}
	"The algorithm needs two passes in order to find overlaps in both the original and the final doc."
	| simpleMapping {Mapping} firstPass {IntegerTable of: PrimFragment} secondPass {IntegerTable of: PrimFragment} |
	simpleMapping _ orig compare: final.
	self setInsertionsFrom: (simpleMapping range complement cast: IntegerRegion) with: final count.
	self setDeletionsFrom: (simpleMapping domain complement cast: IntegerRegion) with: orig count.
	firstPass _ self fixOverlapsIn: (self setUpSourceMoves: simpleMapping simpleRegionMappings).
	secondPass _ self fixOverlapsIn: (self copyMovesByDestination: firstPass).
	myStartMoves _ IntegerTable make.
	myFinalMoves _ IntegerTable make.
	secondPass stepper forEach: [:eachMove {PrimFragment}|
		eachMove startLocations stepper forEach: [:eachStart {IntegerPos} |
			myStartMoves at: eachStart store: eachMove].
		eachMove finalLocations stepper forEach: [:eachEnd {IntegerPos} |
			myFinalMoves at: eachEnd store: eachMove]].!

{IntegerTable} setUpSourceMoves:  mappings {ImmuSet of: Mapping} 
	| moves {IntegerTable of: PrimFragment} srcStart {IntegerVar} newMove {PrimFragment} |
	moves _ IntegerTable make.
	mappings stepper forEach: [:each {Mapping} |
		srcStart _ (each domain cast: IntegerRegion) start.
		newMove _ PrimFragment make: (each domain cast: IntegerRegion) count with: srcStart with: (each range cast: IntegerRegion) start.
		moves _ newMove mergeInto: moves with: srcStart].
	^moves!

{IntegerTable} setUpSourcePrimFragments:  mappings {ImmuSet of: Mapping} 
	| moves {IntegerTable of: PrimFragment} srcStart {IntegerVar} newMove {PrimFragment} |
	moves _ IntegerTable make.
	mappings stepper forEach: [:each {Mapping} |
		srcStart _ (each domain cast: IntegerRegion) start.
		newMove _ PrimFragment make: (each domain cast: IntegerRegion) count
								with: srcStart
								with: (each range cast: IntegerRegion) start.
		moves _ newMove mergeInto: moves with: srcStart].
	^moves! !

!TextComparator methodsFor: 'creation'!

create.IntegerTable: aTable {IntegerTable of: CompareOperation} with.IntegerTable: anotherTable {IntegerTable of: CompareOperation}
	super create.
	myStartMoves _ aTable.
	myFinalMoves _ anotherTable.
	myInsertions _ IntegerTable make: IntegerVar0.
	myDeletions _ IntegerTable make: IntegerVar0.!

create: aText {XuText} with: anotherText {XuText}
	super create.
	self setUpFromDocs: aText with: anotherText.! !

!TextComparator methodsFor: 'accessing'!

{IntegerTable} deletions
	^myDeletions!

{IntegerTable of: PrimFragment} finalMoves
	^myFinalMoves!

{IntegerTable} insertions
	^myInsertions!

{IntegerTable of: PrimFragment} startMoves
	^myStartMoves! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextComparator class
	instanceVariableNames: ''!

(TextComparator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextComparator class methodsFor: 'pseudoConstructors'!

{TextComparator} make.IntegerTable: aTable {IntegerTable of: CompareOperation} with.IntegerTable: anotherTable {IntegerTable of: CompareOperation}

	^TextComparator create.IntegerTable: aTable with.IntegerTable: anotherTable!

{TextComparator} make: aText {XuText} with: anotherText {XuText}

	^TextComparator create: aText with: anotherText! !Converter subclass: #TextDoc2PassageModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(TextDoc2PassageModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TextDoc2PassageModel methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	^PassageModel make: (value quickCast: XuText)! !

!TextDoc2PassageModel methodsFor: 'creation'!

create
	"super create: XuText with: DocumentModel"! !

!TextDoc2PassageModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}oo <<  self getCategory name! !FMBuilder subclass: #TextWaldoBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!

(TextWaldoBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextWaldoBuilder methodsFor: 'creation'!

create
	super create! !

!TextWaldoBuilder methodsFor: 'build'!

{FMBuilding} build: model {Heaper as: XuText} 
 
	^ Scaffold fluidGet build: (model convert: AttributedTextModel)! !

!TextWaldoBuilder methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextWaldoBuilder class
	instanceVariableNames: ''!

(TextWaldoBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextWaldoBuilder class methodsFor: 'pseudo constructors'!

make
	^self create! !Thunk subclass: #TranscriptThunk
	instanceVariableNames: '
		message {MuWordArray}
		arg {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(TranscriptThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TranscriptThunk methodsFor: 'action'!

{void} execute
	"Execute the action defined by this thunk."
	
	cerr << message << '  ' << arg << '
'! !

!TranscriptThunk methodsFor: 'create'!

create: xmessage{MuWordArray} with: xarg{Heaper}
	super create.
	message _ xmessage.
	arg _ xarg! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TranscriptThunk class
	instanceVariableNames: ''!

(TranscriptThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TranscriptThunk class methodsFor: 'pseudo constructors'!

{Thunk} make: text {MuWordArray} with: item {Heaper}
	^ self create: text with: item! !FMBuilder subclass: #TwoLineReferenceBuilder
	instanceVariableNames: ''
	classVariableNames: 'TwoLineReferencePortions {ListModel of: Portion} '
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
TwoLineReferenceBuilder comment:
'Builds a view onto a reference.
*Eventually, will be a director that has a model
describing the format of the view'!

(TwoLineReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class TwoLineReferenceBuilder */
friend SPTR(TwoLineReferenceBuilder) 
twoLineReferenceBuilder ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TwoLineReferenceBuilder methodsFor: 'private: creation'!

create
	super create! !

!TwoLineReferenceBuilder methodsFor: 'build'!

{FMBuilding} build: something {Heaper as: Reference} 
	| reference {Reference} kind {FMBuilding} label {FMBuilding} descriptor {FMBuilding}
	  style {ListStyle} txtBuilder {FMTextBuilder} sumText {AttributedTextModel}
	  author {FMBuilding} furstlyne {Viewer} | 
	reference _ something cast: Reference.
	sumText _ (MuWordArray make.charVector: 'marcs')
				convert: AttributedTextModel.
	txtBuilder _ FMTextBuilder make: (ExtentLayout make: (PointPos make: 2000 with: 12)).
	Scaffold fluidBind: (FMScaffold
			make: AttributedTextModel
			with: txtBuilder
			with: Scaffold fluidGet)
		during: 
			[kind _ Scaffold fluidGet build: reference kind.
			label _ Scaffold fluidGet build: reference label.
			author _ Scaffold fluidGet build: sumText.
			descriptor _ Scaffold fluidGet build: reference descriptor].
	style _ ListStyle defaultHorizontal.
	style setSpacing: 4.
	furstlyne _ ListMultiViewer make: (ListModel make: (MuArray
						array: kind view
						with: label view
						with: author view))
				with: (PortionListComp make: style with: TwoLineReferencePortions).
	^FMBuilding make: (ListMultiViewer make: (ListModel make: (MuArray
				array: furstlyne with: descriptor view))
			with: (BoundingListComp make: ListStyle defaultVertical))
		with: NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TwoLineReferenceBuilder class
	instanceVariableNames: ''!

(TwoLineReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class TwoLineReferenceBuilder */
friend SPTR(TwoLineReferenceBuilder) 
twoLineReferenceBuilder ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TwoLineReferenceBuilder class methodsFor: 'smalltalk: initialization'!

cleanupGarbage

	self linkTimeNonInherited!

initTimeNonInherited
	self REQUIRES: IntegerRegion.
	self REQUIRES: MuArray.
	self REQUIRES: ListModel.
	self REQUIRES: Portion.
	TwoLineReferencePortions _ ListModel make: (MuArray
		array: (Portion make: (IntegerRegion after: 12) with: 0.25)
		with: (Portion make: (IntegerRegion after: 12) with: 0.5)
		with: (Portion make: (IntegerRegion after: 12) with: 0.25))!

linkTimeNonInherited
	TwoLineReferencePortions _ NULL! !

!TwoLineReferenceBuilder class methodsFor: 'make'!

make
	^self create! !Converter subclass: #UDM2UDMWindow
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(UDM2UDMWindow getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UDM2UDMWindow methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	"perform the conversion.  This is defined by those who define a new converter, but not directly called
	 by clients.  Clients invoke conversion purely by using the CONVERT macro"
	
	^ UDMWindowModel make: (value cast: UserDirectoryModel)! !

!UDM2UDMWindow methodsFor: 'creation'!

create
	super create: UserDirectoryModel with: WindowModel! !XnModel subclass: #User2DefaultPermissionSchnert
	instanceVariableNames: '
		myUser {UserModel}
		myDefault {VariableModel of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
User2DefaultPermissionSchnert comment:
'Retrieve the user''s default permissions from the profile information

		myUser {UserModel}
		myDefault {VariableModel of: PackOBits}'!

(User2DefaultPermissionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!User2DefaultPermissionSchnert methodsFor: 'create'!

create: who {UserModel} with: def {VariableModel of: ID}
	super create.
	myUser _ who.
	myDefault _ def.
	who addDependent: self.
	self updateDefault! !

!User2DefaultPermissionSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel} 
	"change the default permissions"

	model == (myUser basicCast: XnModel) ifTrue: [self updateDefault]! !

!User2DefaultPermissionSchnert methodsFor: 'private: private updating'!

{void} updateDefault
	myDefault setValue: myUser keyMaster userID! !

!User2DefaultPermissionSchnert methodsFor: 'protected: creation'!

{void} destruct
	myUser removeDependent: self.
	super destruct! !

!User2DefaultPermissionSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	
	<< ' myUser = ' << myUser 
	<<	'myDefault = ' << myUser! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

User2DefaultPermissionSchnert class
	instanceVariableNames: ''!

(User2DefaultPermissionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!User2DefaultPermissionSchnert class methodsFor: 'make'!

make: who {UserModel} with: def {VariableModel of: ID}
	^self create: who with: def! !XnModel subclass: #User2HomeSchnert
	instanceVariableNames: '
		myUser {UserModel}
		myHome {WaldoModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
User2HomeSchnert comment:
'Retrives the user''s home document'!

(User2HomeSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!User2HomeSchnert methodsFor: 'create'!

create: who {UserModel} with: home {HomeDocumentModel}
	super create.
	myUser _ who.
	myHome _ home.
	myUser addDependent: self.
	self updateHome! !

!User2HomeSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel} 
	"change the home document"

	model == (myUser basicCast: XnModel) ifTrue: [self updateHome]! !

!User2HomeSchnert methodsFor: 'private: private updating'!

{void} updateHome
	myHome setWaldo: myUser keyMaster getHomeDocID
		with: (Sequence string: 'IndexedWaldo')
		with: true
		with: myUser keyMaster! !

!User2HomeSchnert methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' (myUser = ' << myUser << '
	myHome =  ' << myUser << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

User2HomeSchnert class
	instanceVariableNames: ''!

(User2HomeSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!User2HomeSchnert class methodsFor: 'make'!

make: who {UserModel} with: home {HomeDocumentModel}
	^self create: who with: home! !XnModel subclass: #UserDirectoryModel
	instanceVariableNames: '
		myOccludedDirectory {UserDirectoryModel}
		myDirectory {DirectoryModel}
		myClubIDs {ListModel of: PackOBits}
		myClubNames {ListModel of: PackOBits}
		mySuperClubsDirectory {MuTable of: PackOBits and: (ImmuSet of: PackOBits)}
		myTransitiveMembers {MuTable of: PackOBits and: (ImmuSet of: PackOBits)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Models'!
UserDirectoryModel comment:
'Maintains a list of the club IDs that the user knows about, and a corresponding list of club names'!

(UserDirectoryModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserDirectoryModel methodsFor: 'accessing'!

{ImmuSet of: ID} allIDs
	| start {ImmuSet of: PackOBits} |
	[ListModel] USES.
	myOccludedDirectory == NULL
		ifTrue: [start _ ImmuSet make]
		ifFalse: [start _ myOccludedDirectory allIDs].
	^start unionWith: (myDirectory clubIDs asTable range)!

{void} at: name {PackOBits} storeClubID: clubID {ID}

	(self fetchLocalClubID: name) ~~ NULL
		ifTrue: [| oldName {PackOBits} |
			oldName _ self fetchName: clubID.
			myDirectory removeName: oldName].
	myDirectory at: name storeClubID: clubID!

{ListModel of: ID} clubIDs
	"the ordered list of club IDs"
	^myClubIDs!

{ListModel of: PackOBits} clubNames
	"the ordered list of club names"
	^myClubNames!

{ID} fetchClubID: name {PackOBits}
	"This method looks up a name in the local directory to find the corresponding ID.
	 If not found, it attempts to look it up in the occluded directory."
	 
	| iD {ID} |
	iD _ myDirectory fetchClubID: name.
	(iD == NULL and: [myOccludedDirectory ~~ NULL]) 
		ifTrue: [iD _ myOccludedDirectory fetchClubID: name].
	^ iD!

{ID} fetchLocalClubID: name {PackOBits}
	"This method looks up a name ONLY in the local directory.
	 If not found locally, it will return NULL."
	 
	^ myDirectory fetchClubID: name!

{PackOBits} fetchLocalName: club {ID} 
	"find a name to show for the given club ID"
	"check first in my list, then in the public directory."

	^ myDirectory fetchClubName: club!

{PackOBits} fetchName: club {ID} 
	"find a name to show for the given club ID"
	"check first in my list, then in the public directory."

	| name {PackOBits} |
	name _ myDirectory fetchClubName: club.
	(name == NULL and: [myOccludedDirectory ~~ NULL]) ifTrue: 
			[name _ myOccludedDirectory fetchName: club].
	^name!

{ID} getClubID: name {PackOBits}
	"This method looks up a name in the local directory to find the corresponding ID.
	 If not found, it attempts to look it up in the occluded directory."
	 
	| iD {ID} |
	iD _ self fetchClubID: name.
	(iD == NULL) ifTrue: [Heaper BLAST: #ClubNameNotFound].
	^ iD!

{PackOBits} getName: club {ID}
	"find a name to show for the given club ID"
	| result {PackOBits} |
	result _ self fetchName: club.
	result == NULL ifTrue:
		[Heaper BLAST: #NoNameForClub].
	^result!

{KeyMaster} keyMaster
	^Application fluidGet user keyMaster!

{ScruSet of: ID} superClubsOf: clubID {ID} 
	"^(mySuperClubsDirectory get: clubID) cast: ScruSet"
	^ ImmuSet make! !

!UserDirectoryModel methodsFor: 'create'!

create: aDirectory {DirectoryModel} with: occluded {UserDirectoryModel} with: list {ListModel of: ID} 
	super create.
	myOccludedDirectory _ occluded.
	myDirectory _ aDirectory.
	list == NULL
		ifTrue: [myClubIDs _ ListModel make]
		ifFalse: [myClubIDs _ list].
	myClubIDs addDependent: self.
	myClubNames _ ListModel make.
	"List2ListLookupSchnert
		make: myClubIDs
		with: myClubNames
		with: (ID2ClubNameLookup make: self)."
	mySuperClubsDirectory _ MuTable make: FeServer current globalIDSpace.
	myTransitiveMembers _ MuTable make: FeServer current globalIDSpace.
	self updateTransitiveMembers.
	self updateSuperClubs!

{void} destruct
	super destruct! !

!UserDirectoryModel methodsFor: 'private: accessing'!

{ScruTable of: ID and: (ScruSet of: ID)} calculateSuperClubs

	"| membersTable {ScruTable} supersTable {MuTable}
	 superStepper {TableStepper} memberStepper {TableStepper} |
	membersTable _ self transitiveMembersDirectory.
	supersTable _ MuTable make: IDSpace make.
	self clubIDs asTable stepper forEach: [:clubID {ID} |
		supersTable at: clubID store: (MuSet make)].
	(superStepper _ supersTable stepper cast: TableStepper) forEach: [:supers {MuSet} |
		(memberStepper _ membersTable stepper cast: TableStepper) forEach: [:members {ScruSet} |
			(members hasMember: superStepper key)
				ifTrue: [supers store: memberStepper key]]].
	^ supersTable"!

{ScruTable of: ID and: (ScruSet of: ID)} transitiveMembersDirectory

	"| membersTable {MuTable} |
	membersTable _ MuTable make: IDSpace make.
	self clubIDs asTable stepper forEach: [:userID {ID} | | pm {PermissionsModel} |
		pm _ PermissionsModel fetchPermissionsModel: myDirectory waldo keyMaster with: userID.
		pm ~~ NULL ifTrue: [membersTable at: userID store: pm transitiveMembers]].
	^ membersTable"!

{void} updateSuperClubs

	"| memberStepper {TableStepper} |
	self clubIDs asTable stepper forEach: [:clubID {ID} |
		((mySuperClubsDirectory includesKey: clubID) not 
				or: [((mySuperClubsDirectory get: clubID) cast: MuSet) isEmpty])
			ifTrue: [| supers {MuSet} |
				supers _ MuSet make.
				(memberStepper _ myTransitiveMembers stepper cast: TableStepper) 
					forEach: [:members {ScruSet} |
						(members hasMember: clubID)
							ifTrue: [supers store: memberStepper key]].
				mySuperClubsDirectory at: clubID store: supers]]."!

{void} updateTransitiveMembers
	"self clubIDs asTable stepper forEach: [:userID {ID} | | pm {PermissionsModel} |
		(myTransitiveMembers includesKey: userID) not ifTrue: [pm _ PermissionsModel fetchPermissionsModel: myDirectory waldo keyMaster with: userID.
			pm ~~ NULL ifTrue: [myTransitiveMembers at: userID store: pm transitiveMembers]]]"! !

!UserDirectoryModel methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel unused}
	self updateTransitiveMembers.
	self updateSuperClubs! !

!UserDirectoryModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name 
		<< '(' << myClubNames << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UserDirectoryModel class
	instanceVariableNames: ''!

(UserDirectoryModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserDirectoryModel class methodsFor: 'pseudo constructors'!

make: dir {DirectoryModel} with: occluded {UserDirectoryModel} with: list {ListModel of: ID}

	^ self create: dir with: occluded with: list! !Thunk subclass: #UserDirectoryThunk
	instanceVariableNames: 'myUDM {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(UserDirectoryThunk getOrMakeCxxClassDescription)
	friends:
'/* friends for class UserDirectoryThunk */
friend SPTR(UserDirectoryThunk)  userDirectoryThunk (UserDirectoryModel * udm);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserDirectoryThunk methodsFor: 'private: create'!

create: onUDM {UserDirectoryModel}

	super create.
	myUDM _ onUDM! !

!UserDirectoryThunk methodsFor: 'operate'!

{void} execute
	"Execute the action defined by this thunk."
	(UDMWindowModel make: myUDM) open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UserDirectoryThunk class
	instanceVariableNames: ''!

(UserDirectoryThunk getOrMakeCxxClassDescription)
	friends:
'/* friends for class UserDirectoryThunk */
friend SPTR(UserDirectoryThunk)  userDirectoryThunk (UserDirectoryModel * udm);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserDirectoryThunk class methodsFor: 'make'!

make: udm {UserDirectoryModel}

	^ self create: udm! !XnModel subclass: #UserModel
	instanceVariableNames: '
		myKeyMaster {KeyMaster}
		myHomeDocument {HomeDocumentModel}
		myTableTop {TableTopModel}
		myUserDirectory {UserDirectoryModel}
		myDefaultPermission {VariableModel of: PackOBits}
		myLinkTypes {ListModel}
		myDefaultLinkType {VariableModel of: PackOBits}
		myDefaultReferencesStyle {VariableModel of: FMBuilder}
		myFilters {ListModel}
		myDefaultFilter {VariableModel of: ReferenceFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
UserModel comment:
'Represents the current identity of the user.
All permissions interactions should go through here.

		myKeyMaster {KeyMaster}
			The actual permissions object; it should never be
manipulated directly.
		myPublicHomeDocument {WaldoModel}
			The home document of the public club, mapping from
names->club IDs
		myHomeDocument {WaldoModel}
			The home document of the current user
		myTableTop {TableTopModel}
			The active window list
		myUserDirectory {UserDirectoryModel}
			The known club IDs and names
		myDefaultPermission {VariableModel of: PackOBits}
			The default permissions for newly created documents
		myLinkTypes {WaldoListModel}
			The ordered list of known link types
		myDefaultLinkType {VariableModel of: PackOBits}
			The default link type for newly created links
		myDefaultReferencesStyle {VariableModel of: FMBuilder}
			A builder that creates a pane for an individual
reference, the current default setting
		myFilters {WaldoListModel}
			The list of known filters
		myDefaultFilter {VariableModel of: ReferenceFilter}
			The default filter for new windows'!

(UserModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserModel methodsFor: 'create'!

create: km {KeyMaster} 
	| intermediateList {ListModel} |
	super create.
	[TapestryAppModel] USES.
	myKeyMaster _ km.
	myHomeDocument _ HomeDocumentModel make: km with: km getHomeDocID.
	myTableTop _ TableTopModel make: myHomeDocument.
	myUserDirectory _ UserDirectoryModel
		make: (DirectoryModel make: km
			with: (XuDirectory userDirectoryID: km
				with: km userID)
			with: true)
		with: Application fluidGet publicDirectory
		with: NULL.
	myDefaultPermission _ VariableModel make.
	"User2DefaultPermissionSchnert make: self with: myDefaultPermission."
	myLinkTypes _ WaldoListModel make.
	"Waldo2SubListSchnert make: myHomeDocument
		with: (PackOBits make: 'LinkTypes')
		with: myLinkTypes."
	myDefaultLinkType _ VariableModel make.
	"Waldo2ValueSchnert make: myHomeDocument
		with: (PackOBits make: 'DefaultLinkType')
		with: myDefaultLinkType."
	myDefaultReferencesStyle _ 
		VariableModel make: DocumentWindowModel defaultReferenceBuilder.
	myFilters _ ListModel make.
	intermediateList _ WaldoListModel make.
	"Waldo2SubListSchnert make: myHomeDocument
		with: (PackOBits make: 'Filters')
		with: intermediateList.
	ListConverterSchnert make: intermediateList
		with: ReferenceFilter
		with: myFilters
		with: TapestryFilter."
	myDefaultFilter _ VariableModel make.
	"Waldo2ValueSchnert make: myHomeDocument
		with: (PackOBits make: 'DefaultFilter')
		with: myDefaultFilter
		with: TapestryFilter"! !

!UserModel methodsFor: 'accessing'!

{VariableModel of: TapestryFilter} defaultFilter
	"the list of filters known to this user"
	^myDefaultFilter!

{VariableModel of: ID} defaultLinkType
	"the default link types for this user"
	^myDefaultLinkType!

{VariableModel of: ID} defaultPermission
	"the default permissions for documents created by this user"
	^myDefaultPermission!

{FMBuilder} defaultReferencesStyle

	^ myDefaultReferencesStyle getValue cast: FMBuilder!

{ListModel of: TapestryFilter} filters
	"the list of filters known to this user"
	^myFilters!

{WaldoModel} homeDocument
	"the home document of the user's club"
	^myHomeDocument!

{KeyMaster} keyMaster
	"the key master for this user"
	^myKeyMaster!

{ListModel} linkTypes
	"the link types known to this user"
	^myLinkTypes!

{TableTopModel} tableTop
	"the table top for this user"
	^myTableTop!

{UserDirectoryModel} userDirectory
	"the clubs and names known to this user"
	^myUserDirectory! !

!UserModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '(' << ' for '.
	oo << ((self userDirectory fetchName: myKeyMaster userID) convert: MuWordArray). 
	oo << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UserModel class
	instanceVariableNames: ''!

(UserModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserModel class methodsFor: 'pseudo constructors'!

make: km {KeyMaster}
	"make the appropriate subclass"
	| result {UserModel} |
	[result _ STUserModel create: km] smalltalkOnly.
	[result _ UserModel create: km] translateOnly.
	result changed: NewContentsUpdate make.
	^result! !XnSensor subclass: #VariantReferenceSensor
	instanceVariableNames: '
		myDocument {DocumentModel}
		myReferences {SetModel of: Reference}
		myMap {IndexedWaldo}
		myDestroy {XnModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(VariantReferenceSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariantReferenceSensor methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
	((myDestroy basicCast: XnDependent) == model and: [change isKindOf: NewContentsUpdate]) ifTrue:
		[myDestroy removeDependent: self.
		self destroy]! !

!VariantReferenceSensor methodsFor: 'create'!

create: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndexedWaldo} with: destroy {XnModel | NULL}
	super create.
	myDocument _ document.
	myReferences _ references.
	myMap _ map.
	myDestroy _ destroy.
	myDestroy ~~ NULL ifTrue:
		[myDestroy addDependent: self]!

{void} destruct
	myDestroy ~~ NULL ifTrue:
		[myDestroy removeDependent: self].
	super destruct! !

!VariantReferenceSensor methodsFor: 'ringing'!

{NOWAIT PROXY} ring: a {Heaper}
	"add a reference to the set"
	| references {MuSet of: Reference} |
	references _ MuSet make.
	(a cast: IDRegion) stepper forEach: [ :each {ID} |
		references storeAll: (Reference
			variantReferences: ((myMap get: each) cast: Waldo))].
	myReferences storeAll: references! !

!VariantReferenceSensor methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

oo <<  self getCategory name << '(' <<	'myDocument= '  <<	myDocument  
<<		'myReferences= '  <<		myReferences 
<<		'myMap='   <<		myMap
<<		'myDestroy=' <<		myDestroy  << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VariantReferenceSensor class
	instanceVariableNames: ''!

(VariantReferenceSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariantReferenceSensor class methodsFor: 'make'!

make: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndexedWaldo} with: destroy {XnModel default: NULL}
	^self create: document with: references with: map with: destroy! !

!VariantReferenceSensor class methodsFor: 'smalltalk: defaults'!

make: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndexedWaldo}
	^self make: document with: references with: map with: NULL! !XnDependent subclass: #Waldo2SubListSchnert
	instanceVariableNames: '
		myRecord {WaldoModel of: IndexedWaldo}
		myKey {Position}
		mySubList {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
Waldo2SubListSchnert comment:
'Maintains a list that is kept in a subwaldo'!

(Waldo2SubListSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2SubListSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel} 
	model == (myRecord basicCast: XnModel) ifTrue: [self updateSubList]! !

!Waldo2SubListSchnert methodsFor: 'create'!

create: record {WaldoModel of: IndexedWaldo} with: key {Position} with: subList {ListModel}
	super create.
	myRecord _ record.
	myKey _ key.
	mySubList _ subList.
	myRecord addDependent: self.
	self updateSubList! !

!Waldo2SubListSchnert methodsFor: 'protected: creation'!

{void} destruct
	myRecord removeDependent: self.
	super destruct! !

!Waldo2SubListSchnert methodsFor: 'private: updating'!

{void} updateSubList 
	(mySubList cast: WaldoListModel) replaceWith: (((myRecord waldo cast: IndexedWaldo)
		get: myKey) cast: IndexedWaldo)! !

!Waldo2SubListSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	      << 'myRecord = '  << myRecord  
		      << 'myKey = '   << myKey  
		 << 'mySubList = ' << mySubList! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Waldo2SubListSchnert class
	instanceVariableNames: ''!

(Waldo2SubListSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2SubListSchnert class methodsFor: 'make'!

make: record {WaldoModel of: IndexedWaldo} with: key {Position} with: subList {ListModel}
	^self create: record with: key with: subList! !XnDependent subclass: #Waldo2SubTextSchnert
	instanceVariableNames: '
		myParent {WaldoModel}
		myKey {ID}
		myText {WaldoTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
Waldo2SubTextSchnert comment:
'Pulls a text waldo out of a DirectRecord (or wrapper of one)'!

(Waldo2SubTextSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2SubTextSchnert methodsFor: 'private: private updating'!

{void} updateText
	myText replaceWith: ((myParent waldo getChild: myKey) cast: XuText)! !

!Waldo2SubTextSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
	(model == (myParent basicCast: XnModel) 
        	and: [change isKindOf: NewContentsUpdate]) ifTrue:
                [self updateText]! !

!Waldo2SubTextSchnert methodsFor: 'create'!

create: parent {WaldoModel} with: key {ID} with: text {WaldoTextModel}
	super create.
	myParent _ parent.
	myKey _ key.
	myText _ text.
	myParent addDependent: self.
	self updateText! !

!Waldo2SubTextSchnert methodsFor: 'protected: creation'!

{void} destruct
	myParent removeDependent: self.
	super destruct! !

!Waldo2SubTextSchnert methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo <<  self getCategory name<< 'myParent = ' << myParent 
		<< 'myKey = ' << myKey 
		<< 'myText = ' << myText! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Waldo2SubTextSchnert class
	instanceVariableNames: ''!

(Waldo2SubTextSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2SubTextSchnert class methodsFor: 'make'!

make: parent {WaldoModel} with: key {ID} with: text {WaldoTextModel}
	^self create: parent with: key with: text! !XnDependent subclass: #Waldo2ValueSchnert
	instanceVariableNames: '
		myRecord {WaldoModel of: IndexedWaldo}
		myKey {Position}
		myValue {VariableModel}
		myConvertCategory {Category star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!
Waldo2ValueSchnert comment:
'Maintains a value that is kept in a slot of a indexed waldo'!

(Waldo2ValueSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2ValueSchnert methodsFor: 'private: updating'!

{void} updateValue
	| aVal {Heaper} res {Heaper} |
	aVal _ (myRecord waldo cast: IndexedWaldo) get: myKey.
	myConvertCategory ~~ NULL 
		ifTrue: [res _ Converter getConversion: myConvertCategory with: aVal]
		ifFalse: [res _ aVal].
	myValue setValue: res! !

!Waldo2ValueSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model {XnModel} 
	model == (myRecord basicCast: XnModel) ifTrue: [self updateValue]! !

!Waldo2ValueSchnert methodsFor: 'create'!

create: record {WaldoModel of: IndexedWaldo} with: key {Position} with: value {VariableModel} with: convertCat {Category star}
	super create.
	myRecord _ record.
	myKey _ key.
	myValue _ value.
	myRecord addDependent: self.
	myConvertCategory _ convertCat.
	self updateValue! !

!Waldo2ValueSchnert methodsFor: 'protected: creation'!

{void} destruct
	myRecord removeDependent: self.
	super destruct! !

!Waldo2ValueSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
			<< ' myRecord = ' << myRecord << '
	myKey = '  << myKey << '
	myValue = ' << myValue.
	myConvertCategory ~~ NULL ifTrue: [aStream << '
	converting value to ' << myConvertCategory]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Waldo2ValueSchnert class
	instanceVariableNames: ''!

(Waldo2ValueSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Waldo2ValueSchnert class methodsFor: 'make'!

make: record {WaldoModel of: IndexedWaldo} with: key {Position} with: value {VariableModel} with: convertTo {Category star default: NULL}
	^self create: record with: key with: value with: convertTo! !

!Waldo2ValueSchnert class methodsFor: 'smalltalk: defaults'!

make: record {WaldoModel of: IndexedWaldo} with: key {Position} with: value {VariableModel}
	^self create: record with: key with: value with: NULL! !ListModel subclass: #WaldoListModel
	instanceVariableNames: 'myWaldo {IndexedWaldo}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(WaldoListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoListModel methodsFor: 'create'!

create: waldo {IndexedWaldo}
	super create.
	myWaldo _ waldo! !

!WaldoListModel methodsFor: 'accessing'!

{ScruTable} asTable
	"return the list as a table"
	^self waldo asTable!

{IntegerVar} count
	"the number of elements in the list"
	^self waldo count!

{XnRegion} domain
	^myWaldo domain!

{Heaper} fetch: pos {IntegerVar}
	"fetch an element from the list"
	^self waldo fetch: pos integer! !

!WaldoListModel methodsFor: 'manipulating'!

{void} insert: pos {IntegerVar} with: element {Heaper}
	"insert an element into the list"
	self waldo transform: ((IntegerMapping make: 1) restrict: (IntegerRegion after: pos)).
	self waldo at: pos integer store: element.
	self changed: (InsertionUR make: pos integer)!

{void} rearrange: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}
	"A 3 cut rearrange. This swaps the elements between cut1 and cut2 with the elements
	between cut2 and cut3. e.g.
	'abcdefg' rearrange: 1 with: 3 with: 6 == 'adefbcg'"
	self waldo transform: ((((IntegerMapping make
			restrict: (IntegerRegion make: IntegerVar0 with: cut1))
		combine: ((IntegerMapping make: cut3 - cut2)
			restrict: (IntegerRegion make: cut1 with: cut2)))
		combine: ((IntegerMapping make: cut1 - cut2)
			restrict: (IntegerRegion make: cut2 with: cut3)))
		combine: (IntegerMapping make
			restrict: (IntegerRegion after: cut3))).
	self changed: (RearrangeUpdate make: cut1 with: cut2 with: cut3)!

{void} replace: index {IntegerVar unused} with: obj
{Heaper unused} 
	"This method replaces the list element at index with the
new object"

	self unimplemented!

{void} replaceWith: waldo {IndexedWaldo}
	myWaldo == waldo ifFalse:
		[ | old {IndexedWaldo} |
		old _ myWaldo.
		myWaldo _ waldo.
		self changed: (SingleReplaceUR make: old with: waldo)]!

{void} wipe: reg {XnRegion}
	"remove the elements in the specified region"
	| leftover {IntegerRegion} |
	leftover _ ((IntegerRegion after: IntegerVar0) minus: reg) cast: IntegerRegion.
	self waldo wipeAll: leftover beforeLast complement.
	self waldo transform: leftover compactor.
	self changed: (DeletionUR make: reg)! !

!WaldoListModel methodsFor: 'private: private'!

{IndexedWaldo} waldo
	myWaldo == NULL ifTrue: [Heaper BLAST: #InvalidRequest].
	^myWaldo! !

!WaldoListModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '(' << myWaldo asTable << ')'! !

!WaldoListModel methodsFor: 'enumerating'!

{Stepper} stepper
	^ myWaldo stepper! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WaldoListModel class
	instanceVariableNames: ''!

(WaldoListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoListModel class methodsFor: 'make'!

make 
	^self create: NULL!

make: waldo {IndexedWaldo}
	^self create: waldo! !XnModel subclass: #WaldoModel
	instanceVariableNames: '
		myWaldo {Waldo}
		myID {ID}
		myWorkType {PackOBits}
		myGrabbed {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
WaldoModel comment:
'A WaldoModel holds onto a kind of waldo and handles changes to it. Subclasses can hold onto particular kinds of waldos and provide messages for changing them that also produce update records. The superclass takes care of: (or will when it''s finished)
-- grabbing and releasing a waldo
-- if it is not grabbed, keeping a sensor on the bert to watch for changes to the document
-- switching the model to a completely different waldo'!

(WaldoModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoModel methodsFor: 'create'!

create
	super create.
	myWaldo _ NULL.
	myID _ NULL.
	myWorkType _ NULL.
	myGrabbed _ false!

create: waldo {Waldo} 
	super create.
	myWaldo _ waldo.
	myID _ waldo fetchID.
	myGrabbed _ (myID == NULL) not.
	myWorkType _ waldo workType!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits default: NULL} with: phantom {BooleanVar default: true}
	super create.
	myWaldo _ NULL.
	myID _ NULL.
	myWorkType _ NULL.
	myGrabbed _ false.
	self setWaldo: id with: worktype with: phantom with: km!

{void} destroy
	"This destroy() member function blocks calls to the model's destructor,
	but does make sure that the bert is released.  This should cause no problems because
	the bert will be regrabbed if necessary."

	self releaseBert!

{void} destruct

	myWaldo destroy.
	myID _ NULL.
	myWorkType _ NULL.
	super destruct! !

!WaldoModel methodsFor: 'accessing'!

{ID} iD
	"the ID of this waldo - if no bert ID yet, grab to create one..."

	myID == NULL ifTrue: [self makeEditable ifFalse: [Heaper BLAST: #NOID].
		self releaseBert].
	^myID!

{KeyMaster} keyMaster
	^ self waldo keyMaster!

{void} setWaldo: id {ID}
		with: workType {PackOBits default: NULL}
		with: phantom {BooleanVar default: true}
		with: km {KeyMaster default: NULL}
	"switch to a different document"
	(myID ~~ NULL and: [(id isEqual: myID)
			and: [workType == NULL or: [myWorkType ~~ NULL and: [myWorkType isEqual: workType]]]])
		ifFalse: [ | old {ID} newWorkType {PackOBits} newKM {KeyMaster} |
			old _ myID.
			workType ~~ NULL ifTrue:
				[myWorkType _ workType].
			myWorkType == NULL
				ifTrue: [newWorkType _ Sequence string: 'Waldo'"  with: true"]
				ifFalse: [newWorkType _ myWorkType].
			km == NULL
				ifTrue: [newKM _ myWaldo keyMaster]
				ifFalse: [newKM _ km].
			"myWaldo _ newKM open: id
				with: newWorkType
				with: (phantom ifTrue: [OpenTemporaryVariant] ifFalse: [OpenOriginalDocument])."
			self unimplemented.
			myID _ id.
			myGrabbed _ phantom not.
			self changed: (SingleReplaceUR make: old with: id)]!

{Waldo} waldo
	myWaldo == NULL ifTrue:
		[Heaper BLAST: #InvalidRequest].
	^myWaldo! !

!WaldoModel methodsFor: 'smalltalk: smalltalk defaults'!

create: km with: id
	^self create: km with: id with: NULL with: true!

create: km with: id with: type
	^self create: km with: id with: type with: true!

setWaldo: id
	self setWaldo: id with: NULL with: true with: NULL!

setWaldo: id with: type
	self setWaldo: id with: type with: true with: NULL!

setWaldo: id with: type with: phantom
	self setWaldo: id with: type with: phantom with: NULL! !

!WaldoModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' myWaldo = ' << myWaldo << '
 	myID = ' << myID << '
 	myWorkType = ' << myWorkType! !

!WaldoModel methodsFor: 'permissions'!

{ScruSet of: ID} editors

	| pm {PermissionsModel} res {ScruSet} |
	pm _ self fetchEditPermissions.
	pm == NULL ifTrue: [^ ImmuSet make].
	res _ pm members.
	pm destroy.
	^ res!

{PermissionsModel} fetchEditPermissions
	"the model controlling the edit permissions for this document"
	"verify the cache is up to date"
	^PermissionsModel fetchPermissionsModel: self waldo keyMaster
						with: (XuServer currentServer editClubIDFor: self iD)!

{PermissionsModel} fetchReadPermissions
	"the model controlling the edit permissions for this document"

	"verify the cache is up to date"
	^PermissionsModel fetchPermissionsModel: self waldo keyMaster
								with: (XuServer currentServer readClubIDFor: self iD)!

{PermissionsModel} getEditPermissions
	"the model controlling the edit permissions for this document"

	| pm {PermissionsModel} |
	pm _ self fetchEditPermissions.
	pm == NULL ifTrue: [Heaper BLAST: #CannotGetEditClub. ^ NULL].
	^ pm!

{PermissionsModel} getReadPermissions
	"the model controlling the read permissions for this document"

	| pm {PermissionsModel} |
	pm _ self fetchReadPermissions.
	pm == NULL ifTrue: [Heaper BLAST: #CannotGetReadClub. ^ NULL].
	^ pm!

{ScruSet of: ID} readers
	| rp {PermissionsModel} res {ScruSet} |
	rp _ self fetchReadPermissions.
	rp == NULL
		ifTrue: [^self editors].
	res _ rp members.
	rp destroy.
	^res asImmuSet unionWith: self editors! !

!WaldoModel methodsFor: 'protected: policy'!

{BooleanVar} bertIsGrabbed

	^ myGrabbed!

{BooleanVar} makeEditable

	"This method attempts to grab the bert... returns false if it fails"
	myGrabbed ifFalse: [
		myID == NULL 
			ifTrue: [
				myWaldo := myWaldo copy: true.
				myID := myWaldo getID.
				^ (myGrabbed := true)]
			ifFalse: [ | nw {Waldo} |
				KeyMaster problems.DocumentInUse
					handle: [ :boom | ^ (myGrabbed := false)]
					do: [nw := myWaldo keyMaster open: myID
						with: myWaldo workType].
				(myWaldo editionID isEqual: nw editionID)
					ifFalse: [nw replaceWith: myWaldo. "hop to the current state"].
						myWaldo := nw]].
	^ (myGrabbed := true)!

{void} releaseBert
	"This method insures that the bert is not held by this model."
	
	| old {Waldo} |
	myGrabbed ifFalse: [^ VOID].
	old _ myWaldo.
	myWaldo _ myWaldo copy: true.
	old destroy.
	myGrabbed _ false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WaldoModel class
	instanceVariableNames: ''!

(WaldoModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoModel class methodsFor: 'pseudo constructors'!

make
	^self create!

make: km {KeyMaster} with: id {ID} with: worktype {PackOBits} with: phantom {BooleanVar}
	^self create: km with: id with: worktype with: phantom! !WaldoModel subclass: #DirectoryModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(DirectoryModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DirectoryModel methodsFor: 'create'!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits} with: phantom {BooleanVar}
	super create: km with: id with: worktype with: phantom! !

!DirectoryModel methodsFor: 'accessing'!

{void} at: name {PackOBits} storeClubID: iD {ID}
	self bertIsGrabbed ifFalse: [self makeEditable].
	self directoryWaldo at: name store: iD!

{ListModel of: ID} clubIDs
	"provide a list of club ids in this directory (suitable for framing)"
	| table {IntegerTable} index {IntegerVar} ids {ScruSet of: ID} |
	index _ IntegerVar0.
	table _ MuArray make.IntegerVar: (ids _ self directoryWaldo clubIDs) count.
	ids stepper forEach: [:id {ID} | 
		table atInt: index introduce: id.
		index _ index + 1].
	^ListModel make: table!

{ListModel of: PackOBits} clubNames
	| table {IntegerTable} index {IntegerVar} names {ScruSet of: PackOBits} |
	index _ IntegerVar0.
	table _ MuArray make.IntegerVar: (names _ self directoryWaldo clubIDs) count.
	names stepper forEach: [:name {PackOBits} | 
		table atInt: index introduce: name.
		index _ index + 1].
	^ListModel make: table!

{ID} fetchClubID: name {PackOBits}
	
	^ self directoryWaldo fetchClubID: name!

{PackOBits} fetchClubName: iD {ID}
	
	^ self directoryWaldo fetchClubName: iD!

{void} removeName: name {PackOBits}
	self bertIsGrabbed ifFalse: [self makeEditable].
	self directoryWaldo wipe: name! !

!DirectoryModel methodsFor: 'protected: accessing'!

{XuDirectory} directoryWaldo
	^ self waldo cast: XuDirectory! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DirectoryModel class
	instanceVariableNames: ''!

(DirectoryModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DirectoryModel class methodsFor: 'make'!

make: keyMaster {KeyMaster} 
	^self create: keyMaster with: NULL with: (Sequence string: 'XuDirectory') with: false!

make: km {KeyMaster} with: id {ID} with: phantom {BooleanVar default: false}

	^ self create: km with: id with: (Sequence string: 'XuDirectory') with: phantom! !

!DirectoryModel class methodsFor: 'smalltalk: make'!

make: km {KeyMaster} with: id {ID}

	^ self create: km with: id with: (Sequence string: 'XuDirectory') with: false! !

!DirectoryModel class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	"self REQUIRES: XuDirectory."! !WaldoModel subclass: #DocumentModel
	instanceVariableNames: 'myContents {XnModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(DocumentModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DocumentModel methodsFor: 'accessing'!

{Int32} compare: a {XnRegion} with: b {XnRegion}
	"compare the two regions according to where they are in the document,
	returning -1, 0, or 1 if a < b, a = b, or a > b respectively"
	self subclassResponsibility!

{XnModel} contents
	"the model for the document contents"
	(myContents ~~ NULL) assert.
	^myContents!

{Waldo} contentsWaldo
	"the sub waldo that holds the document contents
	-- DO NOT MODIFY -- USE MODEL INSTEAD --"
	^self waldo!

{LinkEnd} createLinkEnd: selection {SelectionObject default: NULL}
	"create a new link end on the selected stuff"
	self subclassResponsibility!

{ListModel of: Reference} createReferenceList: filter {VariableModel of: Filter}
	"create and hook up a sorted list of references to this document"
	| set {SetModel of: Reference} list {ListModel of: Reference} |
	set _ SetModel make.
	Filter2ReferencesSchnert make: filter with: self with: set.
	list _ ListModel make.
	ReferenceSorter make: set with: list with: self.
	^list!

{Waldo} name
	^XuText make: self waldo keyMaster with: 'Some document'! !

!DocumentModel methodsFor: 'create'!

create: waldo {Waldo}
	super create: waldo.
	myContents _ NULL!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits default: NULL} with: phantom {BooleanVar default: true} 
	super create: km
		with: id
		with: worktype
		with: phantom! !

!DocumentModel methodsFor: 'protected: protected'!

{void} destruct

	myContents ~~ NULL ifTrue: [myContents destroy].
	super destruct!

{XnModel} fetchContents
	^myContents!

{void} setContents: model {XnModel}
	myContents _ model! !

!DocumentModel methodsFor: 'smalltalk: defaults'!

createLinkEnd
	^self createLinkEnd: NULL! !

!DocumentModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	super printOn: oo.
	oo << '
		myContents = ' << myContents! !DocumentModel subclass: #HomeDocumentModel
	instanceVariableNames: '
		myCachedDirectory {DirectoryModel}
		myCachedList {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(HomeDocumentModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HomeDocumentModel methodsFor: 'create'!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits} with: phantom {BooleanVar}
	super create: km with: id with: worktype with: phantom.
	myCachedDirectory _ NULL.
	myCachedList _ NULL! !

!HomeDocumentModel methodsFor: 'accessing'!

{Int32} compare: a {XnRegion} with: b {XnRegion}
	"compare the two regions according to where they are in the document,
	returning -1, 0, or 1 if a < b, a = b, or a > b respectively"
	self unimplemented.
	^ Int32Zero!

{Waldo} contentsWaldo
	"the sub waldo that holds the document contents"
	^ self waldo!

{LinkEnd} createLinkEnd: selection {SelectionObject default: NULL}
	"create a new link end on the selected stuff"
	self unimplemented.
	^ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HomeDocumentModel class
	instanceVariableNames: ''!

(HomeDocumentModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HomeDocumentModel class methodsFor: 'make'!

make: km {KeyMaster} with: id {ID}
	^self create: km with: id with: (Sequence string: 'XuHomeDocument') with: false!

make: km {KeyMaster} with: id {ID} with: phantom {BooleanVar}
	^self create: km with: id with: (Sequence string: 'XuHomeDocument') with: phantom! !DocumentModel subclass: #OutlineModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(OutlineModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!OutlineModel methodsFor: 'accessing'!

{Int32} compare: a {XnRegion} with: b {XnRegion}
	"compare the two regions according to where they are in the document,
	returning -1, 0, or 1 if a < b, a = b, or a > b respectively"
	self unimplemented.
	^Int32Zero!

{Waldo} contentsWaldo
	"the sub waldo that holds the document contents
	-- DO NOT MODIFY -- USE MODEL INSTEAD --"
	self unimplemented.
	^NULL!

{LinkEnd} createLinkEnd: selection {SelectionObject unused default: NULL}
	"create a new link end on the selected stuff"
	self unimplemented.
	^NULL! !

!OutlineModel methodsFor: 'create'!

create: waldo {Waldo}

	super create: waldo! !DocumentModel subclass: #PassageModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(PassageModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageModel methodsFor: 'accessing'!

{Int32} compare: a {XnRegion} with: b {XnRegion}
	"compare the two regions according to where they are in the document,
	returning -1, 0, or 1 if a < b, a = b, or a > b respectively"
	| x {IntegerRegion} y {IntegerRegion} |
	x _ a quickCast: IntegerRegion.
	y _ b quickCast: IntegerRegion.
	x isEmpty ifTrue:
		[y isEmpty ifTrue: [^ Int0] ifFalse: [^ -1]].
	y isEmpty ifTrue: [^1].
	x isBoundedBelow
		ifTrue: [y isBoundedBelow
			ifTrue: [x start < y start
				ifTrue: [^-1]
				ifFalse: [x start = y start
					ifTrue: [^Int0]
					ifFalse: [^1]]]
			ifFalse: [^1]]
		ifFalse: [y isBoundedBelow
			ifTrue: [^-1]
			ifFalse: [^Int0]]!

{Waldo} contentsWaldo
	"the sub waldo that holds the document contents
	-- DO NOT MODIFY -- USE MODEL INSTEAD --"
	^self xuText!

{LinkEnd} createLinkEnd: selection {SelectionObject default: NULL}
	"create a new link end on the selected stuff"
	| region {XnRegion} |
	(selection == NULL or: [(region _ selection selection) isEmpty])
		ifTrue: [^LinkEnd make: self xuText keyMaster with: self xuText]
		ifFalse: [^LinkEnd make: self xuText keyMaster with: region with: self xuText]!

{void} setWaldo: id {ID}
		with: workType {PackOBits default: NULL}
		with: phantom {BooleanVar default: true}
		with: km {KeyMaster default: NULL}
	super setWaldo: id with: workType with: phantom with: km.
	self fetchContents ~~ NULL ifTrue: [self fetchContents destroy].
	self setContents: (WaldoTextModel attributedTextModel.Text: self xuText)!

{XuText} xuText
	^self waldo cast: XuText! !

!PassageModel methodsFor: 'create'!

create: doc {XuText}
	| contents {WaldoTextModel} |
	super create: doc.
	contents _ (WaldoTextModel attributedTextModel.Text: doc) cast: WaldoTextModel.
	self setContents: contents.! !

!PassageModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
oo<<  self getCategory name << '()'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PassageModel class
	instanceVariableNames: ''!

(PassageModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageModel class methodsFor: 'make'!

make: doc {XuText}
	^self create: doc! !WaldoModel subclass: #PermissionsModel
	instanceVariableNames: '
		myMembersCache {ImmuSet of: PackOBits}
		myCachedName {PackOBits}'
	classVariableNames: '
		MyCantReadPermissions {PermissionsModel} 
		MyPMCache {MuTable of: PermissionsModel} '
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
PermissionsModel comment:
'A model for a ClubManager.
*Eventually, all interactions to read or change permissions should go through this'!

(PermissionsModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionsModel methodsFor: 'create'!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits} with: phantom {BooleanVar}
	super create: km with: id with: worktype with: phantom.
	myMembersCache _ NULL.
	myCachedName _ NULL! !

!PermissionsModel methodsFor: 'accessing'!

{PackOBits} clubName
	"the name used to show the (external) identity of this club"
	| dName {PackOBits} |
	[TapestryAppModel] USES.
	"myCachedName == NULL
		ifTrue: [| dName {PackOBits} |
	dName _ Application fluidVar user userDirectory fetchName: self iD.
	dName ~= NULL
		ifTrue: [myCachedName _ dName]
		ifFalse: [myCachedName _ Sequence string: 'UNKNOWN']].
	^ myCachedName"
	dName _ Application fluidGet user userDirectory fetchName: self iD.
	dName == NULL
		ifTrue: [dName _ Sequence string: 'UNKNOWN'].
	^dName!

{HomeDocumentModel} homeDocument

	^HomeDocumentModel make: self keyMaster 
		with: (self waldo cast: ClubManager) getHomeDocID 
		with: true!

{ScruSet of: PackOBits} memberNames

	| dir {UserDirectoryModel} names {SetAccumulator} |
	
	dir _ Application fluidGet user userDirectory.
	names _ SetAccumulator make.
	self members stepper forEach: [:memberID {ID} | | tName {PackOBits} |
		tName _ dir fetchName: memberID.
		tName ~~ NULL ifTrue: [names step: tName]].
	^ names value cast: ScruSet! !

!PermissionsModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' on (' << (self clubName convert: MuWordArray).
	oo << ')'! !

!PermissionsModel methodsFor: 'membership'!

{void} addAll: members {ScruSet of: ID}

	members stepper forEach: [:memID {ID} |
		self addMember: memID]!

{void} addMember: id {ID}

	self bertIsGrabbed 
		ifFalse: [self makeEditable ifFalse: [Heaper BLAST: #CANNOTGRABBERT]].
	(self waldo cast: ClubManager) addMember: id.
	myMembersCache _ myMembersCache with: id.
	self changed: (NewContentsUpdate make)!

{ScruSet of: ID} members
	[IDSet] USES.
	myMembersCache == NULL 
		ifTrue: [myMembersCache _ (self waldo cast: ClubManager) members asSet].
	^ myMembersCache!

{void} removeMember: id {ID}
 
	self bertIsGrabbed 
		ifFalse: [self makeEditable ifFalse: [Heaper BLAST: #CANNOTGRABBERT]].
	(self waldo cast: ClubManager) removeMember: id.
	myMembersCache _ myMembersCache without: id.
	self changed: (NewContentsUpdate make)!

{ScruSet of: ID} transitiveMembers

	"This method collects all members of this club by walking transitively through
	all readable clubs.  Note that if a club is not readable by the current
	keyMaster, the club will be skipped and its members will not show up.
	We need to provide information (somehow) about which clubs could not be
	read."
	
	^self collectMembersExcept: (ImmuSet make with: self iD)! !

!PermissionsModel methodsFor: 'private: internals'!

{ScruSet of: ID} collectMembersExcept: theseIDs {ScruSet} 
	"This method a set of all of this club's member clubs (recursively). 
	It also ensures that mutually containing clubs don't cause an infinite 
	loop."

	| members {ImmuSet} tbd {ImmuSet} resultUnion {UnionRecruiter} |
	members _ self members cast: ImmuSet.
	tbd _ members minus: theseIDs.
	resultUnion _ UnionRecruiter make.
	resultUnion step: members.
	resultUnion step: theseIDs.
	tbd stepper forEach: [:memberID {ID} | | pm {PermissionsModel} |
		pm _ PermissionsModel fetchPermissionsModel: self waldo keyMaster with: memberID.
		pm ~~ NULL 
			ifTrue: [resultUnion step: 
						(pm collectMembersExcept: (resultUnion value cast: ScruSet)).
					pm destroy]].
	^resultUnion value cast: ScruSet! !

!PermissionsModel methodsFor: 'permissions'!

{ID} editClubID

	^ (self waldo cast: ClubManager) getEditClubID!

{ID} readClubID

	^ (self waldo cast: ClubManager) getReadClubID! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PermissionsModel class
	instanceVariableNames: ''!

(PermissionsModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionsModel class methodsFor: 'safe make'!

{PermissionsModel} fetchPermissionsModel: km {KeyMaster} with: id {ID} 
	| pm {PermissionsModel} |
	pm _ (MyPMCache fetch: id) cast: PermissionsModel.
	pm == NULL ifTrue: [pm _ self fetchPM: km with: id.
		pm == NULL ifFalse: [MyPMCache at: id introduce: pm]].
	^pm! !

!PermissionsModel class methodsFor: 'private: make'!

{PermissionsModel} fetchPM: km {KeyMaster} with: id {ID}

	KeyMaster problems.OpenFailed handle: [:ex {Exception} |
		^ NULL] do: [^ PermissionsModel make: km with: id]!

make: km {KeyMaster} with: id {ID} 
	^ self create: km with: id with: (Sequence string: 'ClubManager') with: true! !

!PermissionsModel class methodsFor: 'smalltalk: initialization'!

cleanupGarbage

	self linkTimeNonInherited!

initTimeNonInherited

	self REQUIRES: IDSpace.
	"MyPMCache _ MuTable make: IDSpace global"!

linkTimeNonInherited

	MyPMCache _ NULL! !AttributedTextModel subclass: #WaldoTextModel
	instanceVariableNames: '
		wrappedText {XuText}
		charCache {MuWordArray}
		cacheWaldo {WordArrayWaldo}
		newTyping {MuWordArray}
		typingStart {IntegerVar}
		typingNext {IntegerVar}'
	classVariableNames: 'BadModelPositionSignal {Exception smalltalk} '
	poolDictionaries: ''
	category: 'FM-Text'!

(WaldoTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class WaldoTextModel */
friend SPTR(AttributedTextModel) attributedTextModel (XuText *);
friend SPTR(WaldoTextModel)  waldoTextModel (XuText * aText);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoTextModel methodsFor: 'accessing'!

{AttributedTextModel} copy: reg {XnRegion}
	"Return an AttributedTextModel for the specified region."
	^ WaldoTextModel create: ((wrappedText copy: false with: reg with: wrappedText keyMaster) cast: XuText)!

{IntegerVar} count
	"return the number of known elements (characters) in the text"

	^self updatedCache count! !

!WaldoTextModel methodsFor: 'text accessing'!

{MuWordArray} asDataTable
	^self updatedCache!

{Heaper} fetch: pos {Position}

	"Return the object at the specified position"
	
	^ self intFetch: (pos cast: IntegerPos) asIntegerVar!

{Heaper} intFetch: pos {IntegerVar} 
	"Return the object at the specified position"

	^self updatedCache intFetch: pos! !

!WaldoTextModel methodsFor: 'attributes'!

{void} applyAttributes: attrs {AttributeGroup unused}
with: region {XnRegion unused}

	self unimplemented!

{ScruTable of: (Pair of: AttributeGroup and: XnRegion)} attributes
	self unimplemented.
	^NULL!

{AttributeGroup} attributesAtInt: pos {IntegerVar
unused} 
	"return the attributes mapped to their corresponding 
	attribute type (as specified in the creation of this
model) 
	for the specified position."
	^AttributedTextModel noAttributes!

{void} removeAttributes: attr {AttributeGroup unused}
with: reg {XnRegion unused}

	self unimplemented!

{XnRegion} runAtInt: pos {IntegerVar} 
	"Return the object at the specified position"
	^IntegerRegion make: pos with: self count! !

!WaldoTextModel methodsFor: 'testing'!

{BooleanVar} isEqual: other {Heaper} 
	^other isKindOf: WaldoTextModel! !

!WaldoTextModel methodsFor: 'manipulating'!

{void} deflate: reg {XnRegion} 
	"remove the specified region"
	| lReg {IntegerRegion} |
	
	lReg _ reg cast: IntegerRegion.
	(newTyping ~~ NULL and: [lReg stop == typingNext])
		ifTrue: [typingNext _ typingNext - 1.
			typingNext > typingStart
				ifTrue: [newTyping _ (newTyping subTableBetween: IntegerVar0 with: newTyping count - 1) cast: MuWordArray]
				ifFalse: [newTyping _ NULL]]
		ifFalse: 
			[self commitInserts.
			wrappedText deflate: lReg].
	charCache == NULL
		ifFalse: 
			[cacheWaldo == NULL ifTrue: 
				[cacheWaldo _ WordArrayWaldo make: charCache].
			cacheWaldo deflate: lReg.
			charCache _ cacheWaldo table cast: MuWordArray].
	self changed: (DeletionUR make: lReg)!

{void} insert: pos {IntegerVar} with: atm {AttributedTextModel} 
	"insert the string before pos" 

	self insertWordArray: pos with: atm asDataTable!

{void} insertCopy: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion} 
	"copy a string from the other text (region cut1 to cut2) to the 
	position pos"

	self commitInserts.
	other 
		cast: WaldoTextModel into: [:wtm |
			wrappedText
				vcopy: pos
				with: (wtm waldo cast: XuText)
				with: reg]
		others: [self insert: pos with: (other copy: reg) asDataTable].
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: (IntegerRegion integerExtent: pos with: reg count)!

{void} insertWordArray: pos {IntegerVar} with: string
{MuWordArray} 
	"insert the string before pos"

	newTyping == NULL
		ifTrue: 
			[typingStart _ pos.
			typingNext _ pos + string count.
			newTyping _ string]
		ifFalse: [pos == typingNext
				ifTrue: [newTyping introduceAll: string with:
(IntegerMapping make: newTyping count) with: NULL.
					typingNext _ typingNext + string count]
				ifFalse: 
					[self commitInserts.
					typingStart _ pos.
					typingNext _ pos + string count.
					newTyping _ string]].
	charCache == NULL
		ifFalse: 
			[cacheWaldo == NULL ifTrue: 
				[cacheWaldo _ WordArrayWaldo make: charCache].
			cacheWaldo insertAll.IntegerVar: pos with: string.
			charCache _ cacheWaldo table cast: MuWordArray].
	self changed: (InsertionUR make: pos integer with: string
count)!

{void} move: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion} 
	"move the text in region reg in other to before pos in me. Remove 
	from other. Equivalent to rearrange if other == this"

	self commitInserts.
	other 
		cast: WaldoTextModel into: [:wtm |
			wrappedText
				move: pos
				with: wtm waldo
				with: reg]
		others: [self insert: pos with: (other copy: reg) asDataTable.
			other deflate: reg].
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: (IntegerRegion make: pos with: pos + reg count)!

{void} rearrangeRegion: pos {IntegerVar} with: reg {XnRegion}
	"move the text between cut1 and cut2 to before pos in me.  i.e. swap two blocks of text"
	
	| lReg {IntegerRegion} |
	self commitInserts.
	lReg _ reg cast: IntegerRegion.
	lReg isSimple ifFalse: [Heaper BLAST: #NotSimpleRegion].
	wrappedText rearrange: pos with: lReg start with: lReg stop.
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: ((IntegerRegion make: pos) simpleUnion: reg)!

{void} replace: reg {XnRegion} with: other {AttributedTextModel} 
	"replaces a region with the the contents of the other model"

	self commitInserts.
	other 
		cast: WaldoTextModel into: [:wtm |
			wrappedText replace: reg
				with: wtm waldo]
		others: 
			[wrappedText replace: reg
				with: (XuText make: wrappedText keyMaster
					with: (other asDataTable asMuTable cast: MuWordArray))].
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: (reg simpleUnion: 
		(IntegerRegion integerExtent: (reg cast: IntegerRegion) start
			with: other count))!

{void} replaceWith: text {XuText}
	"entirely replace the text"
	| old {XnRegion} |
	old _ wrappedText domain.
	wrappedText _ text.
	charCache _ NULL.
	cacheWaldo _ NULL.
	newTyping _ NULL.
	typingStart _ typingNext _ IntegerVar0.
	self changedRegion: (old unionWith: wrappedText domain)!

{void} replaceWithWordArray: reg {XnRegion} with: string {MuWordArray} 
	"replaces the given region with the contents of the string."

	self commitInserts.
	wrappedText replace: reg with: (XuText make: wrappedText keyMaster with: string).
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: (reg simpleUnion: 
		(IntegerRegion integerExtent: (reg cast: IntegerRegion) start
			with: string count))! !

!WaldoTextModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << 'waldo ('.
	charCache == NULL
		ifTrue: [oo << wrappedText]
		ifFalse: [oo << 'cache ' << 
			(charCache subTable: (IntegerRegion make: IntegerVar0 with: 50))].
	oo << ')'! !

!WaldoTextModel methodsFor: 'protected: protected creation'!

create: newText {XuText}
	super create.
	
	wrappedText _ newText.
	charCache _ NULL.
	cacheWaldo _ NULL.
	newTyping _ NULL.!

{void} destruct
	wrappedText _ NULL.
	charCache _ NULL.
	cacheWaldo _ NULL.
	newTyping _ NULL.	
	super destruct! !

!WaldoTextModel methodsFor: 'private: private'!

{void} changedRegion: reg {XnRegion}

	self changed: (RegionUR make: reg).
	^ VOID!

{void} commitInserts
	newTyping == NULL ifTrue: [^ VOID].
	wrappedText insert: typingStart with: newTyping.
	newTyping _ NULL.
	charCache _ NULL.
	cacheWaldo _ NULL!

{MuWordArray} updatedCache
	charCache == NULL ifTrue:
		[self commitInserts.
		charCache _ wrappedText asDataTable asMuTable cast: MuWordArray].
	^charCache!

{XuText} waldo
	^ wrappedText! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WaldoTextModel class
	instanceVariableNames: ''!

(WaldoTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class WaldoTextModel */
friend SPTR(AttributedTextModel) attributedTextModel (XuText *);
friend SPTR(WaldoTextModel)  waldoTextModel (XuText * aText);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoTextModel class methodsFor: 'pseudo constructors'!

{AttributedTextModel} attributedTextModel.Text: aText {XuText}

	^ WaldoTextModel create: aText!

make: aText {XuText}
	^ self create: aText! !SimpleUpdateRecord subclass: #WindowCloseUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!

(WindowCloseUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WindowCloseUpdate methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '()'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WindowCloseUpdate class
	instanceVariableNames: ''!

(WindowCloseUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WindowCloseUpdate class methodsFor: 'make'!

make
	^theRecord cast: self! !SimpleUpdateRecord subclass: #WindowFrontUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!

(WindowFrontUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WindowFrontUpdate methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name  << '()'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WindowFrontUpdate class
	instanceVariableNames: ''!

(WindowFrontUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WindowFrontUpdate class methodsFor: 'make'!

make
	^theRecord cast: self! !XnModel subclass: #WindowModel
	instanceVariableNames: '
		myPinStatus {BooleanModel}
		mySTWindowModel {STTapestryWindowModel smalltalk}
		myXViewWindowModelInternal {XViewWindowModel ifdefXVIEW}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
WindowModel comment:
'Models the behaviour of a generic window, including opening, closing, pinning, and resizing.
Most of the interface to the window system goes in here. Window-system specific code should be written with #ifdef blocks and methods.

		myPinStatus {BooleanModel}
			Whether this window should be included in the trailing window count
		
		mySTWindowModel {STTapestryWindowModel}
			a model for the smalltalk version'!

(WindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!WindowModel methodsFor: 'create'!

create
	super create.
	myPinStatus _ BooleanModel make: false.
	[mySTWindowModel _ NULL] smalltalkOnly.!

{void} destruct

	[mySTWindowModel ~~ NULL ifTrue: [mySTWindowModel destruct].
	mySTWindowModel _ NULL] smalltalkOnly.
	myPinStatus destroy.
	myPinStatus _ NULL.
	super destruct! !

!WindowModel methodsFor: 'window operations'!

{void} bringToFront
	self frontWindow.
	self changed: WindowFrontUpdate make!

{void} close
	self closeWindow.
	self changed: WindowCloseUpdate make!

{void} open 
	Scaffold fluidBind: self scaffold
		during: [self openWindow].
	[UserModel, TapestryAppModel, TableTopModel] USES.
	"Application fluidVar user tableTop addWindow: self"!

{BooleanModel} pinStatus
	^myPinStatus!

{void} resize: area {PointRegion unused}
	"change the location and size of the window"
	self unimplemented! !

!WindowModel methodsFor: 'protected: windowing'!

{void} closeWindow
	"close the window manager window"!

{void} frontWindow
	"bring the window manager window to the front"!

{void} initWindow
	"do any window-systgm specific initialization"
	[self initSmalltalkWindow] smalltalkOnly!

{void} openWindow
	[self openSmalltalkWindow] smalltalkOnly.
	MACINTOSH ifdef:
		[self openMacWindow].
	XVIEW ifdef:
		[self openXViewWindow]! !

!WindowModel methodsFor: 'protected: building'!

{FMScaffold} scaffold
	| table {MuTable of: FMBuilder} |
	table _ MuTable make: HeaperSpace make.
	table at: (HeaperAsPosition make: XuText)
		introduce: TextWaldoBuilder make.
	table at: (HeaperAsPosition make: MuWordArray)
		introduce: WArrayBuilder make.
	table at: (HeaperAsPosition make: AttributedTextModel)
		introduce: STMBuilder make.
	table at: (HeaperAsPosition make: SelectedTextModel)
		introduce: FMTextEditBuilder make.
	^FMScaffold make: table with: Scaffold fluidVar! !

!WindowModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '('
		<< 'myPinStatus'  << myPinStatus.
	[oo << 'mySTWindowModel'  << mySTWindowModel] smalltalkOnly.
	XVIEW ifdef: [oo << 'myXViewWindowModelInternal' <<
					 myXViewWindowModelInternal].! !

!WindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} myXViewWindowModel  
	^myXViewWindowModelInternal!

{void} openXViewWindow
	self subclassResponsibility!

{void} setMyXViewWindowModel: my  {XViewWindowModel}
	myXViewWindowModelInternal _ my! !WindowModel subclass: #DocumentWindowModel
	instanceVariableNames: '
		myReferenceFilter {VariableModel of: TapestryFilter}
		myDocument {DocumentModel}
		myDocumentSelection {SelectionObject}
		myDocumentBuilding {FMBuilding}
		myDocumentScroller {ScrollerSchnert}
		myReferences {ListModel of: Reference}
		myReferencesSelection {SelectionObject}
		myReferencesBuilding {FMBuilding}
		myReferenceBuilder {FMBuilder}
		myReferencesScroller {ScrollerSchnert}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
DocumentWindowModel comment:
'Models the behaviour of a standard Tapestry
document window, in particular the icon bar layout, the
menus,
and the two panes (references and document). Window-system
specific code should be written with #ifdef blocks and
methods.

		myReferenceFilter {VariableModel of: ReferenceFilter}
			The filter used to find references to the document
		myDocument {DocumentModel}
			The document being viewed
		myDocumentSelection {SelectionRange}
			The current selection in the document
		myDocumentBuilding {FMBuilding}
			The FM viewer & controller for the document pane
		myDocumentScroller {ScrollerSchnert}
			The schnert controlling the scrolling of the document
pane
		myReferences {ListModel of: Reference}
			The list of references to the document
		myReferencesSelection {SelectionObject}
			The currently selected references
		myReferencesBuilding {FMBuilding}
			The FM viewer & controller for the references pane
		myReferencesBuilder {FMBuilder}
			The FM builder that creates the viewer/controller for a
single reference
		myReferencesScroller {ScrollerSchnert}
			The schnert controlling the scrolling of the references
pane'!

(DocumentWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DocumentWindowModel methodsFor: 'accessing'!

{DocumentModel} document
	"the document being edited"
	^myDocument!

{FMBuilding} documentBuilding 
	"the View+Controller for the document pane; build if necessary"
	myDocumentBuilding == NULL ifTrue:
		[Scaffold fluidBind: self documentScaffold during:
			[myDocumentBuilding _ Scaffold fluidVar build: self document].
		myDocumentScroller _ ScrollerSchnert make: myDocumentBuilding view].
	^myDocumentBuilding!

{FMScaffold} documentScaffold
	"scaffold to use for building document pane"
	self subclassResponsibility!

{ScrollerSchnert} documentScroller
	"the scroller for the main document"
	^myDocumentScroller!

{SelectionObject} documentSelection
	"the selection in the document being edited"
	^myDocumentSelection!

{FMBuilder} referenceBuilder
	
	^ myReferenceBuilder!

{VariableModel of: TapestryFilter} referenceFilter
	"the current filter used for looking at references"
	^myReferenceFilter!

{ListModel of: Reference} references
	"the current list of references"
	^myReferences!

{FMBuilding} referencesBuilding 
	"the View+Controller for the references pane; build if
necessary"
	myReferencesBuilding == NULL ifTrue:
		[| notifier {NotifierSchnert} | 
			Scaffold fluidBind: self referencesScaffold during:
			[myReferencesBuilding _ Scaffold fluidVar build: self
references].
		myReferencesScroller _ ScrollerSchnert make:
myReferencesBuilding view.
		notifier _ NotifierSchnert make.
		notifier addDependent: (myReferencesBuilding cast:
FMDirectorBuilding) director.
		(myReferenceBuilder cast: FMDeferredBuilder)
builderModel addDependent: notifier].
	^myReferencesBuilding!

{ScrollerSchnert} referencesScroller
	"the scroller for the references pane"
	^myReferencesScroller!

{SelectionObject} referencesSelection
	"the selected references"
	^myReferencesSelection! !

!DocumentWindowModel methodsFor: 'protected: operations'!

{void} attachNote: type {ID} with: swapped {Boolean} with: permissions {ID} with: outline {Boolean}
	"create a note and attach it to the current selection with a link"
	| note {DocumentModel} a {LinkEnd} b {LinkEnd} |
	self hack. "ignores permissions"
	outline
		ifTrue: [note _ Application fluidVar createOutline: permissions]
		ifFalse: [note _ Application fluidVar createPassage].
	a _ self createLinkEnd.
	b _ note createLinkEnd.
	swapped ifTrue: [ | t {LinkEnd} | t _ a. a _ b. b _ t].
	Application fluidVar createLink: a with: b with: type with: permissions.
	Application fluidVar openWindow: note!

{LinkEnd} createLinkEnd
	"create a link end on the current document with the current selection"
	^self document createLinkEnd: self documentSelection! !

!DocumentWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow
	"create a corresponding smalltalk window object"
	self subclassResponsibility!

{void} openSmalltalkWindow
	mySTWindowModel open! !

!DocumentWindowModel methodsFor: 'private: building'!

{FMScaffold} referencesScaffold
	"scaffold to use for building references pane"
	| builder {MuTable of: FMBuilder} |

	builder _ MuTable make: HeaperSpace make.
	builder at: (HeaperAsPosition make: ListModel) introduce:
(ReferenceListBuilder make: self).
	builder at: (HeaperAsPosition make: Reference) introduce:
myReferenceBuilder.
	^FMScaffold make: builder with: Scaffold fluidVar! !

!DocumentWindowModel methodsFor: 'protected:
create/destruct'!

create: document {DocumentModel} 
	super create.
	[UserModel] USES.
	myReferenceFilter _ "VariableModel make: Application fluidVar user defaultFilter getValue"
			NULL .
	myDocument _ document.
	myDocumentSelection _ NULL.
	"setup from subclass constructor"
	myDocumentScroller _ NULL.
	myDocumentBuilding _ NULL.
	myReferences _ "myDocument createReferenceList: myReferenceFilter" ListModel make.
	myReferencesSelection _ ListSelection make: IntegerRegion make.
	myReferenceBuilder _ FMDeferredBuilder make: Application fluidVar user defaultReferencesStyle.
	myReferencesScroller _ NULL.
	myReferencesBuilding _ NULL.
	Refs2DocSelectionSchnert make: self.
	List2SelectionSchnert make: myReferences with: myReferencesSelection!

{void} destruct
	myReferenceFilter destroy.
	myReferenceFilter _ NULL.
	myDocument _ NULL.
	myDocumentSelection _ NULL.
	myDocumentScroller _ NULL.
	myDocumentBuilding _ NULL.
	myReferences destroy.
	myReferences _ NULL.
	myReferencesSelection destroy.
	myReferencesSelection _ NULL.
	myReferencesScroller _ NULL.
	myReferencesBuilding _ NULL.
	super destruct! !

!DocumentWindowModel methodsFor: 'protected: setup'!

{void} setDocumentSelection: selection {SelectionObject}
	"set up from subclass constructor"
	myDocumentSelection _ selection! !

!DocumentWindowModel methodsFor: 'xview: windowing'!

{void} openXViewWindow
self myXViewWindowModel open! !

!DocumentWindowModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	super printOn: oo.
	oo	<< 'myReferenceFilter' << myReferenceFilter  
		<< 'myDocument'  << myDocument 
		<< 'myDocumentSelection'  << myDocumentSelection  
		<< 'myDocumentBuilding'  << myDocumentBuilding  
		<< 'myDocumentScroller' << myDocumentScroller
		<< 'myReferences'  << myReferences 
		<< 'myReferencesSelection'  << myReferencesSelection
		<< 'myReferencesBuilding'  << myReferencesBuilding 
		<< 'myReferencesScroller' << myReferencesScroller! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DocumentWindowModel class
	instanceVariableNames: ''!

(DocumentWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DocumentWindowModel class methodsFor: 'pseudoConstructors'!

{FMBuilder} defaultReferenceBuilder
	^ TwoLineReferenceBuilder make! !DocumentWindowModel subclass: #PassageWindowModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
PassageWindowModel comment:
'A window for showing passages (TextDocs) '!

(PassageWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageWindowModel methodsFor: 'create'!

create: document {DocumentModel}
	super create: document.
	self setDocumentSelection: SelectionRange make.
	[mySTWindowModel _ self createSmalltalkWindow] smalltalkOnly.
	XVIEW ifdef: [ self setMyXViewWindowModel:  self createXViewWindow].! !

!PassageWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow
	"create a corresponding smalltalk window object"
	^XViewPassageWindowModel create: self!

{XViewWindowModel} createXViewWindow: tBuild {FMBuilding} with: lBuild{FMBuilding}
	"create a corresponding smalltalk window object"
	^XViewPassageWindowModel create: self! !

!PassageWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow
	"create a corresponding smalltalk window object"
	^STPassageWindowModel create: self! !

!PassageWindowModel methodsFor: 'accessing'!

{FMScaffold} documentScaffold
	"scaffold to use for building document pane"
 
	^FMScaffold
		make: PassageModel
		with: (PassageBuilder make: (self documentSelection cast: SelectionRange))
		with: Scaffold fluidVar! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PassageWindowModel class
	instanceVariableNames: ''!

(PassageWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageWindowModel class methodsFor: 'pseudoConstructors'!

make: passage {PassageModel}
	^self create: passage! !WindowModel subclass: #LinkMakerWindowModel
	instanceVariableNames: '
		myEndList {ListModel of: LinkEnd}
		myEndListSelection {SelectionObject}
		myCurrentEditors {ListModel of: ID}
		myCurrentReaders {ListModel of: ID}
		myCurrentEndDescription {AttributedTextModel}
		myCurrentFromEndSet {ListModel of: LinkEnd}
		myCurrentTooEndSet {ListModel of: LinkEnd}
		myCurrentLinkType {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
LinkMakerWindowModel comment:
'This is the FM representation of a link maker
window.  This model is responsible for coordinating the
efforts and actions of the various components of the
window.'!

(LinkMakerWindowModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkMakerWindowModel */
friend SPTR(LinkMakerWindowModel)  linkMakerWindowModel
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkMakerWindowModel methodsFor: 'private: creation'!

create
	super create.
	[mySTWindowModel _ self createSmalltalkWindow]
smalltalkOnly.
XVIEW ifdef: [ self setMyXViewWindowModel:  self createXViewWindow].
	myEndList _ Application fluidVar linkEnds descriptionList.
	myCurrentEndDescription _ NULL.
	myCurrentEditors _ NULL.
	myCurrentReaders _ NULL.
	myCurrentLinkType _ (self linkTypes asTable
intFetch: IntegerVar0) cast: ID.
	myCurrentFromEndSet _ ListModel make.
	myCurrentFromEndSet addDependent: self.
	myCurrentTooEndSet _ ListModel make.
	myCurrentTooEndSet addDependent: self.
	myEndListSelection _ SelectionRange make.
	myEndListSelection addDependent: self.
	List2SelectionSchnert make: myEndList with:
myEndListSelection.
	EndList2DescriptionListSchnert make: Application fluidVar
linkEnds with: myEndList!

{void} destruct

	myCurrentFromEndSet removeDependent: self.
	myCurrentTooEndSet removeDependent: self.
	myEndListSelection removeDependent: self.
	myEndList _ NULL.
	myEndListSelection _ NULL.
	myCurrentFromEndSet _ NULL.
	myCurrentTooEndSet _ NULL.
	myCurrentEndDescription _ NULL.
	myCurrentEditors _ NULL.
	myCurrentReaders _ NULL.
	myCurrentLinkType _ NULL.
	super destruct! !

!LinkMakerWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewLinkMakerWindowModel create: self!

{void} openXViewWindow
self myXViewWindowModel open! !

!LinkMakerWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^STLinkMakerWindowModel create: self!

{void} openSmalltalkWindow

	mySTWindowModel open! !

!LinkMakerWindowModel methodsFor: 'accessing'!

{AttributedTextModel} currentEndDescription
	myCurrentEndDescription == NULL
		ifTrue: [^AttributedTextModel make.WordArray: (MuWordArray make.charVector: '')]
		ifFalse: [^myCurrentEndDescription]!

{ListModel of: ID} editors

	^ myCurrentEditors!

{ListModel of: LinkEnd} endList
	^myEndList!

{FMBuilding} fromEndBuilding 
	 [FMResourceManager] USES.
	XVIEW ifndef: [^ FMBuilding make: (FormViewer make: (Resources fluidVar
fetchImage: 'End0')) with: NULL]. 
XVIEW ifdef: [^ FMBuilding make: (FormViewer make: NULL) with: NULL].!

{ListModel of: LinkEnd} fromEnds

	^ myCurrentFromEndSet!

{ListModel of: ID} linkTypes
	"This method returns a listmodel of link types"
	[TapestryAppModel, UserModel] USES.
	^ Application fluidVar user linkTypes!

{ListModel of: ID} readers

	^ myCurrentReaders!

{SelectionObject} selectedEnds

	^ myEndListSelection!

{FMBuilding} tooEndBuilding 

XVIEW ifndef: [	^ FMBuilding make: (FormViewer make: (Resources fluidVar
fetchImage: 'End0')) with: NULL].
XVIEW ifndef: [	^ FMBuilding make: (FormViewer make: NULL) with: NULL].!

{ListModel of: LinkEnd} tooEnds

	^ myCurrentTooEndSet!

{ListModel of: AttributedTextModel} users
	"This method returns a listmodel of user names as 
	attributedtextmodels, ready for display as a list of names."

	| nameList {ListModel of: PackOBits} newATMs {Accumulator} |
	[Converter] USES.
	nameList _ Application fluidVar user userDirectory clubNames.
	newATMs _ MuArray arrayAccumulator.
	nameList stepper forEach: [:name {PackOBits} | 
		newATMs step: (AttributedTextModel make.WordArray: (name convert: MuWordArray))].
	^ListModel make: (newATMs value cast: IntegerTable)! !

!LinkMakerWindowModel methodsFor: 'buildings'!

{FMBuilding} currentEndBuilding 
	| eb {FMBuilding} |
	Scaffold fluidBind: self scaffold during: [eb _ Scaffold fluidVar build: self currentEndDescription].
	^eb!

{FMBuilding} endlistBuilding 
	| eb {FMBuilding} mcs {Accumulator} msv {MultiSelectionViewer} |
	Scaffold fluidBind: self listScaffold during: [eb _ Scaffold fluidVar build: self endList].
	myEndListSelection _ ListSelection make: IntegerRegion make.
	myEndListSelection addDependent: self.
	mcs _ MuArray arrayAccumulator.
	eb controller ~~ NULL ifTrue: [mcs step: eb controller].
	mcs step: (MultiSelectionController make: eb view with: myEndListSelection).
	"[mcs step: (ClickAction make: (TranscriptThunk make: 'end list selection: ' with: myEndListSelection))] smalltalkOnly."
	msv _ MultiSelectionViewer make: eb view
				with: myEndListSelection
				with: (VariableModel make: HighlightAll make).
	^FMBuilding make: msv with: (SelectionGate make: eb view with: (MultiController make: (mcs value cast: ScruTable)))!

{FMScaffold} listScaffold 
	| table {MuTable of: FMBuilder} layout {AbstractLayout} |
	layout _ ExtentLayout make: (PointPos make: 2000 with: 12). "This'll do fer now. fix"
	table _ MuTable make: HeaperSpace make.
	table at: (HeaperAsPosition make: AttributedTextModel) introduce: (FMTextBuilder make: layout).
	table at: (HeaperAsPosition make: ListModel)
		introduce: (FMDirectedListBuilder make: (BoundingListComp make: ListStyle defaultVertical)).
	^FMScaffold make: table with: Scaffold fluidVar! !

!LinkMakerWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel}

	(myEndListSelection basicCast: XnModel) == sender 
		ifTrue: [
		myEndListSelection selection isEmpty
			ifTrue: [myCurrentEndDescription _ NULL]
			ifFalse: [myCurrentEndDescription _ (myEndList fetch:
						((myEndListSelection selectionPoint cast: IntegerPos)
							asIntegerVar)) cast: AttributedTextModel].
		self changed: (RegionUR make: (Sequence string: 'CurrentEnd') asRegion)].
	(myCurrentFromEndSet basicCast: XnModel) == sender
		ifTrue: [self changed: (RegionUR make: (Sequence string: 'FromEnds')  asRegion)].
	(myCurrentTooEndSet basicCast: XnModel) == sender
		ifTrue: [self changed: (RegionUR make: (Sequence string: 'TooEnds')  asRegion)]! !

!LinkMakerWindowModel methodsFor: 'actions'!

{void} clearAll

	myCurrentFromEndSet wipe: myCurrentFromEndSet domain.
	myCurrentTooEndSet wipe: myCurrentTooEndSet domain.
	myEndListSelection select: IntegerRegion make.!

{void} linkTypeChoice: index {IntegerVar} 
	"This method receives the index in the linkTypesList for
the selected 
	link type."

	myCurrentLinkType _ (self linkTypes fetch: index) cast:
ID.!

{void} makeFromEnd

	| realEnds {LinkEndsModel} |
	[TapestryAppModel] USES.
	myEndListSelection selection isEmpty ifTrue: [^ VOID].
	realEnds _ Application fluidVar linkEnds.
	myEndListSelection selection stepper forEach: [:pos
{IntegerPos} |
		myCurrentFromEndSet insert: (myCurrentFromEndSet count)
with: (realEnds fetch: pos asIntegerVar)].
	^ VOID!

{void} makeLink

	(myCurrentFromEndSet isEmpty and: [myCurrentFromEndSet isEmpty])
		ifTrue: [^ VOID].
	
	IntegerVar0 almostTo: myCurrentFromEndSet count do: [:fromIdx {IntegerVar} | | from {LinkEnd} |
		from _ (myCurrentFromEndSet fetch: fromIdx) cast: LinkEnd.
		IntegerVar0 almostTo: myCurrentTooEndSet count do: [:tooIdx {IntegerVar} | | to {LinkEnd} |
			to _ (myCurrentTooEndSet fetch: tooIdx) cast: LinkEnd.
			Application fluidVar createLink: from with: to with: myCurrentLinkType with: NULL]]!

{void} makeTooEnd

	| realEnds {LinkEndsModel} |
	myEndListSelection selection isEmpty ifTrue: [^ VOID].
	realEnds _ Application fluidVar linkEnds.
	myEndListSelection selection stepper forEach: [:pos
{IntegerPos} |
		myCurrentTooEndSet insert: (myCurrentTooEndSet count)
with: (realEnds fetch: pos asIntegerVar)].
	^ VOID! !

!LinkMakerWindowModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	super printOn: oo.
	oo	<< 'myEndList'  << myEndList
		<< 'myEndListSelection'  << myEndListSelection  
		<< 'myCurrentEditors' << myCurrentEditors 
		<< 'myCurrentReaders'  << myCurrentReaders
		<< 'myCurrentEndDescription'  << myCurrentEndDescription 
		<< 'myCurrentFromEndSet'  << myCurrentFromEndSet 
		<< 'myCurrentTooEndSet'  << myCurrentTooEndSet  
		<< 'myCurrentLinkType'  << myCurrentLinkType << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkMakerWindowModel class
	instanceVariableNames: ''!

(LinkMakerWindowModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkMakerWindowModel */
friend SPTR(LinkMakerWindowModel)  linkMakerWindowModel
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkMakerWindowModel class methodsFor: 'pseudoConstructors'!

make
	^ self create! !WindowModel subclass: #LoginWindowModel
	instanceVariableNames: '
		myResultKeyMaster {VariableModel of: KeyMaster}
		myUDM {UserDirectoryModel}
		mySelection {SelectionObject}
		myClubListPane {FMBuilding}
		mySelectedClub {VariableModel of: PackOBits}
		myLock {VariableModel of: Lock}
		myIDList {ListModel of: PackOBits}
		myNameList {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!
LoginWindowModel comment:
'This window model is used for maintaining a login pane.  It uses a UDM to provide a list of names (this is normally the public UDM).  It then allows the user to select an id to login to and to provide the correct authentication.'!

(LoginWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LoginWindowModel methodsFor: 'create'!

create: km {KeyMaster} with: kmModel {VariableModel of: KeyMaster} with: udm {UserDirectoryModel}
	|tmp {Int32}|
	super create.
	
	[XView] USES. 
	
	
	myResultKeyMaster _ kmModel.
	myUDM _ udm.
	mySelection _ ListSelection make: (IntegerRegion make).
	mySelection addDependent: self.
	myLock _ VariableModel make.
	cerr << 'mySelection = ' << mySelection << 'in create: LoginWindowModel'.
	mySelectedClub _ VariableModel make.
	ID2LockSchnert make: km with: mySelectedClub with: myLock.
	myClubListPane _ self makeCLPane.
	[mySTWindowModel _ self createSmalltalkWindow] smalltalkOnly.
	XVIEW ifdef: [
	["cxx:   
	setBaseWindow (tmp  = (Xv_opaque)xv_create(NULL,FRAME,FRAME_LABEL,""fake base"",0));
	 
	//setBaseWindow (tmp  =NULL);"] translateOnly.
	
	
	 self setMyXViewWindowModel:  (self createXViewWindow )].! !

!LoginWindowModel methodsFor: 'accessing'!

{ID} fetchID

	^ mySelectedClub fetchValue cast: ID!

{KeyMaster} fetchKeyMaster
	^ myResultKeyMaster fetchValue cast: KeyMaster!

{Lock} fetchLock

	^ myLock fetchValue cast: Lock!

{VariableModel of: Lock} lockVar

	^ myLock!

{ListModel} nameList  
	^ myNameList!

{SelectionObject} selection  
^ mySelection! !

!LoginWindowModel methodsFor: 'actions'!

{void} boo
	"Attempt a boo login"

	| newKM {KeyMaster} |
	self fetchLock == NULL ifTrue: [^VOID].
	newKM _ (self fetchLock cast: BooLock) boo.
	newKM == NULL ifTrue: [^VOID].
	myResultKeyMaster setValue: newKM!

{void} match: password {PackOBits} 
	"Attempt a match login"

	| newKM {KeyMaster} |
	self fetchLock == NULL ifTrue: [^VOID].
	newKM _ (self fetchLock cast: MatchLock) password: password.
	newKM == NULL ifTrue: [^VOID].
	myResultKeyMaster setValue: newKM! !

!LoginWindowModel methodsFor: 'windows'!

{FMBuilding} listBuilding
	^myClubListPane! !

!LoginWindowModel methodsFor: 'private: creations'!

{FMBuilding} makeCLPane 
	| nameList {ListModel} lpm {ListPaneModel} bld {FMBuilding} newTab {TableAccumulator} |
	[ImmuSet] USES.
	[Converter] USES.
	newTab _ TableAccumulator make.
	myUDM allIDs stepper forEach: [:id {ID} | newTab step: id].
	myIDList _ ((newTab value cast: ScruTable) asMuTable) convert: ListModel.
	nameList _ ListModel make. 
	List2ListLookupSchnert
		make: myIDList
		with: nameList
		with: (ID2ClubNameLookup make: myUDM).
	lpm _ ListPaneModel make: nameList with: mySelection.
	Scaffold fluidBind: self scaffold during: [bld _ Scaffold fluidVar build: lpm].
	myNameList _ nameList.
	^bld!

{FMScaffold} scaffold 
	| scafTab {MuTable of: FMBuilder} layout {AbstractLayout} |
	layout _ ExtentLayout make: (PointPos make: 2000 with: 12). "This'll do fer now. fix"
	scafTab _ MuTable make: HeaperSpace make.
	scafTab at: (HeaperAsPosition make: UInt8Array)
		introduce: PackOBuilder make.
	scafTab at: (HeaperAsPosition make: AttributedTextModel) 
		introduce: (FMTextBuilder make: layout).
	scafTab at: (HeaperAsPosition make: ListModel)
		introduce: (FMDirectedListBuilder make: 
						(BoundingListComp make: ListStyle defaultVertical)).
	scafTab at: (HeaperAsPosition make: ListPaneModel)
		introduce: (LPMBuilder make: (VariableModel make: HighlightAll make)).
	^FMScaffold make: scafTab with: Scaffold fluidVar! !

!LoginWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow

	"create a corresponding smalltalk window object"
	^STLoginWindowModel create: self!

{void} openSmalltalkWindow

	mySTWindowModel open! !

!LoginWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	mySelection selection count == 1 ifFalse: [^ VOID].
	cerr << 'my selection = ' << mySelection << 'mySelectionPoint' <<mySelection selectionPoint << 'cast to XuInteger' << (mySelection selectionPoint cast: IntegerPos) << ' foo \n'.
	mySelectedClub setValue: 
		(myIDList fetch: (mySelection selectionPoint cast: IntegerPos) asIntegerVar).! !

!LoginWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewLoginWindowModel create: self!

{void} openXViewWindow
	((self myXViewWindowModel) cast: XViewLoginWindowModel) open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LoginWindowModel class
	instanceVariableNames: ''!

(LoginWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LoginWindowModel class methodsFor: 'make'!

make: km {KeyMaster} with: kmModel {VariableModel of: KeyMaster} with: udm {UserDirectoryModel}

	^ self create: km with: kmModel with: udm! !WindowModel subclass: #PermissionWindowModel
	instanceVariableNames: '
		myReadPermissionsModel {PermissionsModel}
		myEditPermissionsModel {PermissionsModel}
		myDirectory {UserDirectoryModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!

(PermissionWindowModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class PermissionWindowModel */
friend SPTR(PermissionWindowModel)  permissionWindowModel (PermissionsModel * edit, PermissionsModel * read, WaldoModel * doc, UserDirectoryModel * ud);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionWindowModel methodsFor: 'accessing'!

{ListModel of: PackOBits} clubNames

	^ myDirectory clubNames!

{FMBuilding} permissionsListBuilding 
	| build {FMBuilding} |
	Scaffold fluidBind: self scaffold during: [
		build _ Scaffold fluidVar build: self permissionsPair].
	^ build!

{Pair of: PermissionsModel and: PermissionsModel} permissionsPair
	^ Pair make: myEditPermissionsModel with: myReadPermissionsModel! !

!PermissionWindowModel methodsFor: 'private: create'!

create: onEdit {PermissionsModel} with: onRead {PermissionsModel} with: document {WaldoModel} with: userDir {UserDirectoryModel}

	super create.
	[mySTWindowModel _ self createSmalltalkWindow] smalltalkOnly.
	XVIEW ifdef: [ self setMyXViewWindowModel:  self createXViewWindow].
	myEditPermissionsModel _ onEdit.
	myReadPermissionsModel _ onRead.
	myDirectory _ userDir!

{void} destruct
	"The permissions models are destroyed here as the only logical place... i hope..."
	myEditPermissionsModel destroy.
	myReadPermissionsModel destroy.
	myDirectory _ NULL.
	super destruct! !

!PermissionWindowModel methodsFor: 'private: setup'!

{FMScaffold} scaffold
	^FMScaffold
		make: Pair
		with: (PermissionsBuilder make: myDirectory)
		with: super scaffold! !

!PermissionWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow
	"PermissionsWindowModel create open"
	"create a corresponding smalltalk window object"

	^STPermissionsWindowModel create: self!

{void} openSmalltalkWindow

	mySTWindowModel open! !

!PermissionWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel unused}

	self changed: ur! !

!PermissionWindowModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	super printOn: oo.
	oo	<< '
	myReadPermissionsModel: ' << myReadPermissionsModel
		<< '
	myEditPermissionsModel: ' << myEditPermissionsModel
		<< '
	myUserDirectory: ' << myDirectory! !

!PermissionWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewPermissionWindowModel create: self!

{void} openXViewWindow
	self myXViewWindowModel open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PermissionWindowModel class
	instanceVariableNames: ''!

(PermissionWindowModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class PermissionWindowModel */
friend SPTR(PermissionWindowModel)  permissionWindowModel (PermissionsModel * edit, PermissionsModel * read, WaldoModel * doc, UserDirectoryModel * ud);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PermissionWindowModel class methodsFor: 'make'!

make: edit {PermissionsModel} with: read {PermissionsModel} with: doc {WaldoModel} with: ud {UserDirectoryModel}

	^ self create: edit with: read with: doc with: ud! !WindowModel subclass: #UDMWindowModel
	instanceVariableNames: '
		myUDM {UserDirectoryModel}
		mySelection {SelectionObject}
		myClubListPane {FMBuilding}
		myClubManagerPane {ClubManagerPaneModel}
		mySelectedClub {VariableModel of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(UDMWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UDMWindowModel methodsFor: 'creation'!

create: onUDM {UserDirectoryModel} with: sel {SelectionObject}
	super create.
	[mySTWindowModel _ STUDMWindowModel create: self] smalltalkOnly.
	XVIEW ifdef: [ self setMyXViewWindowModel:  self createXViewWindow].
	myUDM _ onUDM.
	mySelection _ sel.
	myClubListPane _ NULL.
	mySelection addDependent: self.
	mySelectedClub _ VariableModel make.
	myClubManagerPane _ ClubManagerPaneModel create: myUDM with: mySelectedClub.!

{void} destruct

	self close.
	myClubListPane destroy.
	myClubListPane _ NULL.
	myClubManagerPane destroy.
	myClubManagerPane _ NULL.
	mySelectedClub destroy.
	mySelectedClub _ NULL.
	super destruct! !

!UDMWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow

	"UDMWindowModel create open"
	"create a corresponding smalltalk window object"
	^STUDMWindowModel create: self!

{void} openSmalltalkWindow

	mySTWindowModel open! !

!UDMWindowModel methodsFor: 'accessing'!

{ClubManagerPaneModel} clubManagerPane

	^ myClubManagerPane!

{SelectionObject} selection
	^ mySelection!

{UserDirectoryModel} userDirectoryModel
	^ myUDM! !

!UDMWindowModel methodsFor: 'buildings'!

{FMScaffold} listScaffold 
	| scafTab {MuTable of: FMBuilder} layout {AbstractLayout} |
	layout _ ExtentLayout make: (PointPos make: 2000 with: 12). "This'll do fer now. fix"
	scafTab _ MuTable make: HeaperSpace make.
	scafTab at: (HeaperAsPosition make: UInt8Array)
		introduce: PackOBuilder make.
	scafTab at: (HeaperAsPosition make: AttributedTextModel) 
		introduce: (FMTextBuilder make: layout).
	scafTab at: (HeaperAsPosition make: ListModel)
		introduce: (FMDirectedListBuilder make: 
						(BoundingListComp make: ListStyle defaultVertical)).
	^FMScaffold make: scafTab with: Scaffold fluidVar!

{FMBuilding} udmListBuilding 
	myClubListPane == NULL 
		ifTrue: [Scaffold fluidBind: self listScaffold during: 
			[myClubListPane _ LPMBuilder make build: 
				(ListPaneModel make: myUDM clubNames with: mySelection)]].
	^myClubListPane! !

!UDMWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}
 
	(sender == (myClubManagerPane basicCast: XnModel))
		ifTrue: [(ur isKindOf: WindowCloseUpdate)
			ifTrue: [myClubManagerPane _ NULL]]
		ifFalse: [(sender == (mySelection basicCast: XnModel))
			ifTrue: [self updateFromSelection]]! !

!UDMWindowModel methodsFor: 'window operations'!

{void} close

	mySelection _ NULL.
	myUDM _ NULL.
	super close! !

!UDMWindowModel methodsFor: 'private: updating'!

{void} updateFromSelection

	| pos {IntegerVar} id {ID} |
	mySelection selection count = 1 
		ifTrue: [pos _ (mySelection selection theOne cast: IntegerPos) asIntegerVar.
			id _ (myUDM clubIDs fetch: pos) cast: ID.
			mySelectedClub setValue: id]
		ifFalse: [mySelectedClub setValue: NULL]! !

!UDMWindowModel methodsFor: 'actions'!

{void} deleteClub
	"This deletes a club from the directory, rather than just removing it 
	from the list of clubs in the menu"!

{void} newClub

	| nuClub {PermissionsModel} clubList {ListModel} |
	[TapestryAppModel] USES.
	((myClubManagerPane namePack isEqual: (Sequence string: ''))
		or: [(myUDM fetchLocalClubID: myClubManagerPane namePack) ~~ NULL])
		ifTrue: [Heaper BLAST: #ClubNameAlreadyExists. ^ VOID].
	nuClub _ Application fluidVar makeUserClub: (Application fluidVar user keyMaster).
	clubList _ myUDM clubIDs.
	myUDM at: myClubManagerPane namePack storeClubID: nuClub iD.
	clubList insert: clubList count with: nuClub iD.
	nuClub destroy.!

{void} rearrangeList: distance {IntegerVar} 
	| ul {ListModel} dSel {XnRegion} cut1 {IntegerVar} cut2 {IntegerVar} cut3 {IntegerVar} |
	ul _ myUDM clubIDs.
	dSel _ mySelection selection.
	dSel simpleRegions forEach: [:sr {IntegerRegion} | 
			cut1 _ sr start.
			cut2 _ sr stop.
			distance > IntegerVar0
				ifTrue: [cut3 _ cut2 + distance]
				ifFalse: 
					[cut3 _ cut2.
					cut2 _ cut1.
					cut1 _ cut1 + distance].
			cut1 < IntegerVar0 ifTrue: [cut1 _ IntegerVar0].
			cut3 > ul count ifTrue: [cut3 _ ul count].
			ul rearrange: cut1 with: cut2 with: cut3]!

{void} removeClub
	| dSel {XnRegion} ul {ListModel} |
	dSel _ mySelection selection.
	ul _ myUDM clubIDs.
	dSel isEmpty ifTrue: [^VOID].
	mySelectedClub setValue: NULL.
	ul wipe: dSel!

{void} renameClub

	| cID {ID} |
	(cID _ mySelectedClub fetchValue cast: ID) == NULL ifTrue: [^ VOID].
	((myClubManagerPane namePack isEqual: (Sequence string: ''))
		or: [(myUDM fetchLocalClubID: myClubManagerPane namePack) ~~ NULL])
		ifTrue: [Heaper BLAST: #ClubNameAlreadyExists. ^ VOID].
	
	myUDM at: myClubManagerPane namePack storeClubID: cID! !

!UDMWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewUDMWindowModel create: self!

{void} openXViewWindow
self myXViewWindowModel open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UDMWindowModel class
	instanceVariableNames: ''!

(UDMWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UDMWindowModel class methodsFor: 'make'!

make: onUDM {UserDirectoryModel} with: sel {SelectionObject default: NULL}

	sel == NULL	
		ifTrue: [^ self create: onUDM with: (ListSelection make: IntegerRegion make)]
		ifFalse: [^ self create: onUDM with: sel]! !

!UDMWindowModel class methodsFor: 'smalltalk: make'!

make: onUDM {UserDirectoryModel}
	^ self make: onUDM with: NULL! !WindowModel subclass: #UserListWindowModel
	instanceVariableNames: '
		myULPM {ListPaneModel}
		mySelection {SelectionObject}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(UserListWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserListWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewUserListWindowModel create: self!

{void} openXViewWindow
self myXViewWindowModel open! !Converter subclass: #XnText2ATM
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Text'!

(XnText2ATM getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XnText2ATM methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	
	| myText {XuText} |
	myText _ value basicCast: XuText.
	^ WaldoTextModel make: myText! !

!XnText2ATM methodsFor: 'creation'!

create
	"super create: XuText with: AttributedTextModel"! !
(CxxSystemOrganization fileNamed: 'appmods')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'appmods')
	addClass: TapestryAppModel
getOrMakeCxxClassDescription in: #public;
	addClass: Reference
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'appmods')
	addClass: LoginSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: LinkReference
getOrMakeCxxClassDescription in: #private;
	addClass: VariantReference
getOrMakeCxxClassDescription in: #private!


(CxxSystemOrganization getOrMakeFileNamed: 'appmods')
	addClass: TapestryTester
getOrMakeCxxClassDescription in: #test!

(CxxSystemOrganization fileNamed: 'docmodl')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'docmodl')
	addClass: WaldoListModel
getOrMakeCxxClassDescription in: #public;
	addClass: WaldoModel
getOrMakeCxxClassDescription in: #public;
	addClass: DocumentModel
getOrMakeCxxClassDescription in: #public;
	addClass: HomeDocumentModel
getOrMakeCxxClassDescription in: #public;
	addClass: PassageModel
getOrMakeCxxClassDescription in: #public;
	addClass: OutlineModel
getOrMakeCxxClassDescription in: #public;
	addClass: DirectoryModel
getOrMakeCxxClassDescription in: #public;
	addClass: PermissionsModel
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'docmodl')
	addClass: ReferenceSorter
getOrMakeCxxClassDescription in: #private;
	addClass: TextDoc2PassageModel
getOrMakeCxxClassDescription in: #private;
	addClass: Filter2ReferencesSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: Waldo2SubTextSchnert
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'filters')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'filters')
	addClass: FilterStream
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'filters')
	addClass: EndorsedBackfollowFilter
getOrMakeCxxClassDescription in: #private;
	addClass: EndorsementFilter
getOrMakeCxxClassDescription in: #private;
	addClass: EndorsedBFIDFilter
getOrMakeCxxClassDescription in: #private;
	addClass: UniqueFilter
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'linkmkr')
	comment: ''!

(CxxSystemOrganization getOrMakeFileNamed: 'linkmkr')
	cxxHeader: '/* For Application fluid variable */
#ifndef APPMODSX_HXX
#include "appmodsx.hxx"
#define APPMODSX_HXX
#endif /* APPMODSX_HXX */
' in: #public!

(CxxSystemOrganization getOrMakeFileNamed: 'linkmkr')
	addClass: EndList2DescriptionListSchnert
getOrMakeCxxClassDescription in: #public;
	addClass: LinkTypeList2WordArrayListSchnert
getOrMakeCxxClassDescription in: #public;
	addClass: LinkEndsModel
getOrMakeCxxClassDescription in: #public;
	addClass: LinkMakerWindowModel
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'loginpn')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'loginpn')
	addClass: LoginWindowModel
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'loginpn')
	addClass: ID2LockSchnert
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'permwin')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'permwin')
	addClass: PermissionsBuilder
getOrMakeCxxClassDescription in: #public;
	addClass: MultiThunk
getOrMakeCxxClassDescription in: #public;
	addClass: PermissionWindowModel
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'permwin')
	addClass: ModifyEditorsSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: PermissionSelectBuilder
getOrMakeCxxClassDescription in: #private;
	addClass: ModifyReadersSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: Editors2SelSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: Readers2SelSchnert
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'refrnce')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'refrnce')
	addClass: TapestryFilter
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'refrnce')
	addClass: LinkReferenceSensor
getOrMakeCxxClassDescription in: #private;
	addClass: VariantReferenceSensor
getOrMakeCxxClassDescription in: #private;
	addClass: TapestryLinkFilter
getOrMakeCxxClassDescription in: #private;
	addClass: TapestryVariantFilter
getOrMakeCxxClassDescription in: #private;
	addClass: ReferenceFilter2Tapestry
getOrMakeCxxClassDescription in: #private;
	addClass: TapestryFilter2Reference
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'tabltop')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'tabltop')
	addClass: TableTopModel
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'udirmod')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'udirmod')
	addClass: UserDirectoryThunk
getOrMakeCxxClassDescription in: #public;
	addClass: UserListWindowModel
getOrMakeCxxClassDescription in: #public;
	addClass: UDMWindowModel
getOrMakeCxxClassDescription in: #public;
	addClass: ClubManagerPaneModel
getOrMakeCxxClassDescription in: #public;
	addClass: UDM2UDMWindow
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'udirmod')
	addClass: PackOBit2ATMSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: AddSelectedUsers2MembersThunk
getOrMakeCxxClassDescription in: #private;
	addClass: AddSelectedUsers2TargetThunk
getOrMakeCxxClassDescription in: #private;
	addClass: ID2PackOBitSchnert
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'usermod')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'usermod')
	addClass: LookupTool
getOrMakeCxxClassDescription in: #public;
	addClass: ID2ClubNameLookup
getOrMakeCxxClassDescription in: #public;
	addClass: UserModel
getOrMakeCxxClassDescription in: #public;
	addClass: List2ListLookupSchnert
getOrMakeCxxClassDescription in: #public;
	addClass: UserDirectoryModel
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'usermod')
	addClass: User2HomeSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: Waldo2SubListSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: Waldo2ValueSchnert
getOrMakeCxxClassDescription in: #private;
	addClass: User2DefaultPermissionSchnert
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'winmod')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'winmod')
	addClass: NotifierSchnert
getOrMakeCxxClassDescription in: #public;
	addClass: PassageBuilder
getOrMakeCxxClassDescription in: #public;
	addClass: TextWaldoBuilder
getOrMakeCxxClassDescription in: #public;
	addClass: WindowModel
getOrMakeCxxClassDescription in: #public;
	addClass: DocumentWindowModel
getOrMakeCxxClassDescription in: #public;
	addClass: TranscriptThunk
getOrMakeCxxClassDescription in: #public;
	addClass: PassageWindowModel
getOrMakeCxxClassDescription in: #public;
	addClass: WindowFrontUpdate
getOrMakeCxxClassDescription in: #public;
	addClass: ScrollerSchnert
getOrMakeCxxClassDescription in: #public;
	addClass: WindowCloseUpdate
getOrMakeCxxClassDescription in: #public;
	addClass: Refs2DocSelectionSchnert
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'winmod')
	addClass: FollowThunk
getOrMakeCxxClassDescription in: #private;
	addClass: LinkMakerThunk
getOrMakeCxxClassDescription in: #private;
	addClass: ReferenceListBuilder
getOrMakeCxxClassDescription in: #private;
	addClass: PassageModel2Window
getOrMakeCxxClassDescription in: #private;
	addClass: ShortReferenceBuilder
getOrMakeCxxClassDescription in: #private;
	addClass: FullReferenceBuilder
getOrMakeCxxClassDescription in: #private;
	addClass: TwoLineReferenceBuilder
getOrMakeCxxClassDescription in: #private;
	addClass: NewDocThunk
getOrMakeCxxClassDescription in: #private;
	addClass: ImportThunk
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'wtmod')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'wtmod')
	addClass: WaldoTextModel
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'wtmod')
	addClass: XnText2ATM
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'editing')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'editing')
	addClass: EditOperation
getOrMakeCxxClassDescription in: #public;
	addClass: MoveOperation
getOrMakeCxxClassDescription in: #public;
	addClass: MoveInOperation
getOrMakeCxxClassDescription in: #public;
	addClass: MoveOutOperation
getOrMakeCxxClassDescription in: #public;
	addClass: PrimOperation
getOrMakeCxxClassDescription in: #public;
	addClass: DeleteOperation
getOrMakeCxxClassDescription in: #public;
	addClass: InsertOperation
getOrMakeCxxClassDescription in: #public;
	addClass: ShareOperation
getOrMakeCxxClassDescription in: #public;
	addClass: EditSequence
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'findlcs')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'findlcs')
	addClass: LCSFinder
getOrMakeCxxClassDescription in: #public;
	addClass: Diagonal
getOrMakeCxxClassDescription in: #public;
	addClass: LCSDiagonal
getOrMakeCxxClassDescription in: #public;
	addClass: DiagonalMatrix
getOrMakeCxxClassDescription in: #public;
	addClass: LCSDiagonalMatrix
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'arrange')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'arrange')
	addClass: FirstFitMaker
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'compar')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'compar')
	addClass: CompareFragment
getOrMakeCxxClassDescription in: #public;
	addClass: DeleteFragment
getOrMakeCxxClassDescription in: #public;
	addClass: InsertFragment
getOrMakeCxxClassDescription in: #public;
	addClass: PrimFragment
getOrMakeCxxClassDescription in: #public;
	addClass: TextComparator
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'compar')
	addClass: ComparatorTester
getOrMakeCxxClassDescription in: #test!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: 'tapestry' value: #dir)
 addChild: ((CxxTreeAssociation key: 'appmods' value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #docmodl value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #filters value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #linkmkr value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #loginpn value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #permwin value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #refrnce value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #tabltop value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #udirmod value: #file) yourself);
 addChild: ((CxxTreeAssociation key: 'usermod' value: #file) yourself);
 addChild: ((CxxTreeAssociation key: 'winmod' value: #file) yourself);
 addChild: ((CxxTreeAssociation key: 'wtmod' value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #'compare/merge' value: nil)
 addChild: ((CxxTreeAssociation key: #editing value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #findlcs value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #arrange value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #compar value: #file) yourself); yourself); yourself))!