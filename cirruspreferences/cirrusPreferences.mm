#import <Preferences/Preferences.h>
#import <coreLocation/CoreLocation.h>
#define APP_ID "com.dbdexter.cirruspreferences"

@interface cirrusPreferencesListController: PSListController {
	NSMutableArray* _latitudelongitudeSpecifiers;
}
@end

@interface PSSwitchTableCell : PSControlTableCell
- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier;
@end
 
@interface CustomSwitchTableCell : PSSwitchTableCell
@end

@implementation cirrusPreferencesListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"cirrusPreferences" target:self] retain];
	}
	return _specifiers;
}

- (void)launchDonate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=82VVG6U8TMP3Q"]];
}
@end


@implementation CustomSwitchTableCell
 
-(id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier { //init method
	self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier]; //call the super init method
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:[UIColor colorWithRed:0.1765 green:0.4863 blue:1 alpha:1]]; //change the switch color
	}
	return self;
}
 
@end


// vim:ft=objc
