'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:51 pm'!

Object subclass: #PopUpMenu
	instanceVariableNames: '
		labelString {String}
		font {StrikeFont}
		lineArray {OrderedCollection of: Integer}
		frame {Quadrangle}
		form {Form}
		marker {Rectangle}
		selection {Integer}
		origin {Point}'
	classVariableNames: '
		HelpThreshold {Integer} 
		LiveMenus {BooleanVar} 
		MenuKeyCache {OrderedCollection of: Array | String} 
		MenuValueCache {OrderedCollection of: PopUpMenu} 
		OldMenuKeyCache {OrderedCollection of: Array | String} 
		OldMenuValueCache {OrderedCollection of: PopUpMenu} 
		ShortForm {BooleanVar} '
	poolDictionaries: ''
	category: 'Interface-Menus'!
PopUpMenu comment:
'Class PopUpMenu represents a list of items.  Its instances are presented on the display screen in a rectangular area.  The user points to an item, pressing a mouse button;  the item is highlighted.  When the button is released, the highlighted item indicates the selection.

Instance Variables:

	labelString	<String> of menu items
	font		<StrikeFont> for displaying the characters
	lineArray	<Array> of integers indicating where lines should be drawn in the menu
	frame	<Quadrangle>
	form	<Form> containing the composed paragraph
	marker	<Rectangle> used to highlight selection
	selection	<Integer> index into menu items;  if 0, no selection
'!



!PopUpMenu methodsFor: 'basic control sequence'!

startUp
	"Show the receiver and give control to the user to make a selection."
	^self startUp: #anyButton!

startUpAndWaitForSelectionAt: aPoint
	"Display and make a selection from the receiver as long as the button denoted
	by the symbol, aSymbol, is pressed.  Answer the current selection."
	
	self displayAt: aPoint 
		during: [[(Sensor anyButtonPressed and: [frame inside containsPoint: Sensor cursorPoint])]
					whileFalse: [].
				[self buttonPressed: #anyButton]
					whileTrue: [self manageMarker]].
	^selection! !

!PopUpMenu methodsFor: 'accessing'!

center
	"Answer the point at the center of the receiver's rectangular area."
	^frame center!

height
	"Answer the width of the receiver's rectangular area."
	^frame height!

labelAt: aNumber
	"Answer the label whose ordinal position in the menu is aNumber.  If aNumber is out of range, answer nil."

	| cr count start next |
	aNumber <= 0 ifTrue: [^nil].
	cr _ String with: Character cr.
	count _ aNumber.
	start _ 1.
	[next _ labelString findString: cr startingAt: start.
	"The current label extends from start through (next - 1 if next > 0, otherwise the end of labelString)."
	count > 1]
		whileTrue:
			[next = 0 ifTrue: [^nil].  "aNumber is too large"
			start _ next + 1.
			count _ count - 1].
	^ labelString copyFrom: start to: (next = 0 ifTrue: [labelString size] ifFalse: [next - 1])!

reset
	"Set the positioning to the menu to its original state and the selection to nothing."

	marker _  marker align: marker topLeft with: frame topLeft + frame borderWidth origin.
	origin _ frame inside topLeft.
	selection _ 0.!

topLeft
	"Answer the point at the topLeft of the receiver's rectangular area."
	^frame topLeft!

width
	"Answer the width of the receiver's rectangular area."
	^frame width! !

!PopUpMenu methodsFor: 'bordering'!

borderWidth
	"Answer the borderWidth of the receiver's rectangular area."
	^frame borderWidth! !

!PopUpMenu methodsFor: 'displaying'!

displayAt: aPoint during: aBlock 
	"Display the receiver centered at aPoint while aBlock is evaluated.
	If necessary, translate so the view is completely on the screen."

	| delta savedArea frame2 pt |
	pt _ marker left - 1 @ marker center y.
	frame _ frame align: pt with: aPoint.
	delta _ frame amountToTranslateWithin: (Display boundingBox).
	frame moveBy: delta.
	frame2 _ Quadrangle
		region: (form boundingBox expandBy: frame borderWidth)
		borderWidth: frame borderWidth
		borderColor: frame borderColor
		insideColor: frame insideColor.
	frame _ frame2 align: frame2 origin with: frame origin.
	frame _ frame intersect: (Display boundingBox).
	frame _ frame adjustInsideHeightToMultipleOf: marker height.
	marker _ marker align: pt with: aPoint + delta.
	savedArea _ Form fromDisplay: frame.
	"Display black: (frame origin + (1@1) corner: frame corner).
	Display black: (frame origin corner: frame corner - (1@1))."
	frame displayOn: Display.
	origin _ frame inside topLeft.
	self displayForm.
	Cursor normal showWhile: aBlock.
	savedArea displayOn: Display at: frame topLeft!

displayAt: aPoint withHeading: aText during: aBlock 
	"Display the receiver centered at aPoint while aBlock is evaluated.
	If necessary, translate so the view is completely on the screen."

	| delta savedArea heading headingBox headingSavedArea shiftPoint frame2 |
	frame _ frame align: marker center with: aPoint.
	heading _ aText asDisplayText.
	headingBox _ heading boundingBox expandBy: 2.
	headingBox _ headingBox
			align: headingBox bottomCenter
			with: frame topCenter + (0@2).
	delta _ (frame merge: headingBox) amountToTranslateWithin: (Display boundingBox).
	frame moveBy: delta.
	frame2 _ Quadrangle
		region: (form boundingBox expandBy: frame borderWidth)
		borderWidth: frame borderWidth
		borderColor: frame borderColor
		insideColor: frame insideColor.
	frame _ frame2 align: frame2 origin with: frame origin.
	headingBox moveBy: delta.
	frame top < headingBox height 
		ifTrue:[ frame _ frame translateBy: (shiftPoint _ (0@(headingBox height - frame top - 2))).
				headingBox _ headingBox translateBy: shiftPoint].
	frame _ frame intersect: (Display boundingBox).
	frame _ frame adjustInsideHeightToMultipleOf: marker height.
	marker _ marker align: marker center with: aPoint + delta.
	savedArea _ Form fromDisplay: frame.
	headingSavedArea _ Form fromDisplay: headingBox.
	Display border: (headingBox) width: 2 mask: Form black.
	heading displayAt: headingBox origin + (2@2).
	"Display black: (frame origin + (1@1) corner: frame corner).
	Display black: (frame origin corner: frame corner - (1@1))."
	frame displayOn: Display.
	origin _ frame inside topLeft.
	self displayForm.
	Cursor normal showWhile: aBlock.
	savedArea displayOn: Display at: frame topLeft.
	headingSavedArea displayOn: Display at: headingBox topLeft!

displayForm
	"Display the image of the menu on the display screen.  Highlight
	the selection if there is one."

	form displayOn: Display at: origin clippingBox: frame inside.
	(selection ~= 0 and: [selection notNil]) ifTrue: [Display reverse: marker].! !

!PopUpMenu methodsFor: 'marker adjustment'!

manageMarker
	"If the cursor is inside the receiver's frame, then highlight the marked item.	
	Otherwise no item is to be marked."

	| aPoint |
	aPoint _ self scrollIfNeeded.
	(frame inside containsPoint: aPoint)
		ifTrue: [self markerOn: aPoint]
		ifFalse: [self markerOff]!

markerOff
	"No item is selected.  Reverse the highlight if any item has been marked as selected."
	selection ~= 0
		ifTrue: 
			[Display reverse: marker.
			selection _ 0]!

markerOn: aPoint 
	"The item whose bounding area contains aPoint should be marked as selected.
	Highlight its area and set the selection to its index."

	selection = 0 | (marker containsPoint: aPoint) not 
		ifTrue: [selection = 0 & (marker containsPoint: aPoint)
					ifTrue: [Display reverse: marker]
					ifFalse: 
						[selection ~= 0 ifTrue: [Display reverse: marker].
						marker _ 
							marker 
								align: marker topLeft 
								with: marker left @ (self markerTop: aPoint).
						Display reverse: marker]].
	selection _ marker top - origin y // marker height + 1!

markerTop: aPoint 
	"Answer aPoint, gridded to lines in the receiver."

	^(aPoint y - frame inside top truncateTo: font height) + frame inside top!

scrollIfNeeded
	"Scroll the menu if we need to"

	| aPoint |
	aPoint _ Sensor cursorPoint.
	((frame inside  top) >= aPoint y) & (origin y <= frame top)
		ifTrue: [ origin _ origin + (0@marker height).
				self displayForm ].
	((frame inside bottom) <= aPoint y) & 
		"There is something to scroll"
		((origin y + form height-2) > frame inside bottom)
		ifTrue: [ origin _ origin - (0@marker height).
				self displayForm ].
	^aPoint! !

!PopUpMenu methodsFor: 'selecting'!

selection
	"Answer the current selection."
	^selection! !

!PopUpMenu methodsFor: 'controlling'!

{void} adjustCursor

	self class liveMenus
		ifFalse: [Sensor cursorPoint: ((marker left -1) @ marker center y) + self class menuOffset]!

anyButtonPressed
	"Answer whether any mouse button is pressed."

	^Sensor anyButtonPressed!

buttonPressed: aSymbol 
	"The argument indicates which button should be tested.  Answer whether
	it is pressed."

	"aSymbol = #redButton ifTrue: [^Sensor redButtonPressed].
	aSymbol = #yellowButton ifTrue: [^Sensor yellowButtonPressed].
	aSymbol = #blueButton ifTrue: [^Sensor blueButtonPressed]."
	^Sensor anyButtonPressed!

startUp: t1 
	self displayAt: Sensor cursorPoint - self class menuOffset
		during: 
			[self adjustCursor.
			[self anyButtonPressed]
				whileFalse: [self scrollIfNeeded].
			[self anyButtonPressed]
				whileTrue: [self manageMarker].
			nil].
	^selection!

startUp: aSymbol withHeading: aText
	"Display and make a selection from the receiver as long as the button
	denoted by the symbol, aSymbol, is pressed.  Answer the current selection."
	
	self displayAt: Sensor cursorPoint withHeading: aText
		during: [Sensor cursorPoint: marker center.
				[self buttonPressed: aSymbol]
					whileFalse: [(frame containsPoint: Sensor cursorPoint) ifFalse: [Display flash: frame]].
				[self buttonPressed: aSymbol]
					whileTrue: [self manageMarker]].
	^selection!

startUpBlueButton
	"Display and make a selection from the receiver as long as the view button
	is pressed."

	^self startUp: #blueButton!

startUpRedButton
	"Display and make a selection from the receiver as long as the select button
	is pressed."

	^self startUp: #redButton!

startUpWithHeading: aText
	"Display and make a selection from the receiver as long as the button
	denoted by the symbol, aSymbol, is pressed.  Answer the current selection."
	
	^self startUp: #anyButton withHeading: aText!

startUpYellowButton
	"Display and make a selection from the receiver as long as the operate button
	is pressed."

	^self startUp: #yellowButton! !

!PopUpMenu methodsFor: 'private: private'!

labels: aString font: aFont lines: anArray
	| style labelPara |
	labelString _ aString.
	font _ aFont.
	style _ TextStyle fontArray: (Array with: font).
	style setAlignment: 2.  "centered"
	style gridForFont: 1 withLead: 0.
	labelPara _ Paragraph withText: aString asText style: style.
	lineArray _ anArray.
	form _ labelPara asForm.
	frame _ Quadrangle new.
	frame region: (labelPara compositionRectangle expandBy: 2).
	frame borderWidth: (1@1 corner: 3@3).
	lineArray == nil
	  ifFalse:
		[lineArray do:
			[:line |
			form fill: (0 @ (line * font height) extent: (frame width @ 1)) 
				mask: Form black]].
	marker _ frame inside topLeft extent: frame inside width @ labelPara lineGrid.
	selection _ 0!

rescan
	"cause me to be recreated for system changes like fonts"

	labelString == nil 
		ifFalse: [self labels: labelString font: font lines: lineArray]

	"PopUpMenu allInstancesDo: [:x | x rescan]."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PopUpMenu class
	instanceVariableNames: ''!



!PopUpMenu class methodsFor: 'preferences'!

{Integer} helpThreshold

	HelpThreshold == nil
		ifTrue: [HelpThreshold _ 3000].
	^HelpThreshold!

{void} helpThreshold: thresh {Integer}
	"PopUpMenu helpThreshold: 3000" "Normal case"
	"PopUpMenu helpThreshold: 10000" "Only when you really need it"
	"PopUpMenu helpThreshold: 1" "Make it immediate"
	"PopUpMenu helpThreshold: -1" "To turn it off"

	HelpThreshold _ thresh!

{BooleanVar} liveMenus
	^LiveMenus!

{void} liveMenus: flag {BooleanVar}
	"PopUpMenu liveMenus: true"
	"PopUpMenu liveMenus: false"
	
	LiveMenus _ flag.!

{Point} menuOffset
	^LiveMenus 
		ifTrue: [10@0]
		ifFalse: [0@0]!

{void} shortForm

	^ShortForm!

{void} shortForm: flag {BooleanVar} 
	"PopUpMenu shortForm: true"
	"PopUpMenu shortForm: false"

	ShortForm _ flag!

{Collection of: Symbol} tags
	"PopUpMenu flushMenus"
	
	^#(all), 
	(PopUpMenu shortForm ifTrue: [#(short)] ifFalse: [#(long)]),
	(PopUpMenu liveMenus ifTrue: [#(live)] ifFalse: [#(dead)]),
	(SourceMethods isSourceOnly ifTrue: [#(sourceOnly)] ifFalse: [#(allMethods)]),
	(Cursor usingBigCursor ifTrue: [#(bigCursor)] ifFalse: [#(normalCursor)]),
	(IOAccessor defaultClass = UnixIOAccessor ifTrue: 
		[#(unix)] 
	ifFalse: [IOAccessor defaultClass = MacIOAccessor ifTrue:
		[#(macOS)]
	ifFalse: [IOAccessor defaultClass = DosIOAccessor ifTrue:
		[#(dos)]
	ifFalse: 
		[#()]]])! !

!PopUpMenu class methodsFor: 'instance creation'!

{OrderedCollection of: (Array | Symbol)} arrayMatching: tags {Collection of: Symbol} 
	fromPrefixedArray: array {Array of: (Array | Symbol)}
	"(PopUpMenu matching: #(foo bar) fromPrefixedArray: #(
		(foo 'zorp' zorp 'Xu: I don''t know what a zorp is either')
		-
		(baz 'braz')
		-
		(bar 'foom' (
			(foo 'zorp' zorp 'Xu: I don''t know what a zorp is either')
			(baz 'braz'))))) startUp"
	
	| result {OrderedCollection of: (Array | Symbol)} |
	result _ OrderedCollection new.
	array do: [:rowDesc {Array | String} |
		(rowDesc isKindOf: String)
			ifTrue: [(rowDesc == #-)
						ifTrue: [result addLast: #-]
						ifFalse: [self error: 'invalid syntax']]
			ifFalse: [(tags includes: (rowDesc at: 1))
						ifTrue: [ | item |
							item _ OrderedCollection new.
							item add: (rowDesc at: 2).
							rowDesc size >= 3
								ifTrue: [ | sub |
									sub _ rowDesc at: 3.
									((sub isKindOf: String) 
									 or: [(sub isKindOf: Text) 
									 or: [(sub isKindOf: SequenceableCollection) not]])
				 							ifTrue: [item addLast: sub]
											ifFalse: [item addLast: (self 
															arrayMatching: tags 
															fromPrefixedArray: sub)]].
							rowDesc size >= 4
								ifTrue: [4 to: rowDesc size do: [:i |
											item addLast: (rowDesc at: i)]].
							result addLast: item]]].
	^result!

{PopUpMenu} codeMenu: tags {Collection of: Symbol}
	"Menu for text pane where one expects code (such as browsers)."
	
	| t {Collection of: Symbol} |
	((tags includes: #long) and: [tags includes: #accept])
		ifTrue: [t _ tags, #(longAccept)]
		ifFalse: [t _ tags].
		
	^PopUpMenu matching: t fromPrefixedArray: #(
			(all 		'again'			again					'')	"Rest are standard smalltalk."
			(action		'next'			nextAction:with:		'Xu: Prompt to apply the action associated with this browser to the next applicable case starting at the current selection point')
			(all 		'undo'			undo					'')
			-
			(long		'copy (^C)'	copySelection		'')
			(long		'cut   (^X)'	cut						'')
			(long		'paste (^V)'	paste					'')
			-
			(text		'do it'			doIt					'')
			(text		'print it'		printIt					'')
			(text		'inspect'		inspectIt				'')
			(text		'browse'		browseIt				'Xu: Evaluate an expression. Bring up a HierarchyBrowser on the class it returns.')
			(screenplay1	'audition'		auditionIt		'Xu: Markm will document it when he decides it works.')
			-
			(screenplay2 'rehearse'		rehearseIt:with:		'')
			(screenplay2 'audition'		auditionIt			'')
			-
			(file		'file it in'		fileItIn:from:			'')
			-
			(longAccept	'accept (^S)'	accept					'')
			(longFile		'put (^S)'		accept				'')
			(file		'get'			getNew:from:		'')
			(long		'cancel (^Q)'	cancel					'')
			-
			(file		'spawn'		spawnFile:from:		'')
			(dir			'spawn'		spawnFile:from:		'')
			-
			(pattern	'volumes'	chooseVolume:from:	'')
			(syntax	'proceed'	proceed				'')
			(project	'enter'	enter					'')
			-
			(code		'translate'		cxxFormat				'Xu: Show this method translated to C++')
			(code		'format'		format					'')
			-
			(code		'find' (
				(all			'message senders'	browseOtherSenders	'ST: Prompt with a menu of the messages sent by this method.  Create a browser on all senders of the chosen message.')
				(all			'implementors'		browseMessages			'ST: Prompt with a menu of the messages sent by this method.  Create a browser on all implementors of the chosen message.')
				-
				(all			'inst var refs'		browseFieldsTouched	'Xu: Prompt with a menu of the instance variables referenced by this method.  Create a browser on all methods that reference the chosen instance variable.')
				(all			'assignments'			browseFieldsSet			'Xu: Prompt with a menu of the instance variables referenced by this method.  Create a browser on all methods that assign the chosen instance variable.')
				-
				(all			'non-local vars'		browseAssociations		'Xu: Prompt with a menu of keys of all associations referenced by this method.  Create a browser on all methods which reference that association') ))
			(code		'spawn'		spawnEdits:from:		'')
			(code		'explain'		explain					'')
			-
			(para		'align'			align			'')
			(para		'fit'			fit				'')
			-
			(long		'hardcopy'	hardcopy				'')
			-
			(long		'style'			changeTextStyle		'')
			(long		'font'			changeFont			'') )!

{void} flushMenus
	"PopUpMenu flushMenus"
	
	MenuKeyCache _ nil.
	MenuValueCache _ nil.
	OldMenuKeyCache _ nil.
	OldMenuValueCache _ nil.!

{PopUpMenu} fromArray: array {Array of: (Array | Symbol)}

	^self fromCache: array ifAbsent: [HierarchicalMenu parseFromArray: array]!

{PopUpMenu} fromPrefixedArray: array {Array of: (Array | Symbol)}

	^self matching: PopUpMenu tags fromPrefixedArray: array!

{PopUpMenu} hierarchyFrom: coll {Collection of: String} sep: sep {String} 
	^self fromArray: (self
		hierarchicalStringFrom: (ReadStream on: coll)
		prefix: ''
		sep: sep).!

labelList: labelArray
	"Create a menu with labels from those grouped in labelArray."

	| stream lines line i k label|
	stream _ WriteStream on: (String new: 50).
	lines _ OrderedCollection new: labelArray size-1.
	line _ 0.
	labelArray
		do: [:labels |
			k _ 1.
			[k <= labels size] whileTrue:
				[label _ labels at: k.
				i _ 1.
				[i <= label size] whileTrue:
					[stream nextPut: (label at: i).
					i _ i + 1.].
				k _ k + 1.
				stream cr].
			line _ line + labels size.
			lines add: line].
	lines isEmpty ifFalse: [lines removeLast].
	stream skip: -1.  "remove the final cr"
	^self new
		labels: stream contents
		font: (TextStyle default fontAt: 1)
		lines: lines!

labels: aString
	"Answer an instance of me whose items are in aString."
	^self labels: aString lines: nil!

labels: aString lines: anArray
	"Answer an instance of me whose items are in aString, with lines drawn
	after each item indexed by anArray."
	^ self new labels: aString font: (TextStyle default fontAt: 1) lines: anArray!

{PopUpMenu} matching: tags {Collection of: Symbol} 
	fromPrefixedArray: array {Array of: (Array | Symbol)}

	^self fromArray: (self arrayMatching: tags fromPrefixedArray: array)!

standardCodeMenu
	"Menu for text pane where one expects code (such as browsers)."
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept code)!

standardTextMenu
	"Standard menu for text panes."
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept)! !

!PopUpMenu class methodsFor: 'private: semi-private'!

{PopUpMenu} fromCache: key {Array | String} 
	ifAbsent: aBlock {BlockClosure of: VOID with: PopUpMenu}

	| index {IntegerVar} result {PopUpMenu} |
	OldMenuKeyCache == nil 
		ifTrue: 
			[MenuKeyCache _ Array new: 500.
			MenuValueCache _ Array new: 500.
			OldMenuKeyCache _ Array new: 500.
			OldMenuValueCache _ Array new: 500].
	index _ (key hash \\ MenuKeyCache size) + 1.
	key = (MenuKeyCache at: index)
		ifTrue: [^MenuValueCache at: index].
	key = (OldMenuKeyCache at: index)
		ifTrue: [^OldMenuValueCache at: index].
	result _ aBlock value.
	OldMenuKeyCache at: index put: (MenuKeyCache at: index).
	OldMenuValueCache at: index put: (MenuValueCache at: index).
	MenuKeyCache at: index put: key.
	MenuValueCache at: index put: result.
	^result!

{Array of: Array} hierarchicalStringFrom: coll {ReadStream of: String} 
	prefix: prefix {String} 
	sep: sep {String}

	| out {WriteStream of: Array} |
	out _ WriteStream on: (Array new: 30).
	[coll atEnd not] whileTrue:
		[| item {String} itemRest {String} index {IntegerVar} |
		item _ coll peek.
		(item testPrefix: prefix ignoreCase: false) not
			ifTrue: [^out contents].
		itemRest _ item copyFrom: prefix size + 1 to: item size.
		index _ itemRest indexOfSubCollection: sep startingAt: 1.
		index = 0
			ifTrue: [coll next.
				out nextPut: (Array with: itemRest with: item)]
			ifFalse: [| title {String} newPrefix {String} |
				title _ itemRest copyFrom: 1 to: index -1.
				newPrefix _ prefix, title, sep.
				out nextPut: (Array with: title 
					with: (self hierarchicalStringFrom: coll prefix: newPrefix sep: sep))]].
	^out contents! !

!PopUpMenu class methodsFor: 'obsolete:'!

actionCodeMenu
	"Menu for text pane where one expects code (such as browsers)."
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept code action)!

{PopUpMenu} fromString: string {String}

	^self fromCache: string ifAbsent: [(MenuBuilder parseFrom: (ReadStream on: string)) menu]!

{PopUpMenu} long: long {Array of: (Array | Symbol)} 
	short: short {Array of: (Array | Symbol)}

	ShortForm == nil
		ifTrue: [ShortForm _ false].
	ShortForm
		ifTrue: [^PopUpMenu fromArray: short]
		ifFalse: [^PopUpMenu fromArray: long].!

{PopUpMenu} longForm: long {String} shortForm: short {String}

	"self passe."		"Replaced with long:short:"
	ShortForm == nil
		ifTrue: [ShortForm _ false].
	ShortForm
		ifTrue: [^PopUpMenu fromString: short]
		ifFalse: [^PopUpMenu fromString: long].!

smallTextMenu
	"A generic small version of the menu to be used for text editor panes."
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept)!

{void} toggleLiveMenus
	"PopUpMenu toggleLiveMenus"
	
	LiveMenus _ LiveMenus not.! !