public class RepeatStmtTests: PrettyPrintTestCase {
  public func testBasicRepeatTests() {
    let input =
      """
      repeat {
        let a = 123
        var b = "abc"
      } while condition
      repeat {
        let a = 123
        var b = "abc"
      } while condition && condition2
      """

    let expected =
      """
      repeat {
        let a = 123
        var b = "abc"
      } while condition
      repeat {
        let a = 123
        var b = "abc"
      } while condition &&
              condition2

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }
}
