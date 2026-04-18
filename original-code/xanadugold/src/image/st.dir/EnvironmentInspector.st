'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:05 pm'!

DictionaryInspector subclass: #EnvironmentInspector
	instanceVariableNames: 'environment '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Environments'!
EnvironmentInspector comment:
'An instance of EnvironmentInspector is a kind of DictionaryInspector that maintains the dictionary for the local variables of the Environment to which it refers.
Instance Variables:
	environment	<Environment>'!


!EnvironmentInspector methodsFor: 'accessing'!

environment: anEnvironment 
	"Set the receiver's environment to be anEnvironment. Then the 
	receiver is set to inspect the local variables of anEnvironment. 
	Since the choice of environment can dynamcially change, be care to 
	handle dependency references."

	environment removeDependent: self.
	environment := anEnvironment.
	environment == nil
		ifTrue: [environment := Environment new].
	environment addDependent: self.
	self inspect: environment locals! !

!EnvironmentInspector methodsFor: 'dependents access'!

removeDependent: anObject
	"Clean up any dependency relationships when all dependents of the receiver are gone.
	This is usually when the last view on the receiver is closed."

	super removeDependent: anObject.
	dependents == nil
		ifTrue: [environment removeDependent: self]! !

!EnvironmentInspector methodsFor: 'updating'!

update: anAspect with: aParameter from: anObject 
	"Because some aspect of the receiver's local variables has changed, 
	the receiver informs its inspector. In one aspect (#locals), a new 
	variable has been added."

	anAspect == #locals
		ifTrue: 
			[self field: aParameter key.
			self update.
			self changed: #field.
			^self update].
	anAspect == #removedLocal
		ifTrue: 
			[self field == aParameter
				ifTrue: [self field: nil].
			self update.
			self changed: #field.
			^self update].
	anAspect == #localValue ifTrue: [^self update].
	^super
		update: anAspect
		with: aParameter
		from: anObject! !

!EnvironmentInspector methodsFor: 'menu commands'!

addField
	| aString key |
	aString := FillInTheBlank request: 'Enter key as a Smalltalk constant'.
	aString isEmpty ifTrue: [^self].
	key := aString asSymbol.
	object add: (Association key: key value: nil).
	field := key.
	self changed: #field! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EnvironmentInspector class
	instanceVariableNames: ''!


!EnvironmentInspector class methodsFor: 'view creation'!

inspectorFor: aModel in: aView box: rect 
	"Create the subviews for the dictionary inspector on aModel and put 
	it into aView at the relative location starting at originPoint."

	aView
		addSubView: (SelectionInListView
				on: aModel
				printItems: false
				oneItem: false
				aspect: #field
				change: #field:
				list: #fieldList
				menu: #fieldMenu
				initialSelection: #field)
		in: (rect origin corner: rect left + rect right / 2 @ rect bottom)
		borderWidth: 1.
	aView
		addSubView: (CodeView
				on: aModel
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu
				initialSelection: nil)
		in: (rect left + rect right / 2 @ rect top corner: rect corner)
		borderWidth: 1! !

!EnvironmentInspector class methodsFor: 'examples'!

openOn: anEnvironment 
	"Open a view of an EnvironmentInspector for an Environment. This 
	example permits the addition of fields in the inspector. A report goes 
	directly to the Environment that a new local variable has been 
	added."

	"EnvironmentInspector openOn: Environment new"

	| topView inspector |
	inspector := self new environment: anEnvironment.
	topView := StandardSystemView new label: 'An Environment Inspector'.
	topView borderWidth: 1.
	topView model: anEnvironment.
	topView minimumSize: 200 @ 150.
	self
		inspectorFor: inspector
		in: topView
		box: (0 @ 0 extent: 1 @ 1).
	topView controller open! !