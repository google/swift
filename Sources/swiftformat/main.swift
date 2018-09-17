//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Formatter open source project.
//
// Copyright (c) 2018 Apple Inc. and the Swift Formatter project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Formatter project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Basic
import Core
import Utility

enum Mode: String, Codable, ArgumentKind {
  case format
  case lint
  case version

  static var completion: ShellCompletion {
    return .values([
      ("format", "Format the provided files."),
      ("lint", "Lint the provided files."),
    ])
  }

  init(argument: String) throws {
    guard let mode = Mode(rawValue: argument) else {
      throw ArgumentParserError.invalidValue(argument: argument, error: .unknown(value: argument))
    }
    self = mode
  }
}

struct CommandLineOptions: Codable {
  var configurationPath = ""
  var paths: [String] = []
  var verboseLevel = 0
  var mode: Mode = .format
  var isDebugMode: Bool = false
}

func processArguments(commandName: String, _ arguments: [String]) -> CommandLineOptions {
  let parser = ArgumentParser(commandName: commandName,
                              usage: "[options] <filename or path> ...",
                              overview: "Format or lint Swift source code.")
  let binder = ArgumentBinder<CommandLineOptions>()
  binder.bind(
    option: parser.add(
      option: "--mode",
      shortName: "-m",
      kind: Mode.self,
      usage: "The mode to run swift-format in. Either 'format' or 'lint'."
  )) {
    $0.mode = $1
  }
  binder.bind(
    option: parser.add(
      option: "--version",
      shortName: "-v",
      kind: Bool.self,
      usage: "Prints the version and exists"
  )) { opts, _ in
    opts.mode = .version
  }
  binder.bindArray(
    positional: parser.add(
      positional: "filenames or paths",
      kind: [String].self,
      strategy: .upToNextOption,
      usage: "One or more input filenames",
      completion: .filename
  )) {
    $0.paths = $1
  }
  binder.bind(
    option: parser.add(
      option: "--debug",
      shortName: "-d",
      kind: Bool.self,
      usage: "Annotates the formatted output to assist with debugging the formatter."
  )) {
    $0.isDebugMode = $1
  }

  var opts = CommandLineOptions()
  do {
    let args = try parser.parse(arguments)
    binder.fill(args, into: &opts)
  } catch {
    stderrStream.write("error: \(error)\n\n")
    parser.printUsage(on: stderrStream)
    exit(1)
  }
  return opts
}

func main(_ arguments: [String]) -> Int32 {
  let url = URL(fileURLWithPath: arguments.first!)
  let options = processArguments(commandName: url.lastPathComponent, Array(arguments.dropFirst()))
  switch options.mode {
  case .format:
    var ret = 0
    for path in options.paths {
      ret |= formatMain(path: path, isDebugMode: options.isDebugMode)
    }
    return Int32(ret)
  case .lint:
    var ret = 0
    for path in options.paths {
      ret |= lintMain(path: path)
    }
    return Int32(ret)
  case .version:
    print("0.0.1") // TODO(abl): Something fancy based on the git hash
    return 0
  }
}

exit(main(CommandLine.arguments))
