'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:06 pm'!

InteractiveCompilerErrorHandler subclass: #InteractiveEnvironmentCompilerErrorHandler
	instanceVariableNames: 'environment '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Environments'!
InteractiveEnvironmentCompilerErrorHandler comment:
'InteractiveEnvironmentCompiler represents a specialized InteractiveCompilerErrorHandler used when compiling expressions in the context of an Environment. The instance receives error notifications during code generation, and converts them to interactive messages. Then the instance adds the ''local'' option to the default set provided by its superclass. Thus, users can define variables to be local to a given environment.
Instance Variables:
	environment	<Environment> 	the context for the compilation''
'!


!InteractiveEnvironmentCompilerErrorHandler methodsFor: 'accessing'!

environment: anEnvironment 
	"Set the environment used by the receiver."

	environment := anEnvironment! !

!InteractiveEnvironmentCompilerErrorHandler methodsFor: 'private: private'!

declareLocal: assoc from: codeStream 
	"The user has selected local, so add the association to the receiver's 
	local variables."

	assoc key: assoc key asSymbol.
	environment addNewBinding: assoc.
	^true!

getChoiceMenu
	"Menu for when the environment compiler notices a reference to an undeclared variable."

	^PopUpMenu fromArray: #(
		('temp'			declareTemp:from:		'')	"All are standard smalltalk."
		('class var'		declareClassVar:from:	'')
		('global'		declareGlobal:from:		'')
		('undeclared'	declareUndeclared:from:	'')
		('local'			declareLocal:from:		'')
		-
		('correct it'		declareCorrect:from:	'')
		('abort'			declareFailed:from:		'') ).!

undeclared: association at: sourceRange from: codeStream 
	"An undeclared variable has been detected. Present the user with a 
	menu of options from which a selection is to be made."

	| menu index |
	Cursor normal show.
	self selectRange: sourceRange.
	menu := self getChoiceMenu.
	index := menu startUpWithHeading: ' declare ' asText , (association key contractTo: 40) asText allBold , ' as ' asText.
	index = 0 ifTrue: [^self declareFailed: association from: codeStream].
	^self
		perform: (menu selectorAt: index)
		with: association
		with: codeStream! !