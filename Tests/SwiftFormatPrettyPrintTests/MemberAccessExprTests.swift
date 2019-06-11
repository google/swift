public class MemberAccessExprTests: PrettyPrintTestCase {
  public func testMemberAccess() {
    let input =
      """
      let a = one.two.three.four.five
      let b = (c as TypeD).one.two.three.four
      """

    let expected =
      """
      let a = one.two
        .three.four
        .five
      let b = (
        c as TypeD
      ).one.two.three
        .four

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }
}
