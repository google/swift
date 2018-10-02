public class SwitchStmtTests: PrettyPrintTestCase {
  public func testBasicSwitch() {
    let input =
      """
      switch someCharacter {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      switch value1 + value2 + value3 + value4 {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      """

    let expected =
      """
      switch someCharacter {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      switch value1 + value2 + value3 +
             value4 {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  public func testSwitchCases() {
    let input =
      """
      switch someCharacter {
      case value1 + value2 + value3 + value4:
        let a = 1 + 2
      default:
        print("Some other character")
      }
      """

    let expected =
      """
      switch someCharacter {
      case value1 + value2 + value3 +
           value4:
        let a = 1 + 2
      default:
        print("Some other character")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }
}
