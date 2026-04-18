'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:45 pm'!

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