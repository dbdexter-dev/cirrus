#import "CirrusLockScreen.h"
#import <Weather/HourlyForecast.h>
#import <Weather/DayForecast.h>
#import <coreLocation/CoreLocation.h>

#define LSFONT @".SFUIDisplay-Ultralight"
#define BUNDLE @"/Library/Application Support/Cirrus"

/**
 * An extremely time-consuming function that converts weather IDs into filenames
 * It also takes care of returning a filename based on current lighting conditions
 */

static NSString* idToFname(unsigned long long weatherID, BOOL isNight) {
	switch(weatherID) {
		case 0:
		case 1:
		case 2:
		case 19:
			return @"Tornado";
			break;
		
		case 3:
		case 4:
		case 45:
			return @"Cloud-Lightning";
			break;

		case 5:
		case 6:
		case 7:
		case 13:
		case 14:
		case 15:
		case 16:
		case 18:
		case 41:
		case 43:
		case 46:
			return @"Cloud-Snow";
			break;
		
		case 42:
			return isNight ? @"Cloud-Snow-Moon" : @"Cloud-Snow-Sun";
			break;

		case 8:
		case 9:
			return @"Cloud-Drizzle";
			break;

		case 10:
		case 17:
		case 35:
			return @"Cloud-Hail";
			break;

		case 11:
		case 12:
			return @"Cloud-Rain";
			break;

		case 20:
		case 21:
		case 22:
		case 23:
			return @"Cloud-Fog";
			break;

		case 24:	
			return @"Wind";
			break;

		case 26:
			return @"Cloud";
			break;

		case 27:
		case 29:
		case 33:
			return @"Cloud-Moon";
			break;

		case 28:
		case 30:
		case 34:
			return @"Cloud-Sun";
			break;

		case 31:
			return @"Moon";
			break;

		case 32:
			return @"Sun";
			break;

		case 37:
		case 38:
		case 39:
		case 47:
			return isNight ? @"Cloud-Lightning-Moon" : @"Cloud-Lightning-Sun";
			break;

		case 40:
			return isNight ? @"Cloud-Rain-Moon" : @"Cloud-Rain-Sun";
			break;


		case 44:
			return isNight ? @"Cloud-Moon" : @"Cloud-Sun";
			break;

		default:
			return @"Cloud-Refresh";
			break;
	}
}

@implementation CirrusLSForecastView : UIView

-(id)initWithFrame:(CGRect)frame{
	[super initWithFrame:frame];

	NSBundle *bundle = [NSBundle bundleWithPath:BUNDLE];
	
	_dateFormatter = [[NSDateFormatter alloc]init];
	_dateFormatter.locale = [NSLocale currentLocale];
	
	_dateStrength = 0.33;
	_timeStrength = 0.33;
	
	_legibilitySettings = [[_UILegibilitySettings alloc]initWithStyle:0
							     primaryColor:[UIColor whiteColor]
							   secondaryColor:[UIColor colorWithWhite:0.25 alpha:1]
							      shadowColor:[UIColor colorWithWhite:0.1 alpha:0.23]];

	NSString *iconPath = [bundle pathForResource:@"Cloud-Refresh" ofType:@"png"];		//Get path to temporary image
	_iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconPath]];
	_iconView.image = [_iconView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[_iconView setTintColor:(_tempLabel.usesSecondaryColor ? _legibilitySettings.secondaryColor:_legibilitySettings.primaryColor)];
	
	_dateLabel = [[UILabel alloc]init];
	_maxMinLabel = [[UILabel alloc]init];
	_timeLabel = [[_UILegibilityLabel alloc]initWithSettings:_legibilitySettings
							strength:_timeStrength
							  string:@"00:00"
							    font:[UIFont systemFontOfSize:17]];

	_tempLabel = [[_UILegibilityLabel alloc]initWithSettings:_legibilitySettings
							strength:_dateStrength
							  string:@"0"
							    font:[UIFont fontWithName:LSFONT size:87]];
		
	_forecastOne = [[_UILegibilityLabel alloc]initWithSettings:_legibilitySettings
							  strength:_timeStrength
							    string:@"---"
							      font:[UIFont systemFontOfSize:15]];

	_forecastTwo = [[_UILegibilityLabel alloc]initWithSettings:_legibilitySettings
							  strength:_timeStrength
							    string:@"---"
							      font:[UIFont systemFontOfSize:15]];

	_forecastThree = [[_UILegibilityLabel alloc]initWithSettings:_legibilitySettings
							    strength:_timeStrength
							      string:@"---"
							        font:[UIFont systemFontOfSize:15]];
															
	_degree = [[_UILegibilityLabel alloc]initWithSettings:_legibilitySettings
						     strength:_timeStrength
						       string:@"°"
							 font:[UIFont systemFontOfSize:15]];
	_degree.frame = CGRectMake(-4, 14, 10, 10);
	
	[_dateLabel setTextAlignment:NSTextAlignmentRight];
	_dateLabel.font = [UIFont fontWithName:@".SFUIDisplay-Thin" size:14];
	_dateLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
		
	[_maxMinLabel setTextAlignment:NSTextAlignmentRight];
	_maxMinLabel.font = [UIFont systemFontOfSize:11];
	_maxMinLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
	_maxMinLabel.text = @"0°\t0°";

	_useLegibilityLabels = YES;
	
	[self _forceWeatherUpdate];

	[self addSubview:_iconView];
	[self addSubview:_timeLabel];
	[self addSubview:_dateLabel];
	[self addSubview:_tempLabel];
	[self addSubview:_maxMinLabel];
	[self addSubview:_forecastOne];
	[self addSubview:_forecastTwo];
	[self addSubview:_forecastThree];
	[_iconView addSubview:_degree];
	
	[self _updateLabels];
	[self _updateDisplayedWeather];

	[_degree release];
	[_iconView release];
	[_timeLabel release];
	[_dateLabel release];
	[_tempLabel release];
	[_maxMinLabel release];
	[_forecastOne release];
	[_forecastTwo release];
	[_forecastThree release];
	
	HBLogDebug(@"[Cirrus] LSForecastView: initialized");
	return self;
}

-(void)dealloc{
	HBLogDebug(@"[Cirrus] LSForecastView: deallocating");
	[_legibilitySettings release];
	[_dateFormatter release];
	[super dealloc];
}
-(void)setTextColor:(UIColor *)arg1{
	HBLogDebug(@"[Cirrus] LSForecastView: trying to set text color to %@", arg1);
	if(!arg1)
		return;
	[_legibilitySettings setPrimaryColor:arg1];
	_textColor = arg1;
	[self setLegibilitySettings:_legibilitySettings];
	[_iconView setTintColor:arg1];
	
}
-(UIColor *)textColor{
	return _textColor;
}
-(void)setDate:(NSDate *)arg1 {
	_date = arg1;
	[self _updateLabels];
}
-(void)setLegibilitySettings:(_UILegibilitySettings *)arg1 {
	[self _updateDisplayedWeather];
	if(!arg1)
		return;
	_legibilitySettings.primaryColor = arg1.primaryColor;
	_legibilitySettings.secondaryColor = arg1.secondaryColor;
	[_timeLabel updateForChangedSettings:arg1];
	[_tempLabel updateForChangedSettings:arg1];
	[_forecastOne updateForChangedSettings:arg1];
	[_forecastTwo updateForChangedSettings:arg1];
	[_forecastThree updateForChangedSettings:arg1];
	[_degree updateForChangedSettings:arg1];
	
	[_iconView setTintColor:_tempLabel.drawingColor];
}
-(_UILegibilitySettings *)legibilitySettings{
	return _legibilitySettings;
}
-(void)_updateLabels{
	HBLogDebug(@"[Cirrus] LSForecastView: updating labels");
	[self _updateDisplayedWeather];
	_dateFormatter.timeStyle = NSDateFormatterShortStyle;
	_dateFormatter.dateStyle = NSDateFormatterNoStyle;
	_timeLabel.string = [_dateFormatter stringFromDate:_date];
       [_dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"EdMMM"
                                                                     options:0
                                                                      locale:[NSLocale currentLocale]]];

	_dateLabel.text = [_dateFormatter stringFromDate:_date];

}
-(void)_addLabels{}		//The labels are actually added inside the -init method
-(void)layoutSubviews {
	HBLogDebug(@"[Cirrus] LSForecastView: layoutSubviews called");
	[super layoutSubviews];
	[_tempLabel sizeToFit];
	[_maxMinLabel sizeToFit];
	[_timeLabel sizeToFit];
	[_dateLabel sizeToFit];
	[_forecastOne sizeToFit];
	[_forecastTwo sizeToFit];
	[_forecastThree sizeToFit];
	
	_tempLabel.frame = CGRectMake((self.frame.size.width/2) - _tempLabel.frame.size.width, 
								  0,
								  _tempLabel.frame.size.width,
								  _tempLabel.frame.size.height);
							   
	_dateLabel.frame = CGRectMake((self.frame.size.width/2) - _dateLabel.frame.size.width,
				      self.frame.size.height - _dateLabel.frame.size.height,
				      _dateLabel.frame.size.width, 
				      _dateLabel.frame.size.height);

	_timeLabel.frame = CGRectMake((self.frame.size.width/2)-_timeLabel.frame.size.width,
				      self.frame.size.height - _dateLabel.frame.size.height - _timeLabel.frame.size.height,
				      _timeLabel.frame.size.width+10, 		//add 10 to prevent last digit from being hidden
				      _timeLabel.frame.size.height);

	_maxMinLabel.frame = CGRectMake((self.frame.size.width/2) - _maxMinLabel.frame.size.width,
					_timeLabel.frame.origin.y - _maxMinLabel.frame.size.height,
					_maxMinLabel.frame.size.width,
					_maxMinLabel.frame.size.height);
	
	_iconView.frame = CGRectMake((self.frame.size.width/2),
				     _tempLabel.frame.origin.y,
				     _iconView.frame.size.width,
				     _iconView.frame.size.height);

	_forecastOne.center = CGPointMake(_iconView.frame.origin.x + _iconView.frame.size.width/2,
					  self.frame.size.height-_forecastThree.frame.size.height*5/2);
	_forecastTwo.center = CGPointMake(_iconView.frame.origin.x + _iconView.frame.size.width/2,
					  self.frame.size.height-_forecastThree.frame.size.height*3/2);
	_forecastThree.center = CGPointMake(_iconView.frame.origin.x + _iconView.frame.size.width/2,
			    		    self.frame.size.height-_forecastThree.frame.size.height*1/2);
}
-(void)_useLegibilityLabels:(BOOL)arg1 {
	_useLegibilityLabels = arg1;
}
-(void)updateFormat{}
-(id)_dateText{
	return _dateLabel.text;
}
-(void)_updateLegibilityLabelsWithUpdatedDateString:(BOOL)arg1 {}
-(id)_dateColor{
	return _tempLabel.tintColor;
}
-(void)_setDateAlpha:(double)arg1 {
	_tempLabel.alpha = arg1;
	_timeLabel.alpha = arg1;
	_forecastOne.alpha = arg1;
	_forecastTwo.alpha = arg1;
	_forecastThree.alpha = arg1;
}
-(id)_timeFont{
	return _timeLabel.font;
}
-(id)_dateFont{
	return _dateLabel.font;
}
-(void)_updateLabelAlpha{}
-(double)_effectiveDateAlpha{
	return _dateAlpha;
}
-(double)dateAlphaPercentage{
	return self.dateAlphaPercentage;
}
-(void)_layoutTimeLabel{}			//Not used by my class
-(void)_layoutDateLabel{}			//Not used by my class
-(void)setDateStrength:(double)arg1 {
	_dateStrength = arg1;
}
-(void)setTimeStrength:(double)arg1 {
	_timeStrength = arg1;
}
-(void)setDateAlphaPercentage:(double)arg1 {	//Called when the control center slides up
	_dateLabel.alpha = arg1;
	_tempLabel.alpha = arg1;
	_forecastOne.alpha = arg1;
	_forecastTwo.alpha = arg1;
	_forecastThree.alpha = arg1;
	_timeLabel.alpha = arg1;
	_maxMinLabel.alpha = arg1;
	_iconView.alpha = arg1;
	_dateAlphaPercentage = arg1;
}
-(BOOL)isDateHidden{
	return self.dateHidden;
}
-(void)setDateHidden:(BOOL)arg1 {	//This is called when iOS wants to show a message below the time view,
	HBLogDebug(@"[Cirrus] LSForecastView: will now %@ date", (arg1 ? @"hide" : @"show"));
	_dateLabel.hidden = arg1;	//e.g. the batery percentage when the device is plugged in
	_timeLabel.hidden = arg1;
	_forecastOne.hidden = arg1;
	_forecastTwo.hidden = arg1;
	_forecastThree.hidden = arg1;
	_maxMinLabel.hidden = arg1;
}
-(void)setContentAlpha:(double)arg1 withDateVisible:(BOOL)arg2 {
	[self setDateHidden: !arg2];
	[self setDateAlphaPercentage: arg1];
}
-(void)setCustomSubtitleText:(id)arg1 withColor:(id)arg2 {
}
-(double)timeBaselineOffsetFromOrigin{			//No clue what this is for
	return 0; 
}
-(double)dateBaselineOffsetFromOrigin{
	return _tempLabel.frame.origin.y + _tempLabel.frame.size.height + 15;
}
-(double)timeStrength {
	return _timeStrength;
}
-(double)dateStrength {
	return _dateStrength;
}

-(void)_updateDisplayedWeather {
	[self _forceWeatherUpdate];
	HBLogDebug(@"[Cirrus] LSForecastView: updating displayed weather");
//TODO: check whether this is necessary, as my iPhone crashed in the middle of the night while in airplane mode
//	Crash log @/home/dbdexter/iOS/crashLogs
//	if(![[%c(WeatherPreferences sharedPreferences)] localWeatherCity])
//		return;

	BOOL isNight = ![[[%c(WeatherPreferences) sharedPreferences] localWeatherCity] isDay];
	BOOL isCelsius = [[%c(WeatherPreferences) sharedPreferences] isCelsius];

	NSBundle *bundle = [NSBundle bundleWithPath:BUNDLE];
	NSString *imageName = idToFname([[[%c(WeatherPreferences) sharedPreferences] localWeatherCity] conditionCode], isNight);
	NSString *iconPath = [bundle pathForResource:imageName ofType:@"png"];	//Load image named based on the current weather info
	[_iconView setImage:[UIImage imageNamed:iconPath]];
	_iconView.image = [_iconView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	NSMutableArray *hourlyForecasts  = [[[%c(WeatherPreferences) sharedPreferences] localWeatherCity] hourlyForecasts];
	NSMutableArray *dayForecasts  = [[[%c(WeatherPreferences) sharedPreferences] localWeatherCity] dayForecasts];
	
	NSString* currentCelsius = [[[%c(WeatherPreferences) sharedPreferences] localWeatherCity] temperature];

	NSInteger currentTemp = isCelsius ? [currentCelsius intValue] : ([currentCelsius intValue] * 1.8 + 32);
	NSInteger maxTemp = isCelsius ? [((DayForecast*)dayForecasts[0]).high intValue] : ([((DayForecast*)dayForecasts[0]).high intValue] * 1.8 + 32);
	NSInteger minTemp = isCelsius ? [((DayForecast*)dayForecasts[0]).low intValue] : ([((DayForecast*)dayForecasts[0]).low intValue] * 1.8 + 32);
	NSInteger oneTemp = isCelsius ? [((HourlyForecast*)hourlyForecasts[0]).detail intValue] : ([((HourlyForecast*)hourlyForecasts[0]).detail intValue] * 1.8 + 32);
	NSInteger twoTemp = isCelsius ? [((HourlyForecast*)hourlyForecasts[1]).detail intValue] : ([((HourlyForecast*)hourlyForecasts[1]).detail intValue] * 1.8 + 32);
	NSInteger threeTemp = isCelsius ? [((HourlyForecast*)hourlyForecasts[2]).detail intValue] : ([((HourlyForecast*)hourlyForecasts[2]).detail intValue] * 1.8 + 32);


	_tempLabel.string = [NSString stringWithFormat:@"%ld", (long)currentTemp];

	_maxMinLabel.text = [NSString stringWithFormat:@"%ld°\t%ld°", (long)maxTemp, (long)minTemp];
	
	NSDateFormatter *viewDateFormatter = [[NSDateFormatter alloc] init];
	NSDateFormatter *forecastDateFormatter = [[NSDateFormatter alloc] init];

	viewDateFormatter.dateFormat=@"ha";	
	[forecastDateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
	forecastDateFormatter.dateFormat=@"HH:mm";

	NSString *forecastOneTime = [viewDateFormatter stringFromDate:[forecastDateFormatter dateFromString:((HourlyForecast*)hourlyForecasts[0]).time]];
	NSString *forecastTwoTime = [viewDateFormatter stringFromDate:[forecastDateFormatter dateFromString:((HourlyForecast*)hourlyForecasts[1]).time]];
	NSString *forecastThreeTime = [viewDateFormatter stringFromDate:[forecastDateFormatter dateFromString:((HourlyForecast*)hourlyForecasts[2]).time]];

	_forecastOne.string = [NSString stringWithFormat:@"%@: %ld°", forecastOneTime, (long)oneTemp];
	_forecastTwo.string = [NSString stringWithFormat:@"%@: %ld°", forecastTwoTime, (long)twoTemp];
	_forecastThree.string = [NSString stringWithFormat:@"%@: %ld°", forecastThreeTime, (long)threeTemp];

	[viewDateFormatter release];
	[forecastDateFormatter release];
	[self layoutSubviews];
}

-(void)_forceWeatherUpdate {
	HBLogDebug(@"[Cirrus] LSForecastView: updating current weather info");
	City *localCity = [[%c(WeatherPreferences) sharedPreferences] localWeatherCity];
	WeatherLocationManager *weatherLocationManager = [%c(WeatherLocationManager) sharedWeatherLocationManager];

	CLLocationManager *locationManager = [[CLLocationManager alloc]init];
	[weatherLocationManager setDelegate:locationManager];

	if(![weatherLocationManager locationTrackingIsReady]) {
		[weatherLocationManager setLocationTrackingReady:YES activelyTracking:NO watchKitExtension:nil];
	}

	[[%c(WeatherPreferences) sharedPreferences] setLocalWeatherEnabled:YES];
	[weatherLocationManager setLocationTrackingActive:YES];

	[[%c(TWCLocationUpdater) sharedLocationUpdater] updateWeatherForLocation:[weatherLocationManager location] city:localCity];

	[weatherLocationManager setLocationTrackingActive:NO];
	[locationManager release];
}
@end
