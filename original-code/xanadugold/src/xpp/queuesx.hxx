/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */

#ifndef QX_HXX
#define QX_HXX

#ifndef XCOMPATX_HXX
#include "xcompatx.hxx"
#endif /* XCOMPATX_HXX */

VERSION_ID(queuesx_hxx,
	   "$Id: queuesx.hxx,v 2.6 1992/08/14 22:10:46 shap Exp $")

/*  General purpose doubly-linked list.  This object is both the head of a
     list and the nodes within the list.  These aren't really meant to be
     used to link Heapers.  For non-Heaper objects, one of these can be
     the first variable within the struct or class, and then the pointers
     to the object of Queue part are interchangeable.  When not the first
     object--as would be the usual case in a Heaper--screwy address arithmetic
     would be required.  Yuch!
     Heapers can, however, contain one of these in order to be the head of
     a list of other objects.
*/

class Queue ROOTCLASS {

public:

  /* The constructor for Queue does not initialize the instance variables!!
     This is necessary since Queues are often used as global objects with
     their contents initialized to zero by the system at the beginning of
     runtime. */
  inline Queue ();

  /* This actually initializes the Queue object, and must be explicitly called
     by the constructors for any classes that contain one of these. */
  inline void init ();

  /* Returns TRUE if the receiver only points at itself. */
  inline BooleanVar isEmpty ();

  /* Places item as the LAST object on the receiver's list. */
  inline void insert (Queue* item);

  /* Places item as the FIRST object on the receiver's list. */
  inline void push (Queue* item);

  /* Removes the first object pointed to by the receiver.  If the receiver
     is empty, return NULL.  The returned object points at itself. */
  inline Queue* wipe ();

  /* Returns the object in the receiver's list after item.  Returns NULL if
     that object would be the receiver itself.  This does not remove the
     result from the receiver's list. */
  inline Queue* next (Queue* item);

  /* Return nextP for the FOR_QUEUE macros to use */
  inline Queue* getNextP();

  /* Remove the receiver from whatever list it is on, and cause it to point at
     itself. */
  inline void dechain ();

  /* Replace the receiver with newItem in whatever list it is in.
     The receiver is left pointing at itself. */
  inline void replaceWith (Queue* newItem);

  /* Returns the number of objects in the receiver's list, not including the
     receiver. */
  Int32 count ();

  /* Returns TRUE if
		... thing1 <--> receiver <--> thing2
  */
  inline BooleanVar isSane ();

private:
	Queue* nextP;	   /* Next item in queue */
	Queue* prevP;	   /* Previous item in queue */
};


/*
	This steps over every item in the given Queue, passing it to the
	block as the type that the particular Queue is a head of--in a
	manner that is faster than saying P->next(Q) on each step.
	This implementation allows the iterand to be removed from the Queue.

	As an example, here is the motivating use in the garbage collector:

	BEGIN_FOR_QUEUE (&heap, ABufHead, p) {
		Heaper * obj = (Heaper*) (p + 1);
		... rest of Heap::freeAllUnmarked loop body ...
	} END_FOR_QUEUE;
*/

#define BEGIN_FOR_QUEUE(Q,TYPE,PTR)			\
	{	Queue * _LQ = (Q)->getNextP();		\
		while (_LQ != (Q)) {			\
			Queue * _NQ = _LQ->getNextP();	\
			TYPE * PTR = (TYPE*) _LQ;

#define END_FOR_QUEUE					\
			_LQ = _NQ;			\
		    }					\
	}


#include "queuesx.ixx"

#endif /* QX_HXX */
