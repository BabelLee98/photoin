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
                PlaceholderTabView()
            }
            .tabItem {
                Label("预留", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
        }
        .tint(Color(red: 0.25, green: 0.32, blue: 0.35))
    }
}

#Preview {
    RootTabView(dependencies: .live())
}
