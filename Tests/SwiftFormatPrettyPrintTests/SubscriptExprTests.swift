public class SubscriptExprTests: PrettyPrintTestCase {
  public func testBasicSubscriptGetters() {
    let input =
      """
      let a = myCollection[index]
      let a = myCollection[label: index]
      let a = myCollection[index, default: someDefaultValue]
      """

    let expected =
      """
      let a = myCollection[index]
      let a = myCollection[label: index]
      let a = myCollection[
        index, default: someDefaultValue]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testBasicSubscriptSetters() {
    let input =
      """
      myCollection[index] = someValue
      myCollection[label: index] = someValue
      myCollection[index, default: someDefaultValue] = someValue
      """

    let expected =
      """
      myCollection[index] = someValue
      myCollection[label: index] = someValue
      myCollection[
        index, default: someDefaultValue]
        = someValue

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testSubscriptGettersWithTrailingClosures() {
    let input =
      """
      let a = myCollection[index] { $0 < $1 }
      let a = myCollection[label: index] { arg1, arg2 in foo() }
      let a = myCollection[index, default: someDefaultValue] { arg1, arg2 in foo() }
      """

    let expected =
      """
      let a = myCollection[index] { $0 < $1 }
      let a = myCollection[label: index] {
        arg1,
        arg2 in
        foo()
      }
      let a = myCollection[
        index, default: someDefaultValue
      ] { arg1, arg2 in
        foo()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testSubscriptSettersWithTrailingClosures() {
    let input =
    """
      myCollection[index] { $0 < $1 } = someValue
      myCollection[label: index] { arg1, arg2 in foo() } = someValue
      myCollection[index, default: someDefaultValue] { arg1, arg2 in foo() } = someValue
      """

    let expected =
    """
      myCollection[index] { $0 < $1 } = someValue
      myCollection[label: index] { arg1, arg2 in
        foo()
      } = someValue
      myCollection[
        index, default: someDefaultValue
      ] { arg1, arg2 in
        foo()
      } = someValue

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
