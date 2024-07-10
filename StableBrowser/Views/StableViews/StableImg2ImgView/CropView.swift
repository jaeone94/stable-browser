import SwiftUI
struct CropView: View {
    @Binding var cropRect: CGRect
    @Binding var isCropMode: Bool
    @Binding var baseImage: UIImage
    @Binding var maskImage: UIImage?

    @Binding var scale: CGFloat
    
    @State private var topLeft: CGPoint = .zero
    @State private var topRight: CGPoint = .zero
    @State private var bottomLeft: CGPoint = .zero
    @State private var bottomRight: CGPoint = .zero

    @State private var isCutButtonClicked: Bool = false
    
    @State private var lastLocation: CGPoint = .zero
    @State private var circleSize: CGFloat = 30

    init(cropRect: Binding<CGRect>, isCropMode: Binding<Bool>, baseImage: Binding<UIImage>, maskImage: Binding<UIImage?>, scale: Binding<CGFloat>) {
        self._cropRect = cropRect
        self._isCropMode = isCropMode
        self._baseImage = baseImage
        self._maskImage = maskImage
        self._scale = scale    
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let location = value.location
                                
                                if lastLocation == .zero {
                                    // Set lastLocation to the current touch location at the beginning of the gesture
                                    lastLocation = location
                                }
                                
                                let offset = CGSize(width: location.x - lastLocation.x, height: location.y - lastLocation.y)
                                
                                // Update the position of the cropRect
                                topLeft = CGPoint(x: topLeft.x + offset.width, y: topLeft.y + offset.height)
                                topRight = CGPoint(x: topRight.x + offset.width, y: topRight.y + offset.height)
                                bottomLeft = CGPoint(x: bottomLeft.x + offset.width, y: bottomLeft.y + offset.height)
                                bottomRight = CGPoint(x: bottomRight.x + offset.width, y: bottomRight.y + offset.height)
                                
                                // update cropRect
                                calculateCropRect()
                                
                                // update lastLocation
                                lastLocation = location
                            }
                            .onEnded { _ in
                                // Initialize lastLocation to .zero when the gesture ends
                                lastLocation = .zero
                            }
                    )
                
                Group {
                    Circle()
                        .fill(Color.white)
                        .frame(width: circleSize / scale, height: circleSize / scale)
                        .position(topLeft)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newPosition = value.location
                                    topLeft = newPosition
                                    bottomLeft = CGPoint(x: newPosition.x, y: bottomLeft.y)
                                    topRight = CGPoint(x: topRight.x, y: newPosition.y)
                                    calculateCropRect()
                                }
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: circleSize / scale, height: circleSize / scale)
                        .position(topRight)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newPosition = value.location
                                    topRight = newPosition
                                    bottomRight = CGPoint(x: newPosition.x, y: bottomRight.y)
                                    topLeft = CGPoint(x: topLeft.x, y: newPosition.y)
                                    calculateCropRect()
                                }
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: circleSize / scale, height: circleSize / scale)
                        .position(bottomLeft)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newPosition = value.location
                                    bottomLeft = newPosition
                                    topLeft = CGPoint(x: newPosition.x, y: topLeft.y)
                                    bottomRight = CGPoint(x: bottomRight.x, y: newPosition.y)
                                    calculateCropRect()
                                }
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: circleSize / scale, height: circleSize / scale)
                        .position(bottomRight)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newPosition = value.location
                                    bottomRight = newPosition
                                    topRight = CGPoint(x: newPosition.x, y: topRight.y)
                                    bottomLeft = CGPoint(x: bottomLeft.x, y: newPosition.y)
                                    calculateCropRect()
                                }
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {}
        }
        .onAppear {
            setInitialCirclePositions()
            calculateCropRect()
        }
    }
    
    func setInitialCirclePositions() {          
        let defaultValue:CGFloat = 10
        let scale = self.scale
        let adjustValue = defaultValue / scale
        print(cropRect.size)
        print(baseImage.scale)
        print(baseImage.size)
        print(scale)
        topLeft = CGPoint(x: cropRect.minX + adjustValue, y: cropRect.minY + adjustValue)
        topRight = CGPoint(x: cropRect.maxX - adjustValue, y: cropRect.minY + adjustValue)
        bottomLeft = CGPoint(x: cropRect.minX + adjustValue, y: cropRect.maxY - adjustValue)
        bottomRight = CGPoint(x: cropRect.maxX - adjustValue, y: cropRect.maxY - adjustValue)
    }
    
    func calculateCropRect() {
        let minX = min(topLeft.x, bottomLeft.x)
        let maxX = max(topRight.x, bottomRight.x)
        let minY = min(topLeft.y, topRight.y)
        let maxY = max(bottomLeft.y, bottomRight.y)
        
        cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    
}
