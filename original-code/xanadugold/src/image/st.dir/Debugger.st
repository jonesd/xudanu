'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:06 pm'!

Browser subclass: #Debugger
	instanceVariableNames: 'context receiverInspector contextInspector shortStack sourceMap sourceCode processHandle mayProceed breakPC '
	classVariableNames: 'HighlightPC '
	poolDictionaries: ''
	category: 'Tools-Programming'!
Debugger comment:
'The debugger allows browsing among the stack of contexts of a suspended process.  In addition to viewing the source code at each level, the debugger supports inspection (and change) of temporary and instance variables in each context.

Instance Variables:
	context				<ContextPart> the currently viewed context
	receiverInspector	<Inspector> on instance variables in the current context
	contextInspector	<Inspector> on temporary variables in the current context 
	shortStack			<Integer | nil> Integer if only that many items of the stack is being shown, nil if full stack
	sourceMap			<SortedCollection of: Associations> (pc -> range)
	tempNames			<Array of: String>, cached names of the temporary variables
	processHandle		<ProcessHandle> holding onto the observed process

Class Variables:
	ContextMenu 	<ActionMenu> of operations on the sequence of message sends
	FullStackMenu  <ActionMenu> of operations on executing the method
	HighlightPC 	<Boolean> whether or not to highlight the position in the method at which the interrupt occurred'!


!Debugger methodsFor: 'initialize-release'!

process: aProcess context: aContext interrupted: aBoolean proceedable: proceedBoolean
	sourceCode _ nil.
	shortStack _ 9. 	"Default to 9 element stack"
	processHandle _ ProcessHandle on: aProcess at: aContext interrupted: aBoolean.
	mayProceed _ proceedBoolean!

release
	processHandle terminate.
	context _ nil.
	receiverInspector _ nil.
	contextInspector _ nil.
	super release! !

!Debugger methodsFor: 'accessing'!

interruptedContext
	"Answer the suspended context of the interrupted process."

	^processHandle topContext!

mayProceed
	^mayProceed!

{Behavior} selectedClass
	"Answer the class object that is currently selected."

	^ context == nil
		ifTrue: [nil]
		ifFalse: [context mclass]! !

!Debugger methodsFor: 'dependents access'!

removeDependent: aDependent 
	super removeDependent: aDependent.
	self dependents isEmpty ifTrue: [self release]! !

!Debugger methodsFor: 'doIt/accept/explain'!

acceptText: aText from: aController 
	"Recompile the method of the selected context."

	| classOfMethod newSelector newMethod |
	context == nil ifTrue: [^ false].
	classOfMethod _ context mclass.
	newSelector _ classOfMethod parserClass new parseSelector: aText.
	newSelector ~~ selector
		ifTrue: [self notify: 'selector must not change'].
	Cursor execute showWhile:
		[newSelector _ classOfMethod
				compile: aText
				classified: (classOfMethod organization getCategoryOfElement: newSelector)
				notifying: aController].
	newSelector == nil ifTrue: [^ false].
	Cursor execute showWhile:
		["**have to handle newMethod needing big stack!!"
		newMethod _ classOfMethod compiledMethodAt: newSelector.
		sourceCode _ aText string.
		newMethod isQuick
			ifTrue:  "If compiled quick, we need a non-quick version to put in the context."
				[newMethod _ (classOfMethod compilerClass new
							parse: sourceCode in: classOfMethod notifying: nil) generateNoQuick].
		context _ self homeContext.
		newMethod frameSize > context size
			ifTrue: [context _ context resizedWith: newMethod].
		context restartWith: newMethod.
		sourceMap _ context sourceMap.
		self resetContext: context.
		processHandle interrupted: true].
	^ true!

doItContext
	"Answer the context in which a text selection can be evaluated."
	^ context!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	context == nil ifTrue: [^ nil].
	^ context homeReceiver!

doItValue: anObject 
	"Set the value to be returned when the interrupted process proceeds."

	processHandle proceedValue: anObject! !

!Debugger methodsFor: 'stack manipulation'!

emergencyRestart: anException
	"Respond to an Context>>emergencySignal arising during simulation."

	| topView labelString aContext |
	aContext _ (Object userInterruptSignal accepts: anException signal)
		ifTrue: [anException parameter]
		ifFalse: [anException initialContext].
	labelString _ 'Unhandled exception: ' , anException errorString.
	topView _ (self dependents select: [:v | (v isKindOf: View)
					and: [v isTopView]]) first.			"sheesh!!"
	topView newLabel: labelString.
	processHandle topContext: aContext.
	self context: aContext.
	self changed: #context.
	anException initialContext == aContext
		ifFalse: [anException initialContext unwindUpTo: aContext].!

privateSend
	"The top context on the stack must be selected.  This being so, either some message
	is about to be sent in that context, or that context is about to return.  Send is only
	effective in the former case.  It will cause the next message to be sent.  The send is
	actually simulated, so that the debugger will regain control at the beginning of the
	method which is invoked (unless it is a primitive).  In this way, you can step your
	way deeper into a computation"
 
	self checkContextSelection.
	(context ~~ processHandle topContext) | context willReturn
		ifTrue: [^self].
	processHandle interrupted ifFalse: [processHandle topContext push: processHandle proceedValue].
	processHandle interrupted: true. "simulation leaves same state as interrupting"
	context stepUntilVisibleEffect.
	self resetContext: context send.
	context stepUntilPC: (self stopPC: context pc).
	self changed: #pc!

privateSkipToCaret
	"Executes and stops at the beginning of a statement that the user 
	indicates by a caret. The breakPC is one after the last executed pc."

	| currContext |
	self checkContextSelection.
	processHandle interrupted ifFalse: [processHandle topContext push: processHandle proceedValue].
	processHandle interrupted: true.
	self changed: #breakPC."simulation leaves same state as interrupting"
	Context emergencySignal
		handle: 
			[:ex | 
			ex returnDoing: [self emergencyRestart: ex parameter]]
		do: [context == processHandle topContext
				ifTrue: 
					[currContext _ context.
					[currContext == context and: [currContext pc < breakPC]]
						whileTrue: 
							[currContext _ currContext completeCallee: currContext step.
							(currContext isMemberOf: Array)
								ifTrue: ["handler context"
									currContext _ self contextFromHolder: currContext]].
					currContext == context ifFalse: [self resetContext: currContext].
					self changed: #pc.
					self updateInspectors]
				ifFalse: 
					[currContext _ context.
					currContext _ currContext completeCallee: processHandle topContext.
					[currContext == context and: [currContext pc < breakPC]]
						whileTrue: 
							[currContext _ currContext completeCallee: currContext step.
							(currContext isMemberOf: Array)
								ifTrue: ["handler context"
									currContext _ self contextFromHolder: currContext]].
					self resetContext: currContext]]!

privateStep
	"Step will cause the next message to be sent, or the expression to be 
	assigned, or the return to be executed.  In either case, the debugger 
	regains control so that you can step your way down through a method, 
	and out to the caller when it returns."
	
	| currContext |
	self checkContextSelection.
	processHandle interrupted ifFalse: 
		[processHandle topContext push: processHandle proceedValue].
	processHandle interrupted: true. "simulation leaves same state as interrupting"
	context == processHandle topContext
		ifTrue: 
			[context stepUntilVisibleEffect.
			currContext _ context completeCallee: context step.
			(currContext isMemberOf: Array) ifTrue: "handler context"
					[currContext _ self contextFromHolder: currContext].
			currContext == context ifFalse: "return"
				[self resetContext: currContext].
			currContext stepUntilPC: (self stopPC: currContext pc).
			self changed: #pc.
			self updateInspectors]
		ifFalse: 
			[currContext _ context completeCallee: processHandle topContext.
			(currContext isMemberOf: Array) ifTrue: "handler context"
					[currContext _ self contextFromHolder: currContext].
			currContext stepUntilPC: (self stopPC: currContext pc).
			self resetContext: currContext]! !

!Debugger methodsFor: 'contextList'!

context
	"Answer the currently viewed context."
	
	^ context!

context: aContext
	"Set aContext to be the currently viewed context.  
	This involves resetting all the inspectors, the viewed 
	source code, and the exception handling signals."

	| oldContext class receiver |
	oldContext _ context.
	context _ aContext.
	context == nil
		ifTrue:
			[contextInspector inspect: nil.
			receiverInspector inspect: nil.
			self changed: #text.
			^self].
	receiver _ self contextReceiver.
	class _ (receiver == nil 
		ifTrue: [context mclass] ifFalse: [receiver class]).
	Metaclass obsoleteSignal 
		handle: [:ex | className _ context mclass] 
		do: 
		[meta _ class isMeta.
		meta
			ifTrue: [className _ class soleInstance name]
			ifFalse: [className _ class name].
		selector _ context selector.
		(oldContext == nil or: [oldContext method ~~ context method])
			ifTrue:
				[sourceCode _ context sourceCode.
				sourceMap _ context sourceMap. "will compute tempNames"
				self changed: #text]].
	receiver == nil
		ifTrue: [receiverInspector inspect: nil.
				receiverInspector changed: #empty]
		ifFalse: [receiverInspector inspect: receiver].
	contextInspector inspect: context.
	CompiledCode nPCMapErrorSignal
		handle: [:ex | Transcript cr; show: ex errorString]
		do: [self changed: #pc].
	self normalize.!

contextList
	"Answer the sequenceable collection containing the messages that 
	are accessed from the currently selected context."

	^shortStack notNil
		ifTrue: 
			[| list |
			list _ processHandle topContext stackOfSize: shortStack.
			list last sender isNil ifTrue: [shortStack _ nil].
			list]
		ifFalse: [processHandle topContext stack]!

contextMenu
	"Menus for debugger window."

	| tags |
	
	tags _ PopUpMenu tags, 
	(context ~~ nil ifTrue: [#(context)] ifFalse: [#(noContext)]),
	(shortStack ~~ nil ifTrue: [#(shortStack)] ifFalse: [#()]).
	
	(context ~~ nil and: [PopUpMenu shortForm not])
		ifTrue: [tags _ tags, #(longContext)].
	
	^PopUpMenu matching: tags fromPrefixedArray: #(
		(context		'skip to caret'		skipToCaret			'ST: Treat carret as breakpoint and run until it is hit.')
		(context		'step'				step					'ST: Continue to the next execution point at this level.')
		(context		'send'				send					'ST: Take the next atomic little step.')
		-
		(shortStack	'more stack'		moreStack				'ST: Reveal twice as much stack.')
		-
		(noContext	'proceed'			proceed					'ST: Continue execution.')
		(context		'proceed'			proceed					'ST: Continue execution (skipping selected message send????).')
		(context		'restart'			restart					'ST: Continue execution (retrying selected message send).')
		-
		(context		'spawn' ( 
			(context		'system browser'	spawnSystemBrowser	'Xu: Create a SystemBrowser (positioned on this method????).')
			(context		'cxx browser'		spawnCxxBrowser		'Xu: Create a CxxBrowser (positioned on this method, if possible????).')
			-
			(context		'category'			spawnCategory		'Xu: Create a CategoryBrowser on selected category, (positioned on this method????).')
			(context		'class'				spawnClass				'Xu: Create a ClassBrowser on selected class, (positioned on this method????).')
			(context		'family'			spawnHierarchy		'Xu: Create a FamilyBrowser which contains the selected class, its superclasses, and its subclasses.')
			(context		'protocol'			spawnProtocol			'Xu: Create a ProtocolBrowser on the selected protocol.')
			(context		'method'			spawnMethod			'Xu: Create a MethodBrowser on the selected method.')))
		(context		'history'			methodHistory			'Xu: Create a HistoryBrowser on the selected method.')
		-
		(context		'senders'			browseSenders			'ST: Create a browser on all methods which send the selected message.')
		(context		'implementors'		browseImplementors		'ST: Create a browser on all methods which implement the selected message.')
		(context		'polymorphs'		browsePolymorphs		'Xu: Create a browser on all methods which are C++ polymorphic with the selected message.')
		(longContext	'messages'			browseMessages		'ST: Prompt with a menu of the messages sent by this method.  Create a browser on all implementors of the chosen message.') ).! !

!Debugger methodsFor: 'text'!

text
	"Answer the text for the source code that should be displayed 
	based on the class and message of the currently selected message."

	context == nil ifTrue: [^ Text new].
	^ sourceCode asText makeSelectorBoldIn: self selectedClass! !

!Debugger methodsFor: 'private: private-inspectors'!

contextInspector
	^contextInspector!

openInspectors
	"Further initialization when opening notify view to debug view"

	receiverInspector _ Inspector inspect: nil.
	contextInspector _ ContextInspector inspect: nil.
	self changed: #contextList!

receiverInspector
	^receiverInspector!

updateInspectors
	receiverInspector update.
	contextInspector update! !

!Debugger methodsFor: 'private: private-menu messages'!

correct: aNotifierController
	"Attempt to correct the spelling of the not-understood message and resend."
	| oldSelector oldFirst oldArgs selectors guess score bestScore |
	processHandle topContext selector == #doesNotUnderstand:
		ifFalse: [^ aNotifierController view flash].
	oldSelector _ (processHandle topContext tempAt: 1) selector.
	oldFirst _ oldSelector first.
	oldArgs _ oldSelector numArgs.
	selectors _ processHandle topContext receiver class allSelectors select:
			[:sel | sel first = oldFirst and: [sel numArgs = oldArgs]].
	bestScore _ 0.
	selectors do:
		[:sel |
		(score _ sel spellAgainst: oldSelector) > bestScore ifTrue:
			[bestScore _ score. guess _ sel]].
	(self confirm: 'retry with selector:
	', guess) ifFalse: [^ aNotifierController view flash].
	processHandle topContext tempAt: 1 put:
		(Message selector: guess arguments: (processHandle topContext tempAt: 1) arguments).
	^ self proceed!

fullStack
	"Expand the stack to include all contexts, rather than the first few."
	shortStack _ nil.
	self changed: #context!

moreStack
	"If showing a short stack, expand the stack to include twice as many contexts."
	shortStack isNil
		ifFalse: 
			[shortStack _ shortStack * 2].
	self changed: #context!

proceed
	"Proceed from the interrupted state of the currently selected context.
	The argument is a controller on a view of the receiver.  That view
	is closed."

	self checkContextSelection.
	(context ~= processHandle topContext) | (processHandle interrupted not) 
		ifTrue: [context push: processHandle proceedValue].
	context _ context stepUntilProceedable.
	self resumeProcess!

restart
	"Proceed from the initial state of the currently selected context.
	The argument is a controller on a view of the receiver.  That view
	is closed."

	self checkContextSelection.
	self revertBlock ifFalse: [^self].
	context restart.
	self resumeProcess!

spawnEdits: aText from: aController
	"Open a method browser with aController for the code controller."

	| newController | 
	context == nil  
		ifTrue: [aController view flash "cant spawn changes when deselected"]
		ifFalse: [newController _ aController copy.  "Copy gets the changes"
				aController cancel; controlTerminate.   "Cancel changes in spawning browser"
				BrowserView openMethodBrowserOn: self copyAsBrowser withController: newController]! !

!Debugger methodsFor: 'private: private-pc selection'!

breakPCFrom: aController
	"The break pc is computed by comparing the location of the caret with a source position in sourceMap. The location of the caret is obtained from the controller 'startBlock' instance variable. The break pc is the pc whose source position last in sourceMap is greater than the location of the caret."

	| index |
	index _ aController indexOfSelection.
	breakPC _ self pcForCharacter: index!

pcForCharacter: index
	"The break pc is one after the pc whose source position's last element in sourceMap is less than the location of the caret, and whose source position's first element is less than all of the first positions which appeared."

	| min firstPos |
	sourceMap last value last < index 
			ifTrue: [^context method bytesSize].
	min _ index.
	sourceMap reverseDo: 
		[:assoc | 
			firstPos _ assoc value first.
			firstPos < min ifTrue: 
				[min _ firstPos.
				assoc value last < index 
					ifTrue: [^(sourceMap after: assoc) key]]].
	^sourceMap first key!

pcRange
	"Answer the indices in the source code for the method corresponding
	to the selected context's program counter value."

	| pc i size end |
	(HighlightPC and: [context ~~ nil])
		ifFalse: [^1 to: 0].
	(sourceMap == nil or: [sourceMap size = 0])
		 ifTrue: [^1 to: 0].
	pc_ context pc.
	(context == processHandle topContext and: [processHandle interrupted])
		ifFalse: "When selecting a context in middle of the stack or the context 'halt',
				the pc points to the byte code after the send."
			[i _ 1. 
			size _ sourceMap size.
			[i <= size and: [(sourceMap at: i) key < pc]] 
				whileTrue: [i _ i + 1].
			i > 1 ifTrue: [pc _ (sourceMap at: i - 1) key]].
	pc _ pc - 1.
	i _ sourceMap indexForInserting: (Association key: pc value: nil).
	i < 1 ifTrue: [^1 to: 0].
	i > sourceMap size
		ifTrue:
			[end _ sourceMap inject: 0 into:
				[:prev :this | prev max: this value last].
			^ end+1 to: end].
	^(sourceMap at: i) value!

stopPC: pc
	"Answer a next stop pc included in the sourceMap.
	The optimization compiler can indicate the step's stop pc
	in the sourceMap. If a pc is a send or assign byte code pc 
	but not in the sourceMap, the step dosen't stop at the pc"
 
	| nextPC loadFlag mapSize i stopPC pcCache |
	nextPC _ pc.
	loadFlag _ false.
	mapSize _ sourceMap size.
	(context isJump: nextPC) 
		ifTrue: 	
			[context stepUntilPC: nextPC.
			context step. "execute jump"
			nextPC _ context pc].
	i _ sourceMap indexForInserting: (Association key: nextPC - 1 value: nil).
	i > mapSize ifTrue: [stopPC _ context method bytesSize]
				ifFalse: [stopPC _ (sourceMap at: i) key].
	[nextPC < stopPC] whileTrue:
		[(context isLoad: nextPC) 
			ifTrue: 
				[loadFlag ifFalse: 
					[loadFlag _ true. 
					pcCache _ nextPC]]
			ifFalse:
				[loadFlag _ false].
		(context isJump: nextPC) 
			ifTrue: 	
				[context stepUntilPC: nextPC.
				context step. "execute jump"
				nextPC _ context pc.
				i _ sourceMap indexForInserting: 
						(Association key: nextPC - 1 value: nil).
				i > mapSize 
					ifTrue: [stopPC _ context method bytesSize]
					ifFalse: [stopPC _ (sourceMap at: i) key]]
			ifFalse: 
				[nextPC _ context nextPC: nextPC]].
	loadFlag ifTrue: [^pcCache] ifFalse: [^nextPC]! !

!Debugger methodsFor: 'private: private-selector functions'! !

!Debugger methodsFor: 'private: private-stack manipulation'!

checkContextSelection  
	"Determine whether the currently selected context has been set, 
	and if not, set it."

	context == nil ifTrue: [context _ processHandle topContext]!

contextFromHolder: anArray
	"Answer the context stored in anArray."

	^anArray at: 1!

contextReceiver
	| ctxt |
	context isBlockContext 
		ifTrue: [(ctxt _ context home) == nil 
					ifTrue: [^nil] 
					ifFalse: [^ctxt receiver]]
		ifFalse: [^context receiver]!

homeContext

	| method ctx |
	context isBlockContext ifTrue: 
		[method _ context method homeMethod.
		ctx _ context sender.
		[ctx == nil] whileFalse: 
				[ctx method == method ifTrue: [^ctx].
				ctx _ ctx sender].
		self error: 'Unable to restart: block''s home context 
					not on the current process''s stack.'].
	^context!

resetContext: aContext 
	"Used when a new context becomes top-of-stack, for instance when the
	method of the selected context is re-compiled, or the simulator steps or
	returns to a new method."

	processHandle topContext: aContext.
	context == aContext 
		ifFalse: [self context: aContext].
	self changed: #context!

resumeProcess
	processHandle topContext: context.
	processHandle resumeProcess!

revertBlock
	"If the selected context is a block, then restart from beginning of the block or its home."

	| index home |
	context isBlockContext ifTrue:
		[index _ (PopUpMenu labels: ' beginning of block\beginning of method\abort' withCRs)
			startUpWithHeading: '  I will restart from '.
		index = 1 ifTrue: [^true].
		index = 2 ifTrue: 
					[home _ context home.
						home == nil 
							ifTrue: [self context: self homeContext. ^true]
							ifFalse: [self context: home. ^ true]].
		index = 3 ifTrue: [^false]].
		^true! !

!Debugger methodsFor: 'private: private'!

{Browser} copyAsBrowser
	"The existence of this overriding of 'copyAsBrowser' is a kludge that results from the
	mistake (as far as I am concerned -- MSM) that Debugger uses the wrong choice of
	what to store in 'classname'.  Given the context 'Foo(Bar)>>baz', it'll store 'Foo',
	whereas I think it should store 'Bar'.  I've provided this 'copyAsBrowser' rather than
	fix it because Debugger is too mysterious."
	
	| result {Browser} |
	result _ super copyAsBrowser.
	context ~~ nil
		ifTrue: [result newClassList: context mclass nonMeta name.
			result meta: context mclass isMeta.
			result normalize].
	^result!

process: aProcess context: aContext interrupted: aBoolean 
	"Set the instance variables of the receiver."
	
	sourceCode _ nil.
	shortStack _ 9. 	"Default to 9 element stack"
	processHandle _ ProcessHandle on: aProcess at: aContext interrupted: aBoolean! !

!Debugger methodsFor: 'menu messages'!

send
	"The top context on the stack must be selected.  This being so, either some message
	is about to be sent in that context, or that context is about to return.  Send is only
	effective in the former case.  It will cause the next message to be sent.  The send is
	actually simulated, so that the debugger will regain control at the beginning of the
	method which is invokedi (unless it is a primitive).  In this way, you can step your
	way deeper into a computation."
 
	Context codeSimulationErrorSignal
		handle: [:ex | (self confirm: 'Simulation error -- shall I restart the method?')
						ifTrue: [context restart.
								ex restart]
						ifFalse: [Transcript cr; show: 'Can''t continue.']]
		do: [Context emergencySignal
				handle: [:ex |
					ex returnDoing: [self emergencyRestart: ex parameter]]
				do: [self privateSend]]!

skipToCaret
	Context codeSimulationErrorSignal
		handle: [:ex | (self confirm: 'Simulation error -- shall I restart the method?')
						ifTrue: [context restart.
								ex restart]
						ifFalse: [Transcript cr; show: 'Can''t continue.']]
		do: [Context emergencySignal
				handle: [:ex |
					ex returnDoing: [self emergencyRestart: ex parameter]]
				do: [self privateSkipToCaret]]!

step
	Context codeSimulationErrorSignal
		handle: [:ex | (self confirm: 'Simulation error -- shall I restart the method?')
						ifTrue: [context restart.
								ex restart]
						ifFalse: [Transcript cr; show: 'Can''t continue.']]
		do: [Context emergencySignal
				handle: [:ex |
					ex returnDoing: [self emergencyRestart: ex parameter]]
				do: [self privateStep]]! !

!Debugger methodsFor: 'protected:'!

{CompiledCode} compiledMethod

	^Object notFoundSignal
		handle: [:ex | ex returnWith: context method]
				"If a method held in the debugger stack is recompiled 
				and become unbound method and the menu messages of 
				the unbound method is selected, KeyNotFoundSignal is raised."
		do: [super compiledMethod]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Debugger class
	instanceVariableNames: ''!


!Debugger class methodsFor: 'class initialization'!

initialize
	"Debugger initialize."

	HighlightPC _ true! !

!Debugger class methodsFor: 'instance creation'!

context: aContext 
	"Answer an instance of the receiver that models the current state of the system.  The active
	process has determined that a debugger should be set up (often by the user issuing
	the command debug)."

	| aDebugger |
	aDebugger _ self new.
	aDebugger
		process: Processor activeProcess
		context: aContext
		interrupted: false.
	^aDebugger!

context: aContext proceedable: aBoolean 
	"Answer an instance of me that models the current state of the system.  The active
	process has determined that a debugger should be set up (often by the user issuing
	the command debug)."

	| aDebugger |
	aDebugger _ self new.
	aDebugger
		process: Processor activeProcess
		context: aContext
		interrupted: false
		proceedable: aBoolean.
	^aDebugger!

interruptProcess: interruptedProcess 
	"Answer an instance of the receiver that models the current state of the system.  The active
	process has decided to provide a debugger on an interrupted process.  This message
	is called if the user types the ctrl c interrupt, or a low space notification occurs."

	| debugger |
	debugger _ self new.
	debugger
		process: interruptedProcess
		context: interruptedProcess suspendedContext
		interrupted: true.
	^debugger!

openFullViewOn: aDebugger label: aString 
	"Answer an instance of the receiver on the model, aDebugger.
	The label is aString.  Do not terminate the current active process."

	| topView |
	aDebugger openInspectors.
	topView _ BrowserView model: aDebugger label: aString minimumSize: 300@230.
	topView addSubView:
			(SelectionInListView on: aDebugger printItems: true oneItem: false
				aspect: #context change: #context: list: #contextList
				menu: #contextMenu initialSelection: #context)
		in: (0@0 extent: 1@0.2) borderWidth: 1.
	topView addSubView:
			(CodeView on: aDebugger aspect: #text change: #acceptText:from:
				menu: #textMenu initialSelection: nil)
		in: (0@0.2 extent: 1@0.6) borderWidth: 1.
	InspectorView view: aDebugger receiverInspector
		in: (0@0.8 extent: 0.5@0.2) of: topView.
	InspectorView view: aDebugger contextInspector
		in: (0.5@0.8 extent: 0.5@0.2) of: topView.
	topView controller openNoTerminate.
	^topView! !

Debugger initialize!
