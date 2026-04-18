'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:17 pm'!

Thunk subclass: #TranscriptThunk
	instanceVariableNames: '
		message {MuWordArray}
		arg {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(TranscriptThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TranscriptThunk methodsFor: 'action'!

{void} execute
	"Execute the action defined by this thunk."
	
	cerr << message << '  ' << arg << '
'! !

!TranscriptThunk methodsFor: 'create'!

create: xmessage{MuWordArray} with: xarg{Heaper}
	super create.
	message _ xmessage.
	arg _ xarg! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TranscriptThunk class
	instanceVariableNames: ''!

(TranscriptThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TranscriptThunk class methodsFor: 'pseudo constructors'!

{Thunk} make: text {MuWordArray} with: item {Heaper}
	^ self create: text with: item! !