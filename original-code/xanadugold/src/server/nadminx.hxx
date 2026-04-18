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

#ifndef NADMINX_HXX
#define NADMINX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NADMINX_OXX
#include "nadminx.oxx"
#endif /* NADMINX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef WRAPPERX_HXX
#include "wrapperx.hxx"
#endif /* WRAPPERX_HXX */


#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NADMINP_OXX
#include "nadminp.oxx"
#endif /* NADMINP_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SCHUNKX_OXX
#include "schunkx.oxx"
#endif /* SCHUNKX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FeClubDescription 
 *
 * ************************************************************************ */



/* Initializers for FeClubDescription */







	/* Describes the state of Club -- who is in it, which Work is 
	its home (if it has one), and how you can login to it */

class FeClubDescription : public FeWrapper {

/* Attributes for class FeClubDescription */
	CONCRETE(FeClubDescription)
	ON_CLIENT(FeClubDescription)
	NO_GC(FeClubDescription)

/* Initializers for FeClubDescription */



friend class INIT_TIME_NAME(FeClubDescription,initTimeNonInherited);

  private: /* private: wrapping */

	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	/* Create a new wrapper and endorse it */
	
	static RPTR(FeClubDescription) construct (APTR(FeEdition) ARG(edition));
	
	/* Just create a new wrapper */
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* pseudo constructors */

	
	static CLIENT RPTR(FeClubDescription) make (APTR(FeSet) OR(NULL) OF1(FeClub) ARG(membership), APTR(FeLockSmith) ARG(lockSmith) = NULL);
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* accessing */

	/* Describes how authority for this Club is gained */
	
	virtual CLIENT RPTR(FeLockSmith) lockSmith ();
	
	/* The Clubs which are members of this one. */
	
	virtual CLIENT RPTR(FeSet) OF1(FeClub) membership ();
	
	/* Change how authority is gained */
	
	virtual CLIENT RPTR(FeClubDescription) withLockSmith (APTR(FeLockSmith) ARG(lockSmith));
	
	/* Change the entire membership list */
	
	virtual CLIENT RPTR(FeClubDescription) withMembership (APTR(FeSet) OF1(FeClub) ARG(members));
	
  private: /* private: create */

	
	FeClubDescription (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheClubDescriptionSpec;
/* Friends for class FeClubDescription */
/* friends for class FeClubDescription */

friend class BeClub;



};  /* end class FeClubDescription */



/* ************************************************************************ *
 * 
 *                    Class FeLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeLockSmith */







	/* Describes how to obtain the authority of a Club. */

class FeLockSmith : public FeWrapper {

/* Attributes for class FeLockSmith */
	DEFERRED(FeLockSmith)
	ON_CLIENT(FeLockSmith)
	NO_GC(FeLockSmith)

/* Initializers for FeLockSmith */



friend class INIT_TIME_NAME(FeLockSmith,initTimeNonInherited);

  private: /* private: wrapping */

	
	static void setSpec (APTR(FeWrapperSpec) ARG(spec));
	
  public: /* pseudo constructors */

	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* server locks */

	/* Create a new lock which, if satisfied, will give access to 
	this club. If Club is NULL, then the lock will never be satisfied. */
	
	virtual RPTR(Lock) newLock (APTR(ID) OR(NULL) ARG(clubID)) DEFERRED_FUNC;
	
  protected: /* protected: create */

	
	FeLockSmith (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheLockSmithSpec;
};  /* end class FeLockSmith */



/* ************************************************************************ *
 * 
 *                    Class   FeBooLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeBooLockSmith */







	/* Makes BooLocks; see the comment there */

class FeBooLockSmith : public FeLockSmith {

/* Attributes for class FeBooLockSmith */
	CONCRETE(FeBooLockSmith)
	ON_CLIENT(FeBooLockSmith)
	NO_GC(FeBooLockSmith)

/* Initializers for FeBooLockSmith */



friend class INIT_TIME_NAME(FeBooLockSmith,initTimeNonInherited);

  private: /* private: wrapping */

	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeBooLockSmith) construct (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* pseudo constructors */

	
	static CLIENT RPTR(FeBooLockSmith) make ();
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* server locks */

	/* Make a WallLock if clubID is NULL */
	
	virtual RPTR(Lock) newLock (APTR(ID) OR(NULL) ARG(clubID));
	
  private: /* private: create */

	
	FeBooLockSmith (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheBooLockSmithSpec;
};  /* end class FeBooLockSmith */



/* ************************************************************************ *
 * 
 *                    Class   FeChallengeLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeChallengeLockSmith */







	/* Makes ChallengeLocks; see the comment there */

class FeChallengeLockSmith : public FeLockSmith {

/* Attributes for class FeChallengeLockSmith */
	CONCRETE(FeChallengeLockSmith)
	ON_CLIENT(FeChallengeLockSmith)
	NO_GC(FeChallengeLockSmith)

/* Initializers for FeChallengeLockSmith */



friend class INIT_TIME_NAME(FeChallengeLockSmith,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static CLIENT RPTR(FeChallengeLockSmith) make (APTR(PrimIntArray) ARG(publicKey), APTR(Sequence) ARG(encrypterName));
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  private: /* private: wrapping */

	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeChallengeLockSmith) construct (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* accessing */

	/* The type of encrypter used to create encrypted challenges. */
	
	virtual CLIENT RPTR(UInt8Array) encrypterName ();
	
	/* The public key used to construct challenges. */
	
	virtual CLIENT RPTR(UInt8Array) publicKey ();
	
  public: /* server locks */

	
	virtual RPTR(Lock) newLock (APTR(ID) OR(NULL) ARG(clubID));
	
  private: /* private: create */

	
	FeChallengeLockSmith (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheChallengeLockSmithSpec;
};  /* end class FeChallengeLockSmith */



/* ************************************************************************ *
 * 
 *                    Class   FeMatchLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeMatchLockSmith */







	/* Makes MatchLocks; see the comment there */

class FeMatchLockSmith : public FeLockSmith {

/* Attributes for class FeMatchLockSmith */
	CONCRETE(FeMatchLockSmith)
	ON_CLIENT(FeMatchLockSmith)
	NO_GC(FeMatchLockSmith)

/* Initializers for FeMatchLockSmith */



friend class INIT_TIME_NAME(FeMatchLockSmith,initTimeNonInherited);

  private: /* private: wrapping */

	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeMatchLockSmith) construct (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* pseudo constructors */

	
	static CLIENT RPTR(FeMatchLockSmith) make (APTR(PrimIntArray) ARG(scrambledPassword), APTR(Sequence) ARG(scramblerName));
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* accessing */

	/* The password in scrambled form. If the scrambler is any 
	good, this should be meaningless. */
	
	virtual CLIENT RPTR(UInt8Array) scrambledPassword ();
	
	/* The name of scrambler being used to scramble the password. */
	
	virtual CLIENT RPTR(UInt8Array) scramblerName ();
	
  public: /* server locks */

	
	virtual RPTR(Lock) newLock (APTR(ID) OR(NULL) ARG(clubID));
	
  private: /* private: create */

	
	FeMatchLockSmith (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheMatchLockSmithSpec;
};  /* end class FeMatchLockSmith */



/* ************************************************************************ *
 * 
 *                    Class   FeMultiLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeMultiLockSmith */







	/* Makes MultiLocks; see the comment there */

class FeMultiLockSmith : public FeLockSmith {

/* Attributes for class FeMultiLockSmith */
	CONCRETE(FeMultiLockSmith)
	ON_CLIENT(FeMultiLockSmith)
	NO_GC(FeMultiLockSmith)

/* Initializers for FeMultiLockSmith */



friend class INIT_TIME_NAME(FeMultiLockSmith,initTimeNonInherited);

  private: /* private: wrapping */

	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeMultiLockSmith) construct (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* pseudo constructors */

	
	static CLIENT RPTR(FeMultiLockSmith) make ();
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* server locks */

	
	virtual RPTR(Lock) newLock (APTR(ID) OR(NULL) ARG(clubID));
	
  public: /* accessing */

	/* The named LockSmith */
	
	virtual CLIENT RPTR(FeLockSmith) lockSmith (APTR(Sequence) ARG(name));
	
	/* The names of all the Locksmiths this uses. */
	
	virtual CLIENT RPTR(SequenceRegion) OF1(Sequence) lockSmithNames ();
	
	/* Add or change a LockSmith */
	
	virtual CLIENT RPTR(FeMultiLockSmith) with (APTR(Sequence) ARG(name), APTR(FeLockSmith) ARG(smith));
	
	/* Add or change a LockSmith */
	
	virtual CLIENT RPTR(FeMultiLockSmith) without (APTR(Sequence) ARG(name));
	
  private: /* private: create */

	
	FeMultiLockSmith (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheMultiLockSmithSpec;
};  /* end class FeMultiLockSmith */



/* ************************************************************************ *
 * 
 *                    Class   FeWallLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeWallLockSmith */







	/* Makes WallLocks; see the comment there */

class FeWallLockSmith : public FeLockSmith {

/* Attributes for class FeWallLockSmith */
	CONCRETE(FeWallLockSmith)
	ON_CLIENT(FeWallLockSmith)
	NO_GC(FeWallLockSmith)

/* Initializers for FeWallLockSmith */



friend class INIT_TIME_NAME(FeWallLockSmith,initTimeNonInherited);

  private: /* private: wrapping */

	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWallLockSmith) construct (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* pseudo constructors */

	
	static CLIENT RPTR(FeWallLockSmith) make ();
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* server locks */

	
	virtual RPTR(Lock) newLock (APTR(ID) OR(NULL) ARG(clubID));
	
  private: /* private: create */

	
	FeWallLockSmith (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheWallLockSmithSpec;
};  /* end class FeWallLockSmith */



/* ************************************************************************ *
 * 
 *                    Class FeSession 
 *
 * ************************************************************************ */



/* Initializers for FeSession */
DESIGN_FLUID(FeSession,CurrentSession);	/* in FeSession */




	/* Represent a single unique connection to the server over 
	some underlying bytestream channel. */

class FeSession : public Heaper {

/* Attributes for class FeSession */
	CONCRETE(FeSession)
	ON_CLIENT(FeSession)
	AUTO_GC(FeSession)

/* Initializers for FeSession */


  public: /* accessing */

	/* CurrentSessions fluidFetch == NULL
			ifTrue: [^Stepper itemStepper: CurrentSession fluidGet]
			ifFalse:
				[| acc {SetAccumulator} cur {FePromiseSession} |
				acc _ SetAccumulator make.
				cur _ CurrentSessions fluidGet.
				[cur ~~ NULL] whileTrue:
					[acc step: cur.
					cur _ cur next].
				^(acc value cast: ScruSet) stepper] */
	
	static RPTR(Stepper) OF1(FeSession) allActive ();
	
	
	static CLIENT RPTR(FeSession) current ();
	
  public: /* accessing */

	/* Essential. The clock time at which the connection was initiated. */
	
	virtual CLIENT IntegerVar connectTime ();
	
	/* Essential. Terminate this connection.  If withPrejudice is 
	false, it completes the current request and flushes all 
	output before disconnecting. */
	
	virtual CLIENT void endSession (BooleanVar ARG(withPrejudice) = FALSE) DEFERRED_SUBR;
	
	/* Essential. The ID of the club that the session logged into 
	to get past the perimeter.  Blast of the session is not yet 
	admitted. */
	
	virtual CLIENT RPTR(ID) initialLogin ();
	
	/* Return whether the session has sucessfully logged in, and 
	is still logged in. */
	
	virtual CLIENT BooleanVar isConnected () DEFERRED_FUNC;
	
	/* Return whether the session has sucessfully logged in. */
	
	virtual BooleanVar isLoggedIn ();
	
	/* Essential. A system-specific description of the actual 
	transport medium over which the connection is being maintained. */
	
	virtual CLIENT RPTR(UInt8Array) port () DEFERRED_FUNC;
	
  public: /* creation */

	
	FeSession ();
	
  private: /* private: accessing */

	/* Set the ID of the Club which initially logged in during 
	this session */
	
	virtual void setInitialLogin (APTR(ID) ARG(iD));
	
  private:
	CHKPTR(ID) OR(NULL) myInitialLogin;
	IntegerVar myConnectTime;
/* Friends for class FeSession */
friend class Lock;



};  /* end class FeSession */



/* ************************************************************************ *
 * 
 *                    Class Lock 
 *
 * ************************************************************************ */




	/* To login to a club, you ask the server for a Lock. If you 
	send the right message to the Lock, it will return you a new 
	KeyMaster with the authority of the club. Each subclass of 
	Lock defines its own protocol for opening. 
	
	For each kind of Lock, there is a corresponding kind of 
	LockSmith which creates it. Each ClubManager has a LockSmith 
	sub-document, and when you ask the server for a Lock to that 
	club, it asks the club`s LockSmith document Wrapper to create 
	a newLock. The LockSmith then creates the corresponding kind 
	of Lock. It may also use information stored in the LockSmith 
	document, such as a password or scramblerName. */

class Lock : public Heaper {

/* Attributes for class Lock */
	DEFERRED(Lock)
	ON_CLIENT(Lock)
	EQ(Lock)
	AUTO_GC(Lock)
  public: /* create */

	
	Lock (APTR(ID) ARG(loginID), APTR(FeLockSmith) ARG(lockSmith));
	
  public: /* server accessing */

	/* The lock is opened - make the right KeyMaster */
	
	virtual RPTR(FeKeyMaster) makeKeyMaster ();
	
  protected: /* protected: */

	/* The ID of the club whose authority you can get by opening 
	this lock. */
	
	virtual RPTR(ID) fetchLoginClubID ();
	
	/* Essential. The LockSmith which made this Lock. */
	
	virtual RPTR(FeLockSmith) lockSmith ();
	
  private:
	CHKPTR(ID) myLoginClubID;
	CHKPTR(FeLockSmith) myLockSmith;
};  /* end class Lock */



/* ************************************************************************ *
 * 
 *                    Class   BooLock 
 *
 * ************************************************************************ */




	/* A BooLock is very easy to open. Just say "boo". 
	
	Since anyone can get in, only public clubs with little 
	authority, such as System Public, should have BooLockSmiths. */

class BooLock : public Lock {

/* Attributes for class BooLock */
	CONCRETE(BooLock)
	ON_CLIENT(BooLock)
	NO_GC(BooLock)
  public: /* pseudo constructors */

	
	static RPTR(BooLock) make (APTR(ID) ARG(clubID), APTR(FeLockSmith) ARG(lockSmith));
	
  public: /* accessing */

	/* Essential.  This is a very easy lock to open. Just say `boo'. */
	
	virtual CLIENT RPTR(FeKeyMaster) boo ();
	
  private: /* private: create */

	
	BooLock (APTR(ID) ARG(clubID), APTR(FeLockSmith) ARG(lockSmith));
	

};  /* end class BooLock */



/* ************************************************************************ *
 * 
 *                    Class   ChallengeLock 
 *
 * ************************************************************************ */




	/* A ChallengeLock challenges the client with a random piece 
	of data that has been encrypted with a publicKey, using an 
	algorithm identified by the encrypterName. The client must 
	decrypt it using the corresponding private key and respond 
	with the decrypted challenge. If it matches the original 
	random data, then the lock will open. The encrypterName and 
	the publicKey are stored in the club`s ChallengeLockSmith.  */

class ChallengeLock : public Lock {

/* Attributes for class ChallengeLock */
	CONCRETE(ChallengeLock)
	ON_CLIENT(ChallengeLock)
	AUTO_GC(ChallengeLock)
  public: /* pseudo constructors */

	
	static RPTR(ChallengeLock) make (
			APTR(ID) OR(NULL) ARG(loginID), 
			APTR(FeChallengeLockSmith) ARG(lockSmith), 
			APTR(UInt8Array) ARG(response))
	;
	
  private: /* private: create */

	
	ChallengeLock (
			APTR(ID) ARG(allegedID), 
			APTR(FeLockSmith) ARG(lockSmith), 
			APTR(UInt8Array) ARG(challenge), 
			APTR(UInt8Array) ARG(response))
	;
	
  public: /* accessing */

	/* Essential.  The challenge which must be signed correctly 
	to open the lock. */
	
	virtual CLIENT RPTR(UInt8Array) challenge ();
	
	/* Essential.  The correctly signed challenge will open the lock. */
	
	virtual CLIENT RPTR(FeKeyMaster) response (APTR(PrimIntArray) ARG(signedChallenge));
	
  private:
	CHKPTR(UInt8Array) myChallenge;
	CHKPTR(UInt8Array) myResponse;
};  /* end class ChallengeLock */



/* ************************************************************************ *
 * 
 *                    Class   MatchLock 
 *
 * ************************************************************************ */


/* exceptions: exceptions */

PROBLEM_LIST(PasswordDoesNotMatchFilter,1,(PasswordDoesNotMatch));



	/* The correct password will open the lock. The password is 
	actually stored in the club`s MatchLockSmith in scrambled 
	form, using a Scrambler identified by scramblerName(). The 
	scrambled cleartext supplied as a password is compared to the 
	scrambledPassword in the MatchLockSmith. If they match, the 
	lock is opened. 
	
	The actual process is a bit more complicated than this. The 
	user supplies a password in clear, which is encrypted with 
	the current system public key and then sent to the server. 
	There, it is first decrypted with the private key known only 
	to the server. It is then scrambled and compared with the 
	scrambled password stored in the MatchLockSmith of the club. 
	This procedure both avoids sending passwords in clear over 
	the network, and also allows the MatchLockSmith to be made 
	readable without compromising security. */

class MatchLock : public Lock {

/* Attributes for class MatchLock */
	CONCRETE(MatchLock)
	ON_CLIENT(MatchLock)
	NO_GC(MatchLock)
  public: /* pseudo constructors */

	
	static RPTR(MatchLock) make (APTR(ID) OR(NULL) ARG(clubID), APTR(FeMatchLockSmith) ARG(lockSmith));
	
  public: /* accessing */

	/* Send the encrypted password to the server to be checked.
		NOTE: (for protocol review) The password must have been 
	encrypted using a (yet-to-be-defined) front end library 
	function, since this sort of front end computation can't be 
	done with Promises. */
	
	virtual CLIENT RPTR(FeKeyMaster) encryptedPassword (APTR(PrimIntArray) ARG(encrypted));
	
  private: /* private: create */

	
	MatchLock (APTR(ID) ARG(loginID), APTR(FeMatchLockSmith) ARG(lockSmith));
	

};  /* end class MatchLock */



/* ************************************************************************ *
 * 
 *                    Class   MultiLock 
 *
 * ************************************************************************ */




	/* A MultiLock allows the client to open the lock with any of 
	a list of Locks. This allows a Club to have different 
	passwords for different people; or, the Locks can use 
	different kinds of native authentication systems such as NIS 
	or Kerberos. */

class MultiLock : public Lock {

/* Attributes for class MultiLock */
	CONCRETE(MultiLock)
	ON_CLIENT(MultiLock)
	AUTO_GC(MultiLock)
  public: /* create */

	
	static RPTR(MultiLock) make (
			APTR(ID) OR(NULL) ARG(loginID), 
			APTR(FeMultiLockSmith) ARG(lockSmith), 
			APTR(ImmuTable) OF1(Lock) ARG(locks))
	;
	
  public: /* create */

	
	MultiLock (
			APTR(ID) ARG(loginID), 
			APTR(FeMultiLockSmith) ARG(lockSmith), 
			APTR(ImmuTable) OF1(Lock) ARG(locks))
	;
	
  public: /* accessing */

	/* Get the named lock. You don't get any authority through a 
	MultiLock directly, you merely get a Lock from which you can 
	get authority. */
	
	virtual CLIENT RPTR(Lock) lock (APTR(Sequence) ARG(name));
	
	/* Essential. The names identifying the locks in the list */
	
	virtual CLIENT RPTR(SequenceRegion) lockNames ();
	
  private:
	CHKPTR(ImmuTable) OF2(Sequence,Lock) myLocks;
};  /* end class MultiLock */



/* ************************************************************************ *
 * 
 *                    Class   WallLock 
 *
 * ************************************************************************ */




	/* A Wall cannot be opened. Sorry, dude!!
	
	Clubs can have WallLockSmiths for a variety of reasons. Clubs 
	that represent groups of users, and to which noone should be 
	able to login directly (only as a member using 
	loginToSuperClub), will have WallLockSmiths. Or, if you want 
	to make a document read-only, remove all the members from its 
	editClub, make it self-reading, and put a WallLockSmith on 
	it; then, noone can login to the club, either directly or as 
	a member, and noone can change it.  */

class WallLock : public Lock {

/* Attributes for class WallLock */
	CONCRETE(WallLock)
	ON_CLIENT(WallLock)
	NO_GC(WallLock)
  public: /* pseudo constructors */

	
	static RPTR(WallLock) make (APTR(ID) OR(NULL) ARG(clubID), APTR(FeLockSmith) ARG(lockSmith));
	
  private: /* private: create */

	
	WallLock (APTR(ID) ARG(loginID), APTR(FeLockSmith) ARG(lockSmith));
	

};  /* end class WallLock */



#endif /* NADMINX_HXX */

