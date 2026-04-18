'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:33 pm'!

CompilerErrorHandler subclass: #InteractiveCompilerErrorHandler
	instanceVariableNames: 'editor lengthChange '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
InteractiveCompilerErrorHandler comment:
'I receive error notifications during code generation, and convert them to interactive messages.'!


!InteractiveCompilerErrorHandler methodsFor: 'initialize-release'!

editor: ed
	editor _ ed.
	lengthChange _ 0! !

!InteractiveCompilerErrorHandler methodsFor: 'error handling'!

error: type with: message at: sourcePosition
	"Possible values of type:
		#syntax, message = error message
		#newSelector, message = selector"
	| position option |
	"Handlers return true for retry, false for proceed,
	or an error string or nil for abort."
	position _ sourcePosition.
	type == #newSelector
		ifTrue:
			[option _ self newSelector: message at: sourcePosition.
			position _ sourcePosition first first  "see CompilerErrorHandler for the description of sourcePosition"].
	^self
		errorOption: option
		messageBlock:
			[type == #syntax ifTrue: [message] ifFalse: [message , ' ' , type , ' -> ']]
		at: position!

error: type with: message in: node from: codeStream
	"Possible values of type:
		#error, message = error message
		#warning, message = error message
		#readBeforeWritten, message = var name
		#neverRead, message = var name, node = assignment
		#neverUsed, message = var name
		#redeclared, message = var name
		#redeclaredBlockArg, message = var name
		#undeclared, message = var Association
		#undeclaredStore, message = var Association, node = assignment
		#noEffect, message = nil, node = statement"
	| option |
	"Handlers return true for retry, false for proceed,
	or an error string or nil for abort."
	type == #warning
		ifTrue:
			[option _ self warning: message from: node].
	type == #redeclared
		ifTrue:
			[option _ self redeclared: message from: node].
	type == #redeclaredBlockArg
		ifTrue:
			[option _ self redeclaredBlockArg: message in: node from: codeStream].
	type == #undeclared
		ifTrue:
			[option _ self undeclared: message in: node from: codeStream].
	type == #undeclaredStore
		ifTrue:
			[option _ self undeclaredStore: message in: node from: codeStream].
	type == #readBeforeWritten
		ifTrue:
			[option _ self readBeforeWritten: message from: node].
	type == #neverRead
		ifTrue:
			[option _ self neverRead: message from: node].
	type == #neverUsed
		ifTrue:
			[option _ self neverUsed: message from: node].
	type == #noEffect
		ifTrue:
			[option _ self noEffect: node].
	^self
		errorOption: option
		messageBlock:
			[type == #error
				ifTrue: [message]
				ifFalse: [(message isNil ifTrue: [type] ifFalse: [message , ' ' , type]) , ' -> ']]
		at: node sourcePosition first! !

!InteractiveCompilerErrorHandler methodsFor: 'interaction'!

neverRead: name from: assignNode
	| index |
	index _ self startUp: 'remove\proceed\abort'
			for: name
			with: '''s value is never used '
			at: (assignNode variable sourcePosition first to: assignNode value absoluteSourcePosition-1).
	index = 1 ifTrue:
		[self removeEditSelection.  ^true  "retry"].
	index = 2 ifTrue: [^false  "proceed"].
	^''!

neverUsed: name from: varNode
	| index |
	index _ self startUp: 'remove it\proceed\abort'
			for: name
			with: ' is never used '
			from: varNode.
	index = 1 ifTrue:
		[self removeEditSelection.  ^true  "retry"].
	index = 2 ifTrue: [^false  "proceed"].
	^''!

newSelector: aString at: sourceRangeAndPos
	| sourceRange index menu oldStream list newSym posList posDiff |
	Cursor normal show.
	sourceRange _ sourceRangeAndPos first.
	self selectRange: sourceRange.
	list _ Symbol correctMessage: aString minimumScore: 50.
	list _ list collect: [:sym | sym key].
	menu _ self getChoiceMenu: 'proceed as is\abort' with: #(proceed abort) with: list with: #selector.
	index _ menu startUpWithHeading: ' ' , (aString contractTo: 40) , ' is a new message '.
	index = 0 ifTrue: [^false].
	(menu selectorAt: index) == #proceed ifTrue: [^false].
	(menu selectorAt: index) == #abort ifTrue: [^ ''].
	(menu selectorAt: index) == #selector ifTrue:
		[newSym _ list at: (index-2).
		posList _ sourceRangeAndPos at: 2.
		posList isNil ifTrue: [posList _ Array with: sourceRange first].
		oldStream _ ReadStream on: aString.
		posDiff _ 0.
		newSym keywords with: posList do:  "# of keywords must match"
			[:newKey :oldPos |
			| oldKey |
			oldKey _ oldStream through: $:.
			oldKey = newKey ifFalse:
				[self selectRange: (oldPos + posDiff to: oldPos + posDiff + oldKey size - 1).
				self replaceEditSelectionWith: newKey asString asText.
				posDiff _ posDiff + newKey size - oldKey size]].
		^true].
	^''.!

noEffect: statementNode
	| index |
	index _ self startUp: 'remove\proceed\abort'
			for: ''
			with: 'This statement has no effect'
			fromStatement: statementNode.
	index = 1 ifTrue:
		[self removeEditSelection.  ^true  "retry"].
	index = 2 ifTrue: [^false  "proceed"].
	^''!

readBeforeWritten: name from: varNode
	| index |
	index _ self startUp: 'proceed\abort'
			for: name
			with: ' has no value assigned yet '
			from: varNode.
	index = 1 ifTrue: [^false  "proceed"].
	^''!

redeclared: name from: varNode
	| index |
	index _ self startUp: 'proceed\abort'
			for: name
			with: ' is already defined (perhaps in an outer scope) '
			from: varNode.
	index = 1 ifTrue: [editor deselect.  ^false  "proceed"].
	^''!

redeclaredBlockArg: name in: varNode from: codeStream
	| index newName |
	index _ self startUp: 'proceed\rename & assign to outer var\abort'
			for: name
			with: ' is already defined (perhaps in an outer scope) '
			from: varNode.
	index = 1  "proceed"
		ifTrue:
			[editor deselect.
			^false].
	index = 2  "rename and assign to outer var"
		ifTrue:
			[newName _ name.
			[newName _ newName, 'x'.
			(codeStream variableAt: newName asSymbol from: nil) notNil]
				whileTrue.
			self replaceEditSelectionWith: newName asText.
			editor selectAt: codeStream topNode body sourcePosition first + newName size - name size.
			self replaceEditSelectionWith: (name , ' _ ' , newName , '. ') asText.
			^true].
	^self abort!

undeclared: association at: sourceRange from: codeStream
	| menu index possibles |
	Cursor normal show.
	self selectRange: sourceRange.
	possibles _ self possibleVariablesFor: association key with: codeStream.
	possibles _ possibles copyFrom: 1 to: (5 min: possibles size).
	index := (menu := self getChoiceMenuWith: possibles)
				startUpWithHeading: ' declare ' asText , (association key contractTo: 20) asText allBold , ' as ' asText.
	index = 0 ifTrue: [^self declareFailed: association from: codeStream].
	((index > 5) and: [index <= (5 + possibles size)]) 
		ifTrue: [^ self perform: (menu selectorAt: index) with: association with: codeStream with: (menu labelAt: index)].
	^self perform: (menu selectorAt: index) with: association with: codeStream.!

undeclared: association in: varNode from: codeStream
	^self undeclared: association at: varNode sourcePosition from: codeStream!

undeclaredStore: association in: assignNode from: codeStream
	| pos |
	pos _ assignNode variable sourcePosition first.
	^self undeclared: association at: (pos to: pos + association key size - 1) from: codeStream!

warning: message from: aNode
	| index |
	Cursor normal show.
	self selectRange: aNode sourcePosition.
	index _ (PopUpMenu labels: 'proceed\abort' withCRs)
			startUpWithHeading: ' ' asText , message asText allBold.
	^index = 1 ifTrue: [false] ifFalse: ['']! !

!InteractiveCompilerErrorHandler methodsFor: 'private: private-undeclared variables'!

declareClassVar: assoc from: codeStream
	class addClassVarName: assoc key asSymbol.
	"Smalltalk changes changeClass: class." self thingToDo. "does this need to be logged?"
	^true  "restart"!

declareCorrect: assoc from: codeStream
	"Attempt to correct the spelling of an undeclared variable."

	| oldName lc score bestScore guess name |
	oldName _ assoc key.
	lc _ oldName first asLowercase.
	bestScore _ 0.
	codeStream bindingsDo:
		[:bind |
		name _ bind key.
		name first asLowercase = lc
			ifTrue:
				[(score _ name spellAgainst: oldName) > bestScore ifTrue:
					[bestScore _ score. guess _ name]]].

	bestScore > 50 ifFalse: [^'Couldn''t correct'].
	(self confirm: 'Confirm correction to ' , guess)
		ifTrue:
			[self replaceEditSelectionWith: guess.
			^true  "retry"]
		ifFalse:
			[^self declareFailed: oldName from: codeStream]!

declareFailed: assoc from: codeStream
	^self abort!

declareGlobal: assoc from: codeStream
	"Change the association's key from (possibly) a String to a Symbol,
	then add that association to Smalltalk.  Use at:put: so that the 
	global can be removed from Undeclared if it is there."

	assoc key first isUppercase 
			ifFalse: [self notify: assoc key, ' global variable name should be capitalized; proceed to include anyway.'].
	assoc key: assoc key asSymbol.
	Smalltalk at: assoc key put: assoc value.
	^true  "retry"!

declareReplace: assoc from: codeStream with: newName
	"Attempt to correct the spelling of an undeclared variable."

	self replaceEditSelectionWith: newName.
	^true.!

declareTemp: assoc from: codeStream
	"Declare the undeclared name as a method temp.
	Eventually we should offer the option of declaring
	it in the local scope, or the compiler should figure
	out what scope is the most appropriate."
	| name endTemps replacement |

	name _ assoc key.
	endTemps _ codeStream homeStream topNode body sourcePosition first.
	(editor text at: endTemps) = $|
		ifTrue:		"Paste in before vertical bar"
			[replacement _ name , ' '.
			(editor text at: endTemps - 1) = Character space
				ifFalse: [replacement _ ' ' , replacement]]
		ifFalse:		"No temp declarations yet; have to insert whole line"
			[replacement _ '| ' , name , ' |' , (String with: Character cr) , (String with: Character tab)].
	editor selectAt: endTemps.
	self replaceEditSelectionWith: replacement.
	^true  "retry"!

declareUndeclared: assoc from: codeStream
	| name |
	name _ assoc key asSymbol.
	assoc key: name.
	(Undeclared includesKey: name) ifFalse:
		[Transcript show: ' (' , name , ' is Undeclared) '.
		Undeclared add: assoc].
	^false  "go on"! !

!InteractiveCompilerErrorHandler methodsFor: 'private: private'!

errorOption: option messageBlock: aBlock at: position
	"option = true means user corrected the error, retry.
	option = false means go on regardless.
	option = nil means abort using aBlock value as the error message.
	option = a string means abort using the string as the message."
	| aString |

	option == true ifTrue: [^self retryWith: lengthChange].  "user corrected it, retry"
	option == false ifTrue: [^self].  "user says go on regardless"
	aString _ option == nil ifTrue: [aBlock value] ifFalse: [option].
	Cursor normal show.
	aString isEmpty
		ifTrue:
			["insertAndSelect: adds a space on the front!!
			This is a kludge."
			editor selectAt: (position max: 1);
				deselect;
				selectAndScroll]
		ifFalse:
			[editor insertAndSelect: aString at: (position max: 1)].
	^self abort!

getChoiceMenu
	"Menu for when the compiler notices a reference to an undeclared variable."
	
	^PopUpMenu fromArray: #(
		('temp'			declareTemp:from:		'')	"All are standard smalltalk."
		('class var'		declareClassVar:from:	'')
		('global'		declareGlobal:from:		'')
		('undeclared'	declareUndeclared:from:	'')
		-
		('correct it'		declareCorrect:from:	'')
		('abort'			declareFailed:from:		'') ).!

getChoiceMenu: prelabs with: presels with: proposed with: propmsg
	|  labels selectors |
	labels _ prelabs.
	selectors _ presels.
	proposed isEmpty not 
		ifTrue: [labels _ labels, '\'].
	proposed 
		do: [:var | 
			labels _ labels , var. 
			selectors _ selectors, (Array with: propmsg)]
		andBetweenDo: [labels _ labels, '\'].
	^ActionMenu
		labels: labels withCRs
		lines: (Array with: (prelabs occurrencesOf: $\)+1)
		selectors: selectors.!

getChoiceMenuWith: proposedVars  
	|  labels selectors |
	labels _ 'temp\class var\global\undeclared\abort'.
	selectors _ #(#declareTemp:from: #declareClassVar:from: #declareGlobal:from: #declareUndeclared:from: #declareFailed:from:).
	^ self getChoiceMenu: labels with: selectors with: proposedVars with: #declareReplace:from:with:.!

possibleVariablesFor: proposedVariable with: codeStream
	| results resultSet resultColl |
	results _ proposedVariable correctAgainstDictionary: codeStream bindings
								continuedFrom: nil.
	proposedVariable first isUppercase ifTrue:
		[ results _ codeStream class possibleVariablesFor: proposedVariable
						continuedFrom: results ].
	results _ proposedVariable correctAgainst: nil continuedFrom: results.
	resultSet _ Set new: (results size).
	resultColl _ OrderedCollection new: (results size).
	results do: [:prop |
		(resultSet includes: prop) ifFalse: [resultColl add: prop. resultSet add: prop]].
	^ resultColl.!

removeEditSelection
	self replaceEditSelectionWith: ''!

replaceEditSelectionWith: aStringOrText
	lengthChange _ lengthChange + aStringOrText size - editor selection size.  "needed for retry"
	editor deselect; replaceSelectionWith: aStringOrText asText!

selectRange: sourceRange
	editor selectFrom: sourceRange first to: sourceRange last!

startUp: labels for: name with: text at: sourceRange
	"Start up a menu with a list of labels, selecting
	aNode first.  Answer the index."
	| index |
	Cursor normal show.
	self selectRange: sourceRange.
	index _ (PopUpMenu labels: labels withCRs)
			startUpWithHeading: ' ' asText , (name contractTo: 40) asText allBold , text asText.
	^index!

startUp: labels for: name with: text from: aNode
	^self startUp: labels for: name with: text at: aNode sourcePosition!

startUp: labels for: name with: message fromStatement:
aNode
	" Select the entire statement,
	including preceding tabs and the trailing .."
	| start stop text aChar |
	start _ aNode sourcePosition first.
	stop _ aNode sourcePosition last.
	text _ editor text string.
	[start > 1 and:
	 [aChar _ text at: start - 1.
	 aChar = Character space or: [aChar = Character tab]]]
		whileTrue: [start _ start - 1].
	aChar _ nil.
	[stop < text size and:
	 [aChar _ text at: stop + 1.
	 aChar = Character space or: [aChar = Character tab or:
[aChar = $.]]]]
		whileTrue: [stop _ stop + 1].
	aChar = Character cr ifTrue: [stop _ stop + 1].
	^self startUp: labels for: name with: message at: (start
to: stop)! !