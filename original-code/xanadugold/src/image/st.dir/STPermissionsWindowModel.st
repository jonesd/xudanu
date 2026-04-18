'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:07 pm'!

STWindowModel subclass: #STPermissionsWindowModel
	instanceVariableNames: '
		myController {StandardSystemController}
		myTop {View}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!STPermissionsWindowModel methodsFor: 'pinning'!

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

!STPermissionsWindowModel methodsFor: 'windowing'!

{void} open
	| number |
	number _ self window clubNames count.
	myTop  _ FMMVCFloatingWindow create: self with: 150@(50 + (12*number)).
	self attachButtonsTo: myTop.
	self attachPanesTo: myTop.
	myController _ myTop controller.
	myController initialize; openNoTerminateDisplayAt: (200@200)! !

!STPermissionsWindowModel methodsFor: 'private: window building'!

{void} attachButtonsTo: top {StandardSystemView}
	|  doneLeft doneTop topSize doneHeight doneWidth |
	topSize _ top minimumSize.
	doneHeight _ ((25 / topSize y) max: 0.05) min: 0.1.
	doneWidth _ ((40 / topSize x) max: 0.4) min: 0.75.
	doneLeft _ (1 - doneWidth) / 2.
	doneTop _ (1 - doneHeight).
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #done
				menu: nil
				action: #done)
			form: #doneButton)
		in: (doneLeft@doneTop extent: doneWidth@doneHeight) borderWidth: 2.!

{void} attachPanesTo: top {StandardSystemView}
	"attach passage and link panes to the top view"

	top addSubView: (FMVCScrolledView make: self window permissionsListBuilding)
		in: (0.0@0.0 extent: (1.0@0.9))
		borderWidth: 1! !

!STPermissionsWindowModel methodsFor: 'private: button actions'!

{void} done

	"This is executed when the done button is hit.  It should close the window."
	self window close.
	myWindow _ NULL.
	myController close! !

!STPermissionsWindowModel methodsFor: 'private: display objects'!

{DisplayObject} doneButton
	^'DONE' asString asParagraph! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STPermissionsWindowModel class
	instanceVariableNames: ''!



!STPermissionsWindowModel class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	self REQUIRES: TapestryAppModel. 
	self REQUIRES: FMResourceManager.
	Resources fluidGet storeImage: 'box'
		with: (Image make.void: (Form extent: 10@11
				fromArray: #( 65472 32832 32832 32832 32832 32832 32832 32832 32832 32832 65472)
				offset: 0@0)).
	Resources fluidGet storeImage: 'checkedBox'
		with: (Image make.void: (Form extent: 10@11
				fromArray: #( 65472 32832 33216 33344 33344 33856 33856 51264 43072 36928 65472)
				offset: 0@0))! !