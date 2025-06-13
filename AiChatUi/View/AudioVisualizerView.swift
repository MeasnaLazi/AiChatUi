//
//  AudioVisualizerView.swift
//  AiChatUi
//
//  Created by Measna on 6/6/25.
//
import SwiftUI

struct AudioVisualizerView: View {
    @Binding var audioLevel: CGFloat

    var body: some View {
        VStack(spacing: 30) {
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                circularVisualizerBars(for: timeline.date)
            }
            .frame(width: 300, height: 300)
        }
    }

    private func circularVisualizerBars(for date: Date) -> some View {
        let numberOfBars = 60
        let radius: CGFloat = 100

        return ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)

            ForEach(0..<numberOfBars, id: \.self) { index in
                let barLength = calculateBarLength(
                    for: index,
                    numberOfBars: numberOfBars,
                    audioLevel: audioLevel,
                    date: date
                )

                let angle = (2 * .pi / Double(numberOfBars)) * Double(index)
                let positionRadius = radius + barLength / 2
                let xPos = positionRadius * cos(angle)
                let yPos = positionRadius * sin(angle)

                RoundedRectangle(cornerRadius: 3)
                    .frame(width: 4, height: barLength)
                    .rotationEffect(.radians(angle + .pi / 2))
                    .offset(x: xPos, y: yPos)
                    .foregroundStyle(.gray.gradient)
                    .animation(.interactiveSpring(response: 0.05, dampingFraction: 0.6), value: barLength)
            }
        }
    }

    private func calculateBarLength(for index: Int, numberOfBars: Int, audioLevel: CGFloat, date: Date) -> CGFloat {
        let phase = date.timeIntervalSince1970
        let animatedLength: CGFloat = 50
        let idleSineWavePosition = sin( (Double(index) / Double(numberOfBars) * .pi) + phase)
        let idleAmplitude: CGFloat = 5
        let baseHeight: CGFloat = 20 + audioLevel * animatedLength
    
        return baseHeight + idleSineWavePosition * idleAmplitude
    }
}
