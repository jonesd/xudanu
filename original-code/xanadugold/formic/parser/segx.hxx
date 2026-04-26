/*
      (C) Copyright 1988, 89 by Xanadu Operating Company

****************************************************************
*                                                              *
*  The information contained herein is confidential,           *
*  proprietary to Xanadu Operating Company, and considered     *
*  a trade secret as defined in section 499C of the penal code *
*  of the State of California.  Use of this information by     *
*  anyone other than authorized employees of Xanadu is granted *
*  only under a  written non-disclosure agreement, expressly   *
*  prescribing the scope and  manner of such use.              *
*                                                              *
**************************************************************** */

#ifndef SEGMENT_HXX
#define SEGMENT_HXX

#include "tofux.hxx"
#include "strobjx.hxx"
#include <ctype.h>

/***** used by 'printOn' to set margins *****/

enum Indentation {R,L};
void margin (ostream&, Indentation);

class SFile;
class Segment;
class Token;
class FillerToken;
class Thread;
class Vehicle;
class IList;
class CmpList;
class Iterator;

CLASS(SFile,Heaper) {
  public:
	SFile (char*,Segment*);
	SFile (char*,Segment*,SFile*);

	void 	printOn (ostream& oo);

	char *		fileName ()	{ return myFileName; }
	Segment *	overView ()	{ return myOverView; }
	SFile *		includer ()	{ return myIncluder; }
	BooleanVar	isIncludedIn (char *);

  private:
	char *		myFileName;
	Segment *	myOverView;
	SFile *		myIncluder;
};

CLASS(Segment,Heaper) {
  public:
	Segment();

	void		join (Segment*);
	inline Segment *	next () { return nxt; }
	inline Segment *	previous () { return prv; }
	Token *		gather (Segment*);
	BooleanVar	stringEq (char *);
	BooleanVar	contains (Segment *);
	BooleanVar	equivalentTo (Segment *);
	BooleanVar	inFile (SFile *);

	virtual void	copyOn (ostream& oo);
	virtual void	copyAsLineOn (ostream& oo);

	virtual char *    pointer ();
	virtual int       firstPos ();
	virtual int       lastPos ();
	virtual int       firstLine ();
	virtual SFile *   sFile ();
	virtual char *	  fileName ();
	virtual Segment * overView ();

	virtual Token *		firstToken ()			= 0;
	virtual Token *		lastToken ()			= 0;
	virtual char *	  	asString ()			= 0;
	virtual CmpList *	cmpList ();

  private:
	Segment *	prv;
	Segment *	nxt;
};

CLASS(Token,Segment) {
  public:
	Token (char*,int,int,int,SFile*);
	Token (char*,Segment*);

	virtual void 		printOn (ostream& oo);
	virtual void		xref (ostream& oo, char*);
	virtual void		dumpOn (ostream& oo);

	virtual char *		pointer ();
	virtual int			firstPos ();
	virtual int			lastPos ();
	virtual int			firstLine ();
	virtual SFile *		sFile ();
	virtual char *		fileName ();
	virtual char *		fileExt ();
	virtual Segment *	overView ();
	virtual BooleanVar	isBlank();
	virtual BooleanVar	isFiller()	{ return FALSE; }

	Token *		firstToken ()	{ return this; }
	Token *		lastToken ()	{ return this; }
	CmpList *	cmpList ();
	BooleanVar	equivalentTo (Token*);
	Token *		nextTokenStr (char*);
	Token *		prevTokenStr (char*);
	char *		asString();
	BooleanVar	isIncludedInFile (char *);

  private:
	char *		ptr;
	int			start;
	int			end;
	int			line;
	SFile *		file;
};

CLASS(FillerToken,Token) {
  public:
	FillerToken (char* a1,int a2,int a3,int a4,SFile* a5)
		: Token (a1,a2,a3,a4,a5) {}

	FillerToken (char* a1,Segment* a2)
		: Token (a1,a2) {}

	BooleanVar	isFiller()	{ return TRUE; }
};

CLASS(Thread,Heaper) {
  public:
	Thread ()						{ head = tail = NULL; }
	Thread (Segment* f, Segment* l)	{ head = f; tail = l; }

	void printOn (ostream&);
	void printOpaquelyOn (ostream&);
	void xref (ostream& oo, char*);

	void add (Segment *);
	void insert (Segment *);

	Segment * first ()	{ return head; } 
	Segment * last ()	{ return tail; } 

	Segment * containerOf (Segment*);
	Thread *  contentsOf (Segment*);
	Thread *  between (int,int);
	Segment * find (Segment *);

  private:
	Segment * head;
	Segment * tail;
};

CLASS(Vehicle,Heaper) { 
  public:
	Vehicle 
		(void * a, void * b)	{ p_1 = a; p_2 = b; }

	void *	p1()	{ return p_1; }
	void *	p2()	{ return p_2; }

  private:
	void *	p_1;
	void *	p_2;
};

CLASS(IList,Heaper) {
  public:
	inline IList (Segment*a1,IList*a2)
	{
	    iseg	= a1;
	    ilist	= a2;
	}

	~IList () { if (ilist) delete ilist; }

	void		printOn (ostream&);
	void		append (IList*);
	void		insertBefore (Segment*,IList*);
	IList*		list ()	{ return ilist; }
	Segment*	seg ()	{ return iseg; }
	Segment*	nextSeg ();
	BooleanVar	equivalentTo (IList *);

  private:
	Segment*	iseg;
	IList*		ilist;		/* opt */
};

CLASS(CmpList,IList) {
  public:
	CmpList
		(Segment* s,CmpList* c) : IList(s,c) {}

	char *		asString ();
};

CLASS(Iterator,Heaper) {
  CONCRETE(Iterator)
  public:
	Iterator ();
	Iterator (IList*);
	Iterator (Segment*);

	void	printOn (ostream&);
	void	listOn (ostream&);

	IList *		ilist ()	{ return head; }
	BooleanVar	isEmpty ()	{ return head ? FALSE : TRUE; }
	void		append (Iterator*);
	void		appendSafely (Iterator*);
	void		merge (Iterator*);
	void		appendIList (IList*);
	void		appendSeg (Segment*);
	void		appendSegIfUnique (Segment*);
	void		insertSeg (Segment*);
	void		insertSegBefore (Segment*,IList*);
	int			count();
	Segment *	next ();
	void		reset ();

  private:
	IList * head;
	IList * ptr;
};

#endif /* SEGMENT_HXX */
