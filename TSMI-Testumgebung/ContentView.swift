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
	@ObservedObject var location: BeaconLocationManager = BeaconLocationManager()
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
		Text("\(String(describing:location.beaconData))")
		// Last 10 rangings sorted by beacon
		Text("\(String(describing:location.savedBeacons))")
		//Smoothed beacon data
		Text("\(String(describing:location.smoothedBeaconData))")
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
