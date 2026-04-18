'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:54 pm'!

FeDataHolder subclass: #FeActualDataHolder
	instanceVariableNames: 'myBeDataHolder {BeDataHolder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeActualDataHolder comment:
'Actually has a persistent individual DataHolder on the Server'!

(FeActualDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeActualDataHolder methodsFor: 'client accessing'!

{FeRangeElement} again
	"I'm completely reified.  Just return me."
	
	^self!

{PrimValue} value
	"The actual data value"
	
	^myBeDataHolder value! !

!FeActualDataHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^myBeDataHolder!

{BeRangeElement} getOrMakeBe

	^myBeDataHolder! !

!FeActualDataHolder methodsFor: 'private: create'!

create: be {BeDataHolder}

	super create.
	myBeDataHolder := be.! !

!FeActualDataHolder methodsFor: 'destruct'!

{void} destruct

	myBeDataHolder removeFeRangeElement: self.
	super destruct.! !