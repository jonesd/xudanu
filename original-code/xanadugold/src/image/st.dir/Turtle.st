'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:43 pm'!

Abraham subclass: #Turtle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(Turtle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!Turtle methodsFor: 'accessing'!

{Category} bootCategory
	self subclassResponsibility!

{Heaper} bootHeaper
	self subclassResponsibility!

{Cookbook} cookbook
	self subclassResponsibility!

{Counter} counter
	self subclassResponsibility!

{Agenda | NULL} fetchAgenda
	"Under all normal conditions, a Turtle has an Agenda.  However, during the construction of a Turtle, there may arise situations when a piece of code is invoked which normally asks the Turtle for its agenda before the Turtle is mature enough to have one."
	
	self subclassResponsibility!

{Agenda} getAgenda
	"See Turtle::fetchAgenda()"
	
	| result {Agenda | NULL} |
	result _ self fetchAgenda.
	result == NULL
		ifTrue: [Heaper BLAST: #TurtleNotMature].
	^result!

{XcvrMaker} protocol
	self subclassResponsibility!

{void} saveBootHeaper: boot {Heaper}
	self subclassResponsibility!

{void} setProtocol: xcvrMaker {XcvrMaker} with: book {Cookbook}
	self subclassResponsibility! !

!Turtle methodsFor: 'protected: creation'!

create
	super create!

create: hash {UInt32}
	super create: hash! !

!Turtle methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Turtle class
	instanceVariableNames: ''!

(Turtle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!Turtle class methodsFor: 'pseudo-constructors'!

make: cookbook {Cookbook} with:  bootCategory {Category} with: maker {XcvrMaker}
	^SimpleTurtle make: cookbook with: bootCategory with: maker! !