/**
 * [INPUT]: 依赖 ChunUI 公开 API 全家桶
 * [OUTPUT]: 对外提供 ChunUIGalleryRoot —— 分门别类的组件画廊根视图（示例 App 唯一入口）
 * [POS]: ChunUIDemo 的导航根；每个分区一页，页文件见 GalleryPages*.swift
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import ChunUI
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 画廊根：分区目录
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct ChunUIGalleryRoot: View {
    public init() {
        // 画廊默认 Zinner 同款黑白粉；换品牌色只需改这两行
        var colors = CCColors.default
        ChunUI.configure(colors: colors)
        _ = colors
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("Foundation") {
                    NavigationLink("Theme · 配色 / 字号 / 令牌") { ThemePage() }
                    NavigationLink("Motion · 入场动画范式") { MotionPage() }
                }
                Section("Controls") {
                    NavigationLink("Buttons · 微拟物 / 玻璃族") { ButtonsPage() }
                    NavigationLink("Forms · 表单族") { FormsPage() }
                    NavigationLink("Cards & Tags · 卡片与标签") { CardsPage() }
                }
                Section("Feedback") {
                    NavigationLink("Toast / Alert / Sheet") { FeedbackPage() }
                    NavigationLink("Skeleton & Shimmer · 骨架扫光") { SkeletonPage() }
                }
                Section("Text") {
                    NavigationLink("Typer / Streaming / Markdown") { TextPage() }
                }
                Section("Effects · Metal") {
                    NavigationLink("Aurora / Generating / Sweep") { AIEffectsPage() }
                    NavigationLink("Fractal Floor · 九分形地板") { FractalPage() }
                    NavigationLink("Shader Zoo · 全息/元球/丝绸…") { ShaderZooPage() }
                }
                Section("Ambient") {
                    NavigationLink("Fluid / Orb / Rainbow / Grid") { AmbientPage() }
                }
                Section("Icons") {
                    NavigationLink("PikaIcon · 1225 枚") { IconsPage() }
                }
            }
            .navigationTitle("ChunUI")
        }
        .tint(Color.cc.primary)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 画廊通用排版原子
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct GallerySection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .ccText(font: .cc.smBold, color: .cc.mutedForeground)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.cc.base)
        .background(Color.cc.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GalleryScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(spacing: 12) { content() }
                .padding(.cc.base)
        }
        .background(Color.cc.background)
    }
}
