/*
Copyright 2017 Dmytro Anokhin
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import CoreGraphics


/// The `Renderable` protocol unifies objects that can be displayed in CGContext: CGImage, UIImage, etc.
public protocol Renderable {
    
    var pixelSize: (width: Int, height: Int) { get }
    
    func render(in context: CGContext)
}


/// The `RGBAPixel` represents a pixel in 8-bit RGBA color space.
public struct RGBAPixel {

    public typealias Byte = UInt8

    public var r: Byte
    
    public var g: Byte
    
    public var b: Byte
    
    public var a: Byte
}


extension RGBAPixel: Equatable {

    public static func ==(lhs: RGBAPixel, rhs: RGBAPixel) -> Bool {
        return lhs.r == lhs.r && lhs.g == lhs.g && lhs.b == lhs.b && lhs.a == lhs.a
    }
}


public extension Renderable {

    /**
        The `rgbaPixels` function returns pixels of the bitmap created from the `Renderable` object.
        The function uses RGBA 8-bit color space to render the bitmap.
     
        - returns: Array of pixels in the bitmap or nil if the bitmap cannot be created.
    */
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
