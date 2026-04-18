'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:42 pm'!

TextController subclass: #CodeController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
CodeController comment:
'A CodeController is an interaction with text that adds some capability appropriate only to viewing Smalltalk code, such as ''explain'' and ''format''.'!


!CodeController methodsFor: 'menu messages'!

browseIt
	"Evaluate the current text selection as an expression"
	| result selectionStart oldTextSize selection |
	self controlTerminate.
	selectionStart _ startBlock stringIndex.
	oldTextSize _ self text size.
	selection _ self selection.
	result _ 
		model doItReceiver class evaluatorClass new
				evaluate: self selectionAsStream
				in: model doItContext
				to: model doItReceiver
				notifying: self
				ifFail: 
					[self controlInitialize.
					^#failedDoit].
	self selection asString = selection asString ifFalse:
		[self selectFrom: selectionStart  "Reselect doIt range after compiler interaction"
			to: selectionStart + selection size - 1 + (self text size - oldTextSize)].
	ChangeLog logDoItChanges: '
"---DOIT---"
' , self selection string.
	model doItValue: result.
	result browseHierarchy!

cxxFormat
	"Replace the text with a c++ translation of it. Squirrel the smalltalk 
	off into a corner."

	| cls {Behavior} parse {MethodNode} text {Text} |
	cls _ model selectedClass.
	cls == nil ifTrue: [^self].
	self controlTerminate.
	Cursor execute
		showWhile: 
			[parse _ self parseIn: cls.
			parse == nil
				ifTrue: [self flash]
				ifFalse: [
					| source {String} |
					source _ paragraph text asString.
					Sensor leftShiftDown
						ifTrue: [text _ CxxHeaderFile make 
									translatedTextFor: cls 
									source: source
									tree: parse]
						ifFalse: [text _ CxxDefinitionsFile make 
									translatedTextFor: cls 
									source: source
									tree: parse].
					self replaceSelectionWith: text.
					self selectAt: 1]].
	self controlInitialize!

doIt
	"Evaluate the current text selection as an expression"
	| result selectionStart oldTextSize selection |
	self controlTerminate.
	selectionStart _ startBlock stringIndex.
	oldTextSize _ self text size.
	selection _ self selection.
	result _ 
		model doItReceiver class evaluatorClass new
				evaluate: self selectionAsStream
				in: model doItContext
				to: model doItReceiver
				notifying: self
				ifFail: 
					[self controlInitialize.
					^#failedDoit].
	self selection asString = selection asString ifFalse:
		[self selectFrom: selectionStart  "Reselect doIt range after compiler interaction"
			to: selectionStart + selection size - 1 + (self text size - oldTextSize)].
	ChangeLog logDoItChanges: '
"---DOIT---"
', self selection string.
	model doItValue: result.
	self controlInitialize.
	^result!

explain
	"Try to shed some light on what kind of entity the current selection is.    
	The selection must be a single token or construct.  Insert the answer   
	after the selection.  Call private routines whose names begin with   
	'explain'.  They return a String if they recognise the selection, else nil."
	| reply |
	reply _ (Explainer new
		class: model selectedClass
		selector: model selector
		instance: model doItReceiver
		context: model doItContext
		methodText: model text) explain: self selection string for: model.
	reply size = 0 ifTrue:
		[reply _ '"Sorry, I can''t explain that.  Please select a single token, construct, or special character.' ,
			(model isUnlocked ifTrue: ['"'] ifFalse: ['  Also, please cancel or accept."']).
].
	self insertAndSelect: reply at: stopBlock stringIndex!

forkIt
	"Treat the current text selection as an expression; evaluate it in a separate 
	process."

	| receiver context sel |
	self controlTerminate.
	receiver _ model doItReceiver.
	context _ model doItContext.
	sel _ self selectionAsStream.
	Cursor execute show.
	Controller startBackgroundProcess.
	[receiver class evaluatorClass new
		evaluate: sel
		in: context
		receiver: receiver
		notifying: nil
		ifFail: [nil].
	Cursor normal show.
	Controller stopBackgroundProcess]
		forkAt: Processor userBackgroundPriority.
	ChangeLog logDoItChanges: '
"---DOIT---"
' , self selection string.
	model doItValue: nil.
	self controlInitialize.
	^#forked!

format
	"Reformat the contents of the receiver's view, formatted, if the view is unlocked."

	| selectedClass aCompiler newText |
	Sensor leftShiftDown ifTrue: [^self miniFormat].
	selectedClass _ model selectedClass.
	selectedClass == nil ifTrue: [^self].
	self controlTerminate.
	Cursor execute
		showWhile: 
			[aCompiler _ selectedClass compilerClass new.
			self selectFrom: 1 to: paragraph text size.
			self deselect.
			newText _ aCompiler
						format: paragraph text
						in: selectedClass
						notifying: self.
			newText == nil
				ifFalse: 
					[self replaceSelectionWith: (newText asText makeSelectorBoldIn: selectedClass).
					self selectAt: 1]].
	self controlInitialize!

inspectIt
	"Evaluate the current text selection as an expression"
	| result selectionStart oldTextSize selection |
	self controlTerminate.
	selectionStart _ startBlock stringIndex.
	oldTextSize _ self text size.
	selection _ self selection.
	result _ 
		model doItReceiver class evaluatorClass new
				evaluate: self selectionAsStream
				in: model doItContext
				to: model doItReceiver
				notifying: self
				ifFail: 
					[self controlInitialize.
					^#failedDoit].
	self selection asString = selection asString ifFalse:
		[self selectFrom: selectionStart  "Reselect doIt range after compiler interaction"
			to: selectionStart + selection size - 1 + (self text size - oldTextSize)].
	ChangeLog logDoItChanges: '
"---DOIT---"
' , self selection string.
	model doItValue: result.
	result inspect!

localMenuItem: selector
	^ (#(doIt printIt inspectIt browseIt format cxxFormat explain cxxFormat) includes: selector) or:
		[super localMenuItem: selector]!

miniFormat
	"Replace selection with selection un-wrapped."

	| inStream outStream aChar |
	inStream _ ReadStream on: (self selection copyWithout:
Character tab).
	outStream _ WriteStream on: (String new: self selection
size).
	[inStream atEnd]
		whileFalse: 
			[aChar _ inStream next.
			aChar isSeparator
				ifTrue: 
					[outStream space.
					[inStream atEnd not and: [inStream peek isSeparator]]
						whileTrue: [inStream next]]
				ifFalse: [outStream nextPut: aChar]].
	self deselect.
	self replaceSelectionWith: outStream contents asText.
	self select!

printIt
	"Evaluate the current selection as an expression.  If successful, insert and
	select the printString of the result of evaluation after the current selection."
	| result strm |
	result _ self doIt.
	result ~~ #failedDoit
		ifTrue: 
			[strm _ TextStream on: (String new: 40).
			strm space; print: result.
			self insertAndSelect: strm contents at: stopBlock stringIndex]! !

!CodeController methodsFor: 'private: private'!

parseIn: selectedClass 
	| errorHandler aParser |
	self selectFrom: 1 to: paragraph text size.
	self deselect.
	aParser _ selectedClass parserClass new.
	errorHandler _ (InteractiveCompilerErrorHandler new) class: selectedClass; 
		editor: self; failBlock: [^nil]; retryBlock: [:changeLength | ^self parseIn: selectedClass].
	^aParser
		parse: paragraph text
		class: selectedClass
		notifying: errorHandler! !