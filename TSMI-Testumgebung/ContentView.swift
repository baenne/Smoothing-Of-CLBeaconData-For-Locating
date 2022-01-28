//
//  ContentView.swift
//  TSMI-Testumgebung
//
//  Created by Benedikt Jensch on 07.01.22.
//

import SwiftUI

struct ContentView: View {
	@State private var showBeaconView: Bool = false
    var body: some View {
		VStack {
			if showBeaconView {
				BeaconView(showBeaconView: $showBeaconView)
			} else {
				StartView(showBeaconView: $showBeaconView)
			}
			
		}
    }
}

// View which starts the ranging and displays the raw/sorted/smoothed data
struct BeaconView: View {
	@ObservedObject var beaconManager: BeaconLocationManager = BeaconLocationManager(uuidForRanging: UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!)
	@Binding var showBeaconView: Bool
	var body: some View {
		HStack {
			Spacer()
			Button("Stop", action: {
				showBeaconView = false
			})
			Spacer()
		}
		// Raw data
		Text("\(String(describing:beaconManager.beaconData))")
		// Last 10 rangings sorted by beacon as a dict
		Text("\(String(describing:beaconManager.orderedByBeaconData))")
		//Smoothed beacon data as a dict
		Text("\(String(describing:beaconManager.smoothedData))")
		//reduced Array with single beacons
		Text("\(String(describing:beaconManager.reducedAndSmoothedData))")
		//Final data sorted by proximity and accuracy
		Text("\(String(describing:beaconManager.finalSmoothedData))")
	}
}

// View which has a button to start the ranging
struct StartView: View {
	@Binding var showBeaconView: Bool
	var body: some View {
		Spacer()
		HStack {
			Spacer()
			Button("Start", action: {
				showBeaconView = true
			})
			Spacer()
		}
		Spacer()
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
