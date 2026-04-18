'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:38:54 pm'!

((CxxSystemOrganization tree childNamed: #garbage) ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: #garbage) destroyFiles]!

Thunk subclass: #GCMaxInterval
	instanceVariableNames: 'interval {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-garbage'!

(GCMaxInterval getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!GCMaxInterval methodsFor: 'operate'!

{void} execute
	"Ignored in Smalltalk"! !

!GCMaxInterval methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	interval _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: interval.! !Thunk subclass: #GCMinInterval
	instanceVariableNames: 'interval {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-garbage'!

(GCMinInterval getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!GCMinInterval methodsFor: 'operate'!

{void} execute
	"Ignored in Smalltalk"! !

!GCMinInterval methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	interval _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: interval.! !
(CxxSystemOrganization fileNamed: 'garbage')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'garbage')
	addClass: GCMinInterval
getOrMakeCxxClassDescription in: #private;
	addClass: GCMaxInterval
getOrMakeCxxClassDescription in: #private!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: #garbage value: #file) yourself))!