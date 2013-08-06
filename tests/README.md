
# Tiny Test - ColdFusion Unit Testing Framework

by [Ben Nadel][1]

Tiny Test is a ColdFusion unit testing framework that I built for personal use as a means 
to become more comfortable with the idea of unit testing and TDD (Test Drive Development).
The feature is set is intended to be incredibly limited; and, it's meant to work with an
HTML page that comes pre-packaged with the framework. You just drop it in, point it at
the test specifications, and open it up in the browser.

If you want a more full-featured unit testing framework, I would suggest looking into 
[MXUnit][2]; it's a robust unit testing framework that has been battle-hardened for years
by the ColdFusion community.

## Specs Directory

Tiny Test will look in the "specs" directory for your test cases. It will attempt to run
any ColdFusion component whose name ends with, "Test.cfc". For example, the following are
all valid test case file names:

* AccountTest.cfc
* PrimeNumberGeneratorTest.cfc
* UserServiceTest.cfc

While Tiny Test will examine all of these ColdFusion components, it will only invoke the
ones that you specify in the HTML web page served up by the Tiny Test framework.

## Test Cases

Inside of your test cases, Tiny Test will attempt to invoke every public method that 
starts with, "test". For example, the following are all valid test method names:

* testThatThatWorks();
* testThatThisWorks();

Within each test case can define optional methods that run before and / or after each 
test method:

* setup()
* teardown()

In these methods, you can reset the private variables of your test case to be "pristine" 
for each invocation of the provided test methods.

Each of your test cases should extend the TestCase.cfc component that ships in the specs
directory. This is your bridge into the core functionality provided by Tiny Test.

## Assertions

Each of your test methods will probably make some assertion based on the state of your 
components. Out of the box, Tiny Test provide only the most basic assertions:

* assert( truthy )
* assertTrue( truthy )
* assertFalse( falsey )
* assertEquals( simpleValue, simpleValue )
* assertNotEquals( simpleValue, simpleValue )

If you want to add your own custom assertions, feel free to add them to the TestCase.cfc
provided in the specs directory. Since each of your test cases extends this base 
component, each of your test cases will have access to the custom methods that you define 
within TestCase.cfc.

Inside of your custom assertions, you can make use of the private method, fail(), which 
is how the Tiny Test tracks exceptions:

* fail( errorMessage )

Hopefully you've found some of this vaguely interesting.


[1]: http://www.bennadel.com
[2]: http://mxunit.org