
import { NativeModules, Platform } from 'react-native'

const { AppleAdsAttribution: RNAppleAdsAttribution } = NativeModules;

class AppleAdsAttribution {
  getAttributionData() {
    if (Platform.OS !== 'ios') {
      return null
    }
    return RNAppleAdsAttribution.getAttributionData();
  }

  getiAdAttributionData() {
    if (Platform.OS !== 'ios') {
      return null
    }
    return RNAppleAdsAttribution.getiAdAttributionData();
  }

  getAdServicesAttributionToken() {
    if (Platform.OS !== 'ios') {
      return null
    }
    return RNAppleAdsAttribution.getAdServicesAttributionToken();
  }

  getAdServicesAttributionData() {
    if (Platform.OS !== 'ios') {
      return null
    }
    return RNAppleAdsAttribution.getAdServicesAttributionData();
  }
}

const AppleAdsAttributionInstance = new AppleAdsAttribution();

export default AppleAdsAttributionInstance;
