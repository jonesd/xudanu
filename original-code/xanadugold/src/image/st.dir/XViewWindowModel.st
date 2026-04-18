'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:40 pm'!

XnModel subclass: #XViewWindowModel
	instanceVariableNames: 'myWindow {WindowModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!XViewWindowModel methodsFor: 'accessing'!

{WindowModel} window
	^myWindow! !

!XViewWindowModel methodsFor: 'create'!

create 
	super create.
	myWindow _ NULL.
	myWindow addDependent: self!

create: window {WindowModel}
	super create.
	myWindow _  window.
	myWindow addDependent: self! !

!XViewWindowModel methodsFor: 'windowing'!

{void} open
 	self subclassResponsibility! !

!XViewWindowModel methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
	  <<  'myWindow = ' <<  myWindow << ')'! !