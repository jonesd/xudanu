#ifndef XU_SOCKET_HXX
#define XU_SOCKET_HXX

#ifdef unix
#	include <signal.h>
#	include <sys/types.h>
#	include <sys/time.h>
#endif /* unix */

#include "xanadu.hxx"

class XuSocketPortalSpec : public XuPortalSpec {

	public:
		XuPortalP fetchNewPortal (XuStringVar addr);

		XuSocketPortalSpec ();

	private:

		static XuSocketPortalSpec TheOne;
};

class XuSocketPortal : public XuPortal {
	
	public: /* sending & receiving */

		virtual void sendByte (XuIntVar b);
		virtual XuIntVar receiveByte ();

		virtual void sendBuffer (XuBufferVar buffer, XuIntVar count);
		virtual void receiveBuffer (XuBufferVar buffer, XuIntVar size);
		virtual void flush ();

		virtual ~ XuSocketPortal ();

	private: /* create */

		friend class XuSocketPortalSpec;

	private: /* variables */

		XuSocketPortal (int fd);

		int mySocketFD;
};

#endif /* XU_SOCKET_HXX */
