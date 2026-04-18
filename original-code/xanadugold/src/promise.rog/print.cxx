#include "xanadu.h"
#include "xanadu.hxx"
#include <stream.h>

#ifdef XU_PRINTON_VERBOSE

void XuPromise::printContentsOn (ostream& /*oo*/)
{
}


void XuAdminer::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    XuIf (this->isAcceptingConnections()) {
	oo << " is";
    } XuElse {
	oo << " isn't";
    } XuEndIf;
    oo << "accepting connections";
}


void XuArchiver::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuArray::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "count: " << this->count();
}


void XuFloatArray::printContentsOn (ostream& oo)
{
    this->XuArray::printContentsOn (oo);
}


void XuHumberArray::printContentsOn (ostream& oo)
{
    this->XuArray::printContentsOn (oo);
}


void XuIntArray::printContentsOn (ostream& oo)
{
    this->XuArray::printContentsOn (oo);
}


void XuPtrArray::printContentsOn (ostream& oo)
{
    this->XuArray::printContentsOn (oo);
}


void XuBundle::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "region: " << this->region();
}


void XuArrayBundle::printContentsOn (ostream& oo)
{
    this->XuBundle::printContentsOn (oo);
    oo << ", array: " << this->array();
    oo << ", ordering: " << this->ordering();
}


void XuElementBundle::printContentsOn (ostream& oo)
{
    this->XuBundle::printContentsOn (oo);
    oo << ", element: " << this->element();
}


void XuPlaceHolderBundle::printContentsOn (ostream& oo)
{
    this->XuBundle::printContentsOn (oo);
}


void XuCoordinateSpace::printContentsOn (ostream& oo)
{
    XuDelay {
	XuFilterSpaceP		fSpace = XuFilterSpace::cast(this);
	XuIDSpaceP 		idSpace = XuIDSpace::cast(this);
	XuSequenceSpaceP	sSpace = XuSequenceSpace::cast(this);
	XuCrossSpaceP 		tSpace = XuCrossSpace::cast(this);
	XuIntegerSpaceP 	iSpace = XuIntegerSpace::cast(this);
	XuRealSpaceP 		rSpace = XuRealSpace::cast(this);

	this->XuPromise::printContentsOn (oo);
        XuPromise::forceAll();

	if (fSpace->isFulfilled()) {
	    oo << fSpace;
	} else if (idSpace->isFulfilled()) {
	    oo << idSpace;
	} else if (sSpace->isFulfilled()) {
	    oo << sSpace;
	} else if (tSpace->isFulfilled()) {
	    oo << tSpace;
	} else if (iSpace->isFulfilled()) {
	    oo << iSpace;
	} else if (rSpace->isFulfilled()) {
	    oo << rSpace;
	}
    } XuEndDelay;
}


void XuCrossSpace::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "axes: " << this->axes();
}


void XuFilterSpace::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "baseSpace: " << this->baseSpace();
}


void XuIDSpace::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    /* oo << "export: " << this->export(); */
}


void XuIntegerSpace::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuRealSpace::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuSequenceSpace::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuFillRangeDetector::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuFillDetector::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuKeyMaster::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "actualAuthority: " << this->actualAuthority();
    oo << ", loginAuthority: " << this->loginAuthority();
}


void XuLock::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuBooLock::printContentsOn (ostream& oo)
{
    this->XuLock::printContentsOn (oo);
}


void XuChallengeLock::printContentsOn (ostream& oo)
{
    this->XuLock::printContentsOn (oo);
    oo << "challenge: " << this->challenge();
}


void XuMatchLock::printContentsOn (ostream& oo)
{
    this->XuLock::printContentsOn (oo);
}


void XuMultiLock::printContentsOn (ostream& oo)
{
    this->XuLock::printContentsOn (oo);
    oo << "lockNames: " << this->lockNames();
}


void XuWallLock::printContentsOn (ostream& oo)
{
    this->XuLock::printContentsOn (oo);
}


void XuMapping::printContentsOn (ostream& oo)
{
    XuDelay {
	XuBooleanValueP complete = this->isComplete();
	XuBooleanValueP identity = this->isIdentity();
	XuCrossMappingP cMap = XuCrossMapping::cast(this);
	XuIntegerMappingP iMap = XuIntegerMapping::cast(this);
	XuSequenceMappingP sMap = XuSequenceMapping::cast(this);
	XuMappingP uMap = this->unrestricted();

	this->XuPromise::printContentsOn (oo);
        XuPromise::forceAll();
    
	XuIf(complete) {
	    oo << this->domain() << "to: " << this->range();
	    return;
	} XuEndIf;
	XuIf(identity) {
	    oo << this->domainSpace() << "'s identity mapping";
	    return;
	} XuEndIf;
	if (cMap->isFulfilled()) {
	    oo << cMap;
	    return;
	}
	if (iMap->isFulfilled()) {
	    oo << iMap;
	    return;
	}
	if (sMap->isFulfilled()) {
	    oo << sMap;
	    return;
	}
	if (uMap->isFulfilled()) {
	    oo << "unrestricted: " << uMap;
	    oo << ", restrictedTo: " << this->domain();
	    return;
	}
	oo << "simplerMappings: (";
	XuStepperP stomp = this->simplerMappings();
	XuFor(XuMapping,map,this->simplerMappings()) {
	    oo << map << ", ";
	} XuEndFor;
	oo << ")";
    } XuEndDelay;
    
}


void XuCrossMapping::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "subMappings: " << this->subMappings();
}


void XuIntegerMapping::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "translation: " << this->translation();
}


void XuSequenceMapping::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "shift: " << this->shift();
    oo << ", translation: " << this->translation();
}


void XuOrderSpec::printContentsOn (ostream& oo)
{
    XuDelay {
	XuBooleanValueP up = this->equals (this->coordinateSpace()->ascending());
	XuBooleanValueP down = this->equals (this->coordinateSpace()->descending());
	XuCrossOrderSpecP cOrd = XuCrossOrderSpec::cast(this);

	this->XuPromise::printContentsOn (oo);
        XuPromise::forceAll();

	XuIf(up) {
	    oo << "ascending";
	    return;
	} XuEndIf;
	XuIf(down) {
	    oo << "descending";
	    return;
	} XuEndIf;
	if (cOrd->isFulfilled()) {
	    oo << cOrd;
	    return;
	}
	oo << "unknown";
    } XuEndDelay;
}


void XuCrossOrderSpec::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "lexOrder: " << this->lexOrder();
    oo << ", subOrders: " << this->subOrders();
}


void XuPosition::printContentsOn (ostream& oo)
{
    XuDelay {
	XuFilterPositionP	fPos = XuFilterPosition::cast(this);
	XuIDP 			idPos = XuID::cast(this);
	XuSequenceP 		sPos = XuSequence::cast(this);
	XuTupleP 		tPos = XuTuple::cast(this);
	XuIntegerP 		iPos = XuInteger::cast(this);
	XuRealP 		rPos = XuReal::cast(this);

	this->XuPromise::printContentsOn (oo);
        XuPromise::forceAll();

	if (fPos->isFulfilled()) {
	    oo << fPos;
	} else if (idPos->isFulfilled()) {
	    oo << idPos;
	} else if (sPos->isFulfilled()) {
	    oo << sPos;
	} else if (tPos->isFulfilled()) {
	    oo << tPos;
	} else if (iPos->isFulfilled()) {
	    oo << iPos;
	} else if (rPos->isFulfilled()) {
	    oo << rPos;
	}
    } XuEndDelay;
}


void XuFilterPosition::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "baseRegion: " << this->baseRegion();
}


void XuID::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    /* oo << "export: " << this->export(); */
}


void XuSequence::printContentsOn (ostream& oo)
{
    XuDelay {
	XuBooleanValueP zeros = this->isZero();
	XuIntValueP first = this->firstIndex();
	XuArrayP ints = this->integers();

	this->XuPromise::printContentsOn (oo);
        XuPromise::forceAll();

	XuIf(zeros) {
	    oo << "zero";
	    return;
	} XuEndIf;
	oo << "firstIndex: " << first;
	oo << ", integers: " << ints;
    } XuEndDelay;
}


void XuTuple::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "coordinates: " << this->coordinates();
}


void XuInteger::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "value: " << this->value();
}


void XuReal::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "value: " << this->value();
}


void XuRangeElement::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "owner: " << this->owner();
}


void XuDataHolder::printContentsOn (ostream& oo)
{
    this->XuRangeElement::printContentsOn (oo);
    oo << ", value: " << this->value();
}


void XuEdition::printContentsOn (ostream& oo)
{
    this->XuRangeElement::printContentsOn (oo);
    oo << ", label: " << this->label();
    oo << ", endorsements: " << this->endorsements();
    oo << ", domain: " << this->domain();
}


void XuIDHolder::printContentsOn (ostream& oo)
{
    this->XuRangeElement::printContentsOn (oo);
    oo << ", iD: " << this->iD();
}


void XuLabel::printContentsOn (ostream& oo)
{
    this->XuRangeElement::printContentsOn (oo);
}


void XuWork::printContentsOn (ostream& oo)
{
    this->XuRangeElement::printContentsOn (oo);
    oo << ", canRead: " << this->canRead();
    oo << ", canRevise: " << this->canRevise();
    oo << ", readClub: " << this->readClub();
    oo << ", editClub: " << this->editClub();
    oo << ", historyClub: " << this->historyClub();
    oo << ", grabber: " << this->grabber();
    oo << ", endorsements: " << this->endorsements();
    oo << ", sponsors: " << this->sponsors();

    oo << ", edition: " << this->edition();
}


void XuClub::printContentsOn (ostream& oo)
{
    this->XuWork::printContentsOn (oo);
    oo << ", signatureClub: " << this->signatureClub();
    oo << ", sponsoredWorks: " << this->sponsoredWorks();
}


void XuRevisionDetector::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuServer::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "identifier: " << XuServer::identifier();
}


void XuSession::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "connectTime: " << this->connectTime();
    oo << ", initialLogin: " << this->initialLogin();
    oo << ", port: " << this->port();
}


void XuStatusDetector::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuStepper::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    XuIf(this->atEnd()) {
	oo << "atEnd";
    } XuElse {
	oo << "get: " << this->get();
    } XuEndIf;
}


void XuTableStepper::printContentsOn (ostream& oo)
{
    this->XuStepper::printContentsOn (oo);
    XuIf(!this->atEnd()) {
	oo << ", position: " << this->position();
    } XuEndIf;
}


void XuVoid::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuWaitDetector::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
}


void XuWrapper::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "edition: " << this->edition();
    /* oo << ", inner: " << this->inner(); */
}


void XuClubDescription::printContentsOn (ostream& oo)
{
    this->XuWrapper::printContentsOn (oo);
    oo << ", lockSmith: " << this->lockSmith();
    oo << ", membership: " << this->membership();
}


void XuHyperLink::printContentsOn (ostream& oo)
{
    this->XuWrapper::printContentsOn (oo);
    XuSequenceRegionP names = this->endNames();
    XuIf (names->isFinite()) {
	XuFor(XuSequence,name,names->stepper()) {
	    oo << ", " << name << ": " << this->endAt(name);
	} XuEndFor;
    } XuElse {
	oo << ", endNames: " << names;
    } XuEndIf;
    oo << ", linkTypes: " << this->linkTypes();
}


void XuHyperRef::printContentsOn (ostream& oo)
{
    this->XuWrapper::printContentsOn (oo);
    oo << ", workContext: " << this->workContext();
    oo << ", originalContext: " << this->originalContext();
    oo << ", pathContext: " << this->pathContext();
}


void XuMultiRef::printContentsOn (ostream& oo)
{
    this->XuHyperRef::printContentsOn (oo);
    oo << ", refs: (";
    XuFor(XuHyperRef,r,this->refs()) {
	oo << r << ", ";
    } XuEndFor;
    oo << ")";
}


void XuSingleRef::printContentsOn (ostream& oo)
{
    this->XuHyperRef::printContentsOn (oo);
    oo << ", excerpt: " << this->excerpt();
}


void XuLockSmith::printContentsOn (ostream& oo)
{
    this->XuWrapper::printContentsOn (oo);
}


void XuBooLockSmith::printContentsOn (ostream& oo)
{
    this->XuLockSmith::printContentsOn (oo);
}


void XuChallengeLockSmith::printContentsOn (ostream& oo)
{
    this->XuLockSmith::printContentsOn (oo);
    oo << ", encrypterName: " << this->encrypterName();
    oo << ", publicKey: " << this->publicKey();
}


void XuMatchLockSmith::printContentsOn (ostream& oo)
{
    this->XuLockSmith::printContentsOn (oo);
    oo << ", scrambledPassword: " << this->scrambledPassword();
    oo << ", scramblerName: " << this->scramblerName();
}


void XuMultiLockSmith::printContentsOn (ostream& oo)
{
    this->XuLockSmith::printContentsOn (oo);
    oo << ", lockSmithNames: " << this->lockSmithNames();
}


void XuWallLockSmith::printContentsOn (ostream& oo)
{
    this->XuLockSmith::printContentsOn (oo);
}


void XuPath::printContentsOn (ostream& oo)
{
    this->XuWrapper::printContentsOn (oo);
}


void XuSet::printContentsOn (ostream& oo)
{
    this->XuWrapper::printContentsOn (oo);
    oo << ", count: " << this->count();
}


void XuText::printContentsOn (ostream& oo)
{
    this->XuWrapper::printContentsOn (oo);
    oo << ", contents: " << this->contents();
}


void XuWrapperSpec::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << "filter: " << this->filter();
    oo << ", name: " << this->name();
}


void XuRegion::printContentsOn (ostream& oo)
{
    XuDelay {
	XuFilterP		fReg = XuFilter::cast(this);
	XuIDRegionP 		idReg = XuIDRegion::cast(this);
	XuSequenceRegionP	sReg = XuSequenceRegion::cast(this);
	XuCrossRegionP 		cReg = XuCrossRegion::cast(this);
	XuIntegerRegionP 	iReg = XuIntegerRegion::cast(this);
	XuRealRegionP 		rReg = XuRealRegion::cast(this);

	this->XuPromise::printContentsOn (oo);
        XuPromise::forceAll();

	if (fReg->isFulfilled()) {
	    oo << fReg;
	} else if (idReg->isFulfilled()) {
	    oo << idReg;
	} else if (sReg->isFulfilled()) {
	    oo << sReg;
	} else if (cReg->isFulfilled()) {
	    oo << cReg;
	} else if (iReg->isFulfilled()) {
	    oo << iReg;
	} else if (rReg->isFulfilled()) {
	    oo << rReg;
	}
    } XuEndDelay;
}


void XuCrossRegion::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    XuIf(this->isEmpty()) {
	oo << "emptyRegion";
	return;
    } XuEndIf;
    XuIf(this->isFull()) {
	oo << "fullRegion";
	return;
    } XuEndIf;
    
    XuIf(this->isBox()) {
	oo << "projections: (";
	XuIntValueP dims;
	XuDelay {
	    dims = XuCrossSpace::cast (this->coordinateSpace ())->axisCount();
	} XuEndDelay;
	for (XuIntVar i = 0; i < dims->asInt(); i++) {
	    oo << this->projection(i) << ",";
	}
    } XuElse {
	oo << "boxes: (";
	XuFor(XuCrossRegion,box,this->boxes()) {
	    oo << box << ", ";
	} XuEndFor;
    } XuEndIf;
    oo << ")";
}


void XuFilter::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    XuIf(this->isEmpty()) {
	oo << "emptyRegion";
	return;
    } XuEndIf;
    XuIf(this->isFull()) {
	oo << "fullRegion";
	return;
    } XuEndIf;
}


void XuIDRegion::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    XuIf(this->isEmpty()) {
	oo << "emptyRegion";
	return;
    } XuEndIf;
    XuIf(this->isFull()) {
	oo << "fullRegion";
	return;
    } XuEndIf;
    
    /* oo << "export: " << this->export(); */
}


void XuIntegerRegion::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    XuIf(this->isEmpty()) {
	oo << "emptyRegion";
	return;
    } XuEndIf;
    XuIf(this->isFull()) {
	oo << "fullRegion";
	return;
    } XuEndIf;
    
    XuFor(XuIntegerRegion,reg,this->intervals()) {
	XuBooleanValueP below = reg->isBoundedBelow();
	XuBooleanValueP above = reg->isBoundedAbove();
	XuIntValueP low = reg->start();
	XuIntValueP high = reg->stop();
	
	XuIf(below) {
	    oo << "[" << low << ", ";
	} XuElse {
	    oo << "<-inf, ";
	} XuEndIf;
	
	XuIf(above) {
	    oo << high << ">";
	} XuElse {
	    oo << "+inf>";
	} XuEndIf;
	oo << " ";
    } XuEndFor;
}


void XuRealRegion::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    XuIf(this->isEmpty()) {
	oo << "emptyRegion";
	return;
    } XuEndIf;
    XuIf(this->isFull()) {
	oo << "fullRegion";
	return;
    } XuEndIf;
    
    XuFor(XuRealRegion,reg,this->intervals()) {
	XuBooleanValueP below = reg->isBoundedBelow();
	XuBooleanValueP above = reg->isBoundedAbove();
	XuRealP low = reg->lowerBound();
	XuRealP high = reg->upperBound();
	XuBooleanValueP closedLow = reg->hasMember(low);
	XuBooleanValueP closedHigh = reg->hasMember(high);
	
	XuIf(below) {
	    XuIf(closedLow) {
		oo << "[";
	    } XuElse {
		oo << "<";
	    } XuEndIf;
	    oo << low << ", ";
	} XuElse {
	    oo << "<-inf, ";
	} XuEndIf;
	
	XuIf(above) {
	    oo << high;
	    XuIf(closedHigh) {
		oo << "]";
	    } XuElse {
		oo << ">";
	    } XuEndIf;
	    oo << low << ", ";
	} XuElse {
	    oo << "+inf>";
	} XuEndIf;
	oo << " ";
    } XuEndFor;
}


void XuSequenceRegion::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    XuIf(this->isEmpty()) {
	oo << "emptyRegion";
	return;
    } XuEndIf;
    XuIf(this->isFull()) {
	oo << "fullRegion";
	return;
    } XuEndIf;
    
    XuFor(XuSequenceRegion,reg,this->intervals()) {
	XuBooleanValueP below = reg->isBoundedBelow();
	XuBooleanValueP above = reg->isBoundedAbove();
	XuSequenceP low = reg->lowerEdge();
	XuSequenceP high = reg->upperEdge();
	XuIntValueP lowType = reg->lowerEdgeType();
	XuIntValueP highType = reg->upperEdgeType();
	XuIntValueP lowLimit = reg->lowerEdgePrefixLimit();
	XuIntValueP highLimit = reg->upperEdgePrefixLimit();	
	
	XuIf(!below) {
	    oo << "<-inf";
	} XuElse {
	    XuSwitch(lowType) {
	      case XU_INCLUSIVE:
		oo << "[" << low;
		break;
	      case XU_EXCLUSIVE:
		oo << "<" << low;
		break;
	      case XU_PREFIX:
		oo << "[(" << low << "::" << lowLimit << ")";
		break;
	    } XuEndSwitch;
	} XuEndIf;

	oo << ", ";

	XuIf(!above) {
	    oo << "+inf>";
	} XuElse {
	    XuSwitch(highType) {
	      case XU_INCLUSIVE:
		oo << high << "]";
		break;
	      case XU_EXCLUSIVE:
		oo << high << ">";
		break;
	      case XU_PREFIX:
		oo << "(" << high << "::" << highLimit << ")]";
		break;
	    } XuEndSwitch;
	} XuEndIf;
	oo << " ";
    } XuEndFor;
}


void XuValue::printContentsOn (ostream& oo)
{
    XuDelay {
	XuIntValueP iVal = XuIntValue::cast(this);
	XuFloatValueP fVal = XuFloatValue::cast(this);

	this->XuPromise::printContentsOn (oo);
        XuPromise::forceAll();

	if (iVal->isFulfilled()) {
	    oo << iVal;
	} else {
	    oo << fVal;
	}
    } XuEndDelay;
}


void XuFloatValue::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    oo << (double)this->asDouble();
}


void XuIntValue::printContentsOn (ostream& oo)
{
    this->XuPromise::printContentsOn (oo);
    if (this->isTooBig()) {
	oo << "too big";
    } else {
	oo << this->asInt();
    }
}

#endif /* XU_PRINTON_VERBOSE */
