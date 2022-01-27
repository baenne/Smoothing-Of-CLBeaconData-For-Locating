//
//  BeaconId.swift
//  TSMI-Testumgebung
//
//  Created by Benedikt Jensch on 07.01.22.
//

import Foundation
import SwiftUI

struct BeaconId: Hashable {
	let uuid: UUID
	let major: Int
	let minor: Int
}
