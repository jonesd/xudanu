'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:48 pm'!

PopUpMenu subclass: #ActionMenu
	instanceVariableNames: 'selectors '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
ActionMenu comment:
'ActionMenus carry an array of selectors which correspond to the listed menu items.  This allows a menu to stand alone in parameterizing a controller, since the controller just sends the selector to its model.  This saves maintaining two parallel structures, one for the names in the menu, and one for the selectors to be performed.  ActionMenus allow the pluggable views experiment (TextView, SelectionInListView) to handle menus much easier than having pairs of variables for the menu and its associated selectors.  Obviously these menus eagerly await a proper objectification of protocol.

Instance Variables:
	selectors 	<Array of: Symbols>'!


!ActionMenu methodsFor: 'action symbols'!

selectorAt: index
	"Answer the message selector at location index in the stored array."

	^ selectors at: index!

setSelectors: selArray
	"Set the argument selArray to be the array of message selectors."

	selectors _ selArray! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActionMenu class
	instanceVariableNames: ''!
ActionMenu class comment:
'This subclass of PopUpMenu carries a list of selectors corresponding to the various menu items.
Therefore, with only the menu as a parameter, a controller can display the menu and then
tell its model to perform the associated selector.  This saves maintaining two parallel structures,
one for the names in the menu, and one for the selectors to be performed.'!


!ActionMenu class methodsFor: 'instance creation'!

labelList: anArray selectors: selArray 
	"Answer a menu with labels from anArray and selectors from selArray."

	|menu|
	menu _ self labelList: anArray.
	menu setSelectors: selArray.
	^menu!

labels: aString lines: anArray selectors: selArray 
	"Answer a menu with labels from aString, lines from anArray, and selectors from selArray."

	| aMenu |
	aMenu _ self labels: aString lines: anArray.
	aMenu setSelectors: selArray.
	^ aMenu!

labels: aString selectors: selArray 
	"Answer a menu with labels from aString and selectors from selArray."

	^ self labels: aString lines: nil selectors: selArray! !

!ActionMenu class methodsFor: 'confirmation'!

confirm  
	"Confirm that the user really wants to take the action requested."

	"ActionMenu confirm"
	^ (ActionMenu labels: 'confirm\abort' withCRs selectors: nil) startUp = 1!

confirm: request
	"Confirm that the user really wants to take the action requested."

	"ActionMenu confirm: 'Do you really want to confirm this?'"
	"ActionMenu confirm: ('Do you really want to confirm this?' asText 
		emphasizeFrom: 4 to: 6 with: 2)"

	^ ((ActionMenu labels: 'confirm\abort' withCRs selectors: nil) startUpWithHeading: request) = 1! !