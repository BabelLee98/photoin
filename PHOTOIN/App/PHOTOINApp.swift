//
//  PHOTOINApp.swift
//  PHOTOIN
//
//  Created by LiMenglu on 2026/4/6.
//

import SwiftUI

@main
struct PHOTOINApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootTabView(dependencies: dependencies)
        }
    }
}
