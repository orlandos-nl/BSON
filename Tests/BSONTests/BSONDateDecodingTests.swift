//
//  BSONTimeStampToDateDecodingTests.swift
//
//
//  Created by Suraj Thomas Karathra on 15/04/2024.
//

import Foundation
import XCTest
import BSON

final class BSONTimeStampToDateDecodingTests: XCTestCase {

    private struct Target: Decodable {

        let date: Date
    }

    func testPrimitiveDate() throws {

        struct Source: Encodable {

            let date: Date
        }

        let source = Source(date: Date())

        let sourceBSON = try BSONEncoder().encode(source)

        do {
            let target = try BSONDecoder().decode(Target.self, from: sourceBSON)

            XCTAssertEqual(
                source.date.timeIntervalSinceReferenceDate,
                target.date.timeIntervalSinceReferenceDate,
                accuracy: 0.001
            )
        } catch let error {
            XCTFail("Decoding of primitive date failed : \(error.localizedDescription)")
        }
    }

    func testIntegerDateRelativeToReferenceDate() throws {

        struct Source: Encodable {

            let date: Int
        }

        let timeInterval: TimeInterval = 1356351330
        let source = Source(date: Int(timeInterval))

        let sourceBSON = try BSONEncoder().encode(source)

        do {
            let settings = BSONDecoderSettings.adaptive.with(timestampToDateDecodingStrategy: .relativeToReferenceDate)
            let target = try BSONDecoder(settings: settings).decode(Target.self, from: sourceBSON)

            XCTAssertEqual(
                target.date.timeIntervalSinceReferenceDate,
                timeInterval,
                accuracy: 0.001
            )
            XCTAssertNotEqual(
                target.date.timeIntervalSince1970,
                timeInterval,
                accuracy: 0.001
            )
        } catch let error {
            XCTFail("Decoding of date as integer failed : \(error.localizedDescription)")
        }
    }

    func testIntegerDateRelativeToUnixEpoch() throws {

        struct Source: Encodable {

            let date: Int
        }

        let timeInterval: TimeInterval = 1356351330
        let source = Source(date: Int(timeInterval))

        let sourceBSON = try BSONEncoder().encode(source)

        do {
            let settings = BSONDecoderSettings.adaptive.with(timestampToDateDecodingStrategy: .relativeToUnixEpoch)
            let target = try BSONDecoder(settings: settings).decode(Target.self, from: sourceBSON)
            XCTAssertNotEqual(
                target.date.timeIntervalSinceReferenceDate,
                timeInterval,
                accuracy: 0.001
            )
            XCTAssertEqual(
                target.date.timeIntervalSince1970,
                timeInterval,
                accuracy: 0.001
            )
        } catch let error {
            XCTFail("Decoding of date as integer failed : \(error.localizedDescription)")
        }
    }

    func testIntegerDateStrictMode() throws {

        struct Source: Encodable {

            let date: Int
        }

        let timeInterval: TimeInterval = 1356351330
        let source = Source(date: Int(timeInterval))

        let sourceBSON = try BSONEncoder().encode(source)

        XCTAssertThrowsError(try BSONDecoder(settings: BSONDecoderSettings.strict).decode(Target.self, from: sourceBSON))
    }

    func testInteger32DateRelativeToReferenceDate() throws {

        struct Source: Encodable {

            let date: Int32
        }

        let timeInterval: TimeInterval = 1356351330
        let source = Source(date: Int32(timeInterval))

        let sourceBSON = try BSONEncoder().encode(source)

        do {
            let settings = BSONDecoderSettings.adaptive.with(timestampToDateDecodingStrategy: .relativeToReferenceDate)
            let target = try BSONDecoder(settings: settings).decode(Target.self, from: sourceBSON)

            XCTAssertEqual(
                target.date.timeIntervalSinceReferenceDate,
                timeInterval,
                accuracy: 0.001
            )
            XCTAssertNotEqual(
                target.date.timeIntervalSince1970,
                timeInterval,
                accuracy: 0.001
            )
        } catch let error {
            XCTFail("Decoding of date as integer32 failed : \(error.localizedDescription)")
        }
    }

    func testInteger32DateRelativeToUnixEpoch() throws {

        struct Source: Encodable {

            let date: Int32
        }

        let timeInterval: TimeInterval = 1356351330
        let source = Source(date: Int32(timeInterval))

        let sourceBSON = try BSONEncoder().encode(source)

        do {
            let settings = BSONDecoderSettings.adaptive.with(timestampToDateDecodingStrategy: .relativeToUnixEpoch)
            let target = try BSONDecoder(settings: settings).decode(Target.self, from: sourceBSON)
            XCTAssertNotEqual(
                target.date.timeIntervalSinceReferenceDate,
                timeInterval,
                accuracy: 0.001
            )
            XCTAssertEqual(
                target.date.timeIntervalSince1970,
                timeInterval,
                accuracy: 0.001
            )
        } catch let error {
            XCTFail("Decoding of date as integer32 failed : \(error.localizedDescription)")
        }
    }

    func testInteger32DateStrictMode() throws {

        struct Source: Encodable {

            let date: Int32
        }

        let timeInterval: TimeInterval = 1356351330
        let source = Source(date: Int32(timeInterval))

        let sourceBSON = try BSONEncoder().encode(source)

        XCTAssertThrowsError(try BSONDecoder(settings: BSONDecoderSettings.strict).decode(Target.self, from: sourceBSON))
    }

    func testDoubleDateRelativeToReferenceDate() throws {

        struct Source: Encodable {

            let date: Double
        }

        let timeInterval: TimeInterval = 1356351330.5
        let source = Source(date: timeInterval)

        let sourceBSON = try BSONEncoder().encode(source)

        do {
            let settings = BSONDecoderSettings.adaptive.with(timestampToDateDecodingStrategy: .relativeToReferenceDate)
            let target = try BSONDecoder(settings: settings).decode(Target.self, from: sourceBSON)
            XCTAssertEqual(
                target.date.timeIntervalSinceReferenceDate,
                timeInterval,
                accuracy: 0.001
            )
            XCTAssertNotEqual(
                target.date.timeIntervalSince1970,
                timeInterval,
                accuracy: 0.001
            )
        } catch let error {
            XCTFail("Decoding of date as double failed : \(error.localizedDescription)")
        }
    }

    func testDoubleDateRelativeToUnixEpoch() throws {

        struct Source: Encodable {

            let date: Double
        }

        let timeInterval: TimeInterval = 1356351330.5
        let source = Source(date: timeInterval)

        let sourceBSON = try BSONEncoder().encode(source)

        do {
            let settings = BSONDecoderSettings.adaptive.with(timestampToDateDecodingStrategy: .relativeToUnixEpoch)
            let target = try BSONDecoder(settings: settings).decode(Target.self, from: sourceBSON)
            XCTAssertNotEqual(
                target.date.timeIntervalSinceReferenceDate,
                timeInterval,
                accuracy: 0.001
            )
            XCTAssertEqual(
                target.date.timeIntervalSince1970,
                timeInterval,
                accuracy: 0.001
            )
        } catch let error {
            XCTFail("Decoding of date as double failed : \(error.localizedDescription)")
        }
    }

    func testDoubleDateStrictMode() throws {

        struct Source: Encodable {

            let date: Double
        }

        let timeInterval: TimeInterval = 1356351330.5
        let source = Source(date: timeInterval)

        let sourceBSON = try BSONEncoder().encode(source)

        XCTAssertThrowsError(try BSONDecoder(settings: BSONDecoderSettings.strict).decode(Target.self, from: sourceBSON))
    }
}
