'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:07 pm'!

STWindowModel subclass: #STUDMWindowModel
	instanceVariableNames: '
		myController {StandardSystemController}
		myTop {View}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!STUDMWindowModel methodsFor: 'pinning'!

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

!STUDMWindowModel methodsFor: 'private: icons'!

downArrowForm
	^Resources fluidVar fetchResource: 'DownArrow'!

upArrowForm
	^Resources fluidVar fetchResource: 'UpArrow'! !

!STUDMWindowModel methodsFor: 'private: window building'!

{void} attachButtonsTo: top {StandardSystemView}
	|  doneLeft doneTop topSize doneHeight doneWidth |
	doneTop _ 0.71.
	topSize _ top minimumSize.
	doneHeight _ ((20 / topSize y) max: 0.05) min: 0.1.
	doneWidth _ ((60 / topSize x) max: 0.2) min: 0.4.
	doneLeft _ 0.125.
	
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #done
				menu: nil
				action: #done)
			form: #doneButton)
		in: (doneLeft@doneTop extent: doneWidth@doneHeight) borderWidth: 2.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #newClub
				menu: nil
				action: #newClub)
			form: #newClubButton)
		in: ((doneLeft+doneWidth+0.05)@doneTop extent: doneWidth@doneHeight) borderWidth: 2.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #renameClub
				menu: nil
				action: #renameClub)
			form: #renameButton)
		in: ((doneLeft+(2*doneWidth)+0.1)@doneTop extent: doneWidth@doneHeight) borderWidth: 2.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #removeClub
				menu: nil
				action: #removeClub)
			form: #removeButton)
		in: ((doneLeft+(2*doneWidth)+0.1)@(doneTop + doneHeight + 0.01) extent: doneWidth@doneHeight) borderWidth: 2.

	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #rearrangeUp
				menu: nil
				action: #rearrangeUp)
			form: #upArrowForm)
		in: (0.48@0.05 extent: (0.05@0.05)) borderWidth: 1.
	top addSubView: (CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #rearrangeDown
				menu: nil
				action: #rearrangeDown)
			form: #downArrowForm)
		in: (0.48@0.65 extent: (0.05@0.05)) borderWidth: 1.!

{void} attachPanesTo: top {StandardSystemView}
	"attach passage and link panes to the top view"

	top addSubView: (FMVCScrolledView make: self window udmListBuilding)
		in: (0.0@0.0 extent: (0.45@0.7))
		borderWidth: 1.
	top addSubView: (FMVCView make: self window clubManagerPane building)
		in: (0.55@0.1 extent: (0.40@0.1))
		borderWidth: 1.! !

!STUDMWindowModel methodsFor: 'private: display
objects'!

{DisplayObject} addButton
	^'Add From Directory' asParagraph!

{DisplayObject} deleteButton
	^'Destroy Club' asParagraph!

{DisplayObject} doneButton
	^'DONE' asParagraph!

{DisplayObject} newClubButton
	^'New Club' asParagraph!

{DisplayObject} removeButton
	^'Remove' asParagraph!

{DisplayObject} renameButton

	^ 'Rename' asParagraph!

{DisplayObject} sortButton
	^'Sort List' asParagraph! !

!STUDMWindowModel methodsFor: 'private: button actions'!

{void} deleteClub
	self window deleteClub!

{void} done
	"This is executed when the done button is hit. It should close the 
	window."

	myTop ~~ NULL
		ifTrue: 
			[| temp |
			temp _ myTop.
			myWindow ~~ NULL ifTrue: [myWindow destroy. myWindow _ NULL].
			myTop _ NULL.
			temp controller close]!

newClub
	ApplicationModel blast.ClubNameAlreadyExists handle: 
		[:ex | ^BinaryChoice message: 'That club name already exists']
		do: [self window newClub]!

{void} rearrangeDown

	self window rearrangeList: 1!

{void} rearrangeUp
	self window rearrangeList: -1!

{void} removeClub
	self window removeClub!

renameClub
	self window renameClub! !

!STUDMWindowModel methodsFor: 'windowing'!

{void} open
	
	myTop  _ FMMVCWindow create: self with: 'Club List' with: 300@200.
	self attachButtonsTo: myTop.
	self attachPanesTo: myTop.
	myController _ myTop controller.
	myController initialize; openNoTerminateDisplayAt: (200@200).!

release
	self done.
	super release! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STUDMWindowModel class
	instanceVariableNames: ''!



!STUDMWindowModel class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: TapestryAppModel.
	self REQUIRES: FMResourceManager. 
	Resources fluidGet storeResource: 'UpArrow' with: (Form
			extent: 10 @ 11
			fromArray: #(65472 32832 32832 32832 32832 32832 32832 32832 32832 32832 65472 )
			offset: 0 @ 0).
	Resources fluidGet storeResource: 'DownArrow' with: (Form
			extent: 10 @ 11
			fromArray: #(65472 32832 33216 33344 33344 33856 33856 51264 43072 36928 65472 )
			offset: 0 @ 0)! !