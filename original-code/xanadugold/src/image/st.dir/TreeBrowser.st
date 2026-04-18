'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:00 pm'!

Model subclass: #TreeBrowser
	instanceVariableNames: 'tree treeSelection '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Tree'!
TreeBrowser comment:
'An instance of TreeEditor provides an interface to create and modify trees as indented lists.
Instance Variables:
	tree			<Object>			any object for which a TreeAccessor can provide translation 
	treeSelection	<TreeSelection>		an object that remembers a current selection for the tree-like object'!


!TreeBrowser methodsFor: 'initialize-release'!

tree: aTree 
	"Set the receiver's tree to be aTree."

	tree := aTree.
	treeSelection tree: aTree!

tree: aTree accessor: aTreeAccessor 
	"Set the receiver's tree to be aTree. Access the tree with 
	aTreeAccessor."

	treeSelection := IndentedTreeSelection new.
	treeSelection treeAccessor: aTreeAccessor.
	treeSelection addDependent: self.
	self tree: aTree! !

!TreeBrowser methodsFor: 'accessing'!

currentChild
	"Answer the receiver's currently selected child."

	^treeSelection currentSelection!

currentChild: aChild
	"Set the receiver's currently selected child to be aChild."

	^treeSelection currentSelection: aChild!

tree
	"Answer the receiver's tree."

	^tree!

treeSelection
	"Answer the receiver's tree selection."

	^treeSelection! !

!TreeBrowser methodsFor: 'open set accessing'!

closeCurrent
	"Close the receiver's current selection."

	treeSelection closeCurrent!

deepCloseCurrent
	"Close the receivers current selection and all of its children."

	treeSelection deepCloseCurrent!

deepOpenCurrent
	"Open the receiver's current selection and all of its children."

	treeSelection deepOpenCurrent!

openCurrent
	"Open the receiver's current selection."

	treeSelection openCurrent! !

!TreeBrowser methodsFor: 'updating'!

update: anAspect with: aParameter from: anObject 
	"Receive a change notice from an object, denoted by aSender, 
	of whom the receiver is a dependent."

	anObject == 
		treeSelection 
			ifTrue: [self
					updateTreeSelection: anAspect
					with: aParameter
					from: anObject]!

updateTreeSelection: anAspect with: aParameter from: anObject 
	"The receiver's tree selection has changed. The default is to do 
	nothing."! !

!TreeBrowser methodsFor: 'menu messages'!

selectionListMenu
	"Menu for TreeBrowser, which seems to be some unused tree-as-outline thingie from smalltalk." 
	
	^PopUpMenu fromArray: #(
		('open'			openCurrent		'')	"All are standard smalltalk."
		('close'			closeCurrent		'')
		('deep open'	deepOpenCurrent	'')
		('deep close'	deepCloseCurrent	'') ).! !

!TreeBrowser methodsFor: 'dependents access'!

removeDependent: anObject
	"Clean up any dependency relationships when all dependents of the receiver are gone.
	This is usually when the last view on the receiver is closed."

	super removeDependent: anObject.
	dependents == nil
		ifTrue: [self cleanUpDependency]! !

!TreeBrowser methodsFor: 'private: private'!

cleanUpDependency
	"Clean up any dependency relationships that the receiver has."!

inCleanDependencyEnvironmentDo: aBlock 
	"Execute aBlock with selected dependency relationships of the 
	receiver removed.  This is useful with binary storage."

	self cleanUpDependency.
	aBlock valueNowOrOnUnwindDo: [self setUpDependency]!

setUpDependency
	"Set up any dependency relationships that the receiver needs."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TreeBrowser class
	instanceVariableNames: ''!


!TreeBrowser class methodsFor: 'examples'!

editClass: aClass 
	"Open a tree editor on aClass. The tree-like behavior for a class 
	is assumed to be the subclass hierarchy."

	"TreeBrowser editClass: Object"

	| me topView listView treeAccessor |
	treeAccessor := TreeAccessor children: #subclasses name: #name.
	me := self new.
	me tree: aClass accessor: treeAccessor.
	topView := StandardSystemView new label: aClass name asString.
	topView borderWidth: 1.
	topView insideColor: Form white.
	listView := self getListViewFor: me.
	listView borderWidth: 1.
	topView addSubView: listView.
	topView controller open! !

!TreeBrowser class methodsFor: 'private: private'!

getListViewFor: aTreeEditor
	"Answer an initialized list view on aTreeEditor."

	^ListSelectionView
			on: aTreeEditor treeSelection
			menuChannel: (MessageSend receiver: aTreeEditor selector: #selectionListMenu)
			changeRequestChannel: [aTreeEditor changeRequest]! !