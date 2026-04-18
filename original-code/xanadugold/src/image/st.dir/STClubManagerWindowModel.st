'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:03 pm'!

STWindowModel subclass: #STClubManagerWindowModel
	instanceVariableNames: '
		myController {StandardSystemController}
		myTop {View}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!STClubManagerWindowModel methodsFor: 'pinning'!

{void} pin: n {Integer}
	"set this user's pin status"!

{Integer} pinMask
	^Form gray!

pinMenu
	"we don't pin Permissions..."
	^nil!

pinWindow
	"toggle the pin status of this window"
	"can't pin a Permissions..."! !

!STClubManagerWindowModel methodsFor: 'private: window building'!

{void} attachButtonsTo: top {StandardSystemView}
	|  doneLeft doneTop |
	 doneLeft _ 0.1.
	 doneTop _ 0.91.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #done
				menu: nil
				action: #done)
			form: #doneButton)
		in: (doneLeft@doneTop extent: 0.3@0.05) borderWidth: 2.!

{void} attachPanesTo: top {StandardSystemView}
	"attach passage and link panes to the top view"

	top addSubView: (FMVCView create: self window nameEditBuilding)
		in: (0.0@0.0 extent: (0.8@0.2))
		borderWidth: 1! !

!STClubManagerWindowModel methodsFor: 'private: display
objects'!

{DisplayObject} addButton
	^'Add From Directory' asString asParagraph!

{DisplayObject} doneButton
	^'DONE' asString asParagraph!

{DisplayObject} manageButton
	^'Manage Club' asString asParagraph!

{DisplayObject} removeButton
	^'Remove' asString asParagraph!

{DisplayObject} sortButton
	^'Sort List' asString asParagraph! !

!STClubManagerWindowModel methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel} 

	Transcript nextPutAll: ('STUDMWindow update: ', change printString).
	Transcript nextPutAll: (' from: ', model printString); cr; endEntry! !

!STClubManagerWindowModel methodsFor: 'private: icons'!

downArrowForm
	^Resources fluidGet fetchResource: 'DownArrow'!

upArrowForm
	^Resources fluidVar fetchResource: 'UpArrow'! !

!STClubManagerWindowModel methodsFor: 'private: button actions'!

{void} done

	"This is executed when the done button is hit.  It should close the window."
	self window close.
	myWindow _ NULL.
	myController close! !

!STClubManagerWindowModel methodsFor: 'windowing'!

{void} open
	myTop  _ FMMVCWindow make: self with: 'Manage Club' with: 200@200.
	self attachButtonsTo: myTop.
	self attachPanesTo: myTop.
	myController _ myTop controller.
	myController initialize; open! !