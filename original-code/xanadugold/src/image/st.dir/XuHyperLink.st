'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:34 pm'!

XuWrapper subclass: #XuHyperLink
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
XuHyperLink comment:
'Contains a named table of HyperRefs and a set of Works which describe the usage and/or format of the link.'!

(XuHyperLink getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuHyperLink methodsFor: 'accessing'!

{XuHyperRef} endAt: name {XuSequence} 

	"Get the HyperRef at the given name; blast if none there"
	
	| retVal {XuHyperRef} |
	(self isBroken) ifTrue:
		[^XuHyperRef makeBrokenBy: self].
	(name isBroken) ifTrue:
		[^XuHyperRef makeBrokenBy: name].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuHyperRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuHyperRef make: (self getActualFeHyperLink endAt: ((XuPromise getActual: name) cast: Sequence))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequenceRegion} endNames

	"The names of all of the ends of this link"
	
	| retVal {XuSequenceRegion} |
	(self isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceRegion make: (self getActualFeHyperLink endNames)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSet} linkTypes

	"The various type documents describing this kind of Link. These documents are typically Editions with descriptions at each linkEnd key describing what is at that Link End.
	The reason for having several is to allow type hierarchies to be constructed and searched for, by including all super types of a link in its link type list.
	The Link should be endorsed with all the IDs of all the types.
	What if someone endorses it further (or unendorses it?)"
	
	| retVal {XuSet} |
	(self isBroken) ifTrue:
		[^XuSet makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSet makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSet make: (self getActualFeHyperLink linkTypes)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuHyperLink} withEnd: name {XuSequence} with: linkEnd {XuHyperRef} 

	"Change/add a Link end"
	
	| retVal {XuHyperLink} |
	(self isBroken) ifTrue:
		[^XuHyperLink makeBrokenBy: self].
	(name isBroken) ifTrue:
		[^XuHyperLink makeBrokenBy: name].
	(linkEnd isBroken) ifTrue:
		[^XuHyperLink makeBrokenBy: linkEnd].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuHyperLink makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuHyperLink make: (self getActualFeHyperLink withEnd: ((XuPromise getActual: name) cast: Sequence) with: ((XuPromise getActual: linkEnd) cast: FeHyperRef))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuHyperLink} withLinkTypes: types {XuSet} 

	"Replace the set of type documents describing this kind of Link"
	
	| retVal {XuHyperLink} |
	(self isBroken) ifTrue:
		[^XuHyperLink makeBrokenBy: self].
	(types isBroken) ifTrue:
		[^XuHyperLink makeBrokenBy: types].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuHyperLink makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuHyperLink make: (self getActualFeHyperLink withLinkTypes: ((XuPromise getActual: types) cast: FeSet))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuHyperLink} withoutEnd: name {XuSequence} 

	"Remove a Link end"
	
	| retVal {XuHyperLink} |
	(self isBroken) ifTrue:
		[^XuHyperLink makeBrokenBy: self].
	(name isBroken) ifTrue:
		[^XuHyperLink makeBrokenBy: name].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuHyperLink makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuHyperLink make: (self getActualFeHyperLink withoutEnd: ((XuPromise getActual: name) cast: Sequence))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuHyperLink methodsFor: 'promise access'!

{FeHyperLink} getActualFeHyperLink
	self isBroken
		ifFalse: [^super actualThing cast: FeHyperLink.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuHyperLink methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeHyperLink {FeHyperLink}
	super create: anFeHyperLink.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuHyperLink class
	instanceVariableNames: ''!

(XuHyperLink getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuHyperLink class methodsFor: 'pseudo-constructors'!

make: anFeHyperLink {FeHyperLink}
	^self create: anFeHyperLink!

{XuHyperLink} makeBroken: problem {Problem star}
	| broke {XuHyperLink} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuHyperLink} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !