/* ========================================================================== */
//
//	Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
//
/* ========================================================================== */
//
// The information contained herein is confidential, proprietary to Xanadu
// Operating Company, and considered a trade secret as defined in section
// 499C of the penal code of the State of California.
//
// Use of this information by anyone other than authorized employees of
// Xanadu is granted only under a written nondisclosure agreement,
// expressly prescribing the scope and manner of such use.
//
// The above copyright notice is not to be construed as evidence of
// publication or the intent to publish.
//
/* ========================================================================== */
//
//			urdip.hxx
//
//		Private header file for URDI routines.
//
//		By Michael McClary		1989
//
/* ========================================================================== */
//
//	Moved canPtr() routine to urdix.cxx
//		- michael Jun  4 1991
//
//	Added TRUEHEADER() macro.  (Move to alloc later?)
//		- michael Aug 11 1991
//
//	Cleaned up #endif comment for ANSI
//		- michael Sep  6 1991 (Merged Sep 16)
//
//	Changing hash storage to a fixed size to simplify hash func changes
//		- michael Sep 16 1991

// (NOTE that #includes also appear on next page.)

#include "../xpp/allocx.hxx"

/* ========================================================================== */
//
//	Conversion routine for cannonical pointer printing.
//
/* ========================================================================== */

char *
urdiCanPtr(void * pointer, int columns =0);

extern UInt32	urdiCanRef;

#define	canPtr(x)	urdiCanPtr(x)

/* ========================================================================== */
//
//	Miscelaney for memory leak isolation.
//
/* ========================================================================== */

#define PLUMBER
#ifdef PLUMBER

#define TRUEHEADER(obj)	(					\
	(*((UInt32 *)(void *)obj - 1) == 0) ?			\
		((ABufHead*)((UInt32 *)(void *)obj - 1) - 1)	\
	   :							\
		((ABufHead*)((void *)obj) - 1)			\
)

#endif /* PLUMBER */
/* ========================================================================== */
//
//	File format only known to Urdi.
//
/* ========================================================================== */

const UInt32 		VERS		= 0x21;  // (Counting down from 0x23...)
						// 22 = short snefru
						// 21 = fastHash

/*	The hash function covers all of the record except the hash storage.
 *
 *	If the logical record is smaller than the physical record (i.e.
 *	snarfs from a variable-snarf-size URD which are currently in
 *	the staging area, or guard records) the hash will include only
 *	the logical record.
 */

/* ========================================================================== */
//
//	Guard record layout
//
/* ========================================================================== */

#define	EXPECTED_SIZE_OF_GUARD_RECORD	68
#define MAX_HASH_SIZE			8

#include "fhashx.hxx"
#define	HASH_SIZE	1

#define	SHUFFLE_CHARS	8
#define	URDI_MAGIC	0x55524449		/* "URDI" */
#define	URDI_MAGIC_2143	0x52554944		/* "RUID" */
#define	URDI_MAGIC_3412	0x44495552		/* "DIUR" */
#define	URDI_MAGIC_4321	0x49445255		/* "IDRU" */

struct UrdiGuardRecord {
	UInt32		hash[MAX_HASH_SIZE];	// Snefru[4] or [8], fhash[1]
	UInt32		pad1[2];		// (Pad for ideas that died)
	UInt8		shuffle[SHUFFLE_CHARS];	// Endian-fixup
	UInt32		urdi_magic;		// "URDI"
	UInt32		version;
	UInt32		snarfSize;
	UInt32		snarfCount;
	UInt32		stagingAreaSize;
};

/* ========================================================================== */
//
//	Snarf header layout
//
/* ========================================================================== */

#define	EXPECTED_SIZE_OF_SNARF_HEADER	64

enum	GroupFlag	{ GROUP_MEMBER, GROUP_END, GROUP_SET_END };

struct SnarfHeader {
	UInt32		hash[MAX_HASH_SIZE];	// Snefru[4] or [8], fhash[1]
	UInt32		pad1[2];		// (Pad for ideas that died)
	UInt8		shuffle[SHUFFLE_CHARS];	// Endian-fixup
	Int32		snarfID;		// What hanger in closet?
	UInt32		cycleNumber;		// Update cycle.
	Int32		groupFlag;		// End of group?  End of set?
	UInt8		partridge[4];		// !!!! In a pear tree...
};
