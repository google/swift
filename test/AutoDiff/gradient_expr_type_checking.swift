// RUN: %target-swift-frontend -typecheck -verify %s

func foo(x: Float, y: Float) -> Float {}

let someVar: Int = 100

#gradient(of: someVar) // expected-error {{only functions can be differentiated}}

let foo_grad: (Float, Float) -> (Float, Float) = #gradient(of: foo) // ok
let _: (Float, Float) -> Float = #gradient(of: foo, withRespectTo: .0) // ok
let _: (Float, Float) -> (Float, Float) = #gradient(of: foo, withRespectTo: self, .0) // expected-error {{a 'self' argument can only be used in an instance declaration}}
let _: (Float, Float) -> (Float, Float) = #gradient(of: foo, withRespectTo: .0, self) // expected-error {{the 'self' argument must be the first}}
let _: (Float, Float) -> (Float, Float) = #gradient(of: foo, withRespectTo: .0, .1) // ok
let _: (Float, Float) -> (Float, Float, Float) = #gradient(of: foo, withRespectTo: .0, .1, .2) // expected-error {{the argument index is out of bounds for type}}

// S is not a valid differentiation argument because it does not conform to FloatingPoint.
struct S {
  func a(_ x: Float) -> Float {}

  lazy var da: (Float) -> Float = #gradient(of: self.a) // ok

  func b() {
    let _: (Float) -> Float = #gradient(of: a) // ok
    let _: (Float) -> S = #gradient(of: a, withRespectTo: self) // expected-error {{gradient argument has non-differentiable type 'S'}}
  }

  static func c(_ x: Float) -> Float {}

  static func d() -> Float {
    let _: (Float) -> S = #gradient(of: c, withRespectTo: self) // expected-error {{a 'self' argument can only be used in an instance declaration context}}
  }
}

let s = S()
let _: (Float) -> Float = #gradient(of: s.a)
let _: (Double) -> Double = #gradient(of: s.a) // expected-error {{cannot convert value of type '(Float) -> Float' to specified type '(Double) -> Double'}}

// Gradient expressions with generic primal.
func e<T>(_ x: T) -> T {} // expected-note {{in call to function 'e'}}

let _ = #gradient(of: e) // expected-error {{generic parameter 'T' could not be inferred}}
let _: (Float) -> Float = #gradient(of: e)
let _: (Double) -> Double = #gradient(of: e)
let _: ((Float, Float)) -> (Float, Float) = #gradient(of: e) // expected-error {{cannot convert gradient expression to incompatible contextual type}}
let _: (Int) -> (Int) = #gradient(of: e) // expected-error {{cannot convert gradient expression to incompatible contextual type}}
let _: (Float) -> Double = #gradient(of: e) // expected-error {{cannot convert gradient expression to incompatible contextual type}}

// Complex type inference.
func add<T : FloatingPoint>(_ x: T, _ y: T) -> T {
  return x + y
}
func dadd<T : FloatingPoint>(_ x: T, _ y: T) -> (T, T) {
  return #gradient(of: add)(x, y) // ok
}
func daddWithValue<T : FloatingPoint>(
  _ x: T, _ y: T
) -> (value: T, gradient: (T, T)) {
  return #valueAndGradient(of: add)(x, y) // ok
}

func addNumeric<T : Numeric>(_ x: T, _ y: T) -> T { // expected-note {{in call to function 'addNumeric'}}
  return x + y
}
func daddNumeric<T : Numeric>(_ x: T, _ y: T) -> (T, T) {
  // TODO: improve diagnostic for this case.
  return #gradient(of: addNumeric)(x, y) // expected-error {{generic parameter 'T' could not be inferred}}
}
// Ok because the constraint on daddNumeric is FloatingPoint, not Numeric.
func daddFloatingPoint<T : FloatingPoint>(_ x: T, _ y: T) -> (T, T) {
  return #gradient(of: addNumeric)(x, y) // ok
}
