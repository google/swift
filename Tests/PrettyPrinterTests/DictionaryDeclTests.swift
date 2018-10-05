public class DictionaryDeclTests: PrettyPrintTestCase {
  public func testBasicDictionaries() {
    let input =
      """
      let a = [1: "a", 2: "b", 3: "c"]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c"]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c", 4: "d"]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f", 7: "g"]
      """

    let expected =
      """
      let a = [1: "a", 2: "b", 3: "c"]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c"]
      let a: [Int: String] = [
        1: "a", 2: "b", 3: "c", 4: "d"
      ]
      let a: [Int: String] = [
        1: "a",
        2: "b",
        3: "c",
        4: "d",
        5: "e",
        6: "f",
        7: "g"
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }
}
