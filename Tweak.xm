#import "CirrusLockScreen.h"

#define BUNDLE @"/Library/Application Support/Cirrus"
#define INTERVAL 3600	//Time between subsequent weather updates
#define APP_ID "com.dbdexter.cirruspreferences"

@interface SBLockScreenView : UIView
@property (nonatomic,retain) CirrusLSForecastView *dateView;
@end
static BOOL isEnabled;
static BOOL isLocal;
static double updateInterval;
static double y_offset;
/**
 * A function that updates the global variables syncing them with the preferences
 * the user can access in a preference pane
 */

static void loadPreferences() {
	isEnabled = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR("enabled"), CFSTR(APP_ID), NULL);
	isLocal = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR("useLocalWeather"), CFSTR(APP_ID), NULL);
	updateInterval = [(id)CFPreferencesCopyAppValue(CFSTR("updateInterval"), CFSTR(APP_ID)) doubleValue];
	y_offset = [(id)CFPreferencesCopyAppValue(CFSTR("y_offset"), CFSTR(APP_ID)) doubleValue];
	
}

/**
 * Function called every time the preferences are chagned by the user
 */

static void reloadPreferences(CFNotificationCenterRef center, void *observer,
    CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	
    CFPreferencesAppSynchronize(CFSTR(APP_ID));		//Load preferences from disk
    loadPreferences();								//Update with current values
}




%hook SBFLockScreenDateView
+(id)alloc {
	if(isEnabled)
		return (SBFLockScreenDateView*)[CirrusLSForecastView alloc];
	else
		return %orig();
}
%end

%hook SBLockScreenView
-(void)_layoutDateView {
       %orig();
       if(isEnabled) {                                                         //The frame we're assigned by default is totally off, and it's also small: fix that
               self.dateView.frame = CGRectMake(self.dateView.frame.origin.x,
                                                y_offset,
                                                self.dateView.frame.size.width,
                                                self.dateView.frame.size.height+40);
       }
}
%end

%hook CirrusLSForecastView
-(void)_forceWeatherUpdate {
	City *_city = (isLocal ? [[%c(WeatherPreferences) sharedPreferences] localWeatherCity] : [[%c(WeatherPreferences) sharedPreferences] cityFromPreferencesDictionary:[[[%c(WeatherPreferences) userDefaultsPersistence]userDefaults] objectForKey:@"Cities"][0]]);
	HBLogDebug(@"Weather for %@ updated at %@", _city, [_city updateTime]);
	if([[NSDate date] compare:[[_city updateTime] dateByAddingTimeInterval:updateInterval*3600]] == NSOrderedDescending) {
			[self _forceWeatherUpdate_isLocal:isLocal];
	}
}
-(void)_updateDisplayedWeather {
	[self _updateDisplayedWeather_isLocal:isLocal];
}
%end

%ctor{
	loadPreferences();							//Load preferences the first time
	CFNotificationCenterAddObserver(					//Add an observer to update the preferences when they are changed
                    CFNotificationCenterGetDarwinNotifyCenter(),
                    NULL, reloadPreferences, CFSTR(APP_ID),
                    NULL, 0);
}
