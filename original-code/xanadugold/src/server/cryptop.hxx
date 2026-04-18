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

#ifndef CRYPTOP_HXX
#define CRYPTOP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CRYPTOX_HXX
#include "cryptox.hxx"
#endif /* CRYPTOX_HXX */

#ifndef CRYPTOP_OXX
#include "cryptop.oxx"
#endif /* CRYPTOP_OXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class EncrypterMaker 
 *
 * ************************************************************************ */




	/* Contains a pointer to a function used to create an 
	instance of a particular kind of Encrypter. 
	
	Each concrete Encrypter subclass should create a 
	corresponding EncrypterMaker object and register it in a 
	table, with the name of the encryption algorithm. This should 
	be done using the DECLARE_ENCRYPTER and DEFINE_ENCRYPTER macros. */

class EncrypterMaker : public Heaper {

/* Attributes for class EncrypterMaker */
	CONCRETE(EncrypterMaker)
	EQ(EncrypterMaker)
	NO_GC(EncrypterMaker)
  public: /* create */

	
	EncrypterMaker (EncrypterConstructor ARG(constructor), TCSJ);
	
  public: /* accessing */

	/* Make an instance of this kind of encrypter, with the given 
	public and private keys. */
	
	virtual RPTR(Encrypter) makeEncrypter (APTR(UInt8Array) OR(NULL) ARG(publicKey), APTR(UInt8Array) OR(NULL) ARG(privateKey));
	
  private:
	EncrypterConstructor myConstructor;
};  /* end class EncrypterMaker */



/* ************************************************************************ *
 * 
 *                    Class NoEncrypter 
 *
 * ************************************************************************ */



/* Initializers for NoEncrypter */







	/* Does no encryption at all. */

class NoEncrypter : public Encrypter {

/* Attributes for class NoEncrypter */
	CONCRETE(NoEncrypter)
	NOT_A_TYPE(NoEncrypter)
	NO_GC(NoEncrypter)

/* Initializers for NoEncrypter */



friend class INIT_TIME_NAME(NoEncrypter,initTimeNonInherited);

  public: /* create */

	
	static RPTR(Encrypter) make (APTR(UInt8Array) OR(NULL) ARG(publicKey), APTR(UInt8Array) OR(NULL) ARG(privateKey));
	
  public: /* create */

	
	NoEncrypter (APTR(UInt8Array) OR(NULL) ARG(publicKey), APTR(UInt8Array) OR(NULL) ARG(privateKey));
	
  public: /* encrypting/decrypting */

	
	virtual RPTR(UInt8Array) decrypt (APTR(UInt8Array) ARG(encrypted));
	
	
	virtual RPTR(UInt8Array) encrypt (APTR(UInt8Array) ARG(clear));
	
  public: /* keys */

	
	virtual void randomizeKeys (APTR(UInt8Array) ARG(seed));
	

};  /* end class NoEncrypter */



/* ************************************************************************ *
 * 
 *                    Class NoScrambler 
 *
 * ************************************************************************ */



/* Initializers for NoScrambler */




	/* Does not actually scramble anything. */

class NoScrambler : public Scrambler {

/* Attributes for class NoScrambler */
	CONCRETE(NoScrambler)
	NOT_A_TYPE(NoScrambler)
	NO_GC(NoScrambler)

/* Initializers for NoScrambler */
friend class INIT_TIME_NAME(NoScrambler,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static RPTR(Scrambler) make ();
	
  public: /* scrambling */

	
	virtual RPTR(UInt8Array) scramble (APTR(UInt8Array) ARG(clear));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	

	/* automatic 0-argument constructor */
  public:
	NoScrambler();

};  /* end class NoScrambler */



#endif /* CRYPTOP_HXX */

