#
#	Exported objects from translated comm
#
#	This library is incorporated into those provided by xlatexpp/export.mk
#	Include that to get this.
#
#	$Id: export.mk,v 1.5 1992/10/21 17:45:33 ravi Exp $
#

COMMLIBX_O = $(XPPDIR)/comm/$(PLATFORM)/commlibx.o
SRVLOOPT_O = $(XPPDIR)/comm/$(PLATFORM)/schunkt.o
PROMISE_O  = $(XPPDIR)/comm/$(PLATFORM)/promlibx.o

$(XPPDIR)/comm/$(PLATFORM)/commlibx.o : FORCE
	cd $(XPPDIR)/comm/$(PLATFORM) ; xumake commlibx.o || (rm -f $@ ; false)

$(XPPDIR)/comm/$(PLATFORM)/srvloopt.o : FORCE
	cd $(XPPDIR)/comm/$(PLATFORM) ; xumake srvloopt.o || (rm -f $@ ; false)

$(XPPDIR)/comm/$(PLATFORM)/promlibx.o : FORCE
	cd $(XPPDIR)/comm/$(PLATFORM) ; xumake promlibx.o || (rm -f $@ ; false)
