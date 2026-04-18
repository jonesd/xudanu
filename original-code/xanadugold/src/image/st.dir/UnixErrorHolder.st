'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:50 pm'!

OSErrorHolder subclass: #UnixErrorHolder
	instanceVariableNames: ''
	classVariableNames: 'ErrorNames ErrorSignals '
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixErrorHolder comment:
'Unix error codes are interpreted here.  If we were willing to use multiple-inheritance, this class would be a mix-in for UnixIOAccessor, UnixProcess and UnixFilename.  As it is, those classes forward to UnixErrorHolder (as an `error reporter'') to interpret errors coming back from system service primitives.

Class Variables:
	ErrorNames		<IdentityDictionary> of Signal names
	ErrorSignals		<IdentityDictionary> of Signals'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixErrorHolder class
	instanceVariableNames: ''!


!UnixErrorHolder class methodsFor: 'class initialization'!

hookupTo: platname
	"Set-up to deal with a particular platform (w.r.t. error codes)."

	"Probably should use an ordered collection of patterns (from most to least specific)
	with corresponding selectors to perform.  This will have to do for now."
	"The main difference between the two unixes we have to deal with (at the moment)
	is the mapping from error-codes to error-names."
	('* sun *' match: platname)
		ifTrue: [self initSunErrorNames]
		ifFalse: [('* ardent *' match: platname)
				ifTrue: [self initArdentErrorNames]
				ifFalse: [('* digital *' match: platname)
					ifTrue: [self initDecErrorNames]
					ifFalse: [self initErrorNames]]]!

initialize
	"UnixErrorHolder initialize."

	self initErrorSignals! !

!UnixErrorHolder class methodsFor: 'error reporting'!

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
	^(ErrorSignals at: (ErrorNames at: anErrorHolder errorCode ifAbsent: [#unknown])
		ifAbsent: [self errorSignal])
		raiseWith: anErrorHolder!

reportProceedingOn: anErrorHolder 
	"As an error reporter, report the (proceedable) error contained by this holder."
	"This means, map the error holder's error code to the error name, 
	map the error name to an error signal, and raise the signal."

	^(ErrorSignals at: (ErrorNames at: anErrorHolder errorCode ifAbsent: [#unknown])
		ifAbsent: [self errorSignal])
		raiseRequestWith: anErrorHolder! !

!UnixErrorHolder class methodsFor: 'private: private-initialization'!

initArdentErrorNames

	ErrorNames _ IdentityDictionary new: 100.
	self initPrivateErrorNames.
	self initCommonErrorNames.

	ErrorNames at: 35 put: #ENOMSG.
	ErrorNames at: 36 put: #EIDRM.
	ErrorNames at: 37 put: #ECHRNG.
	ErrorNames at: 38 put: #EL2NSYNC.
	ErrorNames at: 39 put: #EL3HLT.
	ErrorNames at: 40 put: #EL3RST.
	ErrorNames at: 41 put: #ELNRNG.
	ErrorNames at: 42 put: #EUNATCH.
	ErrorNames at: 43 put: #ENOCSI.
	ErrorNames at: 44 put: #EL2HLT.
	ErrorNames at: 45 put: #EWOULDBLOCK.
	UnixIOAccessor wouldBlockErrorCode: 11.
	ErrorNames at: 46 put: #ENOLCK.
	ErrorNames at: 50 put: #EBADE.
	ErrorNames at: 51 put: #EBADR.
	ErrorNames at: 52 put: #EXFULL.
	ErrorNames at: 53 put: #ENOANO.
	ErrorNames at: 54 put: #EBADRQC.
	ErrorNames at: 55 put: #EBADSLT.
	ErrorNames at: 56 put: #EDEADLOCK.
	ErrorNames at: 57 put: #EBFONT.
	ErrorNames at: 60 put: #ENOSTR.
	ErrorNames at: 61 put: #ENODATA.
	ErrorNames at: 62 put: #ETIME.
	ErrorNames at: 63 put: #ENOSR.
	ErrorNames at: 64 put: #ENONET.
	ErrorNames at: 65 put: #ENOPKG.
	ErrorNames at: 66 put: #EREMOTE.
	ErrorNames at: 67 put: #ENOLINK.
	ErrorNames at: 68 put: #EADV.
	ErrorNames at: 69 put: #ESRMNT.
	ErrorNames at: 70 put: #ECOMM.
	ErrorNames at: 71 put: #EPROTO.
	ErrorNames at: 74 put: #EMULTIHOP.
	ErrorNames at: 75 put: #ELBIN.
	ErrorNames at: 76 put: #EDOTDOT.
	ErrorNames at: 77 put: #EBADMSG.
	ErrorNames at: 80 put: #ENOTUNIQ.
	ErrorNames at: 81 put: #EBADFD.
	ErrorNames at:  82 put: #EREMCHG.
	ErrorNames at: 83 put: #ELIBACC.
	ErrorNames at: 84 put: #ELIBBAD.
	ErrorNames at: 85 put: #ELIBSCN.
	ErrorNames at: 86 put: #ELIBMAX.
	ErrorNames at: 87 put: #ELIBEXEC.
	ErrorNames at: 90 put: #EINPROGRESS.
	UnixIOAccessor inProgressErrorCode: 90.
	ErrorNames at: 91 put: #EALREADY.
	ErrorNames at: 92 put: #ENOTSOCK.
	ErrorNames at: 93 put: #EDESTADDRREQ.
	ErrorNames at: 94 put: #EMSGSIZE.
	ErrorNames at: 95 put: #EPROTOTYPE.
	ErrorNames at: 96 put: #ENOPROTOOPT.
	ErrorNames at: 97 put: #EPROTONOSUPPORT.
	ErrorNames at: 98 put: #ESOCKTNOSUPPORT.
	ErrorNames at: 99 put: #EOPNOTSUPP.
	ErrorNames at: 100 put: #EPFNOSUPPORT.
	ErrorNames at: 101 put: #EAFNOSUPPORT.
	ErrorNames at: 102 put: #EADDRINUSE.
	ErrorNames at: 103 put: #EADDRNOTAVAIL.
	ErrorNames at: 104 put: #ENETDOWN.
	ErrorNames at: 105 put: #ENETUNREACH.
	ErrorNames at: 106 put: #ENETRESET.
	ErrorNames at: 107 put: #ECONNABORTED.
	ErrorNames at: 108 put: #ECONNRESET.
	ErrorNames at: 109 put: #ENOBUFS.
	ErrorNames at: 110 put: #EISCONN.
	ErrorNames at: 111 put: #ENOTCONN.
	ErrorNames at: 112 put: #ESHUTDOWN.
	ErrorNames at: 113 put: #ETOOMANYREFS.
	ErrorNames at: 114 put: #ETIMEDOUT.
	ErrorNames at: 115 put: #ECONNREFUSED.
	ErrorNames at: 	116 put: #ELOOP.
	ErrorNames at: 117 put: #ENAMETOOLONG.
	ErrorNames at: 118 put: #EHOSTDOWN.
	ErrorNames at: 119 put: #EHOSTUNREACH.
	ErrorNames at: 120 put: #ENOTEMPTY.
	ErrorNames at: 121 put: #EPROCLIM.
	ErrorNames at: 122 put: #EUSERS.
	ErrorNames at: 123 put: #EDQUOT!

initBsdErrorNames

	ErrorNames at: 35 put: #EWOULDBLOCK.
	UnixIOAccessor wouldBlockErrorCode: 35.
	ErrorNames at: 36 put: #EINPROGRESS.
	UnixIOAccessor inProgressErrorCode: 36.
	ErrorNames at: 37 put: #EALREADY.
	ErrorNames at: 38 put: #ENOTSOCK.
	ErrorNames at: 39 put: #EDESTADDRREQ.
	ErrorNames at: 40 put: #EMSGSIZE.
	ErrorNames at: 41 put: #EPROTOTYPE.
	ErrorNames at: 42 put: #ENOPROTOOPT.
	ErrorNames at: 43 put: #EPROTONOSUPPORT.
	ErrorNames at: 44 put: #ESOCKTNOSUPPORT.
	ErrorNames at: 45 put: #EOPNOTSUPP.
	ErrorNames at: 46 put: #EPFNOSUPPORT.
	ErrorNames at: 47 put: #EAFNOSUPPORT.
	ErrorNames at: 48 put: #EADDRINUSE.
	ErrorNames at: 49 put: #EADDRNOTAVAIL.
	ErrorNames at: 50 put: #ENETDOWN.
	ErrorNames at: 51 put: #ENETUNREACH.
	ErrorNames at: 52 put: #ENETRESET.
	ErrorNames at: 53 put: #ECONNABORTED.
	ErrorNames at: 54 put: #ECONNRESET.
	ErrorNames at: 55 put: #ENOBUFS.
	ErrorNames at: 56 put: #EISCONN.
	ErrorNames at: 57 put: #ENOTCONN.
	ErrorNames at: 58 put: #ESHUTDOWN.
	ErrorNames at: 59 put: #ETOOMANYREFS.
	ErrorNames at: 60 put: #ETIMEDOUT.
	ErrorNames at: 61 put: #ECONNREFUSED.
	ErrorNames at: 62 put: #ELOOP.
	ErrorNames at: 63 put: #ENAMETOOLONG.
	ErrorNames at: 64 put: #EHOSTDOWN.
	ErrorNames at: 65 put: #EHOSTUNREACH.
	ErrorNames at: 66 put: #ENOTEMPTY.
	ErrorNames at: 67 put: #EPROCLIM.
	ErrorNames at: 68 put: #EUSERS.
	ErrorNames at: 69 put: #EDQUOT.
	ErrorNames at: 70 put: #ESTALE.
	ErrorNames at: 71 put: #EREMOTE!

initCommonErrorNames
	"Initialize the error-code to error-name map which is common."

	ErrorNames at: 1 put: #EPERM.
	ErrorNames at: 2 put: #ENOENT.
	ErrorNames at: 3 put: #ESRCH.
	ErrorNames at: 4 put: #EINTR.
	ErrorNames at: 5 put: #EIO.
	ErrorNames at: 6 put: #ENXIO.
	ErrorNames at: 7 put: #E2BIG.
	ErrorNames at: 8 put: #ENOEXEC.
	ErrorNames at: 9 put: #EBADF.
	ErrorNames at: 10 put: #ECHILD.
	ErrorNames at: 11 put: #EAGAIN.
	ErrorNames at: 12 put: #ENOMEM.
	ErrorNames at: 13 put: #EACCES.
	ErrorNames at: 14 put: #EFAULT.
	ErrorNames at: 15 put: #ENOTBLK.
	ErrorNames at: 16 put: #EBUSY.
	ErrorNames at: 17 put: #EEXIST.
	ErrorNames at: 18 put: #EXDEV.
	ErrorNames at: 19 put: #ENODEV.
	ErrorNames at: 20 put: #ENOTDIR.
	ErrorNames at: 21 put: #EISDIR.
	ErrorNames at: 22 put: #EINVAL.
	ErrorNames at: 23 put: #ENFILE.
	ErrorNames at: 24 put: #EMFILE.
	ErrorNames at: 25 put: #ENOTTY.
	ErrorNames at: 26 put: #ETXTBSY.
	ErrorNames at: 27 put: #EFBIG.
	ErrorNames at: 28 put: #ENOSPC.
	ErrorNames at: 29 put: #ESPIPE.
	ErrorNames at: 30 put: #EROFS.
	ErrorNames at: 31 put: #EMLINK.
	ErrorNames at: 32 put: #EPIPE.
	ErrorNames at: 33 put: #EDOM.
	ErrorNames at: 34 put: #ERANGE!

initDecErrorNames

	ErrorNames _ IdentityDictionary new: 100.
	self initPrivateErrorNames.
	self initCommonErrorNames.
	self initBsdErrorNames.
	ErrorNames at: 73 put: #EIDRM.
	ErrorNames at: 74 put: #EALIGN.
	ErrorNames at: 75 put: #ENOLCK!

initErrorNames

	"BUG!!"
	self initSunErrorNames!

initErrorSignals
	"UnixErrorHolder initErrorSignals"

	ErrorSignals _ IdentityDictionary new: 100.
	ErrorSignals at: #unknown put: self errorSignal.
	ErrorSignals at: #EINPROGRESS put: self operationStartedSignal.
	ErrorSignals at: #ENOTBLK put: self inappropriateOperationSignal.
	ErrorSignals at: #ENOTDIR put: self inappropriateOperationSignal.
	ErrorSignals at: #EISDIR put: self inappropriateOperationSignal.
	ErrorSignals at: #ENOTTY put: self inappropriateOperationSignal.
	ErrorSignals at: #ENOSTR put: self inappropriateOperationSignal.
	ErrorSignals at: #ESPIPE put: self inappropriateOperationSignal.
	ErrorSignals at: #ENOTSOCK put: self inappropriateOperationSignal.
	ErrorSignals at: #EOPNOTSUPP put: self inappropriateOperationSignal.
	ErrorSignals at: #inappropriate put: self inappropriateOperationSignal.
	ErrorSignals at: #EPROTOTYPE put: self wrongSubtypeForOperationSignal.
	ErrorSignals at: #ENOPROTOOPT put: self wrongSubtypeForOperationSignal.
	ErrorSignals at: #EPROTONOSUPPORT put: self unsupportedOperationSignal.
	ErrorSignals at: #ESOCKNOSUPPORT put: self unsupportedOperationSignal.
	ErrorSignals at: #EPFNOSUPPORT put: self unsupportedOperationSignal.
	ErrorSignals at: #EAFNOSUPPORT put: self unsupportedOperationSignal.
	ErrorSignals at: #nosupport put: self unsupportedOperationSignal.
	ErrorSignals at: #EISCONN put: self unpreparedOperationSignal.
	ErrorSignals at: #ENOTCONN put: self unpreparedOperationSignal.
	ErrorSignals at: #ESHUTDOWN put: self unpreparedOperationSignal.
	ErrorSignals at: #EWOULDBLOCK put: self notReadySignal.
	ErrorSignals at: #EALREADY put: self notReadySignal.
	ErrorSignals at: #EINTR put: self transientErrorSignal.
	ErrorSignals at: #allocfail put: self allocRetrySignal.
	ErrorSignals at: #EIO put: self transferFaultSignal.
	ErrorSignals at: #ENXIO put: self transferFaultSignal.
	ErrorSignals at: #ECOMM put: self transferFaultSignal.
	ErrorSignals at: #eof put: self noDataSignal.
	ErrorSignals at: #ENOMSG put: self noDataSignal.
	ErrorSignals at: #EPIPE put: self peerFaultSignal.
	ErrorSignals at: #ENETDOWN put: self peerFaultSignal.
	ErrorSignals at: #ENETUNREACH put: self peerFaultSignal.
	ErrorSignals at: #ENETRESET put: self peerFaultSignal.
	ErrorSignals at: #ECONNABORTED put: self peerFaultSignal.
	ErrorSignals at: #ECONNRESET put: self peerFaultSignal.
	ErrorSignals at: #ETIMEOUT put: self peerFaultSignal.
	ErrorSignals at: #ETIME put: self peerFaultSignal.
	ErrorSignals at: #ECONNREFUSED put: self peerFaultSignal.
	ErrorSignals at: #EHOSTDOWN put: self peerFaultSignal.
	ErrorSignals at: #EHOSTUNREACH put: self peerFaultSignal.
	ErrorSignals at: #EIDRM put: self peerFaultSignal.
	ErrorSignals at: #ENOSPC put: self volumeFullSignal.
	ErrorSignals at: #EDQUOT put: self volumeFullSignal.
	ErrorSignals at: #E2BIG put: self invalidArgumentsSignal.
	ErrorSignals at: #EFAULT put: self invalidArgumentsSignal.
	ErrorSignals at: #EADDRINUSE put: self invalidArgumentsSignal.
	ErrorSignals at: #badargs put: self badArgumentsSignal.
	ErrorSignals at: #EBADF put: self badAccessorSignal.
	ErrorSignals at: #EINVAL put: self invalidArgumentsSignal.
	ErrorSignals at: #EMSGSIZE put: self rangeErrorSignal.
	ErrorSignals at: #EMLINK put: self rangeErrorSignal.
	ErrorSignals at: #ELOOP put: self rangeErrorSignal.
	ErrorSignals at: #ENAMETOOLONG put: self rangeErrorSignal.
	ErrorSignals at: #EREMOTE put: self rangeErrorSignal.
	ErrorSignals at: #EDESTADDRREQ put: self underspecifiedSignal.
	ErrorSignals at: #ENODEV put: self inaccessableSignal.
	ErrorSignals at: #ENOENT put: self nonexistentSignal.
	ErrorSignals at: #EBUSY put: self unavailableReferentSignal.
	ErrorSignals at: #ESTALE put: self unavailableReferentSignal.
	ErrorSignals at: #ENONET put: self unavailableReferentSignal.
	ErrorSignals at: #EACCES put: self noPermissionsSignal.
	ErrorSignals at: #EPERM put: self noPermissionsSignal.
	ErrorSignals at: #EROFS put: self noPermissionsSignal.
	ErrorSignals at: #EADDRNOTAVAIL put: self noPermissionsSignal.
	ErrorSignals at: #EEXIST put: self existingReferentSignal.
	ErrorSignals at: #EADDRINUSE put: self existingReferentSignal.
	ErrorSignals at: #EXDEV put: self inappropriateReferentSignal.
	ErrorSignals at: #ENOTEMPTY put: self inappropriateReferentSignal.
	ErrorSignals at: #ENFILE put: self noResourcesSignal.
	ErrorSignals at: #EMFILE put: self noResourcesSignal.
	ErrorSignals at: #EFBIG put: self noResourcesSignal.
	ErrorSignals at: #ENOMEM put: self noMemorySignal.
	ErrorSignals at: #ENOBUFS put: self noMemorySignal.
	ErrorSignals at: #ENOLCK put: self noResourcesSignal.
	ErrorSignals at: #ENOSR put: self noResourcesSignal.
	ErrorSignals at: #ENODATA put: self notReadySignal.
	ErrorSignals at: #ELBIN put: self informationSignal.
	ErrorSignals at: #EDOTDOT put: self informationSignal.
	ErrorSignals at: #EBADFD put: self inappropriateOperationSignal!

initPrivateErrorNames
	"Set up map from error-codes to error-names for internally
	generated errors."

	ErrorNames at: -6 put: #inappropriate.
	ErrorNames at: -5 put: #badargs.
	ErrorNames at: -4 put: #unknown.
	ErrorNames at: -1 put: #nosupport.
	ErrorNames at: -2 put: #allocfail.
	ErrorNames at: -3 put: #eof!

initSunErrorNames

	ErrorNames _ IdentityDictionary new: 100.
	self initPrivateErrorNames.
	self initCommonErrorNames.
	self initBsdErrorNames.
	ErrorNames at: 72 put: #ENOSTR.
	ErrorNames at: 73 put: #ETIME.
	ErrorNames at: 74 put: #ENOSR.
	ErrorNames at: 75 put: #ENOMSG.
	ErrorNames at: 76 put: #EBADMSG.
	ErrorNames at: 77 put: #EIDRM.
	ErrorNames at: 78 put: #EDEADLK.
	ErrorNames at: 79 put: #ENOLCK.
	ErrorNames at: 80 put: #ENONET.
	ErrorNames at: 81 put: #ERREMOTE.
	ErrorNames at: 82 put: #ENOLINK.
	ErrorNames at: 83 put: #EADV.
	ErrorNames at: 84 put: #ESRMNT.
	ErrorNames at: 85 put: #ECOMM.
	ErrorNames at: 86 put: #EPROTO.
	ErrorNames at: 87 put: #EMULTIHOP.
	ErrorNames at: 88 put: #EDOTDOT.
	ErrorNames at: 89 put: #EREMCHG! !

UnixErrorHolder initialize!
