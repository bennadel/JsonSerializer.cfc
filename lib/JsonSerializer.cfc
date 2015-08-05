component
	output = false
	hint = "I provide a way to serialize complex ColdFusion data values as case-sensitive JavaScript Object Notation (JSON) strings."
	{

	// I return the initialized component.
	public any function init() {

		// Every key is added to the full key list - used for one-time key serialization.
		fullKeyList = {};

		// Every key is added to the hint list so that we don't have to switch on the lists.
		fullHintList = {};

		// These key lists determine special data serialization.
		stringKeyList = {};
		booleanKeyList = {};
		integerKeyList = {};
		floatKeyList = {};
		dateKeyList = {};

		// These keys will NOT be used in serialization (ie. the key/value pairs will not be
		// added to the serialized output).
		blockedKeyList = {};

		// Return the initialized component.
		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	// I define the given key without a type. This is here to provide key-casing without caring 
	// about why type of data conversion takes place. Returns serializer.
	public any function asAny( required string key ) {

		return( defineKey( fullKeyList, key, "any" ) );

	}


	// I define the given key as a boolean. Returns serializer.
	public any function asBoolean( required string key ) {

		return( defineKey( booleanKeyList, key, "boolean" ) );

	}


	// I define the given key as a date. Returns serializer.
	public any function asDate( required string key ) {

		return( defineKey( dateKeyList, key, "date" ) );

	}

	// I define the given key as a date in milliseconds since Unix epoch. Returns serializer.
	public any function asEpochMillis( required string key ) {

		return( defineKey( dateKeyList, key, "epochMillis" ) );

	}

	// I define the given key as a float / decimal. Returns serializer.
	public any function asFloat( required string key ) {

		return( defineKey( floatKeyList, key, "float" ) );

	}


	// I define the given key as an integer. Returns serializer.
	public any function asInteger( required string key ) {

		return( defineKey( integerKeyList, key, "integer" ) );

	}


	// I define the given key as a string. Returns serializer.
	public any function asString( required string key ) {

		return( defineKey( stringKeyList, key, "string" ) );

	}


	// I define the key as one that should not be included in the serialized response.
	public any function exclude( required string key ) {

		blockedKeyList[ key ] = true;

		return( this );

	}


	/**
	* I serialize the given input as JavaScript Object Notation (JSON) using the case-sensitive
	* values defined in the key-list.
	* 
	* @output false
	*/
	public string function serialize( required any input ) {

		// Write the serialized value to the output buffer.
		savecontent variable = "local.serializedInput" {

			serializeInput( input, "any" );

		}

		return( serializedInput );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	// I define the given key within the given key list.
	private any function defineKey(
		required struct keyList,
		required string key,
		required string hint
		) {

		if ( structKeyExists( fullKeyList, key ) ) {

			throw( 
				type = "DuplicateKey",
				message = "The key [#key#] has already been defined within the serializer.",
				detail = "The current key list is: #structKeyList( fullKeyList, ', ' )#"
			);

		}

		// Add to the appropriate data-type lists. This one is used for existence checking.
		keyList[ key ] = key;

		// Add all keys to the full key list as well. This one is used to store the serialization
		// of the key so that it doesn't have to be recalculated each time the object is serialized.
		fullKeyList[ key ] = serializeString( key );

		// If we have a specific type, then add the hint to the full hint list as well. This will 
		// allow us to quickly look up the pass-through data type hint during serialization.
		// --
		// NOTE: The reason we don't want to pass through "any" is that we want parent types to be
		// able to "fall through" during the object traversal. If we added "any" to the type list, 
		// then it would always overwrite the parent data type.
		if ( hint != "any" ) {

			fullHintList[ key ] = hint;
			
		}

		// Return this reference for method chaining.
		return( this );

	}


	// I walk the given object, writing the serialized value to the output (which is expected to 
	// be a content buffer).
	// ---
	// NOTE: THIS METHOD IS HUGE - this is on purpose. Since serialization is a rather intense 
	// process, I am trying to cut out as much overhead as possible. In this case, we're cutting 
	// out extra stack space by inlining and duplicating a lot of functionality. This is being done 
	// at the COST of clarity and non-repetitive code.
	private void function serializeInput(
		required any input,
		required string hint
		) {

		// Serialize the data base on the type of input. We are organizing this in terms of the 
		// most commonly-used values first. The anticipation is that the vast majority of data 
		// types will be simple values. 
		if ( isSimpleValue( input ) ) {

			if ( ( hint == "string" ) || ( hint == "any" ) ) {

				// If the string appears to be numeric, then we have to prefix it to make sure 
				// ColdFusion doesn't accidentally convert it to a number.
				if ( isNumeric( input ) ) {

					writeOutput( """" & input & """" );

				} else {

					serializeInputString( input );

				}

			} else if ( ( hint == "boolean" ) && isBoolean( input ) ) {

				writeOutput( input ? "true" : "false" );

			} else if ( ( ( hint == "integer" ) || ( hint == "float" ) ) && isNumeric( input ) ) {

				writeOutput( input );

			} else if ( ( ( hint == "integer" ) || ( hint == "float" ) ) && isBoolean( input ) ) {

				writeOutput( input ? "1" : "0" );

			} else if ( ( hint == "date" ) && ( isDate( input ) || isNumericDate( input ) ) ) {

				// Write the date in ISO 8601 time string format. We're going to assume that the 
				// date is already in the desired timezone. 
				writeOutput( """" & dateFormat( input, "yyyy-mm-dd" ) & "T" & timeFormat( input, "HH:mm:ss.l" ) & "Z""" );

			} else if ( hint == "epochMillis" ) {

				if ( isDate( input ) ) {

					writeOutput( input.getTime() );

				} else if ( isNumericDate( input ) ) {

					writeOutput( createObject( "java", "java.util.Date" ).setTime( input ).getTime() );

				} else {

					serializeInputString( input );

				}

			} else {

				serializeInputString( input );

			}

			return;

		} // END: isSimpleValue().


		// I'm expecting the struct to be the next most common data type since it will likely be 
		// the container for the majority of data values.
		if ( isStruct( input ) ) {

			writeOutput( "{" );

			var isFirst = true;

			for ( var key in input ) {

				// Skip any black-listed keys.
				if ( structKeyExists( blockedKeyList, key ) ) {

					continue;

				}

				// Handle the item delimiter.
				if ( isFirst ) {

					isFirst = false;

				} else {

					writeOutput( "," );

				}

				// Ensure that the given key can be referenced on the full-key list. This way,
				// the subsequent logic will be easier.
				if ( ! structKeyExists( fullKeyList, key ) ) {

					asAny( lcase( key ) );

				}

				writeOutput( fullKeyList[ key ] & ":" );

				// Pass in the most appropriate data-type hint based on the parent key.
				if ( structKeyExists( fullHintList, key ) ) {

					serializeInput( input[ key ], fullHintList[ key ] );

				// If the given key is unknown, just pass through the most recent hint as 
				// it may be defining the type for an entire structure.
				} else {

					serializeInput( input[ key ], hint );

				}

			}

			writeOutput( "}" );

			return;

		} // END: isStruct().


		if ( isArray( input ) ) {

			writeOutput( "[" );

			var isFirst = true;

			// Handle the item delimiter.
			for ( var value in input ) {

				if ( isFirst ) {

					isFirst = false;

				} else {

					writeOutput( "," );

				}

				// Since we don't have a key to go off of, pass-through the most recent hint.
				serializeInput( value, hint );

			}

			writeOutput( "]" );

			return;

		} // END: isArray().


		// When we serialize a query, we're going to treat it like an array of structs.
		if ( isQuery( input ) ) {

			var keys = listToArray( input.columnList );

			// Make sure each column is defined as a known key - makes the subsequent logic easier.
			for ( var key in keys ) {

				if ( ! structKeyExists( fullKeyList, key ) ) {

					asAny( lcase( key ) );

				}

			}

			writeOutput( "[" );

			// Serialize each row of the query as a struct.
			for ( var i = 1 ; i <= input.recordCount ; i++ ) {

				// Handle the row delimiter.
				if ( i > 1 ) {

					writeOutput( "," );

				}

				writeOutput( "{" );

				var isFirst = true;

				for ( var key in keys ) {

					// Skip any black-listed keys.
					if ( structKeyExists( blockedKeyList, key ) ) {

						continue;

					}

					// Handle the item delimiter (in the current row).
					if ( isFirst ) {

						isFirst = false;

					} else {

						writeOutput( "," );

					}

					writeOutput( fullKeyList[ key ] & ":" );

					// Pass in the most appropriate data-type hint based on the parent key.
					if ( structKeyExists( fullHintList, key ) ) {

						serializeInput( input[ key ][ i ], fullHintList[ key ] );

					// If the given key is unknown, just pass through the most recent hint as 
					// it may be defining the type for an entire structure.
					} else {

						serializeInput( input[ key ][ i ], hint );

					}

				} // END: Key list.

				writeOutput( "}" );

			} // END: Row list.

			writeOutput( "]" );
			
			return;

		} // END: isQuery().


		// If we made it this far, we were given a data type that we're not actively supporting.
		// As such, we just have to hand this off to the native serializer.
		writeOutput( serializeJson( input ) );

	}


	/**
	* I serialize and write the given string to the current output context, escaping all appropriate
	* characters for the JSON specification.
	* 
	* NOTE: We are using this manual-encoding process rather than the built-in serializeJson() function
	* as there is a rather nasty bug that corrupts certain patterns in the output. Read more:
	* 
	* http://www.bennadel.com/blog/2842-serializejson-and-the-input-and-output-encodings-are-not-same-errors-in-coldfusion.htm
	* 
	* @input I am the string being serialized.
	*/
	private void function serializeInputString( required string input ) {

		// While this may not be technically needed, this will ensure that we are not using any 
		// "undocumented features" of the language. If we explicitly cast to  a Java string, and
		// something goes wrong due to odd type-casting, it's a ColdFusion bug, at that point, not 
		// a logic error ;)
		input = javaCast( "string", input );

		var length = input.length();

		writeOutput( """" );

		for ( var i = 1 ; i <= length ; i++ ) {

			var charCode = input.codePointAt( javaCast( "int", i - 1 ) );

			// Check for the most common case first (normal characters).
			if ( 
				( charCode >= 32 ) &&
				( charCode != 34 ) &&
				( charCode != 47 ) &&
				( charCode != 92 ) &&
				( charCode != 8232 ) &&
				( charCode != 8233 )
				) {

				writeOutput( chr( charCode ) );

			// Check for the special cases next (control characters, characters that
			// need to be escaped, and characters that need to be encoded nicely).
			} else if ( charCode == 8 ) {

				writeOutput( "\b" );
				
			} else if ( charCode == 9 ) {

				writeOutput( "\t" );

			} else if ( charCode == 10 ) {

				writeOutput( "\n" );

			} else if ( charCode == 12 ) {

				writeOutput( "\f" );

			} else if ( charCode == 13 ) {

				writeOutput( "\r" );

			} else if ( 
				( charCode < 32 ) ||
				( charCode == 8232 ) ||
				( charCode == 8233 )
				) {

				// For Unicode hex values, we need to enforce a 4-digit code.
				writeOutput( "\u" & right( ( "000" & formatBaseN( charCode, 16 ) ), 4 ) );

			} else if ( charCode == 34 ) {

				writeOutput( "\""" );

			} else if ( charCode == 47 ) {

				writeOutput( "\/" );

			} else if ( charCode == 92 ) {

				writeOutput( "\\" );

			}

		}

		writeOutput( """" );

	}


	/**
	* I serialize and return the given string, escaping all appropriate characters for the 
	* JSON specification.
	* 
	* @input I am the string being serialized.
	* @output false
	*/
	private string function serializeString( required string input ) {

		savecontent variable = "local.json" {

			serializeInputString( input );

		}

		return( json );

	}

}