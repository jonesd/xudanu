'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:05 pm'!

STWindowModel subclass: #STLoginWindowModel
	instanceVariableNames: '
		myController {StandardSystemController}
		myTop {View}
		myAuthenticationView {View}
		myAuthenticationTemp {Object}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!STLoginWindowModel methodsFor: 'create'!

create: window {WindowModel}
	super create: window.
	window lockVar addDependent: self.
	myAuthenticationView _ NULL.
	myAuthenticationTemp _ NULL! !

!STLoginWindowModel methodsFor: 'windowing'!

{void} attachPanesTo: top {StandardSystemView}
	"attach passage and link panes to the top view"
	top addSubView: (FMVCScrolledView make: self window listBuilding)
		in: (0.05@0 corner: 0.95@0.8)
		borderWidth: 1!

{void} open
	myTop  _ FMMVCWindow create: self with: 'Login' with: 250@275.
	self attachPanesTo: myTop.
	myController _ myTop controller.
	myController initialize; open! !

!STLoginWindowModel methodsFor: 'private: display objects'!

{DisplayObject} booButton
	^'BOO!!' asString asParagraph!

{DisplayObject} loginButton
	^'Login' asString asParagraph!

{DisplayObject} wallButton
	^'|| WALL ||' asString asParagraph! !

!STLoginWindowModel methodsFor: 'private: button actions'!

boo

	self window boo!

login
	self changed: #login.
	MatchLock problems.PasswordDoesNotMatch handle: [:ex | myTop flash.
		^VOID]
		do: [self window match: (Sequence string: myAuthenticationTemp asString)]!

wall! !

!STLoginWindowModel methodsFor: 'private: authenticate views'!

{void} attachBooButtonTo: top {StandardSystemView}
	|  doneLeft doneTop topSize doneHeight doneWidth |
	topSize _ top minimumSize.
	doneHeight _ ((25 / topSize y) max: 0.05) min: 0.1.
	doneWidth _ ((40 / topSize x) max: 0.4) min: 0.75.
	doneLeft _ (1 - doneWidth) / 2.
	doneTop _ (1 - doneHeight).
	top addSubView: (myAuthenticationView _ CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #boo
				menu: nil
				action: #boo)
			form: #booButton)
		in: (doneLeft@doneTop extent: doneWidth@doneHeight) borderWidth: 2.!

{void} attachLoginViewTo: top {StandardSystemView} 
	| aLoginView |
	"self halt."
	top addSubView: (aLoginView _ HolderView new model: self)
		in: (0.05 @ 0.825 extent: 0.9 @ 0.15)
		borderWidth: 2.
	aLoginView addSubView: 
		(PasswordView on: self aspect: #passwd change: #passwd: menu: nil)
		in: ((0.0 @ 0.0) extent: (1.0 @ 0.5))
		borderWidth: 1.
	aLoginView addSubView: (CenteredFormView
				on: self
				with: (ButtonAndMenuController on: self
						button: #login menu: nil action: #login)
				form: #loginButton)
		in: ((0.3 @ 0.55) extent: (0.4 @ 0.4))
		borderWidth: 2.
	myAuthenticationView _ aLoginView!

{void} attachWallButtonTo: top {StandardSystemView}
	|  doneLeft doneTop topSize doneHeight doneWidth |
	topSize _ top minimumSize.
	doneHeight _ ((25 / topSize y) max: 0.05) min: 0.1.
	doneWidth _ ((40 / topSize x) max: 0.4) min: 0.75.
	doneLeft _ (1 - doneWidth) / 2.
	doneTop _ (1 - doneHeight).
	top addSubView: (myAuthenticationView _ CenteredFormView on: self
			with: (ButtonAndMenuController on: self
				button: #wall
				menu: nil
				action: #wall)
			form: #wallButton)
		in: (doneLeft@doneTop extent: doneWidth@doneHeight) borderWidth: 2.!

{void} setupAuthenticate: lock {Lock}

	myAuthenticationView ~~ NULL
		ifTrue: [myTop releaseSubView: myAuthenticationView.
			myAuthenticationView _ NULL.
			self changed].
	lock == NULL ifTrue: [^ VOID].
	(lock isKindOf: BooLock)
		ifTrue: [self attachBooButtonTo: myTop. self changed]
	ifFalse: [(lock isKindOf: MatchLock)
		ifTrue: [self attachLoginViewTo: myTop. self changed]
	ifFalse: [self attachWallButtonTo: myTop. self changed]].! !

!STLoginWindowModel methodsFor: 'private: password'!

{String} passwd
	^nil!

{void} passwd: newPass
	myAuthenticationTemp _ newPass.
	^ true! !

!STLoginWindowModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel}

	sender == self window lockVar ifFalse: [^ VOID].
	self setupAuthenticate: self window lockVar fetchValue! !