'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:37 pm'!

Turtle subclass: #MockTurtle
	instanceVariableNames: '
		myAgenda {Agenda | NULL}
		myBootCategory {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
MockTurtle comment:
'The MockTurtle is used with the FakePacker.  All it provides is an Agenda'!

(MockTurtle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!MockTurtle methodsFor: 'accessing'!

{Category} bootCategory
	^ myBootCategory!

{Heaper} bootHeaper
	self unimplemented.
	^NULL "fodder"!

{Cookbook} cookbook
	self willNotImplement.
	^ NULL!

{Counter} counter
	self willNotImplement.
	^NULL "fodder"!

{Agenda | NULL} fetchAgenda

	^myAgenda!

{XcvrMaker} protocol
	self willNotImplement.
	^ NULL!

{void} saveBootHeaper: boot {Heaper}
	"Right"
	self willNotImplement.!

{void} setProtocol: xcvrMaker {XcvrMaker} with: book {Cookbook}
	"Right"
	self willNotImplement.! !

!MockTurtle methodsFor: 'protected: creation'!

create: bootCategory {Category}
	super create.
	(CurrentPacker fluidGet cast: FakePacker) storeTurtle: self.
	myAgenda _ NULL.
	myBootCategory _ bootCategory.
	myAgenda _ Agenda make.! !

!MockTurtle methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myAgenda _ receiver receiveHeaper.
	myBootCategory _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myAgenda.
	xmtr sendHeaper: myBootCategory.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MockTurtle class
	instanceVariableNames: ''!

(MockTurtle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!MockTurtle class methodsFor: 'pseudo-constructor'!

{Turtle} make: category {Category}
	^ self create: category! !