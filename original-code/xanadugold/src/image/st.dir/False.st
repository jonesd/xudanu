'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:05 pm'!

Boolean subclass: #False
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Objects'!
False comment:
'Class False describes the behavior of its sole instance, false, logical negation.'!


!False methodsFor: 'logical operations'!

& alternativeObject 
	"Evaluating conjunction.  Answer false since receiver is false."

	^self!

not
	"Negation -- answer true since the receiver is false."

	^true!

| aBoolean 
	"Evaluating disjunction (OR) -- answer with the argument, aBoolean."

	^aBoolean! !

!False methodsFor: 'controlling'!

and: alternativeBlock 
	"Nonevaluating conjunction -- answer with false since the receiver is false."

	"Execution does not actually reach here because the expression is compiled in-line."

	^self!

ifFalse: alternativeBlock 
	"Answer the value of alternativeBlock. This method is typically not 
	invoked because ifTrue:/ifFalse: expressions are compiled in-line for 
	literal blocks."

	^alternativeBlock value!

ifFalse: falseAlternativeBlock ifTrue: trueAlternativeBlock 
	"Answer the value of falseAlternativeBlock. This method is typically 
	not invoked because ifTrue:/ifFalse: expressions are compiled in-line 
	for literal blocks."

	^falseAlternativeBlock value!

ifTrue: alternativeBlock 
	"Since the condition is false, answer the value of the false 
	alternative, which is nil. This method is typically not invoked 
	because ifTrue:/ifFalse: expressions are compiled in-line for literal 
	blocks."

	^nil!

ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock 
	"Answer the value of falseAlternativeBlock. This method is typically 
	not invoked because ifTrue:/ifFalse: expressions are compiled in-line 
	for literal blocks."

	^falseAlternativeBlock value!

or: alternativeBlock 
	"Nonevaluating disjunction -- answer value of alternativeBlock."

	"Execution does not actually reach here because the expression is compiled in-line."

	^alternativeBlock value! !

!False methodsFor: 'printing'!

isLiteral
	"Answer that the receiver has a literal text form recognized 
	by the compiler. "

	^true!

printOn: aStream 
	"Print false."

	aStream nextPutAll: 'false'! !

!False methodsFor: 'cxx special'!

ifdef: a!

ifdef: a else: b
	b value!

ifndef: a
	a value!

ifndef: a else: b
	a value! !