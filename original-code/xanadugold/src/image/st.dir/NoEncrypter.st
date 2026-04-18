'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:09 pm'!

Encrypter subclass: #NoEncrypter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-lock'!
NoEncrypter comment:
'Does no encryption at all.'!

(NoEncrypter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!NoEncrypter methodsFor: 'create'!

create: publicKey {UInt8Array | NULL} with: privateKey {UInt8Array | NULL}

	super create: publicKey with: privateKey.! !

!NoEncrypter methodsFor: 'encrypting/decrypting'!

{UInt8Array} decrypt: encrypted {UInt8Array}

	^encrypted!

{UInt8Array} encrypt: clear {UInt8Array}

	^clear copy cast: UInt8Array! !

!NoEncrypter methodsFor: 'keys'!

{void} randomizeKeys: seed {UInt8Array unused}

	self setPublicKey: (UInt8Array string: 'public').
	self setPrivateKey: (UInt8Array string: 'private').! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NoEncrypter class
	instanceVariableNames: ''!

(NoEncrypter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!NoEncrypter class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self DEFINE.U.ENCRYPTER: 'NoEncrypter' with: #NoEncrypter!

linkTimeNonInherited

	self DECLARE.U.ENCRYPTER: #NoEncrypter! !

!NoEncrypter class methodsFor: 'create'!

{Encrypter} make: publicKey {UInt8Array | NULL} with: privateKey {UInt8Array | NULL}

	^ self create: publicKey with: privateKey.! !