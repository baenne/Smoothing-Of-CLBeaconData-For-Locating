# Smoothing of CLBeaconData for Locating of CLBeacons
Welcome to my gitproject. I´m Baenne(Benedikt) and work with Swift for around a year now.

## Introduction
This projects goal was to programm a class which handles incoming beacon data, sorts it, smooths it and then publishes it, so you can subscribe to it.

## Requirements

- iBeacon-certified hardware
- xCode 12 or higher
- CoreLocation
- Combine
- Foundation
- SwiftUI

## How-To

1. Initialise the BeaconLocationManager either in your view or while initializing the app. The ranging starts with initialization of the class.

```
@ObservedObject var beaconManager: BeaconLocationManager = BeaconLocationManager()
```

2. Afterwards you can subscribe to one of the following publishers

```
beaconData: Sends the raw data after each ranging (roughly every second).
```
```
orderedByBeaconBeaconData: Sends the beacondata sorted as a dictionary 
with a custom struct(BeaconId(uuid,major,minor)) as the key 
and an array with the last 7 ranged values for this specific beacon.
```
```
smoothedBeaconData: Sends a single array with the closest CLBeacons 
resulting from the smoothing of the data.
```
```
sortedAndSmoothedBeaconData: Sends a single array with the closest CLBeacons ordered by proximity and accuracy
```

Alternatively you can use the specific function **getSmoothedBeaconDataForAllAvailableBeacons** to get the values only when you want them to which returns the  ordered CLBeacon array.
```
func getSmoothedBeaconDataForAllAvailableBeacons(smoothedData: [CLBeacon]) -> [CLBeacon]? 
```


## End

