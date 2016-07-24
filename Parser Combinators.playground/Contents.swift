import Foundation


struct Parser<A> {
    typealias Stream = String.CharacterView
    let parse: (Stream) -> (A, Stream)?
}

extension Parser {
    func run(_ string: String) -> (A, Stream)? {
        return parse(string.characters)
    }
    
    var many: Parser<[A]> {
        return Parser<[A]> { input in
            var result: [A] = []
            var remainder = input
            while let (element, newRemainder) = self.parse(remainder) {
                result.append(element)
                remainder = newRemainder
            }
            return (result, remainder)
        }
    }
    
    func map<T>(_ transform: @escaping (A) -> T) -> Parser<T> {
        return Parser<T> { input in
            guard let (result, remainder) = self.parse(input) else { return nil }
            return (transform(result), remainder)
        }
    }
    
    func followed<B>(by other: Parser<B>) -> Parser<(A, B)> {
        return Parser<(A, B)> { input in
            guard let (result1, remainder1) = self.parse(input) else { return nil }
            guard let (result2, remainder2) = other.parse(remainder1) else { return nil }
            return ((result1, result2), remainder2)
        }
    }
}

func character(condition: @escaping (Character) -> Bool) -> Parser<Character> {
    return Parser { input in
        guard let char = input.first, condition(char) else { return nil }
        return (char, input.dropFirst())
    }
}



func multiply(_ x: Int, _ op: Character, _ y: Int) -> Int {
    return x * y
}

func multiply(_ x: Int) -> ((Character) -> ((Int) -> Int)) {
    return { op in
        return { y in
            return x * y
        }
    }
}

func curry<A, B, C, R>(_ f: @escaping (A, B, C) -> R) -> (A) -> (B) -> (C) -> R {
    return { a in { b in { c in f(a, b, c) } } }
}

let curriedMultiply = curry(multiply)



precedencegroup SequencePrecedence {
    associativity: left
    higherThan: AdditionPrecedence
}

infix operator <^>: SequencePrecedence
func <^><A, B>(lhs: @escaping (A) -> B, rhs: Parser<A>) -> Parser<B> {
    return rhs.map(lhs)
}

infix operator <*>: SequencePrecedence
func <*><A, B>(lhs: Parser<(A) -> B>, rhs: Parser<A>) -> Parser<B> {
    return lhs.followed(by: rhs).map { f, x in f(x) }
}



let digit = character { CharacterSet.decimalDigits.contains($0.unicodeScalar) }
let int = digit.many.map { Int(String($0))! }
let multiplication = curriedMultiply <^> int <*> character { $0 == "*" } <*> int


