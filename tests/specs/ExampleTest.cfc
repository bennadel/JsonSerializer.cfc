component
	extends = "TestCase"
	output = false
	hint = "I test a given component or module."
	{


	public void function testThatThisRuns() {

		// Runs failure... if you uncomment any of the following.

		// assert( true == false );
		// assertIsValidEmail( "ben nadel" );
		// assertIsValidEmail( "ben@bennadel.com" );
	
	}


	public void function testThatThatRuns() {

		// Runs successfully...	
	
	}


	public void function proveThatNonStandardNamesWillNotRun() {

		// Since this method name does not start with "test", it should not be invoked by TinyTest.
		fail( "Non-test method invoked incorrectly." );

	}


	private void function testThatThisDoesNotRun() {

		// This is a private method, it should not be invoked by TinyTest.
		fail( "Private method invoked incorrectly." );

	}

}