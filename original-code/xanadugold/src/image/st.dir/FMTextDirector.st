'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:49 pm'!

FMDirector subclass: #FMTextDirector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(FMTextDirector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMTextDirector methodsFor: 'deferred: composing'!

{void} composeWith: layout {AbstractLayout} 
	"This method is used to force composition of a directed text view 
	with a new layout. This method allows the directors to accomplish 
	the layout actions and provides the director with an appropriate 
	layout in which to compose the text."

	self subclassResponsibility! !