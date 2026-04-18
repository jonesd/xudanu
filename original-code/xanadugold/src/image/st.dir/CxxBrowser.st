'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:15 pm'!

Model subclass: #CxxBrowser
	instanceVariableNames: '
		treeBrowser {CxxOutlineBrowser}
		tree {CxxTreeAssociation}
		fileList {CxxFileOrganizer}
		file {CxxModule}
		visFlags {IdentitySet of: Symbol}
		myTranslatorClass {CxxFileTranslator class}
		class {CxxClassDescription}
		protocol {String}
		method {Symbol}
		searchMethod {Symbol}
		searchProtocol {Symbol}
		pubPrivTest {Symbol}
		meta {BooleanVar}
		textMode {Symbol}
		browseController {CodeController}'
	classVariableNames: '
		LastProtocol {String} 
		LastStringSought {String} '
	poolDictionaries: ''
	category: 'Cxx-Browser'!
CxxBrowser comment:
'	The CxxBrowser class is used to provide part of the functionality of
CxxBrowser.  It maintains and updates the right 3 columns and the bottom pane of the
browser.  The left column is handled by a CxxOutlineBrowser, which communicates with
this class to accomplish most of its function.'!



!CxxBrowser methodsFor: 'creation'!

controller: newController {ParagraphEditor}
	browseController ~= nil ifTrue: [browseController release].
	browseController _ newController.!

create: onFileOrganization {CxxFileOrganization} 
	onFileOrganization == nil ifTrue: [self error: 'must have a file organization'].
	fileList _ onFileOrganization.
	pubPrivTest _ #public.
	visFlags _ IdentitySet with: #public.
	meta _ false.
	self initTree! !

!CxxBrowser methodsFor: 'file list'!

fileName: aFile 
	self newFileList: (CxxSystemOrganization fetchModuleNamed: aFile)!

newFileList: newFile {CxxModule}

	file == newFile ifTrue: [^ nil].
	file _ newFile.
	self newClassList: class.
	self changed: #text! !

!CxxBrowser methodsFor: 'class list'!

class: newClass 
	class _ newClass.
	class = nil
		ifTrue: [self newProtocolList: nil]
		ifFalse: [
			self pubPrivTest: class visibility. 
			Dictionary keyNotFoundSignal
				handle: [:ex | Transcript cr; show: 'class ' , class classDescription name , ' no longer exists.'.
					ex return]
				do: [protocol = nil
						ifTrue: [self newProtocolList: nil]
						ifFalse: [self newProtocolList: protocol].
					(newClass isNil and: [file notNil])
						ifTrue: [self textMode: #classDefinition]
						ifFalse: [self classMode ifTrue: [self changed: #text]]]]!

classList

	| classesToShow |
	file == nil ifTrue: [^ nil].

	classesToShow _ OrderedCollection new.
	(visFlags includes: #public)
		ifTrue: [classesToShow addAll: file publicClasses].
	(visFlags includes: #protected)
		ifTrue: [classesToShow addAll: file protectedClasses].
	(visFlags includes: #private)
		ifTrue: [classesToShow addAll: file privateClasses].
	(visFlags includes: #test)
		ifTrue: [classesToShow addAll: file testClasses].
	^ self computeClassOrdering: classesToShow!

classMenu
	"Menu for class pane of cxx browser."
	
	file == nil ifTrue: [^ nil].
	class == nil ifTrue:  
		[^PopUpMenu fromArray: #(
			('add class'			addClass						'Xu: Prompt for a class name.  Add that class to this module in the Cxx organization.')	)].
	^PopUpMenu fromPrefixedArray: #(
		(all		'file' (
		 	(all		'file out changes'	fileOutClassChanges			'Xu: File out changes to this class since the baseline. ????')
			(all		'file out'				fileOutClass					'ST: File out (smalltalk) definition of this class and all its methods.')
			(all		'print out'				printClass						'ST?: Format for printer (and send to printer?)') 
			(unix	'cvs'					cvsClass						'Xu: Bring up the cvs (Concurrent Version System) menu, and apply the action to the selected class and all its methods.') ))
		(all		'spawn' ( 
			(all		'system browser'	spawnSystemBrowser		'Xu: Create a SystemBrowser positioned on this class.')
			(all		'cxx browser'			spawnCxxBrowser			'Xu: Create a CxxBrowser positioned like this one.')
			-
			(all		'category'			spawnCategory				'Xu: Create a new CategoryBrowser on the category of the selected class, positioned like this one.')
			(all		'class'				spawnClass					'Xu: Create a new ClassBrowser on the selected class, positioned like this browser.')
			(all		'family'			spawnHierarchy					'Xu: Create a FamilyBrowser which contains the selected class, its superclasses, and its subclasses.') ))
		(all		'history'			classHistory						'Xu: Create a HistoryBrowser on the selected class.')
		(all		'make' ( 
			(all		'public'				makePublic					'Xu: Make the selected class a public class of this module.  (Put it in files *x.[hc]xx)')
			(all		'protected'			makeProtected				'Xu: Make the selected class a protected class of this module.  (Put it in files *r.hxx, *x.cxx)')
			(all		'private'			makePrivate					'Xu: Make the selected class a private class of this module.  (Put it in files *p.hxx, *x.cxx)')
			(all		'test'				makeTest					'Xu: Make the selected class a test class of this module.  (Put it in files *t.[hc]xx)') ))
		-
		(all		'aspects' (
			(all		'family'			showHierarchy						'ST: Show a list of all superclass and subclasses of the selected class, with inheritance indicated by indentation.')
			(all		'definition'			editClass							'ST: Show (and allow editing of) the definition of the class (member vars, etc.)')
			(all		'comment'			editComment						'ST: Show (and allow editing of) the class comment.  (Obsolete, replaced by including comment in definition?)')
			(all		'class friends'		editClassFriends					'Xu: Edit text to be passed through to X++ in C++.  Intended for declaring class friends.') ))
		-
		(all		'inst var' (
			(all		'references'			browseFieldReferences		'ST: Prompt with a menu of all instance variables.  Show all methods that reference the chosen variable.')
			(all		'assignments'		browseFieldAssignments	'ST: Prompt with a menu of all instance variables.  Show all methods that assign to the chosen variable.') ))
		(all		'class var refs'	browseClassVariables				'ST: Prompt with a menu of class variables.  Show all methods (including those in subclasses) which reference the chosen class variable.')
		(all		'class refs'			browseClassReferences		'ST: Browse all methods that reference this class.')
		(all		'opaque refs'		browseOpaqueRefs			'Xu: Using the current state of the opaque scan info, find all X++ methods which use the selected class''s name as a token')
		-
		(all		'find'				findInClass							'Xu: Apply criteria from a FindMenu to all the methods in this class.')
		(all		'find in family'		findInFamily						'Xu: Apply criteria from a FindMenu to all the methods in this class, all its superclasses, and all its subclasses.')
		(all		'locate method'		findMethodAndSelectAlphabetic	'Xu?: Prompt with an alphabetical list of all methods of this class.  Position this browser on the chosen method.')
		-
		(all		'add class'			addClass							'Xu: Prompt for a class name.  Add that class to this module in the Cxx organization.')
		(all		'move'				moveClass							'Xu: Prompt with a menu of the Cxx organization.  Move this class to the chosen module.')
		(all		'copy deferred'		copyDeferredMethods	'Xu: Copy into this class all methods defined in its superclass which self self subclassResponsibility')
		(all		'rename'			renameClass						'ST: Rename the currently selected class, then bring up a browser on all methods that reference the class, so you can edit the reference to use the new name.')
		(all		'remove'			removeClass						'ST: Remove the currently selected class from the image.') ).!

className
	class = nil ifTrue: [^ nil].
	^ class classDescription name!

className: selection 
	"Set the receiver's currently selected class to be selection and 
	update the message category list. If this class no longer exists, 
	print a message to that effect in the system transcript, if it is open."

	| className |
	selection = nil
		ifTrue: [className _ class _ nil]
		ifFalse: 
			[className _ selection.
			class _ file fetchClass: className].
	class = nil 
		ifTrue: 
			[| spro smeth |
			self fileMode not
				ifTrue: [file = nil 
							ifTrue: [self textMode: nil] 
							ifFalse: [self textMode: #classDefinition]].
			spro _ searchProtocol.
			smeth _ searchMethod.
			self newProtocolList: nil.
			searchProtocol _ spro.
			searchMethod _ smeth]
		ifFalse: [
			pubPrivTest _ class visibility.
			"remove from any other groups in this cxx file"
			self checkClassAndRemove: class. 
			Dictionary keyNotFoundSignal 
				handle: [:ex | Transcript cr; show: 'class ' , className , ' no longer exists.'.
						ex return]
				do: [| spro smeth |
					spro _ self selectedClass organization getCategoryOfElement: searchMethod.
					spro ~~ #'As yet unclassified' ifTrue: [searchProtocol _ spro].
					spro _ searchProtocol.
					smeth _ searchMethod.
					self newProtocolList: searchProtocol.
					searchProtocol _ spro.
					searchMethod _ smeth.
					self classMode ifTrue: [self changed: #text]]]!

classRep
	^class = nil ifFalse: [self makeClassRep: self selectedClass]!

classRep: newClass {ClassRep}
	(#(cxxHeader hxxHeader) includes: textMode) 
		ifTrue: ["self textMode: #classDefinition"].
	newClass ~= nil
		ifTrue: [self className: newClass className]
		ifFalse: [self className: nil]!

computeClassOrdering: list 
	"Supply a result collection into which elements will be added in inheritance 
	(then alphabetic) order."

	| newList |
	newList _ self computeClassOrdering: (list asSortedCollection collect: [:cxxDesc | cxxDesc classDescription])
		into: OrderedCollection new
		indent: 0.
	^ newList!

computeClassOrdering: list into: result indent: indent 
	"Add the elements of list into result in nesting alphabetic order."

	list isEmpty
		ifFalse: 
			[| sup related unrelated |
			sup _ list detect: [:candidate | 
				(list detect: [:maybeSup | 
					candidate inheritsFrom: maybeSup] ifNone: []) == nil].
			result addLast: (self makeClassRep: sup with: indent with:
				(sup fetchCxxClassDescription ~~ nil 
					ifTrue: [sup getCxxClassDescription visibility]
					ifFalse: [nil])).
			related _ OrderedCollection new.
			unrelated _ OrderedCollection new.
			list do: [:sub | sub = sup ifFalse: [(sub inheritsFrom: sup)
						ifTrue: [related addLast: sub]
						ifFalse: [unrelated addLast: sub]]].
			self computeClassOrdering: related
				into: result
				indent: indent + 1.
			self computeClassOrdering: unrelated
				into: result
				indent: indent].
	^result!

fetchSelectedCxxClass
	"Answer the class object that is currently selected."

	^ class!

newClassList: initialClass

	class _ initialClass.
	self classMode ifFalse: ["self textMode: #classDefinition"].
	self changed: #className!

{Behavior} selectedClass
	"Answer the class object that is currently selected."

	class == nil ifTrue: [^ nil].
	meta
		ifTrue: [^ class classDescription class]
		ifFalse: [^ class classDescription]! !

!CxxBrowser methodsFor: 'public/private/test'!

{void} changeVisibility: ofFlag {visibilityEnum}

	(visFlags includes: ofFlag)
		ifTrue: [self switchOff: ofFlag]
		ifFalse: [self switchOn: ofFlag]!

{BooleanVar} private
	^ (visFlags includes: #private)
		ifTrue: [#private]
		ifFalse: [nil]!

{BooleanVar} protected
	^ (visFlags includes: #protected)
		ifTrue: [#protected]
		ifFalse: [nil]!

{BooleanVar} public
	^ (visFlags includes: #public)
		ifTrue: [#public]
		ifFalse: [nil]!

pubPrivTest: newValue 
	| prevGroup |
	self changeRequest ifFalse: [^VOID].
	prevGroup _ self fetchCurrentClassGroup.
	(prevGroup ~~ nil and: [prevGroup isEmpty]) ifTrue: [
		file setGroup: pubPrivTest with: nil].
	pubPrivTest _ newValue.
	file ~~ nil
		ifTrue: [self newFileList: file]
		ifFalse: [self newFileList: nil].
	self newClassList: class.
	(self classMode or: [self fileMode])
		ifTrue: [self changed: #text].
	self switchOn: pubPrivTest!

{void} switchOff: ofFlag {visibilityEnum}

	(visFlags includes: ofFlag)
		ifFalse: [^VOID]. 
	(self bodyFileMode and: [ofFlag ~~ #test])
		ifTrue: 
			[#(public protected private) do: [:vf {Symbol} |
				visFlags remove: vf.
				self changed: vf]]
		ifFalse:
			[visFlags remove: ofFlag.
			self changed: ofFlag].
	(visFlags includes: pubPrivTest) ifFalse:
		[self pubPrivTest: #public].
	self changed: #className!

{void} switchOn: ofFlag {visibilityEnum}

	| changed {Boolean} |
	changed _ false.
	(self bodyFileMode and: [ofFlag ~~ #test])
		ifTrue: 
			[self switchOff: #test.
			#(public protected private) do: [:vf {Symbol} |
				(visFlags includes: vf)
					ifFalse: [visFlags add: vf.
							self changed: vf.
							changed _ true]]]
		ifFalse:
			[(visFlags includes: ofFlag)
				ifFalse: [visFlags add: ofFlag.
						self changed: ofFlag.
						changed _ true].
			self fileMode
				ifTrue: [
					visFlags copy do: [:vf2 {Symbol} |
						vf2 ~~ ofFlag
							ifTrue: [self switchOff: vf2]]]].
	pubPrivTest ~~ ofFlag
		ifTrue: [self pubPrivTest: ofFlag].
	changed 
		ifTrue: [self changed: #className]!

{BooleanVar} test
	^ (visFlags includes: #test)
		ifTrue: [#test]
		ifFalse: [nil]! !

!CxxBrowser methodsFor: 'class/inst switch'!

meta
	^ meta!

meta: metaFlag
	self changeRequest ifFalse: [^self changed: #meta].
	meta _ metaFlag.
	self changed: #meta.
	self newProtocolList: protocol.
	self classMode ifTrue: [self changed: #text]! !

!CxxBrowser methodsFor: 'protocol list'!

newProtocolList: selection
	searchProtocol _ protocol _ selection.
	self changed: #protocolName!

protocol
	protocol = nil ifTrue: [^nil].
	^protocol!

protocol: selection 
	"Set the receiver's currently selected message category to be selection and 
	update the message selector list."

	selection == nil
		ifTrue: 
			[protocol _ method _ nil.
			(class ~~ nil and: [textMode == #methodDefinition]) ifTrue: [self textMode: #classDefinition]]
		ifFalse: 
			[protocol _ selection printString asSymbol.
			LastProtocol _ protocol].
	searchProtocol _ protocol.
	self newMethodList: searchMethod!

{OrderedCollection} protocolList
	class == nil ifTrue: [^nil].
	^ self selectedClass organization categories collect: [ :each | self makeProtocolRep: each]!

protocolMenu
	"Menu for protocol pane of CxxBrowser."

	protocol == nil ifTrue:
		[^PopUpMenu fromArray: #(
			('add protocol'	addProtocol		'') )].
			
	^PopUpMenu fromPrefixedArray: #(
		(all		'file' (
			(all		'print out'				printOutProtocol		'')		"See protocol pane of Browser"
			(unix	'cvs'					cvsProtocol			'Xu: Bring up the cvs (Concurrent Version System) menu, and apply the action to the selected method.') ))
		(all		'spawn' (
			(all		'system browser'	spawnSystemBrowser	'')
			(all		'cxx browser'			spawnCxxBrowser		'')
			-
			(all		'category'			spawnCategory		'')
			(all		'class'				spawnClass				'')
			(all		'family'			spawnHierarchy		'')
			(all		'protocol'			spawnProtocol			'') ))
		(all		'history'			protocolHistory			'')
		-
		(all		'find'				findInProtocol			'')
		-
		(all		'add protocol'		addProtocol				'')
		(all		'rename'			renameProtocol			'')
		(all		'remove'			removeProtocol			'') ).!

protocolName
	^protocol!

protocolName: selection 
	self protocolRep: (selection = nil
			ifTrue: [nil]
			ifFalse: [self makeProtocolRep: selection])!

protocolRep
	"Answer the receiver's currently selected message category."

	^ protocol == nil ifTrue: [nil] ifFalse: [self makeProtocolRep: protocol]!

protocolRep: selection
	"Set the receiver's currently selected message category to be selection and 
	update the message selector list."

	"Transcript show: selection printString; cr."
	selection == nil
		ifTrue: 
			[protocol _ method _ nil.
			(class ~~ nil and: [textMode == #methodDefinition]) ifTrue: [self textMode: #classDefinition]]
		ifFalse: 
			[protocol _ selection methodName.
			LastProtocol _ protocol].
	searchProtocol _ protocol.
	self newMethodList: searchMethod! !

!CxxBrowser methodsFor: 'method list'!

method
	^ method!

method: newMethodName 
	searchMethod _ method _ newMethodName.
	(newMethodName == nil and: [protocol == nil])
		ifTrue: ["method _ nil. self changed: #text." ^self].
	method ~= nil ifTrue: [method _ method asSymbol].
	Dictionary keyNotFoundSignal handle: 
		[:ex | Transcript cr; show: 'method ' , method , ' no longer exists.'.
		ex return]
		do: [self textMode: #methodDefinition]!

methodList
	"Answer the sequenceable collection containing the message selectors that 
	the receiver accesses via the currently selected class and message category."

	protocol == nil ifTrue: [^ nil].
	^ (self selectedClass organization listAtCategoryNamed: protocol "methodName") collect: [:meth | CxxMethodRep create: meth with: (ChangeLog hasChangesFor: meth
			in: self selectedClass)]!

methodMenu
	"Menu for method pane of a CxxBrowser."

	| tags |
	method == nil ifTrue: [^ nil].
	
	tags _ PopUpMenu tags, (meta ifTrue: [#(caller)] ifFalse: [#(impl)]).
	(meta and: [PopUpMenu shortForm not])
		ifTrue: [tags _ tags, #(impl)].
		
	^PopUpMenu matching: tags fromPrefixedArray: #(
		(all		'file' (
			(all		'print out'			printOutMessage		'')		"See selectorMenu in Browser."
			(unix	'cvs'				cvsMethod			'Xu: Bring up the cvs (Concurrent Version System) menu, and apply the action to the selected method.') ))
		(all		'spawn' (
			(all		'system browser'	spawnSystemBrowser	'')
			(all		'cxx browser'		spawnCxxBrowser		'')
			-
			(all		'category'			spawnCategory		'')
			(all		'class'				spawnClass				'')
			(all		'family'			spawnHierarchy		'')
			(all		'protocol'			spawnProtocol			'')
			(all		'method'			spawnMethod			'') ))
		(all		'history'			methodHistory			'')
		-
		(all		'senders'				browseSenders			'ST: Create a browser on all methods which send the selected message.')
		(caller	'callers'				browseCallers			'Xu: Create a browser on all those that send this message directly to this class')
		(impl	'implementors'		browseImplementors		'ST: Create a browser on all methods which implement the selected message.')
		(impl	'polymorphs'			browsePolymorphs		'Xu: Create a browser on all methods which are C++ polymorphic with the selected message.')
		(long	'messages'			browseMessages		'ST: Prompt with a menu of the messages sent by this method.  Create a browser on all implementors of the chosen message.')
		-
		(all		'move'				moveMethod			'')
		(all		'remove'			removeMethod			'') )!

methodNames
	protocol = nil ifTrue: [^ nil].
	^ (self selectedClass organization listAtCategoryNamed: protocol) asOrderedCollection collect: [:nm | CxxMethodRep create: nm with: true]!

methodRep
	(self selectedClass) == nil ifTrue: [^nil].
	^ CxxMethodRep create: method with: (ChangeLog hasChangesFor: method
			in: self selectedClass)!

{void} methodRep: newMethodRep {CxxMethodRep} 
	searchMethod _ method _ (newMethodRep ~~ nil ifTrue: [newMethodRep methodName asSymbol]).
	(method == nil and: [protocol == nil]) ifTrue: [^VOID].
	Dictionary keyNotFoundSignal handle: 
		[:ex | Transcript cr; show: 'method ' , method , ' no longer exists.'.
			ex return]
		do: [self textMode: #methodDefinition]!

newMethodList: init {Symbol} 
	searchMethod _ method _ init.
	self changed: #method!

selector
	^ method! !

!CxxBrowser methodsFor: 'text'!

acceptText: aText from: aController "***** CORRECT ONE ****"
	| commentDest |
	textMode == #classDefinition ifTrue: [^self acceptClass: aText from: aController].
	textMode == #methodDefinition ifTrue: [^self acceptMethod: aText from: aController].
	textMode == #friends ifTrue: [self friends: (aText string). ^ true].
	textMode == #cxxHeader ifTrue: [^ self cxxHeader: aText string].
	textMode == #hxxHeader ifTrue: [^ self hxxHeader: aText string].
	textMode == #translatedFile ifTrue: [^ false].
	textMode == #typeRefs ifFalse: [^false].
	textMode == #fileComment ifTrue: [file comment: aText string. ^ true].
	(textMode == #comment or: [textMode == #groupComment]) ifTrue: [
		commentDest _ self currentCommentHolder.
		(commentDest isKindOf: CxxClassGroup) ifTrue: [
			file comment: aText string in: pubPrivTest.
			^true].
		commentDest comment: aText string.
		^true].
	 ^false!

methodHistorySummary
	| stream |
	stream _ TextStream on: (String new: 200).
	(self selectedClass organization listAtCategoryNamed: protocol) do: [ :sel |
		(ChangeLog hasChangesFor: sel in: self selectedClass since: ChangeLog baseline)
			ifTrue:
				[stream
					nextPut: $";
					emphasis: stream emphasis + 1;
					nextPutAll: sel;
					emphasis: stream emphasis - 1;
					nextPutAll: '   ';
					nextPutAll: (ChangeLog summaryFor: sel in: self selectedClass);
					nextPut: $";
					cr]].
	stream contents isEmpty
		ifTrue: [stream space; emphasis: stream emphasis + 2;
			nextPutAll: '"No changed methods"'; emphasis: stream emphasis - 2; space].
	^stream contents!

prompt: promptString initially: initialString 
	"Prompt the user with the message question promptString, with initial 
	answer initialString, and accept the answer either with the menu 
	item accept or the keyboard press RETURN. Answer the string that 
	the user provides."

	^FillInTheBlank 
		request: promptString , '
then accept or CR' 
		initialAnswer: initialString!

text
	| text |
	textMode == #friends ifTrue: [^ self friends].
	textMode == #instVarTypes ifTrue: [^class instVarTypeString asText].
	textMode == #cxxHeader ifTrue: [^self cxxHeader asText].
	textMode == #hxxHeader ifTrue: [^self hxxHeader asText].
	textMode == #translatedFile ifTrue: [^ self translatedFileText].
	textMode == #typeRefs ifTrue: [^ self typeRefText].
	textMode == #classDefinition ifTrue: [class == nil
			ifTrue: [file == nil ifFalse: [^ (Class cxxTemplate: ('Xanadu-', file moduleName)) asText].
				^(Class template: 'Cxx Class') asText]
			ifFalse: [^self selectedClass definitionWithCommentAndAttributes asText]].
	textMode == #methodDefinition ifTrue: [method == nil
			ifTrue: [Sensor leftShiftDown
				ifFalse: [^self methodHistorySummary]
				ifTrue: [^class sourceCodeTemplate asText]]
			ifFalse: [^(self selectedClass sourceCodeStringAt: method) 
						asText makeSelectorBoldIn: self selectedClass]].
	textMode == #file ifTrue: [^'file to add' asText].
	textMode == #protocol ifTrue: [^'protocol to add' asText].
	(textMode == #fileComment and: [file ~= nil]) ifTrue: [^ file comment asText].
	(textMode == #comment or: [textMode == #groupComment])
		ifTrue: 
			[text _ self currentCommentHolder comment asText.
			text isEmpty ifFalse: [^text].
			meta ifTrue: [^'Select the browser switch "instance" to see the comment' asText].
			^'This class has no comment' asText].
	textMode == #hierarchy ifTrue: [^self selectedClass printHierarchy asText].
	^Text new!

textMenu
	^PopUpMenu standardCodeMenu.!

textMode: aSymbol 
	"Set the mode for which text to display to be aSymbol, and then 
	announce that the receiver has changed."

	| wasNil {BooleanVar}  |
	"Transcript nextPutAll: textMode printString; space; show: aSymbol; space."
	"aSymbol == #classDefinition
		ifTrue: [self halt]."
	wasNil _ textMode == nil.
	textMode _ aSymbol.
	wasNil ifFalse: [self changed: #text].
	self switchOn: pubPrivTest! !

!CxxBrowser methodsFor: 'doit/explain'!

doItContext
	"Answer the context in which a text selection can be evaluated."

	^ nil!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	^ self nonMetaClass!

doItValue: ignored
	"Set the value to be returned when the interrupted process proceeds."!

explainSpecial: string 
	"Answer with a string explaining the code view selection if it is 
	displaying one of the special edit functions."

	| classes whole lits reply |
	(textMode == #classDefinition)
		ifTrue: 
			["Selector parts in class definition"
			string last == $: ifFalse: [^nil].
			lits _ Array with: #subclass:instanceVariableNames:classVariableNames:poolDictionaries:category:.
			(whole _ lits detect: [:each | (each keywords
					detect: [:frag | frag = string] ifNone: []) ~~ nil]
						ifNone: []) ~~ nil
				ifTrue: [reply _ '"' , string , ' is one part of the message selector ' , whole , '.']
				ifFalse: [^nil].
			classes _ Smalltalk allClassesImplementing: whole.
			classes _ 'these classes ' , classes printString.
			^reply , '  It is defined in ' , classes , '."
Smalltalk browseAllImplementorsOf: #' , whole].
	^nil! !

!CxxBrowser methodsFor: 'private: file'!

addFile
	"Prompt the user for a new file name. Insert the file into 
	the class organization before the currently selected file."

	| aString  |
	self changeRequest ifFalse: [^self].
	aString _ self prompt: 'Enter new file name' initially: 'file name'.
	aString isEmpty ifTrue: [^self].
	self thingToDo. "log the change from the fileList object"
	ChangeLog log: #add path: (self currentPath at: self currentPath size put: aString asSymbol; yourself)
		changes: (self wrapCxxOrgChange: 'SystemCxxOrganization addFileNamed: ',
			aString storeString).
	fileList addFileNamed: aString.
	self newFileList: (fileList fetchModuleNamed: aString).!

checkStructure
	MessageTally mySpy: [ Cursor execute showWhile: [self fixOrganization]]!

editCxxHeader
	self changeRequest ifFalse: [^self].
	self newClassList: nil.
	self textMode: #cxxHeader.!

{void} editFileComment
	self changeRequest ifFalse: [^self].
	self textMode: #fileComment.
	self newClassList: nil!

{void} editGroupOrClassComment
	self changeRequest ifFalse: [^self].
	self textMode: #groupComment.
	self newClassList: nil!

editHxxHeader
	self changeRequest ifFalse: [^self].
	self newClassList: nil.
	self textMode: #hxxHeader!

fileOutFile
		| fileName aFileStream |
	file = nil ifTrue: [^ VOID].
	fileName _ Filename request: 'File out on' initially: (file moduleName, '.st') shouldExist: false. 
	fileName = '' ifTrue: [^VOID].
	aFileStream _ (Filename named: fileName) writeStream.
	[file fileoutSTOn: aFileStream]
		valueNowOrOnUnwindDo: [aFileStream close]!

{void} fileoutOrganization
	| fileName aFileStream |
	fileName _ Filename
				request: 'File out on'
				initially: 'cxx.org'
				shouldExist: false.
	fileName = '' ifTrue: [^VOID].
	aFileStream _ (Filename named: fileName) writeStream.
	[fileList fileoutOrgOn: aFileStream]
		valueNowOrOnUnwindDo: [aFileStream close]!

groupTypeFrom: aTypeChar {Character} 
	aTypeChar = $x
		ifTrue: [^#public]
	ifFalse: [aTypeChar = $r
		ifTrue: [^#protected]
	ifFalse: [aTypeChar = $p
		ifTrue: [^#private]
	ifFalse: [aTypeChar = $t
		ifTrue: [^#test]
	ifFalse: [self error: 'bad grouptype'.
		^#public]]]]!

{Class} pickAClass: prompt	
	"Choose a class with a prompter.  Bring up menu for wildcards."

	| destClassName destClass classes |
	destClassName _ FillInTheBlank request: prompt initialAnswer: '*'. 
	destClassName = '' ifTrue: [^nil].
	(destClassName findString: '*' startingAt: 1) ~=0
		ifTrue: [classes _ OrderedCollection new.
				Cursor execute showWhile:
					[classes _ Smalltalk classNames select: [ :cn | destClassName match: cn]].
				(classes == nil or: [classes size = 0]) ifTrue: [^nil].
				(destClassName _ (PopUpMenu fromArray: (classes collect: [:cn |
					Array with: cn])) startUp) = 0
						ifTrue: [^nil]]
		ifFalse: [destClassName _ 
					Smalltalk keys 
						detect: [ :cn | destClassName match: cn] 
						ifNone: [^nil]].
	destClass _ Smalltalk at: destClassName asSymbol ifAbsent: [^nil].
	meta ifTrue: [destClass _ destClass class].
	^destClass!

printOutFile
		"Print the category."
	
	| stream |
	stream _ LabelledTextStream on: (String new: 10000).
	file printOutOn: stream.
	self hardcopyStream: stream with: file moduleName!

removeFile
	"Uncalled"
	self changeRequest ifFalse: [^self].
	(file notNil and: [file isEmpty not]) ifTrue:
		[(self confirm: 'Are you certain that you want to
remove the file', file moduleName, '?') ifFalse: [^VOID]].
	self thingToDo. "log the cxx change to the log file from the file object"
	"ChangeLog log: #remove path: self currentPath
		changes: (self wrapCxxOrgChange: 'SystemCxxOrganization removeFile: ' , 			'(SystemCxxOrganization fetchFileNamed: ',
			file moduleName storeString, ')')."
	fileList removeFile: file.
	self newFileList: nil!

{void} renameFile
	"Prompt the user for a new file name. Insert the file into 
	the class organization before the currently selected file."

	| aString  oldName |
	self changeRequest ifFalse: [^VOID].
	file = nil ifTrue: [^ VOID].
	aString _ self prompt: 'Enter new file name' initially: file moduleName.
	aString isEmpty ifTrue: [^VOID].
	self thingToDo. "log the cxx change to the log file from the file list object"
	oldName _ file moduleName.
	file setFileName: aString.
	"ChangeLog logRename: self currentPath from: oldName asSymbol
		changes: ('(SystemCxxOrganization fetchModuleNamed: ', 
			oldName storeString, ') setFileName: ', aString storeString)."
	self newFileList: (fileList fetchModuleNamed: aString)!

showFile: translatorClass {CxxFileTranslator class}

	self changeRequest ifFalse: [^self].
	self newClassList: nil. 
	myTranslatorClass _ translatorClass.
	self textMode: #translatedFile.!

{void} updateFiles
	self changeRequest ifFalse: [^self].
	self newFileList: file! !

!CxxBrowser methodsFor: 'searching'!

{BooleanVar} findClass: aClass {Object}
	^treeBrowser findClass: aClass! !

!CxxBrowser methodsFor: 'private: class'!

{BooleanVar} acceptClass: aText from: aController 
	| oldClass newClass cxx |
	file = nil ifTrue: [^false].
	oldClass _ class == nil
				ifTrue: [Object]
				ifFalse: [self selectedClass].
	newClass _ oldClass subclassDefinerClass
				evaluate: aText string
				notifying: aController
				logged: false.
	newClass isBehavior ifFalse: [^false].
	newClass isMeta ifFalse: [
		(cxx _ newClass fetchCxxClassDescription) = nil
			ifTrue: [cxx _ CxxClassDescription create: newClass name with: file]
			ifFalse: [cxx classDescription: newClass name].
		self addClass: cxx.
		self newClassList: cxx].
	^true!

{void} addClass
	| newClass {ClassDescription} cxxClass {CxxClassDescription}  |
	
	file = nil ifTrue: [^ nil].
	newClass _ self pickAClass: 'Add class named:'.
	newClass = nil ifTrue: [^ VOID].
	self pubPrivTest: #public.
	newClass isMeta ifTrue: [newClass _ newClass soleInstance].
	newClass fetchCxxClassDescription = nil ifTrue: [
		newClass organization cxxClassDescription: (CxxClassDescription create: newClass name with: file)].
	self class: (cxxClass _ newClass getCxxClassDescription).
	self addClass: cxxClass.
	self changed: #className.!

{void} addClass: aNewClass {CxxClassDescription}
	| group |
	file = nil ifTrue: [^ VOID].
	group _ self getOrMakeCurrentClassGroup.
	group ~= nil ifTrue: [file addClass: aNewClass in: pubPrivTest]!

{NOWAIT} browseClassReferences
	
	(ClassRefsFilter make: self nonMetaClass) browse: self fetchMethodRep!

{void} browseClassVariables
	"Show a menu of all class variables of the currently selected class  
	and its superclasses.  Browse all methods which refer to the variable selected."

	| association selectedClass |
	selectedClass _ self nonMetaClass.
	association _ selectedClass
		showVariableMenu: [:aClass | aClass classPool associations asSortedCollection]
		collectWithClass: [ :aClass :assoc | | cxx |
			cxx _ aClass fetchCxxClassDescription.
			cxx == nil
				ifTrue: [assoc key]
				ifFalse: [assoc key , ' ' , (cxx classVarTypeAt: assoc key)]].
	association isNil 
		ifTrue: [^VOID].
	(ClassVarRefs make: selectedClass with: association key) browse: self fetchMethodRep!

browseFieldAssignments
	"Show a menu of all instance variables of the currently selected class  
	and its superclasses.  Browse all methods which assign to the variable selected."

	self browseFieldAssignments: [:aClass | aClass instVarNames]!

browseFieldAssignments: generatorBlock
	"Show a menu of all instance variables of the currently selected class  
	and its superclasses.  Browse all methods which refer to the variable selected."
	| name |
	name _ self selectedClass showVariableMenu: generatorBlock
		collectWithClass: [ :aClass :cname | | cxx |
			cxx _ aClass fetchCxxClassDescription.
			cxx == nil
				ifTrue: [cname]
				ifFalse: [cname , ' ' , (aClass isMeta
					ifTrue: [cxx classInstVarTypeAt: cname]
					ifFalse: [cxx instVarTypeAt: cname])]].
	name isNil 
		ifTrue: [^VOID].
	(InstVarAssignments make: self selectedClass with: name) browse: self fetchMethodRep!

browseFieldReferences
	"Show a menu of all instance variables of the currently selected class  
	and its superclasses.  Browse all methods which refer to the variable selected."

	self browseFieldReferences: [:aClass | aClass instVarNames]!

browseFieldReferences: generatorBlock
	"Show a menu of all instance variables of the currently selected class  
	and its superclasses.  Browse all methods which refer to the variable selected."
	| name |
	name _ self selectedClass showVariableMenu: generatorBlock
		collectWithClass: [ :aClass :cname | | cxx |
			cxx _ aClass fetchCxxClassDescription.
			cxx == nil
				ifTrue: [cname]
				ifFalse: [cname , ' ' , (aClass isMeta
					ifTrue: [cxx classInstVarTypeAt: cname]
					ifFalse: [cxx instVarTypeAt: cname])]].
	name isNil 
		ifTrue: [^VOID].
	(InstVarRefs make: self selectedClass with: name) browse: self fetchMethodRep!

{NOWAIT} browseOpaqueRefs
	
	(OpaqueReferences make: self nonMetaClass) browse: self fetchMethodRep!

checkClassAndRemove: whichClass {CxxClassDescription} 
	pubPrivTest ~~ #public ifTrue: [
		(file publicClasses includes: whichClass)
			ifTrue: [file fetchPublicGroup removeClass: whichClass]].
	pubPrivTest ~~ #protected ifTrue: [
		(file protectedClasses includes: whichClass)
			ifTrue: [file fetchProtectedGroup removeClass: whichClass]].
	pubPrivTest ~~ #private ifTrue: [
		(file privateClasses includes: whichClass)
			ifTrue: [file fetchPrivateGroup removeClass: whichClass]].
	pubPrivTest ~~ #test ifTrue: [
		(file testClasses includes: whichClass)
			ifTrue: [file fetchTestGroup removeClass: whichClass]]!

classHistory
	self selectedClass == nil ifTrue: [^nil].
	ChangeLog browseHistoryOf: self selectedClass backTo: ChangeLog start.!

classMode
	^#(classDefinition hierarchy comment friends instVarTypes) includes: textMode!

{NOWAIT} cvsClass

	| op {CVSOperator} |
	op _ CVSOperator fetchFromMenu.
	op ~~ nil ifTrue:
		[op cvsClass: self selectedClass nonMeta]!

editClass
	self changeRequest ifFalse: [^self].
	self textMode: #classDefinition.
	self newProtocolList: nil!

editClassFriends
	self changeRequest ifFalse: [^self].
	self newProtocolList: nil.
	self textMode: #friends.!

editComment
	self changeRequest ifFalse: [^self].
	self textMode: #comment.
	self newProtocolList: nil!

{CxxClassGroup} fetchCurrentClassGroup

	file = nil 
		ifTrue: [^nil]
		ifFalse: [^file fetchGroupFor: pubPrivTest]!

fileOutClass

	| fileName fileStream |
	fileName _ Filename request: 'File out on' initially: (self nonMetaClass name, '.st') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	self nonMetaClass fileOutOn: fileStream.]
		valueNowOrOnUnwindDo: [fileStream close]!

{void} findAndShowMethod: methodName {String}

	class = nil ifTrue: [^ VOID].
	methodName isNil
		ifFalse: [
			self newProtocolList: (self selectedClass organization categoryOfElement: methodName).
			self newMethodList: methodName]!

{NOWAIT} findInClass

	self selectedClass == nil ifTrue: [^VOID].
	self browseFiltered: (FromClass make: self selectedClass nonMeta)!

{NOWAIT} findInFamily

	self selectedClass == nil ifTrue: [^VOID].
	self browseFiltered:(FromFamily make: self selectedClass nonMeta)!

{void} findMethodAndSelectAlphabetic
	"Show a menu of the methods implemented by this class.  Select the chosen one."

	| chosenMethod {Symbol} methods {OrderedCollection of: Symbol} |
	class = nil 
		ifTrue: [^ VOID].
	methods _ self selectedClass selectors asSortedCollection.
	methods isEmpty
		ifTrue: [^VOID].
	chosenMethod _ (PopUpMenu fromArray: (methods collect: [:sel |
		Array with: sel])) startUp.
	chosenMethod = 0
		ifTrue: [^VOID].
	self findAndShowMethod: chosenMethod.!

{CxxClassGroup} getOrMakeCurrentClassGroup

	file = nil 
		ifTrue: [^nil]
		ifFalse: [^file getOrMakeGroupFor: pubPrivTest]!

makeClassRep: withClass 
	^self makeClassRep: withClass with: 0  with:
		(withClass fetchCxxClassDescription ~~ nil 
				ifTrue: [withClass getCxxClassDescription visibility]
				ifFalse: [nil])!

makeClassRep: withClass with: indent
	^CxxClassRep
		create: withClass name 
		with: (ChangeLog hasChangesFor: withClass) 
		with: indent
		with: nil!

makeClassRep: withClass with: indent with: pubPriv
	^CxxClassRep
		create: withClass name 
		with: (ChangeLog hasChangesFor: withClass) 
		with: indent
		with: pubPriv!

{void} moveClass
	| module {String} target {CxxModule} |
	module _ FromCxxModule pickAModuleFrom: tree.
	module = nil 
		ifTrue: [^VOID].
	target _ CxxSystemOrganization getModuleNamed: module.
	target addClass: class in: pubPrivTest.
	self changed: #className.!

nonMetaClass
	"Answer the class that is currently selected (nil if none), even
	if looking at the metaClass."
	| classOrNil |
	classOrNil _ self selectedClass.
	(meta and: [classOrNil ~~ nil])
		ifTrue: [classOrNil _ classOrNil soleInstance].
	^classOrNil!

promptClass
	self newClassList: nil.
	self textMode: #classDefinition!

removeClass

	self changeRequest ifFalse: [^self].
	class = nil ifTrue: [^ nil].
	self removeClass: class.
	self newClassList: nil!

removeClass: whichClass {CxxClassDescription}

	| group |
	self changeRequest ifFalse: [^self].
	group _ self fetchCurrentClassGroup.
	group = nil ifTrue: [Transcript show: 'Browser confused...'; cr; endEntry. ^ VOID].
	Dictionary keyNotFoundSignal 
		handle: [:ex | Transcript cr; show: 'can''t remove the class. class ', class name, ' no longer exists.'; endEntry. 
				ex return]
				"KeyNotFoundSignal is raised when the class name to be removed 
				in a browser is already removed in another browser."
		do: [(self confirm: 
'Are you certain that you want to 
DESTROY the class ', class name, '?')
				ifTrue: 
				[class classDescription subclasses size > 0
					ifTrue: [self notify: class name , ' has subclasses'. ^ false].
				group removeClass: whichClass.
				class classDescription removeFromSystem]]!

renameClass
	| aString cleanString newName oldName |
	self changeRequest ifFalse: [^self].
	aString _ self prompt: 'Enter new ClassName' initially: self nonMetaClass name.
	aString isEmpty ifTrue: [^self].
	cleanString _ aString select: [:aChar | aChar isLetter or: [aChar isDigit]].
	cleanString = aString ifFalse: [(self confirm: 'Invalid characters in class name.  Should I use ' , cleanString , '?')
			ifTrue: [aString _ cleanString]
			ifFalse: [Transcript show: 'using odd name for class >'; print: aString; cr]].
	aString first isLowercase ifTrue: [aString at: 1 put: (aString at: 1) asUppercase.
		(self confirm: 'Class names must be capitalized.  Should I use ' , aString , '?')
			ifFalse: [^self]].
	newName _ aString asSymbol.
	oldName _ self nonMetaClass name.
	aString = oldName
		ifFalse: 
			[self nonMetaClass rename: newName.
			self newClassList: class.
			Transcript cr; show: 'Searching for references to this class...'.
			(ClassRefsFilter make: self nonMetaClass with: oldName) browse: self fetchMethodRep]!

showHierarchy
	self changeRequest ifFalse: [^self].
	self newProtocolList: nil.
	self textMode: #hierarchy.!

spawnCategory
	BrowserView openCategoryBrowserOn: self copyAsBrowser!

spawnClass
	BrowserView openClassBrowserOn: self copyAsBrowser!

spawnHierarchy
	BrowserView openFamilyBrowserOn: self copyAsBrowser browseHierarchy! !

!CxxBrowser methodsFor: 'private: protocol'!

{void} addAllMethods
	| methodArray |
	protocol = nil ifTrue: [^nil].
	methodArray _ 
		(meta
			ifTrue: [class classDescription class]
			ifFalse: [class classDescription]) 
				organization listAtCategoryNamed: protocol protocolName asSymbol.
	methodArray do: [:meth | self addMethod: meth]!

addProtocol
	| aString newProtocol |
	self changeRequest ifFalse: [^self].
	aString _ self prompt: 'Enter new protocol name' initially: (LastProtocol == nil
					ifTrue: ['protocol name']
					ifFalse: [LastProtocol]).
	aString isEmpty ifTrue: [^self].
	newProtocol _ aString asSymbol.
	self selectedClass organization addCategory: newProtocol before: protocol.
	self selectedClass reorganize.
	self newProtocolList: newProtocol!

{NOWAIT} cvsProtocol

	| op {CVSOperator} |
	op _ CVSOperator fetchFromMenu.
	op ~~ nil ifTrue:
		[op cvsProtocol: protocol in: self selectedClass]!

{NOWAIT} findInProtocol

	self protocol == nil
		ifTrue: [^VOID].
	self browseFiltered: (FromProtocol make: self selectedClass with: protocol)!

{OrderedCollection} listOfMethods
	protocol = nil ifTrue: [^ OrderedCollection new].
	^ self selectedClass organization listAtCategoryNamed: protocol!

{OrderedCollection} listOfProtocols
	class = nil ifTrue: [^ OrderedCollection new].
	^ self selectedClass organization categories!

makeProtocolRep: aSymbol

	^ CxxMethodRep
		make: aSymbol
		with: ((self selectedClass organization listAtCategoryNamed: aSymbol)
			detect: [ :each |
				ChangeLog hasChangesFor: each
				in: self selectedClass]
			ifNone: [nil]) ~~ nil!

{String} methodContainingString: aString {String} with: startMethod {String} 
	| stepr {TableStepper} notFound {BooleanVar} spot {IntegerVar} |
	protocol = nil ifTrue: [^''].
	stepr _ self listOfMethods stepper.
	notFound _ true.
	startMethod ~= nil ifTrue: [[stepr hasValue & notFound]
			whileTrue: [stepr get = startMethod
					ifTrue: [notFound _ false]
					ifFalse: [stepr step]]].
	[stepr hasValue]
		whileTrue: [spot _ (self selectedClass sourceCodeStringAt: stepr fetch)
						findString: aString startingAt: 1.
			spot ~= 0
				ifTrue: [^stepr fetch]
				ifFalse: [stepr step]]!

{String} methodContainingString: aString {String} with: aProt {CxxProtocol} with: startMethod {String} 
	| stepr {TableStepper} notFound {BooleanVar} spot {IntegerVar} |
	aProt = nil ifTrue: [^''].
	stepr _ aProt methods stepper.
	notFound _ true.
	startMethod ~= nil ifTrue: [[stepr hasValue & notFound]
			whileTrue: [stepr get = startMethod
					ifTrue: [notFound _ false]
					ifFalse: [stepr step]]].
	[stepr hasValue]
		whileTrue: [spot _ (self selectedClass sourceCodeStringAt: stepr fetch)
						findString: aString startingAt: 1.
			spot ~= 0
				ifTrue: [^stepr fetch]
				ifFalse: [stepr step]].
	^ ''.!

{String} pickAProtocol
	| prots {Array of: String}
	  menu {PopUpMenu}
	  newProtocol {String} 
	  uniqueString {String} |
	prots _ self selectedClass organization categories.
	uniqueString _ 'enter name'.
	menu _ PopUpMenu fromArray: 
		(Array with: (Array with: uniqueString)), 
		#(-),
		(prots collect: [:prot {Symbol} |
			Array with: prot]).
	newProtocol _ menu startUp.
	(newProtocol isNil or: [newProtocol = 0])
		ifTrue: [^nil].
	(newProtocol == uniqueString)
		ifTrue: [newProtocol _ self 
					prompt: 'Type destination protocol' 
					initially: LastProtocol.
				newProtocol isEmpty 
					ifTrue: [^nil]].
	LastProtocol _ newProtocol.
	^newProtocol!

printOutProtocol
	"Print out protocol."

	| stream |
	stream _ TextStream on: (String new: 1000).
	self selectedClass printOutCategory: protocol on: stream.
	self hardcopyStream: stream with: self selectedClass name!

protocolHistory

	ChangeLogModel openSimpleOn: ((self selectedClass organization listAtCategoryNamed: protocol "methodName")
		inject: (SortedCollection sortBlock: [ :a :b | a logPosition >= b logPosition])
		into: [ :records :sel |
			records addAll: (ChangeLog
				followAll: (ChangeRecord class: self selectedClass name asSymbol
					meta: meta
					selector: sel)
				from: ChangeLog logPosition
				backTo: ChangeLog start);
			yourself])
	label: 'History of ' , self selectedClass name , ' ' , protocol "methodName" asString storeString!

removeProtocol
	| selectors |
	self changeRequest ifFalse: [^self].
	protocol = nil ifTrue: [^nil].
	selectors _ self selectedClass organization listAtCategoryNamed: protocol.
	selectors isEmpty ifFalse: [(self confirm: 'Are you certain that you want to
remove all methods in this protocol?')
			ifFalse: [^self].
		selectors do: [:sel | self selectedClass removeSelector: sel]].
	self selectedClass organization removeCategory: protocol.
	self selectedClass reorganize.
	self newProtocolList: nil!

renameProtocol
	| aString newProtocol |
	self changeRequest ifFalse: [^VOID].
	protocol = nil ifTrue: [^VOID].
	aString _ self prompt: 'Enter new protocol name' initially: protocol.
	aString isEmpty ifTrue: [^VOID].
	newProtocol _ aString asSymbol.
	(self selectedClass organization renameCategory: protocol to: newProtocol)
		ifTrue: 
			[self selectedClass reorganize.
			self newProtocolList: newProtocol]!

spawnMethod
	BrowserView openMethodBrowserOn: self copyAsBrowser!

spawnProtocol
	BrowserView openProtocolBrowserOn: self copyAsBrowser! !

!CxxBrowser methodsFor: 'private: method'!

acceptMethod: aText from: aController 
	| newSelector |
	newSelector _ self selectedClass
				compile: aText
				classified: protocol
				notifying: aController.
	newSelector == nil ifTrue: [^false].
	newSelector == method 
		ifFalse: [self newMethodList: newSelector].
	^true!

{void} addMethod: methodName {Symbol}
	"This method is used to move methods be...why?"
	(file = nil or: [class = nil or: [protocol = nil]])
		ifTrue: [^nil].
	self changeRequest ifFalse: [^self].
	methodName isEmpty ifTrue: [^self].
	class classDescription organization classify: methodName under: protocol methodName.
	self newMethodList: methodName!

browseAssociations

	| assoc {Symbol} |
	assoc _ self fetchAssociationFromMethod: self compiledMethod.
	assoc ~~ nil
		ifTrue: [(AssociationRefsFilter make: assoc) browse: self fetchMethodRep]!

browseCallers
	
	(CallersFilter make: self fetchMethodRep) browse: self fetchMethodRep!

browseFieldsSet

	| names {Set of: String} |
	names _ self selectedClass instVarNamesTouchedBy: method.
	self browseFieldAssignments: [:aClass {Behavior} | 
		aClass instVarNames select: [:name {String} |
			names includes: name]]!

browseFieldsTouched

	| names {Set of: String} |
	names _ self selectedClass instVarNamesTouchedBy: method.
	self browseFieldReferences: [:aClass {Behavior} | 
		aClass instVarNames select: [:name {String} |
			names includes: name]]!

browseImplementors
	
	(ImplementorsFilter make: method) browse: self fetchMethodRep!

{NOWAIT} browseMessages

	| sels {Collection of: Symbol} |
	sels _ self fetchMessagesFromMethod: self compiledMethod.
	sels == nil
		ifTrue: [^VOID].
	sels size = 1
		ifTrue: [(ImplementorsFilter make: (sels at: 1)) browse: self fetchMethodRep]
		ifFalse: [(MultiImplementorsFilter make: sels) browse: self fetchMethodRep]!

{NOWAIT} browseOtherSenders

	| sels {Collection of: Symbol} |
	sels _ self fetchMessagesFromMethod: self compiledMethod.
	sels == nil
		ifTrue: [^VOID].
	sels size = 1
		ifTrue: [(SendersFilter make: (sels at: 1)) browse: self fetchMethodRep]
		ifFalse: [(MultiSendersFilter make: sels) browse: self fetchMethodRep]!

browsePolymorphs
	
	| rep {MethodRep} |
	rep _ MethodRep make: self selectedClass with: method.
	(GeneratePolymorphs make: rep) browse: rep!

browseSenders
	
	(SendersFilter make: method) browse: self fetchMethodRep!

{NOWAIT} cvsMethod

	| op {CVSOperator} |
	op _ CVSOperator fetchFromMenu.
	op ~~ nil ifTrue:
		[op cvsMethod: method in: self selectedClass]!

editFriends
	self changeRequest ifFalse: [^self].
	self textMode: #friends.!

{Association} fetchAssociationFromMethod: meth {CompiledCode}
	
	| assocs {Collection of: Association} 
	  menu {PopUpMenu} 
	  result {Symbol} |
	
	assocs _ meth allLiteralAssociations.
	(assocs isEmpty)
		ifTrue: [Transcript cr; show: 'No non-local vars used.'.
				^nil].
	assocs _ assocs asSortedCollection.
	menu _ PopUpMenu fromArray: 
		(assocs collect: [:assoc {Association} | 
			Array with: (assoc key contractTo: 40) with: assoc with: 'Xu: Browse all methods which refer to this Association literally']).
	result _ menu startUp.
	result = 0 
		ifTrue: [^nil]
		ifFalse: [^result].!

{Collection of: Symbol} fetchMessagesFromMethod: meth {CompiledCode}
	
	| messages {OrderedCollection of: Symbol} 
	  symbols {OrderedCollection of: Symbol} 
	  anyString {String}
	  menu {PopUpMenu} 
	  result {Symbol} |
	  
	messages _ meth messages asSortedCollection.
	symbols _ (meth literalSymbols select: [:msg |
		(messages includes: msg) not]) asSortedCollection.
	(messages isEmpty and: [symbols isEmpty])
		ifTrue: [Transcript cr; show: 'No messages sent.'.
				^nil].
	anyString _ 'any of ''em'.
	menu _ PopUpMenu fromArray: 
		(Array with: (Array with: anyString with: anyString with: 'Xu: Browse all methods that have the designated relationship to any of the selectors below')),
		#(-),
		(messages collect: [:msg | Array with: (msg contractTo: 40) with: msg with: 'Xu: Browse all methods that have the designated relationship with this selector']),
		#(-),
		(symbols collect: [:msg | Array with: (msg contractTo: 40) with: msg with: 'Xu: Browse all methods that have the designated relationship with this symbol']).
	result _ menu startUp.
	result = 0 
		ifTrue: [^nil].
	result == anyString
		ifTrue: [^messages, symbols]
		ifFalse: [^OrderedCollection with: result]!

fileOutMessage

	| fileName fileStream sel |
	method isKeyword
		ifTrue: [sel _ WriteStream on: (String new: 20).
				method keywords do: [:each | sel nextPutAll: (each copyFrom: 1 to: each size - 1)].
				sel _ sel contents]
		ifFalse: [sel _ method].
	fileName _ Filename request: 'File out on' initially: (self selectedClass name, '-', sel, '.st') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	self selectedClass
		fileOutMessage: method
		on: fileStream
		moveSource: false
		toFile: 0]
		valueNowOrOnUnwindDo: [fileStream close]!

methodHistory

	method == nil ifTrue: [^nil].
	ChangeLog browseHistoryOf: method in: self selectedClass backTo: ChangeLog start.!

{void} moveMethod
	|  newProtocol org  |
	self changeRequest ifFalse: [^VOID].
	protocol = nil ifTrue: [^VOID].
	method = nil ifTrue: [^VOID].
	newProtocol _ self pickAProtocol.
	newProtocol = nil ifTrue: [^VOID].
	(newProtocol includes: $>)
		ifTrue: [Transcript cr; show: 'Sorry, copy to class not implemented'.
				^VOID].
	newProtocol _ newProtocol asSymbol.
	org _ self selectedClass organization.
	(org categories includes: newProtocol)
		ifFalse: [org addCategory: newProtocol.
				self newProtocolList: protocol].
	org classify: method under: newProtocol.
	self selectedClass reorganize.
	self newProtocolList: protocol.!

printOutMessage
	"Print the method."
	
	| stream |
	stream _ TextStream on: (String new: 1000).
	self selectedClass printMethod: method on: stream.
	self hardcopyStream: stream with: self selectedClass name!

removeMethod
	protocol = nil ifTrue: [^nil].
	(self changeRequest and: [self confirm: 'Are you certain that you
want to remove this method?'])
		ifTrue: 
			[self selectedClass removeSelector: method.
			self newMethodList: nil.
			^true].
	^false! !

!CxxBrowser methodsFor: 'private: text'!

{BooleanVar} cxxHeader: newHeader
	| group |
	file = nil ifTrue: [^false].
	group _ self getOrMakeCurrentClassGroup.
	group ~= nil ifTrue: [file cxxHeader: newHeader in: pubPrivTest. ^ true].
	^ false!

flash

	browseController flash!

friends
	| tmp |
	file = nil ifTrue: [^nil].
	class = nil ifTrue: [^nil].
	tmp _ class friends.
	tmp = nil ifTrue: [^('/* friends for class ' , class className , ' */') asText].
	^tmp asText!

friends: newFriends {String}
	file = nil ifTrue: [^ VOID].
	class = nil ifTrue: [^ VOID].
	class friends: (newFriends isEmpty ifTrue: [nil] ifFalse: [newFriends]).!

{BooleanVar} hxxHeader: newHeader
	| group |
	file = nil ifTrue: [^false].
	group _ self getOrMakeCurrentClassGroup.
	group ~= nil ifTrue: [file hxxHeader: newHeader in: pubPrivTest. ^ true].
	^ false!

translatedFileText

	| trans {CxxFileTranslator} |
	file == nil 
		ifTrue: [^'' asText].
	trans _ myTranslatorClass fetchMolt: pubPrivTest with: file.
	trans == nil 
		ifTrue: [^'' asText].
	^trans translatedText.! !

!CxxBrowser methodsFor: 'tree stuff'!

fixOrganization
	| temp fStep |
	(CxxSystemOrganization isKindOf: CxxFileOrganizer) ifFalse: [
		temp _ CxxSystemOrganization fetch: 'xpp'.
		(temp = nil or: [(temp isKindOf: CxxFileOrganizer) not]) ifTrue: [self error: 'eeeek!!'].
		CxxSystemOrganization _ temp].
	"CxxSystemOrganization fixup"
	fStep _ CxxSystemOrganization fileList stepper.
	fStep forEach: [:afile | afile fixup]!

initTree
	tree _ CxxSystemOrganization tree.
	treeBrowser _ CxxOutlineBrowser new.
	treeBrowser editor: self.
	treeBrowser tree: tree accessor: (TreeAccessor
			isLeaf: #isLeaf
			children: #children
			name: #key)!

newValue
	
	self shouldNotImplement!

tree
	^ tree!

tree: aTree
	tree _ aTree!

treeBrowser
	treeBrowser = nil ifTrue: [self initTree].
	^ treeBrowser!

treeBrowser: atb
	treeBrowser _ atb.!

value
	file = nil ifTrue: [^ nil].
	^ file moduleName!

value: someValue 
	someValue == #file
		ifTrue: [self fileName: (self treeBrowser selected key)]
		ifFalse: [self newFileList: nil]! !

!CxxBrowser methodsFor: 'accessing'!

browseController
	^ browseController!

currentClass
	^ class!

currentFile
	^ file!

currentMethod
	^ method!

{OrderedCollection of: Symbol} currentPath

	^ self treeLocation turns!

currentProtocol
	^ protocol!

{String} requestString
	^self requestString: 'String to find'.!

{String} requestString: prompt
	LastStringSought = nil ifTrue: [LastStringSought _ ''].
	LastStringSought _ self prompt: prompt initially: LastStringSought.
	LastStringSought isEmpty ifTrue: [^''].
	^ LastStringSought!

{String} searchString
	^ LastStringSought!

{Void} searchString: newString {String}
	LastStringSought _ newString!

spawnEdits: aText from: aController
	| newController newBrowser | 
	newController _ aController copy.  "Copy gets the changes"
	aController cancel; controlTerminate.   "Cancel changes in spawning browser"
	(file == nil or: [class == nil or: [protocol == nil or: [method == nil]]]) ifTrue: 
		[aController flash. ^nil].
	newBrowser _ Browser new
		onClass: class classDescription;
		meta: meta;
		newProtocolList: protocol;
		newSelectorList: method.
	BrowserView openMethodBrowserOn: newBrowser
		withController: newController!

{CxxTreeLocation} treeLocation
	"the current location in the tree"
	
	| pTree {AssociationTreeWithParent} res {CxxTreeLocation} |
	
	res _ CxxTreeLocation make.
	pTree _ treeBrowser selected.
	[pTree ~~ nil] whileTrue: [
		res addFirst: pTree key.
		pTree _ pTree parent].
	^ res! !

!CxxBrowser methodsFor: 'protected:'!

{NOWAIT} browseFiltered: gen {GenerateMethods}

	MethodFilter browseFiltered: gen with: self fetchMethodRep.!

{CompiledCode} compiledMethod

	^self selectedClass compiledMethodAt: method!

{Browser} copyAsBrowser
	"Create a copy of my state as an instance of a System (not Cxx) Browser"
	
	| result {Browser} |
	result _ Browser new.
	result newClassList: class classDescription name.
	result meta: meta.
	result newSelectorList: method.
	result textMode: textMode.
	result normalize.
	^result.!

currentCommentHolder
	file == nil ifTrue: [^nil].
	class == nil 
		ifTrue: [^ self fetchCurrentClassGroup]
		ifFalse: [^class classDescription]!

{MethodRep} fetchMethodRep
	
	(self selectedClass == nil or: [method == nil])
		ifTrue: [^nil]
		ifFalse: [^MethodRep make: self selectedClass with: method]!

hardcopyStream: aStream

	| document dateTime |
	dateTime _ Time dateAndTimeNow.
	Cursor wait
		showWhile: 
			[document _ Document new.
			document doFooter: true
					  footerString: ('Xanadu Operating Company Proprietary   ---   ',
					  			   (dateTime at: 1) printString, ' at ', (dateTime at: 2) printString) 
					  doPageNumbers: true.
			document startParagraph.
			document addText: aStream contents asText.
			document close.
			document toPrinter]!

hardcopyStream: aStream with: title

	| document dateTime |
	dateTime _ Time dateAndTimeNow.
	Cursor wait
		showWhile: 
			[(aStream isKindOf: LabelledTextStream)
				ifTrue: [document _ IndexedDocument new]
				ifFalse: [document _ Document new].
			document doFooter: true
					  footerString: title asString, '        ',
					  				('Xanadu Operating Company Proprietary   ---   ',
					  			   (dateTime at: 1) printString, ' at ', (dateTime at: 2) printString)
					  doPageNumbers: true.
			document startParagraph.
			document addText: aStream contents asText.
			document close.
			document toPrinter]!

{Collection of: String} parseTextIntoList: aText {Text}

	^ aText asString asCollectionOfLines!

spawnCxxBrowser
	self copyAsBrowser spawnCxxBrowser!

spawnSystemBrowser
	BrowserView openOnBrowser: self copyAsBrowser! !

!CxxBrowser methodsFor: 'class functions'!

copyDeferredMethods
	
	self nonMetaClass copyDeferred.
	self changed: #className!

fileOutClassChanges

	| fileName fileStream |
	fileName _ Filename request: 'File out on' initially: (self nonMetaClass name, '.ch') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	ChangeLog fileOutChanges: self selectedClass name
		backTo: (ChangeLog baseline max: 0)
		onto: fileStream]
	valueNowOrOnUnwindDo: [fileStream close]!

printClass
	"Print the class."
	
	| stream |
	stream _ LabelledTextStream on: (String new: 1000).
	self nonMetaClass printOutOn: stream.
	self hardcopyStream: stream with: self nonMetaClass name! !

!CxxBrowser methodsFor: 'testing functions'!

{void} compareTestToReference

	| testFile {Filename} refFile {Filename} |
	file == nil ifTrue: [^VOID].
	testFile _ file fetchTestOutputPath.
	refFile _ file testReferencePath.
	refFile exists ifFalse: 
		[Transcript show: 'no reference file for ' , file moduleName; cr; endEntry.
		^VOID].
	(testFile == NULL or: [testFile exists]) ifFalse: 
		[Transcript show: 'no test output file for ' , file moduleName; cr; endEntry.
		^VOID].
	refFile contentsOfEntireFile = testFile contentsOfEntireFile
		ifTrue: [^'no difference']
		ifFalse: [Transcript show: 'differences in file ' , file moduleName; cr; endEntry.
			testFile differences: refFile]!

{void} makeOutputIntoReference

	| oRef {Filename} testOut {Filename} |
	(file == nil 
	 or: [(testOut _ file fetchTestOutputPath) == NULL
	 or: [testOut exists not]]) ifTrue: 
		[Transcript show: 'eep. nothing done...'; cr; endEntry.
		^VOID].
	oRef _ file testReferencePath.
	(ActionMenu confirm: '                 R U SURE?
 confirm "', testOut asString, '" will overwrite "', oRef asString, '"!! ')
		ifFalse: [^VOID].
	oRef exists ifTrue: 
		[oRef delete].
	testOut renameTo: oRef! !

!CxxBrowser methodsFor: 'smalltalk: passe'!

{void} destroyFile
	
	self passe. "use CxxOutlineBrowser>>destroyFile"!

{void} obsoleteRunTest
	
	self passe!

pubPrivTest
	
	self passe!

{void} runTest
	self passe!

scanForIncludes
	
	self passe! !

!CxxBrowser methodsFor: 'file private'!

bodyFileMode
	^(#(translatedFile typeRefs) includes: textMode) and: [myTranslatorClass = CxxBodyFile]!

fileMode
	^#(cxxHeader hxxHeader fileComment groupComment translatedFile typeRefs) 
		includes: textMode!

showTypeRefs: translatorClass {CxxFileTranslator class}

	self changeRequest ifFalse: [^self].
	self newClassList: nil. 
	myTranslatorClass _ translatorClass.
	self textMode: #typeRefs.! !

!CxxBrowser methodsFor: 'text private'!

{String} cxxHeader
	| group |
	file == nil ifTrue: [^''].
	group _ self getOrMakeCurrentClassGroup.
	group == nil ifTrue: [^ ''].
	^ group cxxHeader!

{String} hxxHeader
	| group |
	file == nil ifTrue: [^''].
	group _ self getOrMakeCurrentClassGroup.
	group == nil ifTrue: [^''].
	^ group hxxHeader!

typeRefText

	| trans {CxxFileTranslator} |
	file == nil 
		ifTrue: [^'' asText].
	trans _ myTranslatorClass fetchMolt: pubPrivTest with: file.
	trans == nil 
		ifTrue: [^'' asText].
	^trans typeRefText.! !

!CxxBrowser methodsFor: 'class private'!

{void} makePrivate
	class == nil ifTrue: [^VOID].
	class visibility == #private ifTrue: [^VOID].
	file removeClass: class in: class visibility.
	file addClass: class in: #private.
	self changed: #className.
	self switchOn: #private!

{void} makeProtected
	class == nil ifTrue: [^VOID].
	class visibility == #protected ifTrue: [^VOID].
	file removeClass: class in: class visibility.
	file addClass: class in: #protected.
	self changed: #className.
	self switchOn: #protected!

{void} makePublic
	class == nil ifTrue: [^VOID].
	class visibility == #public ifTrue: [^VOID].
	file removeClass: class in: class visibility.
	file addClass: class in: #public.
	self changed: #className.
	self switchOn: #public!

{void} makeTest
	class == nil ifTrue: [^VOID].
	class visibility == #test ifTrue: [^VOID].
	file removeClass: class in: class visibility.
	file addClass: class in: #test.
	self changed: #className.
	self switchOn: #test! !

!CxxBrowser methodsFor: 'private: public/private/test'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxBrowser class
	instanceVariableNames: ''!



!CxxBrowser class methodsFor: 'pseudo constructors'!

make
	CxxSystemOrganization == nil ifTrue: 
		[CxxSystemOrganization _ CxxFileOrganizer make].
	^self create: CxxSystemOrganization.! !

!CxxBrowser class methodsFor: 'string constants'! !