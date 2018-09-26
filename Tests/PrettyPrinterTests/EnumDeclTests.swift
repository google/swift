public class EnumDeclTests: PrettyPrintTestCase {
  public func testBasicEnumDeclarations() {
    let input =
      """
      enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyLongerEnum {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum
      MyLongerEnum {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  public func testMixedEnumCaseStyles() {
    let input =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth, fifth
        case sixth(Int)
        case seventh(a: Int, b: Bool, c: Double)
      }
      """

    let expected =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth,
          fifth
        case sixth(Int)
        case seventh(
          a: Int,
          b: Bool,
          c: Double
        )
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testIndirectEnum() {
    let input =
      """
      enum MyEnum {
        indirect case first
        case second
      }
      indirect enum MyEnum {
        case first
        case second
      }
      public indirect enum MyEnum {
        case first
        case second
      }
      """

    let expected =
      """
      enum MyEnum {
        indirect case first
        case second
      }
      indirect enum MyEnum {
        case first
        case second
      }
      public indirect enum MyEnum {
        case first
        case second
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testGenericEnumDeclarations() {
    let input =
      """
      enum MyEnum<T> {
        case firstCase
        case secondCase
      }
      enum MyEnum<T, S> {
        case firstCase
        case secondCase
      }
      enum MyEnum<One, Two, Three, Four> {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum<T> {
        case firstCase
        case secondCase
      }
      enum MyEnum<T, S> {
        case firstCase
        case secondCase
      }
      enum MyEnum<
        One,
        Two,
        Three,
        Four
      > {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testEnumInheritence() {
    let input =
      """
      enum MyEnum: ProtoOne {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo, ProtoThree {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum: ProtoOne {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo {
        case firstCase
        case secondCase
      }
      enum MyEnum:
        ProtoOne,
        ProtoTwo,
        ProtoThree
      {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testEnumWhereClause() {
    let input =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where
        S: Collection,
        T: ReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testEnumWhereClauseWithInheritence() {
    let input =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection,
        T: Protocol
      {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testEnumFullWrap() {
    let input =
      """
      public enum MyEnum<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        case firstCase
        let B: Double
      }
      """

    let expected =

      """
      public enum MyEnum<
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
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }
}
