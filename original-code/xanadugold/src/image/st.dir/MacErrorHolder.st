'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:00 pm'!

OSErrorHolder subclass: #MacErrorHolder
	instanceVariableNames: ''
	classVariableNames: 'ErrorSignals '
	poolDictionaries: ''
	category: 'OS-Mac'!
MacErrorHolder comment:
'Macintosh error codes are interpreted by class MacErrorHolder.

Class Variables:  
	ErrorSignals		<IdentityDictionary> of Signals
'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacErrorHolder class
	instanceVariableNames: ''!


!MacErrorHolder class methodsFor: 'class initialization'!

hookupTo: platname
	"Set-up to deal with a particular platform (w.r.t. error codes)."!

initialize
	"MacErrorHolder initialize."

	self initErrorSignals! !

!MacErrorHolder class methodsFor: 'error reporting'!

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

!MacErrorHolder class methodsFor: 'private: private'!

initErrorSignals
	"Error codes taken from 'Inside Mac Vol 1-5'."
	"MacErrorHolder initErrorSignals"

	ErrorSignals _ IdentityDictionary new: 50.
	ErrorSignals at: 12 "ENOMEM" put: self noMemorySignal.
	ErrorSignals at: 17 "EEXIST" put: self existingReferentSignal.
	ErrorSignals at: 20 "ENOTDIR" put: self inappropriateOperationSignal.
	ErrorSignals at: 22 "EINVAL" put: self invalidArgumentsSignal.
	ErrorSignals at: 27 "EFBIG" put: self noResourcesSignal.
	ErrorSignals at: 70 "EWOULDBLOCK" put: self notReadySignal.

	ErrorSignals at: -33 put: self volumeFullSignal.
	ErrorSignals at: -34 put: self volumeFullSignal.
	ErrorSignals at: -35 put: self nonexistentSignal.
	ErrorSignals at: -36 put: self transferFaultSignal.
	ErrorSignals at: -37 put: self invalidArgumentsSignal.
	ErrorSignals at: -38 put: self badAccessorSignal.
	ErrorSignals at: -39 put: self noDataSignal.
	ErrorSignals at: -40 put: self rangeErrorSignal.
	ErrorSignals at: -42 put: self noResourcesSignal.
	ErrorSignals at: -43 put: self nonexistentSignal.
	ErrorSignals at: -44 put: self noPermissionsSignal.
	ErrorSignals at: -45 put: self noPermissionsSignal.
	ErrorSignals at: -46 put: self noPermissionsSignal.
	ErrorSignals at: -47 put: self unavailableReferentSignal.
	ErrorSignals at: -48 put: self existingReferentSignal.
	ErrorSignals at: -49 put: self unavailableReferentSignal.
	ErrorSignals at: -50 put: self nonexistentSignal.
	ErrorSignals at: -51 put: self nonexistentSignal.
	ErrorSignals at: -52 put: self errorSignal.
	ErrorSignals at: -53 put: self unpreparedOperationSignal.
	ErrorSignals at: -54 put: self noPermissionsSignal.
	ErrorSignals at: -55 put: self existingReferentSignal.
	ErrorSignals at: -56 put: self inaccessableSignal.
	ErrorSignals at: -57 put: self transferFaultSignal.
	ErrorSignals at: -58 put: self badAccessorSignal.
	ErrorSignals at: -59 put: self invalidArgumentsSignal.
	ErrorSignals at: -60 put: self transferFaultSignal.
	ErrorSignals at: -61 put: self noPermissionsSignal.
	ErrorSignals at: -97 put: self unavailableReferentSignal.
	ErrorSignals at: -98 put: self unpreparedOperationSignal.
	ErrorSignals at: -108 put: self noMemorySignal.
	ErrorSignals at: -120 put: self nonexistentSignal.
	ErrorSignals at: -121 put: self noResourcesSignal.
	ErrorSignals at: -122 put: self inappropriateReferentSignal.
	ErrorSignals at: -123 put: self inappropriateOperationSignal.
	ErrorSignals at: -127 put: self transferFaultSignal.
	ErrorSignals at: -193 put: self unpreparedOperationSignal.
	ErrorSignals at: -3101 put: self noMemorySignal.
	ErrorSignals at: -4101 put: self unpreparedOperationSignal.
	MacIOAccessor wouldBlockErrorCode: 70. "Temporarily paused"! !

MacErrorHolder initialize!
