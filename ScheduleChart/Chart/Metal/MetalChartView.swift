//
//  MetalChartView.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 06/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit


struct GlobalParameters {
    var lineWidth: Float
    var viewport: (Float, Float)
    var transform: matrix_float3x3
    var linePointsCount: UInt
}

extension matrix_float3x3 {
    static let identity = matrix_from_rows(float3(1, 0, 0),
                                           float3(0, 1, 0),
                                           float3(0, 0, 1))
}

private extension MTLDevice {
    func makeBuffer<T>(arr: [T], options: MTLResourceOptions = []) -> MTLBuffer? {
        return makeBuffer(bytes: arr, length: MemoryLayout<T>.stride * arr.count, options: options)
    }
}

class MetalChartView: MTKView {
    
    private(set) var maxChartDataCount: Int = 0
    private(set) var maxChartItemsCount: Int = 0
    private(set) var chartDataCount: Int = 0
    private(set) var chartItemsCount: Int = 0
    
    private var commandQueue: MTLCommandQueue! = nil
    private var library: MTLLibrary! = nil
    private var pipelineDescriptor = MTLRenderPipelineDescriptor()
    private var pipelineState : MTLRenderPipelineState! = nil
    
    var indices : [UInt16] = []
    var globalParams: GlobalParameters!
    var vertices: [vector_float2] = []
    var colors: [vector_float4] = []
    
    private var indicesBuffer : MTLBuffer!
    private var globalParamBuffer : MTLBuffer!
    private var vertexBuffer : MTLBuffer!
    private var colorsBuffer : MTLBuffer!
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
    
    override var drawableSize: CGSize {
        didSet {
            globalParams?.viewport = (Float(drawableSize.width), Float(drawableSize.height))
            print("Viewport", drawableSize)
        }
    }
    
    private func configureWithDevice(_ device : MTLDevice) {
        let viewport = (Float(drawableSize.width), Float(drawableSize.height))
        globalParams = GlobalParameters(lineWidth: 14, viewport: viewport, transform: .identity, linePointsCount: 0)
        
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
//            pipelineDescriptor.vertexFunction = library?.makeFunction(name: "basic_vertex")
//            pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "basic_fragment")
//            pipelineDescriptor.vertexFunction = library!.makeFunction(name: "vertex_main")
//            pipelineDescriptor.fragmentFunction = library!.makeFunction(name: "fragment_main")
            pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
            
            // Run with 4x MSAA:
            pipelineDescriptor.sampleCount = 4
            
            pipelineState = (try? device?.makeRenderPipelineState(descriptor: pipelineDescriptor)) as! MTLRenderPipelineState
            
            // Set how many "elements" are to be used for each curve. Normally we would
            // calculate this per curve, but since we're using the indexed primitives
            // approach, we need a fixed number of vertices per curve. Note that this is
            // the number of triangles, not vertexes:
            
            globalParamBuffer = (self.device?.makeBuffer(bytes: &globalParams,
                                                         length: MemoryLayout<GlobalParameters>.stride,
                                                         options: .storageModeShared))
        }
    }
    
    func setupBuffers(maxChartDataCount: Int, maxChartItemsCount: Int) {
        if indicesBuffer != nil {
            assert(false, "Already setuped")
            return
        }
        self.maxChartDataCount = maxChartDataCount
        self.maxChartItemsCount = maxChartItemsCount
        globalParams.linePointsCount = UInt(maxChartItemsCount)
        
        
        chartDataCount = 1//data.count
        chartItemsCount = 3
        
        let totalCount: Int = maxChartItemsCount * 4 * maxChartDataCount
        indices = Array(0..<UInt16(totalCount))
        indicesBuffer = (self.device?.makeBuffer(arr: indices, options: .storageModeShared))
        
        vertices = Array(repeating: vector_float2(0, 0), count: maxChartDataCount * maxChartItemsCount)
        vertices[0] = vector_float2(0, 0)
        vertices[1] = vector_float2(30, 30)
        vertices[2] = vector_float2(80, 50)
        vertexBuffer = (self.device?.makeBuffer(arr: vertices, options: .storageModeShared))
        
        colors = Array(repeating: vector_float4(0, 0, 0, 0), count: maxChartDataCount)
        colorsBuffer = (self.device?.makeBuffer(arr: colors, options: .storageModeShared))
    }
    
    func setupWithData(data: [ChartData]) {
        mutex.lock()
        defer { mutex.unlock() }
//
//        chartDataCount = 1//data.count
//        chartItemsCount = 3
//        vertices[0] = vector_float2(-1, -1)
//        vertices[1] = vector_float2(1, -1)
//        vertices[2] = vector_float2(-1, 1)
//        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
//        for (i, d) in data.enumerated() {
//            chartItemsCount = d.items.count
//            d.color.getRed(&r, green: &g, blue: &b, alpha: &a)
//            colors[i] = vector_float4(Float(r), Float(g), Float(b), Float(a))
//
//            let vertOffset = i*maxChartItemsCount
//            for (ii, item) in d.items.enumerated() {
//                vertices[vertOffset + ii] = vector_float2(Float(ii) / 200, Float(item.value) / 5000000)
//            }
//        }
    }
    
    
    override func draw(_ rect: CGRect) {
//        if chartDataCount == 0 { return }
        mutex.lock()
        defer { mutex.unlock() }
        
        guard let commandBuffer = commandQueue!.makeCommandBuffer(),
            let renderPassDescriptor = self.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        //        vertices = [vector_float2(-1, -1), vector_float2(1, 1), vector_float2(1, -1)]
        //        renderEncoder.setVertexBytes(vertices, length: 3*MemoryLayout<vector_float2>.stride, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(globalParamBuffer, offset: 0, index: 2)
        
        // Enable this to see the actual triangles instead of a solid curve:
//        renderEncoder.setTriangleFillMode(.lines)
        
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        for i in 0..<chartDataCount {
            let from = (maxChartItemsCount - 1) * 4 * i
            let count = (chartItemsCount-1) * 4
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: count, indexType: .uint16, indexBuffer: indicesBuffer!, indexBufferOffset: from)
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(self.currentDrawable!)
        commandBuffer.commit()
    }
    
}
