'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:09 pm'!

Heaper subclass: #Encrypter
	instanceVariableNames: '
		myPublicKey {UInt8Array | NULL}
		myPrivateKey {UInt8Array | NULL}'
	classVariableNames: 'AllEncrypterMakers {MuTable of: Sequence and: EncrypterMaker} '
	poolDictionaries: ''
	category: 'Xanadu-lock'!
Encrypter comment:
'An Encrypter is an instantiation of some public-key encryption algorithm, along with optional public and private keys. Each subclass implements a particular algorithm, such as Rivest-Shamir-Adelman, in response to the encryption, decryption, and key generation protocol. 

** obsolete documentation **

The algorithm is identified by a Sequence naming it. Each concrete subclass must register itself during initialization time. This is handled by two macros, DECLARE_ENCRYPTER and DEFINE_ENCRYPTER. DECLARE_ENCRYPTER(AClassName) defines a function that can be used to create an instance. DEFINE_ENCRYPTER("identifier",AClassName) creates an EncrypterMaker parametrized with that "constructor" function pointer, and stores it in the system-wide table of EncrypterMakers. DECLARE_ENCRYPTER should be invoked in function scope (i.e. inside a linkTimeNonInherited class method) and DEFINE_ENCRYPTER should be invoked inside an Initializer (i.e. inside an initTimeNonInherited class method).

The pseudo-constructor to make an Encrypter takes the PackOBits identifying the algorithm, and looks for a corresponding EncrypterMaker in the table. It then asks that EncrypterMaker to create an instance, with the given public and private keys.

Encrypters are mutable objects. This allows you to create an Encrypter, generate new random keys for it, make a copy, remove its private key, and pass that out for public use.'!

(Encrypter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Encrypter methodsFor: 'create'!

create: publicKey {UInt8Array | NULL} with: privateKey {UInt8Array | NULL}

	super create.
	myPublicKey := publicKey.
	myPrivateKey := privateKey.! !

!Encrypter methodsFor: 'encrypting/decrypting'!

{UInt8Array} decrypt: encrypted {UInt8Array}
	"Decrypt data with the current private key."
	
	self subclassResponsibility!

{UInt8Array} encrypt: clear {UInt8Array}
	"Encrypt the given data with the current public key."
	
	self subclassResponsibility! !

!Encrypter methodsFor: 'keys'!

{UInt8Array} privateKey

	myPrivateKey == NULL
		ifTrue: [Heaper BLAST: #NoPrivateKey].
	^myPrivateKey!

{UInt8Array} publicKey

	myPublicKey == NULL
		ifTrue: [Heaper BLAST: #NoPublicKey].
	^myPublicKey!

{void} randomizeKeys: seed {UInt8Array}
	"Generate a new pair of public and private keys using the given data as a random seed."
	
	self subclassResponsibility!

{void} setPrivateKey: newKey {UInt8Array | NULL}
	"Change the private key."
	
	myPrivateKey := newKey.!

{void} setPublicKey: newKey {UInt8Array | NULL}
	"Change the public key."
	
	myPublicKey := newKey.! !

!Encrypter methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Encrypter class
	instanceVariableNames: ''!

(Encrypter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Encrypter class methodsFor: 'pseudo constructors'!

make: identifier {Sequence}
	with: publicKey {UInt8Array default: NULL}
	with: privateKey {UInt8Array default: NULL}
	"Make an encrypter of the given type with the given public and private keys. Gets the requested EncrypterMaker out of the table and then asks it to make an encrypter with the given key. Fails with
		BLAST(NoSuchEncrypter) if it is not found."

	ScruTable problems.NotInTable
		handle: [ :boom | Heaper BLAST: #NoSuchEncrypter]
		do: [^((AllEncrypterMakers get: identifier) cast: EncrypterMaker)
			makeEncrypter: publicKey with: privateKey]! !

!Encrypter class methodsFor: 'smalltalk: macros'!

DECLARE.U.ENCRYPTER: className {Symbol}

	"Only applies in C++"!

DEFINE.U.ENCRYPTER: identifier {String} with: className {Symbol}

	self REQUIRES: Encrypter.
	self remember: (Sequence string: identifier)
		with: (Smalltalk at: className)!

{Encrypter} invokeFunction: publicKey {Sequence| NULL} with: privateKey {Sequence | NULL}
	"In Smalltalk, the Encrypter class is used in place of the function pointer."
	
	^self create: publicKey with: privateKey! !

!Encrypter class methodsFor: 'was protected'!

{void} remember: identifier {Sequence}
	with: constructor {EncrypterConstructor var}

	| maker {EncrypterMaker} |
	maker := EncrypterMaker create: constructor.
	AllEncrypterMakers at: identifier introduce: maker.! !

!Encrypter class methodsFor: 'smalltalk: defaults'!

make: identifier {Sequence}

	^self make: identifier with: NULL with: NULL!

make: identifier {Sequence} with: publicKey {Sequence}

	^self make: identifier with: publicKey with: NULL! !

!Encrypter class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self REQUIRES: SequenceSpace.
	self REQUIRES: MuTable.
	AllEncrypterMakers := MuTable make: SequenceSpace make.!

linkTimeNonInherited

	AllEncrypterMakers := NULL.! !