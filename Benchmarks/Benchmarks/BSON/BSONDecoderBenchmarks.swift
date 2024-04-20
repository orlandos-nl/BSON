import BSON
import Benchmark

func bsonDecoderBenchmarks() {
    let smallDocument: Document = [
        "string": "Hello, world!",
        "int": 42,
        "double": 3.14159,
        "bool": true,
        "array": [1, 2, 3, 4, 5],
        "document": ["key": "value"],
    ]
    
    struct SmallType: Codable {
        let string: String
        let int: Int
        let double: Double
        let bool: Bool
        let array: [Int]
        let document: [String: String]
    }

    Benchmark("BSONDecoder:fastPath:small") { _ in
        blackHole(
            try BSONDecoder(settings: .fastPath)
                .decode(SmallType.self, from: smallDocument)
        )
    }

    Benchmark("BSONDecoder:adaptive:small") { _ in
        blackHole(
            try BSONDecoder(settings: .adaptive)
                .decode(SmallType.self, from: smallDocument)
        )
    }

    let largeDocument: Document = [
        "string": "Hello, world!",
        "int": 42,
        "double": 3.14159,
        "bool": true,
        "array": [1, 2, 3, 4, 5],
        "document": ["key": "value"],
        "nested": [
            "string": "Hello, world!",
            "int": 42,
            "double": 3.14159,
            "bool": true,
            "array": [1, 2, 3, 4, 5],
            "document": ["key": "value"],
        ] as Document,
    ]

    struct LargeType: Codable {
        let string: String
        let int: Int
        let double: Double
        let bool: Bool
        let array: [Int]
        let document: [String: String]
        let nested: SmallType
    }

    Benchmark("BSONDecoder:fastPath:large") { _ in
        blackHole(
            try BSONDecoder(settings: .fastPath)
                .decode(LargeType.self, from: largeDocument)
        )
    }

    Benchmark("BSONDecoder:adaptive:large") { _ in
        blackHole(
            try BSONDecoder(settings: .adaptive)
                .decode(LargeType.self, from: largeDocument)
        )
    }
}
