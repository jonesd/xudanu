'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:19 pm'!

OutlineBrowser subclass: #CxxOutlineBrowser
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!


!CxxOutlineBrowser methodsFor: 'menu - misc'!

fixOrg
	| t kiddies keys classes |
	tree withChildrenDo: [:c | (c isKindOf: CxxTreeAssociation) not
			ifTrue: 
				[| tmp |
				tmp _ CxxTreeAssociation key: c key value: c value.
				tmp parent: c parent.
				c childrenDo: [:gc | tmp addChild: gc].
				c become: tmp].
		((t _ CxxSystemOrganization fetchModuleNamed: c key) ~~ nil and: [c isLeaf and: [c value ~~ #file]])
			ifTrue: [c value: #file.
				t fixup]].
	"tree fixOrg."
	self editor fixOrganization.
	kiddies _ IdentitySet new.
	classes _ IdentitySet new.
	keys _ Set new.
	tree withChildrenDo: [:kid | (kiddies includes: kid)
			ifTrue: [Transcript show: 'tree has ' , kid key , ' more than once!!'; cr; endEntry]
			ifFalse: 
				[(keys includes: kid key)
					ifTrue: [Transcript show: 'key ' , kid key , ' is in tree more than once!!'; cr; endEntry]
					ifFalse: [keys add: kid key].
				kiddies add: kid.
				kid value == #file ifTrue: [
					(CxxSystemOrganization getModuleNamed: kid key) allClasses stepper 
						forEach: [:cls |  
							(classes includes: cls)
								ifTrue: [Transcript show: 
									('Class ' , cls name , ' is duplicated in file ' , kid key); cr; endEntry].
							classes add: cls]]]].!

pasteIndented
	super pasteIndented!

selectionListMenu
	"Menu for the outline pane of the cxx browser."
	
	| tags {Collection of: Symbol} |
	tags _ PopUpMenu tags.
	self selected == nil ifTrue: 
		[tags _ tags, #(noSel)]
	ifFalse:
		[tags _ tags, #(sel).
		(tags includes: #long) ifTrue:
			[tags _ tags, #(longSel)].
		(tags includes: #unix) ifTrue:
			[tags _ tags, #(unixSel)]].
		
	^PopUpMenu matching: tags fromPrefixedArray: #(
		(all		'outline' (
			(sel		'make into module'	makeFile					'Xu: Turn the selected outline item into a module (which eventually causes the creation of correspondingly-named files)')
			(sel		'make directory'		makeDirectory			'Xu: Turn the selected outline item into a directory (which eventually creates a directory of the same name in a file-system directory-tree position corresponding to the position of the selected item in the outline browser.)')
			(sel		'make tag'				makeTag					'Xu: Turn the selected item back from a directory or file to a neutral tag')
			(all		'check'						fixOrg						'Xu: Do a partial consitency check of the outline structure.  Report problems, repair simple ones.')
			-
			(all		'BOSS load'				load						'Xu: Load the outline organization from a BOSS file.')
			(all		'BOSS save'				save						'Xu: Save the outline organization to a BOSS file.') ))
		(sel		'module' (
			(all		'test'					runTests					'Xu: Run all the regression tests for modules contained by the selected outline item.  Report differences.')
			(all		'make output into reference' newReference			'Xu:  Make the output of the test code into the reference file')
			(all		'switch loggers'			switchLoggers			'Xu: Bring up menu showing logging environment and allowing it to be changed')
			(longSel	'inspect module'			inspectModule				'Xu: Will go away.  Only here to help MarkM debug')
			-
			(all		'client protocol' 		showClientProtocolFile	'Xu: Show the translated-to-pseudo-c++ client protocol file.')
			(all		'show header' 		showHeaderFile			'Xu: Show the translated-to-c++ header (declarations) file.')
			(all		'show opaque' 		showOpaqueFile			'Xu: Show the translated-to-c++ opaque file.')
			(all		'show inline' 			showInlineFile				'Xu: Show the translated-to-c++ inline (definitions) file.')
			(all		'show body' 			showBodyFile				'Xu: Show the translated-to-c++ body (definitions) file.')
			-
			(all		'automatic stuff then s&t'		regenerateThenScanAndTranslate			'Xu: Regerate automatic code, then do a "scan and translate"')
			(all		's&t with baseline'		autoScanAndTranslate			'Xu: Like "scan and translate", but only modules changed since baseline.  Also sets baseline to now afterwards')
			(all		'scan and translate'		scanAndTranslate			'Xu: Do an includeScan, then write the translation of all modules contained by the selected outline item.')
			(all		'scan'						scanForIncludes			'Xu: Automatically generate the lists of files to be included and classes for which opaque definitions are needed.')
			(all		'translate' (
				(all		'all'						translateAll					'Xu: Write the translation of all code (*[tx].[hc]xx, *[rp].hxx) of all modules contained by the selected outline item.')
				(all	'implementation'		translateImplementation		'Xu: Write the translation of the implementation (*[rp].hxx, *x.cxx) of all modules contained by the selected outline item.')
				(all	'interface'				translateInterface			'Xu: Write the translation of the interface (*x.hxx) of all modules contained by the selected outline item.')
				(all	'client protocol'		translateClientProtocol		'Xu: Write the translation of the client protocol (*x.prx) of all modules contained by the selected outline item.')
				(all		'test'					translateTest					'Xu: Write the translation of the test code (*t.[hc]xx) of all modules contained by the selected outline item.')
				-
				(longSel	'macMakeMake'		fileoutMakeMakeRules	'Xu: Unimplemented:  Write makefile support for Macintosh Programmer''s Workbench.') ))
			-
			(all		'file out' (
				(all		'smalltalk'				fileoutSmalltalk			'Xu: Write the smalltalk version of all the classes contained by the selected outline item as a normal smalltalk fileout.')
				(all		'org'					fileoutSmalltalkOrg		'Xu: Write the organization (for display in the c++ browser???) of all the classes contained by the selected outline item.')
				(all		'print out'				printOutFile				'Xu: Print hardcopy of smalltalk form of all the classes contained by the selected outline item.  (May fake this by writing postscript into a file named temp.postscript*)')
				(all		'print out interface'	printOutFileInterface				'Xu: Print hardcopy of smalltalk form of the public interfaces to all the public classes contained by the selected outline item.  (May fake this by writing postscript into a file named temp.postscript*)') ))
			(unixSel		'cvs'				cvsModule				'Xu: Bring up the cvs (Concurrent Version System) menu, and apply the action to the selected outline item.') ))
		(sel		'aspects' (
			(all		'decl header' 				editDeclHeader			'Xu: Show (and allow editing of) extra c++ code to be inserted near the start of the *.hxx header file.')
			(all		'defn header' 			editDefnHeader			'Xu: Show (and allow editing of) extra c++ code to be inserted near the start of the *.ixx inline file.')
			(all		'type refs' (
				(all		'header'				showHeaderTypeRefs	'Xu: Show types referred to by the *.hxx header file, and the resulting include requirements')
				(all		'opaque'				showOpaqueTypeRefs	'Xu: Show types referred to by the *.oxx opaque file, and the resulting include requirements')
				(all		'inline'					showInlineTypeRefs		'Xu: Show types referred to by the *.ixx inline file, and the resulting include requirements')
				(all		'body'					showBodyTypeRefs		'Xu: Show types referred to by the *.cxx body file, and the resulting include requirements') ))
			(longSel	'module comment'		editFileComment			'Xu: Show (and allow editing of) a comment to be prepended to the *x.hxx file written by translating the modules contained by the selected outline item. ')
			(longSel	'comment'				editGroupOrClassComment	'Xu: Show (and allow editing of) a comment to be prepended to the *x.hxx file written by translating the modules contained by the selected outline item. ') ))
		-
		(all		'update'				update					'Xu: Recalculates display from underlying information, to bring browser into sync with real world.')
		(longSel	'expand'			openCurrent			'Xu: Reveal the level below the currently selected item in the outline browser.')
		(longSel	'contract'			closeCurrent				'Xu: Hide the level below the currently selected item in the outline browser.')
		(sel		'level' (
			(all		'up'				upLevel					'Xu: Promote the currently selected item to the next shallower level of nesting.')
			(all		'down'				downLevel			'Xu: Demote the currently selected item to the next deeper level of nesting.') ))
		-
		(sel		'copy'				copyCurrent				'Xu: Copy the currently selected item (and its subtree) to the outline''s clipboard.')
		(sel		'cut'				cut						'Xu: Copy the currently selected item (and its subtree) to the outline''s clipboard and remove it from its current location.')
		(sel		'paste' (
			(all		'after'				pasteAfter			'Xu: Paste the current contents of the outline''s clipboard after the selected item.')
			(all		'before'			pasteBefore				'Xu: Paste the current contents of the outline''s clipboard before the selected item.')
			(all		'indented'			pasteIndented			'Xu: Paste the current contents of the outline''s clipboard after the selected item, demoted one level deeper in the nest.') ))
		-
		(sel		'find'				findInModule				'Xu: Apply criteria from a FindMenu to all the methods in the selected outline item and its subtree.')
		(all			'find in browser'	findInBrowser				'Xu: Apply criteria from a FindMenu to all the methods of any cxx class.')
		(all			'locate' (
			(all		'class'				findClass					'ST: Prompt for class name, position browser so that class is visible')
			(all		'module'			findModule				'Xu: Prompt with a hierarchical menu of the module tree.  Position the browser to the chosen module.')
			(sel	'includer'			showIncluders			'Xu: Prompt with a menu of those modules which include the selected module, and position to the one selected') ))
		-
		(noSel	'add'					addAfter					'Xu: Create a new outline entry and add it to the browser.')
		(sel	'add' (
			(all		'after'				addAfter				'Xu: Prompt for a name.  Add an outline item of that name after the selected item.')
			(all		'before'			addBefore				'Xu: Prompt for a name.  Add an outline item of that name before the selected item.')
			(all		'indented'			addIndented			'Xu: Prompt for a name.  Add an outline item of that name after the selected item, demoted one level deeper in the nest.')
			(all		'module'			addFile				'Xu: Prompt with a menu of something-or-other.  Add an outline item of that name after the selected item, demoted one level deeper in the nest.  Do this in a way that breaks the outline. ????') ))
		(sel		'rename'			renameCategory			'Xu: Rename the currently selected outline item.')
		(sel		'destroy'			destroyFile				'Xu: Remove the currently selected outline item and all its childre from the outline browser.  The classes remain defined and may be added to other outline items or browsed with the system browser.') )!

showBodyFile

	self collectWarns: [self editor showFile: CxxBodyFile].!

showClientProtocolFile

	self collectWarns: [self editor showFile: CxxClientProtocolFile].!

showHeaderFile

	self collectWarns: [self editor showFile: CxxHeaderFile].!

showInlineFile

	self collectWarns: [self editor showFile: CxxInlineFile].!

showOpaqueFile

	self collectWarns: [self editor showFile: CxxOpaqueFile].!

showPosition
	self treeLocation inspect!

update
	treeSelection updateChange.
	(self selectedChild isKindOf: CxxTreeAssociation)
		ifTrue: [treeSelection resetChild: self selectedChild]
		ifFalse: [treeSelection resetChild: nil]! !

!CxxOutlineBrowser methodsFor: 'menu - finding'!

findClass
	"Prompt for a class and position myself there."

	self findClass: (self editor pickAClass: 'Find class:').!

{void} findInBrowser

	self editor browseFiltered: FromCxxModule make!

{void} findInModule
	
	self selected == nil
		ifTrue: [^VOID].
	self editor browseFiltered: (FromCxxModule make: nil with: self selected)!

{void} findModule
	"Prompt for a category and position myself there."

	| testModule {String} |
	testModule _ FromCxxModule pickAModuleFrom: tree.
	testModule == nil
		ifTrue: [^Transcript cr; show: 'Nobody'].
	self changeRequest ifFalse: [^self].
	self selectModule: testModule.!

{void} showIncluders
	"Xu: Prompt with a menu of those modules which include the selected module
	(or any module in the selected module group), and position to the one selected"

	| testModule {String} |
	self selected == nil
		ifTrue: [^VOID].
	testModule _ self fetchAnIncludingModule: self selected.
	testModule == nil
		ifTrue: [^Transcript cr; show: 'Nobody'].
	self changeRequest ifFalse: [^self].
	self selectModule: testModule.! !

!CxxOutlineBrowser methodsFor: 'menu - file mgmt'!

addFile
	| newName nuOne files   |
	self editor changeRequest ifFalse: [^VOID].
	files _ CxxSystemOrganization fileList asOrderedCollection.
	files _ (files collect: [:f | f moduleName]) asSortedCollection.
	tree withChildrenDo: [:c | c value == #file
		ifTrue: [files remove: c key ifAbsent: []]].
	newName _ FillInTheBlank request: 'Please provide the file name
then accept or CR' initialAnswer: ''.
	(newName == nil or: [newName isEmpty])
		ifTrue: [^VOID].
	nuOne _ self newFor: newName.
	nuOne value: #file.
	self insertChild: nuOne withOpenedSet: nil.
	CxxSystemOrganization getOrMakeFileNamed: newName.!

{NOWAIT} cvsModule

	| op {CVSOperator} |
	op _ CVSOperator fetchFromMenu.
	op ~~ nil ifTrue:
		[op cvsModule: self selected]!

destroyContainedClasses
	 
	| classes {IdentitySet of: Class} 
	  withAllSubclasses {IdentitySet of: Class} 
	  outsiders {IdentitySet of: Class} 
	  condemned {IdentitySet of: Class} |
	  
	classes := IdentitySet new.
	withAllSubclasses := IdentitySet new.
	self selected classesDo: [:cxc {CxxClassDescription} |
		| cls {Class} |
		cls := cxc classDescription.
		classes add: cls.
		(withAllSubclasses includes: cls) ifFalse:
			[withAllSubclasses addAll: cls withAllSubclasses]].
	outsiders := withAllSubclasses select: [:sub {Class} |
		(classes includes: sub) not].
	outsiders isEmpty ifTrue:
		[condemned := classes]
	ifFalse:
		[Transcript cr; << 'Classes (and their modules) with children outside the destroyed set are being preserved'; cr.
		condemned := classes select: [:parent {Class} |
			(parent allSubclasses asIdentitySet intersects: outsiders) not]].
	condemned do: [:croaker {Class} |
		croaker removeFromSystem]!

destroyEmptyModules
	
	| parent nextSelect index |
	parent _ treeSelection currentSelection parent.
	nextSelect _ nil.
	parent ~~ nil
		ifTrue: [index _ parent findIndexOfChild: treeSelection currentSelection.
			(index ~~ nil)
				ifTrue: [(index > 1)
					ifTrue: [nextSelect _ parent at: (index - 1)]
					ifFalse: [nextSelect _ parent]]].
	self selected destroyEmptyModules ifFalse:
		[^VOID].

	nextSelect == nil
		ifTrue: [treeSelection tree: (CxxSystemOrganization tree).
				treeSelection resetChild: nil]
		ifFalse: [treeSelection resetChild: nextSelect]!

destroyFile

	| prefix {String} sel1 {Symbol} sel2 {Symbol} |
	sel1 := (PopUpMenu fromArray: #(
		('save image first'	save	'Xu: Save image in case you want to throw away the one resulting from the destroy')
		('live dangerously'	nick	'Xu: Proceed with the destroy in a foolhardy manner')
		('abort'				abort	'Xu: fogetaboudit'))) startUp.
	(sel1 = 0 or: [sel1 == #abort]) ifTrue:
		[^VOID].
	sel1 == #save ifTrue:
		[prefix _ Smalltalk getImagePrefix.
		prefix isEmpty ifTrue: 
			[^VOID].
		Smalltalk saveAs: prefix thenQuit: false].
		
	sel2 := (PopUpMenu fromArray: #(
		('preserve classes'		removeClassesFromCxxOrg		'Xu: Destroy module tree but leave classes alone')
		('destroy classes too'	destroyContainedClasses		'Xu: Destroy module tree and all its contained classes')
		('abort'					abort								'Xu: fogetaboudit'))) startUp.
	(sel2 = 0 or: [sel2 == #abort]) ifTrue:
		[^VOID].
	Cursor execute showWhile:
		[self perform: sel2.
		self destroyEmptyModules.
		self update]!

fileHistory
	ChangeLog browse: (ChangeRecord pathLeaf: (OrderedCollection with: self selected key asSymbol))
		backTo: ChangeLog baseline!

makeDirectory
	self selected value: #dir!

makeFile
	self selected value: #file.
	CxxSystemOrganization getOrMakeFileNamed: self selected key.
	self editor value: (self selected key).
	treeSelection resetChild: self selected!

makeTag
	self selected value: nil!

printOutFile
	"| stream |
	stream _ LabelledTextStream on: (String new: 10000)."
	self printFiles: self selected on: nil.
	"self editor hardcopyStream: stream.
	stream close"!

printOutFileInterface
	"| stream |
	stream _ TextStream on: (String new: 10000)."
	self printFileInterfaces: self selected on: nil.
	"self editor hardcopyStream: stream.
	stream close"!

removeClassesFromCxxOrg
	
	self selected classesDo: [:cxc {CxxClassDescription} |
		cxc fetchCxxModule removeClass: cxc in: cxc visibility]!

renameCategory
	| newCategory currentChild |
	self changeRequest ifFalse: [^self].
	currentChild := self selectedChild.
	newCategory _ nil.
	[newCategory == nil]
		whileTrue: 
			[newCategory := FillInTheBlank request: 'New item name' 
				initialAnswer: currentChild name.
			newCategory = '' ifTrue: [^self].
			newCategory = currentChild name ifTrue: [^self].
			(currentChild value = #file and: [newCategory size > 7])
				ifTrue: [newCategory _ newCategory copyFrom: 1 to: 7.
					Transcript show: 'filename truncated to ' , newCategory].
			(CxxSystemOrganization fetchModuleNamed: newCategory) ~~ nil 
				ifTrue: [Transcript show: ('"' , newCategory , '" already exists'); 
						cr; endEntry.
				newCategory _ nil]].
	currentChild value = #file 
		ifTrue: [(CxxSystemOrganization getModuleNamed: currentChild key)
			setFileName: newCategory].
	currentChild key: newCategory.
	treeSelection resetChild: currentChild.
	self noteModification! !

!CxxOutlineBrowser methodsFor: 'menu - mac specific'!

fileoutSegmentNames
	| fileName aFileStream |
	self selected == nil ifTrue:[^ VOID].
	fileName _ Filename request: 'File out on'
						 initially: (self selected key asString, '.segs')
						 shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	
	aFileStream _ (Filename named: fileName) writeStream.
	[self selected writeMacSegmentNamesOn: aFileStream] 
		valueNowOrOnUnwindDo: [aFileStream close]! !

!CxxOutlineBrowser methodsFor: 'menu - fileout'!

{NOWAIT} autoScanAndTranslate

	self update.
	self collectWarns: [
		(self selected modulesInActualDirectories 
			select: [:mod {CxxModule} | mod isChanged]) doAll: (OrderedCollection 
				with: [:mod {CxxModule} | mod scanForIncludes]
				with: [:mod {CxxModule} | mod translateAll]).
		ChangeLog baseline: ChangeLog logPosition.
		self update.
		self alert].!

{void} fileoutFile
	self editor fileOutFile!

fileoutSmalltalk
	| files classes sortedClasses fileName aFileStream |
	fileName _ Filename request: 'File out on'
						 initially: (self selected key asString, '.st')
						 shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	
	"get collection of files"
	files _ OrderedCollection new.
	self selected isLeaf
		ifTrue: [ files add: self selected key ]
		ifFalse: [ self selected withChildrenDo: [ :c | c value == #file ifTrue: [files add: c key]]].

	"collect and sort classes"
	classes _ OrderedCollection new.
	files do: [ :f |
		classes addAll: (CxxSystemOrganization getModuleNamed: f) allClasses].
	sortedClasses _ self computeClassOrdering: 
				(classes asSortedCollection collect: [:cxxDesc | cxxDesc classDescription])
			into: OrderedCollection new.

	aFileStream _ (Filename named: fileName) writeStream.
	[
		aFileStream timeStamp.

		"make sure files are remove from receiving image"
		aFileStream <<
'((CxxSystemOrganization tree childNamed: ' << self selected key storeString << ') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: ' << self selected key storeString
	<< ') destroyFiles]!!'; cr; cr.
	
		"fileout classes and per-class stuff like friends and instVarTypes"
		sortedClasses do: [ :c |
			c fileOutOn: aFileStream].

		"fileout organization stuff"
		files do: [ :f |
			(CxxSystemOrganization getModuleNamed: f) fileoutOrgOn: aFileStream].

		aFileStream << '
CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	'.
		CxxSystemOrganization fileoutTree: self selected on: aFileStream.
		aFileStream << ')!!'
	] valueNowOrOnUnwindDo: [aFileStream close]!

fileoutSmalltalkOrg
	| files classes fileName aFileStream |
	fileName _ Filename request: 'File out on'
						 initially: (self selected key asString, '.st')
						 shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	
	"get collection of files"
	files _ OrderedCollection new.
	self selected isLeaf
		ifTrue: [ files add: self selected key ]
		ifFalse: [ self selected withChildrenDo: [ :c | c value == #file ifTrue: [files add: c key]]].

	"collect and sort classes"
	classes _ OrderedCollection new.
	files do: [ :f |
		classes addAll: (CxxSystemOrganization getModuleNamed: f) allClasses].

	aFileStream _ (Filename named: fileName) writeStream.
	[
		aFileStream timeStamp.

		"make sure files are remove from receiving image"
		aFileStream <<
'((CxxSystemOrganization tree childNamed: ' << self selected key storeString << ') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: ' << self selected key storeString
	<< ') destroyFiles]!!'; cr; cr.
	
		"fileout classes and per-class stuff like friends and instVarTypes"
		"sortedClasses do: [ :c |
			c fileOutOn: aFileStream]."

		"fileout organization stuff"
		files do: [ :f |
			(CxxSystemOrganization getModuleNamed: f) fileoutOrgOn: aFileStream].

		aFileStream << '
CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	'.
		CxxSystemOrganization fileoutTree: self selected on: aFileStream.
		aFileStream << ')!!'
	] valueNowOrOnUnwindDo: [aFileStream close]!

fileoutSmalltalkV
	| files classes sortedClasses fileName aFileStream |
	fileName _ Filename request: 'File out on'
						 initially: (self selected key asString, '.st')
						 shouldExist: false. 
	fileName = '' ifTrue: [^nil].
	
	"get collection of files"
	files _ OrderedCollection new.
	self selected isLeaf
		ifTrue: [ files add: self selected key ]
		ifFalse: [ self selected withChildrenDo: [ :c | c value == #file ifTrue: [files add: c key]]].

	"collect and sort classes"
	classes _ OrderedCollection new.
	files do: [ :f |
		classes addAll: (CxxSystemOrganization getModuleNamed: f) allClasses].
	sortedClasses _ self computeClassOrdering: 
				(classes asSortedCollection collect: [:cxxDesc | cxxDesc classDescription])
			into: OrderedCollection new.

	aFileStream _ (Filename named: fileName) writeStream.
	[
		aFileStream timeStamp.
	
		"fileout classes and per-class stuff like friends and instVarTypes"
		sortedClasses do: [ :c |
			c fileOutSmalltalkVOn: aFileStream].

	] valueNowOrOnUnwindDo: [aFileStream close]!

{NOWAIT} inspectModule
	"Temporary debugging purposes only"
	
	self selected value ~~ #file
		ifTrue: [^VOID].
	(CxxSystemOrganization getModuleNamed: self selected key) inspect!

{NOWAIT} regenerateThenScanAndTranslate

	PopUpMenu flushMenus.
	Initializer cleanup.
	Undeclared _ Dictionary new.
	Heaper removeSubclassGeneratedCode.
	Smalltalk snapshot.
	Object compileAllSubclasses.
	Heaper compileSubclassStubbleMethods.
	Heaper compileClientSubclasses.
	"Abraham compileAllLocks.  Obsolete!!"
	Heaper compilePromiseHandlers.
	Heaper requestProceduresFrom: 'client.prc'.
	Heaper makeRequestTable: 'client.prc'.
	Heaper makeClassTable: 'client.prc'.
	Symbol rehash.
	Symbol rehash.
	Smalltalk resetSpaceLimits.
	Smalltalk snapshot.

	self translatePhases: (OrderedCollection 
		with: [:mod {CxxModule} | mod scanForIncludes]
		with: [:mod {CxxModule} | mod translateAll])!

{NOWAIT} scanAndTranslate

	self translatePhases: (OrderedCollection 
		with: [:mod {CxxModule} | mod scanForIncludes]
		with: [:mod {CxxModule} | mod translateAll])!

scanForIncludes
	
	self translatePhases: (OrderedCollection 
		with: [:mod {CxxModule} | mod scanForIncludes])!

{NOWAIT} translateAll
	"Do fake stubble files first, so they'll happen earlier wrt make"
	
	self translatePhases: (OrderedCollection 
		with: [:mod {CxxModule} | mod translateAll])!

{NOWAIT} translateClientProtocol

	self translatePhases: (OrderedCollection 
		with: [:mod {CxxModule} | mod translateClientProtocol])!

{NOWAIT} translateImplementation

	self translatePhases: (OrderedCollection 
		with: [:mod {CxxModule} | mod translateImplementation])!

{NOWAIT} translateInterface

	self translatePhases: (OrderedCollection 
		with: [:mod {CxxModule} | mod translateInterface])!

{NOWAIT} translatePhases: blocks {Collection of: (BlockClosure of: CxxModule)}
	
	self collectWarns: [
		self selected modulesInActualDirectories doAll: blocks.
		self alert]!

{NOWAIT} translateTest

	self translatePhases: (OrderedCollection 
		with: [:mod {CxxModule} | mod translateTest])! !

!CxxOutlineBrowser methodsFor: 'menu edit messages'!

editDeclHeader

	self editor editHxxHeader!

editDefnHeader

	self editor editCxxHeader!

editFileComment
	self editor editFileComment!

editGroupOrClassComment
	self editor editGroupOrClassComment!

showBodyTypeRefs

	self editor showTypeRefs: CxxBodyFile!

showHeaderTypeRefs

	self editor showTypeRefs: CxxHeaderFile!

showInlineTypeRefs

	self editor showTypeRefs: CxxInlineFile!

showOpaqueTypeRefs

	self editor showTypeRefs: CxxOpaqueFile! !

!CxxOutlineBrowser methodsFor: 'private: private'!

{void} alert

	"self selected isLeaf ifFalse: [SoundPlayer onSystem play: 'Simple Beep']"!

{void} collectWarns: aBlock {BlockClosure} 
	| warnedMethods {Collection of: MethodRep} |
	Cursor execute showWhile: [
		HxxPrintStream initWarnedMethods.
		aBlock value.
		(warnedMethods _ HxxPrintStream warnedMethods) isEmpty
			ifTrue: [^VOID].
		(EnumerateMethods 
			make: warnedMethods 
			with: 'Stale: Methods which generated translator warnings') 
				browse: self editor fetchMethodRep]!

computeClassOrdering: list into: result
	"Add the elements of list into result in nesting alphabetic order."

	list isEmpty
		ifFalse: 
			[| sup related unrelated |
			sup _ list detect: [:candidate | 
				(list detect: [:maybeSup | candidate inheritsFrom: maybeSup] ifNone: [])
							== nil].
			result addLast: sup.
			related _ OrderedCollection new.
			unrelated _ OrderedCollection new.
			list do: [:sub | sub = sup ifFalse: [(sub inheritsFrom: sup)
						ifTrue: [related addLast: sub]
						ifFalse: [unrelated addLast: sub]]].
			self computeClassOrdering: related
				into: result.
			self computeClassOrdering: unrelated
				into: result].
	^result!

{String} fetchAnIncludingModule: treeAssoc {CxxTreeAssociation}

	| result {String} cxcs {Set of: CxxClassDescription} menuDesc {OrderedCollection} |
	cxcs _ Set new.
	treeAssoc withChildrenDo: [:kid {CxxTreeAssociation} |
		kid value == #file
			ifTrue: [
				| mod {CxxModule} |
				mod _ CxxSystemOrganization getModuleNamed: kid key.
				cxcs addAll: mod allClasses]].
	menuDesc _ FromCxxModule menuArrayFrom: tree children passing: [:mod {CxxModule} |
		mod allTypeRefs intersects: cxcs].
	menuDesc isEmpty 
		ifTrue: [^nil].
	result _ (PopUpMenu fromArray: menuDesc) startUp.
	result = 0
		ifTrue: [^nil]
		ifFalse: [^result].!

newFor: cat
	^ self newItemWithKey: cat value: nil!

newItemWithKey: newCategory value: newValue 
	"Answer an item with newCategory as the key and newValue 
	as the value."
	
	^CxxTreeAssociation key: newCategory value: newValue!

printFileInterfaces: fromSpot on: blob
	| stream | 
	fromSpot value == #file ifTrue: [
		stream _ LabelledTextStream on: (String new: 10000).
		(CxxSystemOrganization fetchModuleNamed: fromSpot key)
			printOutInterfaceOn: stream.
		self editor hardcopyStream: stream with: fromSpot key.
		stream close].
	fromSpot children do: [:kid | self printFiles: kid on: blob]!

printFiles: fromSpot on: blob
	| stream | 
	fromSpot value == #file ifTrue: [
		stream _ LabelledTextStream on: (String new: 10000).
		(CxxSystemOrganization fetchModuleNamed: fromSpot key)
			printOutOn: stream.
		self editor hardcopyStream: stream with: fromSpot key.
		stream close].
	fromSpot children do: [:kid | self printFiles: kid on: blob]!

