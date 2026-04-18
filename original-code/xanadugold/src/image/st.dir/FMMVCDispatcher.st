'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:51 pm'!

Object subclass: #FMMVCDispatcher
	instanceVariableNames: '
		myEventQ {EventQueue}
		myTopControllers {MuSet of: FMController}
		myTopViews {MuSet of: Viewer}
		myWarpDrive {WarpDrive}
		myWindow {FMWindow}
		myDebug {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!



!FMMVCDispatcher methodsFor: 'private: creation'!

create: warpDrive {WarpDrive} with: window {FMWindow}
	myEventQ _ EventQueue create: PointTranslateDsp make.
	myWarpDrive _ warpDrive.
	myWindow _ window.
	myDebug _ false!

{void} destruct

	myEventQ destruct.
	myWarpDrive destruct.
	myEventQ _ NULL.
	myWarpDrive _ NULL.
	myWindow _ NULL.
	super destruct! !

!FMMVCDispatcher methodsFor: 'accessing'!

{BooleanVar} debug

	^ myDebug!

{void} dsp

	^ myEventQ dsp!

{void} setDebug: verity {BooleanVar}

	myDebug _ verity!

{void} setDsp: newDsp {Dsp}

	myEventQ setDsp: newDsp!

{WarpDrive} warpDrive
	^ myWarpDrive!

{FMWindow} window
	^ myWindow! !

!FMMVCDispatcher methodsFor: 'dispatching'!

{void} dispatchCycle
	| dWarp {Warp} |
	myEventQ checkEvents. "call the generator"
	dWarp _ myWindow warp. 
	[myEventQ isEmpty]
		whileFalse: 
			[| nextEvent {FMEvent} |
			nextEvent _ myEventQ nextEvent.
			[myDebug ifTrue: 
				[Transcript show: 'event : '; print: nextEvent; cr; 
endEntry]] smalltalkOnly.
			myWindow topControllers stepper 
				forEach: [:tc {FMController} | tc handle: nextEvent]].

	myWarpDrive setupDisplay.
	dWarp display: myWindow topFMViewer.
	myWarpDrive finishDisplay! !

!FMMVCDispatcher methodsFor: 'high level events'!

{void} submitMenuEvent: label {ID} 

	myEventQ queue: (FMHighLevelEvent
			make: Time millisecondClockValue
			with: (Sequence string: 'MENU')
			with: label)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMMVCDispatcher class
	instanceVariableNames: ''!



!FMMVCDispatcher class methodsFor: 'pseudo constructors'!

make: withDrive {WarpDrive} with: window {FMWindow}
	^ self create: withDrive with: window! !

!FMMVCDispatcher class methodsFor: 'smalltalk:
initialization'! !