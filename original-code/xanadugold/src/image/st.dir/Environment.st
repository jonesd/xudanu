'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:04 pm'!

TextHolder subclass: #Environment
	instanceVariableNames: 'locals '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Environments'!
Environment comment:
'Instances of this class are workspaces with local variables. 
Environments are like index cards in the paper world.  Each Environment has some textual information.  In addition, each Environment has a dictionary of local variables that are created by executing expressions within the context of the Environment.  These local variables serve as a replacement for temporary or global variables (as they are used in workspaces) but differ in that they persist for the life of the Environment.
Instance Variables:
	locals	<Dictionary> that maintains the local variables associated with an environment'!


!Environment methodsFor: 'accessing'!

addNewBinding: anAssociation 
	"Add a new binding (value) to the receiver's local variables. This may 
	be of interest to dependents, so broadcast a change."

	self locals add: anAssociation.
	self changed: #locals with: anAssociation!

locals
	"Answer the receiver's local variable dictionary."

	locals == nil ifTrue: [locals := Dictionary new].
	^locals!

locals: aDictionary
	"Set the receiver's local variable dictionary to be aDictionary."

	locals := aDictionary!

localScopes
	"Answer an array containing the receiver's local variables. This is 
	used by an EnvironmentCompiler for determining the lexical scope of 
	variables."

	^Array with: self locals!

removeBinding: key {Object} 
	"Remove binding (value) to the receiver's local variables. This may 
	be of interest to dependents, so broadcast a change."

	self locals removeKey: key.
	self changed: #removedLocal with: key! !

!Environment methodsFor: 'copying'!

copy
	"Answer another instance just like the receiver, but with a copy of the receiver's locals."

	| copy |
	copy := self shallowCopy.
	copy breakDependents.
	locals == nil
		ifFalse: [| localsCopy |
				localsCopy := Dictionary new.
				locals associationsDo: [:assoc | localsCopy add: assoc copy].
				copy locals: localsCopy].
	^copy! !

!Environment methodsFor: 'doIt/accept/explain'!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection.  In this default case, anwer nil that no object is informed."

	^self!

doItValue: ignored 
	"Process the value returned from an evaluation of selected text. By 
	default, inform any dependents that there may be a new local 
	variable to display."

	self changed: #localValue! !

!Environment methodsFor: 'private: private'!

defaultContents
	^ Text new! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Environment class
	instanceVariableNames: ''!


!Environment class methodsFor: 'compiler access'!

evaluatorClass
	"Answer an evaluator class appropriate for evaluating expressions in the 
	context of instances of this class."

	^EnvironmentCompiler! !

!Environment class methodsFor: 'examples'!

openAsWorkspace
	"An Environment that looks like a Workspace but has local variables 
	is created by reusing the StringHolder view and controller."

	"Environment openAsWorkspace"

	StringHolderView open: Environment new label: 'Environment'!

openWithInspector1
	"An Environment that looks like a Workspace but has local variables 
	that appear in a dictionary inspector is created by reusing the 
	StringHolder view and controller as subviews (an inspector for a 
	DictionaryInspector is created). The inspector is formed with two 
	subviews--a SelectionInListView and a CodeView. 
	
	This is not a satisfactory solution because new local variables do 
	not automatically appear in the inspector, and the values of the 
	currently selected variable are not automatically displayed nor 
	updated."

	"Environment openWithInspector1"

	"
	To see it display, in the Environment text area, evaluate 
	DictionaryInspector allInstancesDo: [:e | e object = self locals ifTrue: 
	[e changed: #field. e update]] 
	"

	| me inspector aStringHolderView topView |
	me := self new.
	aStringHolderView := StringHolderView container: me.
	topView := StandardSystemView new.
	topView borderWidth: 1.
	topView model: me.
	topView label: 'An Environment'.
	topView minimumSize: 200 @ 150.
	topView
		addSubView: aStringHolderView
		in: (0 @ 0 extent: 1.0 @ 0.6)
		borderWidth: 1.
	inspector := DictionaryInspector inspect: me locals.
	topView
		addSubView: (SelectionInListView
				on: inspector
				printItems: false
				oneItem: false
				aspect: #field
				change: #field:
				list: #fieldList
				menu: #fieldMenu
				initialSelection: #field)
		in: (0@0.6 extent: 0.333 @ 0.4)
		borderWidth: 1.
	topView
		addSubView: (CodeView
				on: inspector
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu
				initialSelection: nil)
		in: (0.333 @ 0.6 extent: 0.666 @ 0.4)
		borderWidth: 1.

	topView controller open!

openWithInspector2
	"An Environment that looks like a Workspace but has local variables 
	that appear in a dictionary inspector is created by reusing the 
	StringHolder view and controller as subviews, but now an inspector 
	for an EnvironmentInspector is created. This inspector has the 
	Environment as a dependent so when a new local variable is added, 
	the inspector knows and can update its dictionary. 
	
	This is still not a satisfactory solution because the value of the 
	currently selected variable is not automatically updated."
	"Environment openWithInspector2"

	| me aStringHolderView topView |
	me := self new.
	aStringHolderView := StringHolderView container: me.
	topView := StandardSystemView new.
	topView borderWidth: 1.
	topView model: me.
	topView label: 'An Environment'.
	topView minimumSize: 200 @ 150.
	topView
		addSubView: aStringHolderView
		in: (0 @ 0 extent: 1.0 @ 0.6)
		borderWidth: 1.
	EnvironmentInspector
		inspectorFor: (EnvironmentInspector new environment: me)
		in: topView
		box: (0 @ 0.6 extent: 1@0.4).
	topView controller open! !