/* ========================================================================== */
//
//	Copyright (c) 1992 by Xanadu Operating Company, All Rights Reserved.
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
//			bombt.ixx
//
//		By Michael McClary		1992
//
/* ========================================================================== */
//
//	Spawned from bombx.cxx during ORDER/BUILD / inline upgrade.
//		- michael Mar  3 1992

#ifndef BOMBT_IXX
#define BOMBT_IXX


BUILD_BOMB_BEGIN( cerr, char *) {cerr << CHARGE;} BUILD_BOMB_END(cerr);

BUILD_SMART_BOMB_BEGIN( smart, char *) {
	cerr << (int) SOURCE << ", therefore: " << CHARGE;
} BUILD_SMART_BOMB_END(smart);

BUILD_BOMB_BEGIN( recursive, char *) {
	cerr << "recursive " << CHARGE;

	char*	message = "This is the recursive message.\n";

	cerr << "About to do PLANT_BOMB()\n";
	PLANT_BOMB(cerr,mess);

	cerr << "About to do ARM_BOMB()\n";
	ARM_BOMB(mess,message);
} BUILD_BOMB_END(recursive);

BUILD_SMART_BOMB_BEGIN( disarmer,_lshield_Bomb *) {
	if (SOURCE == BLASTING) {
		cerr << "disarming.\n";
		CHARGE->disarmBomb();
	}
} BUILD_SMART_BOMB_END(disarmer);

BUILD_BOMB_BEGIN( cheat, char *) {
	this->BombSuperclass::armBomb(); cerr << CHARGE;
} BUILD_BOMB_END(cheat);

BUILD_SMART_BOMB_BEGIN(DieSubConstructor, DieSub *) {
	if (SOURCE == BLASTING) {
		delete CHARGE;
	}
} BUILD_SMART_BOMB_END(DieSubConstructor);

BUILD_SMART_BOMB_BEGIN(CroakSubConstructor, CroakSub *) {
	if (SOURCE == BLASTING) {
		delete CHARGE;
	}
} BUILD_SMART_BOMB_END(CroakSubConstructor);

BUILD_SMART_BOMB_BEGIN(LiveSubConstructor, LiveSub *) {
	if (SOURCE == BLASTING) {
		delete CHARGE;
	}
} BUILD_SMART_BOMB_END(LiveSubConstructor);

BUILD_SMART_BOMB_BEGIN(BaseThingConstructor, BaseThing *) {
	if (SOURCE == BLASTING) {
		delete CHARGE;
	}
} BUILD_SMART_BOMB_END(BaseThingConstructor);

INLINE TestPtrThing::
TestPtrThing (void * p)
{
	this->value = p;
	this->armBomb();
}

INLINE TestPtrThing::
~TestPtrThing () {
	this->detonateBomb(LEFT_AREA); /* wipe from bomb string */
}

INLINE OptimizedTestPtrThing::
OptimizedTestPtrThing (void * p)
{
	this->value = p;
	this->armBomb();
}

INLINE OptimizedTestPtrThing::
~OptimizedTestPtrThing () {
	this->disarmBomb(); /* wipe from bomb string */
}

#endif /* BOMBT_IXX */
