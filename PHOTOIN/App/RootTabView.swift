//
//  RootTabView.swift
//  PHOTOIN
//
//  Created by LiMenglu on 2026/4/6.
//

import SwiftUI

struct RootTabView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(viewModel: dependencies.makeHomeViewModel())
            }
            .tabItem {
                Label("", systemImage: "globe.americas.fill")
            }

            NavigationStack {
                RouteRecordingView(viewModel: dependencies.makeRouteRecordingViewModel())
            }
            .tabItem {
                Label("", systemImage: "figure.hiking")
            }

            NavigationStack {
                ProfileView(viewModel: dependencies.makeProfileViewModel())
            }
            .tabItem {
                Label("", systemImage: "person.crop.circle")
            }
        }
        .tint(Color(red: 0.25, green: 0.32, blue: 0.35))
    }
}

#Preview {
    RootTabView(dependencies: .live())
}
