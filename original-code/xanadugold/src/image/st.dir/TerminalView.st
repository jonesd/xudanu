'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:19 pm'!

TextCollectorView subclass: #TerminalView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Terminal'!
TerminalView comment:
'Instances of TerminalView are the default view for a Terminal.'!


!TerminalView methodsFor: 'emphasis'!

deEmphasizeView
	"Check that the interruptKey state is correct."

	self controller checkInterruptKey.
	super deEmphasizeView! !

!TerminalView methodsFor: 'controller access'!

defaultControllerClass
	
	^TerminalController! !

!TerminalView methodsFor: 'updating'!

update: aParameter 
	"Process a dependency message."

	aParameter == #backspace
				ifTrue:	[^controller removeLastCharacter].
	super update: aParameter! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TerminalView class
	instanceVariableNames: ''!


!TerminalView class methodsFor: 'instance creation'!

openOn: aTerminal label: aString
	"Creates a StandardSystemView with a TextCollectorView as a subview,
 	both having aTerminal as their model. "

	| topView aView style|
	topView _ StandardSystemView new.
	topView model: aTerminal.
	topView label: aString.
	topView minimumSize: 160@120.
	topView borderWidth: 1.
	aView _ TerminalView new model: aTerminal.
	topView addSubView: aView in: (0@0 extent: 1@1) borderWidth: 1.
	style _ TextStyle styleNamed: #fixed ifAbsent: [nil].
	style == nil ifTrue: [style _ TextStyle default].
	aView displayContents textStyle: style.
	topView controller openNoTerminate.
	topView icon: (Icon constantNamed: #default).
	aTerminal startReceiveProcess.
	Cursor normal show.
	Processor terminateActive! !