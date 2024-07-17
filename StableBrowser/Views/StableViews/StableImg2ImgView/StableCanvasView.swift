import SwiftUI

struct StableCanvasView: View {
    var parent: BaseImageSection
    @State var toolSize: CGFloat = 50
    
    @State var width: CGFloat
    @State var height: CGFloat
    @State var baseImage: UIImage
    @State var maskImage: UIImage?
    @State var drawingView = SimpleDrawingView()

    @Binding var isInpaintMode: Bool

    @State var isDrawingMode: Bool = false
    @State var isZoomPanMode: Bool = true
    @State private var isCropMode = false
    @State private var cropRect: CGRect
    
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var scale: CGFloat = 0.85
    @State private var lastScale: CGFloat = 0.85
    @State private var minimumScale: CGFloat = 0
    
    @Environment(\.presentationMode) var presentationMode
    
    init(parent: BaseImageSection, width: CGFloat, height: CGFloat, baseImage: UIImage, isInpaintMode: Binding<Bool>) {
        self.parent = parent
        self.width = width
        self.height = height
        self.baseImage = baseImage

        let widthScale = UIScreen.main.bounds.width / width * 0.90
        let heightScale = UIScreen.main.bounds.height / height * 0.90
        self.scale = min(widthScale, heightScale)
        self.lastScale = min(widthScale, heightScale)
                    
        self.offset = CGSize.zero
        self.lastOffset = CGSize.zero
        
        self._isInpaintMode = isInpaintMode
        self._cropRect = State(initialValue: CGRect(origin: .zero, size: baseImage.size))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                // Canvas Area
                ZStack {
                    Image(uiImage: baseImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: width, height: height)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .scaleEffect(scale)
                        .offset(offset)
                        .simultaneousGesture(
                            MagnificationGesture(minimumScaleDelta: isZoomPanMode ? 0 : .infinity)
                                .onChanged { value in
                                    if self.minimumScale > self.lastScale * value.magnitude {
                                        self.scale = self.minimumScale
                                    } else {
                                        self.scale = self.lastScale * value.magnitude
                                    }
                                }
                                .onEnded { value in
                                    self.lastScale = self.scale
                                }
                            
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: isZoomPanMode ? 0 : .infinity)
                                .onChanged { value in
                                    self.offset = CGSize(width: self.lastOffset.width + value.translation.width, height: self.lastOffset.height + value.translation.height)
                                }
                                .onEnded { _ in
                                    self.lastOffset = self.offset
                                }
                        )
                    
                    VStack {
                        SimpleDrawingViewRepresentable(toolSize: $toolSize, width: $width, height: $height, image: $maskImage, drawingView: $drawingView, scale: scale)
                            .opacity(0.5)
                            .cornerRadius(10)
                            .frame(width: width, height: height)
                            .padding(10)
                            .scaleEffect(scale)
                            .offset(offset)
                            .allowsHitTesting(isDrawingMode)
 
                    }
                    if isCropMode {
                        VStack {
                            CropView(cropRect: $cropRect, isCropMode: $isCropMode, baseImage: $baseImage, maskImage: $maskImage, scale: $scale)
                                .cornerRadius(10)
                                .frame(width: width, height: height)
                                .padding(10)
                                .scaleEffect(scale)
                                .offset(offset)
                        }
                        
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height - (isZoomPanMode || isDrawingMode || isCropMode ? 140 : 80))
                                
                // Tools Area
                VStack {
                    VStack {
                        if isZoomPanMode {
                            zoomPanResetButton
                        }
                        if isDrawingMode {
                            brushSizeSlider
                        }
                        if isDrawingMode {
                            clearInpaintMaskButton
                        }
                        if isCropMode {
                            cropImageButton
                        }
                    }.padding()
                    .padding(.bottom, 15)
                    .frame(height: (isZoomPanMode || isDrawingMode || isCropMode ? 60 : 0))
                    drawingTools
                        .padding(.bottom)
                        .padding(.top, -10)
                }
                .frame(height: (isZoomPanMode || isDrawingMode || isCropMode ? 140 : 80))
                .padding(.horizontal)
                .padding(.bottom, 50)
                .background(Color(UIColor.secondarySystemBackground)) // This gives a card-like appearance
                .cornerRadius(10)
                .shadow(radius: 5)
                
                
            }
            .navigationBarItems(trailing: applyButton)
        }
    }
    
    var applyButton: some View {
        Button("Apply changes") {
            resetZoomPan()
            getImageFromDrawingView()
        }
    }
    
    var drawingTools: some View {
        HStack {
            if isInpaintMode {
                Button(action: {
                    withAnimation {
                        isDrawingMode.toggle()
                        isZoomPanMode = false
                        isCropMode = false
                    }
                }) {
                    VStack {
                        Image(systemName: "pencil")
                            .font(.title)
                            .foregroundColor(isDrawingMode ? .blue : .gray)
                        Text("Inpainting")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: {
                withAnimation {
                    isZoomPanMode.toggle()
                    isDrawingMode = false
                    isCropMode = false
                }
            }) {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundColor(isZoomPanMode ? .blue : .gray)
                    Text("Zoom/Pan")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                withAnimation {
                    isCropMode.toggle()
                    isDrawingMode = false
                    isZoomPanMode = false
                    
                    if isCropMode {
                        resetCropRect()
//                        resetZoomPan()
                    }
                }
            }) {
                VStack {
                    Image(systemName: "crop")
                        .font(.title)
                        .foregroundColor(isCropMode ? .blue : .gray)
                    Text("Crop")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    
   
    
    var zoomPanResetButton: some View {
        Button("Reset scale and position") {
            resetZoomPan()
        }
    }
    
    var brushSizeSlider: some View {
        HStack {
            Text("Brush size")
            Slider(value: $toolSize, in: 1...100)
            Text("\(Int(toolSize))")
        }
    }
    
    var clearInpaintMaskButton: some View {
        Button("Clear inpaint mask") {
            clearDrawing()
        }
    }
    
    var cropImageButton: some View {
        Button("Crop") {
            withAnimation {
                cropImage()
            }
        }
    }
    

    func clearDrawing() {
        drawingView.clearDrawing()
    }

    func getImageFromDrawingView() {
        let baseImage = self.baseImage
        if let renderedImage = drawingView.getImage(width: width, height: height) {
            parent.baseImage = baseImage
            parent.maskImage = renderedImage
            parent.width = width
            parent.height = height
            presentationMode.wrappedValue.dismiss()
        }
    }
        
    func resetZoomPan() {
        withAnimation{
            let widthScale = UIScreen.main.bounds.width / width * 0.90
            let heightScale = UIScreen.main.bounds.height / height * 0.90
            self.scale = min(widthScale, heightScale)
            self.lastScale = min(widthScale, heightScale)
                        
            self.offset = CGSize.zero
            self.lastOffset = CGSize.zero
        }
    }


    func cropImage() {
        let baseImage = baseImage
        guard let cgImage = baseImage.cgImage else { return }
        
        // Adjust the crop area considering the scale of the UIImage
        let scale = baseImage.scale
        let scaledCropRect = CGRect(x: cropRect.origin.x * scale,
                                    y: cropRect.origin.y * scale,
                                    width: cropRect.size.width * scale,
                                    height: cropRect.size.height * scale)

        // Use scaledCropRect to crop the image
        guard let croppedCGImage = cgImage.cropping(to: scaledCropRect) else { return }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: scale, orientation: baseImage.imageOrientation)
        
        self.baseImage = croppedImage
        
        if let maskImage = maskImage, let maskCGImage = maskImage.cgImage {
            let croppedMaskCGImage = maskCGImage.cropping(to: scaledCropRect)
            let croppedMaskImage = UIImage(cgImage: croppedMaskCGImage!)
            self.maskImage = croppedMaskImage
        }
        
        self.width = cropRect.size.width
        self.height = cropRect.size.height

        isCropMode = false
        isZoomPanMode = true
        
        resetCropRect()
    }
    
    func resetCropRect() {
        cropRect = CGRect(origin: .zero, size: baseImage.size)
    }
    
}

struct SimpleDrawingViewRepresentable: UIViewRepresentable {
    @Binding var toolSize: CGFloat
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    @Binding var image: UIImage?
    @Binding var drawingView: SimpleDrawingView
    var scale: CGFloat
    
    func makeUIView(context: Context) -> SimpleDrawingView {
        drawingView.brushSize = toolSize / scale
        return drawingView
    }
    
    func updateUIView(_ uiView: SimpleDrawingView, context: Context) {
        uiView.brushSize = toolSize / scale
    }
    
    func clearDrawing() {
        drawingView.clearDrawing()
    }
}

class SimpleDrawingView: UIView {
    var brushSize: CGFloat = 50 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var lines: [Line] = []
    private var dots: [Dot] = []
    
    struct Line {
        var points: [CGPoint]
        var brushSize: CGFloat
    }
    
    struct Dot {
        var point: CGPoint
        var brushSize: CGFloat
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panRecognizer.maximumNumberOfTouches = 1
        panRecognizer.delegate = self
        addGestureRecognizer(panRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(tapRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getImage(width: CGFloat, height: CGFloat) -> UIImage? {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Render the drawn content into an image context
        self.layer.render(in: context)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    @objc func pan(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        
        switch recognizer.state {
        case .began:
            let newLine = Line(points: [location], brushSize: brushSize)
            lines.append(newLine)
        case .changed:
            if let lastLine = lines.last {
                var newPoints = lastLine.points
                newPoints.append(location)
                let updatedLine = Line(points: newPoints, brushSize: lastLine.brushSize)
                lines[lines.count - 1] = updatedLine
            }
        default:
            break
        }
        
        setNeedsDisplay()
    }
    
    @objc func tap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        let newDot = Dot(point: location, brushSize: brushSize)
        dots.append(newDot)
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineCap(.round)
        context.setStrokeColor(UIColor.green.cgColor)
        
        for line in lines {
            guard let firstPoint = line.points.first else { continue }
            
            context.setLineWidth(line.brushSize)
            context.move(to: firstPoint)
            
            if line.points.count > 2 {
                for i in 1..<line.points.count - 1 {
                    let point = line.points[i]
                    let nextPoint = line.points[i + 1]
                    let midPoint = CGPoint(x: (point.x + nextPoint.x) / 2, y: (point.y + nextPoint.y) / 2)
                    context.addQuadCurve(to: midPoint, control: point)
                }
                context.addLine(to: line.points.last!)
            } else {
                for point in line.points.dropFirst() {
                    context.addLine(to: point)
                }
            }
            
            context.strokePath()
        }
        
        context.setFillColor(UIColor.green.cgColor)
        
        for dot in dots {
            let dotSize = dot.brushSize
            let dotRect = CGRect(x: dot.point.x - dotSize / 2, y: dot.point.y - dotSize / 2, width: dotSize, height: dotSize)
            context.fillEllipse(in: dotRect)
        }
    }
    
    func clearDrawing() {
        lines.removeAll()
        dots.removeAll()
        setNeedsDisplay()
    }
}

extension SimpleDrawingView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
