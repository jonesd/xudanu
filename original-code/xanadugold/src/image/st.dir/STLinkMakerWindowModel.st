'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:05 pm'!

STWindowModel subclass: #STLinkMakerWindowModel
	instanceVariableNames: '
		wasShifted {BooleanVar}
		myController {StandardSystemController}
		myTop {View}
		myCurrentEndView {FMScrolledView}
		currentReader {DisplayObject}
		currentEditor {DisplayObject}
		currentFromType {DisplayObject}
		currentTooType {DisplayObject}
		myFromView {FMMVCView}
		myTooView {FMMVCView}
		myLinkTypesMenu {PopUpMenu}
		myLinkTypesList {ListModel of: (Pair of: MuWordArray and: MuWordArray)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!
STLinkMakerWindowModel comment:
'This is the smalltalk version of the LinkMaker window model.'!



!STLinkMakerWindowModel methodsFor: 'create'!

create: window {WindowModel}
	super create: window.
	wasShifted _ false.
	myController _ NULL.
	myTop _ NULL.
	myCurrentEndView _ NULL.
	currentEditor _ 'Hugh' asString asParagraph.
	currentReader _ 'Hugh' asString asParagraph.
	currentFromType _ 'From Type' asString asParagraph.
	currentTooType _ 'To Type' asString asParagraph! !

!STLinkMakerWindowModel methodsFor: 'pinning'!

{void} pin: n {Integer}
	"set this user's pin status"!

{Integer} pinMask
	^Form gray!

pinMenu
	"we don't pin LinkMakers..."
	^nil!

pinWindow
	"toggle the pin status of this window"
	"can't pin a LinkMaker..."! !

!STLinkMakerWindowModel methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel} 

	(model == self window and: [change isKindOf: RegionUR])
		ifTrue: [| asp {RegionUR} |
			asp _ change basicCast: RegionUR.
			(asp region hasMember: (ID key: 'CurrentEnd'))
				ifTrue: [myCurrentEndView newBuilding: self window currentEndBuilding]
			ifFalse: [(asp region hasMember: (ID key: 'FromEnds'))
				ifTrue: [myFromView setSource: (self getIconForCount: (self window fromEnds count))]
			ifFalse: [(asp region hasMember: (ID key: 'TooEnds'))
				ifTrue: [myTooView setSource: (self getIconForCount: (self window tooEnds count))]]]]! !

!STLinkMakerWindowModel methodsFor: 'private: window building'!

{Float} attachIconsTo: top {StandardSystemView} 
	"attach passage and link panes to the top view"

	| fb {FMBuilding} tb {FMBuilding} |
	top addSubView: (FMVCView new create: (fb _ self window fromEndBuilding))
		in: (0.1 @ 0.12 extent: 0.12 @ 0.12)
		borderWidth: 1.
	top addSubView: (FMVCView new create: (tb _ self window tooEndBuilding))
		in: (0.78 @ 0.12 extent: 0.12 @ 0.12)
		borderWidth: 1.
	myTooView _ tb view.
	myFromView _ fb view.
	myFromView setSource: (self getIconForCount: (self window fromEnds count)).
	myTooView setSource: (self getIconForCount: (self window tooEnds count))!

{void} attachPanesTo: top {StandardSystemView}
	"attach passage and link panes to the top view"
	| topSpace endListSpace descriptSpace |
	topSpace _ 0.35.
	descriptSpace _ 0.1.
	endListSpace _ 1 - topSpace - descriptSpace.
	top addSubView: (myCurrentEndView _ FMVCScrolledView make: self window currentEndBuilding)
		in: (0.1@(topSpace) extent: (0.8@0.1))
		borderWidth: 1.
	top addSubView: (FMVCScrolledView make: self window endlistBuilding)
		in: (0.1@(topSpace + 0.11) extent: (0.6@endListSpace))
		borderWidth: 1.!

{void} attachTypeNamesTo: top {StandardSystemView}
	|  typeWidth topType |
	typeWidth _ 0.4.
	topType _ 0.025 + 0.05.
	top addSubView: (FMVCView make: (self window fromDescriptionBuilding))
		in: (0.3@topType extent: typeWidth@0.05) borderWidth: 1.
	topType _ topType _ 0.05.
	top addSubView: (FMVCView make: (self window tooDescriptionBuilding))
		in: (0.3@topType extent: typeWidth@0.05) borderWidth: 1.! !

!STLinkMakerWindowModel methodsFor: 'windowing'!

{void} open
	myTop  _ FMMVCWindow create: self with: 'Link Creator' with: 300@300.
	self attachButtonsTo: myTop.
	self attachMenusTo: myTop.
	self attachIconsTo: myTop.
	self attachPanesTo: myTop.
	myController _ myTop controller.
	myController initialize; open! !

!STLinkMakerWindowModel methodsFor: 'private: setting'!

{void} editor: newEditor {DisplayObject} 
	currentEditor _ newEditor.
	self changed: #editors!

{void} fromType: newType {DisplayObject} 
	currentFromType _ newType.
	self changed: #fromType!

{void} reader: newReader {DisplayObject} 
	currentReader _ newReader.
	self changed: #readers!

{void} tooType: newType {DisplayObject} 
	currentTooType _ newType.
	self changed: #tooType! !

!STLinkMakerWindowModel methodsFor: 'private: display objects'!

{DisplayObject} deleteItButton
	"get the name of the user's current filter"
	^'Delete End' asString asParagraph!

{DisplayObject} editors
	"get the name of the user's current filter"
	^ currentEditor!

{DisplayObject} fromEndButton
	"get the name of the user's current filter"
	^'Make From' asString asParagraph!

{DisplayObject} fromType
	"get the name of the user's current filter"
	^ currentFromType!

{Image} getIconForCount: aCount {IntegerVar} 
	| tCnt iconName tIcon |
	tCnt _ aCount.
	tCnt > 5
		ifTrue: [iconName _ 'EndMany']
		ifFalse: [iconName _ 'End' , tCnt printString].
	tIcon _ Resources fluidVar fetchImage: iconName.
	tIcon == NULL ifTrue: [self class blast.CannotFindProperIcon raise].
	^tIcon!

{DisplayObject} makeItButton
	"get the name of the user's current filter"
	^'Make Link' asString asParagraph!

pinForm
	self thingToDo."replace this with something else"
	^Resources fluidVar get: (ID key: 'Pin')!

{DisplayObject} readers
	"get the name of the user's current filter"
	^ currentReader!

{DisplayObject} tooType
	"get the name of the user's current filter"

	^currentTooType! !

!STLinkMakerWindowModel methodsFor: 'private: menus'!

{PopupMenu} editorsMenu
	"Menu for some hack Hugh Hoover is working on."

	^ PopUpMenu fromArray: #(
		('The World')
		('Xanadu')
		('Autodesk')
		('Hallway')
		('Sue+MarcS')
		('Sue')
		('Chris')
		('Dean')
		('Eric')
		('Hugh')
		('JoelV')
		('MarcS')
		('MarkM')
		('Michael')
		('Ravi')
		('Roger')
		('Roland') )!

{PopUpMenu} linkTypesMenu

	^ Application fluidVar user linkTypesMenu getValue!

{PopupMenu} readersMenu
	"Menu for some hack Hugh Hoover is working on."

	^ PopUpMenu fromArray: #(
		('The World')
		('Xanadu')
		('Autodesk')
		('Hallway')
		('Sue+MarcS')
		('Sue')
		('Chris')
		('Dean')
		('Eric')
		('Hugh')
		('JoelV')
		('MarcS')
		('MarkM')
		('Michael')
		('Ravi')
		('Roger')
		('Roland') )! !

!STLinkMakerWindowModel methodsFor: 'private: menu actions'!

{void} editorsChoice: symbol {String}

	Transcript show: ('editor selected is ', symbol); cr; endEntry.
	self editor: symbol asString asParagraph!

{void} readersChoice: symbol {String}

	Transcript show: ('reader selected is ', symbol); cr; endEntry.
	self reader: symbol asString asParagraph! !

!STLinkMakerWindowModel methodsFor: 'private: button actions'!

{void} deleteIt

	Transcript show: 'I should delete the selected end now.'; cr; endEntry!

{void} makeIt

	self window makeLink.
	Transcript show: 'I made a link just now.'; cr; endEntry.! !

!STLinkMakerWindowModel methodsFor: 'private: display
objects'!

{Form} arrowForm

	^ Resources fluidVar fetchResource: 'UpArrow'!

{DisplayObject} clearButton
	"get the name of the user's current filter"
	^'Clear' asString asParagraph!

{DisplayObject} tooEndButton
	"get the name of the user's current filter"
	^'Make To' asString asParagraph! !

!STLinkMakerWindowModel methodsFor: 'private: button
actions'!

{void} clearAll
	self window clearAll!

{void} makeFromEnd

	self window makeFromEnd!

{void} makeTooEnd
	self window makeTooEnd! !

!STLinkMakerWindowModel methodsFor: 'private: window
building'!

{void} attachButtonsTo: top {StandardSystemView}
	|  topType typeHeight permitTop permitHeight makeItLeft
makeItWidth makeItHeight makeItTop |
	permitTop _ 0.025.
	permitHeight _ 0.05.
	typeHeight _ 0.05.
	topType _ permitTop + permitHeight + 0.05 + typeHeight.
	makeItLeft _ 0.375.
	makeItWidth _ 0.25.
	makeItHeight _ 0.05.
	makeItTop _ topType + 0.02 + typeHeight.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #makeIt
				menu: nil
				action: #makeIt)
			form: #makeItButton)
		in: (makeItLeft@makeItTop extent:
makeItWidth@makeItHeight) borderWidth: 2.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #makeFromEnd
				menu: nil
				action: #makeFromEnd)
			form: #arrowForm)
		in: (0.14@makeItTop extent: 0.05@0.06) borderWidth: 0.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #makeTooEnd
				menu: nil
				action: #makeTooEnd)
			form: #arrowForm)
		in: (0.82@makeItTop extent: 0.05@0.06) borderWidth: 0.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #deleteIt
				menu: nil
				action: #deleteIt)
			form: #deleteItButton)
		in: (0.73@0.6 extent: makeItWidth@makeItHeight)
borderWidth: 1.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #clearAll
				menu: nil
				action: #clearAll)
			form: #clearButton)
		in: (0.73@0.7 extent: makeItWidth@makeItHeight)
borderWidth: 1.!

{void} attachMenusTo: top {StandardSystemView}
	|  typeWidth topType typeLeft typeHeight permitTop
permitHeight permitWidth readLeft editLeft |
	permitTop _ 0.025.
	permitHeight _ 0.05.
	permitWidth _ 0.33.
	editLeft _ (1 - (2 * permitWidth)) / 3.0.
	readLeft _(2.0 * editLeft) + permitWidth.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: nil
				menu: #readersMenu
				action: #readersChoice:)
			form: #readers)
		in: (readLeft@permitTop extent:
permitWidth@permitHeight) borderWidth: 1.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: nil
				menu: #editorsMenu
				action: #editorsChoice:)
			form: #editors)
		in: (editLeft@permitTop extent:
permitWidth@permitHeight) borderWidth: 1.

	typeLeft _ 0.3.
	typeWidth _ 0.4.
	typeHeight _ 0.05.
	topType _ permitTop + permitHeight + 0.05.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: nil
				menu: #linkTypesMenu
				action: #linkTypeChoice:)
			form: #fromType)
		in: ((typeLeft-0.05)@topType extent:
typeWidth@typeHeight) borderWidth: 1.
	topType _ topType + typeHeight + 0.01.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: nil
				menu: #linkTypeMenu
				action: #linkTypeChoice:)
			form: #tooType)
		in: ((typeLeft+0.05)@topType extent:
typeWidth@typeHeight) borderWidth: 1.! !

!STLinkMakerWindowModel methodsFor: 'private: menu
actions'!

{void} linkTypeChoice: index {IntegerVar} 
	"Note that this routine expects the result from a
PopUpMenu - not a 
	HierarchicalMenu, so that it will get an index (integer)
rather than 
	a symbol."

	| ts left right symbol |
	symbol _ Application fluidVar user linkTypesMenu getValue
labelAt: index.
	left _ (ts _ symbol asString) copyFrom: 1 to: (ts
indexOfSubCollection: '...') + 3.
	right _ ts copyFrom: (ts indexOfSubCollection: '...') to:
ts size.
	self fromType: left asString asParagraph.
	self tooType: right asString asParagraph.
	self window linkTypeChoice: (index // 2)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STLinkMakerWindowModel class
	instanceVariableNames: ''!



!STLinkMakerWindowModel class methodsFor: 'smalltalk: initialization'! !

!STLinkMakerWindowModel class methodsFor: 'smalltalk:
initialization'!

initTimeNonInherited
	self REQUIRES: TapestryAppModel.
	self REQUIRES: FMResourceManager. 
	Resources fluidGet storeImage: 'End0'
		with: (Image make.void: (Form extent: 33 @ 33
				fromArray: #(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3699
39936 0 3699 39936 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 960 0 0
1056 0 0 1056 0 0 1056 0 0 1056 0 0 1056 0 0 1056 0 0 960
0 0 0 0 0 0 0 0 0 0 )
				offset: 0 @ 0)).
	Resources fluidGet storeImage: 'End1'
		with: (Image make.void: (Form extent: 33 @ 33
				fromArray: #(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2047
65528 0 2047 65528 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 32 0 0 96
0 0 32 0 0 32 0 0 32 0 0 32 0 0 32 0 0 0 0 0 0 0 0 0 0 0 0
0 )
				offset: 0 @ 0)).
	Resources fluidGet storeImage: 'End2'
		with: (Image make.void: (Form extent: 34 @ 33
				fromArray: #(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2047
65528 0 2047 65528 0 0 0 0 0 0 0 0 0 0 2047 57344 0 2047
57344 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 56 0 0 68 0 0 4 0 0 8 0 0 16 0 0 32 0 0 124 0 0 0 0
0 0 0 0 0 0 0 0 0 )
				offset: 0 @ 0)).
	Resources fluidGet storeImage: 'End3'
		with: (Image make.void: (Form extent: 33 @ 33
				fromArray: #(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2047
65528 0 2047 65528 0 0 0 0 0 0 0 0 0 0 2047 57344 0 2047
57344 0 0 0 0 0 0 0 0 0 0 2047 65528 0 2047 65528 0 0 0 0
0 0 0 0 0 0 0 0 0 0 248 0 0 16 0 0 32 0 0 112 0 0 8 0 0
136 0 0 112 0 0 0 0 0 0 0 0 0 0 0 0 0 )
				offset: 0 @ 0)).
	Resources fluidGet storeImage: 'End4'
		with: (Image make.void: (Form extent: 33 @ 33
				fromArray: #(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2047
65528 0 2047 65528 0 0 0 0 0 0 0 0 0 0 2047 57344 0 2047
57344 0 0 0 0 0 0 0 0 0 0 2047 65528 0 2047 65528 0 0 0 0
0 0 0 0 0 0 0 0 0 0 8 0 0 24 0 0 40 0 0 72 0 0 124 0 0 8 0
0 8 0 0 0 0 0 0 0 0 0 0 0 0 0 )
				offset: 0 @ 0)).
	Resources fluidGet storeImage: 'End5'
		with: (Image make.void: (Form extent: 34 @ 33
				fromArray: #(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2047
65528 0 2047 65528 0 0 0 0 0 0 0 0 0 0 2047 57344 0 2047
57344 0 0 0 0 0 0 0 0 0 0 2047 65528 0 2047 65528 0 0 0 0
0 0 0 0 0 0 0 0 0 0 62 0 0 32 0 0 60 0 0 2 0 0 2 0 0 34 0
0 28 0 0 0 0 0 0 0 0 0 0 0 0 0 )
				offset: 0 @ 0)).
	Resources fluidGet storeImage: 'EndMany'
		with: (Image make.void: (Form extent: 33 @ 33
				fromArray: #(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2047
65520 0 2047 65520 0 0 0 0 0 0 0 0 0 0 2047 49152 0 2047
49152 0 0 0 0 0 0 0 0 0 0 2047 65520 0 2047 65520 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
584 0 0 0 0 0 0 0 0 0 0 0 0 0 )
				offset: 0 @ 0)).
	Resources fluidGet storeResource: 'UpArrow'
		with: (Form extent: 13@18
				fromArray: #( 512 1792 3968 8128 16352 32752 65528
8128 8128 8128 8128 8128 8128 8128 8128 8128 8128 0)
				offset: 0@0)! !