//
//  PocketAPI.m
//  PocketSDK
//
//  Created by Steve Streza on 5/29/12.
//  Copyright (c) 2012 Read It Later, Inc.
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this
//  software and associated documentation files (the "Software"), to deal in the Software
//  without restriction, including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "PocketAPI.h"
#import "PocketAPIExtensionSafe.h"
#import "PocketAPI+NSOperation.h"
#import "PocketAPILogin.h"
#import "PocketAPIOperation.h"
#import <dispatch/dispatch.h>
#import <sys/sysctl.h>
#import <CommonCrypto/CommonDigest.h>
#import <LaterKit/LaterKit-Swift.h>

#define POCKET_SDK_VERSION @"1.0.2"
#define PocketGlobalKeychainServiceName @"PocketAPI"

static NSString *kPocketAPICurrentLoginKey = @"PocketAPICurrentLogin";
static NSString *kPocketAPIKeychainKeyUsername = @"pocket-username";
static NSString *kPocketAPIKeychainKeyToken = @"pocket-token";
static NSString *kPocketAPIKeychainKeyTokenDigest = @"pocket-tokenDigest";

#pragma mark Private APIs (please do not call these directly)

@interface PocketAPI  ()

+(NSString *)pkt_hashForConsumerKey:(NSString *)consumerKey accessToken:(NSString *)accessToken;

-(NSString *)pkt_getToken;

-(PocketAPILogin *)pkt_loadCurrentLoginFromDefaults;
-(void)pkt_saveCurrentLoginToDefaults;

-(NSDictionary *)pkt_actionDictionaryWithName:(NSString *)name parameters:(NSDictionary *)params;

@end

@interface PocketAPI (Credentials)

-(void)pkt_setKeychainValue:(id)value forKey:(NSString *)key;
-(id)pkt_getKeychainValueForKey:(NSString *)key;

-(void)pkt_setKeychainValue:(id)value forKey:(NSString *)key serviceName:(NSString *)serviceName;
-(id)pkt_getKeychainValueForKey:(NSString *)key serviceName:(NSString *)serviceName;

-(void)pkt_setKeychainValue:(id)value forKey:(NSString *)key accessGroup:(NSString *)accessGroup;
-(id)pkt_getKeychainValueForKey:(NSString *)key accessGroup:(NSString *)accessGroup;

@end

@interface PocketAPILogin (Private)
-(void)_setRequestToken:(NSString *)requestToken;
-(void)_setReverseAuth:(BOOL)isReverseAuth;
@end

#if NS_BLOCKS_AVAILABLE
@interface PocketAPIBlockDelegate : NSObject <PocketAPIDelegate>{
	PocketAPILoginHandler loginHandler;
	PocketAPISaveHandler saveHandler;
	PocketAPIResponseHandler responseHandler;
}

+(id)delegateWithLoginHandler:(PocketAPILoginHandler)handler;
+(id)delegateWithSaveHandler: (PocketAPISaveHandler )handler;
+(id)delegateWithResponseHandler: (PocketAPIResponseHandler )handler;

@property (nonatomic, copy) PocketAPILoginHandler loginHandler;
@property (nonatomic, copy) PocketAPISaveHandler saveHandler;
@property (nonatomic, copy) PocketAPIResponseHandler responseHandler;
@end
#endif

#pragma mark Implementation

@implementation PocketAPI

@synthesize consumerKey, URLScheme, operationQueue, keychainAccessGroup;

#pragma mark Public API

static PocketAPI *sSharedAPI = nil;

+(PocketAPI *)sharedAPI{
	@synchronized(self)
	{
		if (sSharedAPI == NULL){
			sSharedAPI = [self alloc];
			[sSharedAPI init];
		}
	}
	
	return(sSharedAPI);
}

+(NSString *)pocketAppURLScheme{
	return @"pocket-oauth-v1";
}

+(BOOL)hasPocketAppInstalled{
#if TARGET_OS_IPHONE
    NSURL *pktURLScheme = [NSURL URLWithString:[[self pocketAppURLScheme] stringByAppendingString:@":"]];
	return [[UIApplication pkt_sharedApplication] pkt_canOpenURL:pktURLScheme];
#else
	return NO;
#endif
}

+(NSString *)pkt_hashForConsumerKey:(NSString *)consumerKey accessToken:(NSString *)accessToken{
	NSString *string = [NSString stringWithFormat:@"%@-%@",consumerKey, accessToken];
	NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(stringData.bytes, (unsigned int)(stringData.length), digest);

	NSMutableString *hashString = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH];
	for(int i=0; i < CC_SHA1_DIGEST_LENGTH; i++){
		[hashString appendFormat:@"%02x",digest[i]];
	}
	return hashString;
}

-(id)init{
	if(self = [super init]){
		operationQueue = [[NSOperationQueue alloc] init];
		
		// set the initial API key to the one from the singleton
		if(sSharedAPI != self){
			self.consumerKey = [sSharedAPI consumerKey];
		}

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
														   andSelector:@selector(receivedURL:withReplyEvent:)
														 forEventClass:kInternetEventClass
															andEventID:kAEGetURL];
#endif
		
		// register for lifecycle notifications
#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
	}
	return self;
}

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
- (void) receivedURL: (NSAppleEventDescriptor*)event withReplyEvent: (NSAppleEventDescriptor*)replyEvent
{
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	if(urlString){
		[self handleOpenURL:[NSURL URLWithString:urlString]];
	}
}
#endif

-(void)setConsumerKey:(NSString *)aConsumerKey{
	[aConsumerKey retain];
	[consumerKey release];
	consumerKey = aConsumerKey;
	
	if(!URLScheme && consumerKey && ![NSBundle pkt_isApplicationExtension]){
		[self setURLScheme:[self URLScheme]];
	}
	
	// ensure the access token stored matches the consumer key that generated it
    NSString *existingHash = [User pocketTokenDigest];
    NSString *currentHash = [[self class] pkt_hashForConsumerKey:self.consumerKey accessToken:[self pkt_getToken]];
		
    if(![existingHash isEqualToString:currentHash]){
        NSLog(@"*** ERROR: The access token that exists does not match the consumer key. The user has been logged out.");
        [self logout];
    }
}

-(void)enableKeychainSharingWithKeychainAccessGroup:(NSString *)theKeychainAccessGroup{
    self.keychainAccessGroup = theKeychainAccessGroup;
    
    // copy all the keychain values from the default keychain to the shared keychain group
    [self pkt_copyKeychainValuesToSharingKeychain];
}

-(NSString *)URLScheme{
	if(!URLScheme){
		return [NSString stringWithFormat:@"pocketapp%lu", (unsigned long)[self appID]];
	}else{
		return URLScheme;
	}
}

-(void)setURLScheme:(NSString *)aURLScheme{
	[aURLScheme retain];
	[URLScheme release];
	URLScheme = aURLScheme;
	
#if defined(DEBUG) && DEBUG
	// check to make sure 
	BOOL foundURLScheme = NO;
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSArray *urlSchemeLists = [infoDict objectForKey:@"CFBundleURLTypes"];
	for(NSDictionary *urlSchemeList in urlSchemeLists){
		NSArray *urlSchemes = [urlSchemeList objectForKey:@"CFBundleURLSchemes"];
		if([urlSchemes containsObject:URLScheme]){
			foundURLScheme = YES;
			break;
		}
	}
	
	if(!foundURLScheme){
		NSLog(@"** WARNING: You haven't added a URL scheme for the Pocket SDK. This will prevent login from working. See the SDK readme.");
		NSLog(@"** The URL scheme you need to register is: %@",URLScheme);
	}
#endif
}

- (void) setOperationQueue:(NSOperationQueue *)anOperationQueue {
	if (consumerKey) {
		NSLog(@"ERROR: PocketAPI operationQueue is being set after the consumer key was obtained.\n\tThis is probably a sever error.");
	}
	[operationQueue release];
	operationQueue = [anOperationQueue retain];
}

-(void)applicationDidEnterBackground:(NSNotification *)notification{
	[self pkt_saveCurrentLoginToDefaults];
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[operationQueue waitUntilAllOperationsAreFinished];
    [operationQueue release];
    operationQueue = nil;

    [consumerKey release];
    consumerKey = nil;
    [URLScheme release];
    URLScheme = nil;
    [userAgent release];
    userAgent = nil;
    [keychainAccessGroup release];
    keychainAccessGroup = nil;
	
	[super dealloc];
}

-(BOOL)handleOpenURL:(NSURL *)url{
    if ([NSBundle pkt_isApplicationExtension]) {
        NSLog(@"WARNING: -handleOpenURL: is not available within an extension");
        return NO;
    }
    
	if([[url scheme] isEqualToString:self.URLScheme]){
		NSDictionary *urlQuery = [NSDictionary pkt_dictionaryByParsingURLEncodedFormString:[url query]];

		PocketAPILogin *login = currentLogin;
		if([[url path] isEqualToString:@"/reverse"] && [urlQuery objectForKey:@"code"]){
			BOOL allowReverseLogin = YES;
#if TARGET_OS_IPHONE
			id<PocketAPISupport> appDelegate = (id<PocketAPISupport>)[[UIApplication pkt_sharedApplication] delegate];
#else
			id<PocketAPISupport> appDelegate = (id<PocketAPISupport>)[[NSApplication sharedApplication] delegate];
#endif
			
			if(appDelegate && [appDelegate respondsToSelector:@selector(shouldAllowPocketReverseAuth)]){
				if(![appDelegate shouldAllowPocketReverseAuth]){
					allowReverseLogin = NO;
				}
			}
			
			if(allowReverseLogin){
				NSString *requestToken = [urlQuery objectForKey:@"code"];
				login = [[[PocketAPILogin alloc] initWithAPI:self delegate:nil] autorelease];
				[login _setRequestToken:requestToken];
				[login _setReverseAuth:YES];
			}
		}
		
		if(!login){
			login = [self pkt_loadCurrentLoginFromDefaults];
		}
		
		currentLogin = [login retain];
		
		[currentLogin convertRequestTokenToAccessToken];
		return YES;
	}
	
	return NO;
}

-(NSUInteger)appID{
	NSUInteger appID = NSNotFound;
	if(self.consumerKey){
		NSArray *keyPieces = [self.consumerKey componentsSeparatedByString:@"-"];
		if(keyPieces && keyPieces.count > 0){
			NSString *appIDPiece = [keyPieces objectAtIndex:0];
			if(appIDPiece && appIDPiece.length > 0){
				appID = [appIDPiece integerValue];
			}
		}
	}
	return appID;
}

-(BOOL)isLoggedIn{
	NSString *username = [self username];
	NSString *token    = [self pkt_getToken];
	return (username && token && username.length > 0 && token.length > 0);
}

-(void)loginWithDelegate:(id<PocketAPIDelegate>)delegate{
    if ([NSBundle pkt_isApplicationExtension]) {
        NSLog(@"WARNING: -loginWithDelegate: is not available within an extension");
        return;
    }
    
	[currentLogin autorelease];
	currentLogin = [[PocketAPILogin alloc] initWithAPI:self delegate:delegate];
	[currentLogin fetchRequestToken];
}

-(void)saveURL:(NSURL *)url delegate:(id<PocketAPIDelegate>)delegate{
	[operationQueue addOperation:[self saveOperationWithURL:url delegate:delegate]];
}

-(void)saveURL:(NSURL *)url withTitle:(NSString *)title delegate:(id<PocketAPIDelegate>)delegate{
	[operationQueue addOperation:[self saveOperationWithURL:url title:title delegate:delegate]];
}

-(void)saveURL:(NSURL *)url withTitle:(NSString *)title tweetID:(NSString *)tweetID delegate:(id<PocketAPIDelegate>)delegate{
	[operationQueue addOperation:[self saveOperationWithURL:url title:title tweetID:tweetID delegate:delegate]];
}

-(void)callAPIMethod:(NSString *)APIMethod withHTTPMethod:(PocketAPIHTTPMethod)HTTPMethod arguments:(NSDictionary *)arguments delegate:(id<PocketAPIDelegate>)delegate{
	[operationQueue addOperation:[self methodOperationWithAPIMethod:APIMethod forHTTPMethod:HTTPMethod arguments:arguments delegate:delegate]];
}

-(NSOperation *)saveOperationWithURL:(NSURL *)url title:(NSString *)title tweetID:(NSString *)tweetID delegate:(id<PocketAPIDelegate>)delegate{
	if(!url || !url.absoluteString) return nil;
	
	NSNumber *timestamp = [NSNumber numberWithInteger:(NSInteger)([[NSDate date] timeIntervalSince1970])];
	
	NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
	[arguments setObject:timestamp forKey:@"time"];
	[arguments setObject:url.absoluteString forKey:@"url"];
	
	if(title){
		[arguments setObject:title forKey:@"title"];
	}
	
	if(tweetID && ![tweetID isEqualToString:@""] && ![tweetID isEqualToString:@"0"]){
		[arguments setObject:tweetID forKey:@"ref_id"];
	}
	
	return [self methodOperationWithAPIMethod:@"add"
								forHTTPMethod:PocketAPIHTTPMethodPOST
									arguments:[[arguments copy] autorelease]
									 delegate:delegate];
}

-(NSOperation *)saveOperationWithURL:(NSURL *)url title:(NSString *)title delegate:(id<PocketAPIDelegate>)delegate{
	return [self saveOperationWithURL:url title:title tweetID:nil delegate:delegate];
}

-(NSOperation *)saveOperationWithURL:(NSURL *)url delegate:(id<PocketAPIDelegate>)delegate{
	return [self saveOperationWithURL:url title:nil tweetID:nil delegate:delegate];
}

-(NSOperation *)methodOperationWithAPIMethod:(NSString *)APIMethod forHTTPMethod:(PocketAPIHTTPMethod)HTTPMethod arguments:(NSDictionary *)arguments delegate:(id<PocketAPIDelegate>)delegate{
	PocketAPIOperation *operation = [[[PocketAPIOperation alloc] init] autorelease];
	operation.API = self;
	operation.delegate = delegate;
	operation.APIMethod = APIMethod;
	operation.HTTPMethod = HTTPMethod;
	operation.arguments = [NSDictionary dictionaryWithDictionary:arguments];
	return operation;
}

#if NS_BLOCKS_AVAILABLE

-(void)loginWithHandler:(PocketAPILoginHandler)handler{
    if ([NSBundle pkt_isApplicationExtension]) {
        NSLog(@"WARNING: -loginWithHandler: is not available within an extension");
        return;
    }
	[self loginWithDelegate:[PocketAPIBlockDelegate delegateWithLoginHandler:handler]];
}

-(void)saveURL:(NSURL *)url handler:(PocketAPISaveHandler)handler{
	[self saveURL:url delegate:[PocketAPIBlockDelegate delegateWithSaveHandler:handler]];
}

-(void)saveURL:(NSURL *)url withTitle:(NSString *)title handler:(PocketAPISaveHandler)handler{
	[self saveURL:url withTitle:title delegate:[PocketAPIBlockDelegate delegateWithSaveHandler:handler]];
}

-(void)saveURL:(NSURL *)url withTitle:(NSString *)title tweetID:(NSString *)tweetID handler:(PocketAPISaveHandler)handler{
	[self saveURL:url withTitle:title tweetID:tweetID delegate:[PocketAPIBlockDelegate delegateWithSaveHandler:handler]];
}

-(void)callAPIMethod:(NSString *)APIMethod withHTTPMethod:(PocketAPIHTTPMethod)HTTPMethod arguments:(NSDictionary *)arguments handler:(PocketAPIResponseHandler)handler{
	[self callAPIMethod:APIMethod withHTTPMethod:HTTPMethod arguments:arguments delegate:[PocketAPIBlockDelegate delegateWithResponseHandler:handler]];
}

// operation API

-(NSOperation *)saveOperationWithURL:(NSURL *)url handler:(PocketAPISaveHandler)handler{
	return [self saveOperationWithURL:url delegate:[PocketAPIBlockDelegate delegateWithSaveHandler:handler]];
}

-(NSOperation *)saveOperationWithURL:(NSURL *)url title:(NSString *)title handler:(PocketAPISaveHandler)handler{
	return [self saveOperationWithURL:url title:title delegate:[PocketAPIBlockDelegate delegateWithSaveHandler:handler]];
}

-(NSOperation *)saveOperationWithURL:(NSURL *)url title:(NSString *)title tweetID:(NSString *)tweetID handler:(PocketAPISaveHandler)handler{
	return [self saveOperationWithURL:url title:title tweetID:tweetID delegate:[PocketAPIBlockDelegate delegateWithSaveHandler:handler]];
}

-(NSOperation *)methodOperationWithAPIMethod:(NSString *)APIMethod forHTTPMethod:(PocketAPIHTTPMethod)httpMethod arguments:(NSDictionary *)arguments handler:(PocketAPIResponseHandler)handler{
	return [self methodOperationWithAPIMethod:APIMethod forHTTPMethod:httpMethod arguments:arguments delegate:[PocketAPIBlockDelegate delegateWithResponseHandler:handler]];
}

#endif

#pragma mark Account Info

-(NSString *)username{
    return User.pocketAccountName;
}

-(NSString *)pkt_getToken{
    return [User pocketToken];
}

-(void)pkt_loggedInWithUsername:(NSString *)username token:(NSString *)token{
	[self willChangeValueForKey:@"username"];
	[self willChangeValueForKey:@"isLoggedIn"];
    
    [User setPocketToken:token];
    [User setPocketTokenDigest:[PocketAPI pkt_hashForConsumerKey:self.consumerKey accessToken:token]];
	
	[self  didChangeValueForKey:@"isLoggedIn"];
	[self  didChangeValueForKey:@"username"];
}

-(void)logout{
    
    if ([NSBundle pkt_isApplicationExtension]) {
        NSLog(@"WARNING: -logout is not available within an extension");
        return;
    }
    
	[self willChangeValueForKey:@"username"];
	[self willChangeValueForKey:@"isLoggedIn"];
	
    [User pocketLogout];
    
	[self didChangeValueForKey:@"isLoggedIn"];
	[self didChangeValueForKey:@"username"];
}

-(PocketAPILogin *)pkt_loadCurrentLoginFromDefaults{
	NSUserDefaults *defaults = [[[NSUserDefaults alloc] init] autorelease];
	
	PocketAPILogin *login = nil;
	if(!login){
		NSData *data = [defaults dataForKey:kPocketAPICurrentLoginKey];
		if (data) {
			@try {
				login = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			}
			@catch (NSException *exception) {
				NSLog(@"Encountered an exception reading Pocket login: %@", [exception description]);
			}
		}
	}

	if(login){
		[defaults removeObjectForKey:kPocketAPICurrentLoginKey];
		[defaults synchronize];
	}
	
	return login;
}

-(void)pkt_saveCurrentLoginToDefaults{
	if(currentLogin){
        NSUserDefaults *defaults = [[NSUserDefaults alloc] init];

        if (@available(macOS 10.11, *)) {
            NSData *loginData = [NSKeyedArchiver archivedDataWithRootObject:currentLogin];
            [defaults setObject:loginData forKey:kPocketAPICurrentLoginKey];
        }
        
		[defaults synchronize];
		[defaults release];
	}
}

// NOTE: This API will FAIL for you by default. It is only enabled for certain consumer keys,
// and it will only be available for a short time. If you use it, do NOT store the user's
// password permanently. If you require access to this API, contact us at api@getpocket.com.
//
// Be prepared for this API to return errors at any time, even after you are in production.

-(void)pkt_migrateAccountToAccessTokenWithUsername:(NSString *)username password:(NSString *)password delegate:(id<PocketAPIDelegate>)delegate{
	PocketAPIOperation *operation = [[PocketAPIOperation alloc] init];
	operation.API = self;
	operation.delegate = delegate;
	operation.domain = PocketAPIDomainAuth;
	operation.HTTPMethod = PocketAPIHTTPMethodPOST;
	operation.APIMethod = @"authorize";
	
	NSString *locale = [[NSLocale preferredLanguages] objectAtIndex:0];
	NSString *country = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
	int timeZone = round([[NSTimeZone systemTimeZone] secondsFromGMT] / 60);
	
	operation.arguments = [NSDictionary dictionaryWithObjectsAndKeys:
						   username, @"username",
						   password, @"password",
						   @"credentials", @"grant_type",
						   locale, @"locale",
						   country, @"country",
						   [NSString stringWithFormat:@"%i", timeZone], @"timezone",
						   nil];

	[operationQueue addOperation:operation];
	[operation release];
}

#if NS_BLOCKS_AVAILABLE
-(void)pkt_migrateAccountToAccessTokenWithUsername:(NSString *)username password:(NSString *)password handler:(PocketAPILoginHandler)handler{
	[self pkt_migrateAccountToAccessTokenWithUsername:username password:password delegate:[PocketAPIBlockDelegate delegateWithLoginHandler:handler]];
}
#endif

-(NSDictionary *)pkt_actionDictionaryWithName:(NSString *)name parameters:(NSDictionary *)params{
	if(!name) return nil;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:params];
	[dict setObject:name forKey:@"action"];
	[dict setObject:[NSNumber numberWithInteger:(NSInteger)([[NSDate date] timeIntervalSince1970])] forKey:@"time"];
	
	return dict;
}

-(void)pkt_copyKeychainValuesToSharingKeychain{
    // don't copy anything if it's in the extension or no keychain access group given
    if ([NSBundle pkt_isApplicationExtension]) { return; }

    NSString *username = [self pkt_getKeychainValueForKey:kPocketAPIKeychainKeyUsername];
    NSString *token = [self pkt_getKeychainValueForKey:kPocketAPIKeychainKeyToken];
    NSString *tokenDigest = [self pkt_getKeychainValueForKey:kPocketAPIKeychainKeyTokenDigest];
    
    [self pkt_setKeychainValue:username forKey:kPocketAPIKeychainKeyUsername accessGroup:keychainAccessGroup];
    [self pkt_setKeychainValue:token forKey:kPocketAPIKeychainKeyToken accessGroup:keychainAccessGroup];
    [self pkt_setKeychainValue:tokenDigest forKey:kPocketAPIKeychainKeyTokenDigest accessGroup:keychainAccessGroup];
}

#pragma mark -
#pragma mark User Agent (uses UIDevice+Hardware from https://github.com/erica/uidevice-extension)

-(NSString *)pkt_userAgent{
	if(!userAgent){
		NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
		
		NSString *productName   = @"PocketSDK:" POCKET_SDK_VERSION;
		NSString *appName       = [bundleInfo objectForKey:@"CFBundleDisplayName"];
		if(!appName){
			appName             = [bundleInfo objectForKey:(NSString *)kCFBundleNameKey];
		}
		NSString *appVersion    = [bundleInfo objectForKey:@"CFBundleVersion"];
		NSString *deviceMfg     = @"Apple";
		NSString *storeName     = @"App Store";
		NSString *deviceName    = [self pkt_deviceName];
		NSString *osVersion     = [self pkt_deviceOSVersion];

		NSString *osType        = nil;
		NSString *deviceType    = nil;

#if TARGET_OS_IPHONE
		osType = [[UIDevice currentDevice] systemName];
		deviceType = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"Tablet" : @"Mobile";
#else
		osType = @"OS X";
		deviceType = @"Computer";
		
		NSString *receiptPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Contents/_MASReceipt/receipt"] stringByStandardizingPath];
		if(![[NSFileManager defaultManager] fileExistsAtPath:receiptPath]){
			storeName = @"Vendor";
		}
#endif
		
#define PKTAtLeastEmptyString(__str) ((__str) == nil ? @"" : (__str))
		userAgent = [[[NSArray arrayWithObjects:
					   PKTAtLeastEmptyString(productName),
					   PKTAtLeastEmptyString(appName),
					   PKTAtLeastEmptyString(appVersion),
					   PKTAtLeastEmptyString(osType),
					   PKTAtLeastEmptyString(osVersion),
					   PKTAtLeastEmptyString(deviceMfg),
					   PKTAtLeastEmptyString(deviceName),
					   PKTAtLeastEmptyString(deviceType),
					   PKTAtLeastEmptyString(storeName),
					   nil] componentsJoinedByString:@";"] retain];
#undef PKTAtLeastEmptyString
	}
	return userAgent;
}

-(NSString *)pkt_deviceName{
#if TARGET_OS_IPHONE
	size_t size;
	const char *typeSpecifier = "hw.machine";
	sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
	
	char *answer = malloc(size);
	sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
	
	NSString *platform = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
	free(answer);

	if ([platform isEqualToString:@"iFPGA"])        return @"iFPGA";
	
	// iPhone
	if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
	if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
	if ([platform hasPrefix:@"iPhone2"])            return @"iPhone 3GS";
	if ([platform hasPrefix:@"iPhone3"])            return @"iPhone 4";
	if ([platform hasPrefix:@"iPhone4"])            return @"iPhone 4S";
	
	// iPod
	if ([platform hasPrefix:@"iPod1"])              return @"iPod touch 1G";
	if ([platform hasPrefix:@"iPod2"])              return @"iPod touch 2G";
	if ([platform hasPrefix:@"iPod3"])              return @"iPod touch 3G";
	if ([platform hasPrefix:@"iPod4"])              return @"iPod touch 4G";
	
	// iPad
	if ([platform hasPrefix:@"iPad1"])              return @"iPad 1G";
	if ([platform hasPrefix:@"iPad2"])              return @"iPad 2G";
	if ([platform hasPrefix:@"iPad3"])              return @"iPad 3G";
	
	// Apple TV
	if ([platform hasPrefix:@"AppleTV2"])           return @"Apple TV 2G";
	
	if ([platform hasPrefix:@"iPhone"])             return @"Unknown iPhone";
	if ([platform hasPrefix:@"iPod"])               return @"Unknown iPod touch";
	if ([platform hasPrefix:@"iPad"])               return @"Unknown iPad";
	
	// Simulator thanks Jordan Breeding
	if ([platform hasSuffix:@"86"] || [platform isEqual:@"x86_64"]) return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad Simulator" : @"iPhone Simulator";
	
	return @"Unknown iOS Device";
#else
	NSString *modelIdentifier = @"";
	
	int nameSuccess = 0;
	const int SUCCEEDED = 0;
	
	size_t size = 0;
	nameSuccess = sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	if (nameSuccess != SUCCEEDED || size == 0)
		return modelIdentifier;
	
	char *machine = malloc(size);
	nameSuccess = sysctlbyname("hw.machine", machine, &size, NULL, 0);
	if (nameSuccess == SUCCEEDED) {
		modelIdentifier = [NSString stringWithUTF8String:machine];
	}
	free(machine);
	
	return modelIdentifier;
#endif
}

-(NSString *)pkt_deviceOSVersion{
#if TARGET_OS_IPHONE
	return [[UIDevice currentDevice] systemVersion];
#else
    // Gestalt is deprecated in 10.8 with no sane replacement API. This is the currently recommended solution.
    // via http://stackoverflow.com/questions/11072804/mac-os-x-10-8-replacement-for-gestalt-for-testing-os-version-at-runtime/11072974
    return [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"];
#endif
}

@end


#pragma mark Keychain Credentials

#import <TargetConditionals.h>
#import "PocketAPIKeychainUtils.h"

@implementation PocketAPI (Credentials)

-(void)pkt_setKeychainValue:(id)value forKey:(NSString *)key{
	[self pkt_setKeychainValue:value forKey:key serviceName:PocketGlobalKeychainServiceName];
}

-(void)pkt_setKeychainValue:(id)value forKey:(NSString *)key serviceName:(NSString *)serviceName{
    [self pkt_setKeychainValue:value forKey:key serviceName:serviceName accessGroup:nil];
}

-(void)pkt_setKeychainValue:(id)value forKey:(NSString *)key accessGroup:(NSString *)accessGroup{
    [self pkt_setKeychainValue:value forKey:key serviceName:PocketGlobalKeychainServiceName accessGroup:accessGroup];
}

-(void)pkt_setKeychainValue:(id)value forKey:(NSString *)key serviceName:(NSString *)serviceName accessGroup:(NSString *)accessGroup{
	if (value) {
		[PocketAPIKeychainUtils storeUsername:key andPassword:value forServiceName:serviceName inAccessGroup:accessGroup updateExisting:YES error:nil];
	} else {
		[PocketAPIKeychainUtils deleteItemForUsername:key andServiceName:serviceName inAccessGroup:accessGroup error:nil];
	}
}

-(id)pkt_getKeychainValueForKey:(NSString *)key{
    return [self pkt_getKeychainValueForKey:key serviceName:PocketGlobalKeychainServiceName];
}

-(id)pkt_getKeychainValueForKey:(NSString *)key accessGroup:(NSString *)accessGroup{
    return [self pkt_getKeychainValueForKey:key serviceName:PocketGlobalKeychainServiceName accessGroup:accessGroup];
}

-(id)pkt_getKeychainValueForKey:(NSString *)key serviceName:(NSString *)serviceName{
    return [self pkt_getKeychainValueForKey:key serviceName:serviceName accessGroup:nil];
}

-(id)pkt_getKeychainValueForKey:(NSString *)key serviceName:(NSString *)serviceName accessGroup:(NSString *)accessGroup {
	return [PocketAPIKeychainUtils getPasswordForUsername:key andServiceName:serviceName inAccessGroup:accessGroup error:nil];
}

@end

#if NS_BLOCKS_AVAILABLE
@implementation PocketAPIBlockDelegate

@synthesize loginHandler, saveHandler, responseHandler;

-(void)pocketAPILoggedIn:(PocketAPI *)api{
	if(self.loginHandler){
		self.loginHandler(api, nil);
	}
}

-(void)pocketAPI:(PocketAPI *)api hadLoginError:(NSError *)error{
	if(self.loginHandler){
		self.loginHandler(api, error);
	}
}

-(void)pocketAPI:(PocketAPI *)api savedURL:(NSURL *)url{
	if(self.saveHandler){
		self.saveHandler(api, url, nil);
	}
}

-(void)pocketAPI:(PocketAPI *)api failedToSaveURL:(NSURL *)url error:(NSError *)error{
	if(self.saveHandler){
		self.saveHandler(api, url, error);
	}
}

-(void)pocketAPI:(PocketAPI *)api receivedResponse:(NSDictionary *)response forAPIMethod:(NSString *)APIMethod error:(NSError *)error{
	if(self.responseHandler){
		self.responseHandler(api, APIMethod, response, error);
	}
}

+(id)delegateWithLoginHandler:(PocketAPILoginHandler)handler{
	PocketAPIBlockDelegate *delegate = [[[self alloc] init] autorelease];
	delegate.loginHandler = [[handler copy] autorelease];
	return delegate;
}

+(id)delegateWithSaveHandler: (PocketAPISaveHandler)handler{
	PocketAPIBlockDelegate *delegate = [[[self alloc] init] autorelease];
	delegate.saveHandler = [[handler copy] autorelease];
	return delegate;
}

+(id)delegateWithResponseHandler:(PocketAPIResponseHandler)handler{
	PocketAPIBlockDelegate *delegate = [[[self alloc] init] autorelease];
	delegate.responseHandler = [[handler copy] autorelease];
	return delegate;
}

-(void)dealloc{
    [loginHandler release];
    loginHandler = nil;
    [saveHandler release];
    saveHandler = nil;
    [responseHandler release];
    responseHandler = nil;
	
	[super dealloc];
}

@end
#endif

NSString *PocketAPITweetID(unsigned long long tweetID){
	return [NSString stringWithFormat:@"%llu", tweetID];
}
