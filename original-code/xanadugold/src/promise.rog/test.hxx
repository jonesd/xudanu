#ifndef XU_TEST_HXX
#define XU_TEST_HXX

#include "xanadu.hxx"
#include "test.oxx"

class WorksTestFillRangeHook : public XuFillRangeHook {

		XU_PROLOGUE(WorksTestFillRangeHook)

	public: /* create */

		static XuFillRangeHookP make (ostream&, char *);

	public: /* triggering */

		virtual void rangeFilled (XuEditionP);

	private: /* create */

		WorksTestFillRangeHook (ostream&, char *);

	private: /* variables */

		char * myTag;
		ostream * myOutput;
};

class WorksTestStatusHook : public XuStatusHook {

		XU_PROLOGUE(WorksTestStatusHook)

  public: /* create */
	
	static XuStatusHookP make (ostream&, char *);
	
  public: /* triggering */
	
	virtual void grabbed (XuWorkP, XuIDP, XuIntValueP);
	
	virtual void released (XuWorkP, XuIntValueP);
	
  private: /* create */

	WorksTestStatusHook (ostream&, char *);
	
  private:
	char * myTag;
	ostream * myOutput;

};

class WorksTester XU_ROOTCLASS {

	public:

		WorksTester () {}

	public: /* testing */

		void allTestsOn (ostream&);

	public: /* tests */

		void promiseExerciseOn (ostream&);
		void arrayExerciseOn (ostream&);
		void crossSpaceExerciseOn (ostream&);
		void filterSpaceExerciseOn (ostream&);
		void iDSpaceExerciseOn (ostream&);
		void integerSpaceExerciseOn (ostream&);
		void sequenceSpaceExerciseOn (ostream&);
		void integerExerciseOn (ostream&);
		void rangeElementExerciseOn (ostream&);
		void editionExerciseOn (ostream&);
		void workExerciseOn (ostream&);
		void stepperExerciseOn (ostream&);
		void linkExerciseOn (ostream&);
		void wrapperExerciseOn (ostream&);

		void compareTestOn (ostream&);
		void crossTestOn (ostream&);
		void editionTestOn (ostream&);
		void endorseTestOn (ostream&);
		void globalIDTestOn (ostream&);
		void historyTestOn (ostream&);
		void kmTestOn (ostream&);
		void labelTestOn (ostream&);
		void makeEditionTestOn (ostream&);
		void ownerTestOn (ostream&);
		void regionTestOn (ostream&);
		void sponsorTestOn (ostream&);
		void transclusionsTestOn (ostream&);
		void workTestOn (ostream&);

	private:

		void dumpWorkOn (ostream&, XuStringVar, XuWorkP);
};

#endif /* XU_TEST_HXX */
