'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:46 pm'!

Dictionary variableSubclass: #SystemDictionary
	instanceVariableNames: ''
	classVariableNames: '
		BytesLeftLimit {Integer} 
		CachedClassNames {SortedCollection of: Symbol} 
		Frills {BooleanVar} 
		ImagePrefix {String} 
		LowSpaceProcess {Process} 
		LowSpaceSemaphore {Semaphore} 
		OopsLeftLimit {Integer} 
		SnapshotErrorSignal {Signal} 
		SpecialSelectorDictionary {IdentityDictionary of: Symbol with: Integer} 
		SpecialSelectors {Array of: Symbol | Integer} 
		SystemChanges {ChangeSet} '
	poolDictionaries: ''
	category: 'System-Support'!
SystemDictionary comment:
'Class SystemDictionary represents a special dictionary that supports protocol for asking questions about the structure of the system.  The sole instance is Smalltalk.

Class Variables:
	BytesLeftLimit		<Integer>
	CachedClassNames	<SortedCollection> of all class names
	Frills		<Boolean> used to indicate whether some of the functionality considered extra should not be used because of the slower speed of the hardware
	ImagePrefix		<String> current prefix name for the image and changes files
	LowSpaceProcess		<Process> for monitoring the amount of core left and number of remaining objects
	LowSpaceSemaphore	<Semaphore>
	OopsLeftLimit		<Integer>
	SnapshotErrorSignal <Signal> Snapshot primitive failed
	SpecialSelectorDictionary <IdentityDictionary>
	SpecialSelectors	<Array of: Symbols> that are message selectors
	SystemChanges 	<ChangeSet> into which any changes such as method adds, removals, or renames, is remembered'!



!SystemDictionary methodsFor: 'initialize-release'!

install
	"Get connected back up to the hardware after a snapshot or quit."
	"Call the initialization code that depends on system parameters,
	in case we are coming up on a system different from the one
	that we quit or snapshot on."

	SmallInteger initialize.
	LargePositiveInteger initialize.
	LargeNegativeInteger initialize.
	Display beDisplay.
	Cursor install.
	InputSensor install.
	self installLowSpaceNotifier.
	Delay install.
	ScheduledControllers restore.
	OSHandle install.
	CEnvironment install.
	UninterpretedBytes checkByteOrder!

installLowSpaceNotifier
	"Create a low space notifier, that is a semaphore that checks to see
	if space is getting low, and if so notifies the user.  Put the process at
	a low i/o priority."
	
	LowSpaceProcess == nil ifFalse: [LowSpaceProcess terminate].
	LowSpaceSemaphore _ Semaphore new.
	LowSpaceProcess _ [self lowSpaceNotificationLoop] newProcess.
	LowSpaceProcess priority: Processor lowIOPriority.
	LowSpaceProcess resume.
	self resetSpaceLimits!

postSnapshot
	"Clean up after a snapshot"

	Delay postSnapshot.
	Display postSnapshot.
	self changed: #finishedSnapshot.!

preSnapshot
	"Prepare to do a snapshot--flush caches, commit buffers, etc."

	self changed: #aboutToSnapshot.
	self commitExternalViews.
	ScheduledControllers flushDisplayBits.
	Delay preSnapshot.
	Display preSnapshot.
	Smalltalk primGarbageCollect.
	Cursor wait show.!

returnFromSnapshot
	"Get connected back up to the hardware after a snapshot or quit."
	"Call the initialization code that depends on system parameters,
	in case we are coming up on a system different from the one
	that we quit or snapshot on."

	self install.
	self changed: #returnFromSnapshot! !

!SystemDictionary methodsFor: 'accessing'!

at: aKey put: anObject 
	"Set the value at key to be anObject.  If key is not found, create a new
	entry for key and set is value to anObject. Answer anObject."

	"Override from Dictionary so that can check Undeclared and fix up 
	references of undeclared variables."

	| index element |
	index _ self findKeyOrNil: aKey.
	element _ self basicAt: index.
	element == nil
		ifTrue: 
			[self
				valueAtNewKey: aKey
				put: anObject
				atIndex: index
				declareFrom: Undeclared]
		ifFalse: 
			[element value: anObject].
	^anObject!

safeAt: aKey put: anObject 
	"Put a value in the global dictionary only if there isn't already a behavior there!!"
	
	(self at: aKey ifAbsent: []) isBehavior ifTrue: 
		[self warn: 'Tried to overwrite ' , aKey asString , ' in global dictionary...ignored!!'.
		^aKey].
	self at: aKey put: anObject!

valueAtNewKey: aKey put: anObject atIndex: index declareFrom: aDictionary 
	"Handle overriding atKey:put: from Dictionary so that adding 
	something new to a system dictionary such as Smalltalk checks 
	Undeclared and fixes up all references to the undeclared variable"

	(aDictionary includesKey: aKey)
		ifTrue: 
			[self atNewIndex: index 
				put: ((aDictionary associationAt: aKey) value: anObject).
			aDictionary removeKey: aKey]
		ifFalse: 
			[self atNewIndex: index put: (Association key: aKey value: anObject)].
	self flushClassNameCache! !

!SystemDictionary methodsFor: 'enumerating'!

{void} allBehaviorsDo: aBlock {BlockClosure of: Behavior}
	"Evaluate the argument, aBlock, for each kind of Behavior in the system
	(that is, Object and its subclasses)."

	Object withAllSubsAndMetasDo: aBlock!

allClassesDo: aBlock
	"Evaluate the argument, aBlock, for each class in the system."

	(self classNames collect: [:name | Smalltalk at: name]) do: aBlock!

classSearch: aBlock 
	"Evaluate the argument, aBlock, for each kind of Behavior in the system
	(that is, Object and its subclasses)."

	self allBehaviorsDo: aBlock!

pointersTo: anObject do: aBlock 
	"Evaluate the argument aBlock for each pointer to anObject in the 
	system. "

	^self quickPointersTo: anObject do: aBlock!

quickPointersTo: anObject do: aBlock
	"Evaluate the argument aBlock for each pointer to anObject in the system."

	| owner mine callers myBlock blocks me caller |
	me _ thisContext.
	mine _ me valueStack.
	caller _ me sender.
	callers _ caller valueStack.
	owner _ anObject firstOwner.
	myBlock _ nil.
	myBlock _
		[(owner == me 
			or: [owner == caller 
			or: [owner == myBlock
			or: [owner == mine 
			or: [owner == callers 
			or: [owner == blocks]]]]])
			ifFalse: [aBlock value: owner].
		 (owner _ anObject ownerAfter: owner) == nil].
	blocks _ myBlock valueStack.
	myBlock whileFalse.
	mine _ callers _ blocks _ nil "Break cycles"! !

!SystemDictionary methodsFor: 'browsing'!

{NOWAIT} browseAllCallsOn: aSymbol 
	"Create and schedule a message browser on each method that calls on 
	aSymbol."

	"For example, 
		Smalltalk browseAllCallsOn: #open:label:.	"

	(aSymbol isKindOf: Association)
		ifTrue: [(AssociationRefsFilter make: aSymbol) browse]
		ifFalse: [(SendersFilter make: aSymbol asSymbol) browse].!

browseAllCallsOn: literal1 and: literal2 
	"Create and schedule a message browser on each method that calls on the
	two Symbols, literal1 and literal2."

	"For example,
		Smalltalk browseAllCallsOn: #at: and: #at:pt:.	"

	BrowserView
		openListBrowserOn: (self allCallsOn: literal1 and: literal2)
		label: literal1 printString , literal2 printString
		initialSelection: literal1 asSymbol keywords first!

browseAllImplementorsOf: selector
	"Create and schedule a message browser on each method that implements the
	message whose selector is the argument, selector.
	For example,
		Smalltalk browseAllImplementorsOf: #at:put:.	"

	(ImplementorsFilter make: selector) browse!

browseAllImplementorsOf: selector {Symbol} startingAt: aClass {Behavior}
	"Create and schedule a message browser on each method that implements the
	message whose selector is the argument, selector.
	For example,"
		"Smalltalk browseAllImplementorsOf: #at:put: startingAt: Dictionary"

	((FromFamily make: aClass) filteredBy: (ImplementorsFilter make: selector)) browse!

browseAllSelect: aBlock
	"Create and schedule a message browser on each method that, when used as the
	block argument to aBlock gives a true result.
	For example,
		Smalltalk browseAllSelect: 
			[:method | 
			method numLiterals > 30]
	"

	(MethodFinder 
		make: [:cls {Behavior} :sel {Symbol} | 
			aBlock value: (cls compiledMethodAt: sel)]
		with: 'selected messages'
		with: nil)
			browse!

showMenuThenBrowse: selectorCollection
	"Show a menu of the given selectors, abbreviated to 40 characters.
	Create and schedule a message set browser of all implementors of the 
	message chosen.  Do nothing if no message is chosen."

	| menu selector |
	selectorCollection isEmpty ifTrue: [^Transcript cr; show: 'No messages sent.'].
	menu _ PopUpMenu fromArray: (selectorCollection collect: [:sel {Symbol} |
		Array with: (sel contractTo: 40) with: sel with: 'ST: Browse all implementors of this selector']). 
	selector _ menu startUp.
	selector ~= 0 ifTrue: [Smalltalk browseAllImplementorsOf: selector]! !

!SystemDictionary methodsFor: 'retrieving'!

allCallsOn: aLiteral 
	"Answer a SortedCollection of all the methods that call on aLiteral."

	| aSortedCollection |
	aSortedCollection _ SortedCollection new.
	Cursor execute showWhile: 
		[self allBehaviorsDo: 
			[:class |
			 (class whichSelectorsReferTowards: aLiteral) do: 
				[:sel | sel ~~ #DoIt
					ifTrue: [aSortedCollection add: class name , ' ' , sel]]]].
	^aSortedCollection!

allCallsOn: firstLiteral and: secondLiteral
	"Answer a SortedCollection of all the methods that call on both aLiteral and
	secondLiteral."

	| aCollection secondArray |
	aCollection _ SortedCollection new.
	Cursor execute showWhile:
		[self allBehaviorsDo:
			[:class |
			secondArray _ class whichSelectorsReferTowards: secondLiteral.
			(class whichSelectorsReferTowards: firstLiteral) do:
				[:sel | (secondArray includes: sel) ifTrue:
					[aCollection add: class name , ' ' , sel]]]].
	^aCollection!

allClassesImplementing: aSelector  
	"Answer an Array of all classes that implement the message aSelector."

	| aCollection |
	aCollection _ ReadWriteStream on: Array new.
	self allBehaviorsDo:
		[:class | (class includesSelector: aSelector)
			ifTrue: [aCollection nextPut: class]].
	^ aCollection contents!

allImplementorsOf: aSelector  
	"Answer a SortedCollection of all the methods that implement the message aSelector."

	| aCollection |
	aCollection _ SortedCollection new.
	Cursor execute showWhile:
		[self allBehaviorsDo:
			[:class |
			(class includesSelector: aSelector)
				ifTrue: [aCollection add: class name, ' ', aSelector]]].
	^aCollection!

allImplementorsOf: aSelector {ByteSymbol} startingAt: aClass {Behavior}
	"Answer a SortedCollection of all the methods that implement the message aSelector."

	| aCollection |
	aCollection _ SortedCollection new.
	Cursor execute showWhile:
		[aClass withAllSubclasses, aClass allSuperclasses do:
			[:class |
			(class isGenerated not and: [class includesSelector: aSelector])
				ifTrue: [aCollection add: class name, ' ', aSelector]]].
	^aCollection!

allSelect: aBlock 
	"Answer a SortedCollection of each method that, when used as the
	block argument to aBlock, gives a true result."

	| aCollection |
	aCollection _ SortedCollection new.
	Cursor execute showWhile: 
		[self allBehaviorsDo: 
			[:class | class methodsDo:
				[:sel {Symbol} :code {CompiledMethod} | (aBlock value: code)
					ifTrue: [aCollection add: class name , ' ' , sel]]]].
	^aCollection!

collectPointersTo: anObject 
	"Answer an Array of all occurrences in the system of pointers to the argument
	anObject."

	"(Smalltalk collectPointersTo: Browser) inspect."

	| some me |
	some _ OrderedCollection new.
	me _ thisContext.
	self pointersTo: anObject do:
		[:obj | (obj ~~ me) & (obj ~~ some) ifTrue: [some add: obj]].
	me _ nil. "to avoid circularity"
	^some asArray! !

!SystemDictionary methodsFor: 'class names'!

classNames
	"Answer a SortedCollection of all class names.  Use cached copy if available."

	CachedClassNames == nil ifTrue: [^self newClassNames].
	^CachedClassNames!

flushClassNameCache
	"Invalidate cached copy of classnames (see classNames)"

	CachedClassNames _ nil!

newClassNames
	"Compute a sorted collection of class names and cache it for efficiency."

	| names |
	names _ OrderedCollection new: self size.
	self do: 
		[:cl | (cl isBehavior) ifTrue: [names add: cl name]].
	^CachedClassNames _ names asSortedCollection! !

!SystemDictionary methodsFor: 'compiling'!

recompileAllFrom: firstName 
	"Recompile all classes, starting with given name."

	"Smalltalk recompileAllFrom: 'Aardvark'."

	Smalltalk forgetDoIts.
	self allClassesDo: 
		[:class | class name >= firstName
			ifTrue: 
				[Transcript show: class name; cr.
				class compileAll]]!

recompileAllFrom: firstName to: lastName
	"Recompile all classes, starting with given name."

	"Smalltalk recompileAllFrom: 'Cxx' to: 'D'."

	Smalltalk forgetDoIts.
	self allClassesDo: 
		[:class | (class name >= firstName and: [class name < lastName])
			ifTrue: 
				[Transcript show: class name; cr.
				class compileAll]]!

recompileCallsOn: aLiteral 
	"Recompile every message in the system that refers to aLiteral."

	Cursor execute showWhile: 
		[self allBehaviorsDo: 
			[:class | (class whichSelectorsReferTo: aLiteral)
				do: [:sel | sel ~~ #DoIt ifTrue: [class recompile: sel]]]]!

recompileMethodsForWhich: aBlock 
	"Recompile all methods in the system for which aBlock evaluates to true."

	"For example,
		Smalltalk recompileMethodsForWhich: [:meth | meth size=6]"

	Cursor execute showWhile: 
		[self allBehaviorsDo: 
			[:class | class methodsDo: [:sel {Symbol} :code {CompiledMethod} | 
				(aBlock value: code)
					ifTrue: 
						[Transcript show: class name , ' ' , sel; cr.
						class recompile: sel]]]]! !

!SystemDictionary methodsFor: 'change management'!

changes
	"Answer the current system ChangeSet."

	^SystemChanges!

logChange: aStringOrText
	"Write the argument, a String or Text, onto the changes
file."

	| aString |
	SourceFiles == nil
		ifTrue: [^self].
	(aStringOrText isMemberOf: Text)
		ifTrue: [aString _ aStringOrText string]
		ifFalse: [aString _ aStringOrText].
	aString isString
		ifFalse: [self error: 'cant log this change'].
	(aString findFirst: [:aChar | aChar isSeparator not]) = 0
		ifTrue: [^self].  "null doits confuse replay"
	Object errorSignal
		handle: [:ex |
				Transcript cr;
					nextPutAll: 'Caught error "';
					print: ex errorString;
					nextPutAll: '" when logging to changes file; entry
not logged.';
					endEntry.
				ex return]
		do: [| aFileStream |
			aFileStream _ SourceFiles at: 2.
			aFileStream cr; cr; nextChunkPut: aString.
			aFileStream commit].!

newChanges: aChangeSet 
	"Set the system ChangeSet to be aChangeSet."

	SystemChanges _ aChangeSet!

noChanges 
	"Initialize the system ChangeSet."

	SystemChanges initialize!

recover: nCharacters
	"Schedule an editable text view on the last n characters of changes."

	| changes numberToSkip stream fileName|
	changes _ SourceFiles at: 2.
	numberToSkip _ nCharacters min: changes size.
	changes setToEnd; skip: numberToSkip negated.
	fileName _ (Filename named: 'st80.recent').
	stream _ fileName writeStream.
	[stream nextPutAll: changes]
		valueNowOrOnUnwindDo: [stream close].
	fileName edit!

removeClassNamed: className 
	"Remove the class with the name className, and all of its 
	subclasses, 
	from the system, and note the removal in the system
ChangeSet."

	| class |
	class _ self at: className asSymbol ifAbsent: [^self].
	"remove subclasses first"
	class subclasses do: [:subclass | self removeClassNamed:
subclass name].
	ChangeLog log: #remove class: class changes: class name ,
' removeFromSystem'.
	"SystemChanges removeClass: class."
	SystemOrganization removeElement: className.
	((Smalltalk includesKey: #CxxSystemOrganization)
		and: [CxxSystemOrganization ~~ nil])
		ifTrue: [CxxSystemOrganization removeClassNamed:
className].
	self removeKey: className asSymbol.
	self flushClassNameCache.
	class obsolete!

renameClass: aClass as: newName 
	"Rename the class, aClass, to have the title newName."

	| oldref oldkey |
	SystemOrganization classify: newName under: aClass category.
	SystemOrganization removeElement: aClass name.
	"SystemChanges renameClass: aClass from: aClass name to: newName."
	oldref _ self associationAt: aClass name.
	oldkey _ oldref key.
	self removeKey: aClass name.
	oldref key: newName.
	(Undeclared includesKey: newName)
		ifTrue: [self at: newName put: aClass]
		ifFalse: [self add: oldref "Preserve old reference"].
	"ChangeLog logRenameClass: aClass to: oldkey
		changes: aClass name,' rename: ', newName storeString."
	self flushClassNameCache! !

!SystemDictionary methodsFor: 'memory space'!

core
	"Answer an Array containing the number of objects in the system 
	and the number of bytes they occupy. This is implementation 
	dependent."
	"Smalltalk core"

	| nobjects nbytes object class |
	nobjects _ nbytes _ 0.
	object _ Object someObject.
	[(class _ object class) == SmallInteger]
		whileFalse: 
			[nobjects _ nobjects + 1.
			nbytes _ nbytes + 16.
			class isBits
				ifTrue: [nbytes _ nbytes + (object basicSize + 3 bitAnd: -4)]
				ifFalse: 
					[nbytes _ nbytes + (class instSize * 4).
					class isVariable ifTrue: [nbytes _ nbytes + (object basicSize * 4)]].
			object _ object nextObject].
	^Array with: nobjects with: nbytes!

coreLeft
	"Answer the number of unallocated bytes in the object space.  Essential.  
	See Object documentation whatIsAPrimitive."

	<primitive: 112>
	self primitiveFailed!

coreLeftLimit
	"Answer the threshold at which the user is to be notified
	that the system is low in core space."

	^BytesLeftLimit!

coreLeftLimit: newLimit 
	"Set newLimit to be the threshold at which the user is to be notified
	that the system is low in core space."

	BytesLeftLimit _ newLimit.
	self resetLowSpaceSignal.
	^newLimit!

frills
	"Answer whether the current Smalltalk is willing to work harder - 
	on slow machines, you may want to set Smalltalk frills: false"

	^Frills!

frills: aBoolean 
	"Set to true for more functionality on fast machines - 
	but on slow machines, you may want to set Smalltalk frills: false."

	^Frills _ aBoolean!

garbageCollect
	"Do a mark and sweep garbage collection of the entire Smalltalk system, eliminating any unreferencable objects.
	Smalltalk garbageCollect "

	| time startCore result endCore |
	Cursor garbage showWhile:
		[Transcript cr; show: 'Garbage collecting system (please wait)...'.
		time _ Time millisecondsToRun:
			[startCore _ self coreLeft.
			result _ self primGarbageCollect.
			endCore _ self coreLeft].		"note LargeInteger variables takes up oops and space"
		result isNil ifTrue: [Transcript cr; nextPutAll: '[Note: GC primitive not implemented]'].
		self resetSpaceLimitsIfHigher.
		Transcript
			cr; nextPutAll: 'reclaimed ';
			print: (endCore - startCore max: 0); nextPutAll: ' bytes in ';
			print: time//100/10.0; nextPutAll: ' sec.';
			cr; print: endCore; nextPutAll: ' free bytes.';
			cr; endEntry].!

initializeSpaceLimits
	"Initializes threshold on the number of oops and the core space at which
	point the user should be notified."

	OopsLeftLimit _ (self oopsLeft // 4) max: 10000.
	BytesLeftLimit _ (self coreLeft // 4) max: 100000.
	self resetLowSpaceSignal!

oopsLeft
	"Answer the number of unallocated object pointers in the object 
	table.  Equal to the net number of objects which can be created before the 
	object table is full.  Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 115>
	self primitiveFailed!

oopsLeftLimit
	"Answer the threshold at which the user is to be notified
	that the system is low in number of oops."

	^OopsLeftLimit!

oopsLeftLimit: newLimit 
	"Set newLimit to be the threshold at which the user is to be notified
	that the system is low in number of oops."

	OopsLeftLimit _ newLimit.
	self resetLowSpaceSignal.
	^newLimit!

primGarbageCollect
	"Do a mark and sweep garbage collection of the entire system, 
	eliminating all unreferencable objects. Takes approximately several 
	seconds even on fast hosts.  Answer the number of objects that 
	were marked during the collection. ie: The number of referencable 
	objects in the system at that time.  If not implemented, answer nil. 
	Optional. See also documentation in Object metaclass."

	<primitive: 138>
	^nil!

resetLowSpaceSignal
	"The thresholds for notifying the user the space is low have changed so
	update the system."

	self signal: LowSpaceSemaphore
		atOopsLeft: OopsLeftLimit
		bytesLeft: BytesLeftLimit!

resetSpaceLimits
	"Reset the threshold on the number of oops and the core space at which
	point the user should be notified."

	OopsLeftLimit _ self oopsLeft // 4.
	BytesLeftLimit _ self coreLeft // 4.
	self resetLowSpaceSignal!

resetSpaceLimitsIfHigher
	"Reset the threshold on the number of oops and the core space at which
	point the user should be notified, but only do so if the resulting limits will
	be higher than before."

	OopsLeftLimit _ OopsLeftLimit max: self oopsLeft // 4.
	BytesLeftLimit _ BytesLeftLimit max: self coreLeft // 4.
	self resetLowSpaceSignal!

signal: aSemaphore atOopsLeft: numOops bytesLeft: numWords 
	"Tell the object memory to signal the Semaphore when either the number 
	 of object pointers remaining drops below numOops, or the number of  
	bytes in the object space remaining drops below numWords.  Fail if the  
	frist argument is neither a Semaphore nor nil.  Fail if numOops is not a 
	16-bit Integer, or if numWords is not a 32-bit LargePositiveInteger.  
	Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 116>
	self primitiveFailed! !

!SystemDictionary methodsFor: 'special selectors'!

specialNargsAt: anInteger 
	"Answer the number of arguments for the special selector at anInteger."

	^SpecialSelectors at: anInteger * 2!

specialSelectorAt: anInteger 
	"Answer the special message selector stored at location anInteger in the
	system dictionary."

	^SpecialSelectors at: anInteger * 2 - 1!

specialSelectorIndexOf: aSelector
	"Answer the special selector index of aSelector.
	If aSelector is not a special selector, answer 0."
	^SpecialSelectorDictionary at: aSelector ifAbsent: [0]!

{Set of: Symbol} specialSelectorSet
	
	
	^SpecialSelectorDictionary keys!

specialSelectorSize
	"Answer the number of special selectors in the system."

	^SpecialSelectors size // 2! !

!SystemDictionary methodsFor: 'system backup/out'!

copyChangesTo: newFileName 
	"If the file name supplied is different than the current changes 
	file name, copy the changes file and install the new copy as the 
	changes file."

	| oldName newFile |
	newFile _ newFileName asFilename.
	SourceFiles == nil ifTrue: [^self].
	oldName _ (SourceFiles at: 2) name.
	oldName last = $. ifTrue: [oldName _ oldName copyFrom: 1 to: oldName size - 1].
	(newFile asString sameAs: oldName asFilename asString)
		ifFalse: 
			[(SourceFiles at: 2) close.
			oldName asFilename exists
				ifTrue: [Transcript cr; show: 'Copying ' , oldName , ' to ' , newFile asString , '...'.
						Cursor write
							showWhile: [oldName asFilename copyTo: newFile].
						SourceFiles
							at: 2
							put: newFile readAppendStream.
						Transcript show: ' done'; cr]
				ifFalse: [SourceFiles
							at: 2
							put: newFile readAppendStream]]!

currentImagePrefix
	"Return the current Image prefix"

	^ImagePrefix!

getImagePrefix
	"Prompt the user for a snapshot file name.  Persist until a legal name is supplied."

	| default prompt index |
	prompt _ 'Enter name for image file:'.
	
	SourceFiles == nil
		ifTrue: [default _ ImagePrefix]
		ifFalse:
			[default _ (SourceFiles at: 2) name.
			index _ default findLast: [:ch | ch = $.].
			default _ index = 0 
				ifTrue: [default]
				ifFalse: [default copyFrom: 1 to: index-1]].
	ImagePrefix _ default.
	^FillInTheBlank
		request: prompt
		initialAnswer: default!

quit
	"Close open files then exit to another operating system on the host machine, 
	if one exists.  All state changes in the object space since the last snapshot are lost."

	self commitExternalViews.
	self changed: #aboutToQuit.
	self quitPrimitive!

saveAs: imagePrefix thenQuit: quitIfTrue
	"Copy the changes file to the new name if necessary, then create 
	a matching image file.  Answer true if the image file was just created."

	SourceFiles == nil
		ifFalse:
			[(imagePrefix sameAs: 'snapshot')
				ifFalse: [self copyChangesTo: imagePrefix, Filename changeExtension.
					ChangeLog copyLogTo: imagePrefix, Filename logExtension]].
	^self snapshotAs: imagePrefix thenQuit: quitIfTrue!

shutdown
	"Shut off the low space signal so that the Vmem writer can be sure the 
	system is stable while it is tracing."

	self coreLeftLimit: 0.
	self oopsLeftLimit: 0!

snapshot
	"Write the OT and Data of this Smalltalk out on the external file <ImagePrefix>.im."

	self snapshotAs: ImagePrefix thenQuit: false!

snapshotAs: imageFilePrefix thenQuit: quitIfTrue
	"Write the OT and Data of this Smalltalk out on an
external file.  Answer true if the snapshot was just
created."

	| fName justSnapped msg |
	"((Smalltalk includesKey: #Initializer) and: [Initializer
isBehavior])
		ifTrue: [Initializer cleanup.
			DependentsFields isEmpty not 
				ifTrue: [DependentsFields _ DependentsDictionary new]]."
	ImagePrefix _ imageFilePrefix.
	fName _ (imageFilePrefix, Filename imageExtension)
asFilename.
	fName canBeWritten
		ifFalse: [^self error: 'snapshot file can not be written
'].
	Cursor execute show.
	msg _ fName asString, ' created at ', Time dateAndTimeNow
printString.
	ChangeLog logCheckpoint: #save changes:
'''----SNAPSHOT----''!!

"' , msg , '"'.
	Transcript cr; show: msg.
	self preSnapshot.
	self class snapshotFailedSignal
		handle: [ :ex |
				self postSnapshot.
				self class snapshotFailedSignal raise.
				^true]
		do: [justSnapped _ self snapshotAsPrimitive: fName
asString.
			justSnapped == nil
				ifTrue: [quitIfTrue ifTrue: [self quitPrimitive].
						self postSnapshot]
				ifFalse: [self returnFromSnapshot]].
	^justSnapped == nil!

suspend
	"Allow the system to prepare for a Suspend and resume with proper states."

	self changed: #aboutToSuspend.
	self commitExternalViews.
	self suspendPrimitive.
	self changed: #returnFromSuspend! !

!SystemDictionary methodsFor: 'time/versions'!

copyright
	"The Objectworks for Smalltalk-80(tm) copyright.
			Copyright (c) 1988, 1989 ParcPlace Systems, Inc.  All Rights Reserved.
	"

	^'Copyright (c) 1988, 1989 ParcPlace Systems, Inc.  All Rights Reserved.'!

timeStamp: aStream 
	"Write the system version and current time on stream aStream."

	| dateTime |
	dateTime _ Time dateAndTimeNow.
	aStream nextPutAll: 'From ', Smalltalk version, ' on ', (dateTime at: 1) printString,
						' at ', (dateTime at: 2) printString!

version
	"Answer the version of this release."

	^'Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989'!

versionName
	"Answer the version identification, e.g. Objectworks for Smalltalk-80(tm)"

	^'Objectworks for Smalltalk-80(tm)'! !

!SystemDictionary methodsFor: 'system compression'!

condenseChanges
	"Move all the changes onto a compacted sources file.
	Because this gets the changes file out of synch with any stored image
	file, the user is asked whether to snapshot now."
	
	"Smalltalk condenseChanges."

	| f fileName |
	f _ (Filename named: 'temp', Filename changeExtension) writeStream.
	[f timeStamp.
	Smalltalk allBehaviorsDo: [:class | class moveChangesTo: f]]
		valueNowOrOnUnwindDo: [f close].
	fileName _ (SourceFiles at: 2) name.
	(SourceFiles at: 2) close.
	(Filename named: fileName) delete.
	(Filename named: 'temp', Filename changeExtension) renameTo: fileName.
	SourceFiles at: 2 put: (Filename named: fileName) readAppendStream.
	ChangeRecorder newChangeLog.
	(BinaryChoice message: 
	'You must snapshot to be sure your image file 
	is in sync with the new changes file.
		Do you want to snapshot now?')
		ifTrue: 
			[| prefix |
			prefix _ self getImagePrefix.
			prefix isEmpty ifFalse: [self saveAs: prefix thenQuit: false]]!

condenseChangesOntoSources
	"Move all the changes onto the end of the sources file."
	
	"Smalltalk condenseChangesOntoSources."

	| f fileName |
	SourceFiles first close.
	f _ (Filename named: SourceFiles first name) appendStream lineEndTransparent.
	[Smalltalk allBehaviorsDo: 
			[:class | 
			| changes |
			class organization moveChangedCommentToFile: f numbered: 1.
			changes _ class selectors select: [:sel | (class compiledMethodAt: sel) fileIndex > 1].
			class
				fileOutChangedMessages: changes
				on: f
				moveSource: true
				toFile: 1]]
		valueNowOrOnUnwindDo: [f close].
	fileName _ (SourceFiles at: 2) name.
	(SourceFiles at: 2) close.
	(Filename named: fileName) delete.
	SourceFiles at: 2 put: (Filename named: fileName) readAppendStream.
	ChangeRecorder newChangeLog.
	(BinaryChoice message: 
	'You must snapshot to be sure your image file 
	is in sync with the new changes file.
		Do you want to snapshot now?')
		ifTrue: 
			[| prefix |
			prefix _ self getImagePrefix.
			prefix isEmpty ifFalse: [self saveAs: prefix thenQuit: false]]!

forgetDoIts
	"get rid of old DoIt methods"

	"Smalltalk forgetDoIts"

	Smalltalk allBehaviorsDo: 
		[:class |
		class removeSelectorSimply: #DoIt;
		removeSelectorSimply: #DoItIn:]!

newSourceFile: vers
	"Make a new source file"

	self newSourceFile: vers without: (Array new)!

newSourceFile: vers without: setOfClasses 
	"Make a new source file omitting references to any classes in the set, setOfClasses.

		Smalltalk newSourceFile: Smalltalk versionName without: (Array new).

	Make sure versionName is updated.
	Then rename the image similarly."

	| oldFile newFile class newName|
	oldFile _ SourceFiles at: 1.
	newName _ vers , Filename sourceExtension.
	oldFile name = newName ifTrue: [self error: 'Do not overwrite the current source file!!'].
	newFile _ newName asFilename writeStream lineEndTransparent.
	[newFile nextChunkPut: self copyright printString; cr; cr.
	newFile timeStamp.
	Smalltalk classNames do: 
		[:className | 
		class _ Smalltalk at: className.
		(setOfClasses includes: class)
			ifFalse: 
				[class
					fileOutOn: newFile
					moveSource: true
					toFile: 1.
				newFile nextPut: Character newPage]]
	] valueNowOrOnUnwindDo: [newFile close].
	(SourceFiles at: 1) close.
	(SourceFiles at: 2) close.
	SourceFiles at: 1 put: newName asFilename readStream lineEndTransparent.
	SourceFiles at: 2 put: (vers , Filename changeExtension) asFilename readAppendStream.!

renameSystemFiles: newVersion 
	"Rename the sources and changes and image files."
	"Smalltalk renameSystemFiles: Smalltalk versionName."

	| name |
	(SourceFiles at: 1) close.
	(SourceFiles at: 1) name asFilename
		renameTo: (name _ (newVersion , Filename sourceExtension) asFilename).
	SourceFiles at: 1 put: name readStream lineEndTransparent.
	(SourceFiles at: 2) close.
	(SourceFiles at: 2) name asFilename
		renameTo: (name _ (newVersion , Filename changeExtension) asFilename).
	SourceFiles at: 2 put: name readAppendStream! !

!SystemDictionary methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	"Intercepted to avoid infinite recursion when #Smalltalk is reached."

	| tooMany |
	tooMany _ aStream position + self maxPrint.
	aStream nextPutAll: self class name, ' keys ('.
	self keysDo: 
		[:key | 
		aStream position > tooMany ifTrue: [aStream nextPutAll: '...etc...)'. ^self].
		key printOn: aStream.
		aStream space].
	aStream nextPut: $)! !

!SystemDictionary methodsFor: 'private: private'!

commitExternalViews 
	FileDirectory commitExternalReferences!

evaluateAndRemember: doItString
	Compiler evaluate: doItString.
	ChangeLog logDoItChanges: 'Smalltalk evaluateAndRemember: ' ,
		doItString storeString.
	"self changes addDoIt: 'Smalltalk evaluateAndRemember: ' ,
		doItString storeString"!

exitToDebugger
	"Enter the machine language debugger, if one exists.  Essential.  See Object 
	documentation whatIsAPrimitive. "

	<primitive: 114>
	self primitiveFailed!

getFileNamePrefixFor: aName

	| index | 
	1 to: aName size do: [:i | (aName at: i) == $. ifTrue: [index _ i]].
	^index == nil 
			ifTrue: [aName]
			ifFalse: [aName copyFrom: 1 to: index - 1]!

lowSpaceNotificationLoop

	[LowSpaceSemaphore wait.
	ControlManager interruptLockedSignal
		handle: [:ex |
				(Delay forMilliseconds: 200) wait.
				ex restart]
		do:	[ScheduledControllers interruptName:
'Space warning
	bytes left: ', self coreLeft printString].
	self resetSpaceLimits]
			repeat!

quitPrimitive
	"Exit to another operating system on the host machine, if one exists.  All 
	state changes in the object space since the last snapshot are lost.  Essential.  
	See Object documentation whatIsAPrimitive."

	<primitive: 113>
	self primitiveFailed!

releaseExternalViews 
	FileDirectory releaseExternalReferences!

snapshotAsPrimitive: fileName
	"Write the current state of the object memory on a file in the same format as 
	the Smalltalk-80 release.  The file can later be resumed, returning you to 
	this exact state.  Return normally after writing the file.  Essential.  See 
	Object documentation whatIsAPrimitive."

	<primitive: 533>
	^self class snapshotFailedSignal raise!

snapshotPrimitive
	"Write the current state of the object memory on a file in the same format as 
	the Smalltalk-80 release.  The file can later be resumed, returning you to 
	this exact state.  Return normally after writing the file.  Essential.  See 
	Object documentation whatIsAPrimitive."

	<primitive: 97>
	^#primitiveFailed!

specialSelectors
	"Used by SystemTracer only"

	^SpecialSelectors!

suspendPrimitive
	"Pause Smalltalk, and return to the host operating system in such a way
	as to permit resumption at a later time.  Optional."

	<primitive: 163>
	self primitiveFailed! !

!SystemDictionary methodsFor: 'copying'!

copy
	"Normally answers a copy of the receiver, but since the SystemDictionary is
	unique, answer self."

	^self!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. This doesn't make sense for the SystemDictionary."

	^self deepCopyError! !

!SystemDictionary methodsFor: 'smalltalk: passe'!

allImplementedMessages
	"Answer a Set of all the messages that are
	implemented by some class."
	"Smalltalk allImplementedMessages size"

	self passe!

{Set of: Symbol} allSentMessages
	"The Set of all selectors sent by someone"
	"Smalltalk allSentMessages size"
	
	self passe.!

{Set of: Symbol} allUnusedMessages
	"The Set of all selectors implemented by someone but used by no one"
	"Smalltalk allUnusedMessages size"
	
	self passe!

{Set of: Symbol} allUsedLiteralSymbols
	"The Set of all selectors sent by someone"
	"Smalltalk allUsedLiteralSymbols size"
	
	self passe.!

{Set of: Symbol} staleImplementedMessages

	self passe!

{Set of: Symbol} staleUnimplementedMessages
 
	self passe!

{Set of: Symbol} staleUnusedMessages
 
	self passe!

{Set of: Symbol} staleUsedAndImplementedMessages

	self passe!

{Set of: Symbol} staleUsedMessages

	self passe!

{Set of: Symbol} staleUsedOrImplementedMessages

	self passe!

{void} updateMessageCache
	"Smalltalk updateMessageCache"
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SystemDictionary class
	instanceVariableNames: ''!



!SystemDictionary class methodsFor: 'class initialization'!

initialize
	ImagePrefix _ 'snapshot'.
	"SystemDictionary initialize"!

initializeSignal
	"Set up the snapshot failure signal."

	SnapshotErrorSignal _ (Object errorSignal newSignalMayProceed: false)
		notifierString: 'Snapshot primitive failed';
		nameClass: self message: #snapshotFailedSignal
	"SystemDictionary initializeSignal"! !

!SystemDictionary class methodsFor: 'Signal constants'!

snapshotFailedSignal

	^SnapshotErrorSignal! !

!SystemDictionary class methodsFor: 'searching'! !

SystemDictionary initialize!
