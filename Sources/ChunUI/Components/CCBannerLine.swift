//
//  CCBrandLine.swift
//  Chat0IM
//
//  Created by 赵翔宇 on 2024/6/15.
//

import SwiftUI

public struct CCBrandLine: View {
    let text: String
    public init(text: String = CCStrings.current.appName) {
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 4, content: {
            Image("ZinnerLogo")
                .resizable()
                .frame(width: 36, height: 36)
                .background(Color.cc.muted)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.cc.shadow.opacity(0.1), radius: 12, x: 0, y: 0)
            VStack(alignment: .leading, spacing: 4, content: {
                Text(text).ccText(font: .cc.subheadlineBold, color: .cc.foreground)
                Text("Chat with AI, Chat with World").ccText(font: .cc.footnote, color: .cc.mutedForeground)
            })
            Spacer()
            Image("qrCode")
                .resizable()
                .renderingMode(.original)
                .frame(width: 36, height: 36)
        })
    }
}

#Preview {
    CCBrandLine()
}
