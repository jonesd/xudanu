'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:04 pm'!

XnModel subclass: #ConnectorModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-xmodel'!
ConnectorModel comment:
'Connects a bunch of models together. Several objects can send "changed: update" messages to this object, and then a bunch of objects can become dependents of this and watch for those changes.'!

(ConnectorModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ConnectorModel methodsFor: 'create'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ConnectorModel class
	instanceVariableNames: ''!

(ConnectorModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ConnectorModel class methodsFor: 'smalltalk: passe'!

make
	^self passe! !