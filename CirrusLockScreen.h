#import <UIKit/_UILegibilitySettings.h>
#import <UIKit/_UILegibilityLabel.h>
#import <UIKit/_UILegibilityView.h>
#import <UIKit/_UILegibilityImageView.h>
#import <coreLocation/CoreLocation.h>

@interface City : NSObject
-(NSMutableArray*)hourlyForecasts;
-(NSMutableArray*)dayForecasts;
-(unsigned long long)conditionCode;
-(NSString *)temperature;
-(unsigned long long)sunriseTime;
-(unsigned long long)sunsetTime;
-(BOOL)isDay;
-(NSDate*) updateTime;
@end

@interface WeatherPreferences : NSObject
+(id)sharedPreferences;
+(id)userDefaultsPersistence;
-(NSDictionary*)userDefaults;
-(City*)localWeatherCity;
-(void)setLocalWeatherEnabled:(BOOL)arg1;
-(City*)cityFromPreferencesDictionary:(id)arg1;
-(BOOL)isCelsius;
@end

@interface WeatherLocationManager : NSObject
+(id)sharedWeatherLocationManager;
-(BOOL)locationTrackingIsReady;
-(void)setLocationTrackingReady:(BOOL)arg1 activelyTracking:(BOOL)arg2 watchKitExtension:(id)arg3;
-(void)setLocationTrackingActive:(BOOL)arg1;
-(CLLocation*)location;
-(void)setDelegate:(id)arg1;
@end

@interface TWCLocationUpdater : NSObject
+(id)sharedLocationUpdater;
-(void)updateWeatherForLocation:(CLLocation*)arg1 city:(City*)arg2;
@end

@interface TWCCityUpdater : NSObject
+(id)sharedCityUpdater;
-(void)updateWeatherForCity:(City*)arg1;
@end

@interface CFWColorInfo : NSObject
@property(nonatomic, retain) UIColor *backgroundColor;
@property(nonatomic, retain) UIColor *primaryColor;
@property(nonatomic, retain) UIColor *secondaryColor;
@property(nonatomic, assign, getter=isBackgroundDark) BOOL backgroundDark;

+ (instancetype)colorInfoWithAnalyzedInfo:(struct AnalyzedInfo)info;

- (instancetype)initWithAnalyzedInfo:(struct AnalyzedInfo)info;
@end

@interface CirrusLSForecastView : UIView {
	NSDate* _nextCheckDate;
	_UILegibilityLabel* _timeLabel;
	_UILegibilityLabel* _tempLabel;
	_UILegibilityLabel* _forecastOne;
	_UILegibilityLabel* _forecastTwo;
	_UILegibilityLabel* _forecastThree;
	_UILegibilityLabel* _degree;
	_UILegibilityLabel* _dateLabel;	
	_UILegibilityLabel* _maxMinLabel;

	UIImageView* _iconView;
	BOOL _useLegibilityLabels;
	double _timeAlpha;
	double _dateAlpha;
	NSString* _customSubtitleText;
	UIColor* _customSubtitleColor;
	NSDate* _date;
	NSDateFormatter* _dateFormatter;
	_UILegibilitySettings* _legibilitySettings;
	double _timeStrength;
	double _dateStrength;
	UIColor* _textColor;
	UIColor* _defaultColor;
	double _dateAlphaPercentage;
}
@property (assign,getter=isDateHidden,nonatomic) BOOL dateHidden; 
@property (nonatomic,retain) NSDate * date;                                           
@property (nonatomic,retain) _UILegibilitySettings * legibilitySettings;              
@property (assign,nonatomic) double timeStrength;                                     
@property (assign,nonatomic) double dateStrength;                                     
@property (nonatomic,retain) UIColor * textColor;                                     
@property (assign,nonatomic) double dateAlphaPercentage;

-(id)initWithFrame:(CGRect)arg1;
-(void)layoutSubviews;
-(NSDate *)date;
-(void)setTextColor:(UIColor *)arg1 ;
-(UIColor *)textColor;
-(void)setDate:(NSDate *)arg1 ;
-(void)setLegibilitySettings:(_UILegibilitySettings *)arg1 ;
-(_UILegibilitySettings *)legibilitySettings;
-(void)_updateLabels;
-(void)_addLabels;
-(void)_useLegibilityLabels:(BOOL)arg1 ;
-(void)updateFormat;
-(id)_dateText;
-(void)_updateLegibilityLabelsWithUpdatedDateString:(BOOL)arg1 ;
-(id)_dateColor;
-(void)_setDateAlpha:(double)arg1 ;
-(id)_timeFont;
-(id)_dateFont;
-(void)_updateLabelAlpha;
-(double)_effectiveDateAlpha;
-(double)dateAlphaPercentage;
-(void)_layoutTimeLabel;
-(void)_layoutDateLabel;
-(void)setDateStrength:(double)arg1 ;
-(void)setTimeStrength:(double)arg1 ;
-(void)setDateAlphaPercentage:(double)arg1 ;
-(BOOL)isDateHidden;
-(void)setDateHidden:(BOOL)arg1 ;
-(void)setContentAlpha:(double)arg1 withDateVisible:(BOOL)arg2 ;
-(void)setCustomSubtitleText:(id)arg1 withColor:(id)arg2 ;
-(double)timeBaselineOffsetFromOrigin;
-(double)dateBaselineOffsetFromOrigin;
-(double)timeStrength;
-(double)dateStrength;
-(void)_updateDisplayedWeather;
-(void)_updateDisplayedWeather_isLocal:(BOOL)arg1;
-(void)_forceWeatherUpdate;
-(void)_forceWeatherUpdate_isLocal:(BOOL)arg1;
@end
