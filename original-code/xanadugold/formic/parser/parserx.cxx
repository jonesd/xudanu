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

#include "parserx.hxx"
#include "symtab.h"
#include "fhashx.hxx"

extern "C" {
	void 	add_filename(char*);
	void	lexinit(char*);
	int		yyparse();
}

DEFINE_CLASS(TDUnit,Heaper);

TDUnit::
TDUnit (char * n)
{
	myName = n;
	myNext = NULL;
	myPrev = NULL;
}

void TDUnit::
printOn (ostream& oo)
{
	oo << myName;
	oo << "\n";
}

TDUnit * TDUnit::
prev ()
{
	return myPrev;
}

void TDUnit::
add (TDUnit * t)
{
	myNext = t;
	myNext->setPrev(this);
}

void TDUnit::
setPrev (TDUnit* t)
{
	myPrev = t;
}

void TDUnit::
nullNext ()
{
	myNext = NULL;
}

DEFINE_CLASS(TDStack,Heaper);

TDStack::
TDStack ()
{
    head = NULL;
    tail = NULL;
    hashTableSize = 98947;
    hashTable = new TDUnit* [hashTableSize];
    memset ((char*)hashTable, 0, hashTableSize * sizeof(TDUnit*));
    overflowSize = 100;
    numOverflows = 0;
    hashOverflow = new TDUnit* [overflowSize];
}

void TDStack::
printOn (ostream& oo)
{
	TDUnit * ptr = head;

	oo << "TYPEDEF STACK\n";
	for (; ptr; ptr=ptr->next()) {
		oo << ptr;
	}
}

void TDStack::
add (char * n)
{
	unsigned long hash = fastHash(n) % hashTableSize;

	if (hashTable[hash]) {
	    if (hashTable[hash]->is(n)) {
		return;
	    }
	}

	TDUnit * nxt = new TDUnit(n);
	if (hashTable[hash]) {
	    if (numOverflows < overflowSize) {
		hashOverflow[numOverflows++] = nxt;
	    } else {
		cerr << "Too many hash collisions in TDStack::add\n";
		exit (1);
	    }
	} else {
	    hashTable[hash] = nxt;
	}

	if (!head) {
		head = tail = nxt;
	} else {
		/*TDUnit * ptr;
	        for (ptr=head; ptr->next(); ptr=ptr->next());
		ptr->add(nxt);*/
	        tail->add(nxt);
		tail = nxt;
	}
}

char TDStack::
find (char * n)
{
	TDUnit * ptr;
	
	ptr = hashTable[fastHash(n) % hashTableSize];
	if (ptr && ptr->is(n)) {
	    return 1;
	}
	for (int i = 0; i < numOverflows; i++) {
	    if (hashOverflow[i]->is(n)) {
		return 1;
	    }
	}
	/*for (ptr=head; ptr; ptr=ptr->next()) {
	    if (ptr->is(n)) {
			return 1;
		}
	}*/
	return 0;
}

void TDStack::
popScope ()
{
	TDUnit *	ptr = tail;
	TDUnit *	prev;
	BooleanVar	bra = FALSE;

	while (ptr) {
		if (ptr->is("{")) {
			bra = TRUE;
		}
		prev = ptr->prev();
		delete ptr;
		ptr = prev;
		if (bra) {
			break;
		}
	}
	if (ptr) {
		tail = ptr;
		ptr->nullNext();
	} else {
		head = tail = NULL;
	}
}

DEFINE_CLASS(LexUnit,Heaper);

LexUnit::
LexUnit (char * t, char * n)
{
	myName = n;
	myType = t;
	myNext = NULL;
}

void LexUnit::
printOn (ostream& oo)
{
	oo << myName;
	oo << " ";
	oo << myType;
	oo << "\n";
}

void LexUnit::
add (char * n, char * t)
{
	myNext = new LexUnit(n,t);
}

int LexUnit::
is (char * n)
{
	if (!n || !myName) {
		return (!n && !myName) ? 1 : 0;
	}
	return (strcmp(myName,n) == 0) ? 1 : 0;
}

char * LexUnit::
type ()
{
	return myType;
}

DEFINE_CLASS(LexList,Heaper);

LexList::
LexList ()
{
	head = NULL;
}

void LexList::
printOn (ostream& oo)
{
	LexUnit * ptr = head;

	for (; ptr; ptr=ptr->next()) {
		oo << ptr;
	}
}

void LexList::
add (char * n, char * t)
{
	LexUnit * ptr;

	if (!head) {
		head = new LexUnit(n,t);
	} else {
		for (ptr=head; ptr->next(); ptr=ptr->next());
		ptr->add(n,t);
	}
}

char * LexList::
find (char * n)
{
	LexUnit *	ptr;

	for (ptr=head; ptr; ptr=ptr->next()) {
		if (ptr->is(n)) {
			return ptr->type();
		}
	}
	return NULL;
}

DEFINE_CLASS(SymTab,Heaper);

SymTab::
SymTab ()
{
	myTDStack	= new TDStack(); 
	myLexList	= new LexList(); 
	myCScope	= NULL;
}

void SymTab::
printOn (ostream& oo)
{
	oo << "\n";
	if (myTDStack)	oo << myTDStack;
	if (myLexList)	oo << myLexList;
	if (myCScope)	oo << myCScope;
}

void SymTab::
lexAdd (char* key, char* instance)
{
	myLexList->add(key,instance);
}

void SymTab::
classScopeStart ()
{
	myCScope = new Iterator();
}

void SymTab::
insertMemDeclaration (DataMemberDeclaration * d)
{
	if (myCScope) {
		myCScope->appendSeg(d);
	}
}

void SymTab::
classScopeEnd ()
{
	delete myCScope;
	myCScope = NULL;
}

void SymTab::
tdEnter (char* tn)
{
	myTDStack->add(tn);
}

void SymTab::
tdPopScope ()
{
	myTDStack->popScope();
}

int SymTab::
tokenType (char * txt)
{
	if (myCScope) {

		Token *			t	= new Token(txt,NULL);
		IdentifierName *	id	= new IdentifierName (t);
		Segment *		seg;
		BooleanVar		found	= FALSE;

		while (seg = myCScope->next()) {
			if (((DataMemberDeclaration*)seg)->declares(id)) {
				found = TRUE;
				break;
			}
		}
		myCScope->reset();
		/*delete id;
		delete t;*/

		if (found) {
			return IDENTIFIERtoken;
		}
	}

	if (myTDStack->find(txt)) {
		return TYPEDEFnameToken;
	}

	char * s = myLexList->find(txt);
 
	if (s) {
		if (strcmp(s,"PROTECTION_TYPE") == 0) {
			return PROtypeToken;
		}
		if (strcmp(s,"STORAGE_CLASS") == 0) {
			return SCtypeToken;
		}
		if (strcmp(s,"FUNCTION_SPEC") == 0) {
			return FNspecToken;
		}
		if (strcmp(s,"TYPE_NAME") == 0) {
			return TYPEnameToken;
		}
		if (strcmp(s,"CLASS_ATTRIBUTE") == 0) {
			return CLASSattrToken;
		}
	
		if (strcmp(s,"PRE_INSTANCE_ATTRIBUTE") == 0) {
			return MEMattrToken;
		}
		if (strcmp(s,"POST_INSTANCE_ATTRIBUTE") == 0) {
			return MEMattrToken;
		}
		if (strcmp(s,"PRE_METHOD_ATTRIBUTE") == 0) {
			return MEMattrToken;
		}
		if (strcmp(s,"POST_METHOD_ATTRIBUTE") == 0) {
			return MEMattrToken;
		} 
		cerr
			<< "undefined lexical extension: "
			<< s
			<< "\n"
		;
	}

	return IDENTIFIERtoken;
}

DEFINE_CLASS(FileStack,Heaper);

FileStack::
FileStack ()
{
	myFile		= NULL;
	mySubStack	= NULL;
}

FileStack::
FileStack (SFile* sf, FileStack* fs)
{
	myFile		= sf;
	mySubStack	= fs;
}

void FileStack::
printOn (ostream& oo)
{
	oo << "\n";
	if (myFile)		oo << myFile;
	if (mySubStack)	oo << mySubStack;
}
	
void FileStack::
push (SFile * s)
{
	FileStack * tmp = new FileStack(myFile,mySubStack);
	
	myFile = s;
	mySubStack = tmp;
}

SFile * FileStack::
pop ()
{
	SFile *	retFile = myFile;

	if (!mySubStack) {
		myFile = NULL;
		return retFile;
	}

	myFile = mySubStack->peek();

	FileStack *	tmpStack = mySubStack;
	mySubStack = mySubStack->subStack();
	delete tmpStack;

	return retFile;
}

SFile * FileStack::
peek ()
{
	return myFile;
}

DEFINE_CLASS(LineTracker,Heaper);

void LineTracker::
printOn (ostream& oo)
{
	oo << "LineTracker\n";
	oo << myFirstFile << "\n";
	oo << myFile << "\n";
	oo << myLine << "\n";
	oo << myLevel << "\n";
	oo << "FileStack";
	oo << myFileStack;
	oo << "---\n\n";
}

LineTracker::
LineTracker (Program * prog)
{
	myProgram	= prog;
	myFirstFile	= NULL;
	myFile		= new SFile (strdup("\"(input)\""),prog);
	myLine		= 1;
	myLevel		= 0;
	myFileStack	= new FileStack();
}

void LineTracker::
nextFile (char* str) 
{
	char * delim = " \t\n";

	char * key	= 		  strtok(str,delim);
	char * line	= key	? strtok(NULL,delim) : NULL;
	char * file	= line	? strtok(NULL,delim) : NULL;
	char * lvl	= file	? strtok(NULL,delim) : NULL;

	if (strcmp(key,"#line")	!= 0 && strcmp(key,"#") != 0) {
		myLine++;
		return;
	}
	if (!line || !file) {
		cout << str;
		FERROR_VOID("bad #line");
	}

	myLevel = lvl ? atoi(lvl) : 0;

	switch (myLevel) {
	case 1:
		myFileStack->push(myFile);
		break;
	case 2:
		(void)myFileStack->pop();
		break;
	default:
		break;
	}

	myFile = new SFile (file,myProgram,myFileStack->peek());

	myFirstFile = myFirstFile ? myFirstFile : myFile;

	myLine = atoi(line);
}

void LineTracker::
nextLine ()
{
	myLine++;
}

SFile * LineTracker::
firstFile ()
{
	return myFirstFile ? myFirstFile : myFile;
}

SFile * LineTracker::
currentFile ()
{
	return myFile;
}

int LineTracker::
currentLine ()
{
	return myLine;
}

DEFINE_CLASS(XLintUnit,Heaper);

XLintUnit::
XLintUnit (Token * t)
{
	myToken = t;
	myNext = NULL;
}

void XLintUnit::
printOn (ostream& oo)
{
	oo << myToken;
}

XLintUnit * XLintUnit::
next ()
{
	return myNext;
}

void XLintUnit::
add (Token * t)
{
	myNext = new XLintUnit(t);
}

BooleanVar XLintUnit::
exceptionIs (char * str)
{
	char *		tokStr = myToken->asString();
	char *		p = strchr (tokStr,'"');
	BooleanVar	ret = (p && strncmp(p+1,str,strlen(str)) == 0)
					? TRUE : FALSE
				;
	delete tokStr;
	return ret;
}

Token * XLintUnit::
token ()
{
	return myToken;
}

DEFINE_CLASS(XLintList,Heaper);

XLintList::
XLintList ()
{
	head = NULL;
}

void XLintList::
printOn (ostream& oo)
{
	XLintUnit * ptr = head;

	for (; ptr; ptr=ptr->next()) {
		oo << ptr;
	}
}

void XLintList::
add (Token * t)
{
	XLintUnit * ptr;

	if (!head) {
		head = new XLintUnit(t);
	} else {
		for (ptr=head; ptr->next(); ptr=ptr->next());
		ptr->add(t);
	}
}

Iterator * XLintList::
findAll (char * str)
{
	Iterator *	ret = new Iterator();
	XLintUnit * ptr = head;

	for (; ptr; ptr=ptr->next()) {
		if (ptr->exceptionIs(str)) { 
			ret->appendSeg(ptr->token());
		}
	}
	return ret;
}

DEFINE_CLASS(Parser,Heaper);

Parser::
Parser ()
{
	myProgram		= new Program();
	mySymTab		= new SymTab(); 
	myLineTracker	= new LineTracker(myProgram); 
	myXLintList		= new XLintList(); 
}

void Parser::
printOn (ostream& oo)
{
	oo << "\n";
	if (myProgram)		oo << myProgram;
//	if (mySymTab)		oo << mySymTab;
//	if (myLineTracker)	oo << myLineTracker;
//	if (myXLintList)	oo << myXLintList;
}


void Parser::
copyCodeOn (ostream& oo)
{
	if (!myProgram) {
		return;
	}

	Thread *		thr	= myProgram->externalDefinitions();
	Segment *		s	= thr->first();
	Segment *		end	= thr->last();

	for (; s; s = (s==end) ? NULL : s->next()) { 
		s->copyOn(oo);
		oo << "\n";
	}
}

void Parser::
parse (char * s)
{
	extern Program *		ProgramPtr;
	extern SymTab *			SymbolTable;
	extern LineTracker *	LineTrack;
	extern XLintList *		XLintTrack;

	lexinit(s);

	ProgramPtr	= myProgram;
	SymbolTable	= mySymTab;
	LineTrack	= myLineTracker;
	XLintTrack	= myXLintList;

	if (yyparse() != 0) {
		cerr << "parse failed\n";
	}
}

Program * Parser::
program()
{
	return myProgram;
}

SymTab * Parser::
symTab()
{
	return mySymTab;
}

LineTracker * Parser::
lineTracker()
{
	return myLineTracker;
}

XLintList * Parser::
xlintList()
{
	return myXLintList;
}
