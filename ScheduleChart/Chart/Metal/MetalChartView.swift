//
//  MetalChartView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 06/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

struct PointIn {
    var point: vector_float2
}

struct GlobalParameters {
    var lineWidth: Float
    var viewport: (Float, Float)
    var transform: matrix_float3x3
    var linePointsCount: UInt16
}

extension matrix_float3x3 {
    static let identity = matrix_from_rows(float3(1, 0, 0),
                                           float3(0, 1, 0),
                                           float3(0, 0, 1))
}

//private extension MTLDevice {
//    func makeBuffer<T>(arr: inout [T], options: MTLResourceOptions = []) -> MTLBuffer? {
//        return makeBuffer(bytes: arr, length: MemoryLayout<T>.stride * arr.count, options: options)
//    }
//}

class MetalChartView: MTKView {
    
    private(set) var maxChartDataCount: Int = 0
    private(set) var maxChartItemsCount: Int = 0
    var chartDataCount: Int = 0
    var chartItemsCount: Int = 0
    
    private var commandQueue: MTLCommandQueue! = nil
    private var library: MTLLibrary! = nil
    private var pipelineDescriptor = MTLRenderPipelineDescriptor()
    private var pipelineState : MTLRenderPipelineState! = nil
    
    var display: BaseDisplay!
    var indices : [UInt16] = []
    var globalParams: GlobalParameters!
    var vertices: PageAlignedContiguousArray<vector_float2>!
    var colors: PageAlignedContiguousArray<vector_float4>!
    
    var indicesBuffer : MTLBuffer!
    var vertexBuffer : MTLBuffer!
    var colorsBuffer : MTLBuffer!
    private let mutex = Mutex()

    override init(frame frameRect: CGRect, device: MTLDevice?)
    {
        let d = device ?? MTLCreateSystemDefaultDevice()!
        super.init(frame: frameRect, device: d)
        configureWithDevice(d)
    }
    
    required init(coder: NSCoder)
    {
        super.init(coder: coder)
        configureWithDevice(MTLCreateSystemDefaultDevice()!)
    }
    
    private func configureWithDevice(_ device : MTLDevice) {
        display = LineDisplay(view: self)
        
        let viewport = (Float(drawableSize.width), Float(drawableSize.height))
        globalParams = GlobalParameters(lineWidth: 4, viewport: viewport, transform: .identity, linePointsCount: 0)
        
        self.clearColor = MTLClearColor.init(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.framebufferOnly = true
        self.colorPixelFormat = .bgra8Unorm
        
        // Run with 4x MSAA:
        self.sampleCount = 4
        
        self.preferredFramesPerSecond = 60
        
        self.device = device
    }
    
    override var device: MTLDevice! {
        didSet {
            super.device = device
            commandQueue = (self.device?.makeCommandQueue())!
            
            library = device?.makeDefaultLibrary()
            pipelineDescriptor.vertexFunction = library?.makeFunction(name: "bezier_vertex")
            pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "bezier_fragment")
            pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
            
            // Run with 4x MSAA:
            pipelineDescriptor.sampleCount = 4
            
            pipelineState = (try? device?.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
        }
    }
    
    func setupBuffers(maxChartDataCount: Int, maxChartItemsCount: Int) {
        if indicesBuffer != nil {
            assert(false, "Already setuped")
            return
        }
        self.maxChartDataCount = maxChartDataCount
        self.maxChartItemsCount = maxChartItemsCount
        globalParams.linePointsCount = UInt16(maxChartItemsCount)
        
        let totalCount: Int = maxChartItemsCount * 4 * maxChartDataCount
        indices = Array(0..<UInt16(totalCount))
        indicesBuffer = (self.device?.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: .storageModeShared))
        
        vertices = PageAlignedContiguousArray<vector_float2>(repeating: vector_float2(0, 0), count: maxChartDataCount * maxChartItemsCount)
        vertexBuffer = device.makeBufferWithPageAlignedArray(vertices)
        
        colors = PageAlignedContiguousArray(repeating: vector_float4(0, 0, 0, 0), count: maxChartDataCount)
        colorsBuffer = device.makeBufferWithPageAlignedArray(colors)
    }
    
    func setupWithData(data: [ChartData]) {
        mutex.lock()
        defer { mutex.unlock() }

        display.data = data
    }
    
    
    override func draw(_ rect: CGRect) {
//        if chartDataCount == 0 { return }
        globalParams.viewport = (Float(drawableSize.width), Float(drawableSize.height))
        
        mutex.lock()
        defer { mutex.unlock() }
        
        guard let commandBuffer = commandQueue!.makeCommandBuffer(),
            let renderPassDescriptor = self.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        display.display(renderEncoder: renderEncoder)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(self.currentDrawable!)
        commandBuffer.commit()
    }
    
}
