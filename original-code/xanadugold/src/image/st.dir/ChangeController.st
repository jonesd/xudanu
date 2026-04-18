'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:22 pm'!

StringHolderController subclass: #ChangeController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Changes'!
ChangeController comment:
'Class ChangeController represents the text view controller for a change browser.'!


!ChangeController methodsFor: 'menu messages'!

accept
	"Accept cannot doe anything useful, so just flash the view."

	^view flash! !