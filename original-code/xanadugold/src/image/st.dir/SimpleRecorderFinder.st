'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:02 pm'!

AbstractRecorderFinder subclass: #SimpleRecorderFinder
	instanceVariableNames: 'myRangeElement {BeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SimpleRecorderFinder comment:
'A finder which holds onto a RangeElement and looks for ResultRecorders which might want to record it NOT.A.TYPE '!

(SimpleRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!SimpleRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}

	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	((recorder accepts: self rangeElement) and: [self shouldTrigger: recorder with: fossil]) ifTrue:
		[(RecorderTrigger make: fossil with: myRangeElement) schedule]!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}
	"Whether the recorder should be triggered with my RangeElement"
	
	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}
	with: element {BeRangeElement}

	super create: flags.
	myRangeElement := element.! !

!SimpleRecorderFinder methodsFor: 'protected:'!

{BeEdition} edition

	^myRangeElement cast: BeEdition!

{BeRangeElement} rangeElement

	^myRangeElement!

{BeWork} work

	^myRangeElement cast: BeWork! !

!SimpleRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	self subclassResponsibility! !

!SimpleRecorderFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRangeElement _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRangeElement.! !