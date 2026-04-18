'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:04 pm'!

UpdateRecord subclass: #SimpleUpdateRecord
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-xmodel'!
SimpleUpdateRecord comment:
'The abstract superclass provided as a convenience for kinds of update records for which all the information is simply in the type.  For all these, we simply allocate an instance at dynamic initialization time and reuse it.'!

(SimpleUpdateRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SimpleUpdateRecord methodsFor: 'create'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SimpleUpdateRecord class
	instanceVariableNames: 'theRecord {SimpleUpdateRecord} '!

(SimpleUpdateRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SimpleUpdateRecord class methodsFor: 'smalltalk: initialization'!

initTimeInherited

	theRecord _ self create!

linkTimeInherited

	theRecord _ NULL!

suppressInitTimeInherited!

suppressLinkTimeInherited! !