'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:50 pm'!

Heaper subclass: #FMTextModel
	instanceVariableNames: '
		myParent {FMSuperTextModel}
		myIndexCache {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMTextModel comment:
'This is the abstract superclass of text models.  This is intended to provide the basic text accessing features.'!

(FMTextModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMTextModel methodsFor: 'testing'!

{UInt32} hashForEqual
	^ self asOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!FMTextModel methodsFor: 'protected: creation'!

create
	super create.
	myParent _ NULL.
	myIndexCache _ IntegerVar0!

create: withParent {FMSuperTextModel}

	super create.
	myParent _ withParent.
	myIndexCache _ IntegerVar0! !

!FMTextModel methodsFor: 'deferred: accessing'!

{IntegerVar} charCount
	"This methods returns the number of characters in the model."
	
	self subclassResponsibility!

{IntegerVar} charLimit
	"This method returns the maximum number of characters that this 
	model can return."

	self subclassResponsibility!

{MuWordArray} chars

	"This method returns all of the characters in the model"
	
	self subclassResponsibility! !

!FMTextModel methodsFor: 'subclass accessing'!

{IntegerVar} index

	"This method returns the index of the receiver within it's parent"
	
	^ myIndexCache!

{FMSuperTextModel} parent

	^ myParent!

{void} setIndex: newIndex {IntegerVar}
	"This method is used by FMSplitTextModels to set the index of their children.  This is a speed optimization."
	
	myIndexCache _ newIndex! !

!FMTextModel methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << ' on (' << self chars << ') '! !