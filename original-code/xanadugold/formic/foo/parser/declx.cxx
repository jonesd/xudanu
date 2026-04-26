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
*                                                              *
**************************************************************** */

#include "syntaxx.hxx"

DEFINE_CLASS(Complex,Segment);

Program * Complex::
progPtr ()
{
	return (Program*)this->overView();
}

FillerToken * Complex::
fetchComment ()
{
	Iterator *	comm	= new Iterator();
	Token *		tok		= (Token*) this->firstToken()->previous();
	Token *		first	= NULL;
	int			start;
	int			end;

	for (; tok; tok = (Token*)tok->previous()) {
		if (!tok->isFiller()) {
			break;
		}
		if (!tok->isBlank()) {
			comm->appendSeg(tok);
			break;
		}
	}

	while (tok = (Token*)comm->next()) {
		if (!first) {
			first = tok;
			start = tok->firstPos();
		}
		end = tok->lastPos();
	}
	if (!first) {
		return NULL;
	}
	if (end-start < 4) {		// minimum non-empty comment
		return NULL;
	}

	char * ptr = first->pointer();
	char * p1 = ptr+start;
	char * p2 = ptr+start+1;
	char * p3 = ptr+start+2;

	if (*p1=='/' && (*p2=='*' || *p2=='/')) {
		start+=2;
		while (isspace(*(ptr+start)) && start < end) {
			start++;
		}
	}
	if (end-start < 3) {		// 'C' comment with end marker
		return NULL;
	}

	p1 = ptr+end;
	p2 = ptr+end-1;
	p3 = ptr+end-2;

	if (*p1=='/' && *p2=='*') {
		end -= 2;
		if (end > start && *p3=='\n') {
			end--;
		}
	}

	return new FillerToken (
		ptr,
		start,
		end,
		first->firstLine(),
		first->sFile()
	);
}

char * Complex::
asString ()
{
	return this->cmpList()->asString();
}

Iterator * Complex::
allMyExpressions()
{
	Program *	pgm	= this->progPtr();
	Thread *	exs	= pgm->exprThread()->contentsOf(this);
	Segment *	seg	= exs->first();
	Segment *	end	= exs->last();
	Iterator *	ret = new Iterator();

	for (; seg; seg = (seg==end)?NULL:seg->next()) { 
		ret->appendSeg(seg);
	}
	delete exs;
	return ret;
}

DEFINE_CLASS(NewDeclarator,Complex);

DEFINE_CLASS(MetaDeclaration,Complex);

BooleanVar MetaDeclaration::
declares (Name*)
{
	return FALSE;
}

TypeName * MetaDeclaration::
typeOf (Name*)
{
	return NULL;
}

BooleanVar MetaDeclaration::
isTypedefOf (Name*)
{
	return FALSE;
}

DEFINE_CLASS(Initializer,Complex);

EQUALS * Initializer::
equals()
{
	cerr << "Not an '=' initializer\n" << this;
	return NULL;
}

Expression * Initializer::
expression()
{
	cerr << "Not an expression initializer\n" << this;
	return NULL;
}

DEFINE_CLASS(InitializerList,Complex);

Initializer * InitializerList::
makeInitializerWith(EQUALS*)
{
	return NULL;
}

DEFINE_CLASS(StatementList,Complex);

DEFINE_CLASS(EnumList,Complex);

DEFINE_CLASS(Enumerator,EnumList);

DEFINE_CLASS(DeclaratorList,Complex);

DEFINE_CLASS(Declarator,Complex);

AbstractDeclarator * Declarator::
returnAbstract ()
{
	return this->abstract();
}

FunctionDeclarator * Declarator::
functionDeclarator ()
{
	return NULL;
}

Declarator* Declarator::
variableDeclarator ()
{
	return this;
}

BooleanVar Declarator::
declaresFunction ()
{
	return FALSE;
}

BooleanVar Declarator::
declaresVariable ()
{
	return TRUE;
}

int Declarator::
arity ()
{
	return 0;
}

DEFINE_CLASS(PtrOperator,Complex);

DEFINE_CLASS(ArgumentDeclarationList,Complex);

ArgumentDeclarationList::
ArgumentDeclarationList()
{
	myArgList = NULL;
}

Iterator * ArgumentDeclarationList::
arguments ()
{
	if (myArgList) {
		return new Iterator(myArgList);
	}

	Iterator *				ret = new Iterator();
	ArgDeclarationList *	arg_decl_list = this->argDeclarationList ();
	ArgumentDeclaration *	arg;

	if (arg_decl_list) {

		Iterator *	args = arg_decl_list->arguments();
		BooleanVar	out  = FALSE;

		while (arg = (ArgumentDeclaration*)args->next()) {
			if (arg->isOutMarker()) {
				out = TRUE;
				continue;
			}
			if (out) {
				arg->setOut();
			}
											// @@@ Exclude void
			if (!arg->stringEq("void")) {
				ret->appendSeg(arg);
			}
		}
	}
	
	Token * e;

	if (e = this->ellipsis()) {
		arg = new AbstractArgumentDeclaration (
				new DeclSpecifiers (
					NULL,
					new ActualSimpleTypeName (e)
				),
				NULL
		);
		ret->appendSeg(arg);
	}

	myArgList = ret->ilist();
	return ret;
}

char * ArgumentDeclarationList::
signature ()
{
	StringHeaper *			bufP = new StringHeaper();
	Iterator *				args = this->arguments();
	ArgumentDeclaration *	a;

	while (a=(ArgumentDeclaration*)args->next()) {
		bufP->strCat(a->type()->signature());
	}
	delete args;

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
} 

DEFINE_CLASS(ArgDeclarationList,MetaDeclaration);

DEFINE_CLASS(ArgumentDeclaration,ArgDeclarationList);

ArgumentDeclaration::
ArgumentDeclaration ()
{
	myOut = FALSE;
}

ArgumentDeclaration * ArgumentDeclaration::
initializeWith (Initializer*)
{
	cerr << "Already initialized\n" << this;
	return NULL;
}

Expression * ArgumentDeclaration::
defaultInit ()
{
	return NULL;
}

BooleanVar ArgumentDeclaration::
declares (Name *)
{
	return FALSE;
}

BooleanVar ArgumentDeclaration::
isOutMarker()
{
	return FALSE;
}

Iterator * ArgumentDeclaration::
arguments ()
{
	return new Iterator(new IList(this,NULL));
}

BooleanVar ArgumentDeclaration::
isOut()
{
	return myOut;
}

void ArgumentDeclaration::
setOut()
{
	myOut = TRUE;
}

BooleanVar ArgumentDeclaration::
typeEquivalent (Expression* ex)
{
	if (!ex) {
		return FALSE;
	}

	if (this->stringEq("...")) {
		return TRUE;
	}

	TypeName * typ1 = this->type();
	TypeName * typ2 = ex->type();
	if (!BOOL_EQ(typ1,typ2)) {
		return FALSE;
	}
	if (!typ1) {
		return TRUE;
	}

	typ1 = typ1->ultimateType();
	typ2 = typ2->ultimateType();

	if (typ1->isPointer() && ex->stringEq("0")) {
		return TRUE;
	}
	if (typ2->typeEquivalent(typ1) || typ2->fetchConversionTo(typ1)) {
		return TRUE;
	}

	ClassSpecifier *	class1 = typ1->classOfType(); 
	ClassSpecifier *	class2 = typ2->classOfType(); 
	ClassName *			className1 = class1 ? class1->className() : NULL;

	if (	class2
		&&	className1
		&&	class2->classIsKindOf(className1->lastToken())
	) {
		return TRUE;
	 }

	return FALSE;
}

DEFINE_CLASS(AbstractDeclarator,Complex);

Declarator * AbstractDeclarator::
concretizeWith (Declarator*)
{
	return NULL;
}

BooleanVar AbstractDeclarator::
isPrefixable ()
{
	return FALSE;
}

BooleanVar AbstractDeclarator::
isPointer ()
{
	return FALSE;
}

AbstractDeclarator * AbstractDeclarator::
resolved ()
{
	return this;
}

AbstractDeclarator * AbstractDeclarator::
dereferenced ()
{
	cout << "cannot dereference ";
	cout << "\n\n";
	this->printOn(cout);
	cout << "\n\n";

/*												punt error msg
	cerr << "cannot dereference\n" << this;
*/
	return NULL;
}

AbstractDeclarator * AbstractDeclarator::
prefixWith (AbstractDeclarator*)
{
	cerr << "Not prefixable\n" << this;
	return NULL;
}

AbstractDeclarator * AbstractDeclarator::
applyIndirection (AbstractDeclarator* a)
{
	return (a) ? this->prefixWith(a) : this;
}

DEFINE_CLASS(AttributeParamList,Complex);

DEFINE_CLASS(MemberList,Complex);

DEFINE_CLASS(MemberDeclaration,MetaDeclaration);

Iterator * MemberDeclaration::
funcDeclarations ()
{
	return new Iterator();
}

Iterator * MemberDeclaration::
varDeclarations ()
{
	return new Iterator();
}

DEFINE_CLASS(MemberDeclaratorList,Complex);

DEFINE_CLASS(MemberDeclarator,MemberDeclaratorList);

Declarator *  MemberDeclarator::
declOf (Name *) 
{
	return NULL;
}

BooleanVar MemberDeclarator::
declares (Name*) 
{
	return FALSE;
} 

MemberDeclaratorList * MemberDeclarator::
fetchList ()
{
	return NULL;
}

MemberDeclarator * MemberDeclarator::
getDecl ()
{
	return this;
}

DEFINE_CLASS(BaseList,Complex);

DEFINE_CLASS(MemInitializerList,Complex);

MemInitializerList * MemInitializerList::
chain (COMMA*,MemInitializer*)
{
	cerr << "Not chainable\n" << this;
	return NULL;
}

DEFINE_CLASS(MemInitializer,MemInitializerList);

DEFINE_CLASS(Statement,StatementList);

StatementList * Statement::
prepend (StatementList * a1)
{
	return new ActualStatementList (a1,this);
}

Iterator * Statement::
subStatements ()
{
	Thread *	t		= this->progPtr()->stmtThread()->contentsOf(this);
	Segment *	start	= t->first();
	Segment *	end		= t->last();
	Segment *	s;
	Segment *	last 	= NULL;
	Iterator *	ret 	= new Iterator();

	for (s=start; s; s = (s==end) ? NULL : s->next() ) { 
		if ((s==this) || last && last->contains(s)) {
			continue;
		}
		ret->appendSeg(s);
		last = s;
	}
	return ret;
}


DEFINE_CLASS(LabeledStatement,Statement);

DEFINE_CLASS(SelectionStatement,Statement);

DEFINE_CLASS(IterationStatement,Statement);

DEFINE_CLASS(ForInitStatement,Statement);

DEFINE_CLASS(JumpStatement,Statement);

DEFINE_CLASS(CvQualifierList,Complex);

CvQualifierList::
CvQualifierList (CvQualifier* a1,CvQualifierList* a2) 
{
	myQual	= a1;
	myList	= a2;
}

void CvQualifierList::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "CvQualifierList\n";
				oo << myQual;
	if (myList)	oo << myList;
	margin (oo,L);
}

Token * CvQualifierList::
firstToken ()
{
	return myQual->firstToken();
}

Token * CvQualifierList::
lastToken ()
{
	return LAST_FOR_2(myList,myQual);
}

BooleanVar CvQualifierList::
hasConst ()
{
	Token t = Token ("const",NULL);
	if (myQual->equivalentTo(&t)) {
		return TRUE;
	}
	if (myList) {
		return myList->hasConst();
	}
	return FALSE;
}

BooleanVar CvQualifierList::
hasVolatile ()
{
	Token t = Token ("volatile",NULL);
	if (myQual->equivalentTo(&t)) {
		return TRUE;
	}
	if (myList) {
		return myList->hasVolatile();
	}
	return FALSE;
}

DEFINE_CLASS(TypeSpecifierList,Complex);

TypeSpecifierList::
TypeSpecifierList (TypeSpecifier* a1,TypeSpecifierList* a2) 
{
	mySpec	= a1;
	myList	= a2;
}

void TypeSpecifierList::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "TypeSpecifierList\n";
				oo << mySpec;
	if (myList)	oo << myList;
	margin (oo,L);
}

void TypeSpecifierList::
copyOn (ostream& oo)
{
	mySpec->copyOn(oo);
	if (myList) {
		oo << " ";
		myList->copyOn(oo);
	}
}

Token * TypeSpecifierList::
firstToken ()
{
    return mySpec->firstToken();
}

Token * TypeSpecifierList::
lastToken ()
{
    return LAST_FOR_2(myList,mySpec);
}

TypeSpecifier * TypeSpecifierList::
typeSpecifier()
{
	return mySpec;
}

TypeSpecifierList * TypeSpecifierList::
typeSpecifierList()
{
	return myList;
}

CmpList * TypeSpecifierList::
cmpList ()
{
	CmpList * list = mySpec->cmpList(); 
	if (myList) list->append(myList->cmpList());
	return list;
}

void TypeSpecifierList::
chain (TypeSpecifierList * tsl)
{
	if (!tsl) {
		return;
	}
	if (myList) {
		myList->chain(tsl);
	} else {
		myList = tsl;
	}
}

DeclSpecifiers * TypeSpecifierList::
makeDeclSpecifiers ()
{
    DeclSpecifiers *    d = NULL;
    TypeSpecifierList*  t = this;
    TypeSpecifier*		s;

	do {
    	s = t->typeSpecifier();
        d = new DeclSpecifiers (d,s);
    } while (t = t->typeSpecifierList());
    return d;
}

TypeSpecifierList * TypeSpecifierList::
final ()
{
	if (myList) {
		return myList->final();
	}
	return this;
}

TypeSpecifierList * TypeSpecifierList::
replaceFinalWith (TypeSpecifierList * tsl)
{
	if (myList) {
		return new TypeSpecifierList (
			mySpec,
			myList->replaceFinalWith(tsl)
		);
	}
	return tsl;
}

BooleanVar TypeSpecifierList::
hasSpec (Token* t)
{
	if (!t) {
		return FALSE;
	} 
	if (mySpec->equivalentTo(t)) {
		return TRUE;
	}
	if (myList) {
		return myList->hasSpec(t);
	}
	return FALSE;
}

char * TypeSpecifierList::
signature ()
{
	StringHeaper *  bufP = new StringHeaper(20,20);

	BooleanVar void_b		= FALSE;
	BooleanVar char_b		= FALSE;
	BooleanVar short_b		= FALSE;
	BooleanVar int_b		= FALSE;
	BooleanVar long_b		= FALSE;
	BooleanVar float_b		= FALSE;
	BooleanVar double_b		= FALSE;
	BooleanVar l_double_b	= FALSE;
	BooleanVar ellipsis_b	= FALSE;
	BooleanVar unsigned_b	= FALSE;
	BooleanVar const_b		= FALSE;
	BooleanVar volatile_b	= FALSE;
	BooleanVar signed_b		= FALSE;

	TypeSpecifierList *		tsl = this;
	TypeSpecifier *			ts;

	for (; tsl; tsl = tsl->typeSpecifierList()) {

		ts = tsl->typeSpecifier();

		if (ts->stringEq("void"))		void_b		= TRUE;	
		if (ts->stringEq("char"))		char_b		= TRUE;	
		if (ts->stringEq("short"))		short_b		= TRUE;	
		if (ts->stringEq("int"))		int_b		= TRUE;	
		if (ts->stringEq("long"))		long_b		= TRUE;	
		if (ts->stringEq("float"))		float_b		= TRUE;	
		if (ts->stringEq("double"))		double_b	= TRUE;	
		if (ts->stringEq("..."))		ellipsis_b	= TRUE;	
		if (ts->stringEq("const"))		const_b		= TRUE;	
		if (ts->stringEq("signed"))		signed_b	= TRUE;	
		if (ts->stringEq("unsigned"))	unsigned_b	= TRUE;	
		if (ts->stringEq("volatile"))	volatile_b	= TRUE;	
	}
	
	if (const_b)	{ bufP->strCat("C"); }
	if (signed_b)	{ bufP->strCat("S"); }
	if (unsigned_b)	{ bufP->strCat("U"); }
	if (volatile_b)	{ bufP->strCat("V"); }

	if (long_b && double_b) {
		l_double_b	= TRUE;
		long_b		= FALSE;
		double_b	= FALSE;
	}

	if (void_b)		{ bufP->strCat("v"); } else
	if (char_b)		{ bufP->strCat("c"); } else
	if (short_b)	{ bufP->strCat("s"); } else
	if (int_b)		{ bufP->strCat("i"); } else
	if (long_b)		{ bufP->strCat("l"); } else
	if (float_b)	{ bufP->strCat("f"); } else
	if (double_b)	{ bufP->strCat("d"); } else
	if (l_double_b)	{ bufP->strCat("r"); } else
	if (ellipsis_b)	{ bufP->strCat("e"); } else
	if (unsigned_b)	{ bufP->strCat("i"); } else
					{
						char * str = ts->asString();
						bufP->intCat(strlen(str));
						bufP->strCat(str);
					}

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
}

TypeSpecifierList * TypeSpecifierList::
resolved ()
{
	TypeSpecifierList * tsl = this;

	if (mySpec->isCv()) {
		tsl = myList;
	}
	if (tsl->isIntType()) {
		tsl = new TypeSpecifierList (
			new ActualSimpleTypeName (new Token ("int", this->firstToken())),
			NULL
		);
	}
	return tsl;
}

char * Int_types[] = {
	"int",
	"long",
	"short",
	"float",
	"double",
	"char",
	"unsigned",
	NULL
};

#define NAME_OF_TYPE_OF_ENUM "long"


BooleanVar TypeSpecifierList::
isIntType ()
{
	int i;
	for (i=0; Int_types[i]; i++) {
		if (mySpec->stringEq(Int_types[i])) {
			break;
		}
	}
	if (Int_types[i]) {
		return TRUE;
	}

	TypeName * typ = mySpec->type();
	if (typ && typ->stringEq(NAME_OF_TYPE_OF_ENUM)) {
		return TRUE;
	}

	if (!myList) {
		return FALSE;
	}
	return myList->isIntType();
}

BooleanVar TypeSpecifierList::
isEnumSpecifierList ()
{
	if (mySpec->isKindOfEnumSpecifier()) {
		return TRUE;
	}
	if (myList) {
		return myList->isEnumSpecifierList();
	}
	return FALSE;
}

DEFINE_CLASS(TypeName,Complex);

TypeName::
TypeName (TypeSpecifierList* a1,AbstractDeclarator* a2) 
{
	myTSL	= a1;
	myAbs	= a2;

	myUltType	= NULL;
}

void TypeName::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "TypeName\n";
				oo << myTSL;
	if (myAbs)	oo << myAbs;
	margin (oo,L);
}

void TypeName::
copyOn (ostream& oo)
{
				myTSL	-> copyOn(oo);
	if (myAbs)	myAbs	-> copyOn(oo); 
}

Token * TypeName::
firstToken ()
{
	return myTSL -> firstToken();
}

Token * TypeName::
lastToken ()
{
	return LAST_FOR_2(myAbs,myTSL);
}

CmpList * TypeName::
cmpList ()
{
	CmpList * list = myTSL->cmpList();

	if (myAbs) list->append(myAbs->cmpList());

	return list;
}

ArgumentDeclaration * TypeName::
makeArgumentDeclaration (Initializer* a1)
{
	if (a1) {
		return new AbstractInitArgumentDeclaration (
			myTSL->makeDeclSpecifiers(),
			myAbs,
			a1->equals(), 
			a1->expression()
		);
	}
	return new AbstractArgumentDeclaration (
		myTSL->makeDeclSpecifiers(),
		myAbs
	);
}

TypeSpecifierList * TypeName::
typeSpecifierList ()
{
	return myTSL;
}

AbstractDeclarator * TypeName::
abstractDeclarator ()
{
	return myAbs;
}

BooleanVar TypeName::
isPointer ()
{
	return myAbs ? myAbs->isPointer() : FALSE;
}	

TypeName * TypeName::
ultimateType ()
{
	if (myUltType) {
		return myUltType;
	}
	TypeSpecifier * ts	= myTSL->final()->typeSpecifier();

	if (!ts->typeDefinition()) {
		myUltType = this;
		return myUltType;
	}
	TypeName *			 u_typ		= ts->ultimateType();
	TypeSpecifierList *	 ret_tsl	= myTSL->replaceFinalWith(u_typ->typeSpecifierList());
	AbstractDeclarator * u_abs		= u_typ->abstractDeclarator();
	AbstractDeclarator * ret_abs	= myAbs ? myAbs->applyIndirection(u_abs) : u_abs;

	myUltType = new TypeName(ret_tsl,ret_abs);
	return myUltType;
}

ClassSpecifier * TypeName::			// does not resolve typedefs
classOfType ()
{
	TypeSpecifier * ts = 
		this
		-> typeSpecifierList()
		-> final()
		-> typeSpecifier()
	;
	
	Iterator *			classes = this->progPtr()->classes();
	ClassSpecifier *	cs;
	ClassName *			cn;

	while (cs = (ClassSpecifier*)classes->next()) {
		cn = cs->className();
		if (cn && cn->equivalentTo(ts)) {
			delete classes;
			return cs;
		}
	}
	delete classes;
	return NULL;
}

ClassSpecifier * TypeName::
classForType ()				// resolves typedefs
{
	TypeSpecifier * ts = 
		this
		-> ultimateType()
		-> typeSpecifierList()
		-> final()
		-> typeSpecifier()
	;
	
	Iterator *			classes = this->progPtr()->classes();
	ClassSpecifier *	cs;
	ClassName *			cn;

	while (cs = (ClassSpecifier*)classes->next()) {
		cn = cs->className();
		if (cn && cn->equivalentTo(ts)) {
			delete classes;
			return cs;
		}
	}
	delete classes;
	return NULL;
}

char * TypeName::
signature ()
{
	StringHeaper * 		bufP	= new StringHeaper (20,20);
	TypeName *			uType	= this->ultimateType();
	AbstractDeclarator*	abs		= uType->abstractDeclarator();
	TypeSpecifierList*	tsl		= uType->typeSpecifierList();

	if (abs) {
		bufP->strCat(abs->signature());
	}
	bufP->strCat(tsl->signature());

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
}

// All int types are considered equivalent

BooleanVar TypeName::
typeEquivalent (TypeName * toType)
{
	if (!toType) {
		return FALSE;
	}
		/* (change SP2_X etc to X*) 	*/

		/* remove leading 'cont' or 'volatile'					*/
		/* ( change {int,long,short,float,double,char,unsigned}	*/
		/* to int )												*/

	TypeSpecifierList *	toTSL	= toType->typeSpecifierList();
	TypeSpecifierList *	thisTSL = this->typeSpecifierList();

	toTSL	= toTSL ? toTSL->resolved() : NULL;
	thisTSL = thisTSL ? thisTSL->resolved() : NULL;

		/* remove '&' : convert '[]' to '*'		*/

	AbstractDeclarator *	toAbs	= toType->abstractDeclarator();
	AbstractDeclarator *	thisAbs = this->abstractDeclarator();

	toAbs	= toAbs ? toAbs->resolved() : NULL;
	thisAbs = thisAbs ? thisAbs->resolved() : NULL;

		/* 'void*' matches X*		*/

	if (toType->isPointer() && this->isPointer()) {
		if (toTSL->stringEq("void") || thisTSL->stringEq("void")) {
			return TRUE;
		}
	}
												// match abstract declarators
	if (!BOOL_EQ(toAbs,thisAbs)) {
		return FALSE;
	}
	if (toAbs && !toAbs->equivalentTo(thisAbs)) {
		return FALSE;
	}
												// match type specifier lists
	if (!BOOL_EQ(toTSL,thisTSL)) {
		return FALSE;
	}

	ClassSpecifier *	toClass = TypeName(toTSL,NULL).classForType();
	ClassSpecifier *	thisClass = TypeName(thisTSL,NULL).classForType();

	if (!BOOL_EQ(toClass,thisClass)) {
		return FALSE;
	}

	if (toTSL && !toTSL->equivalentTo(thisTSL)) {
		return FALSE;
	}

	return TRUE;
}

Function * TypeName::
fetchConversionTo (TypeName * toType)
{
	if (!toType) {
		return NULL;
	}
	ClassSpecifier *	cs;
	Function *			ret = NULL;

			/* conversion function */

	if (cs = this->classForType()) {
		ret = cs->fetchConversionTo(toType);
	}

	if (ret) {
		return ret;
	}
			/* single-arg constructor */

	if (cs = toType->classForType()) {
		Iterator *	it = cs->memberFuncs();
		Function *	f;
		while (f = (Function*)it->next()) {
			if (f->isCtor()) {
				Iterator *				args = f->arguments();
				ArgumentDeclaration *	arg;
				TypeName *				argType;

				if (args->count() == 1) {
					arg = CAST(ArgumentDeclaration,args->next());
					argType = arg->type();
					if (argType && argType->typeEquivalent(this)) {
						ret = f;
						delete args;
						break;
					}
				}
				delete args;
			}
		}
	}
	return ret;
}

BooleanVar TypeName::
isEnumType ()
{
	TypeSpecifierList *	tsl = myTSL;
	TypeSpecifier *		ts;
	Declaration *		dec = NULL;

	while (tsl) {
		ts = tsl->typeSpecifier();
		if ( dec = CAST(Declaration,ts->declaration())) {
			break;
		}
		tsl = tsl->typeSpecifierList();
	}
	return (dec && dec->isEnumDeclaration());
}

DEFINE_CLASS(NewInitializer,Complex);

NewInitializer::
NewInitializer (LP* a1,InitializerList* a2,RP* a3) 
{
	myLp	= a1;
	myList	= a2;
	myRp	= a3;
}

void NewInitializer::
printOn (ostream& oo)
{
	margin (oo,R);
				oo	<< "NewInitializer\n";
				oo	<< myLp;
	if (myList) oo	<< myList;
				oo	<< myRp;
	margin (oo,L);
}

Token * NewInitializer::
firstToken ()
{
	return myLp;
}

Token * NewInitializer::
lastToken ()
{
	return myRp;
}

DEFINE_CLASS(Placement,Complex);

Placement::
Placement (LP* a1,ExpressionList* a2,RP* a3) 
{
	myLp	= a1;
	myList	= a2;
	myRp	= a3;
}

void Placement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "Placement\n"
		<< myLp
		<< myList
		<< myRp
	;
	margin (oo,L);
}

Token * Placement::
firstToken ()
{
	return myLp;
}

Token * Placement::
lastToken ()
{
	return myRp;
}

DEFINE_CLASS(NewTypeName,Complex);

NewTypeName::
NewTypeName (TypeSpecifierList* a1,NewDeclarator* a2) 
{
	myTSL	= a1;
	myDecl	= a2;
}

void NewTypeName::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "NewTypeName\n";
				oo << myTSL;
	if (myDecl)	oo << myDecl;
	margin (oo,L);
}

Token * NewTypeName::
firstToken ()
{
	return  myTSL->firstToken();
}

Token * NewTypeName::
lastToken ()
{
	return LAST_FOR_2(myDecl,myTSL);
}

DEFINE_CLASS(PointerNewDeclarator,NewDeclarator);

PointerNewDeclarator::
PointerNewDeclarator (ASTERIX* a1,CvQualifierList* a2,NewDeclarator* a3) 
{
	myStar		= a1;
	myQualList	= a2;
	myDecl		= a3;
}

void PointerNewDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "PointerNewDeclarator\n";
					oo << myStar;
	if (myQualList)	oo << myQualList;
	if (myDecl)		oo << myDecl;
	margin (oo,L);
}

Token * PointerNewDeclarator::
firstToken ()
{
	return myStar;
}

Token * PointerNewDeclarator::
lastToken ()
{
	return LAST_FOR_3(myDecl,myQualList,myStar);
}

DEFINE_CLASS(ClassNewDeclarator,NewDeclarator);

ClassNewDeclarator::
ClassNewDeclarator 
	(CompleteClassName* a1,C_COLON* a2,ASTERIX* a3,CvQualifierList* a4,
	NewDeclarator* a5) 
{
	myName		= a1;
	myCCl		= a2;
	myStar		= a3;
	myQualList	= a4;
	myDecl		= a5;
}

void ClassNewDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "ClassNewDeclarator\n";
					oo << myName;
					oo << myCCl;
					oo << myStar;
	if (myQualList)	oo << myQualList;
	if (myDecl)		oo << myDecl;
	margin (oo,L);
}

Token * ClassNewDeclarator::
firstToken ()
{
	return myName->firstToken();
}

Token * ClassNewDeclarator::
lastToken ()
{
	return LAST_FOR_3(myDecl,myQualList,myStar);
}

DEFINE_CLASS(ArrayNewDeclarator,NewDeclarator);

ArrayNewDeclarator::
ArrayNewDeclarator (NewDeclarator* a1,LB* a2,Expression* a3,RB* a4) 
{
	myDecl	= a1;
	myLb	= a2;
	myExp	= a3;
	myRb	= a4;
}

void ArrayNewDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ArrayNewDeclarator\n";
	if (myDecl)	oo << myDecl;
				oo << myLb;
	if (myExp)	oo << myExp;
				oo << myRb;
	margin (oo,L);
}

Token * ArrayNewDeclarator::
firstToken ()
{
	return FIRST_FOR_2(myDecl,myLb);
}

Token * ArrayNewDeclarator::
lastToken ()
{
	return myRb;
}

DEFINE_CLASS(TaggedStatement,LabeledStatement);

TaggedStatement::
TaggedStatement (IDENTIFIER* a1,COLON* a2,Statement* a3) 
{
	myId	= a1;
	myCln	= a2;
	myStmt	= a3;
}

void TaggedStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "TaggedStatement\n"
		<< myId
		<< myCln
		<< myStmt
	;
	margin (oo,L);
}

Token * TaggedStatement::
firstToken ()
{
	return myId;
}

Token * TaggedStatement::
lastToken ()
{
	return myStmt->lastToken();
}

DEFINE_CLASS(CaseStatement,LabeledStatement);

CaseStatement::
CaseStatement (CASE* a1,ConditionalExpression* a2,COLON* a3,Statement* a4) 
{
	myCase	= a1;
	myExp	= a2;
	myCln	= a3;
	myStmt	= a4;
}

void CaseStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "CaseStatement\n"
		<< myCase
		<< myExp
		<< myCln
		<< myStmt
	;
	margin (oo,L);
}

Token * CaseStatement::
firstToken ()
{
	return myCase;
}

Token * CaseStatement::
lastToken ()
{
	return myStmt->lastToken();
}

DEFINE_CLASS(DefaultStatement,LabeledStatement);

DefaultStatement::
DefaultStatement (DEFAULT* a1,COLON* a2,Statement* a3) 
{
	myDefl	= a1;
	myCln	= a2;
	myStmt	= a3;
}

void DefaultStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "DefaultStatement\n"
		<< myDefl
		<< myCln
		<< myStmt
	;
	margin (oo,L);
}

Token * DefaultStatement::
firstToken ()
{
	return myDefl;
}

Token * DefaultStatement::
lastToken ()
{
	return myStmt->lastToken();
}

DEFINE_CLASS(ExpressionStatement,ForInitStatement);

ExpressionStatement::
ExpressionStatement (Expression* a1,SEMICOLON* a2) 
{
	myExp	= a1;
	mySc	= a2;
}

void ExpressionStatement::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ExpressionStatement\n";
	if (myExp)	oo << myExp;
				oo << mySc;
	margin (oo,L);
}

Token * ExpressionStatement::
firstToken ()
{
	return FIRST_FOR_2(myExp,mySc);
}

Token * ExpressionStatement::
lastToken ()
{
	return mySc;
}

DEFINE_CLASS(ActualStatementList,StatementList);
ActualStatementList::
ActualStatementList (StatementList* a1,Statement* a2) 
{
	myList	= a1;
	myStmt	= a2;
}

void ActualStatementList::
printOn (ostream& oo)
{
/*
	margin (oo,R);
	oo
		<< "ActualStatementList\n"
		<< myList
		<< myStmt
	;
	margin (oo,L);
*/
	oo
		<< myList
		<< myStmt
	;
}

Token * ActualStatementList::
firstToken ()
{
	return myList->firstToken();
}

Token * ActualStatementList::
lastToken ()
{
	return myStmt->lastToken();
}

StatementList * ActualStatementList::
prepend (StatementList * slist)
{
	myList = myList->prepend(slist);
	return this;
}

DEFINE_CLASS(CompoundStatement,Statement);

CompoundStatement::
CompoundStatement (LC* a1,StatementList* a2,RC* a3) 
{
	myLc	= a1;
	myList	= a2;
	myRc	= a3;
}

void CompoundStatement::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "CompoundStatement\n";
				oo << myLc;
	if (myList)	oo << myList;
				oo << myRc;
	margin (oo,L);
}

Token * CompoundStatement::
firstToken ()
{
	return myLc;
}

Token * CompoundStatement::
lastToken ()
{
	return myRc;
}

BooleanVar CompoundStatement::
definesScope ()
{
	return TRUE;
}

Iterator * CompoundStatement::
declarations ()
{
	Thread * t = this
				-> progPtr()
				-> declThread()
				-> contentsOf(this)
			;

	Segment *	start	= t->first();
	Segment *	end		= t->last();
	Segment *	s;
	Segment *	last 	= NULL;
	Iterator *	ret 	= new Iterator();

	for (s=start; s; s = (s==end) ? NULL : s->next() ) { 
		if ((s==this) || last && last->contains(s)) {
			continue;
		}
		ret->appendSeg(s);
		last = s;
	}
	return ret;
}

DEFINE_CLASS(IfStatement,SelectionStatement);

IfStatement::
IfStatement (IF* a1,LP* a2,Expression* a3,RP* a4,Statement* a5) 
{
	myIf	= a1;
	myLp	= a2;
	myExp	= a3;
	myRp	= a4;
	myStmt	= a5;
}

void IfStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "IfStatement\n"
		<< myIf
		<< myLp
		<< myExp
		<< myRp
		<< myStmt
	;
	margin (oo,L);
}

Token * IfStatement::
firstToken ()
{
	return myIf;
}

Token * IfStatement::
lastToken ()
{
	return myStmt->lastToken();
}

Expression * IfStatement::
expression ()
{
	return myExp;
}

Statement * IfStatement::
statement ()
{
	return myStmt;
}

DEFINE_CLASS(IfElseStatement,SelectionStatement);

IfElseStatement::
IfElseStatement 
	(IF* a1,LP* a2,Expression* a3,RP* a4,Statement* a5,ELSE* a6,Statement* a7) 
{
	myIf	= a1;
	myLp	= a2;
	myExp	= a3;
	myRp	= a4;
	myStmt1	= a5;
	myElse	= a6;
	myStmt2	= a7;
}

void IfElseStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "IfElseStatement\n"
		<< myIf
		<< myLp
		<< myExp
		<< myRp
		<< myStmt1
		<< myElse
		<< myStmt2
	;
	margin (oo,L);
}

Token * IfElseStatement::
firstToken ()
{
	return myIf;
}

Token * IfElseStatement::
lastToken ()
{
	return myStmt2->lastToken();
}

DEFINE_CLASS(SwitchStatement,SelectionStatement);

SwitchStatement::
SwitchStatement (SWITCH* a1,LP* a2,Expression* a3,RP* a4,Statement* a5) 
{
	mySwitch	= a1;
	myLp		= a2;
	myExp		= a3;
	myRp		= a4;
	myStmt		= a5;
}

void SwitchStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "SwitchStatement\n"
		<< mySwitch
		<< myLp
		<< myExp
		<< myRp
		<< myStmt
	;
	margin (oo,L);
}

Token * SwitchStatement::
firstToken ()
{
	return mySwitch;
}

Token * SwitchStatement::
lastToken ()
{
	return myStmt->lastToken();
}

DEFINE_CLASS(WhileStatement,IterationStatement);

WhileStatement::
WhileStatement (WHILE* a1,LP* a2,Expression* a3,RP* a4,Statement* a5) 
{
	myWhile	= a1;
	myLp	= a2;
	myExp	= a3;
	myRp	= a4;
	myStmt	= a5;
}

void WhileStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "WhileStatement\n"
		<< myWhile
		<< myLp
		<< myExp
		<< myRp
		<< myStmt
	;
	margin (oo,L);
}

Token * WhileStatement::
firstToken ()
{
	return myWhile;
}

Token * WhileStatement::
lastToken ()
{
	return myStmt->lastToken();
}

Expression * WhileStatement::
controlExpression ()
{
	return myExp;
}

Token * WhileStatement::
rParen ()
{
	return myRp;
}

Statement * WhileStatement::
bodyStatement ()
{
	return myStmt;
}

DEFINE_CLASS(DoStatement,IterationStatement);

DoStatement::
DoStatement 
	(DO* a1,Statement* a2,WHILE* a3,LP* a4,Expression* a5,RP* a6,SEMICOLON* a7) 
{
	myDo	= a1;
	myStmt	= a2;
	myWhile	= a3;
	myLp	= a4;
	myExp	= a5;
	myRp	= a6;
	mySc	= a7;
}

void DoStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "DoStatement\n"
		<< myDo
		<< myStmt
		<< myWhile
		<< myLp
		<< myExp
		<< myRp
		<< mySc
	;
	margin (oo,L);
}

Token * DoStatement::
firstToken ()
{
	return myDo;
}

Token * DoStatement::
lastToken ()
{
	return mySc;
}

DEFINE_CLASS(ForStatement,IterationStatement);

ForStatement::
ForStatement 
	(FOR* a1,LP* a2,ForInitStatement* a3,Expression* a4,SEMICOLON* a5,
		Expression* a6,RP* a7,Statement* a8) 
{
	myFor	= a1;
	myLp	= a2;
	myInit	= a3;
	myExp1	= a4;
	mySc	= a5;
	myExp2	= a6;
	myRp	= a7;
	myStmt	= a8;
}

void ForStatement::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ForStatement\n";
				oo << myFor;
				oo << myLp;
				oo << myInit;
	if (myExp1)	oo << myExp1;
				oo << mySc;
	if (myExp2)	oo << myExp2;
				oo << myRp;
				oo << myStmt;
	margin (oo,L);
}

Token * ForStatement::
firstToken ()
{
	return myFor;
}

Token * ForStatement::
lastToken ()
{
	return myStmt->lastToken();
}

Statement * ForStatement::
initStatement ()
{
	return myInit;
}

Expression * ForStatement::
controlExpression ()
{
	return myExp1;
}

Expression * ForStatement::
reinitExpression ()
{
	return myExp2;
}

Token * ForStatement::
rParen ()
{
	return myRp;
}

Statement * ForStatement::
bodyStatement ()
{
	return myStmt;
}

DEFINE_CLASS(BreakStatement,JumpStatement);

BreakStatement::
BreakStatement (BREAK* a1,SEMICOLON* a2) 
{
	myBreak	= a1;
	mySc	= a2;
}

void BreakStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "BreakStatement\n"
		<< myBreak
		<< mySc
	;
	margin (oo,L);
}

Token * BreakStatement::
firstToken ()
{
	return myBreak;
}

Token * BreakStatement::
lastToken ()
{
	return mySc;
}

DEFINE_CLASS(ContinueStatement,JumpStatement);

ContinueStatement::
ContinueStatement (CONTINUE* a1,SEMICOLON* a2) 
{
	myCont	= a1;
	mySc	= a2;
}

void ContinueStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ContinueStatement\n"
		<< myCont
		<< mySc
	;
	margin (oo,L);
}

Token * ContinueStatement::
firstToken ()
{
	return myCont;
}

Token * ContinueStatement::
lastToken ()
{
	return mySc;
}

DEFINE_CLASS(ReturnStatement,JumpStatement);

ReturnStatement::
ReturnStatement (RETURN* a1,Expression* a2,SEMICOLON* a3) 
{
	myRet	= a1;
	myExp	= a2;
	mySc	= a3;
}

void ReturnStatement::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ReturnStatement\n";
				oo << myRet;
	if (myExp)	oo << myExp;
				oo << mySc;
	margin (oo,L);
}

Token * ReturnStatement::
firstToken ()
{
	return myRet;
}

Token * ReturnStatement::
lastToken ()
{
	return mySc;
}

Expression * ReturnStatement::
expression ()
{
	return myExp;
}

DEFINE_CLASS(GotoStatement,JumpStatement);

GotoStatement::
GotoStatement (GOTO* a1,IDENTIFIER* a2,SEMICOLON* a3) 
{
	myGo	= a1;
	myId	= a2;
	mySc	= a3;
}

void GotoStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "GotoStatement\n"
		<< myGo
		<< myId
		<< mySc
	;
	margin (oo,L);
}

Token * GotoStatement::
firstToken ()
{
	return myGo;
}

Token * GotoStatement::
lastToken ()
{
	return mySc;
}

DEFINE_CLASS(DeclarationStatement,ForInitStatement);

DeclarationStatement::
DeclarationStatement (Declaration* a1) 
{
	myDecl	= a1;
}

void DeclarationStatement::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "DeclarationStatement\n"
		<< myDecl
	;
	margin (oo,L);
}

Token * DeclarationStatement::
firstToken ()
{
	return myDecl->firstToken();
}

Token * DeclarationStatement::
lastToken ()
{
	return myDecl->lastToken();
}

DEFINE_CLASS(DeclarationList,MetaDeclaration);

DEFINE_CLASS(Declaration,DeclarationList);

Iterator * Declaration::
funcDeclarations ()
{
	return new Iterator();
}

Iterator * Declaration::
varDeclarations ()
{
	return new Iterator();
}

DeclarationList * Declaration::
declList ()
{
	return NULL;
}

Declaration * Declaration::
decl ()
{
	return this;
}

StatementList * Declaration::
makeStatementList ()
{
	return new DeclarationStatement (this);
}

BooleanVar Declaration::
isEnumDeclaration ()
{
	return FALSE;
}

DEFINE_CLASS(Function,Declaration);

Function::
Function ()
{
	myType		= NULL;
	myClass		= NULL;
	mySuperImp	= NULL;
	myOnum		= NULL;
	myMName		= NULL;
}

Iterator * Function::
arguments ()
{
	return this->functionDeclarator()->arguments();
}

BooleanVar Function::
isDefinition ()
{
	return TRUE;
} 

Function * Function::
definitionIfLocal ()
{
	return this;
} 

BooleanVar Function::
matches (Function* func)
{
	if (!func) {
		return FALSE;
	}

	TypeName * this_type = this->returnType();
	TypeName * func_type = func->returnType();

	if (!this_type) {
		if (func_type) {
			return FALSE;
		}
	} else {
		if (!this_type->equivalentTo(func_type)) {
			return FALSE;
		}
	}
	return this
		-> functionDeclarator()
		-> matches(func->functionDeclarator())
	;
}

void Function::
setOnum (Token* t)
{
	myOnum = t;
} 

BooleanVar Function::
onumIsSet ()
{
	return myOnum ? TRUE : FALSE;
} 

Iterator * Function::
funcDeclarations ()
{
	Iterator * ret = new Iterator();
	ret->appendSeg(this); 
	return ret;
}

Iterator * Function::
varDeclarations ()
{
	return new Iterator();
}

Token * Function:: 
m_name ()
{
	if (myMName) {
		return myMName;
	}

	StringHeaper *  bufP = new StringHeaper(30);

	ClassSpecifier *	cs = this->homeClass();
	ClassName * 		cn = cs ? cs->className() : NULL;

	char * cl_sig = cn ? cn->signature() : NULL;
	char * func_name = this->isCtor() ? "__ct" : this->name()->signature();

	bufP->strCat(func_name);
	bufP->strCat ("__");

	if (cl_sig) {
		bufP->strCat(cl_sig);
	}
	bufP->strCat(this->functionDeclarator()->signature());

	myMName = new Token(bufP->asCharP(),NULL);
	delete bufP;
	return myMName;
}

ClassSpecifier * Function::
homeClass ()
{
	if (myClass) {
		return myClass;
	}

	FunctionDeclarator *	f_dcl= this->functionDeclarator();
	Program *				pgm = this->progPtr();
	ClassSpecifier *		c;

	if (c = f_dcl->dname()->name()->qualifyingClass()) {
		myClass = c;
	} else {
		myClass = (ClassSpecifier*) pgm->classThread()->containerOf(this);
	}
	return myClass;
}

ClassSpecifier * Function::
topImplementor ()
{
	ClassSpecifier * c		= this->homeClass();
	ClassSpecifier * ret	= NULL;

	if (!c) {
		return ret;
	}

	Iterator *	cit = c->ancestors();

	while (c = (ClassSpecifier*)cit->next()) {
		if (c->impOf(this)) {
			ret = c;
		}
	}
	delete cit;
	return ret;
}

TypeName * Function::
returnType ()
{
	if (myType) {
		return myType;
	}
	if (this->isCtor() || this->isDtor() || this->isConv()) {
		return NULL;
	}

	TypeSpecifierList *		tsl;
	DeclSpecifiers *		decl_specs	= this->declSpecifiers();
	Declarator *			tn_dcl		= this->declarator();

	if (decl_specs) {
		tsl = decl_specs->typeSpecifierList();
	} else {
		tsl = new TypeSpecifierList (
			new ActualSimpleTypeName ("int",this),
			NULL
		);
	}
	myType = new TypeName (tsl,tn_dcl->returnAbstract());
	return myType;
}

Token * Function::
proType ()
{
	ClassSpecifier * c = this->homeClass();

	if (!c) {
		return NULL;
	}

	Function * f = NULL;

	if (c->contains(this)) {
		f = this;
	} else {
		f = c->impOf(this);
	}
	if (!f) {
		return NULL;
	}
	return c->proTypeAt(f->firstPos());
}

BooleanVar Function::
isCtor ()
{
	Name * n = this->name();

	if (n && n->isCtorName()) {
		return TRUE;
	}

	ClassSpecifier *	cs = this->homeClass();
	ClassName *			cn = cs ? cs->className() : NULL;

	if (cn && cn->equivalentTo(n)) {
		return TRUE;
	}
	return FALSE;
}

BooleanVar Function::
isDtor ()
{
	Name * n = this->name();

	if (n && n->isDtorName()) {
		return TRUE;
	}
	return FALSE;
}

BooleanVar Function::
isConv()
{
	Name * n = this->name();

	if (n && n->isConvName()) {
		return TRUE;
	}
	return FALSE;
}

Function * Function::
superImp ()
{
	if (mySuperImp) {
		return mySuperImp;
	}

	ClassSpecifier * c = this->homeClass();

	if (!c) {
		return NULL;
	}

	Iterator *	cit = c->ancestors();

	while (c = (ClassSpecifier*)cit->next()) {
		if (mySuperImp = c->impOf(this)) {
			break;
		}
	}
	delete cit;
	return mySuperImp;
}

Iterator * Function::
subImps ()
{
	ClassSpecifier * c = this->homeClass();

	if (!c) {
		return NULL;
	}

	Iterator *	cit = c->children();
	Iterator *	ret = new Iterator();

	while (c = (ClassSpecifier*)cit->next()) {
		ret->appendIList(c->subImpsOf(this));
	}
	delete cit;

	return ret;
}

Iterator * Function::
siblings ()
{
	ClassSpecifier * cls = this->homeClass();
	Iterator *		 sibs;

	sibs = cls
		? cls->memberFuncs()
		: this->progPtr()->globalFunctions()
	;
	return sibs;
}

Iterator * Function::
classRefs ()
{
	Iterator * tmp = new Iterator();

	TypeName *			typ;
	ClassSpecifier *	cs;

	if (   (typ = this->returnType())
		&& (cs = typ->classForType())
	) {
		tmp->appendSeg(cs->classRef());
	}

	Iterator *				args = this->arguments();
	ArgumentDeclaration *	arg;

	while (arg = (ArgumentDeclaration*)args->next()) {
		if (cs = arg->type()->classForType()) {
			tmp->appendSeg(cs);
		}
	}
	delete args;

	Iterator *			ret = new Iterator();
	ClassSpecifier *	tcs;

	while (cs = (ClassSpecifier*)tmp->next()) {
		while (tcs = (ClassSpecifier*)ret->next()) {
			if (cs->classRef() == tcs->classRef()) {
				break;
			}
		}
		ret->reset();
		if (!tcs) {
			ret->appendSeg(cs->classRef());
		}
	}
	delete tmp;
	return ret;
}

Token * Function::
onum ()
{
	if (myOnum) {
		return myOnum;
	}

	Iterator *			iter;
	ClassSpecifier *	cls = this->homeClass();

	if (cls) {
		iter = cls->memberFuncs();
	} else {
		iter = this->progPtr()->globalFunctions();
	}

	Iterator *			tmpiter;
	Function *			f1;
	Function *			f2;
	char *				str1;
	char *				str2;
	IList *				tmp;
	int					num;
	int					nfuncs;
	StringHeaper *		sP;

	while (f1 = (Function*)iter->next()) {
		str1 = f1->name()->asString();
		tmpiter = new Iterator();
		for (tmp=iter->ilist(); tmp; tmp=tmp->list()) {
			f2 = (Function*)tmp->seg();
			if (f2->onumIsSet()) {
				continue;
			}
			str2 = f2->name()->asString();
			if (strcmp(str1,str2) == 0) {
				tmpiter->appendSeg(f2);
			}
		}
		nfuncs = tmpiter->count();
		num = 1;
		while (f2 = (Function*)tmpiter->next()) {
			if (nfuncs == 1) {
				f2->setOnum(new Token ("",f2));
			} else {
				sP = new StringHeaper(8);
				sP->intCat(num++);
				f2->setOnum(new Token (sP->asCharP(),f2));
				delete sP;
			}
		}
		delete tmpiter;
	}
	delete iter;
	return myOnum;
}

BooleanVar Function::
argsMatch (Iterator * actuals)
{
	Iterator *				formals = this->arguments();
	ArgumentDeclaration *	form;
	Expression *			act;
	BooleanVar				skip = FALSE; // ellipsis or default arg in param list
	BooleanVar				ok = TRUE; 

	form = formals ? (ArgumentDeclaration*)formals->next() : NULL;
	act = actuals	? (Expression*)actuals->next() : NULL;

	while (form && act) {
	   	if (!form->typeEquivalent(act)) {
			ok = FALSE;
			break;
		}
		if (form->stringEq("...") || form->defaultInit()) {
			skip = TRUE;
		}
		form = formals	? (ArgumentDeclaration*)formals->next() : NULL;
		act = actuals ? (Expression*)actuals->next() : NULL;
	}

	if (act && !skip) {
		ok = FALSE;
	}
	if (form && !(form->stringEq("...") || form->defaultInit())) {
		ok = FALSE;
	}

	actuals->reset();
	delete formals;
	return ok;
}

int Function::
arity ()
{
	Iterator *	it = this->arguments();
	int			ret = it->count();
	delete it;
	return ret;
}

BooleanVar Function::
isConversionTo (Token*)
{
	return FALSE;
}

BooleanVar Function::
isKindOfFunctionDefinition ()
{
	return FALSE;
}

BooleanVar Function::
isDeferred ()
{
	return FALSE;
}

DEFINE_CLASS(ExpressionInitializerList,InitializerList);

ExpressionInitializerList::
ExpressionInitializerList (Expression* a1) 
{
	myExp	= a1;
}

void ExpressionInitializerList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ExpressionInitializerList\n"
		<< myExp
	;
	margin (oo,L);
}

Token * ExpressionInitializerList::
firstToken ()
{
	return myExp->firstToken();
}

Token * ExpressionInitializerList::
lastToken ()
{
	return myExp->lastToken();
}

Expression * ExpressionInitializerList::
expression ()
{
	return myExp;
}

Initializer * ExpressionInitializerList::
makeInitializerWith (EQUALS* e)
{
	return new ExpressionInitializer (e,myExp);
}

DEFINE_CLASS(CommaInitializerList,InitializerList);

CommaInitializerList::
CommaInitializerList (InitializerList* a1,COMMA* a2,Expression* a3) 
{
	myList	= a1;
	myCm	= a2;
	myExp	= a3;
}

void CommaInitializerList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "CommaInitializerList\n"
		<< myList
		<< myCm
		<< myExp
	;
	margin (oo,L);
}

Token * CommaInitializerList::
firstToken ()
{
	return myList->firstToken();
}

Token * CommaInitializerList::
lastToken ()
{
	return myExp->lastToken();
}

DEFINE_CLASS(CurlyInitializerList,InitializerList);

CurlyInitializerList::
CurlyInitializerList (LC* a1,InitializerList* a2,COMMA* a3,RC* a4) 
{
	myLc	= a1;
	myList	= a2;
	myCm	= a3;
	myRc	= a4;
}

void CurlyInitializerList::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "CurlyInitializerList\n";
				oo << myLc;
				oo << myList;
	if (myCm)	oo << myCm;
				oo << myRc;
	margin (oo,L);
}

Token * CurlyInitializerList::
firstToken ()
{
	return myLc;
}

Token * CurlyInitializerList::
lastToken ()
{
	return myRc;
}

Initializer * CurlyInitializerList::
makeInitializerWith (EQUALS* e)
{
	return new CurlyInitializer (e, myLc, myList, myCm, myRc);
}

DEFINE_CLASS(DeclSpecifiers,Complex);

DeclSpecifiers::
DeclSpecifiers (DeclSpecifiers* a1,DeclSpecifier* a2) 
{
	mySpecS	= a1;
	mySpec	= a2;

	myTSL	= NULL;
}

void DeclSpecifiers::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "DeclSpecifiers\n";
	if (mySpecS)	oo << mySpecS;
					oo << mySpec;
	margin (oo,L);
}

Token * DeclSpecifiers::
firstToken ()
{
	return FIRST_FOR_2(mySpecS,mySpec);
}

Token * DeclSpecifiers::
lastToken ()
{
	return mySpec->lastToken();
}

DeclSpecifiers * DeclSpecifiers::
declSpecs ()
{
	return mySpecS;
}

DeclSpecifier * DeclSpecifiers::
declSpec ()
{
	return mySpec;
}


TypeSpecifierList * DeclSpecifiers::
typeSpecifierList ()
{
	if (myTSL) {
		return myTSL;
	}
		
	DeclSpecifier *		dspec;
	DeclSpecifiers *	dspecs;
	TypeSpecifier *		tspec		= NULL;
	TypeSpecifierList *	tspec_list	= NULL;

	for (dspecs = this; dspecs; dspecs = dspecs->declSpecs()) {
		dspec = dspecs->declSpec();
		tspec = dspec ? dspec->typeSpecifier() : NULL;
		if (tspec) {
			tspec_list = new TypeSpecifierList (tspec,tspec_list);
		}
	}
	myTSL =  tspec_list;
	return myTSL;
}

BooleanVar DeclSpecifiers::
isTypedef ()
{
	if (mySpec->isTypedef()) {
		return TRUE;
	}
	if (mySpecS) {
		return mySpecS->isTypedef();
	}
	return FALSE;
}

BooleanVar DeclSpecifiers::
hasSpec (Token* t)
{
	if (!t) {
		return FALSE;
	}
	if (mySpec->isNamed(t)) {
		return TRUE;
	}
	if (mySpecS) {
		return mySpecS->hasSpec(t);
	}
	return FALSE;
}

BooleanVar DeclSpecifiers::
declares (Name * n)
{
	if (mySpec->declares(n)) {
		return TRUE;
	}
	if (mySpecS) {
		return mySpecS->declares(n);
	}
	return FALSE;
}

DEFINE_CLASS(DataDeclaration,Declaration);

DataDeclaration::
DataDeclaration (DeclSpecifiers* a1,DeclaratorList* a2,SEMICOLON* a3)
{
	mySpecs	= a1;
	myList	= a2;
	mySc	= a3;
}

void DataDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "DataDeclaration\n";
	if (mySpecs)	oo << mySpecs;
	if (myList)		oo << myList;
					oo << mySc;
	margin (oo,L);
}

Token * DataDeclaration::
firstToken ()
{
	return FIRST_FOR_3(mySpecs, myList, mySc);
}

Token * DataDeclaration::
lastToken ()
{
	return mySc;
}

TypeName * DataDeclaration::
typeOf (Name * n)
{
	if (!n) {
		return NULL;
	}

	if (mySpecs && mySpecs->declares(n)) {	// must be enum
		return new TypeName (
			new TypeSpecifierList (
				new ActualSimpleTypeName ("long",mySpecs),
				NULL
			),
			NULL
		);
	}

	Declarator * d;

	if (myList && (d = myList->declOf(n))) {
		return new TypeName (
			mySpecs ? mySpecs->typeSpecifierList() : NULL,
			d->abstract()
		);
	}
	return NULL;
}

BooleanVar DataDeclaration::
declares (Name * n)
{
	if (myList && myList->declares(n)) {
		return TRUE;
	}
	if (mySpecs && mySpecs->declares(n)) {
		return TRUE;
	}
	return FALSE;
}

BooleanVar DataDeclaration::
isTypedefOf (Name * n)
{
	if (!mySpecs || !mySpecs->isTypedef()) {
		return FALSE;
	}
	return (myList && myList->declares(n)) ? TRUE : FALSE;
}

Iterator * DataDeclaration::
funcDeclarations ()
{
	DeclaratorList *	dList;
	Declarator *		decl;
	Iterator *			ret = new Iterator();

	if (!myList || (mySpecs && mySpecs->isTypedef())) {
		return ret;
	}

	for (dList = myList; dList; dList = dList->fetchList()) {

		decl = dList->getDecl();
		if (decl->declaresFunction()) {
			ret->appendSeg (
				new FunctionDeclaration (mySpecs,decl,NULL)
			);
		}
	}
	return ret;
}

Iterator * DataDeclaration::
varDeclarations ()
{
	DeclaratorList *	dList;
	Declarator *		decl;
	Iterator *			ret = new Iterator();

	if (!myList) {
		return ret;
	}

	for (dList = myList; dList; dList = dList->fetchList()) {
		decl = dList->getDecl();
		if (decl->declaresVariable()) {
			ret->appendSeg(new MemVarDeclaration (mySpecs,decl));
		}
	}
	return ret;
}

BooleanVar DataDeclaration::
isEnumDeclaration ()
{
	DeclSpecifiers * dss;

	for (dss = mySpecs; dss; dss = dss->declSpecs()) {
		if (dss->declSpec()->isKindOfEnumSpecifier()) {
			return TRUE;
		}
	}
	return FALSE;
}


DEFINE_CLASS(MemVarDeclaration,Declaration);

MemVarDeclaration::
MemVarDeclaration (DeclSpecifiers* a1,Declarator* a2)
{
	mySpecs	= a1;
	myDecl	= a2;
}

void MemVarDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
	oo << "MemVarDeclaration\n";
	oo << mySpecs;
	oo << myDecl;
	margin (oo,L);
}

Token * MemVarDeclaration::
firstToken ()
{
	return mySpecs->firstToken();
}

Token * MemVarDeclaration::
lastToken ()
{
	return myDecl->lastToken();
}

CmpList * MemVarDeclaration::
cmpList ()
{
	CmpList * list;

	if (mySpecs) {
		list = mySpecs->cmpList();
		list->append(myDecl->cmpList());
	} else {
		list = myDecl->cmpList();
	}
	return list;
}

ClassSpecifier * MemVarDeclaration::
homeClass ()
{
	ClassSpecifier *	c;
	Program *			pgm = this->progPtr();

	if (c = myDecl->dname()->name()->qualifyingClass()) {
		return c;
	} else {
		return (ClassSpecifier*) pgm->classThread()->containerOf(this);
	}
}

Token * MemVarDeclaration::
proType ()
{
	ClassSpecifier * c = this->homeClass();

	if (!c) {
		return NULL;
	}
	return c->proTypeAt(this->firstPos());
}

Name * MemVarDeclaration::
name ()
{
	return myDecl->dname()->name();
}

TypeName * MemVarDeclaration::
type ()
{
	return new TypeName (
		mySpecs->typeSpecifierList(),
		myDecl->abstract()
	);
}

BooleanVar MemVarDeclaration::
hasSpec (Token * t)
{
	return mySpecs ? mySpecs->hasSpec(t) : FALSE;
}

Iterator * MemVarDeclaration::
funcDeclarations ()
{
	return new Iterator();
}

Iterator * MemVarDeclaration::
varDeclarations ()
{
	Iterator * ret = new Iterator();

	ret->appendSeg(this); 
	return ret;
}

DEFINE_CLASS(FakeDeclaration,Declaration);

FakeDeclaration::
FakeDeclaration (SEMICOLON* a1) 
{
	mySc	= a1;
}

void FakeDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
	oo << "FakeDeclaration\n";
	oo << mySc;
	margin (oo,L);
}

Token * FakeDeclaration::
firstToken ()
{
	return mySc;
}

Token * FakeDeclaration::
lastToken ()
{
	return mySc;
}

DEFINE_CLASS(IdentifierMemInitializer,MemInitializer);

IdentifierMemInitializer::
IdentifierMemInitializer (IDENTIFIER* a1,LP* a2,ExpressionList* a3,RP* a4) 
{
	myId	= a1;
	myLp	= a2;
	myList	= a3;
	myRp	= a4;
}

void IdentifierMemInitializer::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "IdentifierMemInitializer\n";
	if (myId)	oo << myId;
				oo << myLp;
	if (myList)	oo << myList;
				oo << myRp;
	margin (oo,L);
}

Token * IdentifierMemInitializer::
firstToken ()
{
	return myId ? myId : myLp;

}

Token * IdentifierMemInitializer::
lastToken ()
{
	return myRp;
}

MemInitializerList * IdentifierMemInitializer::
chain (COMMA* a1, MemInitializer* a2)
{
	return new ActualMemInitializerList (this, a1, a2);
}

DEFINE_CLASS(ClassMemInitializer,MemInitializer);

ClassMemInitializer::
ClassMemInitializer (CompleteClassName* a1,LP* a2,ExpressionList* a3,RP* a4) 
{
	myName	= a1;
	myLp	= a2;
	myList	= a3;
	myRp	= a4;
}

void ClassMemInitializer::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ClassMemInitializer\n";
				oo << myName;
				oo << myLp;
	if (myList)	oo << myList;
				oo << myRp;
	margin (oo,L);
}

Token * ClassMemInitializer::
firstToken ()
{
	return myName->firstToken();
}

Token * ClassMemInitializer::
lastToken ()
{
	return myRp;
}

DEFINE_CLASS(ActualMemInitializerList,MemInitializerList);

ActualMemInitializerList::
ActualMemInitializerList (MemInitializer* a1,COMMA* a2,MemInitializerList* a3) 
{
	myInit	= a1;
	myCm	= a2;
	myList	= a3;
}

void ActualMemInitializerList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ActualMemInitializerList\n"
		<< myInit
		<< myCm
		<< myList
	;
	margin (oo,L);
}

Token * ActualMemInitializerList::
firstToken ()
{
	return myInit->firstToken();
}

Token * ActualMemInitializerList::
lastToken ()
{
	return myList->lastToken();
}

MemInitializerList * ActualMemInitializerList::
chain (COMMA* a1, MemInitializer* a2)
{
	return myList->chain(a1,a2); 
}

DEFINE_CLASS(CtorInitializer,Complex);

CtorInitializer::
CtorInitializer (COLON* a1,MemInitializerList* a2) 
{
	myCln	= a1;
	myList	= a2;
}

void CtorInitializer::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "CtorInitializer\n"
		<< myCln
		<< myList
	;
	margin (oo,L);
}

Token * CtorInitializer::
firstToken ()
{
	return myCln;
}

Token * CtorInitializer::
lastToken ()
{
	return myList->lastToken();
}

CtorInitializer * CtorInitializer::
chain (COMMA* a1,MemInitializer* a2)
{
	myList = myList->chain(a1,a2);
	return this;
}

DEFINE_CLASS(Dname,Declarator);

Dname::
Dname (Name* a1) 
{
	myName = a1;
}

void Dname::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "Dname\n"
		<< myName
	;
	margin (oo,L);
}

Token * Dname::
firstToken ()
{
	return myName->firstToken();
}

Token * Dname::
lastToken ()
{
	return myName->lastToken();
}

Dname * Dname::
dname ()
{
	return this;
}

Name * Dname::
name ()
{
	return myName;
}

AbstractDeclarator * Dname::
abstract ()
{
	return NULL;
}

DEFINE_CLASS(FunctionDeclarator,Declarator);

FunctionDeclarator::
FunctionDeclarator 
	(Declarator* a1,LP* a2,ArgumentDeclarationList* a3,RP* a4,
		CvQualifierList* a5) 
{
	myDecl		= a1;
	myLp		= a2;
	myArgList	= a3;
	myRp		= a4;
	myQualList	= a5;
}

void FunctionDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
	oo << "FunctionDeclarator\n";
	oo << myDecl;
	oo << myLp;
	if (myArgList)	oo << myArgList;
	oo << myRp;
	if (myQualList)	oo << myQualList;
	margin (oo,L);
}

void FunctionDeclarator::
copyOn (ostream& oo)
{
    myDecl -> copyOn(oo);
    myLp -> copyOn(oo);
    if (myArgList)	myArgList -> copyOn(oo);
    myRp -> copyOn(oo);
    if (myQualList)	myQualList -> copyOn(oo);

}

Token * FunctionDeclarator::
firstToken ()
{
	return myDecl->firstToken();
}

Token * FunctionDeclarator::
lastToken ()
{
	return LAST_FOR_2(myQualList,myRp);
}

CmpList * FunctionDeclarator::
cmpList ()
{
	CmpList *	list = myDecl->cmpList(); 

	list->append(myLp -> cmpList());
	if (myArgList)	list->append(myArgList	-> cmpList());
	list->append(myRp -> cmpList());
	if (myQualList)	list->append(myQualList	-> cmpList());

	return list;
}

ArgumentDeclarationList * FunctionDeclarator::
argumentDeclarationList	()
{
	return myArgList;
}

BooleanVar FunctionDeclarator::
matches (FunctionDeclarator * func_decl) 
{
	if (!func_decl) {
		return FALSE;
	} 

	Name * func_name = func_decl->dname()->name()->bareName();
	Name * this_name = myDecl->dname()->name()->bareName();

	if (!func_name->equivalentTo (this_name)) {
		return FALSE;
	}

	ArgumentDeclarationList * func_arg_decl_l
		= func_decl->argumentDeclarationList();

	if (!func_arg_decl_l && !myArgList) {
		return TRUE;
	}
	if (!BOOL_EQ(func_arg_decl_l,myArgList)) {
		return FALSE;
	}

	Iterator * func_args = func_arg_decl_l->arguments();
	Iterator * this_args = myArgList->arguments();

	ArgumentDeclaration * f_a;
	ArgumentDeclaration * t_a;

	for(;;) { 
		f_a = (ArgumentDeclaration*)func_args->next();
		t_a = (ArgumentDeclaration*)this_args->next();
		if (!BOOL_EQ(f_a,t_a)) {		// different arity
			delete func_args;
			delete this_args;
			return FALSE;
		}
		if (!f_a) {						// end of arg list
			delete func_args;
			delete this_args;
			break;
		}
		if (!f_a->type()->equivalentTo(t_a->type())) {
			delete func_args;
			delete this_args;
			return FALSE;
		}
	}
	return TRUE;						// punt ??? is this complete???
}

char * FunctionDeclarator::
signature ()
{
	StringHeaper * bufP = new StringHeaper("F",20);

	if (myArgList) {
		bufP->strCat(myArgList->signature());
	} else {
		bufP->strCat("v");
	}

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
} 

Dname * FunctionDeclarator::
dname ()
{
	return myDecl->dname();
}

AbstractDeclarator * FunctionDeclarator::
returnAbstract ()
{
	return NULL;
}

AbstractDeclarator * FunctionDeclarator::
abstract ()
{
	return new FunctionAbstractDeclarator (
		myDecl->abstract(),
		myLp,
		(myArgList) ? myArgList->abstractArgumentList() : NULL,
		myRp,
		myQualList
	);
}

BooleanVar FunctionDeclarator::
isPtrToFunction ()
{
	return myDecl->firstToken()->stringEq("(");
}

FunctionDeclarator * FunctionDeclarator::
functionDeclarator ()
{
	return this->isPtrToFunction() ? NULL : this;
}

Declarator * FunctionDeclarator::
variableDeclarator ()
{
	return this->isPtrToFunction() ? this : NULL;
}

BooleanVar FunctionDeclarator::
declaresFunction ()
{
	return this->isPtrToFunction() ? FALSE : TRUE;
}

BooleanVar FunctionDeclarator::
declaresVariable ()
{
	return this->isPtrToFunction() ? TRUE : FALSE;
}

BooleanVar FunctionDeclarator::
hasPostSpec (Token* t)
{
	if (!t || !myQualList) {
		return FALSE;
	}
	if (t->stringEq("const")) {
		return myQualList->hasConst();
	}
	if (t->stringEq("volatile")) {
		return myQualList->hasVolatile();
	}
	return FALSE;
}

Iterator * FunctionDeclarator::
arguments ()
{
	return myArgList ? myArgList->arguments() : new Iterator();
}

Declarator * FunctionDeclarator::
getDecl ()
{
	return this;
}

DEFINE_CLASS(FunctionDefinition,Function);

FunctionDefinition::
FunctionDefinition 
	(DeclSpecifiers* a1,Declarator* a2,CtorInitializer* a3,
	CompoundStatement* a4) 
{
	mySpecs		= a1;
	myDecl		= a2;
	myCtorInit	= a3;
	myBody		= a4;
}

void FunctionDefinition::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "FunctionDefinition\n";
	if (mySpecs)	oo << mySpecs;
					oo << myDecl;
	if (myCtorInit)	oo << myCtorInit;
					oo << myBody;
	margin (oo,L);
}

Token * FunctionDefinition::
firstToken ()
{
	return FIRST_FOR_2(mySpecs,myDecl);
}

Token * FunctionDefinition::
lastToken ()
{
	return myBody->lastToken();
}

Declarator * FunctionDefinition::
declarator ()
{
	return myDecl;
}

FunctionDeclarator * FunctionDefinition::
functionDeclarator ()
{
	return myDecl->functionDeclarator();
}

DeclSpecifiers * FunctionDefinition::
declSpecifiers ()
{
	return mySpecs;
}

CompoundStatement * FunctionDefinition::
body ()
{
	return myBody;
}

/*
This is a simplification of the ARM spec.
It does not recognize nested blocks.
*/

MetaDeclaration * FunctionDefinition::
declarationOf (Name * n)
{
	Program *	pgm	= this->progPtr();
	Thread *	thr	= pgm->argDeclarations()->contentsOf(myDecl);
	Segment *	s	= thr->first();
	Segment *	end	= thr->last();
	int			pos = n->firstPos();

	if (! myBody->contains(n)) {
		return NULL;
	}
	for (; s; s = (s==end) ? NULL : s->next()) { 
		if (((ArgumentDeclaration*)s) -> declares(n) ) {
			delete thr;
			return (ArgumentDeclaration*)s;
		}
	}
	delete thr;

	thr	= pgm->declThread()->contentsOf(myBody);
	s	= thr->first();
	end	= thr->last();

	for (; s; s = (s==end) ? NULL : s->next()) { 
		if ( s->lastPos() < pos && ((Declaration*)s) -> declares(n) ) {
			delete thr;
			return (Declaration*)s;
		}
	}
	delete thr;
	return NULL;
}

Iterator * FunctionDefinition::
candidatesFor (Name * n)
{
	Program *		pgm	= this->progPtr();
	Thread *		thr	= pgm->declThread()->contentsOf(myBody);
	Segment *		s	= thr->first();
	Segment *		end	= thr->last();
	Iterator *		ret = new Iterator();
	Declaration *	decl;

	for (; s; s = (s==end) ? NULL : s->next()) { 
		decl = (Declaration*)s;
		if (decl->declares(n)) {
			ret->appendSafely(decl->funcDeclarations());
		}
	}
	delete thr;
	return ret;
}

Name * FunctionDefinition::
name ()
{
	return myDecl->dname()->name();
}

BooleanVar FunctionDefinition::
declares (Name * n)
{
	return myDecl->dname()->equivalentTo(n);
}

BooleanVar FunctionDefinition::
hasSpec (Token * t)
{
	return mySpecs ? mySpecs->hasSpec(t) : FALSE;
}

BooleanVar FunctionDefinition::
hasPostSpec (Token* t)
{
	FunctionDeclarator * fd = myDecl->functionDeclarator();

	return fd ? fd->hasPostSpec(t) : FALSE;
}

BooleanVar FunctionDefinition::
isKindOfFunctionDefinition ()
{
	return TRUE;
}

BooleanVar FunctionDefinition::
isDeferred ()
{
	Token * tok = myBody->firstToken();

	if (	tok->stringEq("DEFERRED_FUNC")
		||	tok->stringEq("DEFERRED_SUBR")
	) {
		return TRUE;
	}
	return FALSE;
}

DEFINE_CLASS(FunctionDeclaration,Function);

FunctionDeclaration::
FunctionDeclaration (DeclSpecifiers* a1,Declarator* a2,PostMethodSpecifier* a3)
{
	mySpecs	= a1;
	myDecl	= a2;
	myPost	= a3;

	myDef	= NULL;
}

void FunctionDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "FunctionDeclaration\n";
	if (mySpecs)	oo << mySpecs;
					oo << myDecl;
	if (myPost)		oo << myPost;
	margin (oo,L);
}

void FunctionDeclaration::
copyOn (ostream& oo)
{
	if (mySpecs)	{
		mySpecs->copyOn(oo);
		oo << " ";
	}
	myDecl->copyOn(oo);
	if (myPost)	{
		oo << " ";
		myPost->copyOn(oo);
	}
}

Token * FunctionDeclaration::
firstToken ()
{
	return FIRST_FOR_2(mySpecs,myDecl);
}

Token * FunctionDeclaration::
lastToken ()
{
	return myDecl->lastToken();
}

DeclSpecifiers * FunctionDeclaration::
declSpecifiers ()
{
	return mySpecs;
}

Declarator * FunctionDeclaration::
declarator ()
{
	return myDecl;
} 

Name * FunctionDeclaration::
name ()
{
	return myDecl->dname()->name();
}

CmpList * FunctionDeclaration::
cmpList ()
{
	CmpList * list;

	if (mySpecs) {
		list = mySpecs->cmpList();
		list->append(myDecl->cmpList());
	} else {
		list = myDecl->cmpList();
	}
	if (myPost) {
		list->append(myPost->cmpList());
	}
	return list;
}

FunctionDeclarator * FunctionDeclaration::
functionDeclarator ()
{
	return myDecl->functionDeclarator();
} 

Function * FunctionDeclaration::
definitionIfLocal()
{
	if (myDef) {
		return myDef;
	}

	Iterator * it = this->progPtr()->functionDefs();
	Function * f;

	while (f=(Function*)it->next()) {
		if (f->m_name()->equivalentTo(this->m_name())) {
			myDef = f;
			return myDef;
		}
	}
	myDef = this;
	return myDef;
}

BooleanVar FunctionDeclaration::
isDefinition ()
{
	return FALSE;
} 

BooleanVar FunctionDeclaration::
hasSpec (Token * t)
{
	return mySpecs ? mySpecs->hasSpec(t) : FALSE;
}

BooleanVar FunctionDeclaration::
hasPostSpec (Token* t)
{
	FunctionDeclarator * fd = myDecl->functionDeclarator();

	if (fd && fd->hasPostSpec(t)) {
		return TRUE;
	}
	if (myPost && myPost->hasPostSpec(t)) {
		return TRUE;
	}
	return FALSE;
}


BooleanVar FunctionDeclaration::
isDeferred ()
{
	BooleanVar ret = FALSE;

	if (!myPost) {
		return ret;
	}

	Token *	df	= new Token ("DEFERRED_FUNC",NULL);
	Token * ds	= new Token ("DEFERRED_SUBR",NULL);

	if (	myPost->hasPostSpec(df)
		||	myPost->hasPostSpec(ds)
		||	myPost->isKindOfPureSpecifier()
	) {
		ret = TRUE;
	} 

	delete df;
	delete ds;

	return ret;
}

DEFINE_CLASS(LinkageSpecification,Declaration);

DEFINE_CLASS(SimpleLinkageSpecification,LinkageSpecification);

SimpleLinkageSpecification::
SimpleLinkageSpecification (EXTERN* a1,StringLiteral* a2,Declaration* a3) 
{
	myExt		= a1;
	myString	= a2;
	myDecl		= a3;
}

void SimpleLinkageSpecification::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "SimpleLinkageSpecification\n"
		<< myExt
		<< myString
		<< myDecl
	;
	margin (oo,L);
}

Token * SimpleLinkageSpecification::
firstToken ()
{
	return myExt;
}

Token * SimpleLinkageSpecification::
lastToken ()
{
	return myDecl->lastToken();
}

DEFINE_CLASS(ListLinkageSpecification,LinkageSpecification);

ListLinkageSpecification::
ListLinkageSpecification 
	(EXTERN* a1,StringLiteral* a2,LC* a3,TranslationUnit* a4,RC* a5) 
{
	myExt		= a1;
	myString	= a2;
	myLc		= a3;
	myUnit		= a4;
	myRc		= a5;
}

void ListLinkageSpecification::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ListLinkageSpecification\n";
				oo << myExt;
				oo << myString;
				oo << myLc;
	if (myUnit)	oo << myUnit;
				oo << myRc;
	margin (oo,L);
}

Token * ListLinkageSpecification::
firstToken ()
{
	return myExt;
}

Token * ListLinkageSpecification::
lastToken ()
{
	return myRc;
}

DEFINE_CLASS(ExpressionInitializer,Initializer);

ExpressionInitializer::
ExpressionInitializer (EQUALS* a1,Expression* a2) 
{
	myEq	= a1;
	myExp	= a2;
}

void ExpressionInitializer::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ExpressionInitializer\n"
		<< myEq
		<< myExp
	;
	margin (oo,L);
}

Token * ExpressionInitializer::
firstToken ()
{
	return myEq;
}

Token * ExpressionInitializer::
lastToken ()
{
	return myExp->lastToken();
}

EQUALS * ExpressionInitializer::
equals ()
{
	return myEq;
}

Expression * ExpressionInitializer::
expression ()
{
	return myExp;
}

DEFINE_CLASS(CurlyInitializer,Initializer);

CurlyInitializer::
CurlyInitializer (EQUALS* a1,LC* a2,InitializerList* a3,COMMA* a4,RC* a5) 
{
	myEq	= a1;
	myLc	= a2;
	myList	= a3;
	myCm	= a4;
	myRc	= a5;
}

void CurlyInitializer::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "CurlyInitializer\n";
				oo << myEq;
				oo << myLc;
				oo << myList;
	if (myCm)	oo << myCm;
				oo << myRc;
	margin (oo,L);
}

Token * CurlyInitializer::
firstToken ()
{
	return myEq;
}

Token * CurlyInitializer::
lastToken ()
{
	return myRc;
}

EQUALS * CurlyInitializer::
equals ()
{
	return myEq;
}

DEFINE_CLASS(ParenInitializer,Initializer);

ParenInitializer::
ParenInitializer (LC* a1,ExpressionList* a2,RC* a3) 
{
	myLp	= a1;
	myList	= a2;
	myRp	= a3;
}

void ParenInitializer::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ParenInitializer\n"
		<< myLp
		<< myList
		<< myRp
	;
	margin (oo,L);
}

Token * ParenInitializer::
firstToken ()
{
	return myLp;
}

Token * ParenInitializer::
lastToken ()
{
	return myRp;
}

DEFINE_CLASS(InitDeclarator,DeclaratorList);

InitDeclarator::
InitDeclarator (Declarator* a1,Initializer* a2) 
{
	myDecl	= a1;
	myInit	= a2;
}

void InitDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "InitDeclarator\n";
				oo << myDecl;
	if (myInit)	oo << myInit;
	margin (oo,L);
}

Token * InitDeclarator::
firstToken ()
{
	return myDecl->firstToken();
}

Token * InitDeclarator::
lastToken ()
{
	return LAST_FOR_2(myInit,myDecl);
}

BooleanVar InitDeclarator::
declares (Name * n)
{
	return myDecl->dname()->equivalentTo(n);
}

Declarator * InitDeclarator::
declOf (Name * n) 
{
	return (this->declares(n)) ? myDecl : NULL;
}

Declarator * InitDeclarator::
getDecl ()
{
	return myDecl;
}

DeclaratorList * InitDeclarator::
fetchList ()
{
	return NULL;
}

BooleanVar InitDeclarator::
declaresFunction ()
{
	return myDecl->declaresFunction();
}

BooleanVar InitDeclarator::
declaresVariable ()
{
	return myDecl->declaresVariable();
}

FunctionDeclarator * InitDeclarator::
functionDeclarator ()
{
	return myDecl->functionDeclarator();
}

DEFINE_CLASS(ActualDeclaratorList,DeclaratorList);

ActualDeclaratorList::
ActualDeclaratorList (DeclaratorList* a1,COMMA* a2,InitDeclarator* a3) 
{
	myList	= a1;
	myCm	= a2;
	myDecl	= a3;
}

void ActualDeclaratorList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ActualDeclaratorList\n"
		<< myList
		<< myCm
		<< myDecl
	;
	margin (oo,L);
}

Token * ActualDeclaratorList::
firstToken ()
{
	return myList->firstToken();
}

Token * ActualDeclaratorList::
lastToken ()
{
	return myDecl->lastToken();
}

Declarator * ActualDeclaratorList::
getDecl ()
{
	return myDecl->getDecl();
}

DeclaratorList * ActualDeclaratorList::
fetchList ()
{
	return myList;
}

BooleanVar ActualDeclaratorList::
declares (Name* n)
{
	return myDecl->declares(n) ? TRUE : myList->declares(n);
}

Declarator * ActualDeclaratorList::
declOf (Name * n) 
{
	Declarator * ret = myDecl->declOf(n);
	return ret ? ret : myList->declOf(n);
}

DEFINE_CLASS(IdEnumerator,Enumerator);

IdEnumerator::
IdEnumerator (IDENTIFIER* a1) 
{
	myId	= a1;
}

void IdEnumerator::
printOn (ostream& oo)
{
	margin (oo,R);
/*
	oo
		<< "IdEnumerator\n"
		<< myId
	;
*/
	oo << "IdEnumerator <";
	myId->copyOn(oo);
	oo << ">\n";

	margin (oo,L);
}

Token * IdEnumerator::
firstToken ()
{
	return myId;
}

Token * IdEnumerator::
lastToken ()
{
	return myId;
}

BooleanVar IdEnumerator::
declares (Name * n)
{
	return n ? n->equivalentTo(myId) : FALSE;
}

DEFINE_CLASS(EqEnumerator,Enumerator);

EqEnumerator::
EqEnumerator (IDENTIFIER* a1,EQUALS* a2,ConditionalExpression* a3) 
{
	myId	= a1;
	myEq	= a2;
	myExp	= a3;
}

void EqEnumerator::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "EqEnumerator\n"
		<< myId
		<< myEq
		<< myExp
	;
	margin (oo,L);
}

Token * EqEnumerator::
firstToken ()
{
	return myId;
}

Token * EqEnumerator::
lastToken ()
{
	return myExp->lastToken();
}

BooleanVar EqEnumerator::
declares (Name * n)
{
	return n ? n->equivalentTo(myId) : FALSE;
}

DEFINE_CLASS(ActualEnumList,EnumList);

ActualEnumList::
ActualEnumList (EnumList* a1,COMMA* a2,Enumerator* a3) 
{
	myList	= a1;
	myCm	= a2;
	myEnum	= a3;
}

void ActualEnumList::
printOn (ostream& oo)
{
/*
	margin (oo,R);
	oo
		<< "ActualEnumList\n"
		<< myList
		<< myCm
		<< myEnum
	;
	margin (oo,L);
*/
	oo
		<< myList
		<< myCm
		<< myEnum
	;
}

Token * ActualEnumList::
firstToken ()
{
	return myList->firstToken();
}

Token * ActualEnumList::
lastToken ()
{
	return myEnum->lastToken();
}

BooleanVar ActualEnumList::
declares (Name * n)
{
	return (myEnum->declares(n) || myList->declares(n)) ? TRUE : FALSE;
}

DEFINE_CLASS(ActualDeclarationList,DeclarationList);

ActualDeclarationList::
ActualDeclarationList (DeclarationList* a1,Declaration* a2) 
{
	myList	= a1;
	myDecl	= a2;
}

void ActualDeclarationList::
printOn (ostream& oo)
{
/*
	margin (oo,R);
	oo
		<< "ActualDeclarationList\n"
		<< myList
		<< myDecl
	;
	margin (oo,L);
*/
	oo
		<< myList
		<< myDecl
	;
}

Token * ActualDeclarationList::
firstToken ()
{
	return myList->firstToken();
}

Token * ActualDeclarationList::
lastToken ()
{
	return myDecl->lastToken();
}

StatementList * ActualDeclarationList::
makeStatementList ()
{
	return new ActualStatementList (
		myList->makeStatementList(),
		new DeclarationStatement(myDecl)
	);
}

DeclarationList * ActualDeclarationList::
declList ()
{
	return myList;
}

Declaration * ActualDeclarationList::
decl ()
{
	return myDecl;
}

DEFINE_CLASS(SimplePtrOperator,PtrOperator);

SimplePtrOperator::
SimplePtrOperator (PTR_OP* a1,CvQualifierList* a2) 
{
	myPtrOp		= a1;
	myQualList	= a2;
}

SimplePtrOperator::
SimplePtrOperator (Segment * seg)
{
	myPtrOp		= new Token ("*",seg);
	myQualList	= NULL;
}

void SimplePtrOperator::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "SimplePtrOperator\n";
					oo << myPtrOp;
	if (myQualList)	oo << myQualList;
	margin (oo,L);
}

Token * SimplePtrOperator::
firstToken ()
{
	return myPtrOp;
}

Token * SimplePtrOperator::
lastToken ()
{
	return LAST_FOR_2(myQualList,myPtrOp);
}

char * SimplePtrOperator::
signature ()
{
	StringHeaper * bufP = new StringHeaper(4,4);

	if (myQualList)	{
		if (myQualList->hasConst())		{ bufP->strCat("C"); }
		if (myQualList->hasVolatile())	{ bufP->strCat("V"); }
	}

	if (myPtrOp->stringEq("*"))	{ bufP->strCat("P"); } else
	if (myPtrOp->stringEq("&"))	{ bufP->strCat("R"); }

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
}

DEFINE_CLASS(ClassPtrOperator,PtrOperator);


ClassPtrOperator::
ClassPtrOperator (CompleteClassName* a1,C_COLON* a2,ASTERIX* a3,
					CvQualifierList* a4) 
{
	myName		= a1;
	myCCl		= a2;
	myStar		= a3;
	myQualList	= a4;
}

void ClassPtrOperator::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "ClassPtrOperator\n";
					oo << myName;
					oo << myCCl;
					oo << myStar;
	if (myQualList)	oo << myQualList;
	margin (oo,L);
}

Token * ClassPtrOperator::
firstToken ()
{
	return myName->firstToken();
}

Token * ClassPtrOperator::
lastToken ()
{
	return LAST_FOR_2(myQualList,myStar);
}

char * ClassPtrOperator::
signature ()
{
	StringHeaper * bufP = new StringHeaper(20,20);

	if (myQualList)	{
		if (myQualList->hasConst())		{ bufP->strCat("C"); }
		if (myQualList->hasVolatile())	{ bufP->strCat("V"); }
	}
	bufP->strCat(myName->signature());

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
}

DEFINE_CLASS(AbstractArgumentDeclaration,ArgumentDeclaration);

AbstractArgumentDeclaration::
AbstractArgumentDeclaration (DeclSpecifiers* a1,AbstractDeclarator* a2) 
{
	mySpecs	= a1;
	myAbs	= a2;
}

void AbstractArgumentDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "AbstractArgumentDeclaration\n";
				oo << mySpecs;
	if (myAbs)	oo << myAbs;
	margin (oo,L);
}

Token * AbstractArgumentDeclaration::
firstToken ()
{
	return mySpecs->firstToken();
}

Token * AbstractArgumentDeclaration::
lastToken ()
{
	return LAST_FOR_2(myAbs,mySpecs);
}

ArgumentDeclaration * AbstractArgumentDeclaration::
initializeWith (Initializer* a1)
{
	return new AbstractInitArgumentDeclaration
		(mySpecs,myAbs,a1->equals(),a1->expression());
}

ArgDeclarationList * AbstractArgumentDeclaration::
abstractArgList ()
{
	return this;
}

Name * AbstractArgumentDeclaration::
name ()
{
	return NULL;
}

TypeName * AbstractArgumentDeclaration::
type ()
{
	return new TypeName (
		mySpecs->typeSpecifierList(),
		myAbs
	);
}

DEFINE_CLASS(AbstractInitArgumentDeclaration,ArgumentDeclaration);

AbstractInitArgumentDeclaration::
AbstractInitArgumentDeclaration 
	(DeclSpecifiers* a1,AbstractDeclarator* a2,EQUALS* a3,Expression* a4) 
{
	mySpecs	= a1;
	myAbs	= a2;
	myEq	= a3;
	myExp	= a4;
}

void AbstractInitArgumentDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "AbstractInitArgumentDeclaration\n";
				oo << mySpecs;
	if (myAbs)	oo << myAbs;
				oo << myEq;
				oo << myExp;
	margin (oo,L);
}

Token * AbstractInitArgumentDeclaration::
firstToken ()
{
	return mySpecs->firstToken();
}

Token * AbstractInitArgumentDeclaration::
lastToken ()
{
	return myExp->lastToken();
}

ArgDeclarationList * AbstractInitArgumentDeclaration::
abstractArgList ()
{
	return this;
}

Expression * AbstractInitArgumentDeclaration::
defaultInit ()
{
	return myExp;
}

Name * AbstractInitArgumentDeclaration::
name ()
{
	return NULL;
}

TypeName * AbstractInitArgumentDeclaration::
type ()
{
	return new TypeName (
		mySpecs->typeSpecifierList(),
		myAbs
	);
}

DEFINE_CLASS(SimpleArgumentDeclaration,ArgumentDeclaration);

SimpleArgumentDeclaration::
SimpleArgumentDeclaration (DeclSpecifiers* a1,Declarator* a2) 
{
	mySpecs	= a1;
	myDecl	= a2;
}

void SimpleArgumentDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "SimpleArgumentDeclaration\n"
		<< mySpecs
		<< myDecl
	;
	margin (oo,L);
}

Token * SimpleArgumentDeclaration::
firstToken ()
{
	return mySpecs->firstToken();
}

Token * SimpleArgumentDeclaration::
lastToken ()
{
	return myDecl->lastToken();
}

ArgumentDeclaration * SimpleArgumentDeclaration::
initializeWith (Initializer* a1)
{
	return new InitArgumentDeclaration
		(mySpecs,myDecl,a1->equals(),a1->expression());
}

ArgDeclarationList * SimpleArgumentDeclaration::
abstractArgList ()
{
	return new AbstractArgumentDeclaration (
		mySpecs,
		myDecl->abstract()
	);
}

TypeName * SimpleArgumentDeclaration::
typeOf (Name* n)
{
	if (myDecl->dname()->equivalentTo(n)) {
		return this->type();
	}
	return NULL;
}

TypeName * SimpleArgumentDeclaration::
type ()
{
	return new TypeName (
		mySpecs->typeSpecifierList(),
		myDecl->abstract()
	);
}

Name * SimpleArgumentDeclaration::
name ()
{
	return myDecl->dname()->name();
}

BooleanVar SimpleArgumentDeclaration::
declares (Name * n)
{
	return myDecl->dname()->equivalentTo(n);
}

DEFINE_CLASS(InitArgumentDeclaration,ArgumentDeclaration);

InitArgumentDeclaration::
InitArgumentDeclaration 
	(DeclSpecifiers* a1,Declarator* a2,EQUALS* a3,Expression* a4) 
{
	mySpecs	= a1;
	myDecl	= a2;
	myEq	= a3;
	myExp	= a4;
}

void InitArgumentDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "InitArgumentDeclaration\n"
		<< mySpecs
		<< myDecl
		<< myEq
		<< myExp
	;
	margin (oo,L);
}

Token * InitArgumentDeclaration::
firstToken ()
{
	return  mySpecs->firstToken();
}

Token * InitArgumentDeclaration::
lastToken ()
{
	return myExp -> lastToken();
}

ArgDeclarationList * InitArgumentDeclaration::
abstractArgList ()
{
	return new AbstractInitArgumentDeclaration (
		mySpecs,
		myDecl->abstract(),
		myEq,
		myExp
	);
}

BooleanVar InitArgumentDeclaration::
declares (Name * n)
{
	return myDecl->dname()->equivalentTo(n);
}

Expression * InitArgumentDeclaration::
defaultInit ()
{
	return myExp;
}

TypeName * InitArgumentDeclaration::
typeOf (Name* n)
{
	if (myDecl->dname()->equivalentTo(n)) {
		return this->type();
	}
	return NULL;
}

TypeName * InitArgumentDeclaration::
type ()
{
	return new TypeName (
		mySpecs->typeSpecifierList(),
		myDecl->abstract()
	);
}

Name * InitArgumentDeclaration::
name ()
{
	return myDecl->dname()->name();
}

DEFINE_CLASS(PseudoArgumentDeclaration,ArgumentDeclaration);

PseudoArgumentDeclaration::
PseudoArgumentDeclaration (Token* t)
{
	myTok = t;
}

void PseudoArgumentDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "PseudoArgumentDeclaration\n"
		<< myTok
	;
	margin (oo,L);
}

Token * PseudoArgumentDeclaration::
firstToken ()
{
	return myTok;
}

Token * PseudoArgumentDeclaration::
lastToken ()
{
	return myTok;
}

BooleanVar PseudoArgumentDeclaration::
isOutMarker ()
{
	return myTok->stringEq("OUT");
}

ArgDeclarationList * PseudoArgumentDeclaration::
abstractArgList ()
{
	return this;
}

TypeName * PseudoArgumentDeclaration::
type ()
{
	return NULL;
}

Name * PseudoArgumentDeclaration::
name ()
{
	return NULL; 
}

DEFINE_CLASS(ActualArgDeclarationList,ArgDeclarationList);

ActualArgDeclarationList::
ActualArgDeclarationList 
	(ArgDeclarationList* a1,COMMA* a2,ArgumentDeclaration* a3) 
{
	myList	= a1;
	myCm	= a2;
	myDecl	= a3;
}

void ActualArgDeclarationList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ActualArgDeclarationList\n"
		<< myList
		<< myCm
		<< myDecl
	;
	margin (oo,L);
}

Token * ActualArgDeclarationList::
firstToken ()
{
	return myList->firstToken();
}

Token * ActualArgDeclarationList::
lastToken ()
{
	return myDecl->lastToken();
}

ArgDeclarationList * ActualArgDeclarationList::
abstractArgList ()
{
	return new ActualArgDeclarationList (
		myList->abstractArgList(),
		myCm,
		(ArgumentDeclaration*)myDecl->abstractArgList()
	);
}

Iterator * ActualArgDeclarationList::
arguments ()
{
	Iterator * args = myList->arguments();
	args->append(myDecl->arguments());
	return args;
}

DEFINE_CLASS(SimpleArgumentDeclarationList,ArgumentDeclarationList);

SimpleArgumentDeclarationList::
SimpleArgumentDeclarationList (ArgDeclarationList* a1,ELLIPSIS* a2) 
{
	myList	= a1;
	myDots	= a2;
}

void SimpleArgumentDeclarationList::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "SimpleArgumentDeclarationList\n";
	if (myList)	oo << myList;
	if (myDots)	oo << myDots;
	margin (oo,L);
}

Token * SimpleArgumentDeclarationList::
firstToken ()
{
	return FIRST_FOR_2(myList,myDots);
}

Token * SimpleArgumentDeclarationList::
lastToken ()
{
	return LAST_FOR_2(myDots,myList);
}

ArgumentDeclarationList * SimpleArgumentDeclarationList::
abstractArgumentList ()
{
	return new SimpleArgumentDeclarationList (
		(myList) ? myList->abstractArgList() : NULL,
		myDots
	);
}

ArgDeclarationList * SimpleArgumentDeclarationList::
argDeclarationList ()
{
	return myList;
}

Token * SimpleArgumentDeclarationList::
ellipsis ()
{
	return myDots;
}

DEFINE_CLASS(CommaArgumentDeclarationList,ArgumentDeclarationList);

CommaArgumentDeclarationList::
CommaArgumentDeclarationList (ArgDeclarationList* a1,COMMA* a2,ELLIPSIS* a3) 
{
	myList	= a1;
	myCm	= a2;
	myDots	= a3;
}

void CommaArgumentDeclarationList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "CommaArgumentDeclarationList\n"
		<< myList
		<< myCm
		<< myDots
	;
	margin (oo,L);
}

Token * CommaArgumentDeclarationList::
firstToken ()
{
	return myList->firstToken();
}

Token * CommaArgumentDeclarationList::
lastToken ()
{
	return myDots;
}

ArgumentDeclarationList * CommaArgumentDeclarationList::
abstractArgumentList ()
{
	return new SimpleArgumentDeclarationList (
		myList->abstractArgList(),
		myDots
	);
}

ArgDeclarationList * CommaArgumentDeclarationList::
argDeclarationList ()
{
	return myList;
}


Token * CommaArgumentDeclarationList::
ellipsis ()
{
	return myDots;
}

DEFINE_CLASS(PtrOpDeclarator,Declarator);

PtrOpDeclarator::
PtrOpDeclarator (PtrOperator* a1,Declarator* a2) 
{
	myPtrOp	= a1;
	myDecl	= a2;
}

void PtrOpDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "PtrOpDeclarator\n"
		<< myPtrOp
		<< myDecl
	;
	margin (oo,L);
}

Token * PtrOpDeclarator::
firstToken ()
{
	return myPtrOp->firstToken();
}

Token * PtrOpDeclarator::
lastToken ()
{
	return myDecl->lastToken();
}

Dname * PtrOpDeclarator::
dname ()
{
	return myDecl->dname();
}

AbstractDeclarator * PtrOpDeclarator::
abstract ()
{
	AbstractDeclarator * abs = myDecl->abstract();
	return new PtrOpAbstractDeclarator (myPtrOp,abs);
}

AbstractDeclarator * PtrOpDeclarator::
returnAbstract ()
{
	return new PtrOpAbstractDeclarator (
		myPtrOp,
		myDecl->returnAbstract()
	);
}

BooleanVar PtrOpDeclarator::
declaresFunction ()
{
	return myDecl->declaresFunction();
}

BooleanVar PtrOpDeclarator::
declaresVariable ()
{
	return myDecl->declaresVariable();
}

FunctionDeclarator * PtrOpDeclarator::
functionDeclarator ()
{
	return myDecl->functionDeclarator();
}

DEFINE_CLASS(ArrayDeclarator,Declarator);

ArrayDeclarator::
ArrayDeclarator (Declarator* a1,LB* a2,ConditionalExpression* a3,RB* a4) 
{
	myDecl	= a1;
	myLb	= a2;
	myExp	= a3;
	myRb	= a4;
}

void ArrayDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ArrayDeclarator\n";
				oo << myDecl;
				oo << myLb;
	if (myExp)	oo << myExp;
				oo << myRb;
	margin (oo,L);
}

Token * ArrayDeclarator::
firstToken ()
{
	return myDecl->firstToken();
}

Token * ArrayDeclarator::
lastToken ()
{
	return myRb;
}

AbstractDeclarator * ArrayDeclarator::
abstract ()
{
	return new ArrayAbstractDeclarator (
		myDecl->abstract(),
		myLb,
		myExp,
		myRb
	);
}

Dname* ArrayDeclarator::
dname ()
{
	return myDecl->dname();
}

BooleanVar ArrayDeclarator::
declaresFunction ()
{
	return myDecl->declaresFunction();
}

BooleanVar ArrayDeclarator::
declaresVariable ()
{
	return myDecl->declaresVariable();
}

FunctionDeclarator * ArrayDeclarator::
functionDeclarator ()
{
	return myDecl->functionDeclarator();
}

DEFINE_CLASS(ParenDeclarator,Declarator);

ParenDeclarator::
ParenDeclarator (LP* a1,Declarator* a2,RP* a3) 
{
	myLp	= a1;
	myDecl	= a2;
	myRp	= a3;
}

void ParenDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ParenDeclarator\n"
		<< myLp
		<< myDecl
		<< myRp
	;
	margin (oo,L);
}
 
Token * ParenDeclarator::
firstToken ()
{
	return myLp;
}

Token * ParenDeclarator::
lastToken ()
{
	return myRp;
}

AbstractDeclarator * ParenDeclarator::
abstract ()
{
	return new ParenAbstractDeclarator (
		myLp,
		myDecl->abstract(),
		myRp
	);
}

Dname * ParenDeclarator::
dname ()
{
	return myDecl->dname();
}

BooleanVar ParenDeclarator::
declaresFunction ()
{
	return myDecl->declaresFunction();
}

BooleanVar ParenDeclarator::
declaresVariable ()
{
	return myDecl->declaresVariable();
}

FunctionDeclarator * ParenDeclarator::
functionDeclarator ()
{
	return myDecl->functionDeclarator();
}

DEFINE_CLASS(PtrOpAbstractDeclarator,AbstractDeclarator);

PtrOpAbstractDeclarator::
PtrOpAbstractDeclarator (PtrOperator* a1,AbstractDeclarator* a2) 
{
	myPtrOp	= a1;
	myAbs	= a2;
}

void PtrOpAbstractDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "PtrOpAbstractDeclarator\n";
				oo << myPtrOp;
	if (myAbs)	oo << myAbs;
	margin (oo,L);
}

void PtrOpAbstractDeclarator::
copyOn (ostream& oo)
{
				myPtrOp	-> copyOn(oo);
	if (myAbs)	myAbs	-> copyOn(oo);
}

Token * PtrOpAbstractDeclarator::
firstToken ()
{
	return myPtrOp->firstToken();
}

Token * PtrOpAbstractDeclarator::
lastToken ()
{
	return LAST_FOR_2(myAbs,myPtrOp);
}

CmpList * PtrOpAbstractDeclarator::
cmpList ()
{
	CmpList * list = myPtrOp->cmpList(); 
	if (myAbs) list->append(myAbs->cmpList());
	return list;
}

AbstractDeclarator * PtrOpAbstractDeclarator::
applyIndirection (AbstractDeclarator* a1)
{
	if (!a1) {
		return this;
	}

	if (a1->isPrefixable()) {
		return a1->prefixWith (
			new ParenAbstractDeclarator (
				new Token ("(",this),
				this,
				new Token (")",this)
			)
		);
	}
	if (myAbs) {
		return new PtrOpAbstractDeclarator (
			myPtrOp,
			myAbs->applyIndirection(a1)
		);
	}
	return new PtrOpAbstractDeclarator (myPtrOp,a1);
}

char * PtrOpAbstractDeclarator::
signature ()
{
	StringHeaper *  bufP = new StringHeaper(myPtrOp->signature(),20);

	if (myAbs) {
		bufP->strCat(myAbs->signature());
	}
	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
} 

BooleanVar PtrOpAbstractDeclarator::
isPointer ()
{
	return TRUE;
}

AbstractDeclarator * PtrOpAbstractDeclarator::
resolved ()
{
	if (myPtrOp->stringEq("&")) {
		return myAbs ? myAbs->resolved() : NULL;
	}
	return new PtrOpAbstractDeclarator (
		myPtrOp,
		myAbs ? myAbs->resolved() : NULL
	);
}

AbstractDeclarator * PtrOpAbstractDeclarator::
dereferenced ()
{
	return myAbs;
}

DEFINE_CLASS(FunctionAbstractDeclarator,AbstractDeclarator);

FunctionAbstractDeclarator::
FunctionAbstractDeclarator 
	(AbstractDeclarator* a1,LP* a2,ArgumentDeclarationList* a3,RP* a4,
		CvQualifierList* a5) 
{
	myAbs		= a1;
	myLp		= a2;
	myArgList	= a3;
	myRp		= a4;
	myQualList	= a5;
}

void FunctionAbstractDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "FunctionAbstractDeclarator\n";
	if (myAbs)		oo << myAbs;
					oo << myLp;
	if (myArgList)	oo << myArgList;
					oo << myRp;
	if (myQualList)	oo << myQualList;
	margin (oo,L);
}

void FunctionAbstractDeclarator::
copyOn (ostream& oo)
{
	if (myAbs)		myAbs		-> copyOn(oo);
					myLp		-> copyOn(oo);
	if (myArgList)	myArgList	-> copyOn(oo);
					myRp		-> copyOn(oo);
	if (myQualList)	myQualList	-> copyOn(oo);
}

Token * FunctionAbstractDeclarator::
firstToken ()
{
	return FIRST_FOR_2(myAbs,myLp);
}

Token * FunctionAbstractDeclarator::
lastToken ()
{
	return LAST_FOR_2(myQualList,myRp);
}

CmpList * FunctionAbstractDeclarator::
cmpList ()
{
	CmpList * list;

	if (myAbs) {
		list = myAbs->cmpList();
		list->append(myLp->cmpList());
	} else {
		list = myLp->cmpList();
	}
	if (myArgList)	list->append(myArgList	-> cmpList());
					list->append(myRp		-> cmpList());
	if (myQualList)	list->append(myQualList	-> cmpList());

	return list;
}

Declarator * FunctionAbstractDeclarator::
concretizeWith (Declarator * d)
{
	Declarator * decl = myAbs ? myAbs->concretizeWith(d) : d;

	return new FunctionDeclarator (
		decl,
		myLp,
		myArgList,
		myRp,
		myQualList
	); 
}

AbstractDeclarator * FunctionAbstractDeclarator::
prefixWith (AbstractDeclarator * a)
{
	if (myAbs) {
		return myAbs->prefixWith(a);
	} else {
		return new FunctionAbstractDeclarator (
			a,
			myLp,
			myArgList,
			myRp,
			myQualList
		);
	}
}

BooleanVar FunctionAbstractDeclarator::
isPrefixable ()
{
	return TRUE;
}

char * FunctionAbstractDeclarator::
signature ()
{
	StringHeaper *  bufP = new StringHeaper(20,20);

	if (myAbs) {
		bufP->strCat(myAbs->signature());
	}
	if (myQualList)	{
		if (myQualList->hasConst())		{ bufP->strCat("C"); }
		if (myQualList->hasVolatile())	{ bufP->strCat("V"); }
	}

	bufP->strCat("F");

	if (myArgList) {
		bufP->strCat(myArgList->signature());
	} else {
		bufP->strCat("v");
	}

	bufP->strCat("_");

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
}

AbstractDeclarator * FunctionAbstractDeclarator::
dereferenced ()
{
	return new FunctionAbstractDeclarator (
		NULL,
		myLp,
		myArgList,
		myRp,
		myQualList
	);
}

DEFINE_CLASS(ArrayAbstractDeclarator,AbstractDeclarator);

ArrayAbstractDeclarator::
ArrayAbstractDeclarator 
	(AbstractDeclarator* a1,LB* a2,ConditionalExpression* a3,RB* a4) 
{
	myAbs	= a1;
	myLb	= a2;
	myExp	= a3;
	myRb	= a4;
}

void ArrayAbstractDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ArrayAbstractDeclarator\n";
	if (myAbs)	oo << myAbs;
				oo << myLb;
	if (myExp)	oo << myExp;
				oo << myRb;
	margin (oo,L);
}

void ArrayAbstractDeclarator::
copyOn (ostream& oo)
{
	if (myAbs)	myAbs	-> copyOn(oo);
				myLb	-> copyOn(oo);
	if (myExp)	myExp	-> copyOn(oo);
				myRb	-> copyOn(oo);
}

Token * ArrayAbstractDeclarator::
firstToken ()
{
	return FIRST_FOR_2(myAbs,myLb);
}

Token * ArrayAbstractDeclarator::
lastToken ()
{
	return myRb;
}

CmpList * ArrayAbstractDeclarator::
cmpList ()
{
	CmpList * list;

	if (myAbs) {
		list = myAbs->cmpList();
		list->append(myLb->cmpList());
	} else {
		list = myLb->cmpList();
	}
	if (myExp)	list->append(myExp	-> cmpList());
				list->append(myRb	-> cmpList());
	return list;
}

Declarator * ArrayAbstractDeclarator::
concretizeWith (Declarator * d)
{
	Declarator * decl = myAbs ? myAbs->concretizeWith(d) : d;
	return new ArrayDeclarator (decl, myLb, myExp, myRb); 
}

AbstractDeclarator * ArrayAbstractDeclarator::
prefixWith (AbstractDeclarator * a)
{
	if (myAbs) {
		return myAbs->prefixWith(a);
	} else {
		return new ArrayAbstractDeclarator (a, myLb, myExp, myRb);
	}
}

BooleanVar ArrayAbstractDeclarator::
isPrefixable ()
{
	return TRUE;
}

char * ArrayAbstractDeclarator::
signature ()
{
	StringHeaper *  bufP = new StringHeaper(20,20);

	if (myAbs) {
		bufP->strCat(myAbs->signature());
	}

	bufP->strCat("A");

	if (myExp) {
		bufP->strCat(myExp->asString());	// what if it is not a
	}											// simple int ??? punt ?

	bufP->strCat("_");

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
}

AbstractDeclarator * ArrayAbstractDeclarator::
resolved ()
{
	return new PtrOpAbstractDeclarator (
		new SimplePtrOperator (new Token("*",myRb), NULL),
		myAbs
	);
}

AbstractDeclarator * ArrayAbstractDeclarator::
dereferenced ()
{
	return myAbs;
}

DEFINE_CLASS(ParenAbstractDeclarator,AbstractDeclarator);

ParenAbstractDeclarator::
ParenAbstractDeclarator (LP* a1,AbstractDeclarator* a2,RP* a3) 
{
	myLp	= a1;
	myAbs	= a2;
	myRp	= a3;
}

void ParenAbstractDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ParenAbstractDeclarator\n"
		<< myLp
		<< myAbs
		<< myRp
	;
	margin (oo,L);
}

void ParenAbstractDeclarator::
copyOn (ostream& oo)
{
	myLp	-> copyOn(oo);
	myAbs	-> copyOn(oo);
	myRp	-> copyOn(oo);
}

Token * ParenAbstractDeclarator::
firstToken ()
{
	return myLp;
}

Token * ParenAbstractDeclarator::
lastToken ()
{
	return myRp;
}

CmpList * ParenAbstractDeclarator::
cmpList ()
{
	CmpList * list = myLp->cmpList(); 

	list->append(myAbs	->cmpList());
	list->append(myRp	->cmpList());

	return list;
}

char * ParenAbstractDeclarator::
signature ()
{
	return myAbs->signature();
}

DEFINE_CLASS(ConversionTypeName,Complex);

ConversionTypeName::
ConversionTypeName (TypeSpecifierList* a1,PtrOperator* a2) 
{
	myTSL	= a1;
	myPtrOp	= a2;
}

void ConversionTypeName::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "ConversionTypeName\n";
					oo << myTSL;
	if (myPtrOp)	oo << myPtrOp;
	margin (oo,L);
}

Token * ConversionTypeName::
firstToken ()
{
	return myTSL->firstToken();
}

Token * ConversionTypeName::
lastToken ()
{
	return LAST_FOR_2(myPtrOp,myTSL);
}

char * ConversionTypeName::
signature ()
{
	StringHeaper *  bufP = new StringHeaper(20,20);

	if (myPtrOp) {
		bufP->strCat(myPtrOp->signature());
	}
	bufP->strCat(myTSL->signature());

	char * ret = bufP->asCharP();
	delete bufP;
	return ret;
}

ClassSpecifier * ConversionTypeName::
classForType ()
{
	TypeSpecifier * ts = 
		myTSL
		-> typeSpecifier()
		-> ultimateType()
		-> typeSpecifierList()
		-> final()
		-> typeSpecifier()
	;
	
	Iterator *			classes = this->progPtr()->classes();
	ClassSpecifier *	cs;
	ClassName *			cn;

	while (cs = (ClassSpecifier*)classes->next()) {
		cn = cs->className();
		if (cn && cn->equivalentTo(ts)) {
			delete classes;
			return cs;
		}
	}
	delete classes;
	return NULL;
}

DEFINE_CLASS(BaseSpecifier,BaseList);

BaseSpecifier::
BaseSpecifier (Token* a1,Token* a2,CompleteClassName* a3) 
{
	mySpec1	= a1;
	mySpec2	= a2;
	myName	= a3;
}

void BaseSpecifier::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "BaseSpecifier\n";
	if (mySpec1)	oo << mySpec1;
	if (mySpec2)	oo << mySpec2;
					oo << myName;
	margin (oo,L);
}

Token * BaseSpecifier::
firstToken ()
{
	return FIRST_FOR_2(mySpec1,mySpec2);
}

Token * BaseSpecifier::
lastToken ()
{
	return myName->lastToken();
}

ClassSpecifier * BaseSpecifier::
superClass ()
{
	return myName->myClass();
}

DEFINE_CLASS(ActualBaseList,BaseList);

ActualBaseList::
ActualBaseList (BaseList* a1,COMMA* a2,BaseSpecifier* a3) 
{
	myList	= a1;
	myCm	= a2;
	mySpec	= a3;
}

void ActualBaseList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ActualBaseList\n"
		<< myList
		<< myCm
		<< mySpec
	;
	margin (oo,L);
}

Token * ActualBaseList::
firstToken ()
{
	return myList->firstToken();
}

Token * ActualBaseList::
lastToken ()
{
	return mySpec->lastToken();
}

ClassSpecifier * ActualBaseList::
superClass ()
{
	return NULL;
}

DEFINE_CLASS(BaseSpec,Complex);

BaseSpec::
BaseSpec (COLON* a1,BaseList* a2) 
{
	myCln	= a1;
	myList	= a2;
}

void BaseSpec::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "BaseSpec\n"
		<< myCln
		<< myList
	;
	margin (oo,L);
}

Token * BaseSpec::
firstToken ()
{
	return myCln;
}

Token * BaseSpec::
lastToken ()
{
	return myList->lastToken();
}

ClassSpecifier * BaseSpec::
superClass ()
{
	return myList->superClass();
}

DEFINE_CLASS(PostMethodSpecifier,Complex);

BooleanVar PostMethodSpecifier::
isKindOfPureSpecifier () 
{
	return FALSE;
}

DEFINE_CLASS(PureSpecifier,PostMethodSpecifier);

PureSpecifier::
PureSpecifier (EQUALS* a1,ConstLiteral* a2) 
{
	myEq	= a1;
	myZero	= a2;
}

void PureSpecifier::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "PureSpecifier\n"
		<< myEq
		<< myZero
	;
	margin (oo,L);
}

Token * PureSpecifier::
firstToken ()
{
	return myEq;
}

Token * PureSpecifier::
lastToken ()
{
	return myZero->lastToken();
}

BooleanVar PureSpecifier::
hasPostSpec (Token *)
{
	return FALSE;
}

BooleanVar PureSpecifier::
isKindOfPureSpecifier () 
{
	return TRUE;
}

DEFINE_CLASS(SimpleMemberDeclarator,MemberDeclarator);

SimpleMemberDeclarator::
SimpleMemberDeclarator (Declarator* a1,PostMethodSpecifier* a2) 
{
	myDecl	= a1;
	myPost	= a2;
}

void SimpleMemberDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "SimpleMemberDeclarator\n";
				oo << myDecl;
	if (myPost)	oo << myPost;
	margin (oo,L);
}

Token * SimpleMemberDeclarator::
firstToken ()
{
	return myDecl->firstToken();
}

Token * SimpleMemberDeclarator::
lastToken ()
{
	return LAST_FOR_2(myPost,myDecl);
} 

BooleanVar SimpleMemberDeclarator::
declaresFunction ()
{
	return myDecl->declaresFunction();
}

BooleanVar SimpleMemberDeclarator::
declaresVariable ()
{
	return myDecl->declaresVariable();
}

BooleanVar SimpleMemberDeclarator::
declares (Name* n)
{
	return myDecl->dname()->equivalentTo(n);
}

Declarator * SimpleMemberDeclarator::
declOf (Name * n)
{
	if (this->declares(n)) {
		return myDecl;
	}
	return NULL;
}

Declaration * SimpleMemberDeclarator::
makeFuncDeclarationWith (DeclSpecifiers* s)
{
	return new FunctionDeclaration(s,myDecl,myPost);
}

Declaration * SimpleMemberDeclarator::
makeVarDeclarationWith (DeclSpecifiers* s)
{
	return new MemVarDeclaration (s,myDecl);
}

DEFINE_CLASS(BitFieldMemberDeclarator,MemberDeclarator);

BitFieldMemberDeclarator::
BitFieldMemberDeclarator (IDENTIFIER* a1,COLON* a2,ConditionalExpression* a3) 
{
	myId	= a1;
	myCln	= a2;
	myExp	= a3;
}

void BitFieldMemberDeclarator::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "BitFieldMemberDeclarator\n";
	if (myId)	oo << myId;
				oo << myCln;
				oo << myExp;
	margin (oo,L);
}

Token * BitFieldMemberDeclarator::
firstToken ()
{
	return (myId) ? myId : myCln;
}

Token * BitFieldMemberDeclarator::
lastToken ()
{
	return myExp->lastToken();
}

BooleanVar BitFieldMemberDeclarator::
declaresFunction ()
{
	return FALSE;
}

BooleanVar BitFieldMemberDeclarator::
declaresVariable ()
{
	return TRUE;
}

Declaration	* BitFieldMemberDeclarator::
makeFuncDeclarationWith (DeclSpecifiers*)
{
	FERROR("BitFieldMemberDeclarator::makeFuncDeclarationWith()")
}

Declaration	* BitFieldMemberDeclarator::
makeVarDeclarationWith (DeclSpecifiers* s)
{
	return new MemVarDeclaration (
		s,
		new Dname (
			new IdentifierName (myId)
		)
	);
}

DEFINE_CLASS(ActualMemberDeclaratorList,MemberDeclaratorList);

ActualMemberDeclaratorList::
ActualMemberDeclaratorList 
	(MemberDeclaratorList* a1,COMMA* a2,MemberDeclarator* a3) 
{
	myList	= a1;
	myCm	= a2;
	myDecl	= a3;
}

void ActualMemberDeclaratorList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ActualMemberDeclaratorList\n"
		<< myList
		<< myCm
		<< myDecl
	;
	margin (oo,L);
}

Token * ActualMemberDeclaratorList::
firstToken ()
{
	return myList->firstToken();
}

Token * ActualMemberDeclaratorList::
lastToken ()
{
	return myDecl->lastToken();
}

BooleanVar ActualMemberDeclaratorList::
declares (Name * n) 
{
	return myDecl->declares(n)
		? TRUE
		: myList->declares(n)
	;
}

Declarator * ActualMemberDeclaratorList::
declOf (Name * n) 
{
	Declarator * ret = myDecl->declOf(n);
	return ret ? ret : myList->declOf(n);
}

MemberDeclaratorList * ActualMemberDeclaratorList::
fetchList ()
{
	return myList;
}

MemberDeclarator * ActualMemberDeclaratorList::
getDecl ()
{
	return myDecl;
}

DEFINE_CLASS(DataMemberDeclaration,MemberDeclaration);

DataMemberDeclaration::
DataMemberDeclaration 
	(DeclSpecifiers* a1,MemberDeclaratorList* a2,SEMICOLON* a3) 
{
	mySpecs	= a1;
	myList	= a2;
	mySc	= a3;
}

void DataMemberDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "DataMemberDeclaration\n";
	if (mySpecs)	oo << mySpecs;
	if (myList)		oo << myList;
					oo << mySc;
	margin (oo,L);
}

Token * DataMemberDeclaration::
firstToken ()
{
	return FIRST_FOR_3(mySpecs,myList,mySc);
}

Token * DataMemberDeclaration::
lastToken ()
{
	return mySc;
}

BooleanVar DataMemberDeclaration::
declares (Name * n)
{
	if (mySpecs && mySpecs->declares(n)) {
		return TRUE;
	}
	if (myList && myList->declares(n)) {
		return TRUE;
	}
	return FALSE;
}

BooleanVar DataMemberDeclaration::
hasSpec (Token* sp)
{
	return mySpecs ? mySpecs->hasSpec(sp) : FALSE;
}

TypeName * DataMemberDeclaration::
typeOf (Name * n)
{
	if (!n) {
		return NULL;
	}
	if (mySpecs && mySpecs->declares(n)) {	// must be enum
		return new TypeName (
			new TypeSpecifierList (
				new ActualSimpleTypeName ("long",mySpecs),
				NULL
			),
			NULL
		);
	}

	Declarator * d;

	if (myList && (d = myList->declOf(n))) {
		return new TypeName (
			mySpecs->typeSpecifierList(),
			d->abstract()
		);
	}
	return NULL;
}

Iterator * DataMemberDeclaration::
funcDeclarations ()
{
	MemberDeclaratorList *	list;
	MemberDeclarator *		decl;
	Iterator *				ret = new Iterator();

	if (!myList || (mySpecs && mySpecs->isTypedef())) {
		return ret;
	}

	Token *	fr = new Token("friend",NULL);

	for (list=myList; list; list=list->fetchList()) {
		decl = list->getDecl();
		if (decl->declaresFunction() && !this->hasSpec(fr)) {
			ret->appendSeg(decl->makeFuncDeclarationWith(mySpecs));
		}
	}
	delete fr;
	return ret;
}

Iterator * DataMemberDeclaration::
varDeclarations ()
{
	MemberDeclaratorList *	list;
	MemberDeclarator *		decl;
	Iterator *				ret = new Iterator();

	if (!myList) {
		return ret;
	}

	Token *	fr = new Token("friend",NULL);

	for (list=myList; list; list=list->fetchList()) {
		decl = list->getDecl();
		if (decl->declaresVariable() && !this->hasSpec(fr)) {
			ret->appendSeg(decl->makeVarDeclarationWith(mySpecs));
		}
	}
	return ret;
}

DEFINE_CLASS(FunctionMemberDeclaration,MemberDeclaration);

FunctionMemberDeclaration::
FunctionMemberDeclaration (FunctionDefinition* a1,SEMICOLON* a2) 
{
	myDef	= a1;
	mySc	= a2;
}

void FunctionMemberDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "FunctionMemberDeclaration\n";
				oo << myDef;
	if (mySc)	oo << mySc;
	margin (oo,L);
}

Token * FunctionMemberDeclaration::
firstToken ()
{
	return myDef->firstToken();
}

Token * FunctionMemberDeclaration::
lastToken ()
{
	return LAST_FOR_2(mySc,myDef);
}

DEFINE_CLASS(QualifiedMemberDeclaration,MemberDeclaration);

QualifiedMemberDeclaration::
QualifiedMemberDeclaration (QualifiedName* a1,SEMICOLON* a2) 
{
	myName	= a1;
	mySc	= a2;
}

void QualifiedMemberDeclaration::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "QualifiedMemberDeclaration\n"
		<< myName
		<< mySc
	;
	margin (oo,L);
}

Token * QualifiedMemberDeclaration::
firstToken ()
{
	return myName->firstToken();
}

Token * QualifiedMemberDeclaration::
lastToken ()
{
	return mySc;
}

DEFINE_CLASS(AttributeParam,AttributeParamList);

AttributeParam::
AttributeParam (IDENTIFIER* a1)
{
	myId = a1;
}

void AttributeParam::
printOn (ostream& oo)
{
	margin (oo,R);
/*
	oo
		<< "AttributeParam\n"
		<< myId
	;
*/
	oo << "AttributeParam <";
	myId->copyOn(oo);
	oo << ">\n";
	margin (oo,L);
}

Token * AttributeParam::
firstToken ()
{
	return myId;
}

Token * AttributeParam::
lastToken ()
{
	return myId;
}

AttributeParamList * AttributeParam::
extendWith (COMMA* c,IDENTIFIER* i)
{
	return new ActualAttributeParamList (
		this,
		c,
		new AttributeParam(i)
	);
}

BooleanVar AttributeParam::
hasParamAt (Token* t,int pos)
{
	return (pos == 0 && myId->equivalentTo(t)) ? TRUE : FALSE; 
}

Token * AttributeParam::
paramAt (int pos)
{
	return (pos == 0) ? myId : NULL; 
}

DEFINE_CLASS(ActualAttributeParamList,AttributeParamList);


ActualAttributeParamList::
ActualAttributeParamList
	(AttributeParam* a1,COMMA* a2,AttributeParamList* a3)
{
	 myParam = a1;
	 myCm	 = a2;
	 myList	 = a3;
}

void ActualAttributeParamList::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "ActualAttributeParamLlist\n"
		<< myParam
		<< myCm
		<< myList
	;
	margin (oo,L);
}

Token * ActualAttributeParamList::
firstToken ()
{
	return myParam->firstToken();
}

Token * ActualAttributeParamList::
lastToken ()
{
	return myList->lastToken();
}

AttributeParamList * ActualAttributeParamList::
extendWith (COMMA* c,IDENTIFIER* i)
{
	myList = myList->extendWith(c,i);
	return this;
}

BooleanVar ActualAttributeParamList::
hasParamAt (Token* t,int pos)
{
	if (pos == 0 && myParam->hasParamAt(t,0)) {
		return TRUE;
	}
	if (pos < 1) {
		return FALSE;
	}
	return myList->hasParamAt(t,pos-1);
}

Token * ActualAttributeParamList::
paramAt (int pos)
{
	if (pos == 0) {
		return myParam->paramAt(pos);
	}
	if (pos < 1) {
		return NULL;
	}
	return myList->paramAt(pos-1);
}

DEFINE_CLASS(AttributeList,Complex);

AttributeList::
AttributeList (Attribute* a1,AttributeList* a2) 
{
	myAttr	= a1;
	myList	= a2;
}

void AttributeList::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "AttributeList\n";
				oo << myAttr;
	if (myList)	oo << myList;
	margin (oo,L);
}

Token * AttributeList::
firstToken ()
{
	return myAttr->firstToken();
}

Token * AttributeList::
lastToken ()
{
	return LAST_FOR_2(myList,myAttr);
}

void AttributeList::
add (Attribute* c)
{
	if (myList) {
		myList->add(c);
	} else {
		myList = new AttributeList(c,NULL);
	}
}

Attribute * AttributeList::
attribute ()
{
	return myAttr;
}

AttributeList * AttributeList::
attributeList ()
{
	return myList;
}

DEFINE_CLASS(PostMethodAttrXpp,PostMethodSpecifier);

PostMethodAttrXpp::
PostMethodAttrXpp (Attribute* a1)
{
	myAttr = a1;
}

void PostMethodAttrXpp::
printOn (ostream& oo)
{
	margin (oo,R);
	oo
		<< "PostMethodAttrXpp\n"
		<< myAttr
	;
	margin (oo,L);
}

Token * PostMethodAttrXpp::
firstToken ()
{
	return myAttr->firstToken();
}

Token * PostMethodAttrXpp::
lastToken ()
{
	return myAttr->lastToken();
}

BooleanVar PostMethodAttrXpp::
hasPostSpec (Token * t)
{
	return myAttr->isNamed(t);
}
 
DEFINE_CLASS(SimpleMemberList,MemberList);

SimpleMemberList::
SimpleMemberList (MemberDeclaration* a1,MemberList* a2) 
{
	myDecl	= a1;
	myList	= a2;
}

void SimpleMemberList::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "SimpleMemberList\n";
				oo << myDecl;
	if (myList)	oo << myList;
	margin (oo,L);
}

Token * SimpleMemberList::
firstToken ()
{
	return myDecl->firstToken();
}

Token * SimpleMemberList::
lastToken ()
{
	return LAST_FOR_2(myList,myDecl);
}

void SimpleMemberList::
extendWith (MemberList * m)
{
	if (myList) {
		myList->extendWith(m);
	} else {
		myList = m;
	}
}

Token * SimpleMemberList::
proTypeAtAfter (int loc, Token * pro)
{
	if (myDecl->firstPos() <= loc && myDecl->lastPos() >= loc) {
		return pro ? pro : new Token ("private",this);
	}
	if (!myList) {
		return NULL;
	}
	return myList->proTypeAtAfter(loc,pro);
}

BooleanVar SimpleMemberList::
hasPro (Token * pro)
{
	if (!myList) {
		return FALSE;
	}
	return myList->hasPro(pro);
}

DEFINE_CLASS(AccessMemberList,MemberList);

AccessMemberList::
AccessMemberList (Token* a1,COLON* a2,MemberList* a3) 
{
	myAcc	= a1;
	myCln	= a2;
	myList	= a3;
}

void AccessMemberList::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "AccessMemberList\n";
				oo << myAcc;
				oo << myCln;
	if (myList)	oo << myList;
	margin (oo,L);
}

Token * AccessMemberList::
firstToken ()
{
	return myAcc;
}

Token * AccessMemberList::
lastToken ()
{
	return LAST_FOR_2(myList,myCln);
}

void AccessMemberList::
extendWith (MemberList* m) 
{
	if (myList) {
		myList->extendWith(m);
	} else {
		myList = m;
	}
}

Token * AccessMemberList::
proTypeAtAfter (int loc,Token * /* pro*/)
{
	if (!myList) {
		return NULL;
	}
	return myList->proTypeAtAfter(loc,myAcc);
}

BooleanVar AccessMemberList::
hasPro (Token * a1)
{
	if (myAcc->equivalentTo(a1)) {
		return TRUE;
	}
	if (!myList) {
		return FALSE;
	}
	return myList->hasPro(a1);
}

DEFINE_CLASS(ClassHead,Complex);

DEFINE_CLASS(ClassHeadStd,ClassHead);

ClassHeadStd::
ClassHeadStd (CLASS_KEY* a1,ClassName* a2,BaseSpec* a3) 
{
	myKey	= a1;
	myName	= a2;
	mySpec	= a3;
}

void ClassHeadStd::
printOn (ostream& oo)
{
	margin (oo,R);
				oo << "ClassHeadStd\n";
				oo << myKey;
	if (myName)	oo << myName;
	if (mySpec)	oo << mySpec;
	margin (oo,L);
}

Token * ClassHeadStd::
firstToken ()
{
	return myKey;
}

Token * ClassHeadStd::
lastToken ()
{
	return LAST_FOR_3(mySpec,myName,myKey);
}

ClassName * ClassHeadStd::
className ()
{
	return myName ? myName : new ClassName (new Token ("",this));
}

ClassSpecifier * ClassHeadStd::
superClass ()
{
	return (mySpec) ? mySpec->superClass() : NULL; 
}

Token * ClassHeadStd::
key ()
{
	return myKey;
}

DEFINE_CLASS(ClassHeadXpp,ClassHead);

ClassHeadXpp::
ClassHeadXpp
 (Token* a1, CLASS_KEY* a2, LP* a3,  ClassName* a4,
  COMMA* a5, ClassName* a6, RP* a7)
{
	myNType	= a1;
	myKey	= a2;
	myLp	= a3;
	myName	= a4;
	myCm	= a5;
	myBase	= a6;
	myRp	= a7;
}

void ClassHeadXpp::
printOn (ostream& oo)
{
	margin (oo,R);
					oo << "ClassHeadXpp\n";
	if (myNType)	oo << myNType;
					oo << myKey;
					oo << myLp;
					oo << myName;
					oo << myCm;
					oo << myBase;
					oo << myRp;
	margin (oo,L);
}

Token * ClassHeadXpp::
firstToken ()
{
	return myNType ? myNType : myKey;
}

Token * ClassHeadXpp::
lastToken ()
{
	return myRp;
}

ClassName * ClassHeadXpp::
className ()
{
	return myName ? myName : new ClassName (new Token ("",this));
}

ClassSpecifier * ClassHeadXpp::
superClass ()
{
	return myBase->myClass();
}

Token * ClassHeadXpp::
key ()
{
	return myKey;
}

DEFINE_CLASS(ExternalDefinition,Complex);

ExternalDefinition::
ExternalDefinition (Declaration* a1)
{
	myDecl = a1;
}

void ExternalDefinition::
printOn (ostream& oo)
{
	if (myDecl) oo << myDecl;
}

Token * ExternalDefinition::
firstToken()
{
	return myDecl->firstToken();
}

Token * ExternalDefinition::
lastToken()
{
	return myDecl->lastToken();
}

Declaration * ExternalDefinition::
declaration ()
{
	return myDecl;
}

DEFINE_CLASS(TranslationUnit,Complex);

TranslationUnit::
TranslationUnit (TranslationUnit * a1, ExternalDefinition * a2)
{
	myTrans	= a1;
	myDef	= a2;
}

void TranslationUnit::
printOn (ostream& oo)
{
/*
	margin (oo,R);
					oo << "TranslationUnit\n";
*/
	if (myTrans)	oo << myTrans;
					oo << myDef;
/*
	margin (oo,L);
*/
}

Token * TranslationUnit::
firstToken ()
{
	return FIRST_FOR_2(myTrans,myDef);
}

Token * TranslationUnit::
lastToken ()
{
	return myDef->lastToken();
}

DEFINE_CLASS(Program,Complex);

Program::
Program ()
{
	myFile		= new SFile ("\"(input)\"",this);
	myTree		= NULL;
	myClassList	= NULL;
	myFuncList	= NULL;
	myStmtList	= NULL;
	myDeclList	= NULL;
}

void Program::
printOn (ostream& oo)
{
/*
	oo << myFile << "\n";
	oo << "FIRST:" << this->firstToken();
	oo << "LAST:" << this->lastToken() << "\n";
	oo << &myExternalDefinitions;
*/
	if (myTree) {
		oo << myTree;
	} else {
		oo << "Empty\n";
	}
}

void Program::
dumpTokensOn (ostream& oo)
{
	Segment * s;

	for (s=this->firstToken(); s; s=s->next()) {
		oo << s; 
	}
}

void Program::
copyIntervalFromToOn (Segment* s1,Segment* s2,ostream& oo)
{
	Token * first_token = this->firstToken();
	Token * last_token	= this->lastToken();

	if (!first_token || !last_token) {
		return;
	}

	char *	p = first_token->pointer();

	int		i = s1 ? s1->lastPos() + 1	: first_token->firstPos();
	int		j = s2 ? s2->firstPos() - 1	: last_token->lastPos();

	while (i <= j) {
		oo.put(p[i++]);
	}
}

Token * Program::
firstToken()
{
	return (Token*)myTokens.first();
}

Token * Program::
lastToken()
{
	return (Token*)myTokens.last();
}

char * Program::
fileName ()
{
	return myFile ? myFile->fileName() : "";
}

void Program::
setFile (char * f)
{
	if (f) {
		myFile = new SFile (f,this);
	}
}

void Program::
setTree (TranslationUnit * t)
{
	myTree = t;
}

void Program::
insertToken (Token* t)
{
	myTokens.add(t);
}

void Program::
insertExpression (Expression* e)
{
	myExpressions.insert(e);
}

void Program::
insertDeclaration (Declaration* d)
{
	myDeclarations.add(d);
}

void Program::
insertArgDeclaration (ArgumentDeclaration* d)
{
	myArgDeclarations.add(d);
}

void Program::
insertMemDeclaration (MemberDeclaration* d)
{
	myMemDeclarations.add(d);
}

void Program::
insertFunction (FunctionDefinition* f)
{
	myFunctions.add(f);
}

void Program::
insertClass (ClassSpecifier* c)
{
	myClasses.insert(c);
}

void Program::
insertStatement (Statement* s)
{
	myStatements.insert(s);
}

void Program::
insertExternalDefinition (ExternalDefinition* p)
{
	myExternalDefinitions.add(p);
}

Iterator * Program::
classes()
{
	if (myClassList) {
		return new Iterator (myClassList);
	}

	Iterator *		 ret = new Iterator();
	Segment *		 begin = myClasses.first(); 
	Segment *		 end = myClasses.last(); 
	Segment *		 seg;

	for (seg=begin; seg; seg=(seg==end)?NULL:seg->next()) {
		ret->appendSeg(seg);
	}
	myClassList = ret->ilist();
	return ret;
}

Iterator * Program::
functionDefs ()
{
	Iterator *	ret = new Iterator();
	Segment *	begin = myFunctions.first(); 
	Segment *	end = myFunctions.last(); 
	Segment *	seg;

	for (seg=begin; seg; seg=(seg==end)?NULL:seg->next()) {
		ret->appendSeg(seg);
	}
	return ret;
}

Iterator * Program::
globalFunctions ()
{
	if (myFuncList) {
		return new Iterator (myFuncList);
	}

	Iterator *	ret		= new Iterator();
	Segment *	begin	= myFunctions.first(); 
	Segment *	end		= myFunctions.last(); 
	Segment *	seg;

	for (seg=begin; seg; seg=(seg==end)?NULL:seg->next()) {
		if (!((Function*)seg)->homeClass()) {
			ret->appendSeg(seg);
		}
	}

	Iterator *	funcDecls;

	begin	= myDeclarations.first(); 
	end		= myDeclarations.last(); 

	for (seg=begin; seg; seg=(seg==end)?NULL:seg->next()) {
		if (!this->classContains(seg)) {
			funcDecls = ((Declaration*)seg)->funcDeclarations();
			ret->merge(funcDecls);
		}
	}
	myFuncList = ret->ilist();
	return ret;
}

Iterator * Program::
statements()
{
	if (myStmtList) {
		return new Iterator (myStmtList);
	}

	Iterator *	ret = new Iterator();
	Segment *	begin = myStatements.first(); 
	Segment *	end = myStatements.last(); 
	Segment *	s;
	Segment *	last = NULL;
	Statement *	st;

	for (s=begin; s; s = (s==end) ? NULL : s->next()) {
		st = ((Statement*)s);
		if (last && last->contains(s)) {
			continue;
		}
		ret->appendSeg(st);
		last = s;
	}
	myStmtList = ret->ilist();
	return ret;
}

Iterator * Program::
declarations()
{
	if (myDeclList) {
		return new Iterator (myDeclList);
	}

	Iterator *		 ret = new Iterator();
	Segment *		 begin = myDeclarations.first(); 
	Segment *		 end = myDeclarations.last(); 
	Segment *		 seg;

	for (seg=begin; seg; seg=(seg==end)?NULL:seg->next()) {
		ret->appendSeg(seg);
	}
	myDeclList = ret->ilist();
	return ret;
}

BooleanVar Program::
classContains (Segment * seg)
{
	Segment *	 begin = myClasses.first(); 
	Segment *	 end = myClasses.last(); 
	Segment *	 s;

	for (s = begin; s; s = (s==end) ? NULL : s->next()) {
		if (s->contains(seg)) {
			return TRUE;
		}
	}
	return FALSE;
}

Thread * Program::
tokens ()
{
	return &myTokens;
}

Thread * Program::
exprThread ()
{
	return &myExpressions;
}

Thread * Program::
argDeclarations ()
{
	return &myArgDeclarations;
}

Thread * Program::
memDeclarations ()
{
	return &myMemDeclarations;
}

Thread * Program::
declThread ()
{
	return &myDeclarations;
}

Thread * Program::
funcThread ()
{
	return &myFunctions;
}

Thread * Program::
classThread ()
{
	return &myClasses;
}

Thread * Program::
stmtThread ()
{
	return &myStatements;
}

Thread * Program::
externalDefinitions ()
{
	return &myExternalDefinitions;
}
