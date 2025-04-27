import SwiftUI

struct FlowLayout: Layout {
    var alignment: HorizontalAlignment = .center
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let point = result.points[index]
            subview.place(at: CGPoint(x: point.x + bounds.minX, y: point.y + bounds.minY), proposal: .unspecified)
        }
    }
    
    private struct FlowResult {
        var size: CGSize = .zero
        var points: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, alignment: HorizontalAlignment, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var lineItems: [(CGSize, Int)] = []
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth, !lineItems.isEmpty {
                    // Place current line
                    let xOffset = alignment == .trailing ? maxWidth - currentX + spacing : 0
                    for (itemSize, _) in lineItems {
                        points.append(CGPoint(x: xOffset + currentX - itemSize.width, y: currentY))
                        currentX += itemSize.width + spacing
                    }
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                    lineItems.removeAll()
                }
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                lineItems.append((size, index))
            }
            
            // Place remaining line
            let xOffset = alignment == .trailing ? maxWidth - currentX + spacing : 0
            for (itemSize, _) in lineItems {
                points.append(CGPoint(x: xOffset + currentX - itemSize.width, y: currentY))
                currentX += itemSize.width + spacing
            }
            
            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
} 