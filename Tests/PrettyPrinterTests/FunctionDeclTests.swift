public class FunctionDeclTests: PrettyPrintTestCase {
  public func testBasicFunctionDeclarations() {
    let input =
      """
      func myFun(var1: Int, var2: Double) {
        print("Hello World")
        let a = 23
      }
      func reallyLongName(var1: Int, var2: Double, var3: Bool) {
        print("Hello World")
        let a = 23
      }
      func myFun() {
        let a = 23
      }
      func myFun() { let a = "AAAA BBBB CCCC DDDD EEEE FFFF" }
      """

    let expected =
      """
      func myFun(var1: Int, var2: Double) {
        print("Hello World")
        let a = 23
      }
      func reallyLongName(
        var1: Int,
        var2: Double,
        var3: Bool
      ) {
        print("Hello World")
        let a = 23
      }
      func myFun() { let a = 23 }
      func myFun() {
        let a = "AAAA BBBB CCCC DDDD EEEE FFFF"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testFunctionDeclReturns() {
    let input =
      """
      func myFun(var1: Int, var2: Double) -> Double {
        print("Hello World")
        return 1.0
      }
      func reallyLongName(var1: Int, var2: Double, var3: Bool) -> Double {
        print("Hello World")
        return 1.0
      }
      """

    let expected =
      """
      func myFun(var1: Int, var2: Double) -> Double {
        print("Hello World")
        return 1.0
      }
      func reallyLongName(
        var1: Int,
        var2: Double,
        var3: Bool
      ) -> Double {
        print("Hello World")
        return 1.0
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testFunctionGenericParameters() {
    let input =
    """
    func myFun<S, T>(var1: S, var2: T) {
      let a = 123
      print("Hello World")
    }

    func longerNameFun<ReallyLongTypeName: Conform, TypeName>(var1: ReallyLongTypeNAme, var2: TypeName) {
      let a = 123
      let b = 456
    }
    """

    let expected =
    """
    func myFun<S, T>(var1: S, var2: T) {
      let a = 123
      print("Hello World")
    }

    func longerNameFun<
      ReallyLongTypeName: Conform,
      TypeName
    >(
      var1: ReallyLongTypeNAme,
      var2: TypeName
    ) {
      let a = 123
      let b = 456
    }

    """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testFunctionWhereClause() {
    let input =
    """
    public func index<Elements: Collection, Element>(
      of element: Element,
      in collection: Elements
    ) -> Elements.Index? where Elements.Element == Element {
      let a = 123
      let b = "abc"
    }

    public func index<Elements: Collection, Element>(
      of element: Element,
      in collection: Elements
    ) -> Elements.Index? where Elements.Element == Element, Element: Equatable {
      let a = 123
      let b = "abc"
    }
    """

    let expected =
    """
    public func index<Elements: Collection, Element>(
      of element: Element,
      in collection: Elements
    ) -> Elements.Index?
    where Elements.Element == Element {
      let a = 123
      let b = "abc"
    }

    public func index<Elements: Collection, Element>(
      of element: Element,
      in collection: Elements
    ) -> Elements.Index?
    where
      Elements.Element == Element,
      Element: Equatable
    {
      let a = 123
      let b = "abc"
    }

    """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testFunctionFullWrap() {
    let input =
    """
    public func index<Elements: Collection, Element>(of element: Element, in collection: Elements) -> Elements.Index? where Elements.Element == Element, Element: Equatable {
      let a = 123
      let b = "abc"
    }
    """

    let expected =
    """
    public func index<
      Elements: Collection,
      Element
    >(
      of element: Element,
      in collection: Elements
    ) -> Elements.Index?
    where
      Elements.Element == Element,
      Element: Equatable
    {
      let a = 123
      let b = "abc"
    }

    """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }
}
