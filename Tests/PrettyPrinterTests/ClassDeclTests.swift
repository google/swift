public class ClassDeclTests: PrettyPrintTestCase {
  public func testBasicClassDeclarations() {
    let input =
      """
      class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyLongerClass {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyClass {
        let A: Int
        let B: Bool
      }
      public class
      MyLongerClass {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  public func testGenericClassDeclarations() {
    let input =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<One, Two, Three, Four> {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<
        One,
        Two,
        Three,
        Four
      > {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testClassInheritence() {
    let input =
      """
      class MyClass: SuperOne {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo, SuperThree {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass: SuperOne {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo {
        let A: Int
        let B: Bool
      }
      class MyClass:
        SuperOne,
        SuperTwo,
        SuperThree
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testClassWhereClause() {
    let input =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName, U: LongerClassName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where
        S: Collection,
        T: ReallyLongClassName,
        U: LongerClassName
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testClassWhereClauseWithInheritence() {
    let input =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testClassFullWrap() {
    let input =
      """
      public class MyContainer<BaseCollection, SecondCollection>: MyContainerSuperclass, MyContainerProtocol, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public class MyContainer<
        BaseCollection,
        SecondCollection
      >:
        MyContainerSuperclass,
        MyContainerProtocol,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }
}
