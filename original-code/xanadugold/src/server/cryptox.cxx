/* Copyright Xanadu Operating Company.  All Rights Reserved. */

/******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/

#ifndef CRYPTOX_CXX
#define CRYPTOX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef CRYPTOX_HXX
#include "cryptox.hxx"
#endif /* CRYPTOX_HXX */

#ifndef CRYPTOX_IXX
#include "cryptox.ixx"
#endif /* CRYPTOX_IXX */

#ifndef CRYPTOP_HXX
#include "cryptop.hxx"
#endif /* CRYPTOP_HXX */

#ifndef CRYPTOP_IXX
#include "cryptop.ixx"
#endif /* CRYPTOP_IXX */


#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Encrypter 
 *
 * ************************************************************************ */



/* Initializers for Encrypter */

GPTR(MuTable) OF2(Sequence,EncrypterMaker) Encrypter::AllEncrypterMakers = NULL;



BEGIN_INIT_TIME(Encrypter,initTimeNonInherited) {
	REQUIRES (SequenceSpace);
	REQUIRES (MuTable);
	Encrypter::AllEncrypterMakers = MuTable::make (SequenceSpace::make ());
} END_INIT_TIME(Encrypter,initTimeNonInherited);



/* Initializers for Encrypter */






/* pseudo constructors */


RPTR(Encrypter) Encrypter::make (
		APTR(Sequence) identifier, 
		APTR(UInt8Array) publicKey/* = NULL*/, 
		APTR(UInt8Array) privateKey/* = NULL*/)
{
	/* Make an encrypter of the given type with the given public 
	and private keys. Gets the requested EncrypterMaker out of 
	the table and then asks it to make an encrypter with the 
	given key. Fails with
			BLAST(NoSuchEncrypter) if it is not found. */
	
	do {
		INSTALL_SHIELD(boom);
		SHIELD_UP_BEGIN(boom, NotInTableFilter) {
			BLAST(NoSuchEncrypter);
			break;
		} SHIELD_UP_END(boom);
		WPTR(Encrypter) 	returnValue;
		returnValue = CAST(EncrypterMaker,Encrypter::AllEncrypterMakers->get(identifier))->makeEncrypter(publicKey, privateKey);
		return returnValue;
	} while (FALSE);
}
/* was protected */


void Encrypter::remember (APTR(Sequence) identifier, EncrypterConstructor constructor){
	SPTR(EncrypterMaker) maker;
	
	CONSTRUCT(maker,EncrypterMaker,(constructor, tcsj));
	Encrypter::AllEncrypterMakers->introduce(identifier, maker);
}
/* An Encrypter is an instantiation of some public-key encryption 
algorithm, along with optional public and private keys. Each subclass 
implements a particular algorithm, such as Rivest-Shamir-Adelman, in 
response to the encryption, decryption, and key generation protocol. 

** obsolete documentation **

The algorithm is identified by a Sequence naming it. Each concrete 
subclass must register itself during initialization time. This is 
handled by two macros, DECLARE_ENCRYPTER and DEFINE_ENCRYPTER. 
DECLARE_ENCRYPTER(AClassName) defines a function that can be used to 
create an instance. DEFINE_ENCRYPTER("identifier",AClassName) creates 
an EncrypterMaker parametrized with that "constructor" function 
pointer, and stores it in the system-wide table of EncrypterMakers. 
DECLARE_ENCRYPTER should be invoked in function scope (i.e. inside a 
linkTimeNonInherited class method) and DEFINE_ENCRYPTER should be 
invoked inside an Initializer (i.e. inside an initTimeNonInherited 
class method).

The pseudo-constructor to make an Encrypter takes the PackOBits 
identifying the algorithm, and looks for a corresponding 
EncrypterMaker in the table. It then asks that EncrypterMaker to 
create an instance, with the given public and private keys.

Encrypters are mutable objects. This allows you to create an 
Encrypter, generate new random keys for it, make a copy, remove its 
private key, and pass that out for public use. */


/* create */


Encrypter::Encrypter (APTR(UInt8Array) OR(NULL) publicKey, APTR(UInt8Array) OR(NULL) privateKey) {
	myPublicKey = publicKey;
	myPrivateKey = privateKey;
}
/* encrypting/decrypting */
/* keys */


RPTR(UInt8Array) Encrypter::privateKey (){
	if (myPrivateKey == NULL) {
		BLAST(NoPrivateKey);
	}
	return (UInt8Array*) myPrivateKey;
}


RPTR(UInt8Array) Encrypter::publicKey (){
	if (myPublicKey == NULL) {
		BLAST(NoPublicKey);
	}
	return (UInt8Array*) myPublicKey;
}


void Encrypter::setPrivateKey (APTR(UInt8Array) OR(NULL) newKey){
	/* Change the private key. */
	
	myPrivateKey = newKey;
}


void Encrypter::setPublicKey (APTR(UInt8Array) OR(NULL) newKey){
	/* Change the public key. */
	
	myPublicKey = newKey;
}



/* ************************************************************************ *
 * 
 *                    Class Scrambler 
 *
 * ************************************************************************ */



/* Initializers for Scrambler */

GPTR(MuTable) OF2(Sequence,Scrambler) Scrambler::AllScramblers = NULL;



BEGIN_INIT_TIME(Scrambler,initTimeNonInherited) {
	REQUIRES (MuTable);
	REQUIRES (SequenceSpace);
	Scrambler::AllScramblers = MuTable::make (SequenceSpace::make ());
} END_INIT_TIME(Scrambler,initTimeNonInherited);



/* Initializers for Scrambler */






/* was protected */


void Scrambler::remember (APTR(Sequence) identifier, APTR(Scrambler) scrambler){
	/* Register the existence of a particular kind of scrambler. 
	The identifier must be unique. */
	
	Scrambler::AllScramblers->introduce(identifier, scrambler);
}
/* accessing */


RPTR(Scrambler) Scrambler::make (APTR(UInt8Array) identifier){
	/* Return a scrambler with the given name. Fail with
			BLAST(NoSuchScrambler) if there is none. */
	
	do {
		INSTALL_SHIELD(boom);
		SHIELD_UP_BEGIN(boom, NotInTableFilter) {
			BLAST(NoSuchScrambler);
			break;
		} SHIELD_UP_END(boom);
		return CAST(Scrambler,Scrambler::AllScramblers->get(Sequence::numbers(identifier)));
	} while (FALSE);
}
/* A Scrambler implements a one-way hash function. It should be 
one-way, in that it should be difficult to unscramble, and it should 
be a hash, in that two similar inputs should produce very different 
outputs. It is furthermore desirable but not essential that the 
algorithm be cryptographically secure (the only way to unscramble an 
output is by scrambling all possible inputs and comparing), and 
one-to-one (two different inputs never produce the same output). Each 
subclass implements some particular algorithm such as Snefru, in 
response to the scrambling protocol. 
 
The system maintains a table of all of the known Scramblers, indexed 
by name (a PackOBits). At initialization time, each concrete subclass 
should use the DEFINE_SCRAMBLER("identifier",(scramblerExpression)) 
macro to place an instance in the table at some appropriate 
identifier. DEFINE_SCRAMBLER must be invoked inside an Initializer 
(e.g. in an initTimeNonInherited method).

MatchLockSmiths store passwords in scrambled form, so that being able 
to read the LockSmith is not enough to find out the password. They 
also store the name of the Scrambler used to scramble it, so that 
trial passwords can be scrambled and compared. */


/* scrambling */
/* tesing */


UInt32 Scrambler::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
Scrambler::Scrambler() {}



/* ************************************************************************ *
 * 
 *                    Class EncrypterMaker 
 *
 * ************************************************************************ */


/* Contains a pointer to a function used to create an instance of a 
particular kind of Encrypter. 

Each concrete Encrypter subclass should create a corresponding 
EncrypterMaker object and register it in a table, with the name of 
the encryption algorithm. This should be done using the 
DECLARE_ENCRYPTER and DEFINE_ENCRYPTER macros. */


/* create */


EncrypterMaker::EncrypterMaker (EncrypterConstructor constructor, TCSJ) {
	myConstructor = constructor;
}
/* accessing */


RPTR(Encrypter) EncrypterMaker::makeEncrypter (APTR(UInt8Array) OR(NULL) publicKey, APTR(UInt8Array) OR(NULL) privateKey){
	/* Make an instance of this kind of encrypter, with the given 
	public and private keys. */
	
	WPTR(Encrypter) 	returnValue;
	returnValue = (*(myConstructor)) (publicKey, privateKey);
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class NoEncrypter 
 *
 * ************************************************************************ */



/* Initializers for NoEncrypter */

DECLARE_ENCRYPTER(NoEncrypter);



BEGIN_INIT_TIME(NoEncrypter,initTimeNonInherited) {
	DEFINE_ENCRYPTER("NoEncrypter",NoEncrypter);
} END_INIT_TIME(NoEncrypter,initTimeNonInherited);



/* Initializers for NoEncrypter */






/* create */


RPTR(Encrypter) NoEncrypter::make (APTR(UInt8Array) OR(NULL) publicKey, APTR(UInt8Array) OR(NULL) privateKey){
	RETURN_CONSTRUCT(NoEncrypter,(publicKey, privateKey));
}
/* Does no encryption at all. */


/* create */


NoEncrypter::NoEncrypter (APTR(UInt8Array) OR(NULL) publicKey, APTR(UInt8Array) OR(NULL) privateKey) 
	: Encrypter(publicKey, privateKey) {
	
}
/* encrypting/decrypting */


RPTR(UInt8Array) NoEncrypter::decrypt (APTR(UInt8Array) encrypted){
	WPTR(UInt8Array) 	returnValue;
	returnValue = encrypted;
	return returnValue;
}


RPTR(UInt8Array) NoEncrypter::encrypt (APTR(UInt8Array) clear){
	return CAST(UInt8Array,clear->copy());
}
/* keys */


void NoEncrypter::randomizeKeys (APTR(UInt8Array) /* seed */){
	this->setPublicKey(UInt8Array::string("public"));
	this->setPrivateKey(UInt8Array::string("private"));
}



/* ************************************************************************ *
 * 
 *                    Class NoScrambler 
 *
 * ************************************************************************ */



/* Initializers for NoScrambler */


BEGIN_INIT_TIME(NoScrambler,initTimeNonInherited) {
	DEFINE_SCRAMBLER("NoScrambler",NoScrambler::make ());
} END_INIT_TIME(NoScrambler,initTimeNonInherited);



/* Initializers for NoScrambler */



/* pseudo constructors */


RPTR(Scrambler) NoScrambler::make (){
	RETURN_CONSTRUCT(NoScrambler,());
}
/* Does not actually scramble anything. */


/* scrambling */


RPTR(UInt8Array) NoScrambler::scramble (APTR(UInt8Array) clear){
	WPTR(UInt8Array) 	returnValue;
	returnValue = clear;
	return returnValue;
}
/* testing */


UInt32 NoScrambler::actualHashForEqual (){
	return cat_NoScrambler->hashForEqual() + 1;
}


BooleanVar NoScrambler::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_NoScrambler);
}

	/* automatic 0-argument constructor */
NoScrambler::NoScrambler() {}

#ifndef CRYPTOX_SXX
#include "cryptox.sxx"
#endif /* CRYPTOX_SXX */


#ifndef CRYPTOP_SXX
#include "cryptop.sxx"
#endif /* CRYPTOP_SXX */



#endif /* CRYPTOX_CXX */

