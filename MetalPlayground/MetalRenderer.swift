//
//  MetalRenderer.swift
//  MetalPlayground
//
//  Created by Yashas Jindal on 2025-10-31.
//

import SwiftUI
import MetalKit

// MARK: - Vertex data for a triangle
private let triangleVertices: [Float] = [
    0.0,  0.5, 0.0,    // top
   -0.5, -0.5, 0.0,    // left
    0.5, -0.5, 0.0     // right
]

// MARK: - Metal Renderer
final class MetalRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var vertexBuffer: MTLBuffer!

    init(mtkView: MTKView) {
        super.init()
        device = mtkView.device
        commandQueue = device.makeCommandQueue()
        vertexBuffer = device.makeBuffer(bytes: triangleVertices,
                                         length: MemoryLayout<Float>.size * triangleVertices.count,
                                         options: [])

        let library = device.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "vertex_main")
        let fragmentFunc = library.makeFunction(name: "fragment_main")

        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunc
        pipelineDesc.fragmentFunction = fragmentFunc
        pipelineDesc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
    }

    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor
        else { return }

        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 1)
        descriptor.colorAttachments[0].loadAction = .clear

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

// MARK: - SwiftUI bridge
struct MetalView: NSViewRepresentable {
    final class Coordinator {
        var renderer: MetalRenderer?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Hold a strong reference to the renderer via the Coordinator so the weak delegate doesn't deallocate it
        let renderer = MetalRenderer(mtkView: mtkView)
        context.coordinator.renderer = renderer
        mtkView.delegate = renderer
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}
