'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:05 pm'!

Object subclass: #Boolean
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Objects'!
Boolean comment:
'Class Boolean is an abstract class that implements behavior common to true and false.  Its subclasses are True and False.

Subclasses must implement methods for 
	logical operations
		&
		not
		| 
	controlling
		and:
		or:
		ifTrue:
		ifFalse:
		ifTrue:ifFalse:
		ifFalse:ifTrue:
'!


!Boolean methodsFor: 'logical operations'!

& aBoolean 
	"Evaluating conjunction.  Evaluate the argument.  Answer true if both the
	receiver and the argument are true."

	self subclassResponsibility!

eqv: aBoolean 
	"Answer true if the receiver is equivalent to aBoolean."

	^self == aBoolean!

not
	"Negation.  Answer true if the receiver is false, answer false if the receiver is true."

	self subclassResponsibility!

xor: aBoolean 
	"Exclusive OR.  Answer true if the receiver is not equivalent to aBoolean."

	^(self == aBoolean) not!

| aBoolean 
	"Evaluating disjunction (OR).  Evaluate the argument.  Answer true if
	either the receiver or the argument is true."

	self subclassResponsibility! !

!Boolean methodsFor: 'controlling'!

and: alternativeBlock 
	"Nonevaluating conjunction.  If the receiver is true, answer the value of
	the argument, alternativeBlock; otherwise answer false without evaluating the
	argument."

	"Execution does not actually reach here because the expression is compiled in-line."

	self subclassResponsibility!

ifFalse: alternativeBlock 
	"If the receiver is true (i.e., the condition is true), then the value is 
	the true alternative, which is nil. Otherwise answer the result of 
	evaluating the argument, alternativeBlock. This method is typically 
	not invoked because ifTrue:/ifFalse: expressions are compiled in-line 
	for literal blocks."

	^self subclassResponsibility!

ifFalse: falseAlternativeBlock ifTrue: trueAlternativeBlock 
	"If the receiver is true (i.e., the condition is true), then answer the 
	value of the argument trueAlternativeBlock. If the receiver is false, 
	answer the result of evaluating the argument falseAlternativeBlock. 
	This method is typically not invoked because ifTrue:/ifFalse: 
	expressions are compiled in-line for literal blocks."

	^self subclassResponsibility!

ifTrue: alternativeBlock 
	"If the receiver is false (i.e., the condition is false), then the value is 
	the false alternative, which is nil. Otherwise answer the result of 
	evaluating the argument, alternativeBlock. This method is typically 
	not invoked because ifTrue:/ifFalse: expressions are compiled in-line 
	for literal blocks."

	^self subclassResponsibility!

ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock 
	"If the receiver is true (i.e., the condition is true), then answer the 
	value of the argument trueAlternativeBlock. If the receiver is false, 
	answer the result of evaluating the argument falseAlternativeBlock. 
	This method is typically not invoked because ifTrue:/ifFalse: 
	expressions are compiled in-line for literal blocks."

	^self subclassResponsibility!

or: alternativeBlock 
	"Nonevaluating disjunction.  If the receiver is false, answer the value of
	the argument, alternativeBlock; otherwise answer true without evaluating the
	argument."

	"Execution does not actually reach here because the expression is compiled in-line."

	self subclassResponsibility! !

!Boolean methodsFor: 'copying'!

deepCopy 
	"Receiver has two concrete subclasses, True and False.
	Only one instance of each should be made, so return self."

	^self!

shallowCopy 
	"Receiver has two concrete subclasses, True and False.
	Only one instance of each should be made, so return self."

	^self! !

!Boolean methodsFor: 'printing'!

storeOn: aStream
	"Append to the argument aStream a sequence of characters that is an
	expression whose evaluation creates an object similar to the receiver."

	self printOn: aStream! !

!Boolean methodsFor: 'testing'!

isManifest
	"Answer whether receiver is manifestly storable."

	^true! !

!Boolean methodsFor: 'fileIn/Out'!

storeBinaryOn: stream 
	"Put a binary representation of the receiver into stream."

	stream storeBoolean: self! !

!Boolean methodsFor: 'cxx stubble'!

makeProxy: comm {CommHandler}
	^self!

makeSheep: comm {CommHandler}
	^self!

sendSelfTo: trans! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Boolean class
	instanceVariableNames: ''!


!Boolean class methodsFor: 'instance creation'!

new
	"Provide an error notification that it is not appropriate
	to create an instance of the receiver."

	self error: 'You may not create any more Booleans - this is two-valued logic'! !

!Boolean class methodsFor: 'client protocol'!

{String} exportName
	"See Heape::exportName."

	^'BooleanValue'! !