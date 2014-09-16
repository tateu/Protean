#import "PRStatusApps.h"
#import "Protean.h"
#import <flipswitch/Flipswitch.h>

NSArray *enabledFlipswitches()
{
    NSMutableArray *fs = [NSMutableArray array];
    for (id key in [Protean getOrLoadSettings][@"flipswitches"])
    {
        id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][key];
        BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
        if (enabled)
            [fs addObject:key];
    }
    return fs;
}

%group SpringBoard
%hook FSSwitchMainPanel
- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    FSSwitchState ret = %orig;
    CHECK_ENABLED(ret);

    id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][switchIdentifier];
    BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
    id alwaysShow_ = [Protean getOrLoadSettings][@"alwaysShowFlipswitches"][switchIdentifier];
    BOOL alwaysShow = alwaysShow_ ? [alwaysShow_ boolValue] : NO;
    id showWhenOff_ = [Protean getOrLoadSettings][@"showWhenOffFlipswitches"][switchIdentifier];
    BOOL showWhenOff = showWhenOff_ ? [showWhenOff_ boolValue] : NO;

    if (enabled && ((ret == FSSwitchStateOn && showWhenOff == NO) || alwaysShow || (ret == FSSwitchStateOff && showWhenOff)))
    {
        [PRStatusApps showIconForFlipswitch:switchIdentifier];
    }
    else
        [PRStatusApps hideIconFor:switchIdentifier];

    return ret;
}

- (void)setState:(FSSwitchState)state forSwitchIdentifier:(NSString *)switchIdentifier
{
    CHECK_ENABLED();

    id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][switchIdentifier];
    BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
    id alwaysShow_ = [Protean getOrLoadSettings][@"alwaysShowFlipswitches"][switchIdentifier];
    BOOL alwaysShow = alwaysShow_ ? [alwaysShow_ boolValue] : NO;
    id showWhenOff_ = [Protean getOrLoadSettings][@"showWhenOffFlipswitches"][switchIdentifier];
    BOOL showWhenOff = showWhenOff_ ? [showWhenOff_ boolValue] : NO;

    if (enabled && ((state == FSSwitchStateOn && showWhenOff == NO) || alwaysShow || (state == FSSwitchStateOff && showWhenOff)))
    {
        [PRStatusApps showIconForFlipswitch:switchIdentifier];
    }
    else
        [PRStatusApps hideIconFor:switchIdentifier];

    %orig;
}
%end
%end

@interface PRFSTimer : NSObject
@end
NSTimer *timer = nil;
@implementation PRFSTimer
-(void) timerTick
{
    for (id key in enabledFlipswitches())
    {
        [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:key];
    }
}

+(void) updateTimer
{
    if ([enabledFlipswitches() count] > 0)
    {
        if (!timer)
        {
            timer = [NSTimer scheduledTimerWithTimeInterval:5
                target:[[[PRFSTimer alloc] init] retain]
                selector:@selector(timerTick)
                userInfo:nil
                repeats:YES];
        }
    }
    else
    {
        if (timer)
        {
            [timer invalidate];
            //[timer release];
            timer = nil;
        }
    }
}
@end

%ctor
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"])
    {
        %init(SpringBoard);
        
        for (id key in enabledFlipswitches())
        {
            [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:key];
        }
        
        [PRFSTimer updateTimer];
    }
}