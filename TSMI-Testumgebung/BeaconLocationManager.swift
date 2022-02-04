//
//  BeaconLocationManager.swift
//  TSMI-Testumgebung
//
//  Created by Benedikt Jensch on 24.01.22.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

class BeaconLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
	
	var locationManager: CLLocationManager
	var rangingUUID: UUID
	@Published var orderedData: [BeaconId:[CLBeacon]] = [BeaconId:[CLBeacon]]()
	@Published var finalData : [CLBeacon] = [CLBeacon]()
	
	init(locationManager: CLLocationManager = CLLocationManager(), rangingUUID: UUID = UUID(uuidString: "7841bc0f-e03f-4a9d-a0bb-065eb28af7ac")!) {
		self.locationManager = locationManager
		self.rangingUUID = rangingUUID
		super.init()
		
		locationManager.delegate = self
		
		locationManager.requestWhenInUseAuthorization()
		
		_orderedData.projectedValue
			.map(smooth(beaconData:))
			.map(reduceBeaconData(beaconData:))
			.map(sort(beaconData:))
			.assign(to: &$finalData)
		
		startSearching()
	}
	
	func orderBeaconDataByBeaconForAllAvailableBeacons(beacons: [CLBeacon]) -> Void {
		// Creates a dictonary with a custom struct which uses the uuid, major and minor of the specific beacon as the keys and/or adds the ranged data into the values array with the matching key
		var rawData = orderedData
		beacons.forEach {
			beacon in
			let beaconKey = BeaconId(uuid: beacon.uuid, major: beacon.major.intValue, minor: beacon.minor.intValue)
			if rawData[beaconKey] != nil {
				if rawData[beaconKey]!.count >= 10 {
					rawData[beaconKey]!.remove(at: 0)
					rawData[beaconKey]!.append(beacon)
				} else {
					rawData[beaconKey]?.append(beacon)
				}
			} else {
				rawData.updateValue([beacon], forKey: beaconKey)
			}
		}
		orderedData = rawData
	}
	
	func getFinalData() -> [CLBeacon]?{
		return finalData
	}
	
	func startSearching() {
		// Starts searching for Beacons in the vincinity with the hardcoded uuid.
		let constraint = CLBeaconIdentityConstraint(uuid: rangingUUID)
		locationManager.startRangingBeacons(satisfying: constraint)
	}
}

extension BeaconLocationManager {
	func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
		self.orderBeaconDataByBeaconForAllAvailableBeacons(beacons: beacons)
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
	}
}

private func smooth(beaconData: [BeaconId:[CLBeacon]]) -> [BeaconId:[CLBeacon]] {
	// Save resulting array with newest BeaconData for each available beacon to smoothedData-Publisher
	return beaconData.filter{
		// Remove all key-value pairs from the dictionary which did not get ranged in the last 10 seconds
		$0.value.last!.timestamp >= Date() - 10
		
		// Remove all key-value pairs from the dictionary which have less than 7 entries
		&& $0.value.count > 6
		
		// Remove all key-value pairs from the dictionary which have 4 or more .unknown proximities in their value array
		&& $0.value.filter
		   { (beacon:CLBeacon)-> Bool in
			   return beacon.proximity == .unknown}
		   .count < 4
		}
}

private func reduceBeaconData(beaconData: [BeaconId: [CLBeacon]]) -> [CLBeacon]{
	return beaconData.compactMap{
		// Create new array with all nil values removed and only the newest entry of each Beacon
		   $0.value.last(where: { $0.proximity != .unknown})
	   }
}

private func sort(beaconData: [CLBeacon]) -> [CLBeacon]{
	// Checks if smoothed data array is empty. If yes returns nil. Otherwise returns the array
	return beaconData.sorted{
		// Sorts the resulting CLBeacon array in order of closest proximity and after that closest accuracy
		($0.proximity.rawValue,$0.accuracy) <
			($1.proximity.rawValue, $1.accuracy)
	}
}
