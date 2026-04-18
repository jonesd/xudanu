'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:04 pm'!

SimpleUpdateRecord subclass: #NewContentsUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-xmodel'!
NewContentsUpdate comment:
'Used in various places to indicate that an aspect of the model one may think of as its "contents" have changed.'!

(NewContentsUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NewContentsUpdate class
	instanceVariableNames: ''!

(NewContentsUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NewContentsUpdate class methodsFor: 'make'!

{NewContentsUpdate INLINE} make
	"Returns a NewContentsUpdate record"
	
	^theRecord cast: NewContentsUpdate! !