//
//  PrimaryResourceBody.swift
//  JSONAPI
//
//  Created by Mathew Polzin on 11/10/18.
//

/// This protocol allows for `SingleResourceBody` to contain a `null`
/// data object where `ManyResourceBody` cannot (because an empty
/// array should be used for no results).
public protocol OptionalPrimaryResource: Equatable, Codable {}

/// A PrimaryResource is a type that can be used in the body of a JSON API
/// document as the primary resource.
public protocol PrimaryResource: OptionalPrimaryResource {}

extension Optional: OptionalPrimaryResource where Wrapped: PrimaryResource {}

/// A ResourceBody is a representation of the body of the JSON API Document.
/// It can either be one resource (which can be specified as optional or not)
/// or it can contain many resources (and array with zero or more entries).
public protocol ResourceBody: Codable, Equatable {
}

/// A `ResourceBody` that has the ability to take on more primary
/// resources by appending another similarly typed `ResourceBody`.
public protocol AppendableResourceBody: ResourceBody {
	func appending(_ other: Self) -> Self
}

public func +<R: AppendableResourceBody>(_ left: R, right: R) -> R {
	return left.appending(right)
}

public struct SingleResourceBody<Entity: JSONAPI.OptionalPrimaryResource>: ResourceBody {
	public let value: Entity

	public init(resourceObject: Entity) {
		self.value = resourceObject
	}
}

public struct ManyResourceBody<Entity: JSONAPI.PrimaryResource>: AppendableResourceBody {
	public let values: [Entity]

	public init(resourceObjects: [Entity]) {
		values = resourceObjects
	}

	public func appending(_ other: ManyResourceBody) -> ManyResourceBody {
		return ManyResourceBody(resourceObjects: values + other.values)
	}
}

/// Use NoResourceBody to indicate you expect a JSON API document to not
/// contain a "data" top-level key.
public struct NoResourceBody: ResourceBody {
	public static var none: NoResourceBody { return NoResourceBody() }
}

// MARK: Codable
extension SingleResourceBody {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		let anyNil: Any? = nil
		if container.decodeNil(),
			let val = anyNil as? Entity {
			value = val
			return
		}

		value = try container.decode(Entity.self)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()

        let anyNil: Any? = nil
        let nilValue = anyNil as? Entity
        guard value != nilValue else {
            try container.encodeNil()
            return
        }

		try container.encode(value)
	}
}

extension ManyResourceBody {
	public init(from decoder: Decoder) throws {
		var container = try decoder.unkeyedContainer()
		var valueAggregator = [Entity]()
		while !container.isAtEnd {
			valueAggregator.append(try container.decode(Entity.self))
		}
		values = valueAggregator
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.unkeyedContainer()

		for value in values {
			try container.encode(value)
		}
	}
}

// MARK: CustomStringConvertible

extension SingleResourceBody: CustomStringConvertible {
	public var description: String {
		return "PrimaryResourceBody(\(String(describing: value)))"
	}
}

extension ManyResourceBody: CustomStringConvertible {
	public var description: String {
		return "PrimaryResourceBody(\(String(describing: values)))"
	}
}
