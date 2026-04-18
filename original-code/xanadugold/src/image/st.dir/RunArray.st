'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:37 pm'!

ArrayedCollection subclass: #RunArray
	instanceVariableNames: 'runs values cacheRun cacheRunStart '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Arrayed'!
RunArray comment:
'RunArrays provide space-efficient storage of data which tends to be constant over long runs of the possible indices.  runs is an array of Integers, and each indicates the number of indices over which the corresponding value (in values) is constant.

Instance Variables:
	runs		<Array of: Integers>  length of the run, i.e., the number of characters to take into account
	values		<Array of: Integers>  which font to use out of a TextStyle
	cacheRun	<Integer>  current index of runs
	cacheRunStart <Integer> index into the string associated with the RunArray (sum of run lengths up to cacheRun)'!


!RunArray methodsFor: 'accessing'!

at: anInteger 
	"Answer the element at index anInteger." 

	^self at: anInteger setRunAndOffset: [:run :offset | values at: run]!

runLengthAt: index 
	"Answer the length remaining in run beginning at index."

	^self at: index 
		setRunAndOffset: [:run :offset | (runs at: run) - offset]!

size
	"Answer how many elements the receiver contains."

	| size |
	size _ 0.
	runs do: [:run | size _ size + run].
	^size!

values
	"Answer the values in the receiver."

	^values! !

!RunArray methodsFor: 'adding'!

addFirst: value
	"Add value as the first element of the receiver."

	cacheRun _ cacheRunStart _ 1.  "Clear cache"
	(runs size = 0 or: [values first ~= value])
	  ifTrue:
		[runs _ (Array with: 1) , runs.
		values _ (Array with: value) , values]
	  ifFalse:
		[runs at: 1 put: runs first + 1]!

addLast: value
	"Add value as the last element of the receiver."

	(runs size=0 or: [values last ~= value])
	  ifTrue:
		[runs_ runs copyWith: 1.
		values_ values copyWith: value]
	  ifFalse:
		[runs at: runs size put: runs last+1]! !

!RunArray methodsFor: 'copying'!

, aRunArray
	"Answer a new RunArray that is a concatenation of the receiver and
	aRunArray. "

	| new copySize newRuns newValues index |
	(aRunArray class == RunArray)
		ifFalse:
			[new _ self copy.
			"attempt to be sociable"
			aRunArray do: [:each | new addLast: each].
			^new].
	runs size = 0 ifTrue: [^aRunArray copy].
	aRunArray runs size = 0 ifTrue: [^self copy].
	"Compute size of runs/values in result."
	copySize _ runs size + aRunArray runs size.
	values last = aRunArray values first ifTrue:
		["runs at boundary will be merged"
		copySize _ copySize - 1].
	newRuns _ Array new: copySize.
	newValues _ Array new: copySize.
	"copy self into result"
	index _ self
				copyFromRun: 1
				offset: 0
				toRun: runs size
				offset: runs last - 1
				intoRuns: newRuns
				values: newValues
				startingAt: 1.
	"copy argument into result"
	aRunArray
		copyFromRun: 1
		offset: 0
		toRun: aRunArray runs size
		offset: aRunArray runs last - 1
		intoRuns: newRuns
		values: newValues
		startingAt: index.
	^RunArray runs: newRuns values: newValues!

copyFrom: start to: stop
	"Answer a copy of a subset of the receiver, starting from element at index start 
	until element at index stop."

	| newRuns newValues |
	stop < start ifTrue: [^RunArray new].
	self at: start setRunAndOffset:
		[:run1 :offset1 |
		self at: stop
			setRunAndOffset:
				[:run2 :offset2 |
				newRuns _ Array new: run2 - run1 + 1.
				newValues _ Array new: newRuns size.
				self
					copyFromRun: run1
					offset: offset1
					toRun: run2
					offset: offset2
					intoRuns: newRuns
					values: newValues
					startingAt: 1]].			
	^RunArray runs: newRuns values: newValues!

copyReplaceFrom: start to: stop with: replacement

	| startRun startOffset stopRun stopOffset endRun endOffset rep repSize copySize newRuns newValues index |
	self at: start - 1
		setRunAndOffset:
			[:run :offset |
			startRun _ run.
			startOffset _ offset].
	(startRun = 1 and: [startOffset < 0])
		ifTrue:
			[startRun _ 0
			"head is empty"].
	self at: stop + 1
		setRunAndOffset:
			[:run :offset |
			stopRun _ run.
			stopOffset _ offset].
	(endRun _ runs size) = 0 ifFalse:
		["if true, receiver is empty"
		endOffset _ (runs at: endRun) - 1].
	(stopRun = endRun and: [stopOffset > endOffset])
		ifTrue:
			[stopRun _ endRun + 1
			"tail is empty"].
	"Coerce replacement to a RunArray."
	((rep _ replacement) class ==  RunArray)
		ifFalse:
			[rep _ RunArray new.
			replacement do: [:each | rep addLast: each]].
	"Compute the size of the copy's runs and values."
	repSize _ rep runs size.
	copySize _ startRun "head runs size" + repSize + (endRun - stopRun + 1) "tail runs size".
	"Determine if boundary runs will merge"
	repSize = 0
		ifTrue:
			["Replacement is empty, check for merging head and tail"
			(startRun > 0 and: [stopRun <= endRun and: [(values at: startRun) = (values at: stopRun)]])
				ifTrue: [copySize _ copySize - 1]]
		ifFalse:
			[(startRun > 0 and: [(values at: startRun) = (rep values at: 1)])
				ifTrue: [copySize _ copySize - 1].
			(stopRun <= endRun and: [(rep values at: repSize) = (values at: stopRun)])
				ifTrue: [copySize _ copySize - 1]].
	newRuns _ Array new: copySize.
	newValues _ Array new: copySize.
	index _ startRun > 0
				ifTrue:  "non-empty head"
					[self
						copyFromRun: 1
						offset: 0
						toRun: startRun
						offset: startOffset
						intoRuns: newRuns
						values: newValues
						startingAt: 1]
				ifFalse: [1].
	repSize > 0 ifTrue:  "non-empty replacement"
		[index _ rep
				copyFromRun: 1
				offset: 0
				toRun: repSize
				offset: (rep runs at: repSize) - 1
				intoRuns: newRuns
				values: newValues
				startingAt: index].
	stopRun <= endRun ifTrue:  "non-empty tail"
		[self
			copyFromRun: stopRun
			offset: stopOffset
			toRun: endRun
			offset: endOffset
			intoRuns: newRuns
			values: newValues
			startingAt: index].
	^RunArray runs: newRuns values: newValues! !

!RunArray methodsFor: 'printing'!

storeOn: aStream
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates a runarray similar to the receiver.  The general format
	is
		( class-name runs: runs values: values )"

	aStream nextPut: $(.
	aStream nextPutAll: self class name.
	aStream nextPutAll: ' runs: '.
	runs storeOn: aStream.
	aStream nextPutAll: ' values: '.
	values storeOn: aStream.
	aStream nextPut: $)! !

!RunArray methodsFor: 'fileIn/Out'!

writeOn: aStream
	"Append the receiver to the argument, aStream, writing first runs and
	then values."

	aStream nextWordPut: runs size.
	1 to: runs size do:
		[:x |
		aStream nextWordPut: (runs at: x).
		aStream nextWordPut: (values at: x)]! !

!RunArray methodsFor: 'private:'!

at: index setRunAndOffset: aBlock 
	"Supply all run information to aBlock."
	" Tolerates index=0 and index=size+1 for copyReplace:"

	| run limit offset runStart runLength |
	index >= cacheRunStart
		ifTrue: 
			[run _ cacheRun.
			runStart _ cacheRunStart.
			limit _ runs size.
			offset _ index - runStart.
			[run < limit and: [(runLength _ runs at: run) <= offset]]
				whileTrue: 
					[offset _ offset - runLength.
					run _ run + 1.
					runStart _ runStart + runLength]]
		ifFalse: [index >= (cacheRunStart - index)
				ifFalse: 
					[run _ runStart _ 1.
					offset _ index - runStart.
					limit _ runs size.
					[run < limit and: [(runLength _ runs at: run) <= offset]]
						whileTrue: 
							[offset _ offset - runLength.
							run _ run + 1.
							runStart _ runStart + runLength]]
				ifTrue: [run _ cacheRun - 1.
					runStart _ cacheRunStart.
					[run >= 1 and: [(runStart _ runStart - ( runs at: run)) > index]]
						whileTrue:  [run _ run -1].
					offset _ index - runStart]].
	cacheRun _ run.
	cacheRunStart _ runStart.
	^aBlock value: run value: offset"an index into runs and values"
	"zero-based offset from beginning of this run"!

at: index setRunOffsetAndValue: aBlock 
	"Supply all run information to aBlock."

	| run limit position |
	" Tolerates index=0 and index=size+1 for copyReplace:"
	run _ 1.
	limit _ runs size.
	position _ index.
	[run <= limit and: [position > (runs at: run)]]
		whileTrue: 
			[position _ position - (runs at: run).
			run _ run + 1].
	run > limit
		ifTrue: 
			["adjustment for size+1"
			run _ run - 1.
			position _ position + (runs at: run)].
	^aBlock
		value: run	"an index into runs and values"
		value: position - 1	"zero-based offset from beginning of this run"
		value: (values at: run)	"value for this run"!

copyFromRun: run1 
	offset: offset1 
	toRun: run2 
	offset: offset2 
	intoRuns: newRuns 
	values: newValues 
	startingAt: index
	"Copy a non-empty interval of this RunArray
	into runs/values being constructed.  Return the
	index beyond the copy.  Check for merging the
	first copied run with the last existing run."
	| end |
	end _ index + run2 - run1.
	(index > 1 and: [(newValues at: index - 1) = (values at: run1)])
		ifTrue:
			["Merge runs"
			end _ end - 1.
			run1 = run2
				ifTrue:
					[newRuns at: index - 1 put: (newRuns at: index - 1) + offset2 - offset1 + 1]
				ifFalse:
					[newRuns at: index - 1 put: (newRuns at: index - 1) + (runs at: run1) - offset1.
					newRuns replaceFrom: index to: end - 1 with: runs startingAt: run1 + 1.
					newRuns at: end put: offset2 + 1.
					newValues replaceFrom: index to: end with: values startingAt: run1 + 1]]
		ifFalse:
			[run1 = run2
				ifTrue:
					[newRuns at: index put: offset2 - offset1 + 1.
					newValues at: index put: (values at: run1)]
				ifFalse:
					[newRuns at: index put: (runs at: run1) - offset1.
					newRuns replaceFrom: index + 1 to: end - 1 with: runs startingAt: run1 + 1.
					newRuns at: end put: offset2 + 1.
					newValues replaceFrom: index to: end with: values startingAt: run1]].
	^ end + 1!

runs
	^runs!

setRuns: newRuns setValues: newValues

	cacheRun _ cacheRunStart _ 1.  "Clear cache"
	runs _ newRuns.
	values _ newValues! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RunArray class
	instanceVariableNames: ''!


!RunArray class methodsFor: 'instance creation'!

create: size with: value 
	"Answer a new instance of the receiver, whose every element is equal to the argument,
	value."

	size = 0 ifTrue: [^self new].
	^self runs: (Array with: size) values: (Array with: value)!

new
	"Answer a new instance of the receiver."

	^self runs: Array new values: Array new!

new: size
	"Answer a new instance of the receiver"

	^self new: size withAll: 1!

new: size withAll: value 
	"Answer a new instance of the receiver, whose every element is equal to the argument,
	value."

	size = 0 ifTrue: [^self new].
	^self runs: (Array with: size) values: (Array with: value)!

readFrom: aStream
	"Answer a new instance of the receiver as described on the stream, aStream."

	| size runs values |
	size _ aStream nextWord.
	runs _ Array new: size.
	values _ Array new: size.
	1 to: size do:
		[:x |
		runs at: x put: aStream nextWord.
		values at: x put: aStream nextWord].
	^ self runs: runs values: values!

runs: newRuns values: newValues 
	"Answer a new instance of the receiver with runs and values specified
	by the arguments."

	| instance |
	instance _ self basicNew.
	instance setRuns: newRuns setValues: newValues.
	^instance! !