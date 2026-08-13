/**
 * [INPUT]: 依赖 ProspectStore、AddProspectSheet、CCAppleCard、CCGeneratingCover、CCNeoButton、CCDesigin.GlassIconButton、CCTiltedMediaStrip、MainViewModel.presentPHPicker/presentFullScreenZoom、CCZoomID.screenshotAnalysis
 * [OUTPUT]: 对外提供 ScreenshotAnalysisCard——选图选人后锚点 zoom 进入全屏分析页（上传/OCR/会话编排全在 ScreenshotAnalysisSession）；选人胶囊短词 Person/对象，Menu「添加」→ AddProspectSheet
 * [POS]: Features/Learn 分析页主卡；点阵空态 + CCTiltedMediaStrip 多图（一次/合计最多 6）+ 选人 + 粉色分析
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

struct ScreenshotAnalysisCard: View {
    @ObservedObject private var store = ProspectStore.shared
    @State private var items: [CCTiltedMediaItem] = []
    @State private var selectedProspectId: String?

    private var selectedProspect: Prospect? {
        selectedProspectId.flatMap { store.prospect(id: $0) }
    }

    private var images: [UIImage] {
        items.compactMap {
            if case .localImage(let image) = $0.payload { return image }
            return nil
        }
    }

    var body: some View {
        Color.clear
            .aspectRatio(0.78, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    card(width: geo.size.width, height: geo.size.height)
                }
            }
    }

    private func card(width: CGFloat, height: CGFloat) -> some View {
        CCAppleCard(radius: 20, shadowLevel: 1) {
            VStack(spacing: 0) {
                mediaStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(8)

                if !items.isEmpty {
                    Text(
                        String(
                            format: String(localized: "analysis.card.count", table: "Learn"),
                            items.count
                        )
                    )
                    .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.top, 2)
                }

                HStack(spacing: 8) {
                    personPickerButton
                    CCNeoButton(
                        String(localized: "analysis.analyze", table: "Learn"),
                        variant: .primary,
                        size: .medium,
                        icon: "sparkle-ai01",
                        fullWidth: true,
                        accent: Color.cc.primary
                    ) {
                        analyze()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
        }
        .frame(width: width, height: height)
        .ccZoomSource(id: CCZoomID.screenshotAnalysis)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 媒体舞台（点阵空态 / 倾斜横滑）
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var mediaStage: some View {
        ZStack {
            CCGeneratingCover(color: Color.cc.mutedForeground)

            if !items.isEmpty {
                CCTiltedMediaStrip(
                    items: items,
                    onDelete: { item in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                            items.removeAll { $0.id == item.id }
                        }
                    },
                    topPadding: 56,
                    bottomPadding: 72,
                    locksHeight: false
                )
            }

            VStack(alignment: .leading, spacing: 3) {
                Spacer()
                Text(String(localized: "analysis.card.title", table: "Learn"))
                    .ccText(font: .cc.title1Bold, color: .cc.foreground)
                    .lineLimit(2)
                Text(
                    items.isEmpty
                        ? String(localized: "analysis.card.hint", table: "Learn")
                        : String(localized: "analysis.card.hint_ready", table: "Learn")
                )
                .ccText(font: .cc.callout, color: .cc.mutedForeground)
                .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .allowsHitTesting(false)

            VStack {
                HStack(spacing: 8) {
                    Spacer()
                    CCDesigin.GlassIconButton(icon: "upload-up", size: .regular) {
                        pickImages()
                    }
                }
                Spacer()
            }
            .padding(12)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 人物选择
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var personPickerButton: some View {
        Menu {
            if store.prospects.isEmpty {
                Text(String(localized: "analysis.select.empty", table: "Learn"))
            } else {
                ForEach(store.prospects) { prospect in
                    Button {
                        AppHelper.shared.mada(.soft)
                        selectedProspectId = prospect.id
                    } label: {
                        if selectedProspectId == prospect.id {
                            Label(prospect.name, systemImage: "checkmark")
                        } else {
                            Text(prospect.name)
                        }
                    }
                }
            }
            Divider()
            Button {
                AppHelper.shared.mada(.soft)
                AppHelper.shared.presentSheet(.form) {
                    AddProspectSheet()
                }
            } label: {
                Label(
                    String(localized: "analysis.select.add", table: "Learn"),
                    systemImage: "person.badge.plus"
                )
            }
        } label: {
            HStack(spacing: 8) {
                PikaIcon("user-love-heart", size: 16, color: .cc.foreground)
                Text(selectedProspect?.name ?? String(localized: "analysis.select_person", table: "Learn"))
                    .font(.cc.calloutBold)
                    .foregroundStyle(Color.cc.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.cc.card)
            .clipShape(Capsule())
            .overlay {
                Capsule().strokeBorder(Color.cc.border.opacity(0.7), lineWidth: CGFloat.cc.hairline)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(CCNeoPressStyle())
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func pickImages() {
        let remaining = max(0, MediaPickLimit.maxPerSession - items.count)
        guard remaining > 0 else { return }
        AppHelper.shared.presentPHPicker(
            selectionLimit: remaining,
            filter: .screenshots
        ) { media in
            let picked = media.compactMap { item -> UIImage? in
                if case .image(let image) = item { return image }
                return nil
            }
            guard !picked.isEmpty else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                items.append(contentsOf: picked.map { CCTiltedMediaItem.localImage($0) })
                if items.count > MediaPickLimit.maxPerSession {
                    items = Array(items.suffix(MediaPickLimit.maxPerSession))
                }
            }
        }
    }

    private func analyze() {
        AppHelper.shared.mada(.soft)
        guard !items.isEmpty else {
            AppHelper.shared.pushNotification(
                type: .info(message: String(localized: "analysis.toast.need_images", table: "Learn"))
            )
            return
        }
        guard let prospect = selectedProspect else {
            AppHelper.shared.pushNotification(
                type: .info(message: String(localized: "analysis.toast.need_person", table: "Learn"))
            )
            return
        }

        let snapshot = images
        MainViewModel.shared.presentFullScreenZoom(
            view: ScreenshotAnalysisView(images: snapshot, prospect: prospect),
            sourceID: CCZoomID.screenshotAnalysis
        )
        items.removeAll()
    }
}
