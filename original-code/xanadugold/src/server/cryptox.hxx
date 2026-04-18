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

#ifndef CRYPTOX_HXX
#define CRYPTOX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CRYPTOX_OXX
#include "cryptox.oxx"
#endif /* CRYPTOX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */


/*  */
/*  */
typedef SPTR(Encrypter) (*EncrypterConstructor) (APTR(UInt8Array) OR(NULL) publicKey, APTR(UInt8Array) OR(NULL) privateKey);

#define DEFINE_ENCRYPTER(identifier,encryptorClass) {		\
	REQUIRES(Encrypter);			\
	Encrypter::remember(Sequence::string(identifier), encryptorClass::make);			\
}

#define DEFINE_SCRAMBLER(identifier,scrambler) {	\
	REQUIRES(Scrambler);			\
	Scrambler::remember(Sequence::string(identifier), scrambler);				\
}



/* ************************************************************************ *
 * 
 *                    Class Encrypter 
 *
 * ************************************************************************ */



/* Initializers for Encrypter */







	/* An Encrypter is an instantiation of some public-key 
	encryption algorithm, along with optional public and private 
	keys. Each subclass implements a particular algorithm, such 
	as Rivest-Shamir-Adelman, in response to the encryption, 
	decryption, and key generation protocol. 
	
	** obsolete documentation **
	
	The algorithm is identified by a Sequence naming it. Each 
	concrete subclass must register itself during initialization 
	time. This is handled by two macros, DECLARE_ENCRYPTER and 
	DEFINE_ENCRYPTER. DECLARE_ENCRYPTER(AClassName) defines a 
	function that can be used to create an instance. 
	DEFINE_ENCRYPTER("identifier",AClassName) creates an 
	EncrypterMaker parametrized with that "constructor" function 
	pointer, and stores it in the system-wide table of 
	EncrypterMakers. DECLARE_ENCRYPTER should be invoked in 
	function scope (i.e. inside a linkTimeNonInherited class 
	method) and DEFINE_ENCRYPTER should be invoked inside an 
	Initializer (i.e. inside an initTimeNonInherited class method).
	
	The pseudo-constructor to make an Encrypter takes the 
	PackOBits identifying the algorithm, and looks for a 
	corresponding EncrypterMaker in the table. It then asks that 
	EncrypterMaker to create an instance, with the given public 
	and private keys.
	
	Encrypters are mutable objects. This allows you to create an 
	Encrypter, generate new random keys for it, make a copy, 
	remove its private key, and pass that out for public use. */

class Encrypter : public Heaper {

/* Attributes for class Encrypter */
	DEFERRED(Encrypter)
	EQ(Encrypter)
	AUTO_GC(Encrypter)

/* Initializers for Encrypter */



friend class INIT_TIME_NAME(Encrypter,initTimeNonInherited);

  public: /* pseudo constructors */

	/* Make an encrypter of the given type with the given public 
	and private keys. Gets the requested EncrypterMaker out of 
	the table and then asks it to make an encrypter with the 
	given key. Fails with
			BLAST(NoSuchEncrypter) if it is not found. */
	
	static RPTR(Encrypter) make (
			APTR(Sequence) ARG(identifier), 
			APTR(UInt8Array) ARG(publicKey) = NULL, 
			APTR(UInt8Array) ARG(privateKey) = NULL)
	;
	
  public: /* was protected */

	
	static void remember (APTR(Sequence) ARG(identifier), EncrypterConstructor ARG(constructor));
	
  public: /* create */

	
	Encrypter (APTR(UInt8Array) OR(NULL) ARG(publicKey), APTR(UInt8Array) OR(NULL) ARG(privateKey));
	
  public: /* encrypting/decrypting */

	/* Decrypt data with the current private key. */
	
	virtual RPTR(UInt8Array) decrypt (APTR(UInt8Array) ARG(encrypted)) DEFERRED_FUNC;
	
	/* Encrypt the given data with the current public key. */
	
	virtual RPTR(UInt8Array) encrypt (APTR(UInt8Array) ARG(clear)) DEFERRED_FUNC;
	
  public: /* keys */

	
	virtual RPTR(UInt8Array) privateKey ();
	
	
	virtual RPTR(UInt8Array) publicKey ();
	
	/* Generate a new pair of public and private keys using the 
	given data as a random seed. */
	
	virtual void randomizeKeys (APTR(UInt8Array) ARG(seed)) DEFERRED_SUBR;
	
	/* Change the private key. */
	
	virtual void setPrivateKey (APTR(UInt8Array) OR(NULL) ARG(newKey));
	
	/* Change the public key. */
	
	virtual void setPublicKey (APTR(UInt8Array) OR(NULL) ARG(newKey));
	
  private:
	CHKPTR(UInt8Array) OR(NULL) myPublicKey;
	CHKPTR(UInt8Array) OR(NULL) myPrivateKey;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(MuTable) OF2(Sequence,EncrypterMaker) AllEncrypterMakers;
};  /* end class Encrypter */



/* ************************************************************************ *
 * 
 *                    Class Scrambler 
 *
 * ************************************************************************ */



/* Initializers for Scrambler */







	/* A Scrambler implements a one-way hash function. It should 
	be one-way, in that it should be difficult to unscramble, and 
	it should be a hash, in that two similar inputs should 
	produce very different outputs. It is furthermore desirable 
	but not essential that the algorithm be cryptographically 
	secure (the only way to unscramble an output is by scrambling 
	all possible inputs and comparing), and one-to-one (two 
	different inputs never produce the same output). Each 
	subclass implements some particular algorithm such as Snefru, 
	in response to the scrambling protocol. 
	 
	The system maintains a table of all of the known Scramblers, 
	indexed by name (a PackOBits). At initialization time, each 
	concrete subclass should use the DEFINE_SCRAMBLER("identifier"
	,(scramblerExpression)) macro to place an instance in the 
	table at some appropriate identifier. DEFINE_SCRAMBLER must 
	be invoked inside an Initializer (e.g. in an 
	initTimeNonInherited method).
	
	MatchLockSmiths store passwords in scrambled form, so that 
	being able to read the LockSmith is not enough to find out 
	the password. They also store the name of the Scrambler used 
	to scramble it, so that trial passwords can be scrambled and 
	compared. */

class Scrambler : public Heaper {

/* Attributes for class Scrambler */
	DEFERRED(Scrambler)
	NO_GC(Scrambler)

/* Initializers for Scrambler */



friend class INIT_TIME_NAME(Scrambler,initTimeNonInherited);

  public: /* was protected */

	/* Register the existence of a particular kind of scrambler. 
	The identifier must be unique. */
	
	static void remember (APTR(Sequence) ARG(identifier), APTR(Scrambler) ARG(scrambler));
	
  public: /* accessing */

	/* Return a scrambler with the given name. Fail with
			BLAST(NoSuchScrambler) if there is none. */
	
	static RPTR(Scrambler) make (APTR(UInt8Array) ARG(identifier));
	
  public: /* scrambling */

	/* Carry out a one-way hash function on the given clear text. */
	
	virtual RPTR(UInt8Array) scramble (APTR(UInt8Array) ARG(clear)) DEFERRED_FUNC;
	
  public: /* tesing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	Scrambler();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(MuTable) OF2(Sequence,Scrambler) AllScramblers;
};  /* end class Scrambler */



#endif /* CRYPTOX_HXX */

