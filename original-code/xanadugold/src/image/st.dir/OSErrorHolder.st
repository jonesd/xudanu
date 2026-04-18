'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:42 pm'!

Object subclass: #OSErrorHolder
	instanceVariableNames: 'errorCode '
	classVariableNames: 'MySignals OsErrorSignal '
	poolDictionaries: ''
	category: 'OS-Support'!
OSErrorHolder comment:
'Class OSErrorHolder is a place to hold error codes (which are usually integers).  Instances of its subclasses are usually used to encapsulate error-codes returned from primitives which take those instances as receivers.  Direct instances of OSErrorHolder are used in creation messages defined in the subclasses.

Instance Variables:
	errorCode	<nil | SmallInteger> nil means no error.  Interpretation of other values is by prior agreement between caller and callee.

Class Variables:
	MySignals		<IdentityDictionary> of Signals
	OsErrorSignal	<Signal> Operating System Error
'!


!OSErrorHolder methodsFor: 'accessing'!

errorCode
	"Answer the receiver's error code."

	^errorCode!

errorString
	"Answer a string that is used to describe the receiver's error code."

	^self errorReporter errorDescriptionFor: self errorCode! !

!OSErrorHolder methodsFor: 'testing'!

failed
	"Answer true if the receiver's last primitive operation had an error."

	^errorCode notNil!

successful
	"Answer true if the receiver's last primitive operation had no errors."

	^errorCode == nil! !

!OSErrorHolder methodsFor: 'error reporting'!

errorReporter
	"Answer the class which can interpret the receiver's error codes."

	^self class errorReporter!

reportError
	"Report an error."
	"Delegate to the receiver's error reporter."

	^self errorReporter reportOn: self!

reportErrorProceeding
	"Report an error, but permit control to proceed later."
	"Delegate to the receiver's error reporter."

	^self errorReporter reportProceedingOn: self!

reportFor: otherRcvr
	"Report an error caused by the other fellow."
	"Delegate to the other receiver's error reporter."

	otherRcvr errorReporter reportOn: self! !

!OSErrorHolder methodsFor: 'printing'!

printErrorDescriptionOn: aStream
	"Print a description of the last error on aStream."

	aStream nextPutAll: 'Error: "'.
	aStream nextPutAll: (self errorReporter errorDescriptionFor: self errorCode).
	aStream nextPut: $"!

printOn: aStream 
	"Print a description of the receiver on aStream."

	super printOn: aStream.
	errorCode == nil
		ifFalse: 
			[aStream nextPut: $(.
			self printErrorDescriptionOn: aStream.
			aStream nextPut: $)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OSErrorHolder class
	instanceVariableNames: ''!


!OSErrorHolder class methodsFor: 'class initialization'!

initialize
	"Set up the OS error signals."
	"OSErrorHolder initialize"

	OsErrorSignal _ (Object errorSignal newSignal)
			notifierString: 'Operating System Error';
			nameClass: self message: #errorSignal.
	self initSignals!

initSignals
	"Initialize all the OS-related signals."

	| es ps |
	es _ self errorSignal.
	MySignals _ IdentityDictionary new: 30.

	MySignals at: #InformationSignal put: (ps _ (es newSignal notifierString: 'Information only';
		nameClass: self message: #informationSignal)).
	MySignals at: #OperationStartedSignal put: (ps newSignal
	notifierString: ' operation initiated';
		nameClass: self message: #operationStartedSignal).

	MySignals at: #IllegalOperationSignal put: (ps _ (es newSignal
		notifierString: 'Illegal operation';
		nameClass: self message: #illegalOperationSignal)).
	MySignals at: #InappropriateOperationSignal put: (ps newSignal
		notifierString: 'Inappropriate operation for this accessor';
		nameClass: self message: #inappropriateOperationSignal).
	MySignals at: #WrongSubtypeForOperationSignal put: (ps newSignal
		notifierString: ' wrong subtype';
		nameClass: self message: #wrongSubtypeForOperationSignal).
	MySignals at: #UnsupportedOperationSignal put: (ps newSignal
		notifierString: ' on this platform';
		nameClass: self message: #unsupportedOperationSignal).
	MySignals at: #UnpreparedOperationSignal put: (ps newSignal
		notifierString: ' sequencing error';
		nameClass: self message: #unpreparedOperationSignal).

	MySignals at: #NeedRetrySignal put: (ps _ (es newSignal
		notifierString: 'Operation should be retried';
		nameClass: self message: #needRetrySignal)).
	MySignals at: #NotReadySignal put: (ps newSignal
		notifierString: ' --accessor not ready yet';
		nameClass: self message: #notReadySignal).
	MySignals at: #TransientErrorSignal put: (ps _ (ps newSignal
		notifierString: ' (transient error)';
		nameClass: self message: #transientErrorSignal)).
	MySignals at: #AllocRetrySignal put: (ps newSignal
		notifierString: ' -- allocation failure';
		nameClass: self message: #allocRetrySignal).

	MySignals at: #TransferFaultSignal put: (ps _ (es newSignal
		notifierString:	'Transfer error';
		nameClass: self message: #transferFaultSignal)).
	MySignals at: #NoDataSignal put: (ps newSignal
		notifierString:	'Data unavailable or EOF reached';
		nameClass: self message: #noDataSignal).
	MySignals at: #PeerFaultSignal put: (ps newSignal
		notifierString:	'Peer communications error';
		nameClass: self message: #peerFaultSignal).
	MySignals at: #VolumeFullSignal put: (ps newSignal
		notifierString:	'Volume full';
		nameClass: self message: #volumeFullSignal).

	MySignals at: #InvalidArgumentsSignal put: (ps _ (es newSignal
		notifierString:	'Arguments invalid';
		nameClass: self message: #invalidArgumentsSignal)).
	MySignals at: #BadArgumentsSignal put: (ps newSignal
		notifierString:	' -- wrong class';
		nameClass: self message: #badArgumentsSignal).
	MySignals at: #BadAccessorSignal put: (ps newSignal
		notifierString:	'Accessor invalid';
		nameClass: self message: #badAccessorSignal).
	MySignals at: #RangeErrorSignal put: (ps newSignal
		notifierString:	' -- request out of range';
		nameClass: self message: #rangeErrorSignal).
	MySignals at: #UnderspecifiedSignal put: (ps newSignal
		notifierString:	' -- operation not fully specified';
		nameClass: self message: #underspecifiedSignal).

	MySignals at: #InaccessableSignal put: (ps _ (es newSignal
		notifierString:	'Referent inaccessable';
		nameClass: self message: #inaccessableSignal)).
	MySignals at: #NonexistentSignal put: (ps newSignal
		notifierString:	'File/directory does not exist';
		nameClass: self message: #nonexistentSignal).	
	MySignals at: #UnavailableReferentSignal put: (ps newSignal
		notifierString:	' at this time';
		nameClass: self message: #unavailableReferentSignal).	
	MySignals at: #NoPermissionsSignal put: (ps newSignal
		notifierString:	'Permission denied';
		nameClass: self message: #noPermissionsSignal).	
	MySignals at: #ExistingReferentSignal put: (ps newSignal
		notifierString:	' -- already exists or in use';
		nameClass: self message: #existingReferentSignal).
	MySignals at: #InappropriateReferentSignal put: (ps newSignal
		notifierString: ' -- operation cannot be performed';
		nameClass: self message: #inappropriateReferentSignal).

	MySignals at: #NoResourcesSignal put: (ps _ (es newSignal
		notifierString:	'Insufficient Resources';
		nameClass: self message: #noResourcesSignal)).
	MySignals at: #NoMemorySignal put: (ps newSignal
		notifierString:	' -- memory';
		nameClass: self message: #noMemorySignal)! !

!OSErrorHolder class methodsFor: 'error reporting'!

errorDescriptionFor: enum
	"Answer a description of this error code."
	"If you got here, there must be no appropriate error reporter."

	^'Unknown error ', enum printString!

errorSignal
	"Answer the most general OS-error signal."

	^OsErrorSignal!

reportOn: anErrorHolder
	"As an error reporter, report the error contained by this holder."
	"No specific error reporter, just raise the most general OS error signal."

	^self errorSignal raiseWith: anErrorHolder!

reportProceedingOn: anErrorHolder
	"As an error reporter, report the (proceedable) error contained by this holder."
	"No specific error reporter, just raise the most general OS error signal."

	^self errorSignal raiseRequestWith: anErrorHolder! !

!OSErrorHolder class methodsFor: 'defaults'!

errorReporter
	"Answer the object which understands my error codes."
	"Must not have found anybody else."

	^self! !

!OSErrorHolder class methodsFor: 'signal access'!

allocRetrySignal
	"Answer the signal for
		some retryable allocation failed."

	^MySignals at: #AllocRetrySignal!

badAccessorSignal
	"Answer the signal for
		bad (invalid) accessor was supplied."

	^MySignals at: #BadAccessorSignal!

badArgumentsSignal
	"Answer the signal for
		bad argument (e.g. wrong class) was supplied."

	^MySignals at: #BadArgumentsSignal!

existingReferentSignal
	"Answer the signal for
		referent (e.g. file) already exists."

	^MySignals at: #ExistingReferentSignal!

illegalOperationSignal
	"Answer the signal for
		operation is illegal."

	^MySignals at: #IllegalOperationSignal!

inaccessableSignal
	"Answer the signal for
		referent (e.g. file) is inaccessable."

	^MySignals at: #InaccessableSignal!

inappropriateOperationSignal
	"Answer the signal for
		operation is inappropriate."

	^MySignals at: #InappropriateOperationSignal!

inappropriateReferentSignal
	"Answer the signal for
		operation is inappropriate for this referent (e.g. file)."

	^MySignals at: #InappropriateReferentSignal!

informationSignal
	"Answer the signal for
		some unusual non-fatal condition."

	^MySignals at: #InformationSignal!

invalidArgumentsSignal
	"Answer the signal for
		invalid arguments (e.g. right class, wrong value)."

	^MySignals at: #InvalidArgumentsSignal!

needRetrySignal
	"Answer the signal for
		operation failed but may be retried."

	^MySignals at: #NeedRetrySignal!

noDataSignal
	"Answer the signal for
		no data available."

	^MySignals at: #NoDataSignal!

noMemorySignal
	"Answer the signal for
		insufficient memory to perform operation."

	^MySignals at: #NoMemorySignal!

nonexistentSignal
	"Answer the signal for
		referent (e.g. device) does not exist."

	^MySignals at: #NonexistentSignal!

noPermissionsSignal
	"Answer the signal for
		protection violation."

	^MySignals at: #NoPermissionsSignal!

noResourcesSignal
	"Answer the signal for
		insufficient resources to perform operation."

	^MySignals at: #NoResourcesSignal!

notReadySignal
	"Answer the signal for
		operation cannot be performed just yet."

	^MySignals at: #NotReadySignal!

operationStartedSignal
	"Answer the signal for
		operation is not yet complete (non-fatal)."

	^MySignals at: #OperationStartedSignal!

peerFaultSignal
	"Answer the signal for
		communications peer is unreachable."

	^MySignals at: #PeerFaultSignal!

rangeErrorSignal
	"Answer the signal for
		some argument's value is out of range."

	^MySignals at: #RangeErrorSignal!

transferFaultSignal
	"Answer the signal for
		data transfer error occurred."

	^MySignals at: #TransferFaultSignal!

transientErrorSignal
	"Answer the signal for
		transient error occurred (maybe you should retry)."

	^MySignals at: #TransientErrorSignal!

unavailableReferentSignal
	"Answer the signal for
		referent unavailable at this time (e.g. file busy)."

	^MySignals at: #UnavailableReferentSignal!

underspecifiedSignal
	"Answer the signal for
		ambigious request."

	^MySignals at: #UnderspecifiedSignal!

unpreparedOperationSignal
	"Answer the signal for
		operations sequencing error."

	^MySignals at: #UnpreparedOperationSignal!

unsupportedOperationSignal
	"Answer the signal for
		operation is unsupported."

	^MySignals at: #UnsupportedOperationSignal!

volumeFullSignal
	"Answer the signal for
		no space available on volume."

	^MySignals at: #VolumeFullSignal!

wrongSubtypeForOperationSignal
	"Answer the signal for
		arguments contradictory."

	^MySignals at: #WrongSubtypeForOperationSignal! !

OSErrorHolder initialize!
