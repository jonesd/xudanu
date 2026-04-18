'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:49 pm'!

PopUpMenu subclass: #HierarchicalMenu
	instanceVariableNames: '
		prefix {String}
		items {OrderedCollection of: Symbol | HierarchicalMenu}
		myComments {OrderedCollection of: String}
		background {Form}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
HierarchicalMenu comment:
'A HierarchicalMenu is a pop up menu that is tree structured.  

Instance Variables:
	prefix		<String>
	items		<OrderedCollection of: <Strings | HierarchicalMenu>> the items to be shown in the possibly structured menu
	background	<Form> cache of the display screen area covered by the receiver''s image'!



!HierarchicalMenu methodsFor: 'accessing'!

menuItems
	"Answer the collection of items in the receiver's menu."

	^items! !

!HierarchicalMenu methodsFor: 'converting'!

asString
	"Answer the text for the label for the receiver."
	
	^labelString! !

!HierarchicalMenu methodsFor: 'displaying'!

displayAt: aPoint 
	"Display the receiver centered at aPoint while aBlock is evaluated. If 
	necessary, translate so the view is completely on the screen."

	| delta |
	frame _ frame align: marker center with: aPoint.
	delta _ frame amountToTranslateWithin: Display boundingBox.
	frame moveBy: delta.
	frame _ frame intersect: Display boundingBox.
	marker _ marker align: marker center with: aPoint + delta.
	"frame _ frame adjustInsideHeightToMultipleOf: marker height."
	background _ Form fromDisplay: frame.
	frame displayOn: Display.
	origin _ frame inside topLeft.
	self displayForm!

displayLeftAt: aPoint
	"Display the receiver so that its left side is at aPoint. If 
	necessary, translate so the view is completely on the screen."

	self displayAt: aPoint + (marker extent + (2@0) // 2).!

eraseMenus
	"Erase all visible menus."

	self selectedMenuDo: [:item | item eraseMenus].
	self restoreBackground.
	selection _ nil.!

restoreBackground
	"Redisplay the image that was on the screen before the menu was displayed."

	background displayOn: Display at: frame topLeft! !

!HierarchicalMenu methodsFor: 'marker adjustment'!

markerOff
	selection isNil
		ifTrue: [^self]
		ifFalse: [self selectedMenuDo: [:item | item eraseMenus].	"erase overlapping sub-menus first"
				Display reverse: marker.
				selection _ nil]!

markerOn: aPoint 
	"The item whose bounding area contains aPoint should be marked as selected. Highlight its area and set the selection to its index."
	selection notNil
		ifTrue: [(marker containsPoint: aPoint)
					ifTrue: [^self]				"no change"
					ifFalse: [self markerOff]].	"erase old marker"
	marker _ marker align: marker topLeft 
					 with: marker left @ (self markerTop: aPoint).
	Display reverse: marker.						"display new marker"
	selection _ marker top - origin y // marker height + 1.
	self selectedMenuDo: [:item | item displayLeftAt: marker topRight].! !

!HierarchicalMenu methodsFor: 'selecting'!

menuAt: aPoint
	"Answer the receiver or selected sub-menu containing this screen coordinate."

	| sub | 
	self selectedMenuDo:	"find overlapping sub-menu first"
		[:menu |
		(sub _ menu menuAt: aPoint) notNil ifTrue: [^sub]].
	(frame containsPoint: aPoint) ifTrue: [^self].
	^nil!

selectedItem
	"Answer the item current selected."

	selection isNil ifTrue: [^nil].
	selection > items size ifTrue: [^#other].
	^items at: selection!

selectorAt: item
	"Included so that one can address HierarchicalMenus just like ActionMenus - see implementors of messages like yellowButtonActivity."

	^item!

{void} showComment

	| comment {String} |
	(selection isNil or: [selection > items size or: [myComments == nil]])
		 ifTrue: [^VOID].
	comment _ myComments at: selection.
	(comment == nil or: [comment = ''])
		ifTrue: [(self selectedItem isKindOf: PopUpMenu)
					ifTrue: [^VOID].
				Transcript cr; show: 'no comment yet'; cr; endEntry]
		ifFalse: [Transcript cr; show: comment; cr; endEntry]!

takeCursor
	"Jump the cursor to the center of the item last selected in this menu"

	(marker containsPoint: Sensor cursorPoint) ifFalse:	"don't jump if unnecessary"
		[Sensor cursorPoint: marker center]! !

!HierarchicalMenu methodsFor: 'controlling'!

controlLoop
	"Allow this menu to change its selection while it contains the cursor or until a leaf selection is made.  Display and erase any submenus as necessary."
	| item selPoint count {Integer} |
	item _ self selectedItem.
	count _ 0.
	["(self menuAt: (selPoint _ Sensor cursorPoint)) == self"
	frame inside containsPoint: (selPoint _ Sensor cursorPoint)]
		whileTrue:
			[Sensor anyButtonPressed
				ifTrue: 
					[(selection notNil and: [marker containsPoint: selPoint])
						ifTrue: [count _ count + 1.
								count = self class helpThreshold
									ifTrue: [self showComment]]
						ifFalse: [count _ 0.
								self markerOn: selPoint]]	"side-effects selection and sub-menus"
				ifFalse: [item _ self selectedItem.
						 (item isKindOf: HierarchicalMenu)
							ifTrue: [item takeCursor.		"jump cursor to sub-menu (optional)"
									[Sensor anyButtonPressed] 
										whileFalse: [item scrollIfNeeded]. "sub-menu selected, wait for button down"
									^nil	  "give control to sub-menu"]
							ifFalse: [(selection isNil		"non sub-menu selection"
											or: [selection <= items size])
										ifTrue: [^item]
										ifFalse: [^FillInTheBlank request: 'Enter a new name'
																 initialAnswer: prefix]]]].
	^nil		"button down outside menu, give up control"!

startUp: aSymbol
	"Display this menu and allow the user to select an item from it or one of  
	  its sub-menus.  Answer the selected item or 0."

	| menu result newMenu |
	self displayAt: Sensor cursorPoint - self class menuOffset during: 
		[| flag |
		flag _ true.
		result _ nil.
		self adjustCursor.
		menu _ nil.
		[flag and: [result == nil]] whileTrue:
			[flag _ self class liveMenus not.  "Turn sticky menus off for live menus."
			[Sensor anyButtonPressed] whileFalse: 
				[flag _ false.
				self scrollIfNeeded].
			menu _ nil.
			[Sensor anyButtonPressed]
				whileTrue: 
					[menu == nil
						ifTrue: [newMenu _ self menuAt: self scrollIfNeeded]
						ifFalse: [newMenu _ self menuAt: menu scrollIfNeeded].
					newMenu isNil
						ifTrue: [menu notNil ifTrue: [menu markerOff]]
						ifFalse: 
							[(menu notNil and: [newMenu selectedItem == menu])
								ifTrue: [menu markerOff].
							menu _ newMenu.
							result _ menu controlLoop]].
			self selectedMenuDo: [:item | item eraseMenus].
			selection _ nil]].
	Sensor waitNoButton.
	result == nil ifTrue: [^0]
		ifFalse: [^result]!

startUp: aSymbol withHeading: aText 
	"Display this menu and allow the user to select an item from it or one of  
	  its sub-menus.  Answer the selected item or nil."

	| menu result newMenu |
	self
		displayAt: Sensor cursorPoint
		withHeading: aText
		during: 
			[Sensor cursorPoint: marker center.
			[self buttonPressed: aSymbol]
				whileFalse: [self scrollIfNeeded].
			menu _ nil.
			[self buttonPressed: aSymbol]
				whileTrue: 
					[menu == nil
						ifTrue: [newMenu _ self menuAt: self scrollIfNeeded]
						ifFalse: [newMenu _ self menuAt: menu scrollIfNeeded].
					newMenu isNil
						ifTrue: [menu notNil ifTrue: [menu markerOff]]
						ifFalse: 
							[(menu notNil and: [newMenu selectedItem == menu])
								ifTrue: [menu markerOff].
							menu _ newMenu.
							result _ menu controlLoop]].
			self selectedMenuDo: [:item | item eraseMenus].
			selection _ nil].
	^result! !

!HierarchicalMenu methodsFor: 'private: private'!

{void} comments: comments {OrderedCollection of: String}

	myComments _ comments!

labels: aString font: aFont lines: anArray
	| style labelPara oldForm |
	labelString _ aString.
	font _ aFont.
	style _ TextStyle fontArray: (Array with: font).
	style setAlignment: 2.  "centered"
	style gridForFont: 1 withLead: 0.
	labelPara _ Paragraph withText: aString asText style: style.
	lineArray _ anArray.
	oldForm _ labelPara asForm.
	form _ Form extent: (oldForm extent + (labelPara lineGrid -3 // 2 + 1@ 0) "for triangles at right hand side").
	oldForm displayOn: form at: (0@0).
	frame _ Quadrangle new.
	frame region: ("labelPara compositionRectangle" form boundingBox expandBy: 2).
	frame borderWidth: (1@1 corner: 3@3).
	lineArray == nil
	  ifFalse:
		[lineArray do:
			[:line |
			form fill: (0 @ (line * font height) extent: (frame width @ 1)) 
				mask: Form black]].
	marker _ frame inside topLeft extent: frame inside width @ labelPara lineGrid.
	selection _ nil!

prefix: prefixString items: itemList
	| on height dot onHeight tooBig newForm |
	dot _ Form dotOfSize: 1.
	onHeight _ (height _ marker height) - 4.
	on _ Form extent: (onHeight //2 + 1) @ onHeight.
	1 to: onHeight // 2 do: [:index |
		dot 	displayOn: on at: 0@(index -1).
		dot 	displayOn: on at: (index -1) @ (index-1).
		dot 	displayOn: on at: 0@(onHeight - index).
		dot 	displayOn: on at: (index -1) @ (onHeight - index)].
	onHeight odd
		ifTrue:[	dot 	displayOn: on at: 0@(onHeight // 2).
				dot 	displayOn: on at: onHeight //2 @ (onHeight // 2)].
	prefix _ prefixString.
	
	items ~~ nil
		ifTrue: [self notify: 'prefix:items: should be called exactly once.  Proceed to continue anyway.'].
	items _ itemList.
	tooBig _ true.
	1 to: itemList size do: [:index |
		((itemList at: index) isKindOf: HierarchicalMenu)
			ifTrue:["We have another hierarchical menu, mark it in our form"
					on 	displayOn: form 
						at: (form width - (onHeight //2 + 1) )@((index -1) * height  +2 ).
					tooBig _ false.]
			ifFalse:["We don't have another h-menu, clear the spot in the form"
					"We assume this method is called only once, and hence don't do anything"
					]].
	tooBig
		ifTrue:[
			newForm _ Form extent: (form width - (onHeight //2 + 1) -1)@(form height).
			form 
				displayOn: newForm
				at: 0@0.
			newForm offset: form offset.
			form _ newForm.
			frame region: ("labelPara compositionRectangle" form boundingBox expandBy: 2).
			marker width: frame inside width.]!

selectedMenuDo: menuBlock
	| item |
	(selection notNil and: [selection <= items size])
		ifTrue: [item _ items at: selection.
				 (item isKindOf: HierarchicalMenu)
					ifTrue: [^menuBlock value: item]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HierarchicalMenu class
	instanceVariableNames: ''!



!HierarchicalMenu class methodsFor: 'examples'!

menuSampler1
	"This example builds a hierarchical menu with the hierarchy three deep.
	The 'right arrow' in an item indicates that selecting the item will open up
	another menu.  Selecting any item will cause nothing to happen."

	"HierarchicalMenu menuSampler1"

	^(PopUpMenu fromString:
		'(restore display[restoreDisplay]
		open window:
			(project[openProject]
			browser[openBrowser]
			workspace[openWorkspace]
			system workspace[openSystemWorkspace]
			transcript[openTranscript]
			file list[openFileList]
			document editor[openWYSIWYGView]))
		(save/quit:
			(save[save]
			save then quit[saveThenQuit]
			quit: 
				confirm[quit])
		exit project[exitProject])' ) startUp!

menuSampler2
	"This example builds a hierarchical menu with the hierarchy three deep.
	The 'right arrow' in an item indicates that selecting the item will open up
	another menu.  Selecting any item will cause nothing to happen."

	"HierarchicalMenu menuSampler2"

	^(PopUpMenu fromArray: #(
		('restore display'		restoreDisplay)
		('open window' (
			('project'				openProject					'AComment')
			('browser'				openBrowser)
			(workspace)
			('system workspace'	openSystemWorkspace)
			-
			('transcript'			openTranscript)
			('file list'				openFileList)
			('document editor'		openWYSIWYGView) )		'a quoted string')
		-
		('save/quit' (
			('save'					save)
			('save then quit'		saveThenQuit)
			('quit' ( 
				('confirm'			quit) )) ))
		('exit project'			exitProject) )) startUp!

menuSampler3
	"HierarchicalMenu menuSampler3"
	
	^(PopUpMenu fromArray: (Array with: (Array with: 'fooo'))) startUp.! !

!HierarchicalMenu class methodsFor: 'private: private'!

prefix: prefix itemList: itemList
	"Answer a new instance of the receiver "

	| newMenu | 
	newMenu _ self labelList: (Array with: (itemList collect:
										[ :item | self removePrefix: prefix from: item asString])
									  with: #('new name')).
	newMenu prefix: prefix items: itemList.
	^newMenu!

removePrefix: prefix from: label
	"Removes the prefix from the given label (or if they are the same, returns the label with brackets around it.)  Does not remove trailing hyphens."

	| pos pot |
	(prefix sameAs: (label , '-')) ifTrue: [
		pos _ label indexOf: $-.
		pos _ 1.
		[pot _ (label findString: '-' startingAt: pos) == 0] whileFalse: [
			pos _ pot ].
		^'<' , (label copyFrom: pos to: label size), '>'].
	(prefix sameAs: (label copyFrom: 1 to: prefix size)) ifTrue:
		[^label copyFrom: (prefix size + 1) to: label size].
	^label! !

!HierarchicalMenu class methodsFor: 'instance creation'!

{HierarchicalMenu} parseFromArray: array {Array of: (Array | String | Text)}
	| labels {OrderedCollection of: (OrderedCollection of: String | Text)}
	  items {OrderedCollection of: (String | Text | HierarchicalMenu)}
	  comments {OrderedCollection of: String}
	  result {HierarchicalMenu} |
	  
	labels _ OrderedCollection with: OrderedCollection new.
	items _ OrderedCollection new.
	comments _ OrderedCollection new.
	array do: [:rowDesc {Array | String} |
		(rowDesc isKindOf: String)
			ifTrue: [(rowDesc == #-)
				ifTrue: [labels add: OrderedCollection new]
				ifFalse: [self blast.InvalidSyntax raise]]
			ifFalse: [ | itemDesc {String | Text | Array} |
				labels last add: (rowDesc at: 1).
				rowDesc size = 1
					ifTrue: [itemDesc _ rowDesc at: 1]
					ifFalse: [itemDesc _ rowDesc at: 2].
				((itemDesc isKindOf: String) 
				 or: [(itemDesc isKindOf: Text) 
				 or: [(itemDesc isKindOf: SequenceableCollection) not]])
					ifTrue: [items add: itemDesc]
					ifFalse: [items add: (self parseFromArray: itemDesc)].
				rowDesc size >= 3
					ifTrue: [comments add: (rowDesc at: 3)]
					ifFalse: [comments add: '']]].
	result _ self labelList: labels.
	result prefix: 'prefix not used' items: items.
	result comments: comments.
	^result
	
	"(PopUpMenu fromArray: #(
	#(foo)
	-
	-
	#(bar)
	#(baz))) startUp"! !