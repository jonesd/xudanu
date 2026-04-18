'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:48 pm'!

Heaper subclass: #UrdiView
	instanceVariableNames: 'myUrdi {Urdi}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(UrdiView getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!UrdiView methodsFor: 'operations'!

{void} abortWrite!

{void} becomeRead!

{void} commitWrite
	myUrdi commitWrite!

{Int4} getDataSizeOfSnarf: snarf {SnarfID}
	^myUrdi getDataSizeOfSnarf: snarf!

{BooleanVar} isWriteView
	^true
	"^myStream name isWritable"!

{SnarfHandle} makeErasingHandle: snarfID {SnarfID}
	^myUrdi eraseHandle: snarfID!

{SnarfHandle} makeReadHandle: snarfID {SnarfID}
	^myUrdi getHandle: snarfID!

{void} thawHandles
	myUrdi commitWrite! !

!UrdiView methodsFor: 'smalltalk: create'!

create: urdi {Urdi}
	super create.
	myUrdi _ urdi! !