'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:19 pm'!

FMController subclass: #FMTextEditor
	instanceVariableNames: '
		myText {AttributedTextModel}
		mySelection {SelectionRange}
		currentAttributes {AttributeGroup}
		beginTypeIn {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Text'!
FMTextEditor comment:
'I am a controller for editing only the string content of text -- I don''t change the style, and I barely consult it.'!

(FMTextEditor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextEditor methodsFor: 'create/delete'!

create: textModel {AttributedTextModel} with: selection {SelectionRange}
	super create.
	myText _ textModel.
	"myText addDependent: self."
	mySelection _ selection.
	beginTypeIn _ IntegerVar0.
	self setCurrentAttributes! !

!FMTextEditor methodsFor: 'control'!

{void} handleEvent.cxx: event {FMEvent}
	"Types should be used for some of the event dispatching."
event keystroke ifTrue: 
		[| keyEvent {KeyEvent} | 
		keyEvent _ event cast: KeyEvent.
		beginTypeIn < IntegerVar0 ifTrue: 
			[beginTypeIn _ mySelection selectionPosition].
		 (self handleKeycodes: keyEvent) ifFalse: [self normalCharacter: (keyEvent keycode DOTasInt basicCast: Character)]].
		 
	 [event keystroke ifTrue:
		[| keyEvent {KeyEvent} | 
		keyEvent _ event cast: KeyEvent.
		beginTypeIn < IntegerVar0 ifTrue: 
			[beginTypeIn _ mySelection selectionPosition].
		 (self handleKeycodes: keyEvent) ifFalse: [self normalCharacter: keyEvent keycode]]
	"keystroke" ifFalse:
		[event selectDownFn ifTrue: [
			self commitTypeIn].
		event selectUpFn ifTrue: [self setCurrentAttributes]. 
		"key _ event key.
		key == #menu ifTrue: 
			[event isShiftDown ifTrue: 
				[key _ event at: #selector.
			 	 key == #again	ifTrue: [^self againLoop].
			 	 key == #paste	ifTrue: [^self pasteMenu: event point].
			 	 ^self perform: key]
			 ifFalse:
				[^self perform: (event at: #selector)]].
		 ""againStep is iterative.""
		 key == #againStep	ifTrue: [^self againStep].
		 event visible ifTrue:
		 	[key == #yellowDown	ifTrue: [self scheduleMenuFor: event]]"]]smalltalkOnly!

{BooleanVar} handleKeycodes.cxx: keyEvent {KeyEvent unused}
	"This method handles operations for each of the control
keys.  Return true if the keycode gets processed, false
otherwise.  This method can assume that the event is a
keystroke."

	"| key {KeyEnum} |
	key _ keyEvent keyName.
	key == #ESC		ifTrue: [self closeTypeIn.		^true].
	key == #Cut		ifTrue: [self cut.				^true].
	key == #Paste		ifTrue: [self paste.				^true].
	key == #BS		ifTrue: [self backspace.			^true].
	key == #BS2		ifTrue: [self leaveBrackets.		^true].
	key == #Ctrlw		ifTrue: [self backspaceWord.	^true].
	key == #Ctrla		ifTrue: [self backspace.			^true].
"	^false!

{BooleanVar} requestEvents.cxx: event {FMEvent}

	^event keystroke or: 
		[event selectUpFn or: 
		[event selectDownFn]]! !

!FMTextEditor methodsFor: 'smalltalk: smalltalk control'!

{void} handleEvent: event {FMEvent}
	"Types should be used for some of the event dispatching."
	event keystroke ifTrue:
		[| keyEvent {KeyEvent} | 
		keyEvent _ event cast: KeyEvent.
		beginTypeIn < IntegerVar0 ifTrue: 
			[beginTypeIn _ mySelection selectionPosition].
		 (self handleKeycodes: keyEvent) ifFalse: [self normalCharacter: keyEvent keycode]]
	"keystroke" ifFalse:
		[event selectDownFn ifTrue: [self commitTypeIn].
		event selectUpFn ifTrue: [self setCurrentAttributes]. 
		"key _ event key.
		key == #menu ifTrue: 
			[event isShiftDown ifTrue: 
				[key _ event at: #selector.
			 	 key == #again	ifTrue: [^self againLoop].
			 	 key == #paste	ifTrue: [^self pasteMenu: event point].
			 	 ^self perform: key]
			 ifFalse:
				[^self perform: (event at: #selector)]].
		 ""againStep is iterative.""
		 key == #againStep	ifTrue: [^self againStep].
		 event visible ifTrue:
		 	[key == #yellowDown	ifTrue: [self scheduleMenuFor: event]]"]!

{BooleanVar} handleKeycodes: keyEvent {KeyEvent}
	"This method handles operations for each of the control keys.  Return true if the keycode gets processed, false otherwise.  This method can assume that the event is a keystroke."

	| key {KeyEnum} |
	key _ keyEvent keyName.
	key == #ESC		ifTrue: [self closeTypeIn.		^true].
	key == #Cut		ifTrue: [self cut.				^true].
	key == #Paste		ifTrue: [self paste.				^true].
	key == #BS		ifTrue: [self backspace.			^true].
	key == #BS2		ifTrue: [self leaveBrackets.		^true].
	key == #Ctrlw		ifTrue: [self backspaceWord.	^true].
	key == #Ctrla		ifTrue: [self backspace.			^true].
	^false!

menuFor: event{FMEvent}
	"Return the approprate menu."

	^self menuWith: 
		#(((again undo) (copy cut paste) ('do it' 'print it' 'inspect it' 'open it') (accept cancel) (spy))
			(again undo copySelection cut paste doIt printIt inspectIt openIt accept cancel spy))!

{BooleanVar} requestEvents: event {FMEvent}

	^event keystroke or: 
		[event selectUpFn or: 
		[event selectDownFn]]! !

!FMTextEditor methodsFor: 'private: private attributes'!

{void} setCurrentAttributes
	"This should actually extract the attributes common across the 
	entire selection."

	mySelection = NULL
		ifTrue: [currentAttributes _ myText attributesAtInt: 1]
		ifFalse: [currentAttributes _ myText attributesAtInt: mySelection selectionPosition]! !

!FMTextEditor methodsFor: 'private: private text actions'!

{void}backspace
	mySelection selectionRange isEmpty
		ifTrue: [self deleteCharacter: (mySelection selectionPosition - 1 max: IntegerVar0)]
		ifFalse: [self cutSelection]!

{void} backspaceTo: index {IntegerVar}
[self halt] smalltalkOnly.
	mySelection setSelectionRange: (IntegerRegion make: index with: self selectionStop).
	beginTypeIn > index ifTrue: [beginTypeIn _ index].
	self cutSelection!

{void} backspaceWord
	"Back up to the beginning of the previous word. If the previous 
	character 
	is a separator, then back up to the beggining of the separators (the 
	end 
	of the last word). Right now it doesn't know the difference between 
	different kinds of non-space characters, so a word is any string of 
	non-separator characters."

	| pos {IntegerVar} flag {BooleanVar} alpha {FMAlphabet} |
	[AttributeGroup] USES.
	pos _ self selectionStart - 1 max: IntegerVar0.
	alpha _ (myText attributesAtInt: pos) alphabet.
	flag _ (alpha isSeparator: ((myText intFetch: pos)
					quickCast: Sequence)) not.
	[pos > IntegerVar0 and: [((myText attributesAtInt: pos) alphabet isSeparator: ((myText intFetch: pos)
				quickCast: Sequence))
			== flag]]
		whileTrue: [pos _ pos - 1].
	self backspaceTo: pos!

{void} closeTypeIn
	beginTypeIn < IntegerVar0 ifFalse: 
		[beginTypeIn < self selectionStart ifTrue: 
			[mySelection setSelectionRange: (mySelection selectionRange simpleUnion: 
								(IntegerRegion make: beginTypeIn))].
		beginTypeIn _ -1].
	myText commitInserts!

{void} commitTypeIn
	myText commitInserts!

{void}cut
	self closeTypeIn.
	self cutSelection.!

{void} cutSelection
	| region {XnRegion} |

	self thingToDo. "need to preserve cut chars?"
	region _ self selectedCharacters.
	region isEmpty not ifTrue: [myText deflate: region].
	mySelection setSelectionPosition: self selectionStart!

{void} deleteCharacter: charPosition {IntegerVar} 
	beginTypeIn > charPosition ifTrue: [beginTypeIn _ charPosition].
	myText deflate: (IntegerRegion make: charPosition)!

{void} insertCharacter: aChar {Character var} 
	myText insert: self selectionStart
			with: (AttributedTextModel make.char: aChar with: currentAttributes)!

{void} normalCharacter: character {char var} 
	"After replaceSelection, the mySelection will have the new text 
	selected (that is, the character just typed). To prevent typing 
	over the same character, update the selection to an insertion 
	point after the typed character."

	self selectedCharacters isEmpty
		ifTrue: [self insertCharacter: character]
		ifFalse: [self replaceSelection: 
					(AttributedTextModel make.char: character with: currentAttributes)].
	mySelection setSelectionPosition: mySelection selectionPosition + 1!

{void} replaceSelection: aText {AttributedTextModel} 
	| lowerBound {IntegerVar} realSelection {XnRegion} |
	lowerBound _ self selectionStart.	
	"This assumes that the lower bound of the selection is closed. 
	The textModel could instead take a distinction...."
	realSelection _ self selectedCharacters.
	realSelection isEmpty not ifTrue: 
		[myText deflate: realSelection].
	myText insert: lowerBound with: aText.
	mySelection setSelectionRange: 
		(IntegerRegion make: lowerBound with: lowerBound + aText count)!

{XnRegion} selectedCharacters
	^ mySelection selectionRange!

{IntegerVar} selectionStart
	mySelection selectionRange isEmpty
		ifTrue: [^mySelection selectionPosition]
		ifFalse: [^(mySelection selectionRange quickCast: IntegerRegion) start]!

{IntegerVar} selectionStop
	mySelection selectionRange isEmpty
		ifTrue: [^mySelection selectionPosition]
		ifFalse: [^(mySelection selectionRange quickCast: IntegerRegion) stop]! !

!FMTextEditor methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << ' on (' << myText << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMTextEditor class
	instanceVariableNames: ''!

(FMTextEditor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextEditor class methodsFor: 'pseudo constructors'!

make: textModel {AttributedTextModel} with: selection {SelectionRange}

	^ self create: textModel with: selection! !