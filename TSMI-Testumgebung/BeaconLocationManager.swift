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
	@Published var orderedByBeaconBeaconData = [BeaconId: [CLBeacon]]()
	@Published var smoothedBeaconData = [BeaconId: [CLBeacon]]()
	@Published var reducedAndSmoothedBeaconData = [CLBeacon]()
	@Published var finalSmoothedBeaconData : [CLBeacon]? = [CLBeacon]()
	
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
		cancellable2 = _orderedByBeaconBeaconData.projectedValue.sink(receiveValue: { orderedByBeaconBeaconData in
			self.smoothBeaconDataForAllAvailableBeacons(from: orderedByBeaconBeaconData)
		})
		cancellable3 = _smoothedBeaconData.projectedValue.sink(receiveValue: { smoothedBeaconData in
			self.reduceSmoothedBeaconData(smoothedBeaconData: smoothedBeaconData)
		})
		cancellable4 = _reducedAndSmoothedBeaconData.projectedValue.sink(receiveValue: { reducedAndSmoothedBeaconData in
			self.sortSmoothedAndReducedBeaconData(reducedAndSmoothedBeaconData: reducedAndSmoothedBeaconData)
		})
		
		startSearching()
	}
	
	func orderBeaconDataByBeaconForAllAvailableBeacons(beacons: [CLBeacon]) -> Void {
		// Creates a dictonary with a custom struct which uses the uuid, major and minor of the specific beacon as the keys and/or adds the ranged data into the values array with the matching key
		beacons.forEach {
			beacon in
			let beaconKey = BeaconId(uuid: beacon.uuid, major: Int(beacon.major), minor: Int(beacon.minor))
			if orderedByBeaconBeaconData[beaconKey] != nil {
				if orderedByBeaconBeaconData[beaconKey]!.count >= 10 {
					orderedByBeaconBeaconData[beaconKey]!.remove(at: 0)
					orderedByBeaconBeaconData[beaconKey]!.append(beacon)
				} else {
					orderedByBeaconBeaconData[beaconKey]?.append(beacon)
				}
			} else {
				orderedByBeaconBeaconData.updateValue([beacon], forKey: beaconKey)
			}
		}
	}
	
	func smoothBeaconDataForAllAvailableBeacons(from dict: [BeaconId:[CLBeacon]]) {
		// Save resulting array with newest BeaconData for each available beacon to smoothedBeaconData-Publisher
		smoothedBeaconData = dict.filter{
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
	
	func reduceSmoothedBeaconData(smoothedBeaconData: [BeaconId: [CLBeacon]]) {
		reducedAndSmoothedBeaconData = smoothedBeaconData.compactMap{
			// Create new array with all nil values removed and only the newest entry of each Beacon
			   $0.value.last(where: { $0.proximity != .unknown})
		   }
	}
	
	func sortSmoothedAndReducedBeaconData(reducedAndSmoothedBeaconData: [CLBeacon]) {
		// Checks if smoothed data array is empty. If yes returns nil. Otherwise returns the array
		if reducedAndSmoothedBeaconData.isEmpty {
			finalSmoothedBeaconData = nil
		} else {
			finalSmoothedBeaconData = reducedAndSmoothedBeaconData.sorted{
				// Sorts the resulting CLBeacon array in order of closest proximity and after that closest accuracy
				($0.proximity.rawValue,$0.accuracy) <
					($1.proximity.rawValue, $1.accuracy)
			}
		}
	}
	
	func getFinalData() -> [CLBeacon]?{
		return finalSmoothedBeaconData
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
