public class ForInStmtTests: PrettyPrintTestCase {
  public func testBasicForLoop() {
    let input =
      """
      for i in mycontainer {
        let a = 123
        let b = i
      }

      for item in mylargecontainer {
        let a = 123
        let b = item
      }
      """

    let expected =
      """
      for i in mycontainer {
        let a = 123
        let b = i
      }

      for item in
          mylargecontainer {
        let a = 123
        let b = item
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  public func testForWhereLoop() {
    let input =
      """
      for i in array where array.isContainer() {
        let a = 123
        let b = 456
      }
      for i in longerarray where longerarray.isContainer() {
        let a = 123
        let b = 456
      }
      for i in longerarray where longerarray.isContainer() && anotherCondition {
        let a = 123
        let b = 456
      }
      """

    let expected =
      """
      for i in array where array.isContainer() {
        let a = 123
        let b = 456
      }
      for i in longerarray
      where longerarray.isContainer() {
        let a = 123
        let b = 456
      }
      for i in longerarray
      where longerarray.isContainer() &&
        anotherCondition
      {
        let a = 123
        let b = 456
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testForLoopFullWrap() {
    let input =
      """
      for item in aVeryLargeContainterObject where aVeryLargeContainerObject.hasProperty() {
        let a = 123
        let b = 456
      }
      """

    let expected =
      """
      for item in
          aVeryLargeContainterObject
      where
        aVeryLargeContainerObject.hasProperty()
      {
        let a = 123
        let b = 456
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }
}
