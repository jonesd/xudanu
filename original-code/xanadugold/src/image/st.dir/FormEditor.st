'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:15 pm'!

MouseMenuController subclass: #FormEditor
	instanceVariableNames: 'form tool grid togglegrid mode previousTool color unNormalizedColor xgridOn ygridOn toolMenu underToolMenu '
	classVariableNames: 'BitEditKey BlackKey BlockKey ChangeGridsKey CurveKey DarkGrayKey EraseKey FlashCursor GrayKey InKey LightGrayKey LineKey OutKey OverKey RepeatCopyKey ReverseKey SelectKey SingleCopyKey TogglexGridKey ToggleyGridKey UnderKey WhiteKey '
	poolDictionaries: ''
	category: 'Tools-Form editing'!
FormEditor comment:
'Class FormEditor supports creating and modifying Forms.  This is intended to be a general-purpose picture (bitMap) editor.	

Instance Variables: 
	form	<Form> form representing the painting brush, i.e., the source for copying
	tool		<Symbol> name of current editing tool 
	grid		<Point>
	togglegrid	<Point>
	mode	<Form> for masking the copying of the form to the screen
	previousTool	<Symbol> name of last editing tool selected
	color	<Form>
	unNormalizedColor	<Form>
	xgridOn		<Boolean>	
	ygridOn		<Boolean>	
	toolMenu	<Controller>
	underToolMenu	<Form>

Class Variables:
	YellowButtonMenu		<PopUpMenu> to be displayed when the operate button is pressed
	YellowButtonMessages	<Array of: Symbols> of message names, one associated with each item in the YellowButtonMenu
	FlashCursor				<Boolean> the indicator of whether or not to turn the cursor (a brush) on 
	and off as it moves across the display

	These are characters representing the keyboard commands to call upon form editing operations.
	They correspond to items in the menu of buttons displayed with a Form Editor.

	BitEditKey
	BlackKey
	BlockKey
	ChangeGridsKey
	CurveKey
	DarkGrayKey
	EraseKey
	GrayKey
	InKey
	LightGrayKey
	LineKey
	OutKey
	OverKey
	RepeatCopyKey
	ReverseKey
	SelectKey
	SingleCopyKey
	TogglexGridKey
	ToggleyGridKey
	UnderKey
	WhiteKey'!


!FormEditor methodsFor: 'initialize-release'!

initialize
	super initialize.
	self setVariables.!

release

	super release.
	toolMenu notNil ifTrue: [toolMenu view release].
	toolMenu _ form _ nil! !

!FormEditor methodsFor: 'basic control sequence'!

controlInitialize

	toolMenu notNil ifTrue:	
		[toolMenu view
			align: toolMenu view displayBox topCenter
			with: view displayBox bottomCenter+(0@1).
		toolMenu view translateBy:
			(toolMenu view displayBox amountToTranslateWithin: Display boundingBox) x @ 0.
		underToolMenu _ Form fromDisplay: toolMenu view displayBox.
		toolMenu view display].
	self normalizeColor: unNormalizedColor.
	sensor waitNoButton!

controlTerminate

	view updateDisplay.
	toolMenu notNil ifTrue:	
		[underToolMenu displayAt: toolMenu view displayBox origin.
		underToolMenu _ nil].! !

!FormEditor methodsFor: 'control defaults'!

controlActivity

	(toolMenu notNil and: [toolMenu isControlWanted]) ifTrue: [^toolMenu startUp].
	self viewHasCursor ifTrue:
		[sensor redButtonPressed ifTrue: [^self redButtonActivity].
		sensor yellowButtonPressed ifTrue: [^self yellowButtonActivity].
		sensor blueButtonPressed ifTrue: [^self blueButtonActivity].
		self dragForm]!

isControlActive

	^(toolMenu notNil and: [toolMenu isControlWanted])
		or: [sensor noButtonPressed
			or: [sensor blueButtonPressed not and: [self viewHasCursor]]]!

isControlWanted

	^(toolMenu notNil and: [toolMenu isControlWanted])
		or: [self viewHasCursor]! !

!FormEditor methodsFor: 'editing tools'!

block
	"Allow the user to fill a rectangle with the gray tone and mode  
	currently selected."

	| rectangle |
	rectangle _ Rectangle fromUser: grid.
	rectangle isNil 
		ifFalse: [Display
					fill: (rectangle intersect: view insetDisplayBox)
					rule: mode
					mask: color]!

changeGridding
	"Allow the user to change the values of the horizontal and(or) vertical grid 
	modules.  Does not change the primary tool."

	| response gridInteger |
	response _ 
		self promptRequest: 'Current horizontal gridding is: ' 
						, togglegrid x printString 
						, '.
Type new horizontal gridding.'.
	response isEmpty
		ifFalse: 
			[gridInteger _ Integer readFromString: response.
			togglegrid x: ((gridInteger max: 1) min: Display extent x)].
	response _ 
		self promptRequest: 'Current vertical gridding is: ' 
						, togglegrid y printString 
						, '.
Type new vertical gridding.'.
	response isEmpty
		ifFalse: 
			[gridInteger _ Integer readFromString: response.
			togglegrid y: ((gridInteger max: 1) min: Display extent y)].
	xgridOn ifTrue: [grid x: togglegrid x].
	ygridOn ifTrue: [grid y: togglegrid y].
	tool _ previousTool!

changeTool: aCharacter 
	"Changes the value of the instance variable tool to be the tool 
	corresponding to aCharacter. Typically sent from a Switch in a 
	FormMenuView. "

	previousTool _ tool.
	tool _ self selectTool: aCharacter.
	(#(singleCopy repeatCopy line curve block) includes: tool)
		ifFalse:
			[self perform: tool]!

colorBlack
	"Set the mask (color) to black. Leaves the tool set in its previous state."

	self normalizeColor: Form black.
	tool _ previousTool!

colorDarkGray
	"Set the mask (color) to dark gray.  Leaves the tool set in its previous state."

	self normalizeColor: Form darkGray.
	tool _ previousTool!

colorGray
	"Set the mask (color) to gray.  Leaves the tool set in its previous state."

	self normalizeColor: Form gray.
	tool _ previousTool!

colorLightGray
	"Set the mask (color) to light gray.  Leaves the tool set in its previous state."

	self normalizeColor: Form lightGray.
	tool _ previousTool!

colorWhite
	"Set the mask (color) to white.  Leaves the tool set in its previous state."

	self normalizeColor: Form white.
	tool _ previousTool!

curve
	"Conic-section specified by three points from the mouse.   
	the resultant curve on the display is displayed according to the   
	current form and mode."

	| firstPoint secondPoint curve |
	firstPoint _ self cursorPoint.
	form
		displayOn: Display
		at: firstPoint
		clippingBox: view insetDisplayBox
		rule: mode
		mask: color.
	secondPoint _ self trackFormUntil: [sensor noButtonPressed].
	curve _ self rubberBandCurve: firstPoint to: secondPoint until: [sensor redButtonPressed].
	curve
		displayOn: Display
		at: 0 @ 0
		clippingBox: view insetDisplayBox
		rule: mode
		mask: color.
	sensor waitNoButton!

eraseMode
	"Set the mode for the tools that copy the form onto the display to erase.  
	Leaves the tool set in its previous state."

	mode _ 4.
	tool _ previousTool!

fileInForm
	"Ask the user for a file name and then recalls the Form in that file as 
	the current source Form (form). Does not change the tool."

	| inName trying newForm |
	trying _ true.
	tool _ previousTool.
	[trying]
		whileTrue: 
			[inName _ self promptRequest: 'type a name for recalling a source Form . . . '.
			inName isEmpty ifTrue: [^self].
			(inName asFilename exists and:
					[(newForm _ Form readFrom: inName) ~~ nil])
				ifTrue: [trying _ false]
				ifFalse: [trying _ BinaryChoice message: 'File not found, or
file not valid form file.
Try again?']].
	newForm ~~ nil
		ifTrue: [form _ newForm]!

fileOutForm
	"Ask the user for a file name and then save the current source form 
	(form) under that name. Does not change the tool."

	| outName |
	tool _ previousTool.
	outName _ self promptRequest: 'type a name for saving the source Form . . . '.
	outName isEmpty ifTrue: [^self].
	outName asFilename exists
		ifTrue: [(BinaryChoice message: 'writing over old file--okay?')
				ifTrue: [form writeOn: outName]]
		ifFalse: [form writeOn: outName]!

line
	"Rubber-band line is specified by two points from the mouse. The resultant   
	line on the display is displayed according to the current form and mode."

	| firstPoint endPoint |
	firstPoint _ self cursorPoint.
	endPoint _ self rubberBandFrom: firstPoint until: [sensor noButtonPressed].
	(Line from: firstPoint to: endPoint withForm: form)
		displayOn: Display
		at: 0 @ 0
		clippingBox: view insetDisplayBox
		rule: mode
		mask: color!

magnify
	"Allow for bit editing of an area of the Form. The user designates a rectangular 
	area that is scaled by 5 to allow individual screens dots to be modified.  
	red button is used to set a bit to black and yellow button is used to set a bit to  
	white. Editing continues until the user depresses any key on the keyboard."

	| smallRect smallForm scaleFactor tempRect |
	scaleFactor _ 8@8.
	smallRect _ (Rectangle fromUser: grid) intersect: view insetDisplayBox.
	smallRect isNil ifTrue: [^self].
	smallForm _ Form fromDisplay: smallRect.

	"Do this computation here in order to be able to save the existing display screen."
	tempRect _ BitEditor locateMagnifiedView: smallForm scale: scaleFactor.
	BitEditor
		openScreenViewOnForm: smallForm 
		at: smallRect topLeft 
		magnifiedAt: tempRect topLeft 
		scale: scaleFactor.
	tool _ previousTool!

newSourceForm
	"Allow the user to define a new sourceForm for the FormEditor. Copying the
	sourceForm onto the display is the primary graphical operation. Resets the tool to
	be repeatCopy."
	form _ Form fromUser: grid.
	tool _ previousTool!

overMode
	"Set the mode for the tools that copy the form onto the display to over.  
	Leaves the tool set in its previous state."

	mode _ Form over.
	tool _ previousTool!

repeatCopy
	"As long as the select button is pressed, copy the source form onto the display screen."
	[sensor redButtonPressed]
		whileTrue: 
			[form
				displayOn: Display
				at: self cursorPoint
				clippingBox: view insetDisplayBox
				rule: mode
				mask: color]!

reverseMode
	"Set the mode for the tools that copy the form onto the display to reverse.  
	Leaves the tool set in its previous state."

	mode _ Form reverse.
	tool _ previousTool!

singleCopy
	"copy the source form onto the display screen at the cursor location."

	form
		displayOn: Display
		at: self cursorPoint
		clippingBox: view insetDisplayBox
		rule: mode
		mask: color.
	sensor waitNoButton!

togglexGridding
	"Turns x (horizontal) gridding off, if it is on, and turns it on, if  
	it is off.  Does not change the primary tool."

	xgridOn
		ifTrue: 
			[grid x: 1.
			xgridOn _ false]
		ifFalse: 
			[grid x: togglegrid x.
			xgridOn _ true].
	tool _ previousTool!

toggleyGridding
	"Turns y (vertical) gridding off, if it is on, and turns it on, if  
	it is off.  Does not change the primary tool."

	ygridOn
		ifTrue: 
			[grid y: 1.
			ygridOn _ false]
		ifFalse: 
			[grid y: togglegrid y.
			ygridOn _ true].
	tool _ previousTool!

underMode
	"Sets the mode for the tools that copy the form onto the display to under.  
	Leaves the tool set in its previous state."

	mode _ Form under.
	tool _ previousTool! !

!FormEditor methodsFor: 'menu messages'!

accept
	"The edited information should now be accepted by the view."
	view updateDisplay.
	view accept!

cancel
	"The edited information should be forgotten by the view."

	view cancel!

fileIn
	"Read in a new form and open an editor on it."

	| inName newForm |
	inName _ self promptRequest: 'type a name for reading a new Form . . . '.
	(inName _ inName asFilename) exists
		ifTrue: 
			[newForm _ Form readFormFile: inName readStream.
			view topView controller close.
			toolMenu view release.
			newForm edit]!

fileOut
	"Ask the user for a file name and then save the current source 
	picture from the Display under that name. Does not change the tool."

	| outName picture |
	picture _ Form fromDisplay: view insetDisplayBox.
	outName _ self promptRequest: 'type a name for saving the Form being edited . . . '.
	outName isEmpty ifTrue: [^self].
	outName asFilename exists
		ifTrue: [(BinaryChoice message: 'writing over old file--okay?')
				ifTrue: [picture writeOn: outName]]
		ifFalse: [picture writeOn: outName]!

hardcopyView
	| document |
	Cursor wait
		showWhile:
			[document _ Document new.
			document addImage: model.
			document close.
			document toPrinter]!

redButtonActivity

	Cursor blank showWhile: [self perform: tool]! !

!FormEditor methodsFor: 'cursor'!

cursorPoint
	"Answer the mouse coordinate data gridded according to the receiver's grid."

	^sensor cursorPoint grid: grid! !

!FormEditor methodsFor: 'private: private'!

dragForm

	tool = #block
		ifTrue:
			[Cursor origin showWhile:
			[[sensor anyButtonPressed
				or: [sensor keyboardPressed
				or: [self viewHasCursor not]]]
				whileFalse: []].
			^ self cursorPoint]
		ifFalse:
			[^Cursor blank showWhile:
			[self trackFormUntil:
				[sensor anyButtonPressed
					or: [sensor keyboardPressed
					or: [self viewHasCursor not]]]]].!

normalizeColor: halftoneForm
	unNormalizedColor _ halftoneForm.
	color _ unNormalizedColor wrapAround: view insetDisplayBox origin.!

promptRequest: outputMessage 
	"Answer a string typed by the user on the keyboard. keyboard input is 
	terminated by a line feed character. Typing feedback happens in a window that 
	is at least 100 bits wide and 50 bits high."

	| answer |
	FillInTheBlank
		request: outputMessage
		displayAt: view insetDisplayBox topCenter + (0@80)
		centered: true
		action: [:ans | answer _ ans] 
		initialAnswer: ''.
	^answer!

rubberBandCurve: startPoint to: endPoint until: aBlock
	| curve previousApex apex | "Return a curve"
	curve _ Curve new.
	curve firstPoint: startPoint.
	curve secondPoint: (previousApex _ self cursorPoint).
	curve thirdPoint: endPoint.
	curve form: form.
	curve
		displayOn: Display
		at: 0 @ 0
		clippingBox: view insetDisplayBox
		rule: Form reverse
		mask: Form black.

	Cursor crossHair showWhile: [
		[aBlock value] whileFalse:
			[(apex _ self cursorPoint) = previousApex 
				ifFalse:
				[curve
					displayOn: Display
					at: 0 @ 0
					clippingBox: view insetDisplayBox
					rule: Form reverse
					mask: Form black.
				curve secondPoint: apex.
				curve
					displayOn: Display
					at: 0 @ 0
					clippingBox: view insetDisplayBox
					rule: Form reverse
					mask: Form black.
				previousApex  _ apex]]].
	curve
			displayOn: Display
			at: 0 @ 0
			clippingBox: view insetDisplayBox
			rule: Form reverse
			mask: Form black.
	^ curve!

rubberBandFrom: startPoint until: aBlock
	"Show an xor line from startPoint to the cursor point until aBlock evaluates to true, then remove the line and answer the endPoint."

	| line endPoint |
	line _ Line from: startPoint to: startPoint withForm: form.
	line displayOn: Display at: 0@0 clippingBox: view insetDisplayBox
		rule: Form reverse mask: nil.		"display"
	[aBlock value] whileFalse:
		[(endPoint _ self cursorPoint) = line endPoint ifFalse:
			[line displayOn: Display at: 0@0 clippingBox: view insetDisplayBox
				rule: Form reverse mask: nil.		"erase"
			line endPoint: endPoint.
			line displayOn: Display at: 0@0 clippingBox: view insetDisplayBox
				rule: Form reverse mask: nil.		"display"
			]].
	line displayOn: Display at: 0@0 clippingBox: view insetDisplayBox
		rule: Form reverse mask: nil.		"erase"
	^line endPoint!

selectTool: aCharacter
	"A new tool has been selected.  It is denoted by aCharacter.  Set the tool."

	"This code is written out in long hand (i.e., rather than dispatching on a
	table of options) so that it is obvious what is happening."
	
	aCharacter =  SingleCopyKey	ifTrue: [^#singleCopy].
	aCharacter =  RepeatCopyKey	ifTrue: [^#repeatCopy].
	aCharacter =  LineKey			ifTrue: [^#line].					
	aCharacter =  CurveKey			ifTrue: [^#curve].				
	aCharacter =  BlockKey			ifTrue: [^#block].		
	aCharacter =  SelectKey			ifTrue: [^#newSourceForm].		
	aCharacter =  OverKey			ifTrue: [^#overMode].
	aCharacter =  UnderKey			ifTrue: [^#underMode].
	aCharacter =  ReverseKey		ifTrue: [^#reverseMode].
	aCharacter =  EraseKey			ifTrue: [^#eraseMode].
	aCharacter =  ChangeGridsKey	ifTrue: [^#changeGridding].
	aCharacter =  TogglexGridKey	ifTrue: [^#togglexGridding].
	aCharacter =  ToggleyGridKey	ifTrue: [^#toggleyGridding].
	aCharacter =  BitEditKey			ifTrue: [^#magnify].			
	aCharacter =  WhiteKey			ifTrue: [^#colorWhite].			
	aCharacter =  LightGrayKey		ifTrue: [^#colorLightGray].			
	aCharacter =  GrayKey			ifTrue: [^#colorGray].				
	aCharacter =  DarkGrayKey		ifTrue: [^#colorDarkGray].			
	aCharacter =  BlackKey			ifTrue: [^#colorBlack].				
	aCharacter =  OutKey			ifTrue: [^#fileOutForm].			
	aCharacter =  InKey				ifTrue: [^#fileInForm].
	^ #singleCopy!

setVariables
	tool _ #repeatCopy.
	previousTool _ tool.
	grid _ 1 @ 1.
	togglegrid _ 8 @ 8.
	xgridOn _ false.
	ygridOn _ false.
	mode _ Form over.
	unNormalizedColor _ color _ Form black.
	form _ Form new extent: 8 @ 8.
	form black!

toolMenu: aController
	toolMenu _ aController.!

trackFormUntil: aBlock
	| previousPoint cursorPoint |
	previousPoint  _ self cursorPoint.
	form displayOn: Display at: previousPoint rule: Form reverse.
	[aBlock value] whileFalse:
		[cursorPoint _ self cursorPoint.
		(FlashCursor or: [cursorPoint ~= previousPoint])
			ifTrue:
			[form displayOn: Display at: previousPoint rule: Form reverse.
			form displayOn: Display at: cursorPoint rule: Form reverse.
			previousPoint  _ cursorPoint]].
	form displayOn: Display at: previousPoint rule: Form reverse.
	^ previousPoint!

yellowButtonMenu
	"Menu for the bit editor."
	
	^PopUpMenu fromArray: #(
		('accept'	accept	'')
		('cancel'	cancel	'')).! !

!FormEditor methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for the bit editor."
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FormEditor class
	instanceVariableNames: ''!


!FormEditor class methodsFor: 'class initialization'!

flashCursor: aBoolean 
	"Set the indicator of whether or not to turn the cursor (a brush) on 
	and off as it moves across the display to be aBoolean."

	FlashCursor _ aBoolean
	"FormEditor flashCursor: true."!

initialize
	"FormEditor initialize."

	FlashCursor _ false.
	self setKeyboardMap.
	"YellowButtonMenu _ PopUpMenu labels: 'accept
cancel
hardcopy'.
	YellowButtonMessages _ #(accept cancel hardcopyView)"

	"FormEditor initialize"! !

!FormEditor class methodsFor: 'instance creation'!

createOnForm: aForm
	"Create and schedule a StandardSystemView for a FormEditor on aForm."

	| formView formEditor menuView topView extent |
	formView _ FormHolderView new model: aForm.
	formEditor _ self new.
	formView controller: formEditor.
	menuView _ FormMenuView new makeFormEditorMenu model: formEditor.
	menuView insideColor: Form lightGray.
	menuView borderWidth: 1.
	menuView window: (menuView defaultWindow expandBy: 16).
	formEditor toolMenu: menuView controller.
	topView _ StandardSystemView new.
	topView model: aForm.
	topView addSubView: formView.
	topView label: 'Form Editor'.
	topView borderWidth: 2.
	extent _ topView viewport extent.
	topView minimumSize: extent.
	topView maximumSize: extent.
	^topView!

openFullScreenForm
	"Create and schedule an instance of the receiver on the form whose extent is the extent of
	the display screen."

	| topView |
	topView _ self createFullScreenForm.
	topView controller 
		openDisplayAt: (topView viewport extent//2)

	"FormEditor openFullScreenForm."!

openOnForm: aForm
	"Create and schedule an instance of the receiver on the form aForm."

	| topView |
	topView _ self createOnForm: aForm.
	topView controller open!

openOnForm: aForm at: originPoint
	"Create and schedule an instance of the receiver on the form aForm whose view origin is
	originPoint."

	| topView |
	topView _ self createOnForm: aForm.
	topView controller 
		openDisplayAt: originPoint + (topView viewport extent//2)! !

!FormEditor class methodsFor: 'examples'!

formFromDisplay
	"Create an instance of the receiver on a new form designated by the user at a location 
	designated by the user."

	"FormEditor formFromDisplay."

	Form fromUser edit!

fullScreen
	"Create an instance of the receiver on a new form that fills the full size of the display
	screen."

	"FormEditor fullScreen."

	FormEditor openFullScreenForm!

newForm
	"Create an instance of the receiver on a new form at a location designated by the user."

	"FormEditor newForm."

	(Form new extent: 300@300) edit!

newFormAtOrigin
	"Create an instance of the receiver on a new form at location 100,100."

	"FormEditor newFormAtOrigin."

	(Form new extent: 300@300) editAt: 100@100! !

!FormEditor class methodsFor: 'private: private'!

createFullScreenForm
	"Create a StandardSystemView for a FormEditor on the form whole screen."

	^self createOnForm: (Form new extent: (Display extent x - 4 @ (Display extent y
- 112)))!

setKeyboardMap
	"Keyboard Mapping"

	SelectKey_$a.
	SingleCopyKey_$s.			"tools"
	RepeatCopyKey_$d.
	LineKey_$f.
	CurveKey_$g.
	BlockKey_$h.
	OverKey_$j.				"modes"
	UnderKey_$k.
	ReverseKey_$l.
	EraseKey_$;.
	InKey_$'.					"file In"
	BitEditKey_$z.
	WhiteKey_$x.				"colors"
	LightGrayKey_$c.
	GrayKey_$v.
	DarkGrayKey_$b.
	BlackKey_$n.
	TogglexGridKey_$m.		"gridding"
	ToggleyGridKey_$,.
	ChangeGridsKey_$..
	OutKey_$/					"file Out"! !

FormEditor initialize!
