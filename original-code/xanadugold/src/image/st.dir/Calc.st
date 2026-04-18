'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:05 pm'!

Heaper subclass: #Calc
	instanceVariableNames: '
		myI {Int32}
		myFoo {FooTest}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Calc'!

(Calc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #EQ; add: #BY.PROXY; yourself)!

!Calc methodsFor: 'proxy accessing'!

{void PROXY} plantPopSensor: sensor {PopSensor}

	self subclassResponsibility!

{Rational PROXY} pop

	self subclassResponsibility!

{void PROXY} push: rat {Rational}

	self subclassResponsibility!

{void PROXY} times

	self subclassResponsibility!

{void PROXY} timesArg: rat {Rational}

	self subclassResponsibility! !

!Calc methodsFor: 'accessing'!

{FooTest} getFoo

	^myFoo!

{Int32} getMyI

	^myI! !

!Calc methodsFor: 'protected: creation'!

create: i {int}
	super create.
	myI _ i.
	myFoo _ FooTest make.! !

!Calc methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '( ' << myI << ', ' << myFoo << ')'! !

!Calc methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myI _ receiver receiveInt32.
	myFoo _ receiver receiveHeaper.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myI.
	xmtr sendHeaper: myFoo.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Calc class
	instanceVariableNames: ''!

(Calc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #EQ; add: #BY.PROXY; yourself)!

!Calc class methodsFor: 'exceptions: exceptions'!

problems.StackOverflow
	^self signals: #(StackOverflow)!

problems.StackUnderflow

	^self signals: #(StackUnderflow)! !