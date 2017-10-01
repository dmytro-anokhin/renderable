## Using Swift to access individual pixels of CGImage, CIImage, and UIImage.

The **Renderable** demonstrates how to use Swift protocol extension to convert object into bitmap and access individual pixels.

### Usage

Include individual **Renderable.swift** and extension files to your project. Or everything as a framework.

```swift 
let image = UIImage(named: "MyImage")
if let pixels = image.rgbaPixels() {
    for pixel in pixels {
        print("red: \(pixel.r), green: \(pixel.g), blue: \(pixel.b), alpha: \(pixel.a)")
    }
}
```

### Description

Goal is to explore how protocol extensions in Swift can connect types from different frameworks. In this case CoreGraphics, CoreImage, and UIKit.

I use `Renderable` protocol to declare types that can be represented in a bitmap:

```swift
protocol Renderable {

    var pixelSize: (width: Int, height: Int) { get }

    func render(in context: CGContext)
}
```

The `render(in:)` is a drawing routine. To construct a bitmap context all I need to know is size in pixels.

#### Rendering

Implementations for `CGImage` and `CIImage` are straight forward:

```swift
extension CGImage: Renderable {
    
    var pixelSize: (width: Int, height: Int) {
        return (width: width, height: height)
    }
    
    func render(in context: CGContext) {
        let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height))
        context.draw(self, in: rect)
    }
}

extension CIImage: Renderable {
    
    public var pixelSize: (width: Int, height: Int) {
        return (width: Int(extent.width), height: Int(extent.height))
    }
    
    public func render(in context: CGContext) {
        let ciContext = CIContext(cgContext: context, options: nil)
        ciContext.draw(self, in: extent, from: extent)
    }
}
```

Unlike `CGImage`, `UIImage` uses current context and does not allow to specify it. Therefore, underlying image is used:

```swift
extension UIImage: Renderable {

    var pixelSize: (width: Int, height: Int) {
        return (width: Int(size.width), height: Int(size.height))
    }

    func render(in context: CGContext) {
        if let image = cgImage {
            image.render(in: context)
            return
        }
        
        if let image = ciImage {
            image.render(in: context)
            return
        }
    }
}
```

#### Color Space and Pixel

I use 8-bit RGBA color space. Every pixel is represented by 4 bytes, one for Red, Green, Blue, and Alpha components. Component value can take 0...255 therefore best type to represent it is `UInt8`. And to represent a pixel I created `RGBAPixel` structure:

```swift
struct RGBAPixel {

    typealias Byte = UInt8

    var r: Byte
    
    var g: Byte
    
    var b: Byte
    
    var a: Byte
}
```

Nice thing that `RGBAPixel` occupy same 4 bytes of memory as pixel in a bitmap.

#### Accessing Bitmap Data

Unifying rendering under `Renderable` type allows me create a single routine via protocol extension.

Idea is to render in RGBA context and read underlying data:

```swift
extension Renderable {

    func rgbaPixels() -> [RGBAPixel]? {

        let width = pixelSize.width
        let height = pixelSize.height
    
        // The depth of color is 8-bit. Every pixel is represented by 4 bytes: red, green, blue, and alpha.
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        
        let bytesPerRow = bytesPerPixel * width
        // Total size for the bitmap in memory
        let byteCount = bytesPerRow * height
    
        let rgbaColorSpace = CGColorSpaceCreateDeviceRGB()
    
        // RGBA bitmap context
        if let context = CGContext(data: nil, width: width, height: height,
            bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow,
            space: rgbaColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        {
            // Render in context
            render(in: context)
            
            // The bitmap is now in a continous chunk of memory. We can remap pointer into bytes and iterate over it.
            // Every pixel is stored in 4 bytes (bytesPerPixel). First byte is red component, second - green, third - blue, fourth - alpha.
            if let bytes = context.data?.bindMemory(to: RGBAPixel.Byte.self, capacity: byteCount) {
                var pixel: RGBAPixel!
                var result: [RGBAPixel] = []
                
                for i in 0..<byteCount {
                    let value = bytes.advanced(by: i).pointee
                    let component = i % bytesPerPixel
                    
                    if component == 0 { // Red
                        if let pixel = pixel { // Store previous pixel
                            result.append(pixel)
                        }
                    
                        pixel = RGBAPixel(r: value, g: 0, b: 0, a: 0) // Create new
                    }
                    else if component == 1 { // Green
                        pixel.g = value
                    }
                    else if component == 2 { // Blue
                        pixel.b = value
                    }
                    else if component == 3 { // Alpha
                        pixel.a = value
                    }
                }
                
                // Store last pixel
                result.append(pixel)
                
                return result
            }
        }
        
        return nil
    }
}

```


Ability to extend existing types with protocols allows to bridge and unify interfaces between different frameworks. And protocol extensions are elegant solution to reduce boilerplate code.
















