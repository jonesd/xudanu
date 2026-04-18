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

#ifndef SNFINFOX_HXX
#define SNFINFOX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SNFINFOX_OXX
#include "snfinfox.oxx"
#endif /* SNFINFOX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */

#ifndef URDIX_OXX
#include "urdix.oxx"
#endif /* URDIX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SnarfHandler 
 *
 * ************************************************************************ */



/* Initializers for SnarfHandler */




	/* A SnarfHandler breaks a snarf into abstract subarrays of 
	bytes into whic flocks are stored.  These indexed flock 
	storage areas are accessed through readStreams and 
	writeStreams provided by the SnarfHandler.  SnarfHandlers 
	also provide the ability to resize these flock areas and 
	associate a couple of flag bits with them.  All access to the 
	snarf goes through a single snarfHandler.
	
	The beginning of the snarf is dedicated to a table that 
	describes the locations and sizes of the contained flock 
	areas.  Currently, we allocate space between the flock 
	nearest the front of the snarf and the end of the mapTable.  
	When not enough space exists between the two, we compact the 
	flock storage areas towards the back (highest address) of the 
	snarf and try to allocate again.
	
	An index in the snarfHAndler can be associated either with 
	one of these flock storage areas or with a snarfID and index 
	to look further for the storage of a given flock.  Right now, 
	the SnarfHAndler keeps the forwarding information in a flock 
	storage area, but it will soon be put into the mapTable directly.
	
	Forwarding pointers occur when a flock outgrows a snarf, and 
	must be moved elsewhere.  Eventually all other snarfs that 
	have objects which point to the forwarding pointer are 
	updated, and the forwarding pointer can be deallocated, but 
	decisions about this must be made by objects external to the 
	SnarfHandler.
	
	The forwarded flag is stored on the snarfID.  The forgotten 
	flag is stored on the size.  Both use the same Flag mask for 
	accessing the flag, and the Value mask for accessing the value. */

class SnarfHandler : public Heaper {

/* Attributes for class SnarfHandler */
	CONCRETE(SnarfHandler)
	AUTO_GC(SnarfHandler)

/* Initializers for SnarfHandler */


  public: /* pcreate */

	
	static RPTR(SnarfHandler) make (APTR(SnarfHandle) ARG(snarfHandle));
	
  public: /* accessing */

	/* The number of bytes for one fence (Each flock requires two). */
	
	static Int32 fenceSize ();
	
	/* Return the number of bytes for a single map record, plus 
	the space for the 
		fence. The fence will be just the index of the flock stored 
	at the beginning and 
		the end of the flock's memory */
	
	static INLINE Int32 mapCellOverhead ();
	
	/* Return the number of bytes for a single map record. */
	
	static INLINE Int32 mapCellSize ();
	
	/* The map starts just after the basic header.  The basic 
	header currently has
		 the number of entries in the map and total amount of free 
	space remaining. */
	
	static INLINE Int32 mapOverhead ();
	
  private: /* private: sorting */

	
	static void quickSort (
			APTR(UInt32Array) ARG(offsets), 
			APTR(UInt32Array) ARG(indices), 
			Int32 ARG(first), 
			Int32 ARG(last))
	;
	
	
	static void quickSort (
			APTR(UInt32Array) ARG(offsets), 
			APTR(UInt32Array) ARG(indices), 
			APTR(OrderSpec) ARG(os), 
			IntegerVar ARG(first), 
			IntegerVar ARG(last))
	;
	
	/* Sort the offsets array in place, and return an array of 
	the same size that maps from the new index of each element to 
	its original index.  The offsets array is *assumed* to be 
	terminated with a guard element which is greater than or 
	equal to all the other elements of the array according to 
	descending order.  If this isn't true, havoc may result. */
	
	static RPTR(UInt32Array) sort (APTR(UInt32Array) ARG(offsets));
	
	/* Sort the offsets array in place, and return an array of 
	the same size that maps from the new index of each element to 
	its original index.  The offsets array is *assumed* to be 
	terminated with a guard element which is greater than or 
	equal to all the other elements of the array according to the 
	sorting order.  If this isn't true, havoc may result. */
	
	static RPTR(UInt32Array) sort (APTR(UInt32Array) ARG(offsets), APTR(OrderSpec) ARG(os));
	
	
	static INLINE void swap (
			APTR(UInt32Array) ARG(array), 
			IntegerVar ARG(i), 
			IntegerVar ARG(j))
	;
	
  public: /* reading */

	/* If the flock specified by index has been forwarded, return 
	a FlockLocation with the SnarfID and index of its new location. */
	
	virtual RPTR(FlockLocation) OR(NULL) fetchForward (Int32 ARG(index));
	
	/* Return the number of bytes in the flock at index */
	
	virtual Int32 flockSize (Int32 ARG(index));
	
	/* The forgotten flag is the flag bit associated with each 
	flock.  It is set when the
		flock has been forgotten, which means that there are no more 
	persistent pointers
		to the flock.  When a flock is forgotten AND is not in RAM, 
	the SnarfPacker is
		free to bring the flock back into RAM and destroy it, which 
	deletes it from the snarf.
		 
		 Return true if the forgotten flag has been set for the 
	flock at index. */
	
	virtual BooleanVar isForgotten (Int32 ARG(index));
	
	/* Return true if there's a flock or forwarder at index. */
	
	virtual BooleanVar isOccupied (Int32 ARG(index));
	
	/* Return the number of slots allocated in the map table. */
	
	virtual Int32 mapCount ();
	
	/* Return a stream on the area of the snarf allocated to mapIndex.  
		 This stream must be used immediately, then thrown away. */
	
	virtual RPTR(XnReadStream) readStream (Int32 ARG(index));
	
	/* Return the snarfID of the snarf this handle holds. */
	
	virtual Int32 snarfID ();
	
	/* Return the amount space left in the snarf. */
	
	virtual Int32 spaceLeft ();
	
  public: /* writing */

	/* Add more cells to the mapTable.  Make sure that there is 
	enough space for
		 those cells, then initialize.  The size is initially 0 and 
	the offset points past 
		 the end of the snarf. */
	
	virtual void allocateCells (IntegerVar ARG(indices));
	
	/* Allocate flockSize bytes for the flock at the index ind. */
	
	virtual void allocate (IntegerVar ARG(ind), Int32 ARG(flockSize));
	
	/* See the comment on isForgotten:.  Set or clear the 
	forgetFlag for the flock at index. */
	
	virtual void storeForget (Int32 ARG(index), BooleanVar ARG(flag));
	
	/* Associate a forwarder with index.  Throw away whatever storage
		 was assigned to it and store the forwarder information in 
	the mapCell. */
	
	virtual void forwardTo (
			IntegerVar ARG(index), 
			Int32 ARG(newSnarfID), 
			Int32 ARG(newIndex))
	;
	
	/* Return true if I represent a writable snarf.  */
	
	virtual BooleanVar isWritable ();
	
	/* Make the handle for the receiver writable. */
	
	virtual void makeWritable ();
	
	/* Write out to the snarf any values held in instance variables (space 
		remaining, number of entries, etc.). */
	
	virtual void rewrite ();
	
	/* Deallocate all space for the flock at index.  The slot for 
	index remains however, and can be reused for another flock. */
	
	virtual void wipeFlock (IntegerVar ARG(index));
	
	/* Return a stream that can write into the bytes allocated to 
	the flock at index. 
		 The stream must be used immediately and thrown away. */
	
	virtual RPTR(XnWriteStream) writeStream (IntegerVar ARG(index));
	
  public: /* initialize */

	/* Put in the minimum necessary for a starting snarf.  
		 All it needs is the number of objects and the spaceLeft.
		 This also writes the information to the real snarf. */
	
	virtual void initializeSnarf ();
	
  private: /* private: operations */

	/* If we are using fences around flock storage areas, then 
	return true only if the fences are still in place for the 
	flock at index.  Fences are extra storage at the front and 
	back of a flock storage area that contains the index of that 
	flock.  These are used for runtime checks that one flock 
	hasn't stepped into the space of another. */
	
	virtual BooleanVar checkFence (Int32 ARG(index));
	
	/* See checkFence:  Check the fences for all flocks and blast 
	if any are violated. */
	/* Int32Zero to: myMapCount-1 do:
			[:i {Int32} | (self checkFence: i) ifFalse: [SnarfHandler 
	BLAST: #BrokenFence]] */
	
	virtual void checkFences ();
	
	/* Blast if the index is not represented in the table.  This 
	is just simple bounds checking. */
	
	virtual void checkIndex (Int32 ARG(index));
	
	/* This checks for count bytes available at the end of the 
	mapTable.  If
		 there isn't enough, it compacts everything and tries again. */
	
	virtual void clearSpace (Int32 ARG(count));
	
	/* Compress flock storage areas towards the end of the snarf, 
	leaving all
		 freespace between the end of the mapTable and the nearest flock. */
	
	virtual void compact ();
	
	/* Generic checking hook to do slow runtime consistency 
	checking when debugging.  No checks are active currently. */
	/* self compact.
		mySpaceLeft == (self nearestFlock - self mapEnd) assert: 
	'space mismatch'. */
	/* | sum {Int32} |
		sum _ Int32Zero.
		Int32Zero almostTo: myMapCount do: 
			[:i {Int32} |
			(self isForwarded: i) ifFalse: [sum _ sum + (self getSize: i)]].
		sum + self mapEnd + mySpaceLeft == myHandle getDataSize 
	assert: 'Space difference' */
	
	virtual void consistencyCheck ();
	
	/* Couldn't resist the name.  Set up the fences for the flock 
	at index.  See checkFence: */
	
	virtual void mendFences (Int32 ARG(index));
	
	/* Return the location of the nearest flock. Everything between the 
		end of the map and the nearest flock is free space. We normally 
		allocate everything from the back of the snarf forward. When we 
		run out of enough contiguous space, we simply compact.
		
		We keep a cache of the current nearest flock.  The cache 
	maintins the invariant that it
		 *must* point to an offset less than or equal to the 
	nearestFlock.  Thus it can be too close 
		 to the mapTable, in which case we will recompute it from scratch. */
	
	virtual Int32 nearestFlock ();
	
	/* Recalculate the nearest flock by looking at the start of 
	every flock and taking the min. */
	
	virtual void recomputeNearest ();
	
  private: /* private: layout */

	/* Store the offset as the starting location for the data of 
	the flock at index.  
		 Update the cache of nearestFlock.  This also clears the 
	forwarded flag. */
	
	virtual void storeIndex (Int32 ARG(index), Int32 ARG(offset));
	
	/* Store size as the number of bytes for the flock at index.  If the 
		 space is at a 0, then change the corresponding pointer to 
	past the end of 
		 the snarf so that we don't find it in our searches. */
	
	virtual void storeSize (Int32 ARG(index), Int32 ARG(size));
	
	/* Return the index of the first byte of the actual data 
	associated with flock number index.  This is like indexOf: 
	except that it leaves room for fencePosts on either side of 
	the flock storage area. */
	
	virtual Int32 flockOffset (Int32 ARG(index));
	
	/* Return the index of the cell one greater than the size of 
	the entire snarf.  This is just past the end of the storage 
	area for flocks. */
	
	virtual Int32 flocksEnd ();
	
	/* Return the index of the first byte of the actual data 
	associated with
		 flock number index.  This area includes space for 
	fencePosts and whatever 
		 other things we might dream up that go with the flock in 
	its storage area. */
	
	virtual Int32 getOffset (Int32 ARG(index));
	
	/* Return the number of bytes in the flock at index.  This 
	includes space allocated internally for fencePosts and the like. */
	
	virtual Int32 getSize (Int32 ARG(index));
	
	/* Return the internal bit that says whether the flock at 
	index is represented by forwarding information or by a flock area */
	
	virtual BooleanVar isForwarded (Int32 ARG(index));
	
	/* Return the offset into the snarf for the mapCell that has 
	the data for the flock at index. */
	
	INLINE Int32 mapCellOffset (Int32 ARG(index));
	
	/* Return the index of the cell just after the end of the 
	map.  This is based on the number of entries in the map. */
	
	virtual Int32 mapEnd ();
	
	/* Actually get from the snarf the number of map slots 
	currently allocated, 
		including ones that are free for reuse. This is stored as 
	the first thing in the 
		snarf. */
	
	virtual Int32 snarfMapCount ();
	
	/* Actually get from the snarf the amount of unallocated 
	space remaining. */
	
	virtual Int32 snarfSpaceLeft ();
	
  protected: /* protected: destruct */

	/* Write my internal constants to the snarf before I go away. */
	
	virtual void destruct ();
	
  public: /* create */

	
	SnarfHandler (APTR(SnarfHandle) ARG(handle), TCSJ);
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	SnarfHandle * myHandle;
	Int4 myMapCount;
	Int4 mySpaceLeft;
	Int4 myNearest;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static UInt4 Flag;
	static Int4 SizeOffset;
	static BooleanVar UseFences;
	static UInt4 Value;
};  /* end class SnarfHandler */



/* ************************************************************************ *
 * 
 *                    Class SnarfInfoHandler 
 *
 * ************************************************************************ */



/* Initializers for SnarfInfoHandler */




	/* The SnarfInfoHandler is an interface to the first few 
	snarfs in an urdi that tells how much space is unallocated in 
	each of the remaining snarfs, and keeps a bit as to whether 
	any forgotten objects are in each snarf.
	
	The data is kept packed in the first few snarfs with 4 bytes 
	per snarf recorded.  The forgotten bit is the high bit of each entry.
	
	mySnarfs is a table of SnarfHandles onto the snarfInfo snarfs 
	(the first few snarfs in the Urdi).  You release those snarfs 
	by destroying the snarfInfoHandler and creating a new one 
	when you want the information again.
	
	myTotal is the total number of snarfs in the Urdi. */

class SnarfInfoHandler : public Heaper {

/* Attributes for class SnarfInfoHandler */
	CONCRETE(SnarfInfoHandler)
	AUTO_GC(SnarfInfoHandler)

/* Initializers for SnarfInfoHandler */


  public: /* pcreate */

	
	static void initializeSnarfInfo (APTR(Urdi) ARG(urdi), APTR(UrdiView) ARG(view));
	
	
	static RPTR(SnarfInfoHandler) make (APTR(Urdi) ARG(urdi), APTR(UrdiView) ARG(view));
	
  public: /* accessing */

	/* Return the forgotten bit for the snarf at snarfID. */
	
	virtual BooleanVar getForgottenFlag (Int32 ARG(snarfID));
	
	/* Return the spaceLeft for the snarf at snarfID. */
	
	virtual Int32 getSpaceLeft (Int32 ARG(snarfID));
	
	/* Set or clear the forgotten bit for the snarf at snarfID. */
	
	virtual void setForgottenFlag (Int32 ARG(snarfID), BooleanVar ARG(flag));
	
	/* Set the space for the snarf at snarfID. */
	
	virtual void setSpaceLeft (Int32 ARG(snarfID), Int32 ARG(space));
	
	/* Return the total number of snarfs in the urdi. */
	
	virtual Int32 snarfCount ();
	
	/* Return the number of snarfs that the snarf info information takes 
		up. This is used to know what snarf to get the first object from. */
	
	virtual Int32 snarfInfoCount ();
	
  private: /* private: */

	/* Se the spaceLeft to a certain amount, and clear all the 
	flags. This is used 
		when initializing the snarfInfo so we don't get confused by 
	the flags. */
	
	virtual void initializeSpaceLeft (Int32 ARG(snarfID), Int32 ARG(space));
	
	/* Return the snarfHandle for the snarfInfo snarf that 
	contains the spaceLeft and forgotten flag for the snarf at snarfID. */
	
	virtual Int32 locate (Int32 ARG(snarfID));
	
  protected: /* protected: destruct */

	/* Release all my handles before going away. */
	
	virtual void destruct ();
	
  public: /* create */

	/* This constructor is for a newly created urdi with no 
	existing snarfInfo 
		information. Set the spaceLeft for each snarf to its maximum 
	and clear the 
		forgotten flag. Note that this figures out how many 
	snarfInfo snarfs to use on 
		the fly by allocating as many snarfInfo cells as it can in 
	the first snarf, then 
		going on to the second snarf, until enough snarfInfo snarfs 
	are allocated. Then 
		it goes through all the entries in the snarfInfo for each 
	non-snarfInfo snarf 
		and set the spaceLeft appropriately. */
	
	SnarfInfoHandler (APTR(Urdi) ARG(urdi), APTR(UrdiView) ARG(view));
	
	/* This constructor is for reopening an existing urdi and 
	using its existing snarfInfo.
		 Read snarfs until it has enough cells for all snarfs in fthe urdi. */
	
	SnarfInfoHandler (APTR(UrdiView) ARG(view), APTR(Urdi) ARG(urdi));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(MuTable) OF1(SnarfHandle) mySnarfs;
	Int4 myTotal;
	CHKPTR(SnarfHandle) myCurrentHandle;
	Int4 myCurrentStart;
	IntegerVar myCurrentIndex;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Int4 ForgottenFlag;
	static Int4 SizeMask;
/* Friends for class SnarfInfoHandler */
/* friends for class SnarfInfoHandler */
friend class SnarfInfoStepper;


};  /* end class SnarfInfoHandler */


#ifdef USE_INLINE
#ifndef SNFINFOX_IXX
#include "snfinfox.ixx"
#endif /* SNFINFOX_IXX */


#endif /* USE_INLINE */


#endif /* SNFINFOX_HXX */

