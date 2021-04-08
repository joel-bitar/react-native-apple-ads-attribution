#import "AppleAdsAttribution.h"
#import <React/RCTLog.h>
#import <AdServices/AdServices.h>
#import <iAd/iAd.h>

@implementation AppleAdsAttribution

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

/**
 * Uses the provided token to request attribution data from apples AdServices API.
 */
+ (void) requestAdServicesAttributionDataUsingToken:(NSString *) token
             completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
API_AVAILABLE(ios(14.3)) {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
  [request setURL:[NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"]];
  [request setHTTPBody:[token dataUsingEncoding:NSUTF8StringEncoding]];
  [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler] resume];
}

/**
 * Tries to generate an attribution token that then can be used for calls to apples AdServices API.
 * Returns nil if token couldn't be generated.
 */
+ (NSString *) getAdServicesAttributionToken {
  if (@available(iOS 14.3, *))
  {
    NSError *error = nil;
    Class AAAttributionClass = NSClassFromString(@"AAAttribution");
    if (AAAttributionClass) {
        NSString *attributionToken = [AAAttributionClass attributionTokenWithError:&error];
        if (!error && attributionToken) {
          return attributionToken;
        } else if (error) {
          NSLog(@"Error getting attributionToken %@", error);
        }
    }
  }
  return nil;
}

/**
 * Generates an attributionToken that it then uses to request attribution data from apples AdServices API.
 * Returns nil in the completionhandler if attribution data couldn't be fetched
 */
+ (void) getAdServicesAttributionDataWithCompletionHandler: (void (^)(NSDictionary * _Nullable data))completionHandler {
  if (@available(iOS 14.3, *))
  {
    NSString* attributionToken = [AppleAdsAttribution getAdServicesAttributionToken];

    if (attributionToken) {
      [AppleAdsAttribution requestAdServicesAttributionDataUsingToken:attributionToken completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (!error && data) {
          NSError* serializationError = nil;
          NSDictionary* attributionDataDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
          
          if (!serializationError && attributionDataDictionary) {
            completionHandler(attributionDataDictionary);
          } else {
            NSLog(@"getAdServicesAttributionDataWithCompletionHandler error serializing data %@", serializationError);
            completionHandler(nil);
          }
        } else {
          NSLog(@"getAdServicesAttributionDataWithCompletionHandler error getting data %@", error);
          completionHandler(nil);
        }
      }];
    } else {
      // No token
      completionHandler(nil);
    }
  } else {
    // Not supported on this device
    completionHandler(nil);
  }
}

/**
 * Gets attribution data from the old iAd API.
 * completionHandler will return nil if attribution data couldn't be retrieved. Reasons for failing may be that the user disabled tracking or that the iOS version is < 10.
 */
+ (void) getiAdAttributionDataWithCompletionHandler: (void (^)(NSDictionary * _Nullable data))completionHandler {
    if ([[ADClient sharedClient] respondsToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
      [[ADClient sharedClient] requestAttributionDetailsWithBlock: ^(NSDictionary *attributionDetails, NSError *error) {
        if (!error) {
          completionHandler(attributionDetails);
        } else {
          NSLog(@"getiAdAttributionDataWithCompletionHandler error getting data %@", error);
          completionHandler(nil);
        }
      }];
    } else {
      // requestAttributionDetailsWithBlock is not available probably < iOS 10
      completionHandler(nil);
    }
}

/**
 * Tries to get attribution data first using the AdServices API. If it fails it fallbacks to the old iAd API. If that fails too the promise is resolved as nil
 */
RCT_EXPORT_METHOD(getAttributionData:
  (RCTPromiseResolveBlock) resolve
      rejecter:
      (RCTPromiseRejectBlock) reject) {
  [AppleAdsAttribution getAdServicesAttributionDataWithCompletionHandler:^(NSDictionary * _Nullable attributionData) {
    if (attributionData) {
      resolve(attributionData);
    } else {
      // Fallback to old iAd client API
      [AppleAdsAttribution getiAdAttributionDataWithCompletionHandler:^(NSDictionary * _Nullable data) {
        resolve(data);
      }];
    }
  }];
}

/**
 * Tries to get attribution data using the old iAd API.
 * Promise is resolved as nil if data couldn't be retrieved.
 */
RCT_EXPORT_METHOD(getiAdAttributionData: (RCTPromiseResolveBlock) resolve rejecter: (RCTPromiseRejectBlock) reject) {
  
      [AppleAdsAttribution getiAdAttributionDataWithCompletionHandler:^(NSDictionary * _Nullable data) {
        resolve(data);
      }];
}

/**
 * Tries to generate an attribution token that then can be used for calls to Apples AdServices API.
 * Promise is resolved as nil if token couldn't be generated.
 */
RCT_EXPORT_METHOD(getAdServicesAttributionToken: (RCTPromiseResolveBlock) resolve rejecter: (RCTPromiseRejectBlock) reject) {
  resolve([AppleAdsAttribution getAdServicesAttributionToken]);
}

/**
 * Tries to get attribution data from apples AdServices API.
 * Promise is resolved as nil if data couldn't be fetched.
 */
RCT_EXPORT_METHOD(getAdServicesAttributionData: (RCTPromiseResolveBlock) resolve rejecter: (RCTPromiseRejectBlock) reject) {
  [AppleAdsAttribution getAdServicesAttributionDataWithCompletionHandler:^(NSDictionary * _Nullable attributionData) {
    if (attributionData) {
      resolve(attributionData);
    } else {
      resolve(nil);
    }
  }];
}

@end
