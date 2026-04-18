'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:10 pm'!

Heaper subclass: #Electrician
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Electrician getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Electrician methodsFor: 'accessing'!

{Transporter} makeTransporter
	self subclassResponsibility! !

!Electrician methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !