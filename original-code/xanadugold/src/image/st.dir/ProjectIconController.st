'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:21 pm'!

IconController subclass: #ProjectIconController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Projects'!
ProjectIconController comment:
'Class ProjectIconController overrides the operate menu for an IconController menu so that ''enter'' is available on the operate button menu.'!


!ProjectIconController methodsFor: 'menu messages'!

enter
	"Enter the project."

	view topView model enter! !

!ProjectIconController methodsFor: 'private: private'!

yellowButtonMenu
	"Menu for some icon in the smalltalk project management system, which is not used at Xanadu."
	
	^PopUpMenu fromArray: #(
		('expand'	expand	'')
		('enter'		enter	'') ).! !

!ProjectIconController methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for some icon in the smalltalk project management system, which is not used at Xanadu."
	
	self passe! !