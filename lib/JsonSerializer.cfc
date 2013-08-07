<cfscript>

component
	output = false
	hint = "I provide a way to serialize complext ColdFusion data values as case-sensitive JavaScript Object Notation (JSON) strings."
	{


	// I return the initialized component.
	public any function init( boolean convertDateToUtcMilliseconds = true ) {

		// By default, we're going to convert defined date-types as UTC milliseconds. If this flag
		// is set to false, then dates will be converted using normal stringification.
		variables.convertDateToUtcMilliseconds = arguments.convertDateToUtcMilliseconds;

		// Every key is added to the full key list.
		fullKeyList = {};

		// These key lists determine special data serialization.
		booleanKeyList = {};
		integerKeyList = {};
		floatKeyList = {};
		dateKeyList = {};

		// These keys will NOT be used in serialization (ie. the key/value pairs will not be added 
		// to the serialized output).
		blockedKeyList = {};

		// When serializing values, ColdFusion has a tendency to convert strings to numbers if those
		// strings look like numbers. We will prepend the string values with this "conversion blocker"
		// so that we can force ColdFusion to make a string (this gets removed after serialization).
		START_OF_STRING = chr( 2 );

		// Return the initialized component.
		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	// I define the given key without a type. This is here to provide key-casing without 
	// caring about why type of data convertion takes place. Returns serializer.
	public any function asAny( required string key ) {

		return(
			defineKey( fullKeyList, key )
		);

	}


	// I define the given key as a boolean. Returns serializer.
	public any function asBoolean( required string key ) {

		return(
			defineKey( booleanKeyList, key )
		);

	}


	// I define the given key as a date. Returns serializer.
	public any function asDate( required string key ) {

		return(
			defineKey( dateKeyList, key )
		);

	}


	// I define the given key as a float / decimal. Returns serializer.
	public any function asFloat( required string key ) {

		return(
			defineKey( floatKeyList, key )
		);

	}


	// I define the given key as an integer. Returns serializer.
	public any function asInteger( required string key ) {

		return(
			defineKey( integerKeyList, key )
		);

	}


	// I define the given key as a string. Returns serializer.
	public any function asString( required string key ) {

		return( asAny( key ) );

	}


	// I serialize the given input as JavaScript Object Notation (JSON) using the case-sensitive
	// values defined in the key-list.
	public string function serialize( required any input ) {

		var preparedInput = prepareInputForSerialization( input );

		var serializedInput = serializeJson( preparedInput );

		// At this point, we have the serialized response; but, the response contains unwanted 
		// artifacts that were required to enforce string value integrity. Those must now be
		// removed, post-serialization.
		var sanitizedResponse = removeStartOfStringMarkers( serializedInput );

		return( sanitizedResponse );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	// I define the given key withihn the given key list.
	private any function defineKey(
		required struct keyList,
		required string key 
		) {

		if ( structKeyExists( fullKeyList, key ) ) {

			throw( 
				type = "DuplicateKey",
				message = "The key [#key#] has already been defined within the serializer.",
				detail = "The current key list is: #structKeyList( fullKeyList, ', ' )#"
			);

		}

		// Add to the appropriate data-type lists.
		keyList[ key ] = key;

		// Add all keys to the full key list as well. NOTE: If the given key list IS the 
		// default key list, we'll get the same key written twice. Not the best thing; but,
		// causes no problems.
		fullKeyList[ key ] = key;

		// Return this reference for method chaining.
		return( this );

	}


	// I return the ISO 8601 time string for the given date. This function assumes that the
	// date is already in the desired timezone. 
	private string function getIsoTimeString(  required date input ) {

		return(
			dateFormat( input, "yyyy-mm-dd" ) & "T" &
			timeFormat( input, "HH:mm:ss.l" ) & "Z"
		);

	}


	// I prepare the given array for serialization. Since the array doesn't have keys, this 
	// function will simply walk the array and prepare each value contained within the array.
	private array function prepareArrayForSerialization( required array input ) {

		var preparedInput = [];

		for ( var value in input ) {

			arrayAppend(
				preparedInput,
				prepareInputForSerialization( value )
			);

		}

		return( preparedInput );

	}


	// I prepare the input for case/value-sensitive serialization.
	private any function prepareInputForSerialization( required any input ) {

		// Convert the response based on its type.
		if ( isArray( input ) ) {

			return(
				prepareArrayForSerialization( input )
			);

		} else if ( isStruct( input ) ) {

			return( 
				prepareStructForSerialization( input )
			);

		} else if ( isQuery( input ) ) {

			return(
				prepareQueryForSerialization( input )
			);

		}

		// If the input is not a complex type, then we can gain no insight on how it's supposed
		// to be converted (we only get this insight when a KEY is provided). As such, simply
		// pass this through and let ColdFusion handle it as best as possible.
		return( input );

	}


	// I prepare the key-value pair for use in the prepared input. I will attempt to convert the
	// value into the serialization-specific data type before adding it to the input.
	private struct function prepareKeyValuePairForSerialization(
		required struct preparedInput,
		required string key,
		required any value
		) {

		// If this key has been blocked, just return the unaltered input.
		if ( structKeyExists( blockedKeyList, key ) ) {

			return( preparedInput );

		}

		// Now that we know this key isn't blocked, get the case-sensitive version of it as
		// defined in our key list. If the key has not been defined, we'll use lowercase as
		// the default formatting. 
		var preparedKey = ( 
			structKeyExists( fullKeyList, key ) 
				? fullKeyList[ key ] 
				: lcase( key )
		);

		// Check to see if the key was defined in a data-type-specific list. If so, we'll try to
		// convert the value as we copy it over into the prepared input.
		if (
			structKeyExists( integerKeyList, key ) &&
			isNumeric( value )
			) {

			var preparedValue = javaCast( "long", value );

		} else if (
			structKeyExists( floatKeyList, key ) &&
			isValid( "float", value )
			) {

			var preparedValue = javaCast( "float", value );

		} else if (
			structKeyExists( booleanKeyList, key ) &&
			isBoolean( value )
			) {

			var preparedValue = javaCast( "boolean", value );

		} else if (
			structKeyExists( dateKeyList, key ) &&
			isNumericDate( value )
			) {

			if ( convertDateToUtcMilliseconds ) {

				var preparedValue = javaCast( 
					"long",
					dateConvert( "utc2local", value ).getTime()
				);

			} else {

				var preparedValue = getIsoTimeString( value );

			}

		} else if ( 
			isSimpleValue( value ) &&
			( value.getClass().getName() == "coldfusion.runtime.OleDateTime" ) 
			) {

			var preparedValue = getIsoTimeString( value );
			
		} else if ( isSimpleValue( value ) ) {

			// Prepend the string-value with the start-of-string marker so that ColdFusion won't 
			// be tempted to serialize the string value as a number.
			var preparedValue = ( START_OF_STRING & value );

		} else {

			var preparedValue = prepareInputForSerialization( value );

		}

		// Add the prepared key/value pair into the prepared input.
		preparedInput[ preparedKey ] = preparedValue;

		return( preparedInput );

	}


	// I prepare the given query for serialization.
	private array function prepareQueryForSerialization( required query input ) {

		var preparedInput = [];

		for ( var i = 1 ; i <= input.recordCount ; i++ ) {

			arrayAppend(
				preparedInput,
				prepareQueryRowForSerialization( input, i )
			);

		}

		return( preparedInput );

	}


	// I prepare the given query row for serialization. Each query row is converted to a 
	// struct in which the column name is the struct-key, and the row value is the struct-value.
	private struct function prepareQueryRowForSerialization( 
		required query input,
		required numeric rowIndex
		) {

		var preparedInput = {};

		for ( var key in listToArray( input.columnList ) ) {

			prepareKeyValuePairForSerialization(
				preparedInput,
				key,
				input[ key ][ rowIndex ]
			);

		}

		return( preparedInput );

	}


	// I prepare the given struct for serialization.
	private struct function prepareStructForSerialization( required struct input ) {

		var preparedInput = {};

		for ( var key in input ) {

			prepareKeyValuePairForSerialization(
				preparedInput, 
				key,
				input[ key ]
			);

		}

		return( preparedInput );

	}


	// I strip out the start-of-string markers that were used to force ColdFusion to serialize
	// the given value as a string (ie, blocks accidental numeric conversions).
	private string function removeStartOfStringMarkers( required string response ) {

		return(
			response.replaceAll(
				javaCast( "string", START_OF_STRING ),
				javaCast( "string", "" )
			)
		);

	}


}

</cfscript>