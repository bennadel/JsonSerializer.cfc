<cfscript>

component
	output = false
	hint = "I define the application setttings and event handlers."
	{


	// Define the application settings.
	this.name = hash( getCurrentTemplatePath() );
	this.applicationTimeout = createTimeSpan( 0, 0, 1, 0 );
	this.sessionManagement = false;

	// Get the current directory ( "example" ).
	this.directory = getDirectoryFromPath( getCurrentTemplatePath() );

	// Get the root directory for our project.
	this.rootDirectory = ( this.directory & "../" );

	// Map the Lib directory so we can instantiate our project components.
	this.mappings[ "/lib" ] = ( this.rootDirectory & "lib/" );


}

</cfscript>
