//
//  RandomNoiseShader.swift
//  YUI
//
//  Created by 赵翔宇 on 2025/3/22.
//

import SwiftUI

import SwiftUI
 
extension View {
    func randomNoiseEffect(isAnimate: Bool = true) -> some View {
        modifier(RandomNoiseShader(isAnimate: isAnimate))
    }
}
 
public struct RandomNoiseShader: ViewModifier {
    let isAnimate: Bool
    let startDate = Date()
 
    public func body(content: Content) -> some View {
        if isAnimate {
            TimelineView(.animation) { _ in
                content
                    .colorEffect(
                        CCShaders.randomNoise(
                            .float(startDate.timeIntervalSinceNow)
                        )
                    )
            }
        } else {
            content
                .colorEffect(
                    CCShaders.randomNoise(
                        .float(startDate.timeIntervalSinceNow)
                    )
                )
        }
    }
}


