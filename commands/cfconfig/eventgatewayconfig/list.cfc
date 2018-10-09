/**
* List all event gateway configurations for a server.
* 
* {code}
* cfconfig eventgatewayconfig list
* cfconfig eventgatewayconfig list from=serverName
* cfconfig eventgatewayconfig list from==/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig eventgatewayconfig list --JSON
* {code}
* 
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	property name="ConfigService" inject="ConfigService";
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @from.optionsFileComplete true
	* @from.optionsUDF serverNameComplete
	* @fromFormat The format to read from. Ex: LuceeServer@5
	* @JSON Set to try to receive mappings back as a parsable JSON object
	*/
	function run(
		string from,
		string fromFormat,
		boolean JSON
	) {
		arguments.from = arguments.from ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		
		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat );
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		}
			
		if( !fromDetails.path.len() ) {
			error( "The location for the server couldn't be determined.  Please check your spelling." );
		}
		
		if( !directoryExists( fromDetails.path ) && !fileExists( fromDetails.path ) ) {
			error( "The CF Home directory for the server doesn't exist.  [#fromDetails.path#]" );
		}
		
		// Read the config
		var oConfig = CFConfigService.determineProvider( fromDetails.format, fromDetails.version )
			.read( fromDetails.path );

		// Get the mappings, remembering it can be null
		var eventGatewayConfigurations = oConfig.getEventGatewayConfigurations() ?: [];
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
					
			// Detect if this installed version of CommandBox can handle automatic JSON formatting (and coloring)
			if( configService.getPossibleConfigSettings().findNoCase( 'JSON.ANSIColors.constant' ) ) {
				print.line( eventGatewayConfigurations );
			} else {
				print.line( formatterUtil.formatJSON( eventGatewayConfigurations ) );	
			}
			
		} else {
			if( eventGatewayConfigurations.len() ) {
				for( var eventGatewayConfiguration in eventGatewayConfigurations ) {
					print.boldLine( 'Name: #eventGatewayConfiguration.type#' );
					print.indentedLine( 'Description: #eventGatewayConfiguration.description#' );
					print.indentedLine( 'Javaclass: #eventGatewayConfiguration.class#' );
					print.indentedLine( 'Timeout: #eventGatewayConfiguration.starttimeout#' );
					print.indentedLine( 'Kill on Timeout?: #eventGatewayConfiguration.killontimeout#' );
					print.line();
				}
			} else {
				print.line( 'No event gateway configurations defined.' );
			}
		}

	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}