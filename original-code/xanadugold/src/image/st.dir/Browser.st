'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:54 pm'!

Model subclass: #Browser
	instanceVariableNames: '
		organization {SystemOrganizer}
		category {Symbol}
		className {Symbol}
		meta {Boolean}
		protocol {Symbol}
		selector {Symbol}
		searchMethod {Symbol}
		searchProtocol {Symbol}
		textMode {Symbol}'
	classVariableNames: '
		LastProtocol {Symbol} 
		LastStringSought {String} 
		MethodMoveProtocol {Symbol} 
		ShowMethodHistory {Boolean} '
	poolDictionaries: ''
	category: 'Tools-Browser'!
Browser comment:
'A browser represents a hierarchical query path through an organization of class and method information.  A full path query identifies a Smalltalk-80 method to be examined.

Instance Variables:
	organization <SystemOrganizer>
	category	 <String> a selection from all categories in the organization.
	className	 <Symbol> a selection from all classes in the category.
	meta 		<Boolean> false for viewing instance methods, true for class methods.
	protocol 	<Symbol> a selection from all protocols in the class.
	selector 	<Symbol> a selection from all messages in the protocol.
	textMode 	<Symbol> indicating the nature of the currently viewed text

Class Variables:
	CategoryMenu	<ActionMenu> of operations on the class categories
	ClassMenu		<ActionMenu> of operations and queries about a class
	LastProtocol	<Symbol> last message category selected
	MessageMenu	<ActionMenu> of operations on the message categories
	MethodMoveProtocol	<Symbol> last message category used in a move
	ProtocolMenu	<ActionMenu> of operations and queries about a message
	ShowMethodHistory	<Boolean> whether to show method history when no method selected
	TextMenu 		<ActionMenu> of text editing operations'!



!Browser methodsFor: 'initialize-release'!

create: aBrowser {Browser}

	super create.
	aBrowser copyAsBrowserInto: self!

on: anOrganizer
	"Set the receiver to be a browser on the system class organization anOrganizer."

	 organization _ anOrganizer.
	meta _ false!

onClass: aClass 
	"Set the receiver to be a browser on the class aClass, so that 
	therefore the organization is the system organizer."

	organization _ SystemOrganization.
	className _ aClass isMeta
				ifTrue: [aClass soleInstance name]
				ifFalse: [aClass name].
	meta _ aClass isMeta.
	self textMode: #classDefinition! !

!Browser methodsFor: 'category list'!

category
	"Answer the receiver's currently selected category."

	^ category!

category: selection 
	"Set the receiver's currently selected category to be selection and 
	update the class list."

	category = '**Hierarchy**' ifTrue: [^nil].
	category _ selection.
	selection isNil ifTrue: [self textMode: nil].
	self newClassList: className!

categoryList
	"Answer the sequenceable collection containing the class categories that 
	the receiver accesses."

	^organization categories collect: [ :each | self makeCategoryRep: each]!

categoryMenu
"This menu appears in SystemBrowser's category pane."

	^PopUpMenu matching: (PopUpMenu tags, (category == nil ifTrue: [#(nocat)] ifFalse: [#(categ)])) fromPrefixedArray: #(
		(categ		'file' (
			(categ		'file out changes'		fileOutCategoryChanges	'?: ?')
			(categ		'file out'				fileOutCategory				'ST: File out contents of this category')
			(categ		'print out'				printOutCategory			'ST?: Format for printer (and send to printer?)')))
		(categ		'spawn' (
			(categ		'system browser'	spawnSystemBrowser		'Xu: Create a new system browser positioned like this one.')
			-
			(categ		'category'				spawnCategory				'Xu: Create a new category browser on selected category.') ))
		(categ		'history'				categoryHistory			'Xu: Create a history browser on all changes in this category.')
		-
		(all			'update'				updateCategories		'ST: Recalculates display from underlying information, to bring browser into sync with real world.')
		(all			'edit all'				editCategories			'ST: Generate editable alternate representation of  category/class organization')
		-
		(categ		'find'					findInCategory			'Xu: Apply criteria from a FindMenu to all the methods in this category.')
		(long		'find in system'		findInSystem				'Xu: Apply criteria from a FindMenu to all the methods in the system.')
		(all			'locate class'			findClass					'ST: Prompt for class name, position browser so that class is visible')
		(all			'locate category'		findCategory				'Xu: Display categories in a hierarchical menu, treating "-" in name as tumbler "."')
		-
		(all			'add category'		addCategory				'ST: Create a new category and add it to the browser.')
		(nocat		'sort categories'		sortNewCategories		'ST?: Sort categories in browser into alphabetical order.')
		(categ		'rename'				renameCategory			'ST: Rename the currently selected category.')
		(categ		'remove'				removeCategory			'ST: Remove the currently selected category and all its classes from the image.') ).!

categoryRep
	"Answer a Rep for the receiver's currently selected category."

	^ category = nil ifTrue: [nil] ifFalse: [self makeCategoryRep: category]!

categoryRep: selection 
	"Set the receiver's currently selected category to be selection and 
	update the class list."

	category = '**Hierarchy**' ifTrue: [^nil].
	category _ selection == nil ifTrue: [nil] ifFalse: [selection asSymbol].
	selection isNil ifTrue: [self textMode: nil].
	self newClassList: className!

newCategoryList: initialSelection
	"Set the currently selected category to be initialSelection."

	category _ initialSelection.
	self changed: #category! !

!Browser methodsFor: 'category functions'!

addCategory
	"Prompt the user for a new category name. Insert the category into 
	the class organization before the currently selected category."

	| aString newCategory |
	self changeRequest ifFalse: [^self].
	aString _ self prompt: 'Enter new category name' initially: 'category name'.
	aString isEmpty ifTrue: [^self].
	newCategory _ aString asSymbol.
	organization addCategory: newCategory before: category.
	"Smalltalk changes reorganizeSystem." 
	self newCategoryList: newCategory!

categoryHistory

	category == nil ifTrue: [^nil].
	ChangeLog browseAny: (SystemOrganization listAtCategoryNamed: category)
		backTo: ChangeLog start.!

editCategories
	self changeRequest ifFalse: [^self].
	self textMode: #categories!

fileOutCategory

	| fileName aFileStream |
	fileName _ Filename request: 'File out on' initially: (category, '.st') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	aFileStream _ (Filename named: fileName) writeStream.
	[organization fileOutCategory: category on: aFileStream]
		valueNowOrOnUnwindDo: [aFileStream close]!

fileOutCategoryChanges

	self unimplemented.
	"| fileName aFileStream |
	fileName _ Filename request: 'File out on' initially: (category, '.ch') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	aFileStream _ (Filename named: fileName) writeStream.
	[ChangeLog fileOutChanges: (SystemOrganization listAtCategoryNamed: category)
		backTo: (ChangeLog baseline max: 0)
		onto: aFileStream]
	valueNowOrOnUnwindDo: [aFileStream close]"!

findCategory
	"Prompt for a category and position myself there."

	| testCategory |
	testCategory _ self pickACategory.
	testCategory == nil
		ifTrue: [^Transcript cr; show: 'Nobody'].
	self changeRequest ifFalse: [^self].
	self newCategoryList: testCategory!

findClass
	"Prompt for a class and position myself there."

	| testClass |
	testClass _ self pickAClass: 'Find class:'.
	testClass == nil
		ifTrue: [^Transcript cr; show: 'Nobody'].
	testClass isBehavior ifFalse: [testClass _ testClass class].
	testClass isMeta ifTrue: [testClass _ testClass soleInstance].
	self changeRequest ifFalse: [^self].
	self newCategoryList: testClass category.	
	self newClassList: testClass name.!

{NOWAIT} findInCategory

	self category == nil
		ifTrue: [^VOID].
	self browseFiltered: (FromCategory make: category with: organization)!

{void} findInSystem

	self browseFiltered: SourceMethods make!

{Symbol | nil} pickACategory
	"Choose a category with a menu."

	^FromCategory pickACategory!

{Symbol} pickACategory: prompt {String}
	"Choose a category with a prompter.  Bring up menu for wildcards."

	| destCatName {String} 
	  cats {OrderedCollection of: Symbol} |
	destCatName _ self requestString: prompt.
	destCatName = '' ifTrue: [^nil].
	(destCatName findString: '*' startingAt: 1) =0
		ifTrue: [^destCatName].
	Cursor execute showWhile:
		[cats _ SystemOrganization categories 
			select: [ :cn | destCatName match: cn]].
	^FromCategory pickFromCategoryMenu: cats.!

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

printOutCategory
		"Print the category."
	
	| stream |
	stream _ LabelledTextStream on: (String new: 1000).
	organization printOutCategory: category on: stream.
	self hardcopyStream: stream!

removeCategory
	| classes |
	self changeRequest ifFalse: [^self].
	classes _ organization superclassOrder: category.
	classes isEmpty ifFalse:
		[(self confirm: 'Are you certain that you want to
remove all classes in this category?') ifFalse: [^self].
		classes reverseDo: [:cls | cls removeFromSystem]].
	organization removeCategory: category.
	"Smalltalk changes reorganizeSystem." 
	self newCategoryList: nil!

renameCategory
	| aString newCategory |
	self changeRequest ifFalse: [^self].
	aString _ self prompt: 'Enter new category name' initially: category.
	aString isEmpty ifTrue: [^ self].
	newCategory _ aString asSymbol.
	(organization renameCategory: category to: newCategory)
		ifTrue:
			["Smalltalk changes reorganizeSystem."
			self newCategoryList: newCategory]!

spawnCategory
	BrowserView openCategoryBrowserOn: self copyAsBrowser!

updateCategories
	self changeRequest ifFalse: [^self].
	self newCategoryList: category! !

!Browser methodsFor: 'class list'!

classList
	"Answer the sequenceable collection containing the classes that 
	are accessed from the currently selected category."

	category == nil ifTrue: [^nil].
	category = '**Hierarchy**' ifTrue:
		[self selectedClass == nil
			ifTrue: ["Class is gone, probably was removed"
					^nil].
		^Browser  computeClassOrdering:
			((self selectedClass withAllSuperclasses reverse , self selectedClass allSubclasses)
				collect: [ :each | each name])].
	^Browser computeClassOrdering: (organization listAtCategoryNamed: category)!

classMenu

	className == nil ifTrue: [^nil].
	
	^PopUpMenu fromPrefixedArray: #(
		 (all	'file' (
		 	(all		'file out changes'		fileOutClassChanges	'')		"ST: browser - see cxx class menu"
			(all		'file out'				fileOutClass			'')
			(all		'print out'				printOutClass			'') ))
		(all		'spawn' (
			(all		'system browser'		spawnSystemBrowser	'')
			(all		'cxx browser'			spawnCxxBrowser		'')
			-
			(all		'category'				spawnCategory		'')
			(all		'class'					spawnClass				'')
			(all		'family'				spawnHierarchy		'') ))
		(all		'history'				classHistory			'')
		-
		(all		'aspects' (
			(all		'family'					showHierarchy			'')
			(all		'definition'				editClass				'')
			(all		'comment'				editComment			'')
			(all		'protocols'				editProtocols			'ST: Show (and allow editing of) the organization of methods into protocols.') ))
		-
		(all		'inst var' (
			(all		'references'			browseFieldReferences		'ST: Prompt with a menu of all instance variables.  Show all methods that reference the chosen variable.')
			(all		'assignments'		browseFieldAssignments		'ST: Prompt with a menu of all instance variables.  Show all methods that assign to the chosen variable.') ))
		(all		'class var refs'			browseClassVariables		'')
		(all		'class refs'				browseClassReferences		'')
		(long		'opaque refs'			browseOpaqueRefs		'Xu: Using the current state of the opaque scan info, find all X++ methods which use the selected class''s name as a token')
		-
		(all		'find'					findInClass					'')
		(all		'find in family'			findInFamily				'')
		(all		'locate method'			findMethodAndSelectAlphabetic '')
		-
		(all		'move'					moveClassToCategory		'ST: Prompt with a menu of all the categories.  Move the selected class to the chosen category.')
		(long		'move tree'				moveClassTreeToCategory	'ST: Prompt with a menu of all the categories.  Move the selected class (and all subclasses in this category) to the chosen category.')
		(all		'copy deferred'		copyDeferredMethods	'Xu: Copy into this class all methods defined in its superclass which self self subclassResponsibility')
		(all		'rename'				renameClass				'')
		(all		'remove'				removeClass				'') )!

className
	"Answer the receiver's currently selected class."

	^ className!

className: selection 
	"Set the receiver's currently selected class to be selection and 
	update the message category list. If this class no longer exists, 
	print a message to that effect in the system transcript, if it is open."

	selection = nil
		ifTrue: [className _ nil]
		ifFalse: 
			[| i |
			i _ 1.
			[(selection at: i) isSeparator]
				whileTrue: [i _ i + 1].
			className _ (i = 1
						ifTrue: [selection]
						ifFalse: [selection copyFrom: i to: selection size]) asSymbol].	
	"KeyNotFoundSignal is raised when the class name selected 
	in a browser is already removed in another browser."
	Dictionary keyNotFoundSignal
		handle: 
			[:ex | 
			Transcript cr; show: 'class ' , className , ' no longer exists.'.
			ex return]
		do: 
			[| spro smeth |
			className ~~ nil ifTrue:
				[spro _ self selectedClass organization getCategoryOfElement: searchMethod.
				spro ~~ #'As yet unclassified' ifTrue: [searchProtocol _ spro]].
			spro _ searchProtocol.
			smeth _ searchMethod.
			self newProtocolList: searchProtocol.
			searchProtocol _ spro.
			searchMethod _ smeth.
			selection isNil & category notNil
				ifTrue: [self textMode: #classDefinition]
				ifFalse: [self classMode ifTrue: [self changed: #text]]]!

classRep
	"Answer a representation for the receiver's currently selected class."

	^className = nil ifFalse: [Browser makeClassRep: self nonMetaClass]!

classRep: rep
	"Answer a representation for the receiver's currently selected class."

	self className: (rep = nil ifFalse: [rep className])!

newClassList: initialSelection
	"Set the currently selected class to be initialSelection."

	className _ initialSelection.
	self changed: #className!

{Behavior} selectedClass
	"Answer the class object that is currently selected."

	className == nil ifTrue: [^ nil].
	meta
		ifTrue: [^ (Smalltalk at: className ifAbsent: [^ className _ nil]) class]
		ifFalse: [^ Smalltalk at: className ifAbsent: [^ className _ nil]]! !

!Browser methodsFor: 'class functions'!

acceptClass: aText from: aController 

	| oldClass class name |
	oldClass _ className == nil ifTrue: [Object] ifFalse: [self selectedClass].
	class _ oldClass subclassDefinerClass
				evaluate: aText string
				notifying: aController
				logged: false.
	class isBehavior ifFalse: [^ false].
	name _ class getClassName.
	self newClassList: name asSymbol.
	^true!

{NOWAIT} browseClassReferences
	
	(ClassRefsFilter make: self nonMetaClass) browse: self fetchMethodRep!

browseClassVariables
	"Show a menu of all class variables of the currently selected class  
	and its superclasses.  Browse all methods which refer to the variable selected."

	| nm {Symbol | nil} |
	nm := ClassVarRefs pickAClassVariableOf: self nonMetaClass.
	nm == nil 
		ifTrue: [^VOID].
	(ClassVarRefs make: self nonMetaClass with: nm) browse: self fetchMethodRep!

browseFieldAssignments
	"Show a menu of all instance variables of the currently selected class  
	and its superclasses.  Browse all methods which assign to the variable selected."

	self browseFieldAssignments: [:aClass | aClass instVarNames]!

browseFieldAssignments: generatorBlock
	"Show a menu of all instance variables of the currently selected class  
	and its superclasses.  Browse all methods which refer to the variable selected."
	| name |
	name _ InstVarRefs pickAnInstVariableOf: self selectedClass with: generatorBlock.
	name isNil 
		ifTrue: [^VOID].
	(InstVarAssignments make: self selectedClass with: name) browse: self fetchMethodRep!

browseFieldReferences
	"Show a menu of all instance variables of the currently selected class  
	and its superclasses.  Browse all methods which refer to the variable selected."

	self browseFieldReferences: [:aClass | aClass instVarNames]!

{NOWAIT} browseFieldReferences: generatorBlock
	"Show a menu of all instance variables of the currently selected class  
	and its superclasses.  Browse all methods which refer to the variable selected."

	| name |
	name _ InstVarRefs pickAnInstVariableOf: self selectedClass with: generatorBlock.
	name isNil 
		ifTrue: [^VOID].
	(InstVarRefs make: self selectedClass with: name) browse: self fetchMethodRep!

{FamilyBrowser} browseHierarchy

	"I am a copy; put me in the right state to browse a hierarchy"
	category _ '**Hierarchy**'.
	^FamilyBrowser create: self!

{NOWAIT} browseOpaqueRefs
	
	(OpaqueReferences make: self nonMetaClass) browse: self fetchMethodRep!

classHistory

	self selectedClass == nil ifTrue: [^nil].
	ChangeLog browseHistoryOf: self selectedClass backTo: ChangeLog start.!

classMode
	^#(classDefinition hierarchy comment protocols instVarTypes) includes: textMode!

copyDeferredMethods
	
	self nonMetaClass copyDeferred.
	self changed: #className!

editClass
	self changeRequest ifFalse: [^self].
	self textMode: #classDefinition.
	self newProtocolList: nil!

editComment
	self changeRequest ifFalse: [^self].
	self textMode: #comment.
	self newProtocolList: nil!

editProtocols
	self changeRequest ifFalse: [^self].
	self textMode: #protocols.
	self newProtocolList: nil!

fileOutClass

	| fileName fileStream |
	fileName _ Filename request: 'File out on' initially: (self nonMetaClass name, '.st') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	self nonMetaClass fileOutOn: fileStream.]
		valueNowOrOnUnwindDo: [fileStream close]!

fileOutClassChanges

	| fileName fileStream |
	fileName _ Filename request: 'File out on' initially: (self nonMetaClass name, '.ch') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	ChangeLog fileOutChanges: className
		backTo: (ChangeLog baseline max: 0)
		onto: fileStream]
	valueNowOrOnUnwindDo: [fileStream close]!

{NOWAIT} findInClass

	self selectedClass == nil ifTrue: [^VOID].
	self browseFiltered: (FromClass make: self selectedClass nonMeta)!

{NOWAIT} findInFamily

	self selectedClass == nil ifTrue: [^VOID].
	self browseFiltered: (FromFamily make: self selectedClass nonMeta)!

findMethodAndSelectAlphabetic
	"Show a menu of the methods implemented by this class.  Select the chosen one."

	| chosenSelector {Symbol} 
	  selectors {OrderedCollecion of: Symbol} |
	  
	selectors _ self selectedClass organization elements asSortedCollection.
	(selectors size = 0)
		ifTrue: [^VOID].
	chosenSelector _ (PopUpMenu fromArray: (selectors collect: [:sel {Symbol} |
		Array with: sel])) startUp.
	chosenSelector = 0
		ifTrue: [^VOID].
	self newProtocolList: (self selectedClass whichCategoryIncludesSelector: chosenSelector).
	self newSelectorList: chosenSelector!

{void} moveClassToCategory
	| cat {Symbol} |
	cat _ self pickACategory.
	cat = nil ifTrue: [^VOID].
	self nonMetaClass category: cat.
	self updateCategories.!

{void} moveClassTreeToCategory
	| cat {Symbol} classTree {Collection of: Class} |
	cat _ self pickACategory.
	cat = nil ifTrue: [^VOID].
	Cursor execute showWhile: 
		[classTree _ OrderedCollection new.
		self classList do: [:cRep {ClassRep} | 
			| c {Class} |
			c _ Smalltalk at: cRep className.
			(c inheritsFrom: self nonMetaClass)
				ifTrue: [classTree add: c]].
		classTree add: self nonMetaClass.
		classTree do: [:cls {Class} | cls category: cat].
		self updateCategories].!

nonMetaClass
	"Answer the class that is currently selected (nil of none), even
	if looking at the metaClass."
	| classOrNil |
	classOrNil _ self selectedClass.
	(meta == true and: [classOrNil ~~ nil])
		ifTrue: [classOrNil _ classOrNil soleInstance].
	^classOrNil!

printOutClass
	"Print the class."
	
	| stream |
	stream _ LabelledTextStream on: (String new: 1000).
	self nonMetaClass printOutOn: stream.
	self hardcopyStream: stream with: self nonMetaClass name!

promptClass
	self newClassList: nil.
	self textMode: #classDefinition!

removeClass
	| class |
	self changeRequest ifFalse: [^self].
	"KeyNotFoundSignal is raised when the class name to be 
	removed 
	in a browser is already removed in another browser."
	Dictionary keyNotFoundSignal handle: [:ex | Transcript cr; show: 'can''t remove the class. class ' , className , ' no longer exists.'.
		ex return]
		do: [| request |
			class _ self nonMetaClass.
			(class fetchCxxClassDescription == nil 
				or: [class fetchCxxClassDescription fetchCxxModule == nil])
				ifTrue: [request _ 'Are you certain that you
want to destroy the class ' , class name , '?']
				ifFalse: [request _ 'Are you sure that you want to destroy
the CXX class ' , class name , ' from ' , class fetchCxxClassDescription fetchModuleName , '??'].
			(self confirm: request) ifTrue: 
				[| cxxCd fd |
				class subclasses size > 0 ifTrue: 
					[self notify: class name , ' has subclasses'. ^VOID].
				(cxxCd _ class fetchCxxClassDescription) ~~ nil ifTrue:
					[(fd _ cxxCd fetchCxxModule) == nil
						ifFalse: [fd removeClass: cxxCd in: cxxCd visibility].
					cxxCd organization cxxClassDescription: nil].
				class removeFromSystem.
				self newClassList: nil]]!

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
			self newClassList: newName.
			Transcript cr; show: 'Searching for references to this class...'.
			(ClassRefsFilter make: self nonMetaClass with: oldName) browse: self fetchMethodRep]!

showHierarchy
	self changeRequest ifFalse: [^self].
	self textMode: #hierarchy.
	self newProtocolList: nil!

showMethods
	BrowserView openMethodBrowserOn: self copyAsBrowser!

spawnClass
	
	BrowserView openClassBrowserOn: self copyAsBrowser!

spawnHierarchy

	BrowserView openFamilyBrowserOn: self copyAsBrowser browseHierarchy! !

!Browser methodsFor: 'class/inst switch'!

meta
	"Answer true if class protocols is selected, false for the instance protocols."

	^ meta!

meta: aBoolean 
	"Set the flag to indicate which protocols are to be selected, false 
	for instance and true for class."

	self changeRequest ifFalse: [^self changed: #meta].
	meta _ aBoolean.
	self changed: #meta.
	self newProtocolList: protocol.
	self classMode ifTrue: [self changed: #text]! !

!Browser methodsFor: 'protocol list'!

newProtocolList: initialSelection
	"Set the currently selected message category to be initialSelection."

	searchProtocol _ protocol _ initialSelection.
	self changed: #protocol!

protocol
	"Answer the receiver's currently selected message category."

	^ protocol!

protocol: selection
	"Set the receiver's currently selected message category to be selection and 
	update the message selector list."

	selection == nil
		ifTrue: 
			[protocol _ selector _ nil.
			(className ~~ nil and: [textMode == #methodDefinition]) ifTrue: [self textMode: #classDefinition]]
		ifFalse: 
			[protocol _ selection printString asSymbol.
			LastProtocol _ protocol].
	searchProtocol _ protocol.
	self newSelectorList: searchMethod!

protocolList
	"Answer the sequenceable collection containing the message categories that 
	the receiver accesses from the currently selected class."

	className == nil ifTrue: [^ nil].
	^ self selectedClass organization categories collect: [ :each | self makeProtocolRep: each]!

protocolMenu
	"Menus for protocol pane of all SystemIsh browsers."

	protocol == nil ifTrue:			"Menu used when no protocol is selected."
		[^PopUpMenu fromArray: #(
			('add protocol'	addProtocol					'ST: Add a new protocol.') )].
		
	^PopUpMenu fromArray: #(		"Menu used when a protocol is selected."
		('file' (
			('file out'		fileOutProtocol				'ST: File out all methods in the protocol.')
			('print out'		printOutProtocol			'ST: Format all methods in the protocol (and print them?)') ))
		('spawn' ( 
			('system browser' spawnSystemBrowser	'Xu: Create a new SystemBrowser positioned like this browser.')
			('cxx browser'	spawnCxxBrowser			'Xu: Create a new CxxBrowser positioned like this browser, if possible.')
			-
			('category'		spawnCategory			'Xu: Create a new CategoryBrowser on the selected category positioned like this browser.')
			('class'			spawnClass					'Xu: Create a new ClassBrowser on the selected class, positioned like this browser.')
			('family'			spawnHierarchy			'Xu: Create a FamilyBrowser which contains the selected class, its superclasses, and its subclasses.')
			('protocol'		spawnProtocol				'Xu: Create a ProtocolBrowser on the selected protocol.') ))
		('history'		protocolHistory				'Xu: Create a HistoryBrowser on all methods in this protocol.')
		-
		('find'			findInProtocol				'Xu: Apply criteria from a FindMenu to all the methods in this protocol.')
		-
		('add protocol'	addProtocol					'ST: Add a new protocol.')
		('rename' renameProtocol					'ST: Rename the currently selected protocol.')
		('remove' removeProtocol					'ST: Remove the currently selected protocol and all its messages from the image.')).!

protocolRep
	"Answer the receiver's currently selected message category."

	^ protocol == nil ifTrue: [nil] ifFalse: [self makeProtocolRep: protocol]!

protocolRep: selection 
	"Set the receiver's currently selected message category to be 
	selection and update the message selector list."

	selection == nil
		ifTrue: 
			[protocol _ selector _ nil.
			(className ~~ nil and: [textMode == #methodDefinition]) ifTrue: [self textMode: #classDefinition]]
		ifFalse: 
			[protocol _ selection asSymbol.
			LastProtocol _ protocol].
	searchProtocol _ protocol.
	self newSelectorList: searchMethod! !

!Browser methodsFor: 'protocol functions'!

addProtocol
	| aString newProtocol |
	self changeRequest ifFalse: [^self].
	aString _ self 
			prompt: 'Enter new protocol name'
			initially: (LastProtocol == nil ifTrue: ['protocol name'] ifFalse: [LastProtocol]).
	aString isEmpty ifTrue: [^ self].
	newProtocol _ aString asSymbol.
	self selectedClass organization addCategory: newProtocol before: protocol.
	self selectedClass reorganize.
	self newProtocolList: newProtocol!

fileOutProtocol
	|fileName fileStream|
	fileName _ Filename request: 'File out on' initially: (self selectedClass name, '-', protocol, '.st') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	self selectedClass fileOutCategory: protocol
		on: fileStream
		moveSource: false
		toFile: 0]
		valueNowOrOnUnwindDo: [fileStream close]!

{NOWAIT} findInProtocol

	self protocol == nil
		ifTrue: [^VOID].
	self browseFiltered: (FromProtocol make: self selectedClass with: protocol)!

printOutProtocol
	"Print out protocol."

	| stream |
	stream _ TextStream on: (String new: 1000).
	self selectedClass printOutCategory: protocol on: stream.
	self hardcopyStream: stream with: self selectedClass name!

protocolHistory

	ChangeLogModel openSimpleOn: ((self selectedClass organization listAtCategoryNamed: protocol)
		inject: (SortedCollection sortBlock: [ :a :b | a logPosition >= b logPosition])
		into: [ :records :sel |
			records addAll: (ChangeLog
				followAll: (ChangeRecord class: className asSymbol
					meta: meta
					selector: sel)
				from: ChangeLog logPosition
				backTo: ChangeLog start);
			yourself])
	label: 'History of ' , self selectedClass name , ' ' , protocol asString storeString!

removeProtocol
	| selectors |
	self changeRequest ifFalse: [^self].
	selectors _ self selectedClass organization listAtCategoryNamed: protocol.
	selectors isEmpty ifFalse:
		[(self confirm: 'Are you certain that you want to
remove all methods in this protocol?') ifFalse: [^self].
		selectors do: [:sel | self selectedClass removeSelector: sel]].
	self selectedClass organization removeCategory: protocol.
	self selectedClass reorganize.
	self newProtocolList: nil!

renameProtocol
	| aString newProtocol |
	self changeRequest ifFalse: [^self].
	aString _ self prompt: 'Enter new protocol name' initially: protocol.
	aString isEmpty ifTrue: [^ self].
	newProtocol _ aString asSymbol.
	(self selectedClass organization renameCategory: protocol to: newProtocol)
		ifTrue:
			[self selectedClass reorganize.
			self newProtocolList: newProtocol]!

spawnProtocol
	BrowserView openProtocolBrowserOn: self copyAsBrowser! !

!Browser methodsFor: 'selector list'!

newSelectorList: initialSelection
	"Set the currently selected message selector to be initialSelection."

	searchMethod _ selector _ initialSelection.
	self changed: #selector!

selector
	"Answer the receiver's currently selected message selector."

	^ selector!

selector: selection 
	"Set the receiver's currently selected message selector to be 
	selection. If the selection has been separately removed from the 
	system, then print a message to that effect in the system 
	transcript, if it is open."

	searchMethod _ selector _ selection ~~ nil ifTrue: [selection asSymbol].
	(selection == nil and: [protocol == nil]) ifTrue: [^self].
	Dictionary keyNotFoundSignal
		handle: 
			[:ex | 
			Transcript cr; show: 'selector ' , selector , ' no longer exists.'.
			self textMode: #unclassified.
			ex return]
		do: ["KeyNotFoundSignal is raised when the selector name selected 
			  in a browser is already removed in another browser."
			self textMode: #methodDefinition]!

{void} selectorChangedInPlace: newSelector {Symbol}
	"Set the currently selected message selector to be initialSelection."

	self newSelectorList: newSelector!

selectorList
	"Answer the sequenceable collection containing the message selectors that 
	the receiver accesses via the currently selected class and message category."

	protocol == nil ifTrue: [^ nil].
	^ (self selectedClass organization listAtCategoryNamed: protocol)
		collect: [ :each | self makeSelectorRep: each]!

selectorMenu
	"Menu for method pane of SystemIsh browsers."
	
	| tags |
	selector == nil ifTrue: [^ nil].
	
	tags _ PopUpMenu tags, (meta ifTrue: [#(caller)] ifFalse: [#(impl)]).
	(meta and: [PopUpMenu shortForm not])
		ifTrue: [tags _ tags, #(impl)].
		
	^PopUpMenu matching: tags fromPrefixedArray: #(
		(all		'file' (
			(all		'file out'			fileOutMessage			'ST: File out contents of this method')
			(all		'print out'			printOutMessage			'ST?: Format for printer (and send to printer?)') ))
		(all		'spawn' ( 
			(all		'system browser'	spawnSystemBrowser	'Xu: Create a SystemBrowser positioned like this one.')
			(all		'cxx browser'		spawnCxxBrowser		'Xu: Create a CxxBrowser positioned like this one, if possible.')
			-
			(all		'category'			spawnCategory			'Xu: Create a CategoryBrowser on selected category, positioned like this one.')
			(all		'class'				spawnClass				'Xu: Create a ClassBrowser on selected class, positioned like this one.')
			(all		'family'			spawnHierarchy			'Xu: Create a FamilyBrowser which contains the selected class, its superclasses, and its subclasses.')
			(all		'protocol'			spawnProtocol			'Xu: Create a ProtocolBrowser on the selected protocol.')
			(all		'method'			spawnMethod				'Xu: Create a MethodBrowser on the selected method.') ))
		(all		'history'				methodHistory			'Xu: Create a HistoryBrowser on the selected method.')
		-
		(all		'senders'				browseSenders			'ST: Create a browser on all methods which send the selected message.')
		(caller	'callers'				browseCallers			'Xu: Create a browser on all those that send this message directly to this class')
		(impl	'implementors'		browseImplementors		'ST: Create a browser on all methods which implement the selected message.')
		(impl	'polymorphs'			browsePolymorphs		'Xu: Create a browser on all methods which are C++ polymorphic with the selected message.')
		(long	'messages'			browseMessages			'ST: Prompt with a menu of the messages sent by this method.  Create a browser on all implementors of the chosen message.')
		-
		(all		'move'					moveMethod				'Xu: Prompt with a menu of the protocols.  Move this method to the chosen protocol.')
		(all		'remove'				removeMethod			'ST: Remove the currently selected method from the image.') )!

selectorRep
	"Answer the receiver's currently selected message selector."

	^ selector = nil ifTrue: [nil] ifFalse: [self makeSelectorRep: selector]!

selectorRep: selection 
	"Set the receiver's currently selected message selector to be 
	selection. If the selection has been separately removed from the 
	system, then print a message to that effect in the system 
	transcript, if it is open."

	searchMethod _ selector _ selection ~~ nil ifTrue: [selection asSymbol].
	(selection == nil and: [protocol == nil]) ifTrue: [^self].
	Dictionary keyNotFoundSignal
		handle: 
			[:ex | 
			Transcript cr; show: 'selector ' , selector , ' no longer exists.'.
			self textMode: #unclassified.
			ex return]
		do: ["KeyNotFoundSignal is raised when the selector name 
			selected in a browser is already removed in another browser."
			self textMode: #methodDefinition]! !

!Browser methodsFor: 'selector functions'!

acceptMethod: aText from: aController
	| newSelector |
	newSelector _ self selectedClass
				compile: aText
				classified: protocol
				notifying: aController.
	newSelector == nil ifTrue: [^false].
	newSelector == selector
		ifFalse: [self selectorChangedInPlace: newSelector].
	^true!

browseAssociations

	| assoc {Symbol} |
	assoc _ self fetchAssociationFromMethod: self compiledMethod.
	assoc ~~ nil
		ifTrue: [(AssociationRefsFilter make: assoc) browse: self fetchMethodRep]!

browseCallers
	
	(CallersFilter make: self fetchMethodRep) browse: self fetchMethodRep!

browseFieldsSet

	| names {Set of: String} |
	names _ self selectedClass instVarNamesTouchedBy: selector.
	self browseFieldAssignments: [:aClass {Behavior} | 
		aClass instVarNames select: [:name {String} |
			names includes: name]]!

browseFieldsTouched

	| names {Set of: String} |
	names _ self selectedClass instVarNamesTouchedBy: selector.
	self browseFieldReferences: [:aClass {Behavior} | 
		aClass instVarNames select: [:name {String} |
			names includes: name]]!

browseImplementors

	(ImplementorsFilter make: selector) browse: self fetchMethodRep!

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
	rep _ MethodRep make: self selectedClass with: selector.
	(GeneratePolymorphs make: rep) browse: rep!

browseSenders
	
	(SendersFilter make: selector) browse: self fetchMethodRep!

fileOutMessage

	| fileName fileStream sel |
	selector isKeyword
		ifTrue: [sel _ WriteStream on: (String new: 20).
				selector keywords do: [:each | sel nextPutAll: (each copyFrom: 1 to: each size - 1)].
				sel _ sel contents]
		ifFalse: [sel _ selector].
	fileName _ Filename request: 'File out on' initially: (self selectedClass name, '-', sel, '.st') shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	self selectedClass
		fileOutMessage: selector
		on: fileStream
		moveSource: false
		toFile: 0]
		valueNowOrOnUnwindDo: [fileStream close]!

methodHistory

	selector == nil ifTrue: [^nil].
	ChangeLog browseHistoryOf: selector in: self selectedClass backTo: ChangeLog start.!

moveMethod
	| newProtocol {String}
	  classPart {String}
	  destClass {ClassDescription}
	  protStart {IntegerVar}
	  moved {BooleanVar}
	  destClassName {String} |
	  
	self changeRequest ifFalse: [^VOID].
	protocol = nil ifTrue: [^VOID].
	selector = nil ifTrue: [^VOID].
	newProtocol _ self pickAProtocol.
	newProtocol = nil ifTrue: [^VOID].
	moved _ false.
	(newProtocol includes: $>)
		ifTrue: 
			["copy to another class"
			classPart _ newProtocol copyUpTo: $>.
			destClassName _ classPart copyUpTo: Character space.
			destClass _ Smalltalk at: destClassName asSymbol ifAbsent: [nil].
			destClass isBehavior
				ifFalse: [(Display flash: Display boundingBox). ^nil].
			classPart size = destClassName size
				ifFalse:
					[(classPart size-destClassName size = 6
						and: [(classPart copyFrom: classPart size - 5 to: classPart size) = ' class'])
								ifTrue: [destClass _ destClass class]
								ifFalse: [(Display flash: Display boundingBox). ^nil]].
			protStart _ classPart size + 2.
			[(newProtocol at: protStart) = $ ]
				whileTrue: [protStart _ protStart + 1].
			newProtocol _ (newProtocol copyFrom: protStart to: newProtocol size) asSymbol.
			destClass == self selectedClass
				ifFalse:
					[moved _ true.
					destClass compile: self text classified: newProtocol notifying: nil]]
		ifFalse: 
			["move within this class"
			destClass _ self selectedClass.
			newProtocol _ newProtocol asSymbol].
	moved 
		ifFalse: 
			[(destClass organization categories includes: newProtocol)
				ifFalse: 
					[destClass organization addCategory: newProtocol.
					self newProtocolList: protocol].
			destClass organization classify: selector under: newProtocol.
			destClass reorganize].
	self newSelectorList: selector!

printOutMessage
	"Print the method."
	
	| stream |
	stream _ TextStream on: (String new: 1000).
	self selectedClass printMethod: selector on: stream.
	self hardcopyStream: stream with: self selectedClass name!

{BooleanVar} removeMethod

	(self changeRequest and: [self confirm: 'Are you certain that you
want to remove this method?'])
		ifTrue: [self removeMethodSilently.
				^true].
	^false!

{void} removeMethodSilently

	self selectedClass removeSelector: selector.
	self newSelectorList: nil!

spawnEdits: aText from: aController
	| newController newBrowser | 
	newController _ aController copy.  "Copy gets the changes"
	newBrowser _ self copyAsBrowser.
	aController cancel; controlTerminate.   "Cancel changes in spawning browser"
	category == nil ifTrue: 
		[BrowserView openOn: newBrowser withController: newController].
	className == nil ifTrue: 
		[BrowserView openCategoryBrowserOn: newBrowser withController: newController].
	protocol == nil ifTrue: 
		[BrowserView openClassBrowserOn: newBrowser withController: newController].
	selector == nil ifTrue: 
		[BrowserView openProtocolBrowserOn: newBrowser withController: newController].
	BrowserView openMethodBrowserOn: newBrowser withController: newController!

spawnMethod
	BrowserView openMethodBrowserOn: self copyAsBrowser! !

!Browser methodsFor: 'text'!

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
	| text   |

	textMode == #instVarTypes ifTrue: [^(Smalltalk at: className) getOrMakeCxxClassDescription instVarTypeString asText].
	textMode == #classDefinition ifTrue: [className == nil
			ifTrue: [^(Class template: category) asText]
			ifFalse: [^self selectedClass definitionWithCommentAndAttributes asText]].
	textMode == #methodDefinition ifTrue: [selector == nil
			ifTrue: [Sensor leftShiftDown
				ifFalse: [^self methodHistorySummary]
				ifTrue: [^self selectedClass sourceCodeTemplate asText]]
			ifFalse: [^self selectedClass ~~ nil ifTrue:
				[(self selectedClass sourceCodeAt: selector) asText makeSelectorBoldIn: self selectedClass]]].
	textMode == #category ifTrue: [^'category to add' asText].
	textMode == #categories ifTrue: [^organization printString asText].
	textMode == #protocol ifTrue: [^'protocol to add' asText].
	textMode == #protocols ifTrue: [^self selectedClass organization printString asText].
	textMode == #comment
		ifTrue: 
			[text _ self selectedClass comment asText.
			text isEmpty ifFalse: [^text].
			self selectedClass isMeta ifTrue: [^'Select the browser switch "instance" to see the comment' asText].
			^'This class has no comment' asText].
	textMode == #hierarchy ifTrue: [^self selectedClass printHierarchy asText].
	^Text new!

textMenu
	^PopUpMenu standardCodeMenu!

textMode: aSymbol 
	"Set the mode for which text to display to be aSymbol, and then 
	announce that the receiver has changed."

	textMode _ aSymbol.
	self changed: #text! !

!Browser methodsFor: 'searching'! !

!Browser methodsFor: 'doIt/accept/explain'!

acceptText: aText from: aController 
	textMode == #classDefinition ifTrue: [^self acceptClass: aText from: aController].
	textMode == #methodDefinition ifTrue: [^self acceptMethod: aText from: aController].

	textMode == #categories ifTrue: 
			[organization changeFromString: aText string.
			self newCategoryList: category.
			^true].
	textMode == #protocols ifTrue: 
			[self selectedClass organization changeFromString: aText string.
			self selectedClass reorganize.
			self textMode: #protocol; newProtocolList: nil.
			^true].
	textMode == #comment ifTrue: 
			[self selectedClass comment: aText string.
			self textMode: #comment; newProtocolList: nil.
			^true].
	textMode == #hierarchy ifTrue: [aController flash].
	^false
"	textMode == #friends ifTrue: [^(Smalltalk at: className) friends: aText string notifying: aController].
	textMode == #cxxHeader ifTrue: [(Smalltalk at: className) cxxHeader: aText string. ^true].
	textMode == #hxxHeader ifTrue: [(Smalltalk at: className) hxxHeader: aText string. ^true].
"!

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

	textMode == #hierarchy
		ifTrue: 
			["Instance variables in subclasses"
			classes _ self selectedClass allSubclasses.
			classes _ classes detect: [:each | (each instVarNames
						detect: [:name | name = string] ifNone: []) ~~ nil]
					ifNone: [^nil].
			classes _ classes printString.
			^'"is an instance variable in class ' , classes , '."
' , classes , ' browseAllAccessesTo: ''' , string , '''.'].
	^nil! !

!Browser methodsFor: 'protected:'!

{NOWAIT} browseFiltered: gen {GenerateMethods}

	MethodFilter browseFiltered: gen with: self fetchMethodRep.!

{CompiledCode} compiledMethod

	^self selectedClass compiledMethodAt: selector!

{Browser} copyAsBrowser
	"The various Browser spawn methods used to open a new BrowserView on 'self copy'.
	This was broken, because if you want to spawn a normal browser from a Debugger,
	you don't want to copy all the wierd debugger state.  Instead, by using 'copyAsBrowser',
	browser and its subclasses can have a nice normalized *instance* of Browser"
	
	| result {Browser} |
	result _ Browser new.
	self copyAsBrowserInto: result.
	^result!

{void} copyAsBrowserInto: aBrowser {Browser}
	"See Browse>>copyAsBrowser"
	
	self normalize.
	aBrowser on: organization.
	aBrowser newCategoryList: category.
	aBrowser newClassList: className.
	aBrowser meta: meta.
	aBrowser newProtocolList: protocol.
	aBrowser newSelectorList: selector.
	aBrowser textMode: textMode.!

{MethodRep} fetchMethodRep
	
	(self selectedClass == nil or: [selector == nil])
		ifTrue: [^nil]
		ifFalse: [^MethodRep make: self selectedClass with: selector]!

hardcopyStream: aStream

	| document dateTime |
	dateTime _ Time dateAndTimeNow.
	Cursor wait
		showWhile: 
			[document _ IndexedDocument new.
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
			[document _ IndexedDocument new.
			document doFooter: true
					  footerString: title asString, '        ',
					  				('Xanadu Operating Company Proprietary   ---   ',
					  			   (dateTime at: 1) printString, ' at ', (dateTime at: 2) printString)
		doPageNumbers: true.
			document startParagraph.
			document addText: aStream contents asText.
			document close.
			document toPrinter]!

makeCategoryRep: aSymbol

	^ ClassRep
		create: aSymbol
		with: (ChangeLog hasChangesIn: aSymbol)
		with: 0!

makeClassRep: class with: indent
	class == nil ifTrue: [^ nil].
	^ClassRep
		create: class name
		with: (ChangeLog hasChangesFor: class) 
		with: indent!

makeMethodRep: sel
	^ ClassRep create: sel
		with: (ChangeLog hasChangesFor: sel
			in: self selectedClass)
		with: 0!

makeProtocolRep: aSymbol

	^ ClassRep
		create: aSymbol
		with: ((self selectedClass organization listAtCategoryNamed: aSymbol)
			detect: [ :each |
				ChangeLog hasChangesFor: each
				in: self selectedClass]
			ifNone: [nil]) ~~ nil
		with: 0!

makeSelectorRep: sel
	^ ClassRep create: sel
		with: (ChangeLog hasChangesFor: sel
			in: self selectedClass)
		with: 0!

{void} normalize
	"assume className, meta, and selector valid.  Set some others accordingly"
	
	organization = nil
		ifTrue: [organization _ SystemOrganization].
	self selectedClass = nil 
		ifTrue: [^VOID].
	category _ organization categoryOfElement: className.
	selector = nil 
		ifTrue: [^VOID].
	protocol _ self selectedClass organization categoryOfElement: selector.!

{String} requestString
	^self requestString: 'String to find'.!

{String} requestString: prompt
	LastStringSought = nil ifTrue: [LastStringSought _ ''].
	LastStringSought _ self prompt: prompt initially: LastStringSought.
	LastStringSought isEmpty ifTrue: [^''].
	^ LastStringSought!

spawnCxxBrowser
	| cxxBrowser {CxxBrowser} |
	self normalize.
	cxxBrowser _ CxxBrowser make.
	(cxxBrowser findClass: self selectedClass) not ifTrue: [^VOID].
	cxxBrowser className: self nonMetaClass name.
	cxxBrowser meta: self meta.
	cxxBrowser protocol: protocol.
	cxxBrowser method: selector. 
	CxxBrowserView openCxxBrowserOn: cxxBrowser.!

spawnSystemBrowser
	BrowserView openOnBrowser: self copyAsBrowser! !

!Browser methodsFor: 'private: private-selector functions'!

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
			Array with: (assoc key contractTo: 40) with: assoc]).
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
		ifFalse: [^OrderedCollection with: result]! !

!Browser methodsFor: 'private: private-category functions'!

sortNewCategories

	| dCats stillOld sysCats newCats |
	dCats _ SystemOrganization categories.
	stillOld _ dCats indexOf: #'OS-Mac-Support'.
	sysCats _ dCats copyFrom: 1 to: stillOld.
	newCats _ dCats copyFrom: stillOld + 1 to: dCats size.
	newCats _ newCats asSortedCollection asArray.
	dCats _ sysCats, newCats.
	SystemOrganization categories: dCats! !

!Browser methodsFor: 'private: private-protocol functions'!

{String} pickAProtocol
	| prots {Array of: String}
	  menu {PopUpMenu}
	  newProtocol {String} 
	  uniqueString {String} |
	  
	prots _ self selectedClass organization categories.
	uniqueString _ #'enter name'.
	menu _ PopUpMenu fromArray: 
		(Array with: (Array with: uniqueString)), 
		#(-),
		(prots collect: [:prot {Symbol} |
			Array with: prot]).
	newProtocol _ menu startUp.
	(newProtocol isNil or: [newProtocol = 0])
		ifTrue: [^nil].
	(newProtocol == uniqueString)
		ifTrue: [newProtocol _ self prompt: 'Type destination protocol
(Class>protocol will copy)' initially: MethodMoveProtocol.
				newProtocol isEmpty 
					ifTrue: [^nil]].
	MethodMoveProtocol _ newProtocol.
	^newProtocol! !

!Browser methodsFor: 'smalltalk: passe'!

{Symbol} pickFromCategoryMenu: cats {OrderedCollection of Symbol}
	"Pick a category from a menu"

	self passe "use FromCategory class pickFromCategoryMenu:"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Browser class
	instanceVariableNames: ''!



!Browser class methodsFor: 'class initialization'!

initialize 
	"Browser initialize."

	MethodMoveProtocol _ 'protocol name'.
	LastProtocol _ nil.! !

!Browser class methodsFor: 'instance creation'!

newOnClass: aClass
	"Create and schedule a view that is a browser for the class aClass."
	"Browser newOnClass: BrowserView"

	BrowserView openClassBrowserOn: (self new onClass: aClass)! !

!Browser class methodsFor: 'configuration'!

showMethodHistory
	^ShowMethodHistory!

showMethodHistory: flag
	ShowMethodHistory _ flag! !

!Browser class methodsFor: 'class ordering'!

computeClassOrdering: list 
	"Supply a result collection into which elements will be added in inheritance (then alphabetic) order."

	^Browser computeClassOrdering: (list asSortedCollection collect: [:cl | Smalltalk at: cl asSymbol])
		into: OrderedCollection new indent: 0!

computeClassOrdering: list into: result indent: indent
	"Add the elements of list into result in nesting alphabetic order."

	list isEmpty
		ifFalse: 
			[| sup related unrelated |
			sup _ list detect: [:candidate | (list detect: [:maybeSup | candidate inheritsFrom: maybeSup] ifNone: []) == nil].
			result addLast: (self makeClassRep: sup with: indent).
			related _ OrderedCollection new.
			unrelated _ OrderedCollection new.
			list do: [:sub | sub = sup ifFalse: [(sub inheritsFrom: sup)
						ifTrue: [related addLast: sub]
						ifFalse: [unrelated addLast: sub]]].
			self computeClassOrdering: related into: result indent: indent + 1.
			self computeClassOrdering: unrelated into: result indent: indent].
	^result!

makeClassRep: class 
	^self makeClassRep: class with: 0!

makeClassRep: class with: indent
	class == nil ifTrue: [^ nil].
	^ClassRep
		create: class name
		with: (ChangeLog hasChangesFor: class) 
		with: indent! !

Browser initialize!
