/*
      (C) Copyright 1988, 89 by Xanadu Operating Company

****************************************************************
*							       *
*  The information contained herein is confidential,	       *
*  proprietary to Xanadu Operating Company, and considered     *
*  a trade secret as defined in section 499C of the penal code *
*  of the State of California.	Use of this information by     *
*  anyone other than authorized employees of Xanadu is granted *
*  only under a  written non-disclosure agreement, expressly   *
*  prescribing the scope and  manner of such use.	       *
*							       *
**************************************************************** */

#include "segx.hxx"

/*****	indentation for debugging output *****/

/*===============================================================
 |
 | 'margin' is used by 'printOn' to control its indentation.
 | If called with 'in' == 'R', it output blanks on 'oo' up to
 | the current indentation level, then increments the level.
 | If called with 'in' == 'L', it decrements the level.
 |
 | The 'printOn' of a Complex typically does 'margin (oo,R)' at
 | its beginning, then outputs a line, calls 'printOn' for each
 | of its constituent Complexes, and finally does 'margin (oo,L)' 
 | to reset the margin before exiting.
 |
 ================================================================*/

  void
margin(ostream& oo, Indentation in)
{
    static int lvl = 0;

    if (in == R) {
		for (int i=0; i<lvl; i++) {
			oo << "  ";
		}
		lvl++;
	} else {
		if (lvl > 0) {
			lvl--;
		}
    }
}

  int
indent(int count)
{
    static int lvl = 0;

	if (count < 0) {
		return lvl;
	} else {
		lvl = count;
		return 0;
	}
}

DEFINE_CLASS(SFile,Heaper);

SFile::
SFile (char* a1, Segment* a2)
{
	myFileName	= a1;
	myOverView	= a2;
	myIncluder	= NULL;
}

SFile::
SFile (char* a1, Segment* a2, SFile* a3)
{
	myFileName	= a1;
	myOverView	= a2;
	myIncluder	= a3;
}

void SFile::
printOn (ostream& oo)
{
	oo << myFileName;
	if (myIncluder) {
		oo << " in " << myIncluder; 
	}
}

BooleanVar SFile::
isIncludedIn (char * fileName)
{
/*
cout << "\n\nIII\n";
cout  << myFileName << " " << fileName << "\n";
*/
	if (!myFileName || !fileName) {
		return FALSE;
	}
	StringHeaper * fileString = new StringHeaper(fileName);
	StringHeaper * myFileString = new StringHeaper(myFileName);

	char * myFileNameTrimmed = myFileString->asBaseName();
	char * fileNameTrimmed = fileString->asBaseName();

	delete fileString;
	delete myFileString;

/*
cout  << myFileNameTrimmed << " " << fileNameTrimmed << "\n";
*/

	if (strcmp(fileNameTrimmed,myFileNameTrimmed) == 0) {
		return TRUE;
	}

	if (!myIncluder) {
		return FALSE;
	}
	return myIncluder->isIncludedIn(fileName);
}

DEFINE_CLASS(Segment,Heaper);

Segment::
Segment ()
{
	prv		= NULL;
	nxt		= NULL;
}

char * Segment::
pointer ()
{
	return firstToken()->pointer();
}

int Segment::
firstPos ()
{
	return firstToken()->firstPos();

} 
int Segment::
lastPos ()
{
	return lastToken()->lastPos();
}

int Segment::
firstLine ()
{
	return firstToken()->firstLine();
} 

SFile * Segment::
sFile ()
{
	return firstToken()->sFile();
}

char * Segment::
fileName ()
{
	return firstToken()->fileName();
}

Segment * Segment::
overView ()
{
	return firstToken()->overView();
}

void Segment::
copyOn (ostream& oo)
{
	char *	p = this->pointer();
	int		i = this->firstPos();	
	int		j = this->lastPos();	

	while (i <= j) {
		oo.put (p[i++]);
	}
}

void Segment::
copyAsLineOn (ostream& oo)
{
	Token * t = this->firstToken();
	Token * end = this->lastToken();

	for (; t; t=(Token*)t->next()) {
		if (!t->stringEq("\n")) {
			t->copyOn(oo);
		}
		if (t == end) {
			break;
		}
	}
}

void Segment::
join (Segment * s)
{
	nxt = s;
	if (s) {
		s->prv = this;
	}
}

Token * Segment::
gather (Segment * s)
{
	char *	this_ptr	= this->pointer();
	char *	s_ptr		= s ? s->pointer()	: this_ptr;
	int		this_start	= this->firstPos();
	int		s_start	= s ? s->firstPos()	: this_start;
	int		this_end	= this->lastPos();
	int		s_end		= s ? s->lastPos()	: this_end;

	if (   this_ptr != s_ptr
		|| s_start < this_start
		|| this_end	> s_end
	) {
		FERROR("Segment::gather");
	}
	return new Token (
		this_ptr,
		this_start,
		s_end,
		this->firstLine(),
		this->sFile()
	);
} 

BooleanVar Segment::
stringEq (char * s)
{
	char *	p = this->pointer();
	int		start = this->firstPos();
	int		len = 1 + this->lastPos() - start;	

	if (strlen(s) != len) {
		return FALSE;
	}
	return (strncmp(p+start,s,len) == 0) ? TRUE : FALSE;
}
 
BooleanVar Segment::
contains (Segment* s)
{
	if (!s) {
		return FALSE;
	}

	int start_container	= this->firstPos();
	int end_container	= this->lastPos();
	int start_contents	= s->firstPos();
	int end_contents	= s->lastPos();

	return (
		(start_contents >= start_container && end_contents <= end_container) 
		? TRUE
		: FALSE
	) ;
}


CmpList * Segment::
cmpList ()
{
	Token *		t   = this->lastToken();
	Token *		f   = this->firstToken();
	CmpList *	ret = NULL;

	for (; t; t=(Token*)t->previous()) {
		if (!t->isFiller()) {
			ret = new CmpList(t,ret);
		}
		if (t == f) {
			break;
		}
	}
	return ret;
}

BooleanVar Segment::
equivalentTo (Segment* seg)
{
	if (!seg) {
		return FALSE;
	}

	CmpList *	c1 = this->cmpList();
	CmpList *	c2 = seg->cmpList();

	BooleanVar	ret = c1->equivalentTo(c2);

/*	delete c1;
	delete c2;*/

	return ret;
}

BooleanVar Segment::
inFile (SFile * sf)
{
	return (strcmp(sf->fileName(),this->fileName()) == 0) ? TRUE : FALSE;
}

/*
int Segment::
textCmp (Segment* s)
{
	if (!s) {
		return this->firstToken() ? 1 : 0;
	}
	int ret = 0;

	IList * ilist1 = this->cmpList();
	IList * ilist2 = s->cmpList();
	IList * i1;
	IList * i2;

	for (i1=ilist1, i2=ilist2; i1 && i2; i1=i1->list(), i2=i2->list()) {
		if (ret = ((Token*)i1->seg()) -> textCmp((Token*)i2->seg()) ) {
			break;
		}
	}
	if (!ret) {
		ret = i1 ? 1 : i2 ? -1 : 0;
	}

	delete ilist1;
	delete ilist2;

	return ret;
}
*/

DEFINE_CLASS(Token,Segment);

Token::
Token (char* a ,int b ,int c ,int d ,SFile* e)
{
	ptr		= a;
	start	= b;
	end		= c;
	line	= d;
	file	= e;
}


Token::
Token (char* str, Segment* seg)
{
	ptr		= str;
	start	= 0;
	end		= strlen(str)-1;
	line	= seg ? seg->firstLine() : NULL;
	file	= seg ? seg->sFile() : NULL;
}

void  Token::
printOn (ostream& oo)
{
	margin(oo,R);
	oo << "<";
	this->copyOn(oo);
	oo << ">\n";
	margin(oo,L);
}

#define MAXLEN 30

void Token::
xref (ostream& oo, char* msg)
{
	int i = start;	
	int n = 0;

	oo
		<< this->fileName()
		<< ", line "
		<< line
		<< ": at '"
	;
	for (; n < MAXLEN && i <= end; n++) {
		oo.put (ptr[i++]);
	}

	oo << "' " ;
	if (msg) {
		oo << msg;
	}
	oo << " \n" ;
}

void Token::
dumpOn (ostream& oo)
{
	oo
		<< this
#ifdef _MSC_VER
		<< "start "	<<start	  << " "
		<< "end "	<<end			  << " "
		<< "line "	<<line		  << " "
#else
		<< "ptr "	<< hex<<(void*)ptr	<< " "
		<< "start "	<< dec<<start		<< " "
		<< "end "	<< dec<<end			<< " "
		<< "line "	<< dec<<line		<< " "
#endif /* _MSC_VER */
		<< "file "	<< this->fileName()	<< "\n"
		<< "prv "	<< this->previous()	
		<< "nxt "	<< this->next()	<< "\n"
	;
}

CmpList * Token::
cmpList ()
{
	return new CmpList(this,NULL);
}

BooleanVar Token::
equivalentTo (Token* t)
{
	if (!t) {
		return FALSE;
	}

	char *	tptr	= t->pointer();
	int	tstart	= t->firstPos();
	int	tend	= t->lastPos();
	int		tlen	= (tend - tstart) + 1;

	if (tlen != (end - start) + 1) {
		return FALSE;
	}
	if (strncmp(ptr+start,tptr+tstart,tlen) != 0) {
		return FALSE;
	}
	return TRUE;
}

char * Token::
pointer ()
{
	return ptr;
}

int Token::
firstPos ()
{
	return start;
}

int Token::
lastPos ()
{
	return end;
}

int Token::
firstLine ()
{
	return line;
}

SFile * Token::
sFile ()
{
	return file;
};

char * Token::
fileName ()
{
	return file ? file->fileName() : "no file";
};

char * Token::
fileExt ()
{
	char * fn = strdup(file->fileName());
	char * end;
	char * ext;
	char * ret;

	if (ext = strrchr(fn,'.')) { 
		if (end = strpbrk(ext,">\"")) {
			*end = NULL;
		}
		ret = strdup(ext);
	} else {
		ret = strdup("");
	}
	free(fn);
	return ret;
}

Segment * Token::
overView ()
{
	return file->overView();
};

BooleanVar Token::
isBlank()
{
	int i;

	for (i=start; i < end; i++) {
		if (!isspace(ptr[i])) {
			return FALSE;
		}
	}
	return TRUE;
}

char * Token::
asString()
{
	int			len = (end-start)+1;
	char *		str = new char[len+1];

	strncpy (str,ptr+start,len);
	str[len] = NULL;
	return str;
}

Token * Token::
nextTokenStr (char * s)
{
	Token * t;

	for (t=(Token*)this->next(); t; t=(Token*)t->next()) {
		if (t->stringEq(s)) {
			return t;
		}
	}
	return NULL;
}

Token * Token::
prevTokenStr (char * s)
{
	Token * t;

	for (t=(Token*)this->previous(); t; t=(Token*)t->previous()) {
		if (t->stringEq(s)) {
			return t;
		}
	}
	return NULL;
}

BooleanVar Token::
isIncludedInFile (char * fileName)
{
/*
cout << "\nIIIF\n" << this << file << fileName;
*/
	return (file && file->isIncludedIn(fileName));
}

DEFINE_CLASS(FillerToken,Token);

DEFINE_CLASS(Thread,Heaper);

void Thread::
xref (ostream& oo, char* msg)
{
	Segment * s;

	for (s=head; s; s=s->next()) {
		s->firstToken()->xref(oo,msg);;
		if (s == tail) {
			break;
		}
	}
}

void Thread::
printOn (ostream& oo)
{
	Segment * s;

	for (s=head; s; s=s->next()) {
		oo << s;
		if (s == tail) {
			break;
		}
	}
}

void Thread::
printOpaquelyOn (ostream& oo)
{
	Segment * s;
	Segment * lst = NULL;

	for (s=head; s; s=s->next()) {
		if (!lst || !lst->contains(s)) {
			oo << s;
			lst = s;
		}
		if (s == tail) {
			break;
		}
	}
}

void Thread::
add (Segment * s)
{
	if (!tail) {
		head = tail = s;
	} else {
		tail->join(s); 
		tail = s;
	}
}

void Thread::
insert (Segment * s)
{
	if (!tail) {
		tail = head = s;
		return;
	} 

	int			pos = s->firstPos();
	Segment *	p;

	for (p = tail; p &&  p->firstPos() >= pos; p = p->previous());

	if (p == tail) {
		tail->join(s);
		tail = s;
	} else 
	if (!p) {
		s->join(head);
		head = s;
	} else {
		s->join(p->next());
		p->join(s); 
	}
}

Segment * Thread::
containerOf (Segment* a1)
{
	int pos = a1->firstPos();
	Segment * s;

	for (s=head; s; s=s->next()) {
		if (s->firstPos() <= pos && s->lastPos() >= pos) {
			return s;
		}
		if (s == tail) {
			break;
		}
	}
	return NULL;
}

Thread * Thread::
contentsOf  (Segment* a1)
{
	int			start = a1->firstPos();
	int			end = a1->lastPos();
	Segment *	first = NULL;
	Segment *	last = NULL;
	Segment *	s;

	for (s=head; s; s=s->next()) {
		if (s->firstPos() >= start && s->lastPos() <= end) {
			if (!first) {
				first = s;
			}
			last = s;
		} else {
			if (first) {
				break;
			}
		}
		if (s == tail) {
			break;
		}
	}
	return new Thread (first,last);
}

Segment * Thread::
find (Segment* s)
{
	Segment * p;

	for (p=head; p; p = p->next()) {
		if ( ! p->equivalentTo(s) ) {
			return p;
		}
		if (p == tail) {
			break;
		}
	}
	return NULL;
}

Thread * Thread::
between (int start, int end)
{
	Segment *	first = NULL;
	Segment *	last = NULL;
	Segment *	s;

	for (s=head; s; s=s->next()) {
		if (s->firstPos() > start && s->lastPos() < end) {
			if (!first) {
				first = s;
			}
			last = s;
		} else {
			if (first) {
				break;
			}
		}
		if (s == tail) {
			break;
		}
	}
	return new Thread (first,last);
}

DEFINE_CLASS(IList,Heaper);

void IList::
printOn (ostream& oo)
{
				oo << iseg;
	if (ilist)	oo << ilist;
}

void IList::
append (IList * a1)
{
	if (!a1) {
		return;
	}
	if (ilist) {
		ilist->append(a1);
	} else {
		ilist = a1;
	}
}

void IList::
insertBefore (Segment* aseg, IList * alist)
{
	if (!aseg) {
		FERROR_VOID("IList::inertBefore - null insertion");
	} else

	if (!alist) {
		this->append(alist);
	} else 

	if (alist == ilist) {
		ilist = new IList(aseg,ilist);
	} else

	if (!ilist) {
		FERROR_VOID("IList::inertBefore - bad insertion point");
	} else {

		ilist->insertBefore(aseg,alist);
	}
}

Segment * IList::
nextSeg ()
{
	return ilist ? ilist->seg() : NULL;
}

BooleanVar IList::
equivalentTo (IList * ilist)
{
	IList * i1;
	IList * i2;

	for (i1=this, i2=ilist; i1 && i2; i1=i1->list(), i2=i2->list()) {
		if ( ! ((Token*)i1->seg()) -> equivalentTo((Token*)i2->seg()) ) {
			return FALSE;
		}
	}
	return (i1 || i2) ? FALSE : TRUE; 
}

DEFINE_CLASS(CmpList,IList);


#define MAXSTR 1000

char * CmpList::
asString ()
{
	CmpList *	clst = this;
	BooleanVar	prevId = FALSE;
	char *		str;
	char		c;
	char		buf[MAXSTR];
	int			tlen;
	int			len = 0;
	char *		ret;

	buf[0] = NULL;

	for (; clst; clst=(CmpList*)clst->list()) {
		str = clst->seg()->asString();
		tlen = strlen(str);
		len += tlen;
		if (len >= MAXSTR) {
			FERROR("String Too Long")
		}
		if (prevId && isalpha(str[0])) {
			strcat(buf," ");
		}
		strcat(buf,str);
		c = str[tlen-1];
		prevId = (isalpha(c) || c == '_') ? TRUE : FALSE;
		ret = strdup(buf);
		delete str;
	}
	return ret;
}

DEFINE_CLASS(Iterator,Heaper);

Iterator::
Iterator ()
{
	head = NULL;
	ptr	 = NULL;
}

Iterator::
Iterator (IList* a1)
{
	head = a1;
	ptr	 = a1;
}

Iterator::
Iterator (Segment* aSeg)
{
	head = ptr = new IList(aSeg,NULL);
}

void Iterator::
printOn (ostream& oo)
{
	IList * i;

	oo << "\n====\n";
	for (i=head; i; i=i->list()) {
		i->seg()->copyOn(oo);
		oo << "\n";
	}
	oo << "\n---\n";
}

void Iterator::
listOn (ostream& oo)
{
	IList * i;

	oo << "\n====\n";
	for (i=head; i; i=i->list()) {
		i->seg()->firstToken()->copyOn(oo);
		oo << "\n";
	}
	oo << "\n---\n";
}

Segment * Iterator::
next()
{
	Segment * ret = NULL; 

	if (ptr) {
		ret = ptr->seg();
		ptr = ptr->list();
	}
	return ret;
}

void Iterator::
append (Iterator * a1)
{
	if (!a1) {
		return;
	}
	if (head) {
		head->append(a1->ilist());
	} else {
		ptr = head = a1->ilist();
	}
}

void Iterator::
appendSafely (Iterator * a1)
{
	Segment * s;

	if (!a1) {
		return;
	}
	while (s = a1->next()) {
		this->appendSeg(s);
	}
	a1->reset();
}

void Iterator::
merge (Iterator * a1)
{
	Segment * s;

	if (!a1) {
		return;
	}
	while (s = a1->next()) {
		this->insertSeg(s);
	}
	a1->reset();
}

void Iterator::
appendIList (IList * a1)
{
	if (!a1) {
		return;
	}
	if (head) {
		head->append(a1);
	} else {
		ptr = head = a1;
	}
}

void Iterator::
appendSeg (Segment * a1)
{
	if (!a1) {
		return;
	}
	if (head) {
		head->append(new IList(a1,NULL));
	} else {
		ptr = head = new IList(a1,NULL);
	}
}

void Iterator::
appendSegIfUnique (Segment * a1)
{
	IList * i;

	for (i=head; i; i=i->list()) {
		if (i->seg() == a1) {
			return;
		}
	}
	this->appendSeg(a1);
}

void Iterator::
insertSeg (Segment * a1)
{
	if (!a1) {
		return;
	}
	if (!head) {
		ptr = head = new IList(a1,NULL);
		return;
	}

	IList *	lst;

	for (lst=head; lst; lst=lst->list()) {
		if (a1->firstPos() <= lst->seg()->firstPos()) {
			break;
		}
	}
	if (lst == head) {
		ptr = head = new IList(a1,head);
	} else

	if (lst) { 
		head->insertBefore(a1,lst); 

	} else {
		head->append(new IList(a1,NULL));
	}
}

void Iterator::
insertSegBefore (Segment * anew, IList* asite)
{
	IList * tmp;

	if (!anew) {
		FERROR_VOID("Iterator::insertSegBefore - insert of NULL");
	} else

	if (!asite) {
		this->appendSeg(anew);
	} else

	if (asite == head) {
		tmp = new IList(anew,head);
		ptr = head = tmp;
	} else {

		head->insertBefore(anew,asite);
	}
}

int Iterator::
count ()
{
	IList * i;
	int		ret = 0;

	for (i=head; i; i=i->list()) {
		ret++;
	}
	return ret;
}

void Iterator::
reset ()
{
	ptr = head;
}
