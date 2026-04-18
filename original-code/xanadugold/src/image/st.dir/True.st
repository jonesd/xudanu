'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:08 pm'!

Boolean subclass: #True
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Objects'!
True comment:
'Class True describes the behavior of its sole instance, true, logical assertion.'!


!True methodsFor: 'logical operations'!

& alternativeObject 
	"Evaluating conjunction.  Answer alternativeObject since receiver is true."

	^alternativeObject!

not
	"Negation--answer false since the receiver is true."

	^false!

| aBoolean 
	"Evaluating disjunction (OR) -- answer true since the receiver is true."

	^self! !

!True methodsFor: 'controlling'!

and: alternativeBlock 
	"Nonevaluating conjunction -- answer the value of alternativeBlock since
	the receiver is true."

	"Execution does not actually reach here because the expression is compiled in-line."

	^alternativeBlock value!

ifFalse: alternativeBlock 
	"Since the condition is true, the value is the true alternative, which 
	is nil. This method is typically not invoked because ifTrue:/ifFalse: 
	expressions are compiled in-line for literal blocks."

	^nil!

ifFalse: falseAlternativeBlock ifTrue: trueAlternativeBlock 
	"Answer the value of trueAlternativeBlock. This method is typically 
	not invoked because ifTrue:/ifFalse: expressions are compiled in-line 
	for literal blocks."

	^trueAlternativeBlock value!

ifTrue: alternativeBlock 
	"Answer the value of alternativeBlock. This method is typically not 
	invoked because ifTrue:/ifFalse: expressions are compiled in-line for 
	literal blocks."

	^alternativeBlock value!

ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock 
	"Answer the value of trueAlternativeBlock. This method is typically 
	not invoked because ifTrue:/ifFalse: expressions are compiled in-line 
	for literal blocks."

	^trueAlternativeBlock value!

or: alternativeBlock 
	"Nonevaluating disjunction -- answer true since the receiver is true."

	"Execution does not actually reach here because the expression is compiled in-line."

	^self! !

!True methodsFor: 'printing'!

isLiteral
	"Answer that the receiver has a literal text form recognized 
	by the compiler. "

	^true!

printOn: aStream 
	"Print true."

	aStream nextPutAll: 'true'! !

!True methodsFor: 'error handling'!

assert
	"This only succeeds for True."

	^self!

assert: aString
	"This only succeeds for True."

	^self! !

!True methodsFor: 'cxx special'!

ifdef: a
	a value!

ifdef: a else: b
	a value!

ifndef: a!

ifndef: a else: b
	b value! !