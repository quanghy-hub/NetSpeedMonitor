import SwiftUI

struct UsageBarPreview: View {
    let usage: Double
    let color: Color
    var useThresholdColoring: Bool = true
    var suffix: String = ""
    
    var body: some View {
        HStack(spacing: 4) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 10)
                
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            useThresholdColoring ? (
                                usage > 0.9 ? Color.red :
                                usage > 0.75 ? Color.orange :
                                color
                            ) : color
                        )
                        .frame(
                            width: geometry.size.width * min(max(usage, 0), 1),
                            height: 10
                        )
                }
                .frame(height: 10)
            }
            .frame(minWidth: 60)
            
            Text("\(Int(usage * 100))%\(suffix)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .frame(width: suffix.isEmpty ? 30 : 46, alignment: .trailing)
        }
    }
}
