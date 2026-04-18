#include <stream.h>
#include <string.h>
#include <stdlib.h>

#include "test.hxx"

XU_DEFINE_TYPE(WorksTestFillRangeHook,XuFillRangeHook)

XuFillRangeHookP WorksTestFillRangeHook::make (ostream& oo, char * tag) {
	return new WorksTestFillRangeHook (oo, tag);
}

void WorksTestFillRangeHook::rangeFilled (XuEditionP ident) {
	(*myOutput) <<  myTag << ident;
}

WorksTestFillRangeHook::WorksTestFillRangeHook (ostream& oo, char * tag) {
	myOutput = &oo;
	myTag = tag;
}

XU_DEFINE_TYPE(WorksTestStatusHook,XuStatusHook)

XuStatusHookP WorksTestStatusHook::make (ostream& oo, char * tag) {
	return new WorksTestStatusHook (oo, tag);
}
	
void WorksTestStatusHook::grabbed (XuWorkP work, XuIDP author, XuIntValueP reason) {
	(*myOutput) << myTag << " grabbed " << work << " by " << author << " because " << reason;
}

void WorksTestStatusHook::released (XuWorkP work, XuIntValueP reason) {
	(*myOutput) << myTag << " released " << work << " because " << reason;
}

WorksTestStatusHook::WorksTestStatusHook (ostream& oo, char * tag) {
	myOutput = &oo;
	myTag = tag;
}

void WorksTester::allTestsOn (ostream& oo) {
	XuIDP testID;
	
      XuConnection::current()->recordExerciseCoverage();

    XuDelay {	
	XuCurrentKeyMaster.set (XuBooLock::cast (
		XuServer::loginByName("Test"))->boo ());
	XuCurrentKeyMaster.get ()->incorporate(XuKeyMaster::universalPublic ());
	testID = XuServer::clubID("Test");

	XuInitialOwner.set (testID);
	XuInitialReadClub.set (testID);
	XuInitialEditClub.set (testID);
	XuInitialSponsor.set (testID);
	XuCurrentAuthor.set (testID);
    } XuEndDelay

        this->promiseExerciseOn(oo);
        this->arrayExerciseOn(oo);
	this->crossSpaceExerciseOn(oo);
	this->filterSpaceExerciseOn(oo);
	this->iDSpaceExerciseOn(oo);
	this->integerSpaceExerciseOn(oo);
	this->sequenceSpaceExerciseOn(oo);
	this->integerExerciseOn(oo);
	this->rangeElementExerciseOn(oo);
	this->editionExerciseOn(oo);
	this->workExerciseOn(oo);
	this->stepperExerciseOn(oo);
	this->linkExerciseOn(oo);
	this->wrapperExerciseOn(oo);

	this->regionTestOn(oo);
	this->transclusionsTestOn(oo);
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
	this->ownerTestOn(oo);
	this->labelTestOn(oo);

	oo << "\nRequest numbers with usage count\n";
	XuConnection::current()->reportExerciseCoverage(oo);
}

void WorksTester::promiseExerciseOn (ostream& oo)
{
    oo << "\nPromise exercise\n";

    XuDelay {
	XuPtrArrayP array = XuPtrArray::nulls(1);
	XuIntValueP i = 3;
	array->store (0, i);
	XuPromiseP prom = array->get(0);
	XuIntValueP j = XuIntValue::cast (prom);
	oo << prom << "\n";
	oo << j << "\n";
	oo << XuValue::isTypeOf (prom) << "\n";
	oo << XuValue::isTypeOf (j) << "\n";
	oo << XuValue::cast (prom) << "\n";
	oo << XuValue::cast (j) << "\n";
	oo << prom->hash() << "\n";
	oo << j->hash() << "\n";
	oo << prom->equals (j) << "\n";
	oo << j->equals (prom) << "\n";

	XuPromiseP buff[2];
	XuIntValueP n = array->export (buff, sizeof(buff));
	oo << n << "\n";

	
    } XuEndDelay
}

void WorksTester::arrayExerciseOn (ostream& oo)
{
    oo << "\nArray exercise\n";

    XuDelay {
	XuIntVar i;
	XuIntValueP n;

	float	floats[4];
	floats[0] = 1.23456789;
	floats[1] = 9.78654321;
	floats[2] = -1.11e11;
	floats[3] = 2.2222e-22;
	XuFloatArrayP floatsA = XuFloatArray::import (4, 32, floats);
	oo << "floats = " << floatsA << '\n'
		<< "count = " << floatsA->count() << '\n'
		<< "bitCount = " << floatsA->bitCount() << '\n';
	for (i = 0; i < 4; i++) {
		oo << "floatsA->get (" << i << ") = "
			<< XuFloatValue::cast (floatsA->get (i)) << '\n';
	}
	n = floatsA->export (floats, 4 * sizeof (float));
	n->force ();
	oo << "export = " << n << '\n';
	for (i = 0; i < 4; i++) {
		oo << "floats[" << i << "] = " << floats[i] << '\n';
	}

	double	doubles[4];
	doubles[0] = 1.23456789;
	doubles[1] = 9.78654321;
	doubles[2] = -1.11e11;
	doubles[3] = 2.2222e-22;
	XuFloatArrayP doublesA = XuFloatArray::import (4, 64, doubles);
	oo << "doubles = " << doublesA << '\n'
		<< "count = " << doublesA->count() << '\n'
		<< "bitCount = " << doublesA->bitCount() << '\n';
	for (i = 0; i < 4; i++) {
		oo << "doublesA->get (" << i << ") = "
			<< XuFloatValue::cast (doublesA->get (i)) << '\n';
	}
	n = doublesA->export (doubles, 4 * sizeof (double));
	n->force ();
	oo << "export = " << n << '\n';
	for (i = 0; i < 4; i++) {
		oo << "doubles[" << i << "] = " << doubles[i] << '\n';
	}

	XuUIntVar	uints[4];
	uints[0] = 123;
	uints[1] = 456789;
	uints[2] = 9876543;
	uints[3] = 21;
	XuIntArrayP uintsA = XuIntArray::import (4, sizeof(XuIntVar)*8, uints);
	oo << "uints = " << uintsA << '\n'
		<< "count = " << uintsA->count() << '\n'
		<< "bitCount = " << uintsA->bitCount() << '\n';
	for (i = 0; i < 4; i++) {
		oo << "uintsA->get (" << i << ") = "
			<< XuIntValue::cast (uintsA->get (i)) << '\n';
	}
	n = uintsA->export (uints, 4 * sizeof (int));
	n->force ();
	oo << "export = " << n << '\n';
	for (i = 0; i < 4; i++) {
		oo << "uints[" << i << "] = " << uints[i] << '\n';
	}

	XuIntVar	ints[4];
	ints[0] = 123;
	ints[1] = -456789;
	ints[2] = 1000;
	ints[3] = -1000;
	XuIntArrayP intsA = XuIntArray::import (4, -8 * sizeof(XuIntVar), ints);
	oo << "ints = " << intsA << '\n'
		<< "count = " << intsA->count() << '\n'
		<< "bitCount = " << intsA->bitCount() << '\n';
	for (i = 0; i < 4; i++) {
		oo << "intsA->get (" << i << ") = "
			<< XuIntValue::cast (intsA->get (i)) << '\n';
	}
	n = intsA->export (ints, 4 * sizeof (int));
	n->force ();
	oo << "export = " << n << '\n';
	for (i = 0; i < 4; i++) {
		oo << "ints[" << i << "] = " << ints[i] << '\n';
	}

	char	chars[80];
	strcpy (chars, "The quick brown fox jumps over the lazy dog. NOT!");
	XuIntArrayP charsA = XuIntArray::import (strlen(chars)+1, 8, chars);
	oo << "chars = " << charsA << '\n'
		<< "count = " << charsA->count() << '\n'
		<< "bitCount = " << charsA->bitCount() << '\n';
	for (i = 0; i < 4; i++) {
		oo << "charsA->get (" << i << ") = "
			<< XuIntValue::cast (charsA->get (i)) << '\n';
	}
	chars[49] = 255;
	chars[48] = '\0';
	n = charsA->export (&chars[4], 44);
	n->force ();
	oo << "export = " << n << '\n';
	oo << "string is " << chars << " and marker is " << chars[49] << '\n';

    } XuEndDelay
}

void WorksTester::crossSpaceExerciseOn (ostream& oo) 
{
    oo << "\nCrossSpace exercise\n";

    XuDelay {
	XuIDSpaceP ids = XuIDSpace::global();
	XuCrossSpaceP cs = XuCrossSpace::make (XuPtrArray::with (ids, ids));
	XuIDRegionP emptyIDReg = XuIDRegion::cast(ids->emptyRegion());
	XuCrossRegionP empty0 = XuCrossRegion::cast(cs->emptyRegion());
	XuCrossRegionP empty1 = cs->crossOfRegions (XuPtrArray::with (emptyIDReg, emptyIDReg));
	XuCrossRegionP empty2 = cs->crossOfRegions (XuPtrArray::with (ids->newIDs(1), emptyIDReg));
	XuCrossRegionP empty3 = cs->crossOfRegions (XuPtrArray::with (emptyIDReg, ids->newIDs(1))) ;
	XuCrossRegionP reg = cs->crossOfRegions (XuPtrArray::with (ids->newIDs(1), ids->newIDs(1)));
	oo << emptyIDReg << " " << emptyIDReg->isEmpty() << "\n";
	oo << cs << "\n";
	oo << empty0 << "\n";
	oo << empty1 << "\n";
	oo << empty2 << "\n";
	oo << empty3 << "\n";
	oo << reg << "\n";
	XuTupleP tuple = cs->crossOfPositions (XuPtrArray::with (ids->newID(), ids->newID()));
	oo << tuple << "\n";
	oo << tuple->coordinate(0) << "\n";
    } XuEndDelay
}

void WorksTester::filterSpaceExerciseOn (ostream& oo)
{
    oo << "\nFilterSpace exercise\n";

//    XuDelay {
	XuIntegerSpaceP is = XuIntegerSpace::make();
	XuFilterSpaceP fs = XuFilterSpace::make (is);
	oo << fs << "\n";
	oo << fs->baseSpace() << "\n";
	oo << fs->allFilter (is->above (3, TRUE)) << "\n";
	oo << fs->anyFilter (is->below (7, FALSE)) << "\n";
	oo << fs->position (is->interval (3, 7)) << "\n";
//    } XuEndDelay
}

void WorksTester::iDSpaceExerciseOn (ostream& oo)
{
    oo << "\nIDSpace exercise\n";

    XuDelay {
	XuIDSpaceP ids = XuIDSpace::global();
	XuIDRegionP fullReg = XuIDRegion::cast(ids->fullRegion());
	XuStepperP stomp = fullReg->stepper();
	oo << ids << "\n";
	oo << fullReg << "\n";
	oo << stomp << "\n";
    } XuEndDelay
}

void WorksTester::integerSpaceExerciseOn (ostream& oo)
{
    oo << "\nIntegerSpace exercise\n";

    XuDelay {
	XuIntegerRegionP reg = XuIntegerSpace::make()->interval (3, 7);
	oo << reg << "\n";
	oo << reg->start() << "\n";
	oo << reg->stop() << "\n";

	XuMappingP map5 = 5;
	XuMappingP mapMinus3 = -3;
	XuMappingP multiMap = map5->combine(mapMinus3);
	oo << map5 << "\n";
	oo << mapMinus3 << "\n";
	oo << multiMap << "\n";
	oo << map5->inverse() << "\n";
	oo << multiMap->inverse() << "\n";
	oo << map5->of(7) << "\n";
	oo << multiMap->of(7) << "\n";
	oo << map5->ofAll(reg) << "\n";
	oo << multiMap->ofAll(reg) << "\n";
	oo << map5->restrict(reg) << "\n";
	oo << multiMap->restrict(reg) << "\n";

	XuOrderSpecP up = XuIntegerSpace::make()->ascending();
	XuOrderSpecP down = up->reversed();
	oo << up << "\n";
	oo << down << "\n";
	oo << down->equals(XuIntegerSpace::make()->descending()) << "\n";
	oo << up->follows (3, 5) << "\n";
	oo << up->follows (5, 3) << "\n";
	oo << up->follows (3, 3) << "\n";
	oo << down->follows (3, 5) << "\n";
	oo << down->follows (5, 3) << "\n";
	oo << down->follows (3, 3) << "\n";
    } XuEndDelay
}

void WorksTester::sequenceSpaceExerciseOn (ostream& oo)
{
    oo << "\nSequenceSpace exercise\n";

    XuDelay {
	XuSequenceSpaceP ss = XuSequenceSpace::make();
	XuSequenceP foo = "foo";
	XuSequenceP bar = "bar";
	oo << foo << "\n";
	oo << bar << "\n";
	oo << ss->interval (foo, bar) << "\n";
	oo << ss->interval (bar, foo) << "\n";
	oo << ss->position ("baz", 3) << "\n";
	oo << ss->position ("baz", -3) << "\n";
	oo << ss->mapping (3, "zorch") << "\n";
    } XuEndDelay
}

void WorksTester::integerExerciseOn (ostream& oo) 
{
    oo << "\nInteger exercise\n";

    XuDelay {
	XuIntValueP i = 3;
	oo << i << "\n";

	i = 0;
	oo << i << "\n";

	i = 1;
	oo << i << "\n";

	i = -1;
	oo << i << "\n";
    } XuEndDelay
}

void WorksTester::rangeElementExerciseOn (ostream& oo) 
{
    oo << "\nRangeElement exercise\n";

    XuDelay {
	XuRangeElementP a = XuRangeElement::placeHolder();
	XuRangeElementP b = XuRangeElement::placeHolder();
	oo << a << "\n";
	oo << b << "\n";
	oo << a->hash() << "\n";
	oo << b->hash() << "\n";
	oo << a->equals(b) << "\n";
	oo << a->isIdentical(b) << "\n";
	oo << b->equals(a) << "\n";
	oo << b->isIdentical(a) << "\n";
	a->makeIdentical(b);
	oo << a << "\n";
	oo << b << "\n";
	oo << a->hash() << "\n";
	oo << b->hash() << "\n";
	oo << a->equals(b) << "\n";
	oo << a->isIdentical(b) << "\n";
	oo << b->equals(a) << "\n";
	oo << b->isIdentical(a) << "\n";
	a = a->again();
	oo << a << "\n";
	oo << b << "\n";
	oo << a->hash() << "\n";
	oo << b->hash() << "\n";
	oo << a->equals(b) << "\n";
	oo << a->isIdentical(b) << "\n";
	oo << b->equals(a) << "\n";
	oo << b->isIdentical(a) << "\n";
    } XuEndDelay
}

void WorksTester::editionExerciseOn (ostream& oo) 
{
    oo << "\nEdition exercise\n";

    XuDelay {
	XuIntegerSpaceP is = XuIntegerSpace::make();
	XuIntegerRegionP below4 = is->below(4, FALSE);
	XuRangeElementP pl = XuRangeElement::placeHolder();

	XuEditionP edition1 = XuEdition::fromOne(3, pl);
	XuEditionP edition2 = XuEdition::cast (edition1->relabelled (XuLabel::make()));
	oo << edition1 << "\n";
	oo << edition2 << "\n";
	oo << edition1->label()->equals (edition2->label()) << "\n";
	oo << edition1->equals (edition2) << "\n";
	oo << edition1->isIdentical (edition2) << "\n";
	oo << edition1->label()->isIdentical (edition2->label()) << "\n";
	oo << pl->transcluders() << "\n";

	oo << edition1->hasPosition(1) << "\n";
	oo << edition1->hasPosition(3) << "\n";

	XuEditionP edition3 = edition1->transformedBy(5);
	XuEditionP edition4 = edition1->combine(edition3);
	oo << edition3 << "\n";
	oo << edition1->mapSharedOnto (edition2) << "\n";
	oo << edition1->mapSharedOnto (edition3) << "\n";
	oo << edition1->mapSharedOnto (edition4) << "\n";
	oo << edition4->mapSharedOnto (edition1) << "\n";
	oo << edition1->mapSharedTo (edition4) << "\n";
	oo << edition4->mapSharedTo (edition1) << "\n";
	oo << edition1->notSharedWith (edition4) << "\n";
	oo << edition1->notSharedWith (edition4, 0) << "\n";
	oo << edition1->sharedRegion (edition4) << "\n";
	oo << edition1->sharedRegion (edition4, 0) << "\n";
	oo << edition1->sharedWith (edition4) << "\n";
	oo << edition1->sharedWith (edition4, 0) << "\n";
	oo << edition1->rangeTranscluders() << "\n";
	oo << edition4->rangeTranscluders (below4) << "\n";

	XuFilterSpaceP endorsementFS = XuFilterSpace::make (XuCrossSpace::endorsements());
	XuFilterP fullFilter = XuFilter::cast (endorsementFS->fullRegion());
	oo << edition4->rangeTranscluders (below4, fullFilter, fullFilter) << "\n";
	oo << edition4->rangeTranscluders (below4, fullFilter, fullFilter, 0) << "\n";

	oo << edition4->retrieve() << "\n";
	oo << edition4->retrieve(below4) << "\n";
	oo << edition4->retrieve(below4, is->descending()) << "\n";
	oo << edition4->retrieve(below4, is->descending(), 0) << "\n";

	oo << edition1->visibleEndorsements() << "\n";
    } XuEndDelay
}

void WorksTester::workExerciseOn (ostream& oo) 
{
    oo << "\nWork exercise\n";

    XuDelay {
	XuIntegerSpaceP is = XuIntegerSpace::make();
	XuEditionP empty1 = XuEdition::empty(is);
	XuEditionP empty2 = XuEdition::empty(is);

	XuWorkP work1 = XuWork::make (empty1);
	oo << work1 << "\n";
	oo << work1->lastRevisionAuthor() << "\n";
	oo << work1->lastRevisionTime() << "\n";

	work1->revise (empty2);
	oo << work1 << "\n";
	oo << work1->lastRevisionAuthor() << "\n";
	oo << work1->lastRevisionTime() << "\n";

    } XuEndDelay
}

void WorksTester::stepperExerciseOn (ostream& oo) 
{
    oo << "\nStepper exercise\n";

    XuDelay {
	XuIntegerSpaceP is = XuIntegerSpace::make();
	XuIntegerRegionP reg = is->interval(-100, 10000);
	XuEditionP hello = XuEdition::fromArray ("hello world\n");
	XuStepperP a = is->emptyRegion()->stepper();
	XuStepperP b = is->fullRegion()->stepper();
	XuStepperP c = reg->stepper();
	XuStepperP d = reg->stepper (is->descending());
	XuTableStepperP e = hello->stepper();

	oo << reg << "\n";
	oo << hello << "\n";

	oo << a << "\n";
	oo << a->theOne() << "\n";
	oo << a->stepMany() << "\n";
	oo << a->stepMany(5) << "\n";
	
	oo << b << "\n";
	oo << b->theOne() << "\n";
	oo << b->stepMany() << "\n";
	oo << b->stepMany(5) << "\n";
	
	oo << c<< "\n";
	oo << c->theOne() << "\n";
	oo << c->stepMany() << "\n";
	oo << c->stepMany(5) << "\n";
	
	oo << d << "\n";
	oo << d->theOne() << "\n";
	oo << d->stepMany() << "\n";
	oo << d->stepMany(5) << "\n";

	oo << e << "\n";
	oo << e->theOne() << "\n";
	oo << e->stepMany() << "\n";
	oo << e->stepMany(5) << "\n";
	oo << e->stepManyPairs() << "\n";
	oo << e->stepManyPairs(5) << "\n";
	
    } XuEndDelay
}

void WorksTester::linkExerciseOn (ostream& oo) 
{
    oo << "\nLink exercise\n";

    XuDelay {
	XuEditionP hello = XuEdition::fromArray ("hello world\n");
	XuEditionP goodbye = XuEdition::fromArray ("goodbye sweet world\n");
	XuSetP types = XuSet::make();
	XuSingleRefP left = XuSingleRef::make (hello, XuWork::make(hello));
	XuSingleRefP right = XuSingleRef::make (goodbye, 
					        XuWork::make(hello), 
					        XuWork::make(hello));
	XuHyperLinkP link = XuHyperLink::make (types, left, right);

	oo << types << "\n";
	oo << left << "\n";
	oo << right << "\n";
	oo << link << "\n";

    } XuEndDelay
}

void WorksTester::wrapperExerciseOn (ostream& oo) 
{
    oo << "\nWrapper exercise\n";

    XuDelay {

	/* should do a bunch of XuSet exercising */

	XuIntegerSpaceP is = XuIntegerSpace::make();
	XuTextP hello = XuText::make ("hello texty world\n");
	XuTextP bye = XuText::make ("goodbye testy world\n");
	oo << hello << "\n";
	oo << bye << "\n";
	oo << hello->replace (is->interval(0, 5), 
			      bye->extract(is->interval(0, 7))) << "\n";

    } XuEndDelay
}

void WorksTester::compareTestOn (ostream& oo){

    XuDelay {

	oo << "Test the various version comparision operations\n";
	
	XuEditionP a;
	XuEditionP b;
	XuIntegerSpaceP is = XuIntegerSpace::make ();
	
	a = XuEdition::placeHolders(is->interval (0,100));
	b = a->copy(is->below(50, FALSE))
		->transformedBy(100)
		->combine(XuEdition::placeHolders(is->interval (0, 50)))
		->combine(a->copy(is->interval (25, 75))
			->transformedBy(25));

	oo << "a sharedWith b: " << a->sharedWith(b) << '\n'
		<< "a notSharedWith b: " << a->notSharedWith(b) << '\n'
		<< "a sharedRegion b: " << a->sharedRegion(b) << '\n'
		<< "a mapSharedTo b: " << a->mapSharedTo(b) << '\n'
		<< "a positionsOf a[50]: " << a->positionsOf(a->get(is->position (50))) << '\n'
		<< "b sharedWith a: " << b->sharedWith(a) << '\n'
		<< "b notSharedWith a: " << b->notSharedWith(a) << '\n'
		<< "b mapSharedTo a: " << b->mapSharedTo(a) << '\n'
		<< "b sharedRegion a: " << b->sharedRegion(a) << '\n'
		<< "b positionsOf a[50]: " << b->positionsOf(a->get(is->position (50))) << '\n';
    } XuEndDelay
}

void WorksTester::crossTestOn (ostream& oo){
	XuPromiseP four[4];
	XuIDSpaceP is;
	XuCrossSpaceP cross;
	XuEditionP doc;
	
    XuDelay {

	oo << "\nCrossSpace retrieval test\n";

	is = XuIDSpace::unique();
	four[0] = is;
	four[1] = XuRealSpace::make ();
	four[2] = XuRealSpace::make ();
	four[3] = XuRealSpace::make ();
	cross = XuCrossSpace::make (XuPtrArray::import (4, four));
	doc = XuEdition::empty(cross);
	for (XuIntVar i = 1; i <= 10; i++) {
			four[0] = is->newID()->asRegion();
			four[1] = XuRealSpace::make ()->interval(1.0 * i, 1.0 * (i + 4));
			four[2] = XuRealSpace::make ()->interval(1.0 * i, 1.0 * (21 - i));
			four[3] = XuRealSpace::make ()->interval(1.0 * i, 1.0 * (i + 1));
			doc = doc->combine(XuEdition::fromAll(
				cross->crossOfRegions(XuPtrArray::import (4, four)),
				XuDataHolder::make (i)));
	}

    } XuEndDelay

	for (XuIntVar j = 1; j <= 3; j++) {
			oo << "Looking for dimension " << j << " >= 10\n";
			XuStepperP pieces = doc->copy(cross->extrusion(j,
					XuRealSpace::make ()->above(10.0, TRUE)))
				->retrieve();
			XuFor(XuElementBundle,bundle,pieces) {
				oo << "found " << bundle->element() << " at " << bundle->region() << '\n';
			} XuEndFor
	}
}


void WorksTester::editionTestOn (ostream& oo){

    XuDelay {

	oo << "Test the simple Edition operations\n";
	
	XuEditionP edition;
	XuIntegerSpaceP is = XuIntegerSpace::make ();
	
	edition = XuEdition::empty(is);
		oo << "initially: " << edition << '\n'
		<< " coordinateSpace: " << edition->coordinateSpace() << '\n'
		<< " count: " << edition->count() << '\n'
		<< " domain: " << edition->domain() << '\n'
		<< " isEmpty: " << edition->isEmpty() << '\n'
		<< " isFinite: " << edition->isFinite() << '\n';
	edition = edition->with(0,
		XuRangeElement::placeHolder());
	oo << "with(0): " << edition << '\n'
		<< " theOne: " << edition->theOne() << '\n';
	edition = edition->withAll(is->above(1,TRUE),
		XuDataHolder::make (65));
	oo << "withAll: " << edition << '\n'
		<< " domain: " << edition->domain() << '\n'
		<< " isEmpty: " << edition->isEmpty() << '\n'
		<< " isFinite: " << edition->isFinite() << '\n';
	oo << "stepper:" << '\n';
	XuForPairs(XuPosition,k,XuRangeElement,v,(edition->stepper(is->interval (0, 2)))) {
		oo << " " << k << " -> " << v << '\n';
	} XuEndForPairs

	edition = edition->without (3);
	oo << "without 3" << edition << '\n';
	edition = edition->withoutAll(is->above(2,TRUE));
	oo << "withoutAll: " << edition << '\n'
		<< " count: " << edition->count() << '\n'
		<< " domain: " << edition->domain() << '\n'
		<< " isEmpty: " << edition->isEmpty() << '\n'
		<< " isFinite: " << edition->isFinite() << '\n'
		<< " get 1: " << edition->get(1) << '\n';
	oo << "combined: " << edition->combine(XuEdition::fromOne(5, XuRangeElement::placeHolder())) << '\n';
	oo << "replaced: " << edition->replace(XuEdition::fromOne(1, XuRangeElement::placeHolder())) << '\n';

    } XuEndDelay
}


void WorksTester::endorseTestOn (ostream& oo){

    XuDelay {

	oo << "Test endorsing and unendorsing Editions and Works\n";
	
	XuEditionP e1;
	XuWorkP w1;
	XuIDP iD;
	XuIDRegionP userRegion;
	
	e1 = XuEdition::empty(XuIntegerSpace::make ());
	w1 = XuWork::make (e1);
	oo << "Initial endorsements:" << '\n'
		<< "  on Edition: " << e1->endorsements() << '\n'
		<< "  on Work: " << w1->endorsements() << '\n'
		<< '\n';
	userRegion = XuIDRegion::cast (XuCurrentAuthor.get ()->asRegion());
	e1->endorse(XuCrossRegion::endorsements(userRegion, userRegion));
	iD = XuIDSpace::global()->newID();
	w1->endorse(XuCrossRegion::endorsements(userRegion, XuIDRegion::cast (iD->asRegion())));
	oo << "After endorsing:" << '\n'
		<< "  on Edition: " << e1->endorsements() << '\n'
		<< "  on Work: " << w1->endorsements() << '\n';
	e1->retract(XuCrossRegion::endorsements(userRegion, userRegion));
	w1->retract(XuCrossRegion::endorsements(userRegion, XuIDRegion::cast (iD->asRegion())));
	oo << "After unendorsing:" << '\n'
		<< "  on Edition: " << e1->endorsements() << '\n'
		<< "  on Work: " << w1->endorsements() << '\n';

    } XuEndDelay
}


void WorksTester::globalIDTestOn (ostream& oo){

	oo << "Test assigning and retrieving by global IDs\n";
	
	XuRangeElementP p1;
	XuIDP id1a;
	XuIDP id1b;
	XuIDRegionP ids;
	XuRangeElementP p2;
	XuIDP id2;
	XuEditionP ed;
	
	p1 = XuRangeElement::placeHolder();
	XuIf (!(ids = XuServer::iDsOf(p1))->isEmpty()) {
		oo << "Newly created place holder " << p1
			<< " should not have had any IDs but was reported to have " << ids << '\n';
	} XuEndIf
	id1a = XuServer::assignID(p1);
	XuIf (!(ids = XuServer::iDsOf(p1))->equals(id1a->asRegion())) {
		oo << "PlaceHolder " << p1
			<< " should have IDs " << id1a->asRegion()
			<< " but was reported to have IDs " << ids << '\n';
	} XuEndIf
	id1b = XuServer::assignID(p1);
	XuIf (!(ids = XuServer::iDsOf(p1))->equals(id1a->asRegion()->with(id1b))) {
		oo << "PlaceHolder " << p1 << " should have IDs " << id1a->asRegion()->with(id1b) << " but was reported to have IDs " << ids << '\n';
	} XuEndIf
	p2 = XuRangeElement::placeHolder();
	id2 = XuServer::assignID(p2);
	ed = XuEdition::fromOne(0, p1)->combine(XuEdition::fromOne(1, p2));
	XuIf (!(ids = XuServer::iDsOfRange(ed))->equals(id1a->asRegion()->with(id1b)->with(id2))) {
		oo << "PlaceHolders " << ed << " should have IDs " << id1a->asRegion()->with(id1b)->with(id2) << " but was reported to have IDs " << ids << '\n';
	} XuEndIf
	oo << "Global ID assignment test successful\n";
}


void WorksTester::historyTestOn (ostream& oo){
	XuServerP s;
	XuWorkP work;

    XuDelay {

	oo << "Test history mechanism\n";
	
	work = XuWork::make(XuEdition::fromArray("Howdy doody."));
	work->setHistoryClub(XuServer::publicClubID());
	work->revise(XuEdition::fromArray("TLC"));
	work->revise(XuEdition::fromArray("Much better."));
	oo << "The trail is: " << work->revisions() << '\n';
	XuForPairs(XuPosition,key,XuWork,value,(work->revisions()->stepper())) {
		oo << key << "->" << XuArrayBundle::cast (value->edition()->retrieve()->theOne())->array() << '\n';
	} XuEndForPairs
	oo << '\n';

    } XuEndDelay
}


void WorksTester::kmTestOn (ostream& oo){

    XuDelay {

	oo << "Test the operation of KeyMasters\n";
	
	XuKeyMasterP km;
	XuWrapperSpecP clubspec;
	XuClubP test;
	XuClubP club1;
	XuStatusDetectorP detect1;
	XuWorkP work1;
	XuClubP club2;
	XuStatusDetectorP detect2;
	XuWorkP work2;
	XuClubDescriptionP desc;
	XuIntegerSpaceP is = XuIntegerSpace::make ();
	
	km = XuCurrentKeyMaster.get()->copy();
	XuBind(XuCurrentKeyMaster,km) {
		clubspec = XuWrapperSpec::get("ClubDescription");
		test = XuClub::cast (XuServer::get(XuCurrentAuthor.get ()));
		club1 = XuClub::make(
			XuClubDescription::make(XuSet::make(),
			XuBooLockSmith::make())->edition());
		oo << "Club1 is initially " << clubspec->wrap(club1->edition()) << '\n'
			<< "and XuCurrentKeyMaster is " << km << '\n'
			<< '\n';
		club2 = XuClub::make(
			XuClubDescription::make(XuSet::make(),
			XuBooLockSmith::make())->edition());
		oo << "Club 2 is initially " << clubspec->wrap(club2->edition()) << '\n'
			<< "and XuCurrentKeyMaster is " << km << '\n'
			<< '\n';
		XuBind(XuInitialEditClub,XuServer::iDOf(club1)) {
			work1 = XuWork::make(XuEdition::empty(is));
		} XuEndBind
		detect1 = work1->addStatusDetector(
			WorksTestStatusHook::make (oo, "\nWork 1"));
		oo << "Giving Work 1 edit authority to Club 1" << '\n';
		work1->requestGrab();
		XuBind(XuInitialEditClub,XuServer::iDOf(club2)) {
			work2 = XuWork::make(XuEdition::empty(is));
		} XuEndBind
		detect2 = work2->addStatusDetector(
			WorksTestStatusHook::make (oo, "\nWork 2"));
		oo << "Giving Work 2 edit authority to Club 2" << '\n';
		work2->requestGrab();
		desc = XuClubDescription::cast (clubspec->wrap(club1->edition()));
		club1->revise(desc->withMembership(desc->membership()->with(test))->edition());
		oo << "Club 1 should now have Test as a member: " << clubspec->wrap(club1->edition()) << '\n'
			<< "So XuCurrentKeyMaster should have Club 1 authority: " << km->actualAuthority() << '\n'
			<< "and Work 1 should have become grabbed: " << work1->canRevise() << '\n'
			<< '\n';
		desc = XuClubDescription::cast (clubspec->wrap(club2->edition()));
		club2->revise(desc->withMembership(desc->membership()->with(club1))->edition());
		oo << "Club 2 should now have Club 1 as a member: " << clubspec->wrap(club2->edition()) << '\n'
			<< "So XuCurrentKeyMaster should have Club 2 authority: " << km->actualAuthority() << '\n'
			<< "and Work 2 should have become grabbed: " << work2->canRevise() << '\n'
			<< '\n';
		desc = XuClubDescription::cast (clubspec->wrap(club2->edition()));
		club2->revise(desc->withMembership(desc->membership()->without(club1)->with(test))->edition());
		oo << "Club 2 should have Public but not Club 1 as a member: " << clubspec->wrap(club2->edition()) << '\n'
			<< "So XuCurrentKeyMaster should retain Club 2 authority: " << km->actualAuthority() << '\n'
			<< "and Work 2 should remain grabbed: " << work2->canRevise() << '\n'
			<< '\n';
		km->removeLogins(XuIDRegion::cast (
			XuServer::publicClubID()->asRegion()));
		oo << "The combined KeyMaster should have lost Public & Club 2 authority: " << km->loginAuthority() << '\n'
			<< km->actualAuthority() << '\n'
			<< "and Work 2 should have become released but unreadable:" << " canRevise " << work2->canRevise() << " canRead " << work2->canRead() << '\n'
			<< '\n';
		desc = XuClubDescription::cast (clubspec->wrap(club1->edition()));
		club1->revise(desc->withMembership(desc->membership()->without(test))->edition());
		oo << "Club 1 should no longer have Test as a member: " << clubspec->wrap(club1->edition()) << '\n';
		oo << "So XuCurrentKeyMaster should not have Club 1 authority: " << km->actualAuthority() << '\n';
		oo << "and Work 1 should have become released and unreadable:" << " canRevise " << work1->canRevise() << " canRead " << work1->canRead() << '\n';
		oo << '\n';
		detect2->destroy ();
		detect1->destroy ();
		club1->release();
		club2->release();
	} XuEndBind
	/* Clean up persistent information in Server */
	/* Thing to do !!!! */
    } XuEndDelay
	
}


void WorksTester::labelTestOn (ostream& oo){
	XuEditionP edition;
	XuEditionP e1;
	XuEditionP e2;
	XuEditionP e3;
	XuEditionP e4;
	XuEditionP e1prime;
	XuEditionP edition2;
	XuArrayP es;

    XuDelay {

	oo << "Test label operations\n";

	e1 = XuEdition::fromArray("First Edition");
	e2 = XuEdition::fromArray("Second Edition");
	e3 = XuEdition::fromArray("Third Edition");
	e4 = XuEdition::fromArray("Fourth Edition");
	edition = XuEdition::fromOne (0, e1)
		->with (1, e2)
		->with (2, XuWork::make(e1));
	oo << "Labels:" << '\n';
	oo << " " << e1->label() << " " << e2->label() << " " << e3->label() << " " << e4->label() << '\n';
	oo << "labelled e1: " << edition->positionsLabelled(e1->label()) << '\n';
	e1prime = XuEdition::cast (edition->get(0))->with(1, XuRangeElement::placeHolder());
	edition2 = edition->with(0, e1prime);
	oo << "edit e1: " << edition2->positionsLabelled(e1->label()) << '\n';
	oo << "labelled e2: " << edition2->positionsLabelled(e2->label()) << '\n';
	oo << "rebind e2: " << edition2->rebind(1, e3)->positionsLabelled(e2->label()) << '\n';
	oo << "duplicate e1: " << edition2->with(1, e1)->positionsLabelled(e1->label()) << '\n';
	oo << '\n';

    } XuEndDelay
}


void WorksTester::makeEditionTestOn (ostream& oo){

    XuDelay {

	oo << "Try making Editions in a variety of ways\n";
	
	XuEditionP edn;
	XuRangeElementP place;
	XuDataHolderP data;
	XuArrayP bits;
	XuIntegerSpaceP is = XuIntegerSpace::make ();
	
	oo << (edn = XuEdition::empty(XuSequenceSpace::make ())) << '\n'
		<< XuEdition::empty(is) << '\n';
	oo << XuEdition::placeHolders(is->interval (0, 10)) << '\n'
		<< XuEdition::placeHolders(XuSequenceSpace::make ()->fullRegion()) << '\n';
	data = XuDataHolder::make(3);
	place = XuRangeElement::placeHolder();
	oo << XuEdition::fromOne(is->position (0), edn) << '\n'
		<< XuEdition::fromOne(1, place) << '\n'
		<< XuEdition::fromOne(2, data) << '\n';
	oo << XuEdition::fromAll(is->above(10, TRUE), edn) << '\n'
		<< XuEdition::fromAll(is->below(100, FALSE), place) << '\n'
		<< XuEdition::fromAll(XuIDSpace::unique()->fullRegion(), data) << '\n';
	oo << XuEdition::fromArray("hello world") << '\n';
	bits = "hello world!";
	/* << (XuServer current newEdition: bits
					with: XU_NULL
					with: XuIntegerSpace make getDescending) << '\n'
				<< (XuServer current newEdition: bits
					with: (IntegerRegion make: 100 with: 112)
					with: XuIntegerSpace make getDescending) << '\n' */
	oo << XuEdition::fromArray(bits) << '\n'
		<< XuEdition::fromArray(bits, is->interval (10, 22)) << '\n';
	oo << "Making Editions test finished" << '\n'
		<< '\n';

    } XuEndDelay
}


void WorksTester::ownerTestOn (ostream& oo){
	XuWorkP work;
	XuClubP club;
	XuEditionP edition;
	
    XuDelay {

	oo << "Test ownership mechanism\n";

	club = XuClub::cast (XuServer::get(XuServer::publicClubID()));
	oo << "Club: " << club << " owned by: " << club->owner() << '\n';
	XuBind(XuInitialOwner,XuCurrentAuthor.get ()) {
		work = XuWork::make(XuEdition::fromArray("The one I can change."));
	} XuEndBind
	oo << "Work: " << work << " owned by: " << work->owner() << '\n';
	edition = XuEdition::fromOne ("changeable", work)
		->with ("permanent", club);
	oo << "Set owners of: " << edition << '\n';
	oo << "result: " << edition->setRangeOwners(XuServer::publicClubID()) << '\n';
	oo << "Club: " << club << " owned by: " << club->owner() << '\n';
	oo << "Work: " << work << " owned by: " << work->owner() << '\n';
	oo << '\n';
    } XuEndDelay
}

void WorksTester::regionTestOn (ostream& oo) {
    XuIntValueP start, stop;

    XuDelay {
	
	oo << "\nTest IntegerRegions\n";

	XuIntegerRegionP interval = XuIntegerSpace::make ()->interval (3, 7);
	start = interval->start ();
	stop = interval->stop ();

    } XuEndDelay

    oo << "interval is from " << start->asInt () << " to " << stop->asInt () << '\n';

    XuIntValueP i = 3;
    
    oo << "i = " << i->asInt () << '\n';
    
    XuRealP low;
    XuRealP high;

    XuDelay {
	
	oo << "Test RealRegions\n";

	XuRealRegionP floaterval = XuRealSpace::make ()->interval (1.0, 2.0);
	low = floaterval->lowerBound ();
	high = floaterval->upperBound ();

    } XuEndDelay

    oo << "interval is from " << low->value()->asDouble ()
        << " to " << high->value ()->asDouble () << '\n';

    XuFloatValueP x = 3.3;
    
    oo << "x = " << x->asDouble () << '\n';
}

void WorksTester::sponsorTestOn (ostream& oo){

    XuDelay {

	oo << "Test the sponsoring mechanism\n";
	
	XuClubP club;
	XuClubP testClub;
	XuEditionP blank;
	XuWorkP w1;
	XuWorkP w2;
	
	testClub = XuClub::cast (XuServer::get(XuCurrentAuthor.get ()));
	club = XuClub::make(XuClubDescription::make(
		XuSet::make(XuPtrArray::with(XuServer::get(XuCurrentAuthor.get ()))),
		XuWallLockSmith::make())->edition());
	blank = XuEdition::empty(XuIntegerSpace::make ());
	w1 = XuWork::make(blank);
	XuServer::assignID(w1);
	w2 = XuWork::make(blank);
	XuServer::assignID(w1);
	oo << "Initially " << '\n'
		<< "sponsored by Test: " << testClub->sponsoredWorks() << '\n'
		<< "sponsored by new: " << club->sponsoredWorks() << '\n'
		<< "work 1 sponsors: " << w1->sponsors() << '\n'
		<< "work 2 sponsors: " << w2->sponsors() << '\n';
	w1->sponsor(XuIDRegion::cast (XuCurrentAuthor.get ()->asRegion()));
	w2->sponsor(XuIDRegion::cast (XuCurrentAuthor.get ()->asRegion()->with(XuServer::iDOf(club))));
	oo << "After sponsoring " << '\n'
		<< "sponsored by Test: " << testClub->sponsoredWorks() << '\n'
		<< "sponsored by new: " << club->sponsoredWorks() << '\n'
		<< "work 1 sponsors: " << w1->sponsors() << '\n'
		<< "work 2 sponsors: " << w2->sponsors() << '\n';
	w1->unsponsor(XuIDRegion::cast (XuCurrentAuthor.get ()->asRegion()));
	w2->unsponsor(XuIDRegion::cast (XuCurrentAuthor.get ()->asRegion()->with(XuServer::iDOf(club))));
	oo << "After unsponsoring " << '\n'
		<< "sponsored by Test: " << testClub->sponsoredWorks() << '\n'
		<< "sponsored by new: " << club->sponsoredWorks() << '\n'
		<< "work 1 sponsors: " << w1->sponsors() << '\n'
		<< "work 2 sponsors: " << w2->sponsors() << '\n';
	/* Thing to do !!!! */
	
	/* get rid of persistent info */
	/* Thing to do !!!! */
    } XuEndDelay
}


void WorksTester::transclusionsTestOn (ostream& oo){

    /* these detectors need to stay alive outside the delay block so that they
    will be there to be triggered when the results come back */
    XuFillRangeHookP hook1, hook2;
    hook1 = WorksTestFillRangeHook::make (oo, "\n1 Transcluded by ");
    hook2 = WorksTestFillRangeHook::make (oo, "\n2 Transcluded by ");

    XuDelay {

	oo << "Test the transclusions query\n";
	
        XuFillRangeDetectorP det1, det2;
	XuTextP text;
	XuIntValueP n;
	XuEditionP texts;
	XuEditionP refs;
	XuWorkP work;
	XuIntegerSpaceP is = XuIntegerSpace::make ();
	
	oo << '\n'
		<< '\n'
		<< "Transclusions test" << '\n'
		<< '\n';
	text = XuText::make("(abcdefghijklmnopqrstuvwxyz)");
	n = text->count();
	texts = text->edition()->rangeTranscluders(XU_NULL, XuWrapperSpec::get("Text")->filter());
	refs = text->edition()->rangeTranscluders(XU_NULL, XuWrapperSpec::get("HyperRef")->filter());
	det1 = texts->addFillRangeDetector(hook1);
	det2 = refs->addFillRangeDetector(hook2);
	work = XuWork::make(XuSingleRef::make(text->edition())->edition());
	text = text->move(0, is->interval (n / 2, n));
	work->revise(XuSingleRef::make(text->edition())->edition());
	text = text->extract(XuIntegerRegion::cast (
		is->interval (n / 4, n / 2)->complement()));
	work->revise(XuSingleRef::make(text->edition())->edition());
	text->insert(n / 2, XuText::make ("[ABCDEFGHIJKLMNOPQRSTUVWXYZ]"));
	work->revise(XuSingleRef::make(text->edition())->edition());
	texts = text->edition()->rangeTranscluders(is->interval (n / 2, n), 
     		XuWrapperSpec::get("Text")->filter(), XU_NULL, 0, texts);
	refs = text->edition()->rangeTranscluders(is->interval (n / 2, n), 
		XuWrapperSpec::get("HyperRef")->filter(), XU_NULL, 0, refs);
	text = text->extract(is->above(n / 2, TRUE));
	work->revise(XuSingleRef::make(text->edition())->edition());
	text = text->extract(is->below(n, FALSE));
	work->revise(XuSingleRef::make(text->edition())->edition());
	text = text->move(0, is->interval (n / 2, n));
	work->revise(XuSingleRef::make(text->edition())->edition());

    } XuEndDelay
}


void WorksTester::workTestOn (ostream& oo){

    XuDelay {

	oo << "Try the various operations on Works\n";
	
	XuEditionP e1;
	XuWorkP w1;
	XuStatusDetectorP det;

	e1 = XuEdition::fromArray("hello world");
	w1 = XuWork::make(e1);
	this->dumpWorkOn(oo, "As newly created ", w1);
	det = w1->addStatusDetector(
		WorksTestStatusHook::make (oo, "\nWork 1"));
	w1->release();
	this->dumpWorkOn(oo, "With authority restored", w1);
	w1->grab();
	this->dumpWorkOn(oo, "Grabbed", w1);
	w1->release();
	this->dumpWorkOn(oo, "Released", w1);
	XuBind(XuCurrentKeyMaster,XuKeyMaster::universalPublic ()) {
		w1->requestGrab();
	} XuEndBind
	det->destroy ();

    } XuEndDelay
}
/* private: */


void WorksTester::dumpWorkOn (
		ostream& oo, 
		XuStringVar tag, 
		XuWorkP work)
{
	/* Print the state and contents of a Work */
	
	XuBooleanValueP canRead;
	XuBooleanValueP canRevise;
	XuDelay {
		canRead = work->canRead();
		canRevise = work->canRevise();
	} XuEndDelay
	oo << tag << '[';
	XuIf (canRead) {
		oo << work->edition();
	} XuEndIf
	XuIf (canRevise) {
		oo << " (grabbed)";
	} XuEndIf
	oo << ']';
}

int main (int argc, const char *argv[]) {
	if (argc != 3) {
		cerr << "usage: " << argv[0] << " <transport> <address>\n";
		exit (-1);
	}

	XuIntVar error = XuServer::connect (argv[1], argv[2]);
	if (error) {
		cerr << argv[0] << ": connect error " << error << '\n';
		exit (-1);
	}

	WorksTester tester;
	tester.allTestsOn (cerr);
	return 0;
}

