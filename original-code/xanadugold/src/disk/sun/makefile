#
#  disk translated from smalltalk
#
# $Id: makefile,v 1.6 1992/10/21 17:45:49 ravi Exp $
#

XPPDIR = ../..

EXTRADEFS = -DMANUAL_CRUTCH
EXTRAINCLUDES = -I$(XPPDIR)/server -I$(XPPDIR)/urdi -I$(XPPDIR)/client
EXTRASTUBBLEDEFS = -FWITH_SERVER_HOOKS -J.
EXTRASTUBBLEDEPENDS = \
	$(XPPDIR)/stubble/copy.hf \
	$(XPPDIR)/stubble/backend1.hf $(XPPDIR)/stubble/backend2.hf


include $(XPPDIR)/xpp/$(PLATFORM)/xpp.mk

include $(XPPDIR)/xpp/$(PLATFORM)/export.mk
include $(XPPDIR)/xlatexpp/$(PLATFORM)/export.mk
include $(XPPDIR)/server/$(PLATFORM)/export.mk

DISK = diskman snfinfo packer turtle fakedsk flkinfo purging

DISK_O = $(DISK:=x.o)

TEST = consist diskman packer
TEST_O = $(TEST:=t.o)

default : libs testbin

libs : disklibx.o 
testbin : $(TEST_O)

all: default

tests:
	@echo "no tests in disk directory"

disklibx.o : $(DISK_O)
	ld -r $(DISK_O) -o $@

#snfinfox.o : snfinfox.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) snfinfox.cxx

#packerx.o : packerx.cxx
#	asynch ; $(COMPILE4.cxx) $(OUTPUT_OPTION) packerx.cxx

include depends.mk
