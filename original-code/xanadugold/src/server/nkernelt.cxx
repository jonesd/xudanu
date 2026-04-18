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

#ifndef NKERNELT_CXX
#define NKERNELT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef NKERNELT_HXX
#include "nkernelt.hxx"
#endif /* NKERNELT_HXX */

#ifndef NKERNELT_IXX
#include "nkernelt.ixx"
#endif /* NKERNELT_IXX */


#ifndef CROSSX_HXX
#include "crossx.hxx"
#endif /* CROSSX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */

#ifndef NLINKSX_HXX
#include "nlinksx.hxx"
#endif /* NLINKSX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef WORKSRVX_HXX
#include "worksrvx.hxx"
#endif /* WORKSRVX_HXX */

#ifndef WRAPPERX_HXX
#include "wrapperx.hxx"
#endif /* WRAPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class WorksTester 
 *
 * ************************************************************************ */



/* Initializers for WorksTester */

GPTR(WorksTester) WorksTester::TheTester = NULL;





/* Initializers for WorksTester */






/* server library */


RPTR(ID) WorksTester::clubID (APTR(Sequence) clubName){
	/* Looks up the ID of a named Club in the directory 
	maintained by the System Admin Club. Requires read permission 
	on the directory. Blasts if there is no Club with that name. */
	
	WPTR(ID) 	returnValue;
	returnValue = FeServer::iDOf(CAST(FeWork,FeServer::get(FeServer::clubDirectoryID()))->edition()->get(clubName));
	return returnValue;
}


RPTR(IntegerPos) WorksTester::xuInteger (IntegerVar val){
	WPTR(IntegerPos) 	returnValue;
	returnValue = IntegerPos::make (val);
	return returnValue;
}


RPTR(Sequence) WorksTester::sequence (char * string){
	WPTR(Sequence) 	returnValue;
	returnValue = Sequence::string(string);
	return returnValue;
}


RPTR(PrimArray) WorksTester::string (char * string){
	WPTR(PrimArray) 	returnValue;
	returnValue = UInt8Array::string(string);
	return returnValue;
}
/* testing */


void WorksTester::allTestsOn (ostream& oo){
	SPTR(ID) testID;
	
	myConnection = Connection::make (cat_FeServer);
	myConnection->bootHeaper();
	CurrentKeyMaster.fluidSet(CAST(BooLock,FeServer::loginByName(WorksTester::sequence("Test")))->boo());
	CurrentKeyMaster.fluidGet()->incorporate(FeKeyMaster::makePublic());
	testID = WorksTester::clubID(WorksTester::sequence("Test"));
	InitialOwner.fluidSet(testID);
	InitialReadClub.fluidSet(testID);
	InitialEditClub.fluidSet(testID);
	InitialSponsor.fluidSet(testID);
	CurrentAuthor.fluidSet(testID);
	this->makeEditionTestOn(oo);
	this->editionTestOn(oo);
	
	this->crossTestOn(oo);
	this->compareTestOn(oo);
	
	this->globalIDTestOn(oo);
	
	this->workTestOn(oo);
	this->endorseTestOn(oo);
	
	this->historyTestOn(oo);
	this->sponsorTestOn(oo);
	
	this->kmTestOn(oo);
	this->transclusionsTestOn(oo);
	
	this->transcludersBugTestOn(oo);
	this->ownerTestOn(oo);
	
	this->labelTestOn(oo);
	
	FeServer::waitForWrite(WorksWaitDetector::make (oo, "Test done!"));
}
/* tests */


void WorksTester::compareTestOn (ostream& oo){
	/* Test the various version comparision operations */
	
	SPTR(FeEdition) a;
	SPTR(FeEdition) b;
	SPTR(FeWork) work1;
	SPTR(FeWork) work2;
	SPTR(FeWork) work3;
	SPTR(FeEdition) edn;
	SPTR(XnRegion) region;
	
	a = FeEdition::placeHolders(IntegerRegion::interval(Int32Zero, 100));
	b = a->copy(IntegerSpace::make ()->below(IntegerPos::make (50), FALSE))->transformedBy(IntegerSpace::make ()->translation(100))->combine(FeEdition::placeHolders(IntegerSpace::make ()->interval(IntegerPos::make (Int32Zero), IntegerPos::make (50))))->combine(a->copy(IntegerSpace::make ()->interval(IntegerPos::make (25), IntegerPos::make (75)))->transformedBy(IntegerSpace::make ()->translation(25)));
	oo << "a sharedWith b: " << a->sharedWith(b) << myCR << "a notSharedWith b: " << a->notSharedWith(b) << myCR << "a sharedRegion b: " << a->sharedRegion(b) << myCR << "a mapSharedTo b: " << a->mapSharedTo(b) << myCR << "a sharedRegion b copy [120,130): " << a->sharedRegion(b->copy(IntegerRegion::make (120, 130))) << myCR << "a keysOf a[50]: " << a->positionsOf(a->get(IntegerPos::make (50))) << myCR << "b sharedWith a: " << b->sharedWith(a) << myCR << "b notSharedWith a: " << b->notSharedWith(a) << myCR << "b mapSharedTo a: " << b->mapSharedTo(a) << myCR << "b sharedRegion a: " << b->sharedRegion(a) << myCR << "b sharedRegion a copy [20,30): " << b->sharedRegion(a->copy(IntegerRegion::make (20, 30))) << myCR << "b positionsOf a[50]: " << b->positionsOf(a->get(IntegerPos::make (50))) << myCR;
	work1 = FeWork::make (FeText::make (UInt8Array::string("foo"))->edition());
	work2 = FeWork::make (FeEdition::fromOne(IntegerPos::make (Int32Zero), work1));
	edn = FeEdition::fromOne(IntegerPos::make (Int32Zero), work1);
	work3 = CAST(FeWork,work2->edition()->theOne());
	region = edn->positionsOf(work3);
	oo << "region = " << region << myCR;
}


void WorksTester::crossTestOn (ostream& oo){
	SPTR(PtrArray) four;
	SPTR(IDSpace) is;
	SPTR(CrossSpace) cross;
	SPTR(FeEdition) doc;
	
	oo << myCR << "CrossSpace retrieval test" << myCR;
	four = PtrArray::nulls(4);
	is = IDSpace::unique();
	four->store(UInt32Zero, is);
	four->store(1, IntegerSpace::make ());
	four->store(2, IntegerSpace::make ());
	four->store(3, IntegerSpace::make ());
	cross = CrossSpace::make (four);
	doc = FeEdition::empty(cross);
	{
		Int32 LoopFinal = 10;
		Int32 i = 1;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				four->store(UInt32Zero, is->newID()->asRegion());
				four->store(1, IntegerSpace::make ()->interval(IntegerPos::make (i), IntegerPos::make (i + 4)));
				four->store(2, IntegerSpace::make ()->interval(IntegerPos::make (i), IntegerPos::make (21 - i)));
				four->store(3, IntegerSpace::make ()->interval(IntegerPos::make (i), IntegerPos::make (i + 1)));
				doc = doc->combine(FeEdition::fromAll(cross->crossOfRegions(four), FeDataHolder::make (PrimIntValue::make (i))));
			}
			i += 1;
		}
	}
	{
		Int32 LoopFinal = 3;
		Int32 j = 1;
		for (;;) {
			if (j > LoopFinal){
				break;
			}
			{
				oo << "Looking for dimension " << j << " >= 10" << myCR;
				BEGIN_FOR_EACH(FeElementBundle,bundle,(doc->copy(cross->extrusion(j, IntegerSpace::make ()->above(IntegerPos::make (10), TRUE)))->retrieve())) {
					oo << "found " << bundle->element() << " at " << bundle->region() << myCR;
				} END_FOR_EACH;
			}
			j += 1;
		}
	}
}


void WorksTester::editionTestOn (ostream& oo){
	/* Test the simple Edition operations */
	
	SPTR(FeEdition) edition;
	
	oo << "Testing various Edition operations" << myCR;
	edition = FeEdition::empty(IntegerSpace::make ());
	oo << "initially: " << edition << myCR << " coordinateSpace: " << edition->coordinateSpace() << myCR << " count: " << edition->count() << myCR << " domain: " << edition->domain() << myCR << " isEmpty: " << edition->isEmpty() << myCR << " isFinite: " << edition->isFinite() << myCR;
	edition = edition->with(IntegerPos::make (Int32Zero), FeRangeElement::placeHolder());
	oo << "with(0): " << edition << myCR << " theOne: " << edition->theOne() << myCR;
	edition = edition->withAll(IntegerSpace::make ()->above(IntegerPos::make (1), TRUE), FeDataHolder::make (PrimIntValue::make (65)));
	oo << "withAll: " << edition << myCR << " domain: " << edition->domain() << myCR << " isEmpty: " << edition->isEmpty() << myCR << " isFinite: " << edition->isFinite() << myCR;
	oo << "stepper:" << myCR;
	
	BEGIN_FOR_POSITIONS(Position,p,FeRangeElement,v,(edition->stepper(IntegerSpace::make ()->interval(IntegerPos::make (IntegerVarZero), IntegerPos::make (2))))) {
		oo << " " << p << " -> " << v << myCR;
	} END_FOR_POSITIONS;
	edition = edition->without(IntegerPos::make (3));
	oo << "without 3" << edition << myCR;
	edition = edition->withoutAll(IntegerSpace::make ()->above(IntegerPos::make (2), TRUE));
	oo << "withoutAll: " << edition << myCR << " count: " << edition->count() << myCR << " domain: " << edition->domain() << myCR << " isEmpty: " << edition->isEmpty() << myCR << " isFinite: " << edition->isFinite() << myCR << " get 1: " << edition->get(IntegerPos::make (1)) << myCR;
	oo << "combined: " << edition->combine(FeEdition::fromOne(IntegerPos::make (5), FeRangeElement::placeHolder())) << myCR;
	oo << "replaced: " << edition->replace(FeEdition::fromOne(IntegerPos::make (1), FeRangeElement::placeHolder())) << myCR;
}


void WorksTester::endorseTestOn (ostream& oo){
	/* Test endorsing and unendorsing Editions and Works */
	
	SPTR(FeEdition) e1;
	SPTR(FeWork) w1;
	SPTR(ID) iD;
	SPTR(IDRegion) userRegion;
	
	e1 = FeEdition::empty(IntegerSpace::make ());
	w1 = FeWork::make (e1);
	oo << "Initial endorsements:" << myCR << "  on Edition: " << e1->endorsements() << myCR << "  on Work: " << w1->endorsements() << myCR << myCR;
	userRegion = CAST(IDRegion,CurrentAuthor.fluidGet()->asRegion());
	e1->endorse(FeServer::endorsementRegion(userRegion, userRegion));
	iD = IDSpace::global()->newID();
	w1->endorse(FeServer::endorsementRegion(userRegion, CAST(IDRegion,iD->asRegion())));
	oo << "After endorsing:" << myCR << "  on Edition: " << e1->endorsements() << myCR << "  on Work: " << w1->endorsements() << myCR;
	e1->retract(FeServer::endorsementRegion(userRegion, userRegion));
	w1->retract(FeServer::endorsementRegion(userRegion, CAST(IDRegion,iD->asRegion())));
	oo << "After unendorsing:" << myCR << "  on Edition: " << e1->endorsements() << myCR << "  on Work: " << w1->endorsements() << myCR;
}


void WorksTester::globalIDTestOn (ostream& oo){
	/* Test assigning and retrieving by global IDs */
	
	AS(SPTR(FeRangeElement),FePlaceHolder) p1;
	SPTR(ID) id1a;
	SPTR(ID) id1b;
	SPTR(IDRegion) ids;
	AS(SPTR(FeRangeElement),FePlaceHolder) p2;
	SPTR(ID) id2;
	SPTR(FeEdition) ed;
	
	p1 = FeRangeElement::placeHolder();
	if (!(ids = FeServer::iDsOf(p1))->isEmpty()) {
		oo << "Newly created place holder " << p1 << " should not have had any IDs but was reported to have " << ids << myCR;
	}
	id1a = FeServer::assignID(p1);
	if (!(ids = FeServer::iDsOf(p1))->isEqual(id1a->asRegion())) {
		oo << "PlaceHolder " << p1 << " should have IDs " << id1a->asRegion() << " but was reported to have IDs " << ids << myCR;
	}
	id1b = FeServer::assignID(p1);
	if (!(ids = FeServer::iDsOf(p1))->isEqual(id1a->asRegion()->with(id1b))) {
		oo << "PlaceHolder " << p1 << " should have IDs " << id1a->asRegion()->with(id1b) << " but was reported to have IDs " << ids << myCR;
	}
	p2 = FeRangeElement::placeHolder();
	id2 = FeServer::assignID(p2);
	ed = FeEdition::fromOne(IntegerPos::make (Int32Zero), p1)->combine(FeEdition::fromOne(IntegerPos::make (1), p2));
	if (!(ids = FeServer::iDsOfRange(ed))->isEqual(id1a->asRegion()->with(id1b)->with(id2))) {
		oo << "PlaceHolders " << ed << " should have IDs " << id1a->asRegion()->with(id1b)->with(id2) << " but was reported to have IDs " << ids << myCR;
	}
	oo << "Global ID assignment test successful\n";
}


void WorksTester::historyTestOn (ostream& oo){
	SPTR(FeWork) work;
	
	work = FeWork::make (FeEdition::fromArray(WorksTester::string("Howdy doody.")));
	work->setHistoryClub(FeServer::publicClubID());
	work->revise(FeEdition::fromArray(WorksTester::string("Good bye")));
	work->revise(FeEdition::fromArray(WorksTester::string("Much better.")));
	oo << "The trail is: " << work->revisions() << myCR;
	BEGIN_FOR_POSITIONS(Position,position,FeWork,value,(work->revisions()->stepper())) {
		oo << position << "->" << CAST(FeArrayBundle,value->edition()->retrieve()->theOne())->array() << myCR;
	} END_FOR_POSITIONS;
	oo << myCR;
}


void WorksTester::kmTestOn (ostream& oo){
	/* Test the operation of KeyMasters */
	
	SPTR(FeKeyMaster) km;
	SPTR(FeWrapperSpec) clubspec;
	SPTR(FeClub) test;
	SPTR(FeClub) club1;
	SPTR(FeStatusDetector) detect1;
	SPTR(FeWork) work1;
	SPTR(FeClub) club2;
	SPTR(FeStatusDetector) detect2;
	SPTR(FeWork) work2;
	SPTR(FeClubDescription) desc;
	
	km = CurrentKeyMaster.fluidGet()->copy();
	{	FLUID_BIND(CurrentKeyMaster,km) {
			clubspec = FeWrapperSpec::get(WorksTester::sequence("ClubDescription"));
			test = CAST(FeClub,FeServer::get(CurrentAuthor.fluidGet()));
			club1 = FeClub::make (FeClubDescription::make (FeSet::make (), FeBooLockSmith::make ())->edition());
			oo << "Club1 " << FeServer::iDOf(club1) << " is initially " << clubspec->wrap(club1->edition()) << myCR << "and CurrentKeyMaster is " << km->actualAuthority() << myCR << myCR;
			oo << "Logged in as " << CAST(BooLock,FeServer::login(FeServer::iDOf(club1)))->boo();
			club2 = FeClub::make (FeClubDescription::make (FeSet::make (), FeBooLockSmith::make ())->edition());
			oo << "Club 2 " << FeServer::iDOf(club2) << " is initially " << clubspec->wrap(club2->edition()) << myCR << "and CurrentKeyMaster is " << km->actualAuthority() << myCR << myCR;
			{	FLUID_BIND(InitialEditClub,FeServer::iDOf(club1)) {
					{	FLUID_BIND(InitialReadClub,FeServer::iDOf(club1)) {
							work1 = FeWork::make (FeEdition::empty(IntegerSpace::make ()));
						}
					}
				}
			}
			detect1 = WorksTestStatusDetector::make (oo, "\nWork 1");
			work1->addStatusDetector(detect1);
			oo << "Giving Work 1 edit authority to Club 1" << myCR;
			work1->requestGrab();
			{	FLUID_BIND(InitialEditClub,FeServer::iDOf(club2)) {
					work2 = FeWork::make (FeEdition::empty(IntegerSpace::make ()));
				}
			}
			detect2 = WorksTestStatusDetector::make (oo, "\nWork 2");
			work2->addStatusDetector(detect2);
			oo << "Giving Work 2 edit authority to Club 2" << myCR;
			work2->requestGrab();
			desc = CAST(FeClubDescription,clubspec->wrap(club1->edition()));
			club1->revise(desc->withMembership(desc->membership()->with(test))->edition());
			oo << "Club 1 should now have Test as a member: " << clubspec->wrap(club1->edition()) << myCR << "So CurrentKeyMaster should have Club 1 authority: " << km->actualAuthority() << myCR << "and Work 1 should have become grabbed: " << work1->canRevise() << myCR << myCR;
			desc = CAST(FeClubDescription,clubspec->wrap(club2->edition()));
			club2->revise(desc->withMembership(desc->membership()->with(club1))->edition());
			oo << "Club 2 should now have Club 1 as a member: " << clubspec->wrap(club2->edition()) << myCR << "So CurrentKeyMaster should have Club 2 authority: " << km->actualAuthority() << myCR << "and Work 2 should have become grabbed: " << work2->canRevise() << myCR << myCR;
			desc = CAST(FeClubDescription,clubspec->wrap(club2->edition()));
			club2->revise(desc->withMembership(desc->membership()->without(club1)->with(FeServer::get(FeServer::publicClubID())))->edition());
			oo << "Club 2 should have Public but not Club 1 as a member: " << clubspec->wrap(club2->edition()) << myCR << "So CurrentKeyMaster should retain Club 2 authority: " << km->actualAuthority() << myCR << "and Work 2 should remain grabbed: " << work2->canRevise() << myCR << myCR;
			km->removeLogins(CAST(IDRegion,FeServer::publicClubID()->asRegion()));
			oo << "The combined KeyMaster should have lost Public & Club 2 authority: " << " login " << km->loginAuthority() << myCR << " actual " << km->actualAuthority() << myCR << "and Work 2 should have become released but readable:" << " canRevise " << work2->canRevise() << " canRead " << work2->canRead() << myCR << myCR;
			desc = CAST(FeClubDescription,clubspec->wrap(club1->edition()));
			club1->revise(desc->withMembership(desc->membership()->without(test))->edition());
			oo << "Club 1 should no longer have Test as a member: " << clubspec->wrap(club1->edition()) << myCR << "So CurrentKeyMaster should not have Club 1 authority: " << km->actualAuthority() << myCR << "and Work 1 should have become released and unreadable:" << " canRevise " << work1->canRevise() << " canRead " << work1->canRead() << myCR << myCR;
			/* work2 removeStatusDetector: detect2. */
				/* work1 removeStatusDetector: detect1. */
			club1->release();
			club2->release();
		}
	}
	/* Clean up persistent information in Server */
	/* Thing to do !!!! */
	
}


void WorksTester::labelTestOn (ostream& oo){
	SPTR(FeEdition) edition;
	SPTR(FeEdition) e1;
	SPTR(FeEdition) e2;
	SPTR(FeEdition) e3;
	SPTR(FeEdition) e4;
	SPTR(FeEdition) e1prime;
	SPTR(FeEdition) edition2;
	
	e1 = FeEdition::fromArray(WorksTester::string("First Edition"));
	e2 = FeEdition::fromArray(WorksTester::string("Second Edition"));
	e3 = FeEdition::fromArray(WorksTester::string("Third Edition"));
	e4 = FeEdition::fromArray(WorksTester::string("Fourth Edition"));
	edition = FeEdition::fromArray(
					PrimSpec::pointer()->arrayWithThree(e1, e2, FeWork::make (e1)));
	oo << "Labels:" << myCR;
	oo << " " << e1->label() << " " << e2->label() << " " << e3->label() << " " << e4->label() << myCR;
	oo << "labelled e1: " << edition->positionsLabelled(e1->label()) << myCR;
	e1prime = CAST(FeEdition,edition->fetch(IntegerPos::make (IntegerVarZero)))->with(IntegerPos::make (1), FeRangeElement::placeHolder());
	edition2 = edition->with(IntegerPos::make (IntegerVarZero), e1prime);
	oo << "edit e1: " << edition2->positionsLabelled(e1->label()) << myCR;
	oo << "labelled e2: " << edition2->positionsLabelled(e2->label()) << myCR;
	oo << "rebind e2: " << edition2->rebind(IntegerPos::make (1), e3)->positionsLabelled(e2->label()) << myCR;
	oo << "duplicate e1: " << edition2->with(IntegerPos::make (1), e1)->positionsLabelled(e1->label()) << myCR;
	oo << myCR;
}


void WorksTester::makeEditionTestOn (ostream& oo){
	/* Try making Editions in a variety of ways */
	
	SPTR(FeEdition) edn;
	SPTR(FeRangeElement) place;
	SPTR(FeDataHolder) data;
	SPTR(PrimArray) bits;
	
	oo << (edn = FeEdition::empty(SequenceSpace::make ())) << myCR << FeEdition::empty(IntegerSpace::make ()) << myCR;
	oo << FeEdition::placeHolders(IntegerSpace::make ()->interval(IntegerPos::make (IntegerVarZero), IntegerPos::make (10))) << myCR << FeEdition::placeHolders(SequenceSpace::make ()->emptyRegion()) << myCR << FeEdition::placeHolders(SequenceSpace::make ()->fullRegion()) << myCR;
	data = FeDataHolder::make (PrimIntValue::make (3));
	place = FeRangeElement::placeHolder();
	oo << FeEdition::fromOne(IntegerPos::make (IntegerVarZero), edn) << myCR << FeEdition::fromOne(IntegerPos::make (1), place) << myCR << FeEdition::fromOne(IntegerPos::make (2), data) << myCR;
	oo << FeEdition::fromAll(IntegerSpace::make ()->above(IntegerPos::make (10), TRUE), edn) << myCR << FeEdition::fromAll(IntegerSpace::make ()->below(IntegerPos::make (100), FALSE), place) << myCR << FeEdition::fromAll(IntegerSpace::make ()->emptyRegion(), place) << myCR << FeEdition::fromAll(IDSpace::unique()->fullRegion(), data) << myCR;
	oo << FeEdition::fromArray(WorksTester::string("")) << myCR;
	oo << FeEdition::fromArray(WorksTester::string("hello world")) << myCR;
	bits = WorksTester::string("hello world!");
	/* << (FeEdition fromArray: bits
					with: NULL
					with: IntegerSpace make getDescending) << myCR
				<< (FeEdition fromArray: bits
					with: (IntegerSpace make interval: (IntegerPos 
		make: 100) with: (IntegerPos make: 113))
					with: IntegerSpace make getDescending) << myCR */
	oo << FeEdition::fromArray(bits) << myCR << FeEdition::fromArray(bits, IntegerSpace::make ()->interval(IntegerPos::make (10), IntegerPos::make (22))) << myCR;
	oo << "Making Editions test finished" << myCR << myCR;
}


void WorksTester::ownerTestOn (ostream& oo){
	SPTR(FeWork) work;
	SPTR(FeClub) club;
	SPTR(FeEdition) edition;
	
	club = CAST(FeClub,FeServer::get(FeServer::publicClubID()));
	oo << "Club: " << club << " owned by: " << club->owner() << myCR;
	{	FLUID_BIND(InitialOwner,CurrentAuthor.fluidGet()) {
			work = FeWork::make (FeEdition::fromArray(WorksTester::string("The one I can change.")));
		}
	}
	oo << "Work: " << work << " owned by: " << work->owner() << myCR;
	edition = 
			FeEdition::fromArray(PrimSpec::pointer()->arrayWithTwo(work, club), WorksTester::sequence("changeable")->asRegion()->with(WorksTester::sequence("permanent")), SequenceSpace::make ()->ascending());
	oo << "Set owners of: " << edition << myCR;
	oo << "result: " << edition->setRangeOwners(FeServer::publicClubID()) << myCR;
	oo << "Club: " << club << " owned by: " << club->owner() << myCR;
	oo << "Work: " << work << " owned by: " << work->owner() << myCR;
	oo << myCR;
}


void WorksTester::sponsorTestOn (ostream& oo){
	/* Test the sponsoring mechanism */
	
	SPTR(FeClub) club;
	SPTR(FeClub) testClub;
	SPTR(FeEdition) blank;
	SPTR(FeWork) w1;
	SPTR(FeWork) w2;
	
	testClub = CAST(FeClub,FeServer::get(CurrentAuthor.fluidGet()));
	club = FeClub::make (FeClubDescription::make (FeSet::make (CAST(PtrArray,PrimSpec::pointer()->arrayWith(FeServer::get(CurrentAuthor.fluidGet())))), FeWallLockSmith::make ())->edition());
	blank = FeEdition::fromArray(UInt8Array::string("blank"));
	w1 = FeWork::make (blank);
	FeServer::assignID(w1);
	w2 = FeWork::make (blank);
	FeServer::assignID(w1);
	oo << "Initially " << myCR << "sponsored by Test: " << testClub->sponsoredWorks() << myCR << "sponsored by new: " << club->sponsoredWorks() << myCR << "work 1 sponsors: " << w1->sponsors() << myCR << "work 2 sponsors: " << w2->sponsors() << myCR;
	w1->sponsor(CAST(IDRegion,CurrentAuthor.fluidGet()->asRegion()));
	w2->sponsor(CAST(IDRegion,CurrentAuthor.fluidGet()->asRegion()->with(FeServer::iDOf(club))));
	oo << "After sponsoring " << myCR << "sponsored by Test: " << testClub->sponsoredWorks() << myCR << "sponsored by new: " << club->sponsoredWorks() << myCR << "work 1 sponsors: " << w1->sponsors() << myCR << "work 2 sponsors: " << w2->sponsors() << myCR;
	w1->unsponsor(CAST(IDRegion,CurrentAuthor.fluidGet()->asRegion()));
	w2->unsponsor(CAST(IDRegion,CurrentAuthor.fluidGet()->asRegion()->with(FeServer::iDOf(club))));
	oo << "After unsponsoring " << myCR << "sponsored by Test: " << testClub->sponsoredWorks() << myCR << "sponsored by new: " << club->sponsoredWorks() << myCR << "work 1 sponsors: " << w1->sponsors() << myCR << "work 2 sponsors: " << w2->sponsors() << myCR;
	/* Thing to do !!!! */
	
	/* get rid of persistent info */
	/* Thing to do !!!! */
	
}


void WorksTester::transcludersBugTestOn (ostream& oo){
	SPTR(FeText) text;
	SPTR(FeEdition) refs;
	SPTR(FeWork) work;
	SPTR(FeFillRangeDetector) detector;
	SPTR(FeEdition) container;
	SPTR(FeText) text2;
	SPTR(PtrArray) values;
	
	oo << myCR << myCR << "Transcluders bug test" << myCR << myCR;
	/* Test a bug in the transcluders mechanism:
				if E1 = {x -> E2}, then E1 transcluders will be 
		triggered by an Edition containing E2 */
	text = FeText::make (CAST(PrimDataArray,WorksTester::string("oops")));
	container = FeEdition::fromOne(IntegerPos::make (1), text->edition());
	refs = container->transcluders(FeWrapperSpec::get(WorksTester::sequence("HyperRef"))->filter());
	detector = WorksTestFillRangeDetector::make (oo, "Should not have been transcluded by ");
	refs->addFillRangeDetector(detector);
	work = FeWork::make (FeSingleRef::make (text->edition())->edition());
	refs->removeFillRangeDetector(detector);
	/* if E1 = {x -> E2, y -> E3}, then E1 transcluders may be 
		triggered by another separately created Edition 
		containing E1 & E2? */
	values = PtrArray::nulls(2);
	text2 = FeText::make (CAST(PrimDataArray,WorksTester::string("oops")));
	values->store(UInt32Zero, text->edition());
	values->store(1, text2->edition());
	container = FeEdition::fromArray(values);
	refs = container->transcluders(FeWrapperSpec::get(WorksTester::sequence("HyperRef"))->filter());
	refs->addFillRangeDetector(detector);
	work->revise(FeEdition::fromArray(values));
	refs->removeFillRangeDetector(detector);
}


void WorksTester::transclusionsTestOn (ostream& oo){
	/* Test the transclusions query */
	
	SPTR(FeText) text;
	IntegerVar n;
	SPTR(FeEdition) texts;
	SPTR(FeEdition) refs;
	SPTR(FeFillRangeDetector) detector;
	SPTR(FeWork) work;
	SPTR(IntegerRegion) interval;
	
	oo << myCR << myCR << "Transclusions test" << myCR << myCR;
	text = FeText::make (CAST(PrimDataArray,WorksTester::string("(abcdefghijklmnopqrstuvwxyz)")));
	n = text->count();
	work = FeWork::make (FeSingleRef::make (text->edition())->edition());
	texts = text->edition()->rangeTranscluders(NULL, FeWrapperSpec::get(WorksTester::sequence("Text"))->filter());
	refs = text->edition()->rangeTranscluders(NULL, FeWrapperSpec::get(WorksTester::sequence("HyperRef"))->filter());
	detector = WorksTestFillRangeDetector::make (oo, "Transcluded by ");
	texts->addFillRangeDetector(detector);
	refs->addFillRangeDetector(detector);
	interval = IntegerSpace::make ()->interval(IntegerPos::make (n / 2), IntegerPos::make (n));
	text = text->move(IntegerVarZero, interval);
	work->revise(FeSingleRef::make (text->edition())->edition());
	text = text->extract(CAST(IntegerRegion,IntegerRegion::integerExtent(n / 4, n / 4)->complement()));
	work->revise(FeSingleRef::make (text->edition())->edition());
	text = text->insert(n / 2, FeText::make (CAST(PrimDataArray,WorksTester::string("[ABCDEFGHIJKLMNOPQRSTUVWXYZ]"))));
	work->revise(FeSingleRef::make (text->edition())->edition());
	texts = 
			text->edition()->rangeTranscluders(interval, FeWrapperSpec::get(WorksTester::sequence("Text"))->filter(), NULL, Int32Zero, texts);
	refs = 
			text->edition()->rangeTranscluders(interval, FeWrapperSpec::get(WorksTester::sequence("HyperRef"))->filter(), NULL, Int32Zero, refs);
	text = text->extract(IntegerSpace::make ()->above(IntegerPos::make (n / 2), TRUE));
	work->revise(FeSingleRef::make (text->edition())->edition());
	text = text->extract(IntegerSpace::make ()->below(IntegerPos::make (n), FALSE));
	work->revise(FeSingleRef::make (text->edition())->edition());
	text = text->move(IntegerVarZero, interval);
	work->revise(FeSingleRef::make (text->edition())->edition());
	texts->removeFillRangeDetector(CAST(FeFillRangeDetector,detector));
	refs->removeFillRangeDetector(CAST(FeFillRangeDetector,detector));
}


void WorksTester::workTestOn (ostream& oo){
	/* Try the various operations on Works */
	
	SPTR(FeEdition) e1;
	SPTR(FeWork) w1;
	SPTR(FeKeyMaster) km;
	
	e1 = FeEdition::fromArray(WorksTester::string("hello world"));
	w1 = FeWork::make (e1);
	this->dumpWorkOn(oo, "As newly created ", w1);
	w1->addStatusDetector(WorksTestStatusDetector::make (oo, "\nWork 1"));
	w1->release();
	this->dumpWorkOn(oo, "With authority restored", w1);
	w1->grab();
	this->dumpWorkOn(oo, "Grabbed", w1);
	{	FLUID_BIND(CurrentKeyMaster,CAST(BooLock,FeServer::loginByName(Sequence::string("Test")))->boo()) {
			w1->grab();
			this->dumpWorkOn(oo, "Grabbed again", w1);
		}
	}
	w1->requestGrab();
	this->dumpWorkOn(oo, "Grab requested again", w1);
	w1->release();
	this->dumpWorkOn(oo, "Released", w1);
	km = FeKeyMaster::makePublic();
	{	FLUID_BIND(CurrentKeyMaster,km) {
			w1->requestGrab();
			this->dumpWorkOn(oo, "Grab requested yet again", w1);
			km->incorporate(CAST(BooLock,FeServer::loginByName(Sequence::string("Test")))->boo());
			this->dumpWorkOn(oo, "KeyMaster incorporated", w1);
		}
	}
	km->removeLogins(CAST(IDRegion,CurrentAuthor.fluidGet()->asRegion()));
	this->dumpWorkOn(oo, "KeyMaster login removed", w1);
}
/* private: */


void WorksTester::dumpWorkOn (
		ostream& oo, 
		char * tag, 
		APTR(FeWork) work)
{
	/* Print the state and contents of a Work */
	
	oo << myCR << tag << "[";
	if (work->canRead()) {
		oo << work->edition();
	}
	if (work->canRevise()) {
		oo << " (grabbed)";
	}
	oo << "]";
}
/* hooks: */


void WorksTester::restartWorksTester (APTR(Rcvr) /* rcvr *//* = NULL*/){
	myConnection = NULL;
	myCR = "\n";
}

	/* automatic 0-argument constructor */
WorksTester::WorksTester() {}



/* ************************************************************************ *
 * 
 *                    Class WorksTestFillDetector 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FeFillDetector) WorksTestFillDetector::make (ostream& oo, char * tag){
	RETURN_CONSTRUCT(WorksTestFillDetector,(oo, tag));
}
/* triggering */


void WorksTestFillDetector::filled (APTR(FeRangeElement) transclusion){
	
	(*myOutput) << myTag << transclusion << "\n";
	
}
/* private: create */


WorksTestFillDetector::WorksTestFillDetector (ostream& oo, char * tag) {
	
	myOutput = &oo;
	
	myTag = tag;
}



/* ************************************************************************ *
 * 
 *                    Class WorksTestFillRangeDetector 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FeFillRangeDetector) WorksTestFillRangeDetector::make (ostream& oo, char * tag){
	RETURN_CONSTRUCT(WorksTestFillRangeDetector,(oo, tag));
}
/* triggering */


void WorksTestFillRangeDetector::rangeFilled (APTR(FeEdition) transclusions){
	
	(*myOutput) << myTag << transclusions << "\n";
	
}
/* private: create */


WorksTestFillRangeDetector::WorksTestFillRangeDetector (ostream& oo, char * tag) {
	
	myOutput = &oo;
	
	myTag = tag;
}



/* ************************************************************************ *
 * 
 *                    Class WorksTestStatusDetector 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FeStatusDetector) WorksTestStatusDetector::make (ostream& oo, char * tag){
	RETURN_CONSTRUCT(WorksTestStatusDetector,(oo, tag));
}
/* triggering */


void WorksTestStatusDetector::grabbed (
		APTR(FeWork) work, 
		APTR(ID) author, 
		IntegerVar reason)
{
	
	(*myOutput) << myTag << " canRevise (" << author << ")\n";
	
}


void WorksTestStatusDetector::released (APTR(FeWork) work, IntegerVar reason){
	
	(*myOutput) << myTag << " released\n";
	
}
/* private: create */


WorksTestStatusDetector::WorksTestStatusDetector (ostream& oo, char * tag) {
	
	myOutput = &oo;
	
	myTag = tag;
}

#ifndef NKERNELT_SXX
#include "nkernelt.sxx"
#endif /* NKERNELT_SXX */



#endif /* NKERNELT_CXX */

