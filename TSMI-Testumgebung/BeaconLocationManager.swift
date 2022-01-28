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
	let uuidForRanging: UUID
	
	@Published var beaconData = [CLBeacon]()
	@Published var orderedByBeaconData = [BeaconId: [CLBeacon]]()
	@Published var smoothedData = [BeaconId: [CLBeacon]]()
	@Published var reducedAndSmoothedData = [CLBeacon]()
	@Published var finalSmoothedData : [CLBeacon]? = [CLBeacon]()
	
	private var cancellable: AnyCancellable?
	private var cancellable2: AnyCancellable?
	private var cancellable3: AnyCancellable?
	private var cancellable4: AnyCancellable?
	
	init(uuidForRanging: UUID = UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!) {
		self.uuidForRanging = uuidForRanging
		super.init()
		
		locationManager = CLLocationManager()
		locationManager?.delegate = self
		
		cancellable = _beaconData.projectedValue.sink(receiveValue: { beaconData in
			self.orderBeaconDataByBeaconForAllAvailableBeacons(beacons: beaconData)
		})
		cancellable2 = _orderedByBeaconData.projectedValue.sink(receiveValue: { orderedByBeaconData in
			self.smoothBeaconDataForAllAvailableBeacons(from: orderedByBeaconData)
		})
		cancellable3 = _smoothedData.projectedValue.sink(receiveValue: { smoothedData in
			self.reduceSmoothedBeaconData(smoothedData: smoothedData)
		})
		cancellable4 = _reducedAndSmoothedData.projectedValue.sink(receiveValue: { reducedAndSmoothedData in
			self.sortSmoothedAndReducedBeaconData(reducedAndSmoothedData: reducedAndSmoothedData)
		})
		
		startSearching()
	}
	
	func orderBeaconDataByBeaconForAllAvailableBeacons(beacons: [CLBeacon]) -> Void {
		// Creates a dictonary with a custom struct which uses the uuid, major and minor of the specific beacon as the keys and/or adds the ranged data into the values array with the matching key
		beacons.forEach {
			beacon in
			let beaconKey = BeaconId(uuid: beacon.uuid, major: Int(beacon.major), minor: Int(beacon.minor))
			if orderedByBeaconData[beaconKey] != nil {
				if orderedByBeaconData[beaconKey]!.count >= 10 {
					orderedByBeaconData[beaconKey]!.remove(at: 0)
					orderedByBeaconData[beaconKey]!.append(beacon)
				} else {
					orderedByBeaconData[beaconKey]?.append(beacon)
				}
			} else {
				orderedByBeaconData.updateValue([beacon], forKey: beaconKey)
			}
		}
	}
	
	func smoothBeaconDataForAllAvailableBeacons(from dict: [BeaconId:[CLBeacon]]) {
		// Save resulting array with newest BeaconData for each available beacon to smoothedData-Publisher
		smoothedData = dict.filter{
			// Remove all key-value pairs from the dictionary which did not get ranged in the last 10 seconds
			$0.value.last!.timestamp >= Date.now - 10
			
			// Remove all key-value pairs from the dictionary which have less than 7 entries
			&& $0.value.count > 6
			
			// Remove all key-value pairs from the dictionary which have 4 or more .unknown proximities in their value array
			&& $0.value.filter
			   { (beacon:CLBeacon)-> Bool in
				   return beacon.proximity == .unknown}
			   .count < 4
			}
	}
	
	func reduceSmoothedBeaconData(smoothedData: [BeaconId: [CLBeacon]]) {
		reducedAndSmoothedData = smoothedData.compactMap{
			// Create new array with all nil values removed and only the newest entry of each Beacon
			   $0.value.last(where: { $0.proximity != .unknown})
		   }
	}
	
	func sortSmoothedAndReducedBeaconData(reducedAndSmoothedData: [CLBeacon]) {
		// Checks if smoothed data array is empty. If yes returns nil. Otherwise returns the array
		if reducedAndSmoothedData.isEmpty {
			finalSmoothedData = nil
		} else {
			finalSmoothedData = reducedAndSmoothedData.sorted{
				// Sorts the resulting CLBeacon array in order of closest proximity and after that closest accuracy
				($0.proximity.rawValue,$0.accuracy) <
					($1.proximity.rawValue, $1.accuracy)
			}
		}
	}
	
	func getFinalData() -> [CLBeacon]?{
		return finalSmoothedData
	}
	
	func startSearching() {
		// Starts searching for Beacons in the vincinity with the hardcoded uuid.
		let constraint = CLBeaconIdentityConstraint(uuid: uuidForRanging)
		locationManager?.startRangingBeacons(satisfying: constraint)
	}
}

extension BeaconLocationManager {
	func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
		beaconData = beacons
	}
}
