'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:19 pm'!

TextCollectorController subclass: #TerminalController
	instanceVariableNames: ''
	classVariableNames: 'SavedInterruptKey '
	poolDictionaries: ''
	category: 'Tools-Terminal'!
TerminalController comment:
'An instance of TerminalController writes the characters that are typed to its model (aTerminal).

Class Variables:
	SavedInterruptKey	<SmallInteger> This variable refers to what the system is really using for system interrupt.  The terminal changes it to be something different, and restores upon control terminate.'!


!TerminalController methodsFor: 'initialize-release'!

release
	"Overridden to allow some necessary clean-up by Terminals."

	super release.
	model release! !

!TerminalController methodsFor: 'basic control sequence'!

controlInitialize
	"Save the key that interrupts the system and install a different one so I can have a different meaning for control c."

	SavedInterruptKey _ InputState interruptKey.
	InputState interruptKey: 162. "L3 key"
	^super controlInitialize!

controlTerminate
	"Return the interrupt key to its saved value."

	InputState interruptKey: SavedInterruptKey.
	^super controlTerminate! !

!TerminalController methodsFor: 'control defaults'!

controlActivity 
	"This is needed to make the caret show."

	selectionShowing ifFalse: [self select].
	super controlActivity! !

!TerminalController methodsFor: 'editing'!

readKeyboard
	"Sends keyboard characters to the model (a Terminal)."

	| buffer |
	buffer _ WriteStream on: (String new: 20).
	[sensor keyboardPressed] whileTrue: [buffer nextPut: sensor keyboard. ].
	(model sendAll: buffer contents) ifFalse: [view flash].! !

!TerminalController methodsFor: 'menu messages'!

close
	"Close the terminal."

	model close.		"close the port."!

reset
	"Reset the Model."

	model reset.
	self cancel!

sendPasteBuffer
	"Send paste buffer to model."

	(model sendAll: CurrentSelection asString)
		ifFalse: [view flash].! !

!TerminalController methodsFor: 'entry control'!

removeLastCharacter
	"Remove the last character from the editable text."

	view topView isCollapsed
		ifTrue:
			[paragraph text replaceFrom: 1 to: paragraph text size with: model contents]
		ifFalse: 
			[self deselect.
			startBlock _ paragraph characterBlockForIndex: paragraph text size.
			stopBlock _ paragraph characterBlockForIndex: paragraph text size + 1.
			self replaceSelectionWith: Text new.
			self selectWithoutComp: paragraph text size + 1.
			self selectAndScroll.
			self deselect]! !

!TerminalController methodsFor: 'private: private'!

checkInterruptKey
	"Check that the interruptKey state is correct."

	SavedInterruptKey == InputState interruptKey
		ifFalse: [InputState interruptKey: SavedInterruptKey]!

yellowButtonMenu
	"Menu for pseudo-terminal window."
	"Sets up our yellow button commands."

	^PopUpMenu fromArray: #(
		('again'		again				'')	"All are standard smalltalk."
		-
		('copy'		copySelection		'')
		('paste'		sendPasteBuffer	'')
		-
		('do it'		doIt					'')
		('inspect'	inspectIt			'')
		-
		('reset'		reset				'') ).! !

!TerminalController methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for pseudo-terminal window."
	"Sets up our yellow button commands."

	self passe! !