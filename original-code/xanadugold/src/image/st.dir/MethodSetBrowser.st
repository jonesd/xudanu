'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:30 pm'!

Browser subclass: #MethodSetBrowser
	instanceVariableNames: '
		myMethods {OrderedCollection of: MethodRep}
		myHidden {Collection of: MethodRep}
		mySelectedRep {MethodRep}
		myGen {MethodGenerator}
		myAction {MethodAction | nil}
		myBrowserGen {BrowserGenerator | nil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!MethodSetBrowser methodsFor: 'doIt/accept/explain'!

acceptText: aText from: aController
	"Text has been changed.  Store or compile the text, depending on 
	the current mode of the receiver."

	textMode == #unclassified ifTrue:
		[self notify: 'A method must be selected to suggest class and protocol'.
		^ false].
	^ super acceptText: aText from: aController! !

!MethodSetBrowser methodsFor: 'selector list'!

{void} selectorChangedInPlace: newSelector {Symbol}
	

	super selectorChangedInPlace: newSelector.
	mySelectedRep selector ~~ newSelector
		ifTrue: [mySelectedRep alternative: newSelector.
				self changed: #methodName]! !

!MethodSetBrowser methodsFor: 'private: private-menu messages'!

{Collection of: MethodRep} alternatives

	| result {Set of: MethodRep} alt {Symbol}  |
	result _ Set new.
	myMethods, myHidden asOrderedCollection do: [:rep {MethodRep} |
		alt _ rep alternative.
		alt ~~ nil
			ifTrue: [result add: (MethodRep make: rep methodClass with: alt)]].
	^result!

{NOWAIT} browseAlternatives

	| newReps {Set of: MethodRep} alt {Symbol} initSel {MethodRep} |
	newReps _ self alternatives.
	(mySelectedRep ~~ nil and: [(alt _ mySelectedRep alternative) ~~ nil])
		ifTrue: [initSel _ MethodRep make: mySelectedRep methodClass with: alt]
		ifFalse: [initSel _ nil].
	(EnumerateMethods make: newReps with: 'Alternatives to ', myGen label) 
		browse: initSel with: newReps!

{NOWAIT} browseHidden

	(EnumerateMethods 
			make: (myHidden collect: [:rep | rep copy]) 
			with: 'Hidden from ', myGen label) 
		browse: mySelectedRep with: myHidden!

{void} fileOutList

	| fileName {String} str {WriteStream} |
	fileName _ Filename request: 'File out list on:' 
					initially: 'list.txt'
					shouldExist: false.
	fileName = '' ifTrue: [^VOID].
	str _ (Filename named: fileName) writeStream.
	[myMethods do: [:meth {MethodRep} |
		str << meth; cr]
	] valueNowOrOnUnwindDo: [str close]!

spawnEdits: aText from: aController
	"Open a method browser with aController for the code controller."

	| newController | 
	selector == nil  
		ifTrue: [aController view flash "cant spawn changes when deselected"]
		ifFalse: [newController _ aController copy.  "Copy gets the changes"
				aController cancel; controlTerminate.   "Cancel changes in spawning browser"
				BrowserView openMethodBrowserOn: self copyAsBrowser withController: newController]!

{void} updateList: methods {(OrderedCollection of: MethodRep) default: nil}
	
	| coll {SortedCollection of: MethodRep} |
	Cursor execute showWhile: [ 
		methods == nil
			ifTrue: [coll _ myGen methodReps asSortedCollection]
			ifFalse: [coll _ methods asSortedCollection].
		myMethods _ MethodSortingNode indentedAndSorted: coll.
		self changed: #methodName]! !

!MethodSetBrowser methodsFor: 'private: private-method functions'!

hideMethod
	"Note: doesn't do its own 'self changed: #methodName' "

	| i |
	i _ myMethods indexOf: mySelectedRep.
	i >= 1
		ifFalse: [mySelectedRep _ nil.
				^VOID].
				
	myMethods _ myMethods copyWithout: mySelectedRep.
	myHidden add: mySelectedRep.
	i <= myMethods size 
		ifTrue: [self silentMethodName: (myMethods at: i)]
		ifFalse: [self silentMethodName: nil]!

nextMethod
	"Note: doesn't do its own 'self changed: #methodName' "
	
	| i |
	i _ myMethods indexOf: mySelectedRep.
	(i >= 1 and: [i < myMethods size])
		ifTrue: [self silentMethodName: (myMethods at: i +1)]
		ifFalse: [self silentMethodName: nil]!

removeMethodFromBrowser

	self hideMethod.
	self changed: #methodName!

{void} removeMethodSilently

	super removeMethodSilently.
	self removeMethodFromBrowser! !

!MethodSetBrowser methodsFor: 'private:'!

{void} computeOrdering: list {OrderedCollection of: MethodRep}
	indent: indent {IntegerVar}
	
	| sup {MethodRep} 
	  related {OrderedCollection of: MethodRep} 
	  unrelated {OrderedCollection of: MethodRep} |
	list isEmpty ifTrue: [^VOID].
	
	sup _ list detect: [:candidate {MethodRep} | 
		(list detect: [:maybeSup {Methodrep} | 
				candidate methodClass inheritsFrom: maybeSup methodClass] 
			ifNone: []) == nil].
	related _ OrderedCollection new.
	unrelated _ OrderedCollection new.
	list do: [:sub {MethodRep} | 
		sub methodClass = sup methodClass 
			ifTrue: [sub indent: indent.
					myMethods addLast: sub]
			ifFalse: [(sub methodClass inheritsFrom: sup methodClass)
				ifTrue: [related addLast: sub]
				ifFalse: [unrelated addLast: sub]]].
	self computeOrdering: related indent: indent + 1.
	self computeOrdering: unrelated indent: indent.!

{CodeController} fetchCodeController
	"This is an incredible kludge"
	
	| result {CodeController} |
	result _ nil.
	self dependents do: [:dep |
		((dep isKindOf: CodeView) and: [dep controller isKindOf: CodeController])
			ifTrue: [result == nil
						ifTrue: [result _ dep controller]
						ifFalse: [self halt. ^nil]]].
	^result! !

!MethodSetBrowser methodsFor: 'creation'!

create: gen {MethodGenerator} 
	with: sel {MethodRep default: nil} 
	with: methods {(Collection of: MethodRep) default: nil}
	with: browserGen {BrowserGenerator default: nil}
	"Initialize the receiver with the list of methods to be browsed."

	super create.
	organization _ SystemOrganization.
	myMethods _ OrderedCollection new.
	myHidden _ Set new.
	mySelectedRep _ sel.
	myGen _ gen.
	myAction _ gen fetchAction.
	myBrowserGen _ browserGen.
	self updateList: methods! !

!MethodSetBrowser methodsFor: 'method list'!

{OrderedCollection of: MethodRep} methodList
	"Answer the sequenceable collection containing the methods that 
	the receiver accesses."

	^myMethods!

methodMenu
	"Menu for methodSet browser (which is a browser on an arbitrary set of methods)"

	| tags {Collection of: Symbol} |
	
	tags _ PopUpMenu tags.
	(myAction ~~ nil and: [myAction isEditAction]) 
		ifTrue: [tags _ tags, #(action)].
	(myBrowserGen ~~ nil and: [myBrowserGen hasNextBrowser])
		ifTrue: [tags _ tags, #(nextBrowser)].
	(myMethods, myHidden asOrderedCollection 
			areAny: [:rep {MethodRep} | rep alternative ~~ nil])
		ifTrue: [tags _ tags, #(alternatives)].
	myHidden isEmpty not
		ifTrue: [tags _ tags, #(hidden)].
	meta ~~ nil
		ifTrue: [tags _ tags, (meta ifTrue: [#(caller)] ifFalse: [#(impl)]).
				(meta and: [PopUpMenu shortForm not])
					ifTrue: [tags _ tags, #(impl)]].
	
	mySelectedRep == nil ifTrue: 
		[^PopUpMenu matching: tags fromPrefixedArray: #(
			(all				'update' 				updateList				'Xu: Bring the browser into agreement with the underlying data according to the browsing criteria')
			-
			(all				'find in list' 			findInMethodList		'Xu: Apply criteria from a FindMenu to all the methods in this browser.')
			(nextBrowser	'next browser'		nextBrowser			'')
			(nope			'global replace'		globalReplace			'')
			(hidden		'hidden'				browseHidden			'')
			(alternatives	'alternatives'			browseAlternatives	''))].
			
	^PopUpMenu matching: tags fromPrefixedArray: #(
		(all		'file' (
			(all		'file out list'				fileOutList						'Xu: File out listing of top pane')
			(bogus		'file out all'			fileOutAll						'Xu: File out all the methods in this browser')
			(bogus		'print out all'			printOutAll					'Xu: Format for printer (and print?) all the methods in this browser')
			-
			(all		'file out this' 				fileOutMessage				'ST: File out contents of this method')
			(all		'print out this' 			printOutMessage				'ST?: Format for printer (and send to printer?)') ))
		(all		'spawn' (
			(all		'system browser'	spawnSystemBrowser		'Xu: Create a new SystemBrowser positioned like this browser.')
			(all		'cxx browser'			spawnCxxBrowser			'Xu: Create a new CxxBrowser positioned like this browser, if possible.')
			-
			(all		'category' 			spawnCategory				'Xu: Create a new CategoryBrowser on the selected category positioned like this browser.')
			(all		'class' 				spawnClass					'Xu: Create a new ClassBrowser on the selected class, positioned like this browser.')
			(all		'family' 				spawnHierarchy				'Xu: Create a FamilyBrowser which contains the selected class, its superclasses, and its subclasses.')
			(all		'protocol' 			spawnProtocol				'Xu: Create a ProtocolBrowser on the selected protocol.')
			(all		'method' 				spawnMethod					'Xu: Create a MethodBrowser on the selected method.') ))
		(all		'history' 					methodHistory				'Xu: Create a HistoryBrowser on the selected method.')
		(all		'update' 					updateList						'Xu: Bring the browser into agreement with the underlying data according to the browsing criteria')
		-
		(all		'senders'				browseSenders			'ST: Create a browser on all methods which send the selected message.')
		(caller	'callers'				browseCallers			'Xu: Create a browser on all those that send this message directly to this class')
		(impl	'implementors'		browseImplementors		'ST: Create a browser on all methods which implement the selected message.')
		(impl	'polymorphs'			browsePolymorphs		'Xu: Create a browser on all methods which are C++ polymorphic with the selected message.')
		(long	'messages'				browseMessages				'ST: Prompt with a menu of the messages sent by this method.  Create a browser on all implementors of the chosen message.')
		-
		(all			'find in list' 			findInMethodList				'Xu: Apply criteria from a FindMenu to all the methods in this browser.')
		(action		'substitute'			substitute						'')
		(nextBrowser	'next browser'	nextBrowser					'')
		(nope			'global replace'	globalReplace					'')
		(hidden		'hidden'			browseHidden					'')
		(alternatives	'alternatives'		browseAlternatives			'')
		-
		(all		'move' 					moveMethod					'Xu: Prompt with a menu of the protocols.  Move this method to the chosen protocol.')
		(all		'remove' 					removeMethod				'ST: Remove the currently selected method from the image.')
		(all		'hide' 						removeMethodFromBrowser	'Xu: Remove the currently selected method from the browser (but not the system)') )!

methodName
	"Answer the receiver's currently selected message selector."

	^mySelectedRep!

methodName: selection {MethodRep} 
	"Set the receiver's currently selected method to be selection."

	mySelectedRep _ selection.
	selection == nil ifTrue:  
		[selector _ nil. 
		^self textMode: #unclassified].
	className _ selection methodClass nonMeta name.
	meta _ selection methodClass isMeta.
	self selector: selection selector.
	self normalize.
	self categoryRep: category.
	self changed: #meta!

{void} silentMethodName: selection {MethodRep} 
	"Set the receiver's currently selected method to be selection."

	mySelectedRep _ selection.
	selection == nil ifTrue:  
		[selector _ nil. 
		textMode _ #unclassified.
		^VOID].
	className _ selection methodClass nonMeta name.
	meta _ selection methodClass isMeta.
	selector _ selection selector.
	textMode _ #methodDefinition.
	self normalize! !

!MethodSetBrowser methodsFor: 'searching'!

{NOWAIT} findInMethodList

	MethodFilter browseFiltered: myGen with: mySelectedRep with: myMethods! !

!MethodSetBrowser methodsFor: 'smalltalk: defaults'!

{void} updateList
	
	self updateList: nil! !

!MethodSetBrowser methodsFor: 'text'!

{PopUpMenu} textMenu
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept code),
		(myAction == nil ifTrue: [#()] ifFalse: [#(action)])! !

!MethodSetBrowser methodsFor: 'action'!

acceptAndSubstituteAll

	[true]
		whileTrue:
			[self fetchCodeController accept.
			self removeMethodFromBrowser.
			mySelectedRep == nil
				ifTrue: [^VOID].
			self applyAction
				ifFalse: [^VOID]]!

acceptHideSubstitute

	self fetchCodeController accept.
	self removeMethodFromBrowser.
	self substitute!

{BooleanVar} applyAction

	| controller {CodeController | nil} |  
	controller _ self fetchCodeController.
	controller == nil
		ifTrue: [self error: 'Cannot find unique code controller'].
		
	myAction nextAction: controller text with: controller with: true.
	
	^controller selectionStarts > controller text size!

{BooleanVar} applyActionSilently

	| newText {Text | nil} sel {Symbol | nil} |
	newText _ myAction 
		fetchUniqueReplacementFor: (mySelectedRep methodClass
											sourceCodeStringAt: mySelectedRep selector) asText.
	newText == nil
		ifTrue: [^false].
	
	sel _ self selectedClass compile: newText classified: protocol.
	sel == nil
		ifTrue: [^false].
	sel ~~ mySelectedRep selector
		ifTrue: [mySelectedRep alternative: sel].
	^true!

cancelNextSubstitute

	self fetchCodeController cancel.
	self nextMethod.
	self changed: #methodName.
	self substitute!

{MethodAction | nil} fetchAction

	^myAction!

{void} globalReplace

	| old new |
	mySelectedRep ~~ nil
		ifTrue: [LastStringSought _ mySelectedRep selector].
	old _ self requestString: 'Pattern of old selectors to replace'.
	old = ''
		ifTrue: [^VOID].
	new _ self requestString: 'Pattern of new replacement selectors'.
	new = ''
		ifTrue: [^VOID].
	[self globalReplace: old with: new] whileTrue: []!

{BooleanVar} globalReplace: old {String} with: new {String}

	| uniqueString menu choice selectors asses |
	selectors _ IdentitySet new.
	myMethods do: [:rep |
		selectors add: rep selector].
	uniqueString _ 'all of ''em'.
	asses _ OrderedCollection new.
	(selectors select: [:sel1 | old match: sel1]) do: [:sel2 |
		asses add: (Association 
			key: sel2 
			value: (old matchAndReplace: sel2 asText with: new asText allBold))].
	asses isEmpty 
		ifTrue: [^false].
	(asses count = 1 and: [asses theOne key asString = old and: [asses theOne value asString = new]])
		ifTrue: [self rememberToReplace: old asSymbol with: new asSymbol.
				^false].
				
	menu _ PopUpMenu fromArray: 
		(Array with: (Array with: uniqueString with: uniqueString with: '')),
		#(-),
		(asses collect: [:ass |
			Array 
				with: ass key asText, ' ---> ' asText, ass value
				with: ass
				with: '']).
	choice _ menu startUpWithHeading: 'Add these to global search and replace table?'.
	(choice == nil or: [choice = 0])
		ifTrue: [^false].
	(choice isKindOf: Association)
		ifTrue: [asses _ Array with: choice]
		ifFalse: [(choice == uniqueString) assert].
	asses do: [:rep4 |
		self rememberToReplace: rep4 key with: rep4 value asString asSymbol].
	^true!

{void} globalReplacePattern

	| old new |
	mySelectedRep ~~ nil
		ifTrue: [LastStringSought _ mySelectedRep selector].
	old _ self requestString: 'Pattern of old selectors to replace'.
	old = ''
		ifTrue: [^VOID].
	new _ self requestString: 'Pattern of new replacement selectors'.
	new = ''
		ifTrue: [^VOID].
	[self globalReplace: old with: new] whileTrue: []!

{void} globalReplaceSingle

	| old new |
	LastStringSought _ old _ mySelectedRep selector.
	new _ self requestString: 'Replace it with?'.
	new = ''
		ifTrue: [^VOID].
	self globalReplace: old with: new!

{void} nextAction: text {Text} with: controller {CodeController}

	myAction nextAction: text with: controller!

nextBrowser

	myBrowserGen nextBrowserFrom: self!

{void} rememberToReplace: old {Symbol} with: new {Symbol}

	| changes otherNew rep1 |
	myBrowserGen == nil
		ifTrue: [myBrowserGen _ MethodSearchAndReplacer shared].
	changes _ myBrowserGen changes.
	otherNew _ changes at: old ifAbsent: [nil].
	(otherNew ~~ nil
	 and: [otherNew ~~ new
	 and: [(self confirm: 'Overwrite ', old, ' ---> ', otherNew, ' with ---> ', new, '?') not]])
	 	ifTrue: [^VOID].
	changes at: old put: new.
	[rep1 _ myMethods detect: [:rep2 | rep2 selector == old] ifNone: [nil].
	rep1 ~~ nil]
		whileTrue:
			[self methodName: rep1.
			self removeMethodFromBrowser]!

{void} substitute

	| menu {PopUpMenu} sel {Symbol} |
	mySelectedRep == nil
		ifTrue: [^VOID].
	self applyAction
		ifFalse: [^VOID].
	menu _ PopUpMenu fromPrefixedArray: #(
		(all		'accept-hide-substitute'		acceptHideSubstitute	'')
		(all		'cancel-next-substitute'		cancelNextSubstitute	'')
		(all		'abort'							abortSubstitution		'')
		-
		(all		'accept & substitute all'		acceptAndSubstituteAll	'')
		(all		'substitute all silently'		substituteAllSilently		'')).
	sel _ menu startUpWithHeading: 'What should I do with edited method?'.
	(sel == nil or: [sel = 0 or: [sel == #abortSubstitution]])
		ifTrue: [^VOID].
	self perform: sel!

substituteAllSilently

	self fetchCodeController accept.
	self removeMethodFromBrowser.
	[mySelectedRep ~~ nil]
		whileTrue:
			[self applyActionSilently
				ifTrue: [self hideMethod]
				ifFalse: [self nextMethod]].
	self changed: #methodName! !

!MethodSetBrowser methodsFor: 'smalltalk: passe'!

{NOWAIT} browseOverloadsWithinList

	self passe!

{NOWAIT} browseSendersToList

	self passe! !

!MethodSetBrowser methodsFor: 'accessing'!

{Collection of: MethodRep} fullMethodList

	^myHidden asOrderedCollection, myMethods!

{Collection of: MethodRep} hidden

	^myHidden! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodSetBrowser class
	instanceVariableNames: ''!



!MethodSetBrowser class methodsFor: 'creation'!

make: gen {MethodGenerator} 
	with: sel {MethodRep default: nil} 
	with: methods {(Collection of: MethodRep) default: nil}
	with: browserGen {BrowserGenerator default: nil}
	
	^self create: gen with: sel with: methods with: browserGen! !

!MethodSetBrowser class methodsFor: 'smalltalk: defaults'!

make: gen {MethodGenerator}
	
	^self make: gen with: nil with: nil with: nil!

make: gen {MethodGenerator} 
	with: sel {MethodRep default: nil}
	
	^self make: gen with: sel with: nil with: nil!

make: gen {MethodGenerator} 
	with: sel {MethodRep default: nil} 
	with: methods {(Collection of: MethodRep) default: nil}
	
	^self make: gen with: sel with: methods with: nil! !