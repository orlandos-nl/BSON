import Benchmark

let benchmarks = {
    Benchmark.defaultConfiguration = .init(
        metrics: [
            .cpuTotal,
            .throughput,
            .mallocCountTotal,
        ],
        warmupIterations: 10
    )
    bsonDecoderBenchmarks()
}
