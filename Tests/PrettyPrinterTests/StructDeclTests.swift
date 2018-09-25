public class StructDeclTests: PrettyPrintTestCase {
  public func testBasicStructDeclarations() {
    let input =
      """
      struct MyStruct {
        let A: Int
        let B: Bool
      }
      public struct MyStruct {
        let A: Int
        let B: Bool
      }
      public struct MyLongerStruct {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      struct MyStruct {
        let A: Int
        let B: Bool
      }
      public struct MyStruct {
        let A: Int
        let B: Bool
      }
      public struct
      MyLongerStruct {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  public func testGenericStructDeclarations() {
    let input =
      """
      struct MyStruct<T> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<T, S> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<One, Two, Three, Four> {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      struct MyStruct<T> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<T, S> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<
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

  public func testStructInheritence() {
    let input =
      """
      struct MyStruct: ProtoOne {
        let A: Int
        let B: Bool
      }
      struct MyStruct: ProtoOne, ProtoTwo {
        let A: Int
        let B: Bool
      }
      struct MyStruct: ProtoOne, ProtoTwo, ProtoThree {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      struct MyStruct: ProtoOne {
        let A: Int
        let B: Bool
      }
      struct MyStruct: ProtoOne, ProtoTwo {
        let A: Int
        let B: Bool
      }
      struct MyStruct:
        ProtoOne,
        ProtoTwo,
        ProtoThree
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testStructWhereClause() {
    let input =
      """
      struct MyStruct<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T> where S: Collection, T: ReallyLongStructName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      struct MyStruct<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>
      where
        S: Collection,
        T: ReallyLongStructName
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testStructWhereClauseWithInheritence() {
    let input =
      """
      struct MyStruct<S, T>: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      struct MyStruct<S, T>: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection,
        T: Protocol
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testStructFullWrap() {
    let input =
      """
      public struct MyContainer<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public struct MyContainer<
        BaseCollection,
        SecondCollection
      >:
        MyContainerProtocolOne,
        MyContainerProtocolTwo,
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
