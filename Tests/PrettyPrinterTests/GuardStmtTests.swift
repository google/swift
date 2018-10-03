public class GuardStmtTests: PrettyPrintTestCase {
  public func testGuardStatement() {
    let input =
      """
      guard var1 > var2 else {
        let a = 23
        var b = "abc"
      }
      guard var1, var2 > var3 else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(), let var2 = myFun() else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(), let var2 = myLongFunction() else {
        let a = 23
        var b = "abc"
      }
      """

    let expected =
      """
      guard var1 > var2 else {
        let a = 23
        var b = "abc"
      }
      guard var1, var2 > var3 else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(),
            let var2 = myFun() else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(),
            let var2 = myLongFunction()
      else {
        let a = 23
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }
}
