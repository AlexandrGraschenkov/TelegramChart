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
    var halfViewport: (Float, Float)
    var transform: matrix_float3x3
    var linePointsCount: UInt32
    var chartCount: UInt32
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
    var isSelectionChart: Bool = false
    
    private var commandQueue: MTLCommandQueue! = nil
    private var library: MTLLibrary! = nil
    private var pipelineDescriptor = MTLRenderPipelineDescriptor()
    private var pipelineState : MTLRenderPipelineState! = nil
    
    private var levelDisplay: LineLevelDisplay?
    var display: BaseDisplay!
    var globalParams: GlobalParameters!
    var customScale: [Float] = []
    let mutex = Mutex()

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
    
    func updateChartType(chartType: ChartType) {
        switch chartType {
        case .line:
            if !(display is LineDisplay) {
                display = LineDisplay(view: self, device: device!, reuseBuffers: display?.buffers)
            }
        case .stacked:
            if !(display is StackFillDisplay) {
                display = StackFillDisplay(view: self, device: device!, reuseBuffers: display?.buffers)
            }
        case .percentage:
            if !(display is PercentFillDisplay) {
                display = PercentFillDisplay(view: self, device: device!, reuseBuffers: display?.buffers)
            }
        }
        
        display?.setupBuffers(maxChartDataCount: maxChartDataCount, maxChartItemsCount: maxChartItemsCount)
    }
    
    private func configureWithDevice(_ device : MTLDevice) {
//        display = LineDisplay(view: self, device: device)
//        display = StackFillDisplay(view: self, device: device)
//        display = PercentFillDisplay(view: self, device: device)
        
        let viewport = (Float(drawableSize.width) / 2.0,
                        Float(drawableSize.height) / 2.0)
        globalParams = GlobalParameters(lineWidth: 4, halfViewport: viewport, transform: .identity, linePointsCount: 0, chartCount: 0)
        
        clearColor = MTLClearColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        framebufferOnly = true
        colorPixelFormat = .bgra8Unorm
        
        // Run with 4rx MSAA:
        sampleCount = 4
        
        preferredFramesPerSecond = 60
        isPaused = true
        enableSetNeedsDisplay = true
        
        self.device = device
    }
    
    override var device: MTLDevice! {
        didSet {
            super.device = device
            commandQueue = (self.device?.makeCommandQueue())!
            
        }
    }
    
    func setupBuffers(maxChartDataCount: Int, maxChartItemsCount: Int) {
        self.maxChartDataCount = maxChartDataCount
        self.maxChartItemsCount = maxChartItemsCount
        globalParams.linePointsCount = UInt32(maxChartItemsCount)
        
        display?.setupBuffers(maxChartDataCount: maxChartDataCount, maxChartItemsCount: maxChartItemsCount)
    }
    
    func setupWithData(data: ChartGroupData) {
        mutex.lock()
        defer { mutex.unlock() }

        updateChartType(chartType: data.type)
        display.data = data
    }
    
    func updateLevels(levels: [LineAlpha]) {
        if levelDisplay == nil {
            levelDisplay = LineLevelDisplay(view: self, device: device, reuseBuffers: nil)
        }
        levelDisplay?.update(lines: levels)
    }
    
    override func draw(_ rect: CGRect) {
//        if chartDataCount == 0 { return }
        globalParams.halfViewport = (Float(drawableSize.width) / 2.0,
                                     Float(drawableSize.height) / 2.0)
        display.prepareDisplay()
        
        mutex.lock()
        
        guard let commandBuffer = commandQueue!.makeCommandBuffer(),
            let renderPassDescriptor = self.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                mutex.unlock()
            return
        }
        commandBuffer.addCompletedHandler { (_) in
            self.mutex.unlock()
        }
        
        
        let drawLineFirst = display.groupMode == .none
        if display.showGrid && drawLineFirst {
            levelDisplay?.display(renderEncoder: renderEncoder)
        }
        
        display.display(renderEncoder: renderEncoder)
        
        if display.showGrid && !drawLineFirst {
            levelDisplay?.display(renderEncoder: renderEncoder)
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(self.currentDrawable!)
        commandBuffer.commit()
    }
}
