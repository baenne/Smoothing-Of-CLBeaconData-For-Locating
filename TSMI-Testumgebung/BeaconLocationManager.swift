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
	
	var locationManager: CLLocationManager?
	
	@Published var beaconData = [CLBeacon]()
	@Published var sortedBeaconData = [BeaconId: [CLBeacon]]()
	@Published var smoothedBeaconData = [CLBeacon]()
	
	private var cancellable: AnyCancellable?
	private var cancellable2: AnyCancellable?
	private var cancellable3: AnyCancellable?
	
	override init() {
		
		super.init()
		
		locationManager = CLLocationManager()
		locationManager?.delegate = self
		
		cancellable = _beaconData.projectedValue.sink(receiveValue: { beaconData in
			self.sortBeaconDataForAllAvailableBeacons(beacons: beaconData)
		})
		cancellable2 = _sortedBeaconData.projectedValue.sink(receiveValue: { sortedBeaconData in
			self.smoothBeaconDataForAllAvailableBeacons(from: sortedBeaconData)
		})
		cancellable3 = _smoothedBeaconData.projectedValue.sink(receiveValue: { smoothedBeaconData in
			self.getSmoothedBeaconDataForAllAvailableBeacons(smoothedData: smoothedBeaconData)
		})
		
		startSearching()
	}
	
	func sortBeaconDataForAllAvailableBeacons(beacons: [CLBeacon]) -> Void {
		// Creates a dictonary with a custom struct which uses the uuid, major and minor of the specific beacon as the keys and/or adds the ranged data into the values array with the matching key
		beacons.forEach {
			beacon in
			let beaconKey = BeaconId(uuid: beacon.uuid, major: Int(beacon.major), minor: Int(beacon.minor))
			if sortedBeaconData[beaconKey] != nil {
				if sortedBeaconData[beaconKey]!.count >= 10 {
					sortedBeaconData[beaconKey]!.remove(at: 0)
					sortedBeaconData[beaconKey]!.append(beacon)
				} else {
					sortedBeaconData[beaconKey]?.append(beacon)
				}
			} else {
				sortedBeaconData.updateValue([beacon], forKey: beaconKey)
			}
		}
	}
	
	func smoothBeaconDataForAllAvailableBeacons(from dict: [BeaconId:[CLBeacon]]){
		// Save resulting array with newest BeaconData for each available beacon to smoothedBeaconData-Publisher
		smoothedBeaconData = dict.filter{
			// Remove all key-value pairs from the dictionary which did not get ranged in the last 20 seconds
			$0.value.last!.timestamp >= Date.now - 10
			
			// Remove all key-value pairs from the dictionary which have less than 10 entries
			&& $0.value.count > 6
			
			// Remove all key-value pairs from the dictionary which have 6 or more .unknown proximities in their value array
			&& $0.value.filter
			   { (beacon:CLBeacon)-> Bool in
				   return beacon.proximity == .unknown}
			   .count < 4
			}
			.compactMap{
				// Create new array with all nil values removed and only the newest entry of each Beacon
				$0.value.last(where: { $0.proximity != .unknown})
			}
			.sorted{
				// Sorts the resulting CLBeacon array in order of closest accuracy
				$0.accuracy < $1.accuracy
			}
	}
	
	func getSmoothedBeaconDataForAllAvailableBeacons(smoothedData: [CLBeacon]) -> [CLBeacon]? {
		// Checks if smoothed data array is empty. If yes returns nil. Otherwise returns the array
		if smoothedData.isEmpty {
			return nil
		} else {
			return smoothedData
		}
	}
	
	func startSearching() {
		// Starts searching for Beacons in the vincinity with the hardcoded uuid.
		let uuid = UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")
		let constraint = CLBeaconIdentityConstraint(uuid: uuid!)
		
		locationManager?.startRangingBeacons(satisfying: constraint)
	}
}

extension BeaconLocationManager {
	func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
		beaconData = beacons
	}
}
