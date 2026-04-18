IdentityDictionary variableSubclass: #DependentsDictionary
	instanceVariableNames: 'length fullTally '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Support'!
DependentsDictionary comment:
'A DependentsDictionary holds the dependents for objects that are the keys of the instance.  The values are either the sole dependent of an object or a DependentsCollection of dependents.

Instance Variables:
	length		<SmallInteger>   the basicSize of the instance 
	fullTally	<SmallInteger>   the amount the instance can hold before growing is necessary 
'!


!DependentsDictionary methodsFor: 'access'!

at: anObject add: aDependentObject
	"Add aDependentObject to anObject's dependents."

	| deps indx obj |
	indx _ self findKeyOrNil: anObject.
	(obj _ self basicAt: indx) == nil
		ifTrue:
			[tally _ tally + 1.
			self basicAt: indx put: anObject.
			deps _ aDependentObject]
		ifFalse:
			[deps _ (valueArray at: indx) asDependentsWith: aDependentObject].
	valueArray at: indx put: deps.
	obj == nil ifTrue: [self fullCheck].
	^aDependentObject!

at: anObject remove: aDependentObject
	"Remove aDependentObject from anObject's dependents."

	| deps indx |
	indx _ self findKeyOrNil: anObject.
	(self basicAt: indx) == nil
		ifTrue: [^aDependentObject].
	deps _ (valueArray at: indx) asDependentsWithout: aDependentObject.
	deps == nil
		ifTrue:
			[self removeAndCleanUpAtIndex: indx.
			^aDependentObject].
	valueArray at: indx put: deps.
	^aDependentObject!

atOrNil: anObject
	"Answer a nil, singleton, or DependentsCollection of the objects that are dependent on the receiver, that is, the objects that should be notified if the receiver changes."

	"^self at: anObject ifAbsent: [nil]"

	| index probe start |
	index _ anObject identityHash \\ length + 1.
	start _ index.
	[(probe _ self basicAt: index) == nil
		ifTrue: [^nil].
	probe == anObject
		ifTrue: [^valueArray at: index].
	(index _ index + 1) <= length] whileTrue.
	index _ 1.
	[(probe _ self basicAt: index) == nil
		ifTrue: [^nil].
	probe == anObject
		ifTrue: [^valueArray at: index].
	(index _ index + 1) < start] whileTrue.
	^nil!

collectionAt: anObject
	"Answer a Collection of the objects that are dependent on the receiver, that is, the objects that should be notified if the receiver changes."

	| index probe start |
	index _ anObject identityHash \\ length + 1.
	start _ index.
	[(probe _ self basicAt: index) == nil ifTrue: [^#()].
	probe == anObject
		ifTrue: [^(valueArray at: index) asDependentsAsCollection].
	(index _ index + 1) <= length] whileTrue.
	index _ 1.
	[(probe _ self basicAt: index) == nil ifTrue: [^#()].
	probe == anObject
		ifTrue: [^(valueArray at: index) asDependentsAsCollection].
	(index _ index + 1) < start] whileTrue.
	^#()!

removeKeyNoError: anObject
	"Remove anObject as a key from the receiver."

	self removeKey: anObject ifAbsent: []! !

!DependentsDictionary methodsFor: 'private: private'!

findKeyOrNil: key 
	"Look for the key in the receiver.  If it is found, answer the index of 
	the key, otherwise answer the index of the first unused slot."

	| index probe pass |
	pass _ 1.
	index _ key identityHash \\ length + 1.
	[(probe _ self basicAt: index) == nil or: [probe == key]]
		whileFalse: [(index _ index + 1) > length
				ifTrue: 
					[index _ 1.
					pass _ pass + 1.
					pass > 2 ifTrue: [^self grow findKeyOrNil: key]]].
	^index!

fullCheck
	"Check the receiver to see if growing is necessary."

	tally >= fullTally
		ifTrue: [self grow]!

setTally
	"Initialize tally and other instance variables."

	super setTally.
	length _ self basicSize.
	fullTally _ length - (length // 4)! !

Magnitude subclass: #MessageTally
	instanceVariableNames: 'class method tally receivers '
	classVariableNames: 'HowOften ObservedProcess RootTally TargetBlock Timer '
	poolDictionaries: ''
	category: 'System-Support'!
MessageTally comment:
'A MessageTally represents nodes in a tree that gathers statistics on the time spent in various parts of the system.  Specifically, each node represents a message being sent.  During the evaluation of an expression, a timer periodically interrupts the execution of the various methods involved, and tallies these probes in the tree of MessageTallies which it constructs.  When evaluation of the expression is complete, a detailed report is produced indicating where in the system most of the time was spent.  See the comment for spyOn: in MessageTally class for an example of how to use the spy.  MessageTallies may be taken on only one block at a time.  Spying on two blocks at once does not work.  The block upon which the MessageTally is spying can be stopped and started.  See spyEvery:on:.

Instance Variables:
	class		<Behavior> the class of the receiver of the message
	method		<CompiledMethod> which was running when probe occurred
	tally		<Integer> number of probes which hit this method or others
				called by it
	receivers	<Array> of MessageTally; sons of this node in the tree,
				representing tallies of methods called from this one.
				If this field is nil, it indicates tallies due to in-line primitives

Class Variables:
	HowOften			<Integer> when to take a look>
	ObservedProcess	<Process>
	TargetBlock		<Block>
	Timer 				<Process>
	RootTally			<MessageTally>'!


!MessageTally methodsFor: 'initialize-release'!

close 
	(Timer isMemberOf: Process) ifTrue: [Timer terminate].
	Timer _ ObservedProcess _ TargetBlock _ RootTally _ nil.
	class _ method _ tally _ receivers  _ nil!

continueSpying
	| myDelay value active |
	myDelay _ Delay forMilliseconds: HowOften.
	active _ true.
	Timer _
		[[active] whileTrue: 
			[myDelay wait.
			active ifTrue: [self tally: ObservedProcess suspendedContext]].
		nil] newProcess.
	Timer priority: Processor userInterruptPriority.
		"activate the probe and evaluate the block"
	Timer resume.
	[value _ TargetBlock value] valueNowOrOnUnwindDo: 
		[active _ false
		"Timer will fire once more, not tally, and terminate itself"].
	^value  "return the block's value"!

defaultInterval 
	"Answer the number of ticks between sampling."

	Smalltalk frills ifTrue: [^16] ifFalse: [^60]!

reportOn: aStream
	"Default cutoff percentage is 2%."

	self reportOn: aStream cutoff: 2!

reportOn: aStream cutoff: perCent 
	"Print a report on the stream. perCent should be a number like 2 or 3"

	tally = 0
		ifTrue:
			[aStream nextPutAll: ' - no tallies obtained']
		ifFalse:
			[aStream nextPutAll: ' - '; print: tally; nextPutAll: ' tallies.'; cr; cr.
			self fullPrintOn: aStream cutoff: perCent]!

spyEvery: millisecs on: aBlock 
	"Create a spy on the given block at the specified rate.  Don't run it yet"

"Set a block up for spying, and accumulate the tallies from several executions
	| spy |
	spy _ MessageTally new.
	spy spyEvery: spy defaultInterval on: 
		['this block contains your code'. 30 factorial].
	10 timesRepeat: [spy continueSpying].
	spy report: 'spy.results'.  spy close.
	(FileStream fileNamed: 'spy.results') edit.

If there are no tallies reported, the block executes faster than the delay"


	(aBlock isMemberOf: BlockClosure)
		ifFalse: [self error: 'spy needs a block here'].
	self class: aBlock class method: aBlock method.
		"set up the probe"
	ObservedProcess _ Processor activeProcess.
	RootTally _ self.
	HowOften _ millisecs.
	TargetBlock _ aBlock!

spyOn: aBlock
	"Spy on the evaluation of aBlock.  Browse the results in a workspace."

	| val reportStream |
	["Set up the block"
	self spyEvery: self defaultInterval on: aBlock.
	"Run the block and take the tallies"
	val _ self continueSpying.
	"Report it"
	reportStream _ WriteStream on: (String new: 5000).
	self reportOn: reportStream.
	] valueNowOrOnUnwindDo: [self close].
	StringHolderView
		open: (StringHolder new contents: reportStream contents)
		label: 'Spy Results'.
	^val  "Never gets returned due to window scheduling"!

spyOn: aBlock to: fileName
	"Spy on the evaluation of aBlock.  Write the data collected on a file named fileName."

	| val aFileStream |
		"Set up the block"
	[self spyEvery: 1 on: aBlock.
		"Run the block and take the tallies"
	val _ self continueSpying.
		"Report it"
	aFileStream _ (Filename named: fileName) writeStream.
	[aFileStream timeStamp; nextPutAll: fileName; space.
	self reportOn: aFileStream.
	self close]
		valueNowOrOnUnwindDo: [aFileStream close].
	] valueNowOrOnUnwindDo: [self close].
	^val! !

!MessageTally methodsFor: 'comparing'!

< aMessageTally 
	"Answer whether the receiver is less than the argument."

	^tally > aMessageTally tally!

= aMessageTally 
	"Answer whether the receiver is equal to the argument."

	^aMessageTally method == method!

> aMessageTally 
	"Answer whether the receiver is greater than the argument."

	^tally < aMessageTally tally!

hash
	"Answer with a SmallInteger unique to the receiver."

	^method identityHash!

sonsOver: threshold
	| hereTally last sons |
	(receivers == nil or: [receivers size = 0]) ifTrue: [^#()].
	hereTally _ tally.
	sons _ receivers select:  "subtract subNode tallies for primitive hits here"
		[:son |
		hereTally _ hereTally - son tally.
		son tally > threshold].
	hereTally > threshold
		ifTrue: 
			[last _ MessageTally new class: class method: method.
			^sons copyWith: (last primitives: hereTally)].
	^sons! !

!MessageTally methodsFor: 'tallying'!

bump
	tally _ tally + 1!

tally: context 
	"Explicitly tally the specified context and its stack."

	| root |
	context method == method ifTrue: [^self bump].
	(root _ context sender) == nil ifTrue: [^self bump tallyPath: context].
	^(self tally: root) tallyPath: context!

tallyPath: context 

	| aMethod  index length path|
	aMethod _ context method.
	index _ 1.
	length _ receivers size.
	[index <= length] whileTrue:
		[path _ receivers at: index.
		path method == aMethod ifTrue: [^path bump].
		index _ index + 1].
	path _ self class new
				class: context receiver class
				method: aMethod.
	receivers _ receivers copyWith: path.
	^path bump! !

!MessageTally methodsFor: 'collecting leaves'!

bump: anInteger 
	tally _ tally + anInteger!

into: aDictionary 
	| aMessageTally index |
	index _ 
		aDictionary 
			find: self
			ifAbsent: 
				[aDictionary add: 
					(aMessageTally _ MessageTally new class: class method: method).
				^aMessageTally bump: tally].
	(aDictionary basicAt: index) bump: tally!

leaves: leafDictionary 
	| aBreakDown |
	aBreakDown _ self sonsOver: 0.
	aBreakDown size = 0
		ifTrue: 
			[self into: leafDictionary]
		ifFalse: 
			[aBreakDown do: [:aMessageTally | aMessageTally leaves: leafDictionary]]!

totals: dict 
	| aTally newTally |
	aTally _ dict at: method ifAbsent: 
		[dict at: method put: (MessageTally new class: class method: method)].
	newTally _ aTally tally + tally.
	(receivers ~~ nil and: [receivers size > 0])
		ifTrue: [receivers do: [:aMessageTally | aMessageTally totals: dict]].
	aTally setTally: newTally!

totals: dict from: caller
	| tallyAndCallers callerTally newTally newCallerTally |
	tallyAndCallers _ dict at: method ifAbsent: 
		[dict at: method put: ((MessageTally new class: class method: method)
			-> IdentityDictionary new)].
	newTally _ tallyAndCallers key tally + tally.
	caller ~~ nil ifTrue:
		[callerTally _ tallyAndCallers value at: caller method ifAbsent:
			[tallyAndCallers value at: caller method put: (MessageTally new
				class: caller tallyClass method: caller method)].
		newCallerTally _ callerTally tally + tally].
	(receivers ~~ nil and: [receivers size > 0])
		ifTrue: [receivers do: [:aMessageTally | aMessageTally totals: dict from: self]].
	tallyAndCallers key setTally: newTally.
	caller ~~ nil ifTrue:
		[callerTally setTally: newCallerTally]! !

!MessageTally methodsFor: 'printing'!

fromTotalsPrintOn: aStream over: threshold 
	| aDict |
	aDict _ IdentityDictionary new: 128.
	self totals: aDict from: nil.
	((SortedCollection sortBlock: [ :a :b | a key <= b key])
		addAll: (aDict asOrderedCollection
			select: [:pair | pair key tally > threshold]); yourself) do: 
		[:pair | | callers |
		pair key printOn: aStream total: tally cr: false.
		callers _ (pair value asOrderedCollection
			select: [:node | node tally > threshold]) asSortedCollection.
		(callers size > 1 or: [callers isEmpty not "and: [callers first tally / pair key tally < 0.95]"]) ifTrue:
			[callers do: [ :node |
		 		aStream cr; tab.
		 		node printOn: aStream total: tally cr: false]].
		 aStream cr]!

fullPrintOn: aStream cutoff: perCent 
	| threshold |  
	threshold _ (perCent asFloat / 100 * tally) rounded.
	aStream nextPutAll: '**Tree**'; cr.
	self treePrintOn: aStream
		tabs: OrderedCollection new
		thisTab: ''
		total: tally
		over: threshold.
	aStream nextPut: Character newPage; cr.
	aStream nextPutAll: '**Leaves**'; cr.
	self fromTotalsPrintOn: aStream over: threshold.!

leavesPrintOn: aStream over: threshold 
	| aSet |
	aSet _ Set new: 128.
	self leaves: aSet.
	(aSet asOrderedCollection select: [:node | node tally > threshold])
		asSortedCollection do: 
		[:node | node printOn: aStream total: tally]!

printOn: aStream total: total 
	self printOn: aStream total: total cr: true!

printOn: aStream total: total cr: cr
	| aSelector aClass cls|
	aStream print: (tally asFloat / total * 100.0 roundTo: 0.1); space.
	receivers == nil
		ifTrue: [aStream nextPutAll: 'primitives']
		ifFalse: 
			[class == BlockClosure
				ifTrue:[cls _ self findClassForBlockClosuresMethod.
						cls == nil ifTrue: [cls _ self exhaustiveSearchForBlockClosuresMethod].
						cls == nil
							ifTrue: [aStream nextPutAll: '[] in unbound method']
							ifFalse: [aSelector _ cls
										selectorAtMethod: (self outerMethodFor: method)
										setClass: [:cl | aClass _ cl].
									aStream nextPutAll: '[] in ' ,aClass name; space.
									aStream nextPutAll: aSelector]]
				ifFalse: [aSelector _ class selectorAtMethod: method setClass: [:cl | aClass _ cl].
						aStream nextPutAll: aClass name; space; nextPutAll: aSelector]].
	cr ifTrue: [aStream cr]!

totalsPrintOn: aStream over: threshold 
	| aDict |
	aDict _ IdentityDictionary new: 128.
	self totals: aDict.
	(aDict asOrderedCollection select: [:node | node tally > threshold])
		asSortedCollection do: 
		[:node | node printOn: aStream total: tally]!

treePrintOn: aStream tabs: tabs thisTab: myTab total: total over: threshold 
	| sons sonTab |
	tabs do: [:tab | aStream nextPutAll: tab].
	tabs size > 0 ifTrue: [self printOn: aStream total: total].
	sons _ self sonsOver: threshold.
	sons isEmpty ifFalse:
		[tabs addLast: myTab.
		sons _ sons asSortedCollection.
		(1 to: sons size) do: 
			[:i |
			sonTab _ i < sons size ifTrue: ['  |'] ifFalse: ['  '].
			(sons at: i)
				treePrintOn: aStream tabs: tabs thisTab: sonTab total: total over: threshold].
		tabs removeLast]! !

!MessageTally methodsFor: 'private: private'!

class: aClass method: aMethod 
	class _ aClass.
	method _ aMethod.
	tally _ 0.
	receivers _ Array new: 0!

exhaustiveSearchForBlockClosuresMethod

	| meth |
	meth _ self outerMethodFor: method.
	Smalltalk allBehaviorsDo:
		[:b |
		(b selectorAtMethod: meth ifAbsent: [nil]) == nil
			ifFalse: [^b]].
	"none were found"
	^nil!

findClassFor: aMethod returning: returnBlock

	((class == BlockClosure) not and: [aMethod == method])
		ifTrue: [returnBlock value: class]
		ifFalse: [receivers do:
					[:aMessageTally |
					aMessageTally findClassFor: aMethod returning: returnBlock]]!

findClassForBlockClosuresMethod

	RootTally findClassFor: (self outerMethodFor: method) returning: [:aClass | ^aClass].
	"none were found"
	^nil!

method
	^method!

outerMethodFor: aCompiledMethod

	aCompiledMethod isBlockMethod
		ifTrue: [^self outerMethodFor: aCompiledMethod outerMethod]
		ifFalse: [^aCompiledMethod]!

primitives: anInteger 
	tally _ anInteger.
	receivers _ nil!

setTally: t
	tally _ t!

tally
	^tally!

tallyClass
	^class! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MessageTally class
	instanceVariableNames: ''!


!MessageTally class methodsFor: 'spying'!

mySpy: aBlock 
	"An execution profile of the execution of aBlock is obtained. "

	"For example:
		MessageTally mySpy: [Pen penSampler]. MessageTally mySpy: [Smalltalk asSortedCollection]
	The execution profile is presented in a workspace (user is prompted for area).
	No value is returned"

	| spy val reportStream |
	spy _ self new.
	spy spyEvery: 4 on: aBlock.
	"Run the block and take the tallies"
	val _ spy continueSpying.
	"Report it"
	reportStream _ WriteStream on: (String new: 5000).
	spy reportOn: reportStream cutoff: 1; close.
	StringHolderView
		open: (StringHolder new contents: reportStream contents)
		label: 'Spy Results'.
	^val  "Never gets returned due to window scheduling"!

spyOn: aBlock 
	"An execution profile of the execution of aBlock is obtained. "

	"For example:
		MessageTally spyOn: [Pen penSampler].
	The execution profile is presented in a workspace (user is prompted for area).
	No value is returned"

	| spy val reportStream |
	spy _ self new.
	[spy spyEvery: spy defaultInterval on: aBlock.
	"Run the block and take the tallies"
	val _ spy continueSpying.
	"Report it"
	reportStream _ WriteStream on: (String new: 5000).
	spy reportOn: reportStream.
	] valueNowOrOnUnwindDo: [spy close].
	StringHolderView
		open: (StringHolder new contents: reportStream contents)
		label: 'Spy Results'.
	^val  "Never gets returned due to window scheduling"!

spyOn: aBlock every: interval
	"An execution profile of the execution of aBlock is obtained. "

	"For example:
		MessageTally spyOn: [Pen penSampler].
	The execution profile is presented in a workspace (user is prompted for area).
	No value is returned"

	| spy val reportStream |
	spy _ self new.
	[spy spyEvery: interval on: aBlock.
	"Run the block and take the tallies"
	val _ spy continueSpying.
	"Report it"
	reportStream _ WriteStream on: (String new: 5000).
	spy reportOn: reportStream.
	] valueNowOrOnUnwindDo: [spy close].
	StringHolderView
		open: (StringHolder new contents: reportStream contents)
		label: 'Spy Results'.
	^val  "Never gets returned due to window scheduling"!

spyOn: aBlock to: fileName
	"Spy on the evaluation of aBlock.  Write the data collected on a file named fileName.
	The value of the block is returned as the value of this method. "

	"For example:
		MessageTally spyOn: [Smalltalk asSortedCollection] to: 'spy.results'.
		(Filename named: 'spy.results') edit.
	"

	| spy val aFileStream |
	spy _ self new.
	"Set up the block"
	[spy spyEvery: spy defaultInterval on: aBlock.
		"Run the block and take the tallies"
	val _ spy continueSpying.
		"Report it"
	aFileStream _ (Filename named: fileName) writeStream.
	[aFileStream timeStamp; nextPutAll: fileName; space.
	spy reportOn: aFileStream]
		valueNowOrOnUnwindDo: [aFileStream close].
	] valueNowOrOnUnwindDo: [spy close].
	^val! !

!MessageTally class methodsFor: 'cleanup'!

cleanupGarbage
	RootTally _ nil! !

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


Object subclass: #InputSensor
	instanceVariableNames: ''
	classVariableNames: 'CurrentCursor CurrentCursorGridding CurrentInputState '
	poolDictionaries: ''
	category: 'System-Support'!
InputSensor comment:
'Class InputSensor represents an interface to the user input devices.  There is at least one global instance of the class, whose name is Sensor.

Class Variables:
	CurrentCursor		<Cursor> reference to the cursor that is currently being displayed
	CurrentInputState	<InputState> for accessing the hardware'!


!InputSensor methodsFor: 'keyboard'!

ctrlDown
	"Answer whether the control key is down."

	^self primCtrlDown!

flushKeyboard
	"Remove all characters from the keyboard buffer."

	[self keyboardPressed]
		whileTrue: [self keyboard]!

keyboard
	"Answer the next character from the keyboard buffer as a fully decoded 
	(ASCII) character."

	^self primKbdNext keyCharacter!

keyboardEvent
	"Answer the next character from the keyboard buffer as a KeyboardEvent."

	^self primKbdNext!

keyboardPeek
	"Answer the next character in the keyboard buffer or false if it is empty.   
	self keyboardPressed must be true, else an error is reported."

	self keyboardPressed ifTrue: [^self primKbdPeek keyCharacter].
	self error: 'Cant peek when nothing there'!

keyboardPressed
	"Answer false if the keyboard buffer is empty, else true."

	"The keyboard queue only contains real keystrokes, so
	just test if it is non-empty."

	^self primKbdPeek notNil!

leftShiftDown
	"Answer whether the left shift key is down."

	^self primLeftShiftDown! !

!InputSensor methodsFor: 'mouse'!

anyButtonPressed
	"Answer whether a mouse button is being pressed."

	^self buttons > 0!

blueButtonPressed
	"Answer whether only the blue mouse button is being pressed."

	^ self buttons = 1!

mousePoint
	"Answer a Point indicating the coordinates of the current mouse location."

	^CurrentInputState mousePoint!

mousePointNext
	"Answer the next mouse point if red button or tablet is down; false otherwise."

	self redButtonPressed ifTrue: [^self mousePoint].
	^false!

noButtonPressed
	"Answer whether any mouse button is not being pressed."

	^self anyButtonPressed == false!

redButtonPressed
	"Answer whether only the red mouse button is being pressed."

	^self buttons = 4!

waitButton
	"Wait for the user to press any mouse button and then answer with the 
	current location of the cursor."

	[self anyButtonPressed] whileFalse.
	^self cursorPoint!

waitClickButton
	"Wait for the user to click (press and then release) any mouse button and then
	answer with the current location of the cursor."

	self waitButton.
	^self waitNoButton!

waitNoButton
	"Wait for the user to release any mouse button and then answer with the 
	current location of the cursor."

	[self anyButtonPressed] whileTrue.
	^self cursorPoint!

yellowButtonPressed
	"Answer whether only the yellow mouse button is being pressed."

	^ self buttons = 2! !

!InputSensor methodsFor: 'current cursor'!

currentCursor
	"Answer the instance of Cursor currently displayed."

	^CurrentCursor!

currentCursor: newCursor 
	"Set newCursor to be the displayed Cursor form."

	CurrentCursor _ newCursor.
	Cursor currentCursor: CurrentCursor!

cursorPoint
	"Answer a Point indicating the cursor location."

	^self mousePoint!

cursorPoint: aPoint 
	"Set aPoint to be the current cursor location."

	^self primCursorLocPut: aPoint!

maybeGriddedCursorPoint
	"Answer a Point indicating the cursor location.  If leftShiftDown, then answer gridded
	version of cursor position"

	self leftShiftDown
		ifTrue: [^self cursorPoint]
		ifFalse: 
			[CurrentCursorGridding = nil
				ifTrue: [CurrentCursorGridding _ 8@8].
			^self cursorPoint grid: CurrentCursorGridding]! !

!InputSensor methodsFor: 'private: private'!

buttons
	^self primMouseButtons!

primCtrlDown
	^CurrentInputState ctrlDown!

primCursorLocPut: pt 
	CurrentInputState cursorPoint: pt!

primKbdNext
	^CurrentInputState keyboardNext!

primKbdPeek
	^CurrentInputState keyboardPeek!

primLeftShiftDown
	^CurrentInputState leftShiftDown!

primMouseButtons
	^CurrentInputState mouseButtons!

primMousePt
	"Poll the mouse to find out its position. Return a Point. Fail if event-driven 
	tracking is used instead of polling. Optional. See Object documentation 
	whatIsAPrimitive. "

	<primitive: 90>
	^CurrentInputState mousePoint! !

!InputSensor methodsFor: 'FM control'!

{BooleanVar} controlDownFn
	^ self ctrlDown!

{BooleanVar} lockDownFn
	^ CurrentInputState lockDown!

menuDownFn
	^ self yellowButtonPressed!

{BooleanVar} metaDownFn
	^ CurrentInputState metaDown!

selectDownFn
	^ self redButtonPressed!

{BooleanVar} shiftDownFn
	^ self leftShiftDown!

windowDownFn
	^ self blueButtonPressed! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InputSensor class
	instanceVariableNames: ''!


!InputSensor class methodsFor: 'class initialization'!

install
	"Create an instance of InputState for accessing the hardware, and 
	save it in the class variable CurrentInputState."

	CurrentInputState _ InputState new.
	CurrentInputState install! !

!InputSensor class methodsFor: 'constants'!

default
	"Answer the default system InputSensor, Sensor."

	^Sensor!

initSensor
	"Create the default system InputSensor, Sensor."

	Sensor _ InputSensor new! !

!InputSensor class methodsFor: 'gridding'!

{void} grid: aPoint {Point}
	"InputSensor grid: 8@8"
	CurrentCursorGridding _ aPoint! !

Array variableSubclass: #DependentsCollection
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Support'!
DependentsCollection comment:
'A DependentsCollection is a collection of dependents for some object.  Instances forward update messages to the dependents, which are the elements of the collection.  Note that the same dependent may appear more than once in the collection.  Note also that the size of a DependentsCollection must always be 2 or greater.  (If an object has only one dependent, that object by itself serves as the collection of dependents.)
'!


!DependentsCollection methodsFor: 'accessing'!

asDependentsAsCollection
	" Answer the receiver, considered as a
	collection of dependents, as a real
	Collection.  Since the receiver is a
	Collection already, answer the receiver. "

	^self!

asDependentsWith: anObject
	" Answer the receiver, considered as a
	collection of dependents, with anObject
	added. "

	^self copyWith: anObject!

asDependentsWithout: anObject
	" Answer the receiver, considered as a
	collection of dependents, with the first
	occurrence of anObject (if any) removed.
	If anObject does not occur in the receiver,
	answer the receiver. "
	" If there is only one dependent left,
	just answer it, rather than a new Collection. "

	| newCollection item size indx |
	size _ self size.
	size = 2 ifTrue:
		[(self at: 1) == anObject
			ifTrue: [^self at: 2]
			ifFalse:
				[(self at: 2) == anObject
					ifTrue: [^self at: 1]
					ifFalse: [^self]]].

	newCollection _ self class new: size - 1.
	indx _ 1.
	" Search until we find an occurrence of
	anObject, or until we have copied all but
	the last item in the collection. "
	[indx = size or:
	  [item _ self at: indx.
	  item == anObject]]
		whileFalse:
			[newCollection at: indx put: item.
			indx _ indx + 1].
	indx = size
		ifTrue:
			[(self at: size) == anObject
				ifTrue: [^newCollection]
				ifFalse: [^self]]
		ifFalse: 
			[newCollection replaceFrom: indx to: size - 1 with: self startingAt: indx + 1.
			^newCollection]! !

!DependentsCollection methodsFor: 'updating'!

performUpdate: aSymbol
	"Send aSymbol to each member of the receiver."

	1 to: self size do:
		[:i |
		(self at: i) perform: aSymbol]!

performUpdate: aSymbol with: anObject
	"Send aSymbol to each member of the receiver with anObject as argument."

	1 to: self size do:
		[:i |
		(self at: i) perform: aSymbol with: anObject]!

update: anAspect with: aParameter from: anObject
	"Send the message update: anAspect with: aParameter from: anObject to each member of the receiver."

	1 to: self size do:
		[:i |
		(self at: i) update: anAspect with: aParameter from: anObject]!

updateRequest
	"Send the message updateRequest to each member of the receiver.
	If one answers false answer falase otherwise answer true."

	1 to: self size do:
		[:i |
		(self at: i) updateRequest
			ifFalse: [^false]].
	^true!

updateRequest: anAspectSymbol
	"Send the message updateRequest: to each member of the receiver with anAspectSymbol as argument.
	If one answers false answer falase otherwise answer true."

	1 to: self size do:
		[:i |
		((self at: i) updateRequest: anAspectSymbol)
			ifFalse: [^false]].
	^true! !

Object subclass: #KeyboardEvent
	instanceVariableNames: 'keyCharacter metaState '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Support'!
KeyboardEvent comment:
'Class KeyboardEvent represents a keyboard event consisting of a non-meta key being struck plus the state of the meta keys at that moment.  Only InputState creates instances of the class.

Instance Variables:
		keyCharacter	<Integer> non-meta key character
		metaState		<Integer> combined state of meta keys
		
'!


!KeyboardEvent methodsFor: 'accessing'!

keyCharacter
	"Answer the character that was pressed."
	"Fix because the mac (for some reason) stopped accepting the apple key
	as the control key."
	
	self hasCtrl
		ifTrue: [keyCharacter > 127
			ifTrue: [^ keyCharacter asCharacter]
			ifFalse: [
			^(keyCharacter asCharacter asUppercase asciiValue bitAnd: -65)
					 asCharacter]]
		ifFalse: [^keyCharacter asCharacter]!

keyValue
	"Answer the keyboard character of the receiver."
	self hasCtrl
		ifTrue: [^keyCharacter bitAnd: 191]
		ifFalse: [^keyCharacter]!

metaState
	"Answer the state of the special keyboard characters--control, shift, lock."

	^metaState! !

!KeyboardEvent methodsFor: 'testing'!

hasCtrl
	"Answer whether a control key was pressed."

	^metaState anyMask: 2!

hasLock
	"Answer whether the shift key is locked."

	^metaState anyMask: 4!

hasShift
	"Answer whether a shift key was pressed."

	^metaState anyMask: 1! !

!KeyboardEvent methodsFor: 'private: private'!

key: anInteger meta: meta 

	keyCharacter _ anInteger.
	metaState _ meta! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

KeyboardEvent class
	instanceVariableNames: ''!


!KeyboardEvent class methodsFor: 'instance creation'!

code: code meta: meta 
	"Answer an instance of the receiver, with code the regular key and meta the special
	keys--ctrl, shift, lock."

	^self new key: code meta: meta! !

Object subclass: #InputState
	instanceVariableNames: 'x y bitState lshiftState rshiftState ctrlState lockState metaState keyboardQueue metaKeyState otherMetaKey1State otherMetaKey2State otherMetaKey3State '
	classVariableNames: 'BitMax BitMin CtrlKey EmergencyInterruptKey IdleSemaphore InputProcess InputSemaphore InterruptKey LetterCKey LockKey LshiftKey MetaKey OtherMeta1 OtherMeta2 OtherMeta3 RshiftKey '
	poolDictionaries: ''
	category: 'System-Support'!
InputState comment:
'Class InputState represents the state of the user input devices.

Instance Variables:
	x  <Integer> mouse X location 
	y  <Integer> mouse Y location 
	bitState  <Integer> mouse button and keyset state 
	lshiftState  <1 or 0> state of left shift key 
	rshiftState  <1 or 0> state of right shift key 
	ctrlState  <2 or 0> state of ctrl key 
	lockState  <4 or 0> state of shift-lock key 
	metaState  <Integer> combined state of the meta keys 
	keyboardQueue  <SharedQueue> of keyboard characters 
	metaKeyState  <Integer>
	otherMetaKey1State  <Integer>
	otherMetaKey2State  <Integer>
	otherMetaKey3State  <Integer>
		
Class Variables:
	InputSemaphore	<Semaphore>
		Signalled by the VM when input is available.
	IdleSemaphore	<Semaphore>
		Signalled by InputState>>run when Smalltalk goes "active" (e.g. mouse cursor enters display area.)
	
	These are all integers defined in the class message initialize. that represent particular key presses.
		BitMax
		BitMin
		CtrlKey
		EmergencyInterruptKey
		InputProcess
		InterruptKey
		LetterCKey
		LockKey
		LshiftKey
		MetaKey
		OtherMeta1
		OtherMeta2
		OtherMeta3
		RshiftKey
'!


!InputState methodsFor: 'initialize-release'!

install
	"Initialize and connect the receiver to the hardware.  Terminate the old input 
	process if any."

	InputProcess == nil ifFalse: [InputProcess terminate].
	self initState.
	InputSemaphore _ Semaphore new.
	IdleSemaphore _ Semaphore new.
	InputProcess _ [IdleSemaphore signal. self run] newProcess.
	InputProcess priority: Processor lowIOPriority.
	InputProcess resume.
	self primInputSemaphore: InputSemaphore! !

!InputState methodsFor: 'keyboard'!

ctrlDown
	"Answer whether the control key is down."

	^ctrlState ~= 0!

keyboardNext
	"Remove and answer the next key in the keyboard buffer."

	^[keyboardQueue next] valueUninterruptably!

keyboardPeek
	"Answer the next key in the keyboard buffer but do not remove it."

	^[keyboardQueue peek] valueUninterruptably!

leftShiftDown
	"Answer whether the left shift key is down."

	^lshiftState ~= 0!

{BooleanVar} lockDown
	^lockState ~~ 0!

{BooleanVar}metaDown
	^metaState ~~ 0! !

!InputState methodsFor: 'mouse'!

mouseButtons
	"Answer the status of the mouse buttons--an Integer between 0 and 7."

	^bitState bitAnd: 7!

mousePoint
	"Answer the coordinates of the mouse location."
	IdleSemaphore wait.
	IdleSemaphore signal.
	^x@y! !

!InputState methodsFor: 'cursor'!

cursorPoint: aPoint 
	"Set the current cursor position to be aPoint."

	self primCursorLocPut: aPoint.
	x _ aPoint x.
	y _ aPoint y! !

!InputState methodsFor: 'private: private'!

initState

	x _ y _ 0.
	keyboardQueue _ SharedQueue new: 50.
	ctrlState _ lshiftState _ rshiftState _ lockState _ metaState _ metaKeyState _ 0.
	otherMetaKey1State _ otherMetaKey2State _ otherMetaKey3State _ 0.
	bitState _ 0!

keyAt: keyNumber put: value 
	| index |
	index _ keyNumber bitAnd: 255.
	(index < BitMin or: ["Get rid of meta bits"
		index > OtherMeta3])
		ifTrue: ["Not a potential special character"
			value = 1 ifTrue: ["only look at down strokes"
				index = InterruptKey
					ifTrue: [(lshiftState ~= 0 or: [(keyNumber bitAnd: 256)
								~= 0])
							ifTrue: [self forkEmergencyEvaluatorAt: Processor userInterruptPriority]
							ifFalse: [[ControlManager interruptLockedSignal
										handle: [:ex | ex return]
										do: [ScheduledControllers interruptName: 'User Interrupt']] fork]]
					ifFalse: [index = EmergencyInterruptKey
							ifTrue: [self forkEmergencyEvaluatorAt: Processor userInterruptPriority]
							ifFalse: [^keyboardQueue nextPut: (KeyboardEvent
												code: index
												meta: (metaState bitOr: (keyNumber bitShift: -8)))]]]]
		ifFalse: 
			[self setStateFor: index with: value.
			metaState _ (((((ctrlState bitOr: (lshiftState bitOr: rshiftState))
						bitOr: lockState)
						bitOr: metaKeyState)
						bitOr: otherMetaKey1State)
						bitOr: otherMetaKey2State)
						bitOr: otherMetaKey3State]!

metaInput: word 
	| args numA opcode |
	numA _ word bitAnd: 15.
	opcode _ (word bitShift: -4) bitAnd: 15.
	numA > 0 ifTrue: 
			[args _ Array new: numA.
			1 to: numA do: 
				[:i | 
				InputSemaphore wait.
				args at: i put: self primInputWord]].
"resize"	opcode = 9 ifTrue: [ControlManager lastDisplayExtent: (args at: 1) @ (args at: 2)]
"child"	ifFalse: [opcode = 16rE
					ifTrue: [| pcls |
							pcls _ ExternalProcess defaultClass.
							pcls notNil ifTrue: [pcls reapSome]]
"exit"	ifFalse: [opcode = 8 ifTrue: [IdleSemaphore initSignals]
"enter"	ifFalse: [opcode = 7 ifTrue: [IdleSemaphore signal]
"close"	ifFalse: [opcode = 16rA ifTrue: []
"open"	ifFalse: [opcode = 16rB ifTrue: []
"repaint"ifFalse: [opcode = 16rC ifTrue: []
"quit"	ifFalse: [opcode = 16rD ifTrue: []
		ifFalse: ["Unknown opcode"]]]]]]]]!

primCursorLocPut: aPoint 
	"Set the cursor to the point on the screen specified by the 
	argument aPoint.  Fail if the argument is not a Point.  Essential. See 
	Object documentation whatIsAPrimitive."

	<primitive: 91>
	^self primCursorLocPutAgain: aPoint rounded!

primCursorLocPutAgain: aPoint 
	"Set the cursor to the point on the screen specified by the 
	argument aPoint.  Fail if the argument is not a Point.  Essential. See 
	Object documentation whatIsAPrimitive."

	<primitive: 91>
	^self primitiveFailed!

primInputSemaphore: aSemaphore 
	"Install the argument (a Semaphore) as the object to be signalled whenever 
	an input event occurs. The semaphore will be signaled once for every 
	word placed in the input buffer by an I/O device. Fail if the argument is 
	neither a Semaphore nor nil. Essential. See Object whatIsAPrimitive."

	<primitive: 93>
	^self primitiveFailed!

primInputWord
	"Return the next word from the input buffer and remove the word from the 
	buffer. This message should be sent just after the input semaphore 
	finished a wait (was sent a signal by an I/O device). Fail of the input 
	buffer is empty. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 95>
	^self primitiveFailed!

primMousePt
	"Poll the mouse to find out its position.  Return a Point.  Fail if event-driven 
	tracking is used instead of polling.  Optional.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 90>
	^x @ y!

primSampleInterval: anInteger 
	"Set the minimum time span between event driven mouse position 
	samples.  The argument is a number of milliseconds.  Fail if the argument 
	is not a SmallInteger.  Essential.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 94>
	^self primitiveFailed!

run
	"This is the loop that actually processes input events."

	| word type param |
	[true]
		whileTrue: 
			[InputSemaphore wait.
			"Test for mouse X/Y events here to avoid an activation."
			word _ self primInputWord.
			type _ word bitShift: -12.
			param _ word bitAnd: 4095.
"Mouse X"	type = 1 ifTrue: [x _ param]
"Mouse Y"	ifFalse: [type = 2 ifTrue: [y _ param]
"Key down"	ifFalse: [type = 3 ifTrue: [self keyAt: param put: 1]
"Key up"	ifFalse: [type = 4 ifTrue: [self keyAt: param put: 0]
"MetaInput"ifFalse: [type = 7 ifTrue: [self metaInput: word]
"Delta time"ifFalse: [type = 0 ifTrue: []
"Reset time"ifFalse: [type = 5 ifTrue: [self primInputWord; primInputWord]
			ifFalse: [self error: 'Bad event type']]]]]]]]!

setStateFor: index with: state
	"Set the state keys"

	| mask | 
	index = LshiftKey ifTrue: [^lshiftState _ state].
	index = RshiftKey ifTrue: [^rshiftState _ state].
	index = CtrlKey ifTrue: [^ctrlState _ state bitShift: 1].
	index = LockKey ifTrue: [^lockState _ state bitShift: 2].
	index = MetaKey ifTrue: [^metaKeyState _ state bitShift: 3].
	index = OtherMeta1 ifTrue: [^otherMetaKey1State _ state bitShift: 4].
	index = OtherMeta2 ifTrue: [^otherMetaKey2State _ state bitShift: 5].
	index = OtherMeta3 ifTrue: [^otherMetaKey3State _ state bitShift: 6].
	(index >= BitMin and: [index <= BitMax])
		ifTrue: [mask _ 1 bitShift: index - BitMin.
				state = 1
					ifTrue: [bitState _ bitState bitOr: mask]
					ifFalse: [bitState _ bitState bitAnd: -1 - mask]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InputState class
	instanceVariableNames: ''!


!InputState class methodsFor: 'class initialization'!

initialize
	"Define parameters"

	"InputState initialize"

	InterruptKey	 _ 25.			"25 for Ctrl-Y, 3 for Ctrl-C, 206 for Ctrl-."
	EmergencyInterruptKey _ 249.	"249 for Ctrl-Shift-Y, 227 for Ctrl-Shift-C, 222 for Ctrl-Shift-."
	BitMin _ 128.  "Min mouse/keyset bit code"
	BitMax _ 135.  "Max mouse/keyset bit code"
	LshiftKey _ 136.
	RshiftKey _ 137.
	CtrlKey _ 138.
	LockKey _ 139.
	MetaKey _ 140.
	OtherMeta1 _ 141.
	OtherMeta2 _ 142.
	OtherMeta3 _ 143! !

!InputState class methodsFor: 'key settings'!

emergencyInterruptKey
	"Answer the code for the key that causes an emergency interrupt."

	^EmergencyInterruptKey!

emergencyInterruptKey: anInteger
	"Set the code for the key that causes an emergency interrupt."

	EmergencyInterruptKey _ anInteger!

interruptKey
	"Answer the code for the key that causes an interrupt."

	^InterruptKey!

interruptKey: anInteger
	"Set the code for the key that causes an interrupt."

	InterruptKey _ anInteger! !

!InputState class methodsFor: 'private: private-initialization'!

idleReset
	"Only used in juntas"
	IdleSemaphore _ Semaphore new.
	IdleSemaphore signal! !

InputState initialize!
