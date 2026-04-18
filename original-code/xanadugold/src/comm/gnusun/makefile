#
#  comm translated from smalltalk
#
#  $Id: makefile,v 1.7 1993/03/24 02:40:19 eric Exp $
#

XPPDIR = ../..

EXTRADEFS = -DMANUAL_CRUTCH
EXTRAINCLUDES = -I$(XPPDIR)/client -I$(XPPDIR)/server -I$(XPPDIR)/disk

include $(XPPDIR)/xpp/$(PLATFORM)/xpp.mk

include $(XPPDIR)/xpp/$(PLATFORM)/export.mk
include $(XPPDIR)/xlatexpp/$(PLATFORM)/export.mk

COMM = nscotty nxcvr recipe txtcomm xfrspec negoti8 \
	bootpln cookbk bin2com portal
RPC = proman comdtct prolstn handlrs srvloop sktsrv schunk
# sktwire srvloop sktsrv proman comdtct
COMMLIB = $(COMM)

COMMLIB_O = $(COMMLIB:=x.o)
RPC_O = $(RPC:=x.o)

default : libs

libs : commlibx.o promlibx.o

all : default

tests :
	@echo "no tests in comm directory"

commlibx.o : $(COMMLIB_O)
	ld -r $(COMMLIB_O) -o commlibx.o

promlibx.o : $(RPC_O)
	ld -r $(RPC_O) -o promlibx.o

#bin2comx.o : ../bin2comx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) ../bin2comx.cxx

undef-list :
	nm -ou $(COMMLIB_O)

commsizes :
	size $(COMMLIB_O)

include depends.mk
