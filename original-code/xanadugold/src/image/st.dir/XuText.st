'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:25 pm'!

XuWrapper subclass: #XuText
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
XuText comment:
'Handles a integer-indexed, contiguous, zero-based Edition of RangeElements'!

(XuText getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuText methodsFor: 'promise access'!

{FeText} getActualFeText
	self isBroken
		ifFalse: [^super actualThing cast: FeText.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuText methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeText {FeText}
	super create: anFeText.! !

!XuText methodsFor: 'text manipulation'!

{XuEdition} contents

	"The Edition of the actual contents, without any style information. You should use this instead of edition() when you want to get the Edition for comparisons, queries, etc. Future styled text implementations will not store the contents as directly as we do now."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeText contents)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} count

	"The number of elements in the string"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeText count)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuText} extract: region {XuIntegerRegion} 

	"All the text lying within the region, with the gaps compressed out."
	
	| retVal {XuText} |
	(self isBroken) ifTrue:
		[^XuText makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuText makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuText makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuText make: (self getActualFeText extract: ((XuPromise getActual: region) cast: IntegerRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuText} insert: position {XuIntValue} with: text {XuText} 

	"Insert new information into the Edition at the given point, pushing everything after it forward."
	
	| retVal {XuText} |
	(self isBroken) ifTrue:
		[^XuText makeBrokenBy: self].
	(position isBroken) ifTrue:
		[^XuText makeBrokenBy: position].
	(text isBroken) ifTrue:
		[^XuText makeBrokenBy: text].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuText makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuText make: (self getActualFeText insert:position getActualIntegerVar with: ((XuPromise getActual: text) cast: FeText))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuText} move: pos {XuIntValue} with: region {XuIntegerRegion} 

	"Insert a virtual copy of the region of text before the given position, and remove it from its current location. If the position is one past the last character, then it will be inserted after the end. If the region is discontiguous, then the contiguous pieces are concatenated together, in sequence, and inserted."
	
	| retVal {XuText} |
	(self isBroken) ifTrue:
		[^XuText makeBrokenBy: self].
	(pos isBroken) ifTrue:
		[^XuText makeBrokenBy: pos].
	(region isBroken) ifTrue:
		[^XuText makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuText makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuText make: (self getActualFeText move:pos getActualIntegerVar with: ((XuPromise getActual: region) cast: IntegerRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuText} replace: dest {XuIntegerRegion} with: other {XuText} 

	"Replaces a region of text with a virtual copy of text from another document.
	If the destination region lies to the left of the domain, inserts before the beginning; if it intersects the domain, insert at the first common position; if it lies after the end, insert after the end. Fails with
		BLAST(AmbiguousReplacement) if the region is empty.
	May be used to copy information within a single document.
	This operation may not be particularly useful with non-simple destination regions."
	
	| retVal {XuText} |
	(self isBroken) ifTrue:
		[^XuText makeBrokenBy: self].
	(dest isBroken) ifTrue:
		[^XuText makeBrokenBy: dest].
	(other isBroken) ifTrue:
		[^XuText makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuText makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuText make: (self getActualFeText replace: ((XuPromise getActual: dest) cast: IntegerRegion) with: ((XuPromise getActual: other) cast: FeText))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuText class
	instanceVariableNames: ''!

(XuText getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuText class methodsFor: 'pseudo-constructors'!

make: anFeText {FeText}
	^self create: anFeText!

{XuText} makeBroken: problem {Problem star}
	| broke {XuText} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuText} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !