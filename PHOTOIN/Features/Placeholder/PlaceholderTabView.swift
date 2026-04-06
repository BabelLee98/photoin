//
//  PlaceholderTabView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import SwiftUI

struct PlaceholderTabView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.94),
                    Color(red: 0.9, green: 0.91, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Color(red: 0.34, green: 0.38, blue: 0.4))

                Text("第二个 tab 先预留")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.23, blue: 0.25))

                Text("等你想清楚它是行程、灵感，还是照片时间线后，我们再把信息架构补完整。")
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))
                    .padding(.horizontal, 28)
            }
        }
        .navigationTitle("预留")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlaceholderTabView()
    }
}
