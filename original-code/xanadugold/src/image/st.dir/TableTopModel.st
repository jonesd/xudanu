'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:02 pm'!

XnModel subclass: #TableTopModel
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
	^self create: home! !