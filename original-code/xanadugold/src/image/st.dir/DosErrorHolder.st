'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:57 pm'!

OSErrorHolder subclass: #DosErrorHolder
	instanceVariableNames: ''
	classVariableNames: 'ErrorSignals '
	poolDictionaries: ''
	category: 'OS-Dos'!
DosErrorHolder comment:
'MS-DOS error codes are interpreted here.

Class Variables:
	ErrorSignals		<IdentityDictionary> of Signals
'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DosErrorHolder class
	instanceVariableNames: ''!


!DosErrorHolder class methodsFor: 'class initialization'!

hookupTo: platname
	"Set-up to deal with a particular platform (w.r.t. error codes)."!

initialize
	"DosErrorHolder initialize."

	self initErrorSignals! !

!DosErrorHolder class methodsFor: 'error reporting'!

errorDescriptionFor: aSmallInteger
	"returns a string describing the error."

	<primitive: 697>
	^super errorDescriptionFor: aSmallInteger!

reportOn: anErrorHolder 
	"As an error reporter, report the error contained by this holder."
	"This means, map the error holder's error code to the error name, 
	map the error name to an error signal, and raise the signal."

	anErrorHolder errorCode == nil
		ifTrue:	[^self unsupportedOperationSignal raiseWith: anErrorHolder].
	^(ErrorSignals at: anErrorHolder errorCode
		ifAbsent: [self errorSignal])
		raiseWith: anErrorHolder!

reportProceedingOn: anErrorHolder 
	"As an error reporter, report the (proceedable) error contained by this holder."
	"This means, map the error holder's error code to the error name, 
	map the error name to an error signal, and raise the signal."

	^(ErrorSignals at: anErrorHolder errorCode
		ifAbsent: [self errorSignal])
		raiseRequestWith: anErrorHolder! !

!DosErrorHolder class methodsFor: 'private: private'!

initErrorSignals
	"DosErrorHolder initErrorSignals"

	ErrorSignals _ IdentityDictionary new: 94.
	ErrorSignals at: -99 put: self errorSignal.
	ErrorSignals at: -1 put: self badArgumentsSignal.
	ErrorSignals at: -2 put: self rangeErrorSignal.
	ErrorSignals at: -3 put: self inappropriateOperationSignal.
	ErrorSignals at: -4 put: self existingReferentSignal.
	ErrorSignals at: 1 put: self illegalOperationSignal.
	ErrorSignals at: 2 put: self nonexistentSignal.
	ErrorSignals at: 3 put: self nonexistentSignal.
	ErrorSignals at: 4 put: self noResourcesSignal.
	ErrorSignals at: 5 put: self noPermissionsSignal.
	ErrorSignals at: 6 put: self badAccessorSignal.
	ErrorSignals at: 7 put: self errorSignal. "??"
	ErrorSignals at: 8 put: self noMemorySignal.
	ErrorSignals at: 9 put: self badArgumentsSignal.
	ErrorSignals at: 10 put: self badArgumentsSignal.
	ErrorSignals at: 11 put: self badArgumentsSignal.
	ErrorSignals at: 12 put: self badArgumentsSignal.
	ErrorSignals at: 13 put: self badArgumentsSignal.
	ErrorSignals at: 15 put: self errorSignal. "??"
	ErrorSignals at: 16 put: self noPermissionsSignal.
	ErrorSignals at: 17 put: self illegalOperationSignal.
	ErrorSignals at: 18 put: self noResourcesSignal. "??"
	ErrorSignals at: 19 put: self noPermissionsSignal.
	ErrorSignals at: 20 put: self unavailableReferentSignal.
	ErrorSignals at: 21 put: self notReadySignal.
	ErrorSignals at: 22 put: self inappropriateReferentSignal.
	ErrorSignals at: 23 put: self transferFaultSignal.
	ErrorSignals at: 24 put: self rangeErrorSignal.
	ErrorSignals at: 25 put: self transferFaultSignal.
	ErrorSignals at: 26 put: self transferFaultSignal.
	ErrorSignals at: 27 put: self transferFaultSignal.
	ErrorSignals at: 28 put: self notReadySignal.
	ErrorSignals at: 29 put: self transferFaultSignal.
	ErrorSignals at: 30 put: self transferFaultSignal.
	ErrorSignals at: 31 put: self errorSignal.
	ErrorSignals at: 32 put: self noPermissionsSignal.
	ErrorSignals at: 33 put: self noPermissionsSignal.
	ErrorSignals at: 34 put: self inappropriateReferentSignal.
	ErrorSignals at: 35 put: self invalidArgumentsSignal.
	ErrorSignals at: 50 put: self unsupportedOperationSignal.
	ErrorSignals at: 51 put: self peerFaultSignal.
	ErrorSignals at: 52 put: self existingReferentSignal.
	ErrorSignals at: 53 put: self nonexistentSignal.
	ErrorSignals at: 54 put: self needRetrySignal.
	ErrorSignals at: 55 put: self nonexistentSignal.
	ErrorSignals at: 56 put: self rangeErrorSignal.
	ErrorSignals at: 57 put: self transferFaultSignal.
	ErrorSignals at: 58 put: self transferFaultSignal.
	ErrorSignals at: 59 put: self transferFaultSignal.
	ErrorSignals at: 60 put: self peerFaultSignal.
	ErrorSignals at: 61 put: self noResourcesSignal.
	ErrorSignals at: 62 put: self errorSignal. "??"
	ErrorSignals at: 63 put: self noResourcesSignal.
	ErrorSignals at: 64 put: self nonexistentSignal.
	ErrorSignals at: 65 put: self noPermissionsSignal.
	ErrorSignals at: 66 put: self wrongSubtypeForOperationSignal.
	ErrorSignals at: 67 put: self nonexistentSignal.
	ErrorSignals at: 68 put: self rangeErrorSignal.
	ErrorSignals at: 69 put: self noResourcesSignal.
	ErrorSignals at: 70 put: self notReadySignal.
	DosIOAccessor wouldBlockErrorCode: 70. "Temporarily paused"
	ErrorSignals at: 71 put: self transferFaultSignal.
	ErrorSignals at: 72 put: self notReadySignal.
	ErrorSignals at: 80 put: self existingReferentSignal.
	ErrorSignals at: 82 put: self errorSignal. "??"
	ErrorSignals at: 83 put: self errorSignal. "??"
	ErrorSignals at: 84 put: self noResourcesSignal.
	ErrorSignals at: 85 put: self existingReferentSignal.
	ErrorSignals at: 86 put: self noPermissionsSignal.
	ErrorSignals at: 87 put: self invalidArgumentsSignal.
	ErrorSignals at: 88 put: self transferFaultSignal! !

DosErrorHolder initialize!
