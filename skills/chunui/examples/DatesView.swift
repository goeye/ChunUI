/**
 * [INPUT]: 依赖 ProspectStore、MemPostRow、MemPostDetailView、MemPostComposerSheet、MemPostFeedSection、CCDesigin.GlassIconButton
 * [OUTPUT]: 对外提供 DatesView——按 TODAY/YESTERDAY… 分段的往来信息流
 * [POS]: Features/Dating 经历信息流根视图
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

struct DatesView: View {
    @ObservedObject private var store = ProspectStore.shared
    @State private var filterProspectId: String?
    @State private var revealed = false

    private struct FeedSection: Identifiable {
        let id: MemPostFeedSection
        let logs: [MemPost]
        var title: String { id.title }
    }

    private var sortedLogs: [MemPost] {
        store.memPosts
            .filter { filterProspectId == nil || $0.prospectId == filterProspectId }
            .sorted { lhs, rhs in
                switch (lhs.happenedAt, rhs.happenedAt) {
                case (let l?, let r?): return l > r
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return lhs.title < rhs.title
                }
            }
    }

    private var sections: [FeedSection] {
        var buckets: [MemPostFeedSection: [MemPost]] = [:]
        for log in sortedLogs {
            let key = log.happenedAt?.memPostFeedSection ?? .earlier
            buckets[key, default: []].append(log)
        }
        return MemPostFeedSection.allCases
            .compactMap { key in
                guard let logs = buckets[key], !logs.isEmpty else { return nil }
                return FeedSection(id: key, logs: logs)
            }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                if store.memPosts.isEmpty && store.isInitialLoading {
                    feedSkeleton
                }

                ForEach(Array(sections.enumerated()), id: \.element.id) { sectionIndex, section in
                    Text(section.title)
                        .font(.cc.sm)
                        .foregroundStyle(Color.cc.mutedForeground)
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .padding(.horizontal, 20)
                        .padding(.top, sectionIndex == 0 ? 8 : 22)
                        .padding(.bottom, 4)
                        .ccReveal(revealed, index: feedRevealIndex(sectionIndex: sectionIndex, logOffset: -1))

                    ForEach(Array(section.logs.enumerated()), id: \.element.id) { logOffset, log in
                        MemPostRow(
                            log: log,
                            prospect: store.prospect(id: log.prospectId),
                            onOpen: {
                                MainViewModel.shared.pushZoom(
                                    view: MemPostDetailView(logId: log.id),
                                    sourceID: log.id
                                )
                            }
                        )
                        .ccZoomSource(id: log.id)
                        .ccReveal(revealed, index: feedRevealIndex(sectionIndex: sectionIndex, logOffset: logOffset))
                    }

                    if sectionIndex < sections.count - 1 {
                        Rectangle()
                            .fill(Color.cc.border.opacity(0.4))
                            .frame(height: CGFloat.cc.hairline)
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                    }
                }
            }
            .padding(.bottom, 140)
        }
        .refreshable { await store.refresh() }
        .overlay {
            if store.memPosts.isEmpty && !store.isInitialLoading {
                CCEmptyState(
                    kind: .interactions,
                    message: String(localized: "dates.empty.hint", table: "Dating")
                )
            }
        }
        .ccFloatingPageHeader {
            CCPageHeader(
                title: String(localized: "dates.title", table: "Dating"),
                subtitleView: AnyView(securitySubtitle)
            ) {
                HStack(spacing: 10) {
                    filterMenu
                    CCDesigin.GlassIconButton(icon: "plus-default") {
                        MainViewModel.shared.presentZoom(
                            view: MemPostComposerSheet(zoomID: CCZoomID.memPostComposer),
                            sourceID: CCZoomID.memPostComposer
                        )
                    }
                    .ccZoomSource(id: CCZoomID.memPostComposer)
                }
            }
        }
        .onAppear {
            revealed = true
            Task { await store.refresh() }
        }
    }

    /// 分段标题 + 帖子行共用一条递增错峰序列（标题用 logOffset=-1）
    private func feedRevealIndex(sectionIndex: Int, logOffset: Int) -> Int {
        var index = 0
        for i in 0 ..< sectionIndex {
            index += 1 + sections[i].logs.count
        }
        return index + 1 + logOffset
    }

    /// 与对象页同构：icon + 灰阶文字（非键帽）
    private var securitySubtitle: some View {
        HStack(spacing: 5) {
            PikaIcon("lock-close", size: 12, color: .cc.mutedForeground)
            Text(String(localized: "security.tag", table: "Dating"))
                .font(.cc.sm)
                .foregroundStyle(Color.cc.mutedForeground)
                .textCase(.uppercase)
                .tracking(0.6)
        }
    }

    private var filterMenu: some View {
        Menu {
            Menu {
                ForEach(store.prospects) { prospect in
                    Button {
                        filterProspectId = prospect.id
                    } label: {
                        if filterProspectId == prospect.id {
                            Label(prospect.name, systemImage: "checkmark")
                        } else {
                            Text(prospect.name)
                        }
                    }
                }
            } label: {
                Label(String(localized: "filter.only_prospect", table: "Dating"), systemImage: "person")
            }


            if filterProspectId != nil {
                Button(role: .destructive) {
                    filterProspectId = nil
                } label: {
                    Label(String(localized: "filter.clear", table: "Dating"), systemImage: "xmark.circle")
                }
            }
        } label: {
            CCDesigin.GlassIconButtonLabel(icon: "filter-funnel")
                .overlay(alignment: .topTrailing) {
                    if filterProspectId != nil {
                        Circle()
                            .fill(Color.cc.primary)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: 2)
                    }
                }
        }
    }

    private var feedSkeleton: some View {
        CCSkeleton {
            VStack(alignment: .leading, spacing: 0) {
                CCBone(width: 64, height: 10)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                ForEach(0 ..< 3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: -10) {
                                CCBone(width: 36, height: 36, radius: 18)
                                CCBone(width: 36, height: 36, radius: 18)
                            }
                            Spacer()
                            CCBone(width: 28, height: 11)
                        }
                        CCBoneText(lines: 2, lineHeight: 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
        }
    }
}

#Preview("约会·Feed") {
    DatesView()
        .background(Color.cc.background)
}
