'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:13 pm'!

MouseMenuController subclass: #EntController
	instanceVariableNames: 'vertHorz '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tree-Showing'!


!EntController methodsFor: 'initialize-release'!

initialize
	"EntController initialize"
	super initialize.
	vertHorz _ true.!

yellowButtonMenu
	| sel menuString |
	menuString _ 
		'basic inspect[basicInspect]
		inspect[inspect]
		audition[audition]'.
	sel _ view selection.
	
	sel == nil ifTrue:
		[^PopUpMenu fromArray: #(
			('basic inspect'			basicInspectModel	'')
			('inspect'				inspectModel		'')
			('toggle orientation'	toggleVertHorz		'') )]
			
	ifFalse: [(sel host respondsTo: #inspectMenu) ifTrue:
		[^(MenuBuilder parseFrom: (ReadStream on: model host inspectMenu, menuString)) menu]
		"^----- (guts of PopUpMenu>fromString:  ^-----------------------------^) -----^	"
		
	ifFalse:
		[^PopUpMenu fromString: menuString]]! !

!EntController methodsFor: 'control defaults'!

isControlActive
	"Inherits control from superclass MouseMenuController.
	As the blue blutton menu is used for reframing views only, counters are to be activated
	by pressing the other two buttons."

	^super isControlActive & sensor blueButtonPressed not!

menuMessageReceiver
	| sel | 
	sel _ view selection.
	^nil = sel ifTrue: [self] ifFalse: [sel host]!

redButtonActivity
	| oldSelection |
	oldSelection _ view selection.
	oldSelection notNil 
		ifTrue: [ model highlight: oldSelection origin: (view insetDisplayBox origin)].
	(view selection: 
		(model containingPoint: Sensor cursorPoint - view insetDisplayBox origin)) notNil 
		ifTrue: [model highlight: (view selection) origin: (view insetDisplayBox origin)].
	Sensor waitNoButton! !

!EntController methodsFor: 'menu messages'!

basicInspectModel
	self view selection basicInspect!

browseSelection
	view selection notNil ifTrue: [EntView openOn: view selection]!

inspectModel
	self view selection inspect!

toggleVertHorz
	vertHorz _ vertHorz not.
	model changed: #all! !

!EntController methodsFor: 'smalltalk: passe'!

setYellowButtonMenu
	| sel menuArray  |
	
	self passe.
	menuArray _ 
		#(
			('basic inspect'	basicInspect	'')
			('inspect'		inspect			'')
			('audition'		audition		'')).
		
	sel _ view selection.
	
	sel == nil ifTrue:
		[self yellowButtonMenu: (PopUpMenu fromArray: #(
			('basic inspect'			basicInspectModel	'')
			('inspect'				inspectModel		'')
			('toggle orientation'	toggleVertHorz		'') ) )]
			
	ifFalse: [(sel host respondsTo: #inspectMenuArray) ifTrue:
		[ | menuArraySize inspectMenuArray inspectMenuArraySize combinedArray |
		
			inspectMenuArray _ sel host inspectMenuArray.
			inspectMenuArraySize _ inspectMenuArray size.
			menuArraySize _ menuArray size.
			combinedArray _ Array new: (inspectMenuArraySize + menuArraySize).
			1 to: inspectMenuArraySize do: [ :index | combinedArray at: index put: (inspectMenuArray at: index)].
			1 to: menuArraySize do: [ :index | combinedArray at: index + inspectMenuArraySize put: (menuArray at: index)].
		
			self yellowButtonMenu: (PopUpMenu fromArray: combinedArray)]
		
	ifFalse:
		[self yellowButtonMenu: (PopUpMenu fromArray: menuArray)]]! !