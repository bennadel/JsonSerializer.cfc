component
	output = false
	hint = "I represent the error that was thrown during a TestCase execution."
	{


	public any function init( required any exception ) {

		errorMessage = getErrorFromException( exception );

		stackTrace = getStackTraceFromException( exception );
		
		fullStackTrace = getFullStackTraceFromException( exception );

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	public string function getErrorMessage() {

		return( errorMessage );

	}


	public string function getFullStackTrace() {

		return( fullStackTrace );

	}


	public array function getStackTrace() {

		return( stackTrace );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	private string function getErrorFromException( required any exception ) {

		if ( 
			! structKeyExists( exception, "message" ) ||
			! len( exception.message )
			) {

			return( "An unexpected error has occurred." );

		}

		return( exception.message );

	}


	private string function getFullStackTraceFromException( required any exception ) {
		
		if ( ! structKeyExists( exception, "stackTrace" ) ) {

			return( "" );

		}
		
		return( exception.stackTrace );

	}


	private array function getStackTraceFromException( required any exception ) {

		if ( ! structKeyExists( exception, "tagContext" ) ) {

			return( arrayNew( 1 ) );

		}

		var simplifiedContext = [];

		for ( var tagContext in exception.tagContext ) {

			// For generated templates, this will not be a file path. This is caused by the
			// use of the evaluate() method to invoke a compoonent method.
			if ( isPhysicalTemplatePath( tagContext.template ) ) {

				arrayAppend(
					simplifiedContext,
					{
						fileName = getFileFromPath( tagContext.template ),
						filePath = tagContext.template,
						lineNumber = tagContext.line
					}
				);
				
			}

		}

		return( simplifiedContext );

	}


	private boolean function isPhysicalTemplatePath( required string templatePath ) {

		return( templatePath != "<generated>" );

	}


}