'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:56 pm'!

Model subclass: #CollectionBrowser
	instanceVariableNames: 'valueEditor modified filename '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Structures'!
CollectionBrowser comment:
'A CollectionBrowser is an abstract class description for structure browsing.  It does not know the values of the elements of its structure, but rather knows a kind of editor that has knowledge about the values of the elements.  An instance of a subclass of CollectionBrowser:
	manages the operations for modifying the structure, the browser
	knows whether or not the structure has been changed but not saved
	knows where, if any, the structure has been stored externally
	is able to store and retrieve the structure (using binary storage mechanisms)
	knows the Editor for the elements of the collection and finds out values from the Editor
This means that the CollectionBrowser provides a framework for full pluggability.  Using subclasses, different kinds of structures can be edited.  Using composition with other browsers, lists, trees,  or other structures can provide references to different kinds of values.  See ListBrowser or EnvironmentBrowser as examples.
Subclasses must implement:
	accessing
		collection
		selectionHolder
	storing-loading
		loadedNewCollection:
	private
		newItemWithKey:value:
Instance Variables:
	valueEditor		<Object>	that understands value, value:, and newValue
	modified		<Boolean>
	filename		<String> '!


!CollectionBrowser methodsFor: 'initialize-release'!

initialize
	"Specify the default values for the receiver's instance variables."

	modified := false! !

!CollectionBrowser methodsFor: 'accessing'!

collection
	"Answer the collection that the receiver is browsing."
	
	^self subclassResponsibility!

editor
	"Answer the receiver's value editor."

	^valueEditor!

editor: aValueEditor
	"Set the receiver's value editor to be aValueEditor."

	valueEditor := aValueEditor!

filename
	"Answer the name, if any, of the file from which the last information 
	for the receiver was loaded or saved."

	^filename == nil
		ifTrue: [String new]
		ifFalse: [filename]!

filename: aString 
	"Store aString as the name of the file from which the  
	information for the receiver is to be loaded or saved."

	filename := aString!

selected
	"Answer receiver's current selection or nil if nothing is selected."

	^self selectionHolder currentSelection!

selectedValue
	"Answer the value of the receiver's current selection or nil if nothing 
	is selected."

	| selection |
	selection := self selected.
	^selection == nil
		ifTrue: [nil]
		ifFalse: [selection value]!

selectionHolder
	"Answer the holder of the receiver's selection."

	^self subclassResponsibility! !

!CollectionBrowser methodsFor: 'changing'!

closeRequest
	"Notify the user if the outline has not been saved. The user decides 
	whether to continue and lose the changes."

	^modified
		ifTrue: [self confirm: 'The collection has been altered.
Do you wish to discard those changes?']
		ifFalse: [valueEditor changeRequest]!

newLabel: aString
	"Sent by the user interface.  Do nothing,  subclasses might find meaning here."

	^self! !

!CollectionBrowser methodsFor: 'updating'!

update: anAspect with: aParameter from: anObject 
	"Receive a change notice from an object, denoted by anObject, 
	of whom the receiver is a dependent."

	anObject == self selectionHolder
		ifTrue: [^self
				updateSelection: anAspect
				with: aParameter
				from: anObject]
		ifFalse: [^super
				update: anAspect
				with: aParameter
				from: anObject]!

updateSelection: anAspect with: aParameter from: anObject 
	"Because of the dependency between the receiver and its own 
	selection holder, whenever the selection is changed, the 
	receiver is informed."

	anAspect == #currentSelection ifFalse: [^self].
	self setValueEditorsValue: self selectedValue! !

!CollectionBrowser methodsFor: 'storing-loading'!

load
	"Prompt the user for the name of a file from which a collection is to be 
	loaded. If the user provides no file name, then do nothing. If the file 
	does not exist, then inform the user and ask again. The loaded 
	collection is given to the receiver in the loadedNewCollection: message."

	| aFileName tmp |
	self changeRequest ifFalse: [^self].
	aFileName := nil.
	[aFileName isNil]
		whileTrue: 
			[aFileName := 
				FillInTheBlank request: 'Load information from file name' 
								initialAnswer: self filename.
			aFileName = '' ifTrue: [^nil].
			self filename: aFileName.
			Cursor read showWhile: [tmp := BinaryStorage fromFileNamed: aFileName].
			self loadedNewCollection: tmp.
			self noteModification]!

loadedNewCollection: aCollection
	"Additional structure has been retrieved. Insert it into the existing 
	structure after the current selection."

	^self subclassResponsibility!

save
	"Prompt the user for the name of a file into which to save the 
	receiver's collection. If the user types nothing, then do nothing."

	| aFileName |
	self changeRequest ifFalse: [^self].
	aFileName := FillInTheBlank request: 'File name for saving the outline ' 
							initialAnswer: self filename.
	aFileName = '' ifTrue: [^nil].
	aFileName asFilename exists ifTrue:
		[(self confirm: 'File already exists.  Proceed to overwrite?')
			ifFalse: [^nil]].
	self filename: aFileName.
	Cursor write showWhile: 
		[self inCleanDependencyEnvironmentDo: 
				[BinaryStorage put: self collection onFileNamed: aFileName]].
	modified := false! !

!CollectionBrowser methodsFor: 'dependents access'!

removeDependent: anObject
	"Clean up any dependency relationships when all dependents of the receiver are gone.
	This is usually when the last view on the receiver is closed."

	super removeDependent: anObject.
	dependents == nil
		ifTrue: [valueEditor release]! !

!CollectionBrowser methodsFor: 'private: private'!

inCleanDependencyEnvironmentDo: aBlock 
	"Execute aBlock with selected dependency relationships of the 
	receiver removed. This is useful with binary storage."

	self setValueEditorsValue: nil.
	aBlock valueNowOrOnUnwindDo: [self setValueEditorsValue: self selectedValue]!

newFor: newCategory 
	"Answer a new list item."

	^self newItemWithKey: newCategory value: self newItemValue!

newItemValue
	"Answer an prototypical value to store in the receivers collection."

	^valueEditor == nil
		ifFalse: [valueEditor newValue]
		ifTrue: [nil]!

newItemWithKey: newCategory value: newValue 
	"Answer an item with newCategory as the key and newValue 
	as the value."

	^self subclassResponsibility!

noteModification
	"Note that receiver's list has changed."

	modified := true!

setValueEditorsValue: aValue
	"Give aValue to the value editor to edit."

	valueEditor == nil
		ifFalse: [valueEditor value == aValue
					ifFalse: [valueEditor value: aValue]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CollectionBrowser class
	instanceVariableNames: ''!


!CollectionBrowser class methodsFor: 'instance creation'!

new
	"Answer an initialized instance of the receiver."

	^super new initialize!

openOnFile: aFilename with: anEditor 
	"Open a collection browser on a new collection, loading the 
	information from the file whose name is aFilename. Use anEditor as 
	the editor for the values accessed through the collection.  This
	editor must respond to the message openOnFile:.  All examples
	of using a kind of CollectionBrowser are found in an associated
	editor."

	^anEditor openOnFile: aFilename! !