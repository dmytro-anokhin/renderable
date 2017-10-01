/*
Copyright 2017 Dmytro Anokhin
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import XCTest
@testable import Renderable


class RenderableTests: XCTestCase {
    
    // Test input: image name, expected pixels
    private let testInput: [(name: String, expectedPixels: [RGBAPixel])] = [
        // 50% Opacity (a = 128)
        (
            name: "palette_50_alpha",
            expectedPixels: [
                // RGB
                RGBAPixel(r: 255, g: 0, b: 0, a: 128),
                RGBAPixel(r: 0, g: 255, b: 0, a: 128),
                RGBAPixel(r: 0, g: 0, b: 255, a: 128),
                
                // CMY
                RGBAPixel(r: 0, g: 255, b: 255, a: 128),
                RGBAPixel(r: 255, g: 0, b: 255, a: 128),
                RGBAPixel(r: 255, g: 255, b: 0, a: 128),
                
                // Grayscale
                RGBAPixel(r: 255, g: 255, b: 255, a: 128),
                RGBAPixel(r: 204, g: 204, b: 204, a: 128),
                RGBAPixel(r: 153, g: 153, b: 153, a: 128),
                RGBAPixel(r: 102, g: 102, b: 102, a: 128),
                RGBAPixel(r: 51, g: 51, b: 51, a: 128),
                RGBAPixel(r: 0, g: 0, b: 0, a: 128)
            ]
        ),
        
        // 50% Opacity (a = 255)
        (
            name: "palette_100_alpha",
            expectedPixels: [
                // RGB
                RGBAPixel(r: 255, g: 0, b: 0, a: 255),
                RGBAPixel(r: 0, g: 255, b: 0, a: 255),
                RGBAPixel(r: 0, g: 0, b: 255, a: 255),
                
                // CMY
                RGBAPixel(r: 0, g: 255, b: 255, a: 255),
                RGBAPixel(r: 255, g: 0, b: 255, a: 255),
                RGBAPixel(r: 255, g: 255, b: 0, a: 255),
                
                // Grayscale
                RGBAPixel(r: 255, g: 255, b: 255, a: 255),
                RGBAPixel(r: 204, g: 204, b: 204, a: 255),
                RGBAPixel(r: 153, g: 153, b: 153, a: 255),
                RGBAPixel(r: 102, g: 102, b: 102, a: 255),
                RGBAPixel(r: 51, g: 51, b: 51, a: 255),
                RGBAPixel(r: 0, g: 0, b: 0, a: 255)
            ]
        )
    ]
    
    func testMemorySize() {
        // Loading bitmap in memory is heavy operation. I want to be sure that used data types do not have additional implications. In RGBA each pixel is 4 bytes and so must be in-memory representation.
        XCTAssertEqual(MemoryLayout<RGBAPixel>.size, 4)
    }
    
    func testEmptyImage() {
        let image = UIImage()
        XCTAssertNil(image.rgbaPixels())
    }
    
    func testCGImage() {

        for input in testInput {
            let path = Bundle(for: type(of: self)).path(forResource: input.name, ofType: "png")!
            var dataProvider: CGDataProvider!
            
            path.withCString { filename in
                dataProvider = CGDataProvider(filename: filename)!
            }
            
            let image = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
            let pixels = image.rgbaPixels()!
            XCTAssertEqual(pixels, input.expectedPixels)
        }
    }
    
    func testCIImage() {
    
        for input in testInput {
            let url = Bundle(for: type(of: self)).url(forResource: input.name, withExtension: "png")!
            let image = CIImage(contentsOf: url)!
            let pixels = image.rgbaPixels()!
            XCTAssertEqual(pixels, input.expectedPixels)
        }
    }
    
    func testUIImage() {

        for input in testInput {
            let image = UIImage(named: input.name, in: Bundle(for: type(of: self)), compatibleWith: nil)!
            let pixels = image.rgbaPixels()!
            XCTAssertEqual(pixels, input.expectedPixels)
        }
    }
}
