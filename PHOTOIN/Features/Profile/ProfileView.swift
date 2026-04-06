//
//  ProfileView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("我的")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.2))

                    Text("以后这里可以集中查看设置、全部照片和所有打卡地点。")
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section("内容") {
                Label("全部照片", systemImage: "photo.on.rectangle.angled")
                Label("打卡地点", systemImage: "mappin.and.ellipse")
                Label("旅行足迹", systemImage: "point.3.connected.trianglepath.dotted")
            }

            Section("设置") {
                Label("通知与提醒", systemImage: "bell.badge")
                Label("隐私与权限", systemImage: "hand.raised")
                Label("导出与备份", systemImage: "externaldrive")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.94, green: 0.95, blue: 0.93))
        .navigationTitle("我的")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
