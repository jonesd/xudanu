'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:36 pm'!

Controller subclass: #ScreenController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Support'!
ScreenController comment:
'Class ScreenController represents the controller for the parts of the display screen that have no window on them.  It only provides a standard operate button menu and views (a FormView of) an infinite gray form.

Class Variables:

	ScreenYellowButtonMenu		<PopUpMenu>
	ScreenYellowButtonMessages 	<Array of: Symbols>'!


!ScreenController methodsFor: 'initialize-release'! !

!ScreenController methodsFor: 'control defaults'!

isControlWanted
	^super isControlWanted and: [sensor anyButtonPressed]! !

!ScreenController methodsFor: 'menu messages'!

baseline
	"set the baseline for looking at changes."
	
	| base |
	base _ ChangeLog chooseAny: #(FORK NOTE FILEOUT FILEIN) initially: ChangeLog baseline.
	base ~= -1 ifTrue: [ChangeLog baseline: base].!

browseOverrides
	"browse methods since the baseline that have overridden stuff since a divergence point I choose"
	ChangeLog browseOverridesFrom: ChangeLog logPosition
		backTo: ChangeLog baseline
		of: (ChangeLog chooseAny: #(FORK NOTE) from: ChangeLog baseline - 1 backTo: -1)!

browseRecentHistory

	ChangeLog browseLast: 100!

closeInspectors
	"Close all active inspectors"
	
	ScheduledControllers scheduledControllers do:
		[ :controller |
		(controller view isKindOf: InspectorView)
			ifTrue: [controller closeAndUnschedule]]!

closeNotifiers
	"Close all active notifiers"
	
	ScheduledControllers scheduledControllers do:
		[ :controller |
		(controller view isKindOf: NotifierView)
			ifTrue: [controller closeAndUnschedule]]!

conflicts

	ChangeLog browseConflictsBackTo: ChangeLog baseline!

exitProject
	"Answer to the project in which the current project was defined."

	Project current exit!

fastbaseline
	"set the baseline for looking at changes."
	
	| base |
	base _ ChangeLog chooseAny: #(FORK NOTE FILEOUT FILEIN) initially: ChangeLog baseline limit: 20.
	base ~= -1 ifTrue: [ChangeLog baseline: base].!

fileOutAllChanges
	"file out all changes since the baseline"
	
	| fileName fileStream |
	self note.
	fileName _ Filename requestFileName: 'File out on'
		default: (ChangeRecorder changesFile)
		version: #any
		ifFail: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	ChangeLog logFileOutAllAfter: ChangeLog baseline named: fileName.
	fileStream nextChunkPut: 'ChangeLog user: ' , ChangeLog user storeString.
	ChangeLog fileOutChanges: #RECORD backTo: (ChangeLog baseline max: 0) onto: fileStream]
		valueNowOrOnUnwindDo: [fileStream close]!

fileOutMyChanges
	"file out all changes since the baseline"
	
	| fileName fileStream |
	self note.
	fileName _ Filename requestFileName: 'File out on'
		default: (ChangeRecorder changesFile)
		version: #any
		ifFail: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	ChangeLog logFileOutAllAfter: ChangeLog baseline named: fileName.
	fileStream nextChunkPut: 'ChangeLog user: ' , ChangeLog user storeString.
	ChangeLog fileOutChanges: ChangeLog user backTo: (ChangeLog baseline max: 0) onto: fileStream]
		valueNowOrOnUnwindDo: [fileStream close]!

{NOWAIT} findMethods
	"Xu: Apply criteria from a FindMenu to all the methods in the system, and bring up a method set browser on the result."

	| filter {MethodFilter | nil} |
	filter := MethodFilter fetchFromMenu.
	filter ~~ nil ifTrue: [filter browse]!

findWindow
	ScheduledControllers findWindow!

fork

	| comment |
	comment _ FillInTheBlank request: 'Version fork comment?'.
	comment isEmpty ifFalse: [ChangeLog logFork: comment]!

garbageCollect
	"Initiate the Smalltalk garbage collector. Cursor changes shape; wait 
	until the shape returns to its prior form."

	Smalltalk garbageCollect!

{void} liveMenusOff

	PopUpMenu liveMenus: false!

{void} liveMenusOn

	PopUpMenu liveMenus: true!

note

	| comment |
	comment _ FillInTheBlank request: 'ChangeLog note?'.
	comment isEmpty ifFalse: [ChangeLog logNote: comment]!

openBrowser
	"Create a system class browser."

	BrowserView openOn: SystemOrganization!

openCxxBrowser
	"Create a cxx browser."

	CxxBrowserView openOutline!

openDeskTop
	"In most systems, suspend the running Smalltalk-80 system and 
	collapse access to it from an icon. On the Macintosh, create and 
	display a menu of Desk Accessories."

	| anAcc list |
	(IOAccessor defaultClass respondsTo: #getAccessories)
		ifFalse: [^Smalltalk suspend].
	list _ IOAccessor defaultClass getAccessories.
	anAcc _ (PopUpMenu labelList: (Array with: list)) startUp.
	anAcc > 0 ifTrue: [IOAccessor defaultClass runAccessory: anAcc]!

openFileEditor
	"Prompt for a file name and open an editor on it."

	| aString prompt |
	[aString _ Filename
				requestFileName: 'Please type a file name: '
				default: ParagraphEditor currentSelection
				version: #any
				ifFail: [''].
	aString = ''
		ifTrue:	[^self]
		ifFalse: [Filename errorReporter inaccessableSignal
					handle: [ :ex | prompt _ ex parameter ]
					do: [(Filename named: aString) edit].
				self confirm: prompt,'\   Try again?' withCRs]] whileTrue!

openFileList
	"Create and schedule a FileList view for specifying files to access."
	HierarchicalFileList openOnPattern: '*'!

openProject
	"Create a new project."

	ProjectView open!

openProjectManager
	self unimplemented
	"ProjectSetManager open"!

openScreenSaver
	"Bounce the ParcPlace logo around the screen until a key or mouse 
	button is pressed."

	Form screenSaveWith: Form parcPlaceLogo velocity: 33@18 delay: 60!

openSystemWorkspace
	"Create and schedule a System Workspace."

	StringHolderView openSystemWorkspace.!

openTerminal
	"Prompt the user to frame a view containing one of the following: 1) 
	on platforms which support it, a Unix (tm) C shell; or 2) a 'dumb' 
	terminal serial port interface."

	ExternalProcess defaultClass == ExternalProcess
		ifTrue: [Terminal openTty]
		ifFalse: [Terminal openCsh]!

openTranscript
	"Create and schedule a system transcript."

	TextCollectorView open: Transcript label: 'System Transcript'!

openWorkspace
	"Create and schedule a workspace."

	StringHolderView open!

quit
	"Using a pop up menu, ask the user whether to save before quitting or not."

	| menu index imagePrefix |
	menu _ PopUpMenu labels: 
' Save, then quit 
 Quit, without saving 
 Continue '
		lines: #(1 2).
	index _ menu startUp.
	index = 1
		ifTrue:
			[imagePrefix _ Smalltalk getImagePrefix.
			imagePrefix isEmpty ifTrue: [^self].
			Smalltalk saveAs: imagePrefix thenQuit: true].
	index = 2 ifTrue: [Smalltalk quit]!

quitSmalltalk
	Smalltalk quit!

restoreDisplay
	"Redisplay all the scheduled views."

	ScheduledControllers restore!

save
	"Create a snapshot."

	| prefix |
	prefix _ Smalltalk getImagePrefix.
	prefix isEmpty ifTrue: [^self].
	Smalltalk saveAs: prefix thenQuit: false!

saveThenQuit
	| imagePrefix |
	imagePrefix _ Smalltalk getImagePrefix.
	imagePrefix isEmpty ifTrue: [^self].
	Smalltalk saveAs: imagePrefix thenQuit: true!

setBigCursor

	Cursor bigCursor: true!

{void} setGriddingTo16
	InputSensor grid: 16@16!

{void} setGriddingTo32
	InputSensor grid: 32@32!

{void} setGriddingTo8
	InputSensor grid: 8@8!

{void} setLongMenus
	PopUpMenu shortForm: false!

{void} setMenuHelpTimeout
	
	| string {String} stream {ReadStream of: Character} num {Integer} |
	string _ FillInTheBlank 
		request: 'How long till menu help string appears?' 
		initialAnswer: PopUpMenu helpThreshold printString.
	string == ''
		ifTrue: [^VOID].
	stream _ ReadStream on: string.
	num _ Integer readFrom: stream.
	stream atEnd not
		ifTrue: [Transcript cr; << 'Not understood: '; << string; cr; endEntry].
	PopUpMenu helpThreshold: num!

setNormalCursor

	Cursor bigCursor: false!

{void} setShortMenus
	PopUpMenu shortForm: true!

{void} setSourceFilterOff
	
	SourceMethods sourceOnly: false!

{void} setSourceFilterOn
	
	SourceMethods sourceOnly: true!

{void} setTranslationPathPrefix
	
	| answer {String} |
	answer _ FillInTheBlank request: 'Translation path prefix'
		initialAnswer: (CxxFilePrefix == nil ifTrue: [''] ifFalse: [CxxFilePrefix fluidVar]).
	answer = ''
		ifTrue: [^VOID].
	CxxFileOrganizer setPrefix: answer.!

setUserName
	| name |
	name _ FillInTheBlank request: 'User name' initialAnswer: ChangeLog user.
	(name isEmpty not and: [ChangeLog user ~= name])
		ifTrue: [ChangeRecorder user: name]!

showMethodHistory
	Browser showMethodHistory: true!

showMethodTemplate
	Browser showMethodHistory: false!

{void} toggleBusyMethodSetBrowser
	
	BrowserView methodSetViewBusy: BrowserView isMethodSetViewBusy not!

{void} toggleLiveMenus

	PopUpMenu toggleLiveMenus!

{void} turnGriddingOff
	InputSensor grid: 1@1! !

!ScreenController methodsFor: 'cursor'!

centerCursorInView
	"Override so this doesn't happen when taking control."! !

!ScreenController methodsFor: 'bit caching'!

flushDisplayBits
	"Get rid of the cached bits.  ScreenControllers do not cache bits"

	^self!

intersectsDisplayBoxOf: aController
	"Answer whether the receiver's view's display region intersects the 
	display region for aController's view."

	^false!

saveDisplayBits
	"Cache the receiver's view's image."!

showOnDisplay
	"Redisplay the image of the receiver's view."! !

!ScreenController methodsFor: 'control activity'!

controlActivity
	| sel |
	(sensor anyButtonPressed and: [self viewHasCursor]) 
		ifTrue: 
			[sel _ ScreenController screenMenu startUp.
			0 = sel ifFalse: [self menuMessageReceiver perform: sel]]!

idle
	"do nothing"!

isControlActive
	^(view containsPoint: sensor cursorPoint)
		and: [sensor anyButtonPressed]!

menuMessageReceiver
	"Answer the object that should be sent a message when a menu item is selected."
	^ self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScreenController class
	instanceVariableNames: ''!


!ScreenController class methodsFor: 'menus'!

oldScreenMenu
	"ScreenController oldScreenMenu startUp"
	
	self passe.		"Replaced with a new one."

	^PopUpMenu fromArray: #(
		('restore display'		restoreDisplay			'')
		('garbage collect'		garbageCollect			'')
		('screen saver'			openScreenSaver		'')
		('exit project'			exitProject				'')
		-
		('browser'				openBrowser			'')
		('workspace'			openWorkspace			'')
		('file list'				openFileList				'')
		('file editor'				openFileEditor			'')
		('terminal'				openTerminal			'')
		('project'				openProject				'')
		-
		('system transcript'	openTranscript			'')
		('system workspace'	openSystemWorkspace	'')
		-
		('desk top'				openDeskTop			'')
		-
		('save'					save					'')
		('quit'					quit						'') ).!

screenMenu
	"Background menu"
	
	"ScreenController screenMenu startUp"

	^PopUpMenu fromPrefixedArray: #(
		(all		'find window'					findWindow				'Xu: Prompt with a list of all the window labels, in order of increasing depth.  Bring the chosen window to the top.')
		(all		'spawn' (
			(all		'system browser'		openBrowser				'St: Bring up a System Browser')
			(all		'cxx browser'				openCxxBrowser			'Xu: Bring up a CxxBrowser.')
			(all		'find methods'			findMethods				'Xu: Apply criteria from a FindMenu to all the methods in the image, and bring up a method set browser on the result.') ))
		(all		'workspace'					openWorkspace			'')
		(all		'file list'						openFileList				'')
		-
		(short	'long menus'					setLongMenus			'Xu: Switch to displaying long menus.  In long menu form, other preferences are hidden under here')
		(long	'preferences' (
			(long	'short menus'				setShortMenus			'Xu: Switch to displaying short menus.')
			(dead	'live menus'				liveMenusOn				'Xu: Have menus popup under the cursor.')
			(live	'dead menus'		liveMenusOff				'Xu: Have menus popup immediately to the right of the cursor (so you have to slide right to select).')
			(long	'menu help timeout'		setMenuHelpTimeout		'Xu: Prompt for a number to determine how long to wait before printing out the menu help string')
			(sourceOnly	'all methods'		setSourceFilterOff		'Xu: Put the find system in a global mode where all methods are canidates even if they aren''t source methods')
			(allMethods	'sources only'	setSourceFilterOn		'Xu: Put the find system in a mode where the only candidates are source methods')
			-
			(long	'gridding' (
				(long	'off'					turnGriddingOff			'Xu: Windows can be put anywhere.')
				(long	'8@8'					setGriddingTo8			'Xu: Windows snap to 8-pixel boundaries.')
				(long	'16@16'				setGriddingTo16			'Xu: Windows snap to 16-pixel boundaries.')
				(long	'32@32'				setGriddingTo32			'Xu: Windows snap to 32-pixel boundaries.') ))
			(bigCursor	'normal cursor'		setNormalCursor		'Xu: restore normal arrow cursor')
			(normalCursor		'big cursor'			setBigCursor			'Xu: use big arrow cursor')
			(bogus	'toggle busy-methods'	toggleBusyMethodSetBrowser	'Xu: toggle whether the MethodSetBrowser (the kind returned from "find" requests) is simple or busy')
			(long	'method pane:' (
				(long	'history'				showMethodHistory	'Xu: show history of methods when none selected')
				(long	'template'				showMethodTemplate	'Xu: show method template when none selected') ))
			(long	'translation path prefix'	setTranslationPathPrefix	'Xu: prompt for a file path prefix.  Set it so translation will go there (and to its subdirectories)') ))
		(all		'other' (
			(all		'file editor'				openFileEditor			'')
			(all		'terminal'				openTerminal			'')
			(all		'desktop'				openDeskTop			'')
			(all		'system transcript'	openTranscript			'')
			(all		'system workspace'	openSystemWorkspace	'') ))
		(all		'changes' (
			(all		'set user '				setUserName			'Xu: Prompt for a user identifier.  Used to identify author of editing changes and name file outs (until next time it''s changed).')
			(all		'set baseline'			fastbaseline				'Xu: Prompt with a menu of significant events in the change history.  Changes baseline to chosen event. Limited to last 10 significant events.')
			(all		'set baseline(long)'			baseline				'Xu: Prompt with a menu of significant events in the change history.  Changes baseline to chosen event. Limited to 150 items unless shift key held down, then all items are presented.')
			(all		'version fork'			fork						'Xu: Prompt for a name.  Use it and the time to label the current state as a significant event.')
			(all		'change annotation'	note					'Xu: Label significant events, as with version fork, but in a way that files in and out with nearby changes.  Initially intended to record which bug is addressed by a set of changes.')
			-
			(all		'browse conflicts (slow)' conflicts				'Xu: Browse all conflicts since the baseline.  A conflict is when two or more users have made changes to the same entity.')
			(all		'browse Overrides (slow)'	browseOverrides	'Xu: Browse all conflicts between any code since the baseline and other peoples code from there back to a divergence point chosen from a menu')
			(all		'file out mine'			fileOutMyChanges		'Xu: Prompt for a name (default generated from user''s name).  File out all changes made by the current user since the baseline.')
			(all		'file out all'			fileOutAllChanges		'Xu: Prompt for a name (default generated from user''s name).  File out all changes made since the baseline.') ))
		(all		'system' (
			(all		'restore display'		restoreDisplay			'')
			(all		'close inspectors'		closeInspectors			'Xu: Close all inspector windows.')
			(all		'close notifiers'		closeNotifiers				'Xu: Close all notifier windows.')
			(all		'garbage collect'		garbageCollect			'')
			-
			(all		'save'					save					'')
			(all		'save then quit'		saveThenQuit			'')
			(all		'quit' (
				(all		'confirm'				quitSmalltalk			'') ))) ))! !