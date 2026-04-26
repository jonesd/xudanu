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

#ifndef PARSER_HXX
#define PARSER_HXX

#include "syntaxx.hxx"

CLASS(TDUnit,Heaper) {
  public:
	TDUnit (char *);

	LEAF void		printOn (ostream&);
	inline TDUnit *	next () { return myNext; }
	LEAF TDUnit *	prev ();
	LEAF void		add (TDUnit*);
	inline int		is (char*n)
	{
	    if (!n || !myName) {
		return !n && !myName;
	    } else {
		return strcmp(myName,n) == 0;
	    }
	}
	LEAF void		nullNext ();

  private:
	char *		myName;
	TDUnit *	myNext;
	TDUnit *	myPrev;

	void		setPrev (TDUnit*);
};

CLASS(TDStack,Heaper) {
  public:
	TDStack ();

	LEAF void	printOn (ostream&);
	LEAF void	add (char*);
	LEAF char	find (char*);
	LEAF void	popScope ();

  private:
	TDUnit * head;
	TDUnit * tail;
	int	  hashTableSize;
	TDUnit ** hashTable;
	int	  overflowSize;
	int	  numOverflows;
	TDUnit ** hashOverflow;
};

CLASS(LexUnit,Heaper) {
  public:
	LexUnit (char*,char*);

	LEAF void		printOn (ostream&);
	inline LexUnit *	next () {return myNext;}
	LEAF void		add (char*,char*);
	LEAF int		is (char*);
	LEAF char *		type ();

  private:
	char *		myName;
	char * 		myType;
	LexUnit *	myNext;
};

CLASS(LexList,Heaper) {
  public:
	LexList ();

	LEAF void	printOn (ostream&);
	LEAF void	add (char*,char*);
	LEAF char *	find (char*);

  private:
	LexUnit * head;
};

CLASS(SymTab,Heaper) {
  public:
	SymTab ();

	LEAF void	printOn (ostream&);

	LEAF void	lexAdd (char*,char*); 

	LEAF void	classScopeStart ();
	LEAF void	insertMemDeclaration (DataMemberDeclaration*);
	LEAF void	classScopeEnd ();

	LEAF void	tdEnter (char*);
	LEAF void	tdPopScope ();

	LEAF int	tokenType (char*);

  private:
	TDStack *	myTDStack;
	LexList *	myLexList;
	Iterator *	myCScope;
};

/*===============================================================
	The FileStack is used by the LineTracker (see below)
	to keep track of nested include files
================================================================*/

CLASS(FileStack,Heaper) {
  public:
	FileStack ();

	void printOn (ostream&);
	
	void	push (SFile*);
	SFile *	pop ();
	SFile *	peek ();

  private:
	SFile *		myFile;
	FileStack *	mySubStack;

	FileStack (SFile*,FileStack*);

	FileStack * subStack() { return mySubStack; }
};

/*===============================================================
	The LineTracker extracts and dispenses information from
	'#line' directives in preprocessor output.
================================================================*/

CLASS(LineTracker,Heaper) { 
  public:
	LineTracker (Program*);

	void	printOn (ostream&);
	void	nextFile (char*); 
	void	nextLine ();

	SFile *	firstFile ();
	SFile *	currentFile ();
	int		currentLine ();

  private:
	Program *	myProgram;
	SFile *		myFirstFile;
	SFile *		myFile;
	int			myLine;  // next line number to be assigned
	int			myLevel;
	FileStack *	myFileStack;
};

/*===============================================================
	The XLintUnits control the enabling and disabling of
	Xlint exception checking.
================================================================*/

CLASS(XLintUnit,Heaper) {
  public:
	XLintUnit (Token*);

	void		printOn (ostream&);
	XLintUnit *	next ();
	void		add (Token*);
	BooleanVar	exceptionIs (char *);
	Token *		token ();
	

  private:
	Token *		myToken;
	XLintUnit *	myNext;
};

CLASS(XLintList,Heaper) {
  public:
	XLintList ();

	LEAF void		printOn (ostream&);
	LEAF void		add (Token*);
	LEAF Iterator *	findAll (char *);

  private:
	XLintUnit * head;
};

/*===============================================================
	The Parser object reads and parses X++ programs
================================================================*/

CLASS(Parser,Heaper) {
  public:
	Parser ();

	LEAF void			printOn (ostream&);
	LEAF void			copyCodeOn (ostream&);
	LEAF void			parse (char*); 
	LEAF Program *		program ();
	LEAF SymTab *		symTab ();
	LEAF LineTracker *	lineTracker ();
	LEAF XLintList *	xlintList ();

  private:
	Program *		myProgram;
	SymTab *		mySymTab;
	LineTracker *	myLineTracker;
	XLintList *		myXLintList;
};

#endif /*PARSER_HXX*/
