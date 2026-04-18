'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:09 pm'!

Heaper subclass: #EncrypterMaker
	instanceVariableNames: 'myConstructor {EncrypterConstructor var}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-lock'!
EncrypterMaker comment:
'Contains a pointer to a function used to create an instance of a particular kind of Encrypter. 

Each concrete Encrypter subclass should create a corresponding EncrypterMaker object and register it in a table, with the name of the encryption algorithm. This should be done using the DECLARE_ENCRYPTER and DEFINE_ENCRYPTER macros.'!

(EncrypterMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!EncrypterMaker methodsFor: 'create'!

create: constructor {EncrypterConstructor var}

	super create.
	myConstructor := constructor.! !

!EncrypterMaker methodsFor: 'accessing'!

{Encrypter} makeEncrypter: publicKey {UInt8Array | NULL} with: privateKey {UInt8Array | NULL}
	"Make an instance of this kind of encrypter, with the given public and private keys."
	
	^myConstructor invokeFunction: publicKey with: privateKey! !

!EncrypterMaker methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !