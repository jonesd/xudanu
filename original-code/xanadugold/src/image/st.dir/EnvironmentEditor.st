'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:05 pm'!

Model subclass: #EnvironmentEditor
	instanceVariableNames: 'environment inspector '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Environments'!
EnvironmentEditor comment:
'An instance of EnvironmentEditor provides interactive support for editing the text of an Environment and its local variables.  In addition to a code editor, the instance provides dictionary inspection of the local variables declared in the Environment.  
Examples show an Environment Editor combined with various Browsers for browsing collections of Environments with simple lists or sophisticated hierarchical outlines.
Instance Variables:
	environment	<Environment>
	inspector		<EnvironmentInspector>'!


!EnvironmentEditor methodsFor: 'accessing'!

environment
	"Answer the receiver's environment."

	^environment!

environment: anEnvironment
	"Set the environment for the receiver to edit."

	environment := anEnvironment.
	environment == nil
		ifTrue: [environment := Environment new].
	self inspector environment: anEnvironment!

hasEnvironment
	"Answer true if the receiver has an environment,  otherwise answer false."

	^environment ~~ nil!

inspector
	"Answer the receiver's inspector."

	inspector == nil
		ifTrue: [inspector := EnvironmentInspector new.
				inspector environment: self environment].
	^inspector!

newValue
	"Answer an new value that the receiver can edit."

	^Environment new!

value
	"Answer the environment that the receiver is editing."

	^environment!

value: anEnvironment
	"Set the receiver's environment to be anEnvironment."

	self environment: anEnvironment.
	self changed: #text! !

!EnvironmentEditor methodsFor: 'text'!

acceptText: aText from: aController 
	"Accept the new text as the text for the current item's environment."

	self environment contents: aText copy.
	^true!

doItContext
	"Answer the context in which a text selection can be evaluated. 
	In this case, the context is the context of the selected environment, 
	in which local variables might be declared."

	^self environment doItContext!

doItReceiver
	"Answer the object that should be informed of the result of 
	evaluating a text selection. In this case, use the doItReceiver of the 
	current outline item."

	^self environment doItReceiver!

doItValue: ignored
	"Process the value returned from an evaluation of selected text."

	self environment doItValue: ignored.!

text
	"Answer the text in the environment of the currently selected item."

	| env |
	env := self environment.
	^env == nil
		ifTrue: [Text new]
		ifFalse: [env contents copy]!

textMenu
	"Answer a menu for the text view."

	"If the menu items hardcopy, style, font are desired because 
	Postscript printing of the environment is desired, then this is the 
	place to add it in. The corresponding messages are hardcopy 
	changeTextStyle changeFont."

	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EnvironmentEditor class
	instanceVariableNames: ''!


!EnvironmentEditor class methodsFor: 'instance creation'!

open: anEnvironment label: aString
	"Create an editor on the environment anEnvironment.  That is,	
	a workspace with local variables."

	"EnvironmentEditor open: Environment new label: 'Environment Editor'"

	| me topView textView |
	me := self new.
	me environment: anEnvironment.
	topView := StandardSystemView new.
	topView borderWidth: 1.
	topView model: me.
	topView label: aString.
	topView minimumSize: 200 @ 150.
	textView := CodeView 
					on: me
					aspect: #text
					change: #acceptText:from:
					menu: #textMenu.
	textView controller: AlwaysAcceptCodeController new.
	topView
		addSubView: textView
		in: (0 @ 0 extent: 1.0 @ 0.6)
		borderWidth: 1.
	EnvironmentInspector
		inspectorFor: me inspector
		in: topView
		box: ( 0 @ 0.6 extent: 1@0.4).
	topView controller open!

openOnFile: aFilename 
	"Open an editor on information loaded
	from the file whose name is aFilename."

	"EnvironmentEditor openOnFile: 'testing'"

	| root |
	root := BinaryStorage fromFileNamed: aFilename.
	(root isKindOf: AssociationTree)
		ifTrue: [self openOutlineBrowserOn: root label: root key].
	(root isKindOf: SequenceableCollection)
		ifTrue: [self openListBrowserOn: root label: aFilename].
	(root isKindOf: Environment)
		ifTrue: [^self open: root label: aFilename].
	self error: 'unknown object'! !

!EnvironmentEditor class methodsFor: 'browser creation'!

openListBrowserOn: anAssociationList label: aString 
	"Create a browser that provides a simple list of names for accessing 
	Environments."

	"EnvironmentEditor 
				openListBrowserOn: OrderedCollection new
				label: 'Rolodex'"

	| topView textView listBrowser listView environmentEditor |
	environmentEditor := self new.
	listBrowser := ListBrowser new.
	listBrowser editor: environmentEditor.
	listBrowser list: anAssociationList accessor: (NameAccessor name: #key).
	topView := StandardSystemView new.
	topView borderWidth: 1.
	topView model: listBrowser.
	topView label: aString.
	topView minimumSize: 200 @ 150.
	topView controller: CollectionBrowserController new.
	listView := ListSelectionView
				on: listBrowser selectionHolder
				menuChannel: (MessageSend receiver: listBrowser selector: #selectionListMenu)
				changeRequestChannel: 
					[environmentEditor changeRequest and:
						[environmentEditor inspector changeRequest]].
	topView
		addSubView: listView
		in: (0 @ 0 extent: 1.0 @ 0.3)
		borderWidth: 1.
	textView := OnlyWhenSelectedCodeView
				on: environmentEditor
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu
				initialSelection: nil
				selection: #hasEnvironment.
	topView
		addSubView: textView
		in: (0 @ 0.3 extent: 1.0 @ 0.5)
		borderWidth: 1.
	EnvironmentInspector
		inspectorFor: environmentEditor inspector
		in: topView
		box: (0 @ 0.8 extent: 1 @ 0.2).
	topView controller open!

openOutlineBrowserOn: anAssociationTree label: aString
	"Create a browser that provides a hierarchical outline of names for accessing 
	Environments."

	" | path | 	
	  path := ':Tutorial:'.
	  EnvironmentEditor 
		openOutlineBrowserOn: (BinaryStorage fromFileNamed: path, 'Tutorial-Text') 
		label: 'Tutorial Browser'."

	"EnvironmentEditor 
		openOutlineBrowserOn: (AssociationTreeWithParent key: 'Tutorial' value: Environment new)
		label: 'Tutorial Browser'"

	| topView textView outlineBrowser listView environmentEditor |
	environmentEditor := self new.
	outlineBrowser := OutlineBrowser new.
	outlineBrowser editor: environmentEditor.
	outlineBrowser
		tree: anAssociationTree
		accessor: (TreeAccessor isLeaf: #isLeaf children: #children name: #key).
	topView := StandardSystemView new.
	topView borderWidth: 1.
	topView model: outlineBrowser.
	topView label: aString.
	topView minimumSize: 200 @ 150.
	topView controller: CollectionBrowserController new.
	listView := ListSelectionView
				on: outlineBrowser selectionHolder
				menuChannel: (MessageSend receiver: outlineBrowser selector: #selectionListMenu)
				changeRequestChannel: 
					[environmentEditor changeRequest and:
						[environmentEditor inspector changeRequest]].
	topView
		addSubView: listView
		in: (0 @ 0 extent: 1.0 @ 0.3)
		borderWidth: 1.
	textView := CodeView
				on: environmentEditor
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu.
	textView controller: AlwaysAcceptCodeController new.
	topView
		addSubView: textView
		in: (0 @ 0.3 extent: 1.0 @ 0.5)
		borderWidth: 1.
	EnvironmentInspector
		inspectorFor: environmentEditor inspector
		in: topView
		box: (0 @ 0.8 extent: 1 @ 0.2).
	topView controller open! !