#import "CirrusLockScreen.h"

#define BUNDLE @"/Library/Application Support/Cirrus"
#define INTERVAL 3600	//Time between subsequent weather updates
#define APP_ID "com.dbdexter.cirruspreferences"

@interface SBLockScreenView : UIView
@property (nonatomic,retain) CirrusLSForecastView *dateView;
@end

@interface City : NSObject
-(NSDate*)updateTime;
@end

@interface WeatherPreferences : NSObject
+(id)sharedPreferences;
-(City*)localWeatherCity;
@end

static BOOL isEnabled;
static double updateInterval;
/**
 * A function that updates the global variables syncing them with the preferences
 * the user can access in a preference pane
 */

static void loadPreferences() {
	isEnabled = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR("enabled"), CFSTR(APP_ID), NULL);
	updateInterval = [(id)CFPreferencesCopyAppValue(CFSTR("updateInterval"), CFSTR(APP_ID)) doubleValue];
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
                                                28.5,
                                                self.dateView.frame.size.width,
                                                self.dateView.frame.size.height+40);
       }
}
%end

%hook CirrusLSForecastView
-(void)_forceWeatherUpdate {
	if([[NSDate date] compare:[[[[%c(WeatherPreferences)sharedPreferences]localWeatherCity]updateTime] dateByAddingTimeInterval:updateInterval*3600]] == NSOrderedDescending)
		%orig();
}
%end

%ctor{
	loadPreferences();							//Load preferences the first time
	CFNotificationCenterAddObserver(					//Add an observer to update the preferences when they are changed
                    CFNotificationCenterGetDarwinNotifyCenter(),
                    NULL, reloadPreferences, CFSTR(APP_ID),
                    NULL, 0);
}
