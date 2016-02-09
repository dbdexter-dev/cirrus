#import "CirrusLockScreen.h"
#import "XMLReader.h"
#import <coreLocation/CoreLocation.h>

#define BUNDLE @"/Library/Application Support/Cirrus"
#define ISNIGHT ((double)[[NSDate date]timeIntervalSince1970] < [[_weatherInfo objectForKey:@"sunrise"]doubleValue]) || ((double)[[NSDate date]timeIntervalSince1970] > [[_weatherInfo objectForKey:@"sunset"]doubleValue])
#define INTERVAL 3600	//Time between subsequent weather updates
#define APP_ID "com.dbdexter.cirruspreferences"

#define __updateTimer MSHookIvar<NSTimer*>(self, "_updateTimer")
#define __forecastConnection MSHookIvar<NSURLConnection*>(self, "_forecastConnection")
#define __forecastData MSHookIvar<NSMutableData*>(self, "_forecastData")
#define __sunConnection MSHookIvar<NSURLConnection*>(self, "_sunConnection")
#define __sunData MSHookIvar<NSMutableData*>(self, "_sunData")

@interface SBLockScreenView : UIView
@property (nonatomic,retain) CirrusLSForecastView *dateView;
@end

@interface WeatherLocationManager : NSObject
+(id)sharedWeatherLocationManager;
-(BOOL)locationTrackingIsReady;
-(void)setLocationTrackingReady:(BOOL)arg1 activelyTracking:(BOOL)arg2 watchKitExtension:(id)arg3;
-(void)setLocationTrackingActive:(BOOL)arg1;
-(CLLocation*)location;
-(void)setDelegate:(id)arg1;
@end

static BOOL isEnabled;
static BOOL shouldAutolocate;
static double updateInterval;
static float latitude;
static float longitude;
static BOOL isFarenheit;

static NSMutableDictionary* _weatherInfo = nil;
static double lastTimeChecked;

/**
 * A function that updates the global variables syncing them with the preferences
 * the user can access in a preference pane
 */

static void loadPreferences() {
	isEnabled = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR("enabled"), CFSTR(APP_ID), NULL);
	updateInterval = [(id)CFPreferencesCopyAppValue(CFSTR("updateInterval"), CFSTR(APP_ID)) doubleValue];
	shouldAutolocate = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR("shouldAutolocate"), CFSTR(APP_ID), NULL);
	latitude = [(id)CFPreferencesCopyAppValue(CFSTR("latitude"), CFSTR(APP_ID)) floatValue];
	longitude = [(id)CFPreferencesCopyAppValue(CFSTR("longitude"), CFSTR(APP_ID)) floatValue];
	isFarenheit = (CFPreferencesGetAppIntegerValue(CFSTR("tempUnit"), CFSTR(APP_ID), NULL) == 1);
	lastTimeChecked = 0;
}

/**
 * Function called every time the preferences are chagned by the user
 */

static void reloadPreferences(CFNotificationCenterRef center, void *observer,
    CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	
    CFPreferencesAppSynchronize(CFSTR(APP_ID));		//Load preferences from disk
    loadPreferences();								//Update with current values
}


/**
 + An extremeyl time-consuming function that converts weather IDs into filenames
 * It also takes care of returning a filename based on current lighting conditions
 */

static NSString* idToFname(int weatherID, BOOL isNight) {
	if(weatherID > 100)
		weatherID -= 100;
	switch(weatherID) {
		case 6:
		case 24:
		case 25:
			return (isNight ? @"Cloud-Lightning-Moon":@"Cloud-Lightning-Sun");
			break;
			
		case 11:
		case 22:
		case 30:
			return @"Cloud-Lightning";
			break;
			
		case 5:
		case 40:
			return (isNight ? @"Cloud-Drizzle-Moon":@"Cloud-Drizzle-Sun");
			break;
			
		case 46:
			return @"Cloud-Drizzle";
			break;

		case 41:
			return (isNight ? @"Cloud-Rain-Moon":@"Cloud-Rain-Sun");
			break;
			
		case 9:
		case 10:
			return @"Cloud-Rain";
			break;
		
		case 7:
		case 20:
		case 26:
		case 27:
		case 42:
		case 43:
			return (isNight ? @"Cloud-Hail-Moon":@"Cloud-Hail-Sun");
			break;
		
		case 12:
		case 23:
		case 31:
		case 32:
		case 47:
		case 48:
			return @"Cloud-Hail";
			break;
		
		case 8:
		case 21:
		case 28:
		case 29:
		case 44:
		case 45:
			return (isNight ? @"Cloud-Snow-Moon":@"Cloud-Snow-Sun");
			break;

		case 13:
		case 14:
		case 33:
		case 34:
		case 49:
		case 50:
			return @"Cloud-Snow";
			break;

		case 15:
			return @"Cloud-Fog";
		
		case 1:
			return (isNight ? @"Moon":@"Sun");
			break;
		
		case 2:
		case 3:
			return (isNight ? @"Cloud-Moon":@"Cloud-Sun");
			break;
			
		case 4:
			return @"Cloud";
			break;

		default:
			return @"Cloud-Refresh";
			break;
	}
}

%hook SBFLockScreenDateView
+(id)alloc {
	if(isEnabled)
		return [CirrusLSForecastView alloc];
	else
		return %orig();
}
%end

%hook CirrusLSForecastView

/**
 * A method that takes care of updating the global NSDictionary containing the current
 * weater info. It does not update the displayed info
 */
-(void)_updateWeatherInfo {
	if(([[NSDate date]timeIntervalSince1970]-(updateInterval * 3600) >= lastTimeChecked)) {		//Make sure we updated long enough ago
		lastTimeChecked = [[NSDate date] timeIntervalSince1970];				//Update last check timestamp
		
		if(shouldAutolocate) {									//Find our current location and get the forecast for that lat/lon
			WeatherLocationManager *weatherLocationManager = [%c(WeatherLocationManager) sharedWeatherLocationManager];
			CLLocationManager *locationManager = [[CLLocationManager alloc]init];
			 
			[weatherLocationManager setDelegate:locationManager];				//Needed to receive the current position coordinated
			
			if(![weatherLocationManager locationTrackingIsReady]) {
				[weatherLocationManager setLocationTrackingReady:YES activelyTracking:NO watchKitExtension:nil];
			}
			
			[weatherLocationManager setLocationTrackingActive:YES];				//Start tracking
			
			latitude = [[weatherLocationManager location] coordinate].latitude;		//Save latitude
			longitude = [[weatherLocationManager location] coordinate].longitude;		//Save longitude
			
			NSLog(@"[Cirrus] current coordinates: %fN %fE", latitude, longitude);		

			[weatherLocationManager setLocationTrackingActive:NO];				//Stop tracking
			[locationManager release];							//Release allocated object
		}
		
		NSString* url =[NSString stringWithFormat:@"http://api.met.no/weatherapi/locationforecast/1.9/?lat=%f;lon=%f", latitude, longitude];
		NSURLRequest *forecastQuery = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
		__forecastConnection = [[NSURLConnection alloc] initWithRequest:forecastQuery delegate:self];
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
		formatter.dateFormat = @"yyyy-MM-dd";							//Need today's date to get sunrise and sunset times
		
		NSString* sunUrl = [NSString stringWithFormat:@"http://api.yr.no/weatherapi/sunrise/1.0/?lat=%f;lon=%f;date=%@", latitude, longitude, [formatter stringFromDate:[NSDate date]]];
		NSURLRequest *sunQuery = [NSURLRequest requestWithURL:[NSURL URLWithString:sunUrl]];
		__sunConnection = [[NSURLConnection alloc] initWithRequest:sunQuery delegate:self];
		[formatter release];

	} else {
		[self _updateDisplayedWeather];
		if(!__updateTimer)
			__updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_updateDisplayedWeather) userInfo:nil repeats:YES];
	}
}

-(void) dealloc {
	[__updateTimer invalidate];
	__updateTimer = nil;
	%orig();
}
/**
 * A method that syncs the displayed weather with the global NSDictionary _weatherInfo
 */

-(void)	_updateDisplayedWeather{
	UIImageView* iconView = MSHookIvar<UIImageView*>(self, "_iconView");
	_UILegibilityLabel* tempLabel = MSHookIvar<_UILegibilityLabel*>(self, "_tempLabel");
	UILabel* maxMinLabel = MSHookIvar<UILabel*>(self, "_maxMinLabel");
	_UILegibilityLabel* forecastOne = MSHookIvar<_UILegibilityLabel*>(self, "_forecastOne");
	_UILegibilityLabel* forecastTwo = MSHookIvar<_UILegibilityLabel*>(self, "_forecastTwo");
	_UILegibilityLabel* forecastThree = MSHookIvar<_UILegibilityLabel*>(self, "_forecastThree");
	
	NSBundle *bundle = [NSBundle bundleWithPath:BUNDLE];
	NSString *imageName = idToFname([[_weatherInfo objectForKey:@"id"] intValue], ISNIGHT);
	NSString *iconPath = [bundle pathForResource:imageName ofType:@"png"];	//Load image named based on the current weather info
	
	[iconView setImage:[UIImage imageNamed:iconPath]];
	iconView.image = [iconView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[iconView setTintColor:(tempLabel.usesSecondaryColor ? self.legibilitySettings.secondaryColor:self.legibilitySettings.primaryColor)];
	
	int temp = lroundf([[_weatherInfo objectForKey:@"temp"]doubleValue] * (isFarenheit ? 1.8 : 1) + (isFarenheit ? 32 : 0));
	int temp_min = lroundf([[_weatherInfo objectForKey:@"temp_min"]doubleValue] * (isFarenheit ? 1.8 : 1) + (isFarenheit ? 32 : 0));
	int temp_max = lroundf([[_weatherInfo objectForKey:@"temp_max"]doubleValue] * (isFarenheit ? 1.8 : 1) + (isFarenheit ? 32 : 0));
	int temp_one = lroundf([[_weatherInfo objectForKey:@"temp_one"]doubleValue] * (isFarenheit ? 1.8 : 1) + (isFarenheit ? 32 : 0));
	int temp_two = lroundf([[_weatherInfo objectForKey:@"temp_two"]doubleValue] * (isFarenheit ? 1.8 : 1) + (isFarenheit ? 32 : 0));
	int temp_three = lroundf([[_weatherInfo objectForKey:@"temp_three"]doubleValue] * (isFarenheit ? 1.8 : 1) + (isFarenheit ? 32 : 0));

	tempLabel.string = [NSString stringWithFormat:@"%d", temp];							//Set current temperature
	maxMinLabel.text = [NSString stringWithFormat:@"%d°\t%d°", temp_min, temp_max];	//Set 6h max/min temps
	
	NSDate* forecastHour = [[NSDate dateWithTimeIntervalSince1970:lastTimeChecked] dateByAddingTimeInterval:3*3600];
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc]init];
	dateFormatter.dateFormat = @"ha";
	
	forecastOne.string = [NSString stringWithFormat:@"%@: %d°", [dateFormatter stringFromDate:forecastHour], temp_one];	//Set +3h temp
	forecastHour = [forecastHour dateByAddingTimeInterval:3*3600];
	forecastTwo.string = [NSString stringWithFormat:@"%@: %d°", [dateFormatter stringFromDate:forecastHour], temp_two];	//Set +6h temp
	forecastHour = [forecastHour dateByAddingTimeInterval:3*3600];
	forecastThree.string = [NSString stringWithFormat:@"%@: %d°", [dateFormatter stringFromDate:forecastHour], temp_three];	//Set +9h temp
	
	[dateFormatter release];
	[self layoutSubviews];
}

%new
-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {		//prepare to receive data
	if(connection == __forecastConnection) {
		__forecastData = [[NSMutableData alloc]init];
	} else if (connection == __sunConnection) {
		__sunData = [[NSMutableData alloc]init];
	}
}
%new
-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)response {			//Append data
	if(connection == __forecastConnection) {
		[__forecastData appendData:response];
	} else if (connection == __sunConnection) {
		[__sunData appendData:response];
	}

}
%new
-(NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse {
	return nil;											//Don't cache data
}
%new
-(void)connectionDidFinishLoading:(NSURLConnection*)connection {
	if(connection == __forecastConnection) {
		if(__forecastData == nil) {				//If we didn't receive any data
			lastTimeChecked = 0;				//Will retry next time we are asked for the weather
			return;
		}
		
		NSDictionary *xml = [XMLReader dictionaryForXMLData:__forecastData error:nil];				//Parse the data

		BOOL isLocal = ![[xml valueForKeyPath:@"weatherdata.meta.model.name"] isKindOfClass:[NSString class]];	//If class is NSString, we received only one forecast
		NSLog(@"[Cirrus] using local weather: %@", (isLocal ? @"YES" : @"NO"));					//That means we will have to go with non-local forecast formatting
															//This has to do with how yr.no represents its data: it uses a local
															//model (if available)  and a global model. For locations outside
															//Europe only the global model seemsn to be available
		
		//The parsing code below is extremely ugly but its principle is quite simple: get the data from the xml response and place it in a more compact NSDictionary,
		//converting the units of measurement as needed
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"H";
		int global_index = ((([[formatter stringFromDate:[NSDate date]]intValue] / 3 + 1) % 2) ? 5 : 8);	//Weird conversion to get the correct index for temp_max and temp_min
															//Because we have 3h forecasts, but only 6h max/min temps
		[formatter release];

		[_weatherInfo setObject: [[[xml valueForKeyPath:@"weatherdata.product.time"]objectAtIndex:(isLocal ? 6 : 4)] valueForKeyPath:@"location.symbol.number"]  forKey:@"id"];
		[_weatherInfo setObject: @((int)lroundf([[[[xml valueForKeyPath:@"weatherdata.product.time"]objectAtIndex:0] valueForKeyPath:@"location.temperature.value"]doubleValue])) forKey:@"temp"];
		[_weatherInfo setObject: @([[[[xml valueForKeyPath:@"weatherdata.product.time"]objectAtIndex:(isLocal ? 34 : global_index)] valueForKeyPath:@"location.maxTemperature.value"]doubleValue]) forKey:@"temp_max"];
		[_weatherInfo setObject: @([[[[xml valueForKeyPath:@"weatherdata.product.time"]objectAtIndex:(isLocal ? 34 : global_index)] valueForKeyPath:@"location.minTemperature.value"]doubleValue]) forKey:@"temp_min"];
		[_weatherInfo setObject: @((int)lroundf([[[[xml valueForKeyPath:@"weatherdata.product.time"]objectAtIndex:(isLocal ? 15 : 3)] valueForKeyPath:@"location.temperature.value"]doubleValue])) forKey:@"temp_one"];
		[_weatherInfo setObject: @((int)lroundf([[[[xml valueForKeyPath:@"weatherdata.product.time"]objectAtIndex:(isLocal ? 30 : 6)] valueForKeyPath:@"location.temperature.value"]doubleValue])) forKey:@"temp_two"];
		[_weatherInfo setObject: @((int)lroundf([[[[xml valueForKeyPath:@"weatherdata.product.time"]objectAtIndex:(isLocal ? 45 : 9)] valueForKeyPath:@"location.temperature.value"]doubleValue])) forKey:@"temp_three"];
		
		[__forecastConnection release];
	} else if (connection == __sunConnection) {
		if(__sunData == nil) {
			lastTimeChecked = 0;
			return;
		}
		NSDictionary *sunXml = [XMLReader dictionaryForXMLData:__sunData error:nil];
		NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
		formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";		//E.g. 2016-02-07T22:15:08Z
		
		[_weatherInfo setObject: @((double)[[formatter dateFromString:[sunXml valueForKeyPath:@"astrodata.time.location.sun.rise"]] timeIntervalSince1970]) forKey:@"sunrise"];
		[_weatherInfo setObject: @((double)[[formatter dateFromString:[sunXml valueForKeyPath:@"astrodata.time.location.sun.set"]] timeIntervalSince1970]) forKey:@"sunset"];

		[__sunConnection release];
		[formatter release];
	}
	
	[self _updateDisplayedWeather];						//Update displayed weather with freshly-fetched data
}
%new
-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error{
	lastTimeChecked = 0;
	NSLog(@"<ERROR> [Cirrus] connection %@ failed", connection);
}

%end


%hook SBLockScreenView
-(void)_layoutDateView {
	%orig();
	if(isEnabled) {								//The frame we're assigned by default is totally off, and it's also small: fix that
		self.dateView.frame = CGRectMake(self.dateView.frame.origin.x,
						 28.5,
						 self.dateView.frame.size.width,
						 self.dateView.frame.size.height+40); 
	}
}
%end

%ctor{
	loadPreferences();							//Load preferences the first time
	CFNotificationCenterAddObserver(					//Add an observer to update the preferences when they are changed
                    CFNotificationCenterGetDarwinNotifyCenter(),
                    NULL, reloadPreferences, CFSTR(APP_ID),
                    NULL, 0);

	_weatherInfo = [[NSMutableDictionary alloc]init];			//Prepare the cached response array
	lastTimeChecked = 0;							//Make sure we check the weather when initialized the very first time
}
