'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:50 pm'!

Object subclass: #ErrAbort
	instanceVariableNames: ''
	classVariableNames: 'ErrorInSnefruSignal {UNKNOWN} '
	poolDictionaries: ''
	category: 'Xanadu-Snefru'!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ErrAbort class
	instanceVariableNames: ''!



!ErrAbort class methodsFor: 'accessing'!

{void} errAbort: msg {char star}

	#cerr << msg << '
'.
	self blast.ERROR.U.IN.U.SNEFRU raise.! !

!ErrAbort class methodsFor: 'exceptions: exceptions'!

blast.ERROR.U.IN.U.SNEFRU
	ErrorInSnefruSignal == nil ifTrue: [ErrorInSnefruSignal _ Signal new].
	ErrorInSnefruSignal notifierString: 'Error in Snefru'.
	^ErrorInSnefruSignal! !