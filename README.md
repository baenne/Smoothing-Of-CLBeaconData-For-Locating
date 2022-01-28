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


`beaconData`: Sends the raw data after each ranging (roughly every second).


`orderedByBeaconBeaconData`: Sends the beacondata sorted as a dictionary 
with a custom struct(BeaconId(uuid,major,minor)) as the key 
and an array with the last 7 ranged values for this specific beacon.

`smoothedBeaconData`: Sends the smoothed dictionary.
Removed: beacons which last ranged more than 10 seconds ago, beacons with less than 7 value entries 
and beacons which have 4 or more .unknown proximities in their last 7 ranges.

`reducedAndSmoothedBeaconData`: Sends a single array with the newest ranged data from each remaining beacon.

`finalSmoothedBeaconData`: Sends a single array with the closest CLBeacons ordered by proximity and accuracy.

Alternatively you can use the specific function **getFinalData()** to get the values only when you want them to 
which returns the  ordered optional CLBeacon array.If not enough data is available the function returns nil
```
func getFinalData() -> [CLBeacon]? 
```


## End

