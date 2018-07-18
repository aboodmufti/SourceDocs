//
//  Generate.swift
//  SourceDocs
//
//  Created by Eneko Alonso on 10/19/17.
//

import Foundation
import Commandant
import Rainbow
import Result
import Curry
import SourceKittenFramework

struct GenerateCommandOptions: OptionsProtocol {
    let spmModule: String?
    let moduleName: String?
    let outputDirectory: String
    let sourceDirectory: String?
    let contentsFileName: String
    let includeModuleNameInPath: Bool
    let clean: Bool
    let collapsibleBlocks: Bool
    let tableOfContents: Bool
    let xcodeArguments: [String]

    static func evaluate(_ mode: CommandMode) -> Result<GenerateCommandOptions, CommandantError<SourceDocsError>> {
        return curry(self.init)
            <*> mode <| Option(key: "spm-module", defaultValue: nil,
                               usage: "Generate documentation for Swift Package Manager module.")
            <*> mode <| Option(key: "module-name", defaultValue: nil,
                               usage: "Generate documentation for a Swift module.")
            <*> mode <| Option(key: "output", defaultValue: SourceDocs.defaultOutputDirectory,
                               usage: "Output directory (defaults to \(SourceDocs.defaultOutputDirectory)).")
            <*> mode <| Option(key: "source", defaultValue: nil,
                               usage: "Output directory (defaults to the current directory).")
            <*> mode <| Option(key: "contents-filename", defaultValue: SourceDocs.defaultContentsFilename,
                               usage: "Output file (defaults to \(SourceDocs.defaultContentsFilename)).")
            <*> mode <| Switch(flag: "m", key: "module-name-path",
                               usage: "Include the module name as part of the output folder path.")
            <*> mode <| Switch(flag: "c", key: "clean",
                               usage: "Delete output folder before generating documentation.")
            <*> mode <| Switch(flag: "l", key: "collapsible",
                               usage: "Put methods, properties and enum cases inside collapsible blocks.")
            <*> mode <| Switch(flag: "t", key: "table-of-contents",
                               usage: "Generate a table of contents with properties and methods for each type.")
            <*> mode <| Argument(defaultValue: [], usage: "List of arguments to pass to xcodebuild.")
    }
}

struct GenerateCommand: CommandProtocol {
    typealias Options = GenerateCommandOptions

    private let markdownIndex = MarkdownIndex()
    private let initialPath = FileManager.default.currentDirectoryPath

    let verb = "generate"
    let function = "Generates the Markdown documentation"

    func run(_ options: GenerateCommandOptions) -> Result<(), SourceDocsError> {
        do {
            if let sourcePath = options.sourceDirectory {
                FileManager.default.changeCurrentDirectoryPath(NSString(string: sourcePath).expandingTildeInPath)
            }

            if let module = options.spmModule {
                let docs = try parseSPMModule(moduleName: module)
                try generateDocumentation(docs: docs, options: options, module: module)
            } else if let module = options.moduleName {
                let docs = try parseSwiftModule(moduleName: module, args: options.xcodeArguments)
                try generateDocumentation(docs: docs, options: options, module: module)
            } else {
                let docs = try parseXcodeProject(args: options.xcodeArguments)
                try generateDocumentation(docs: docs, options: options, module: "")
            }
            return Result.success(())
        } catch let error as SourceDocsError {
            return Result.failure(error)
        } catch let error {
            return Result.failure(SourceDocsError.internalError(message: error.localizedDescription))
        }
    }

    private func parseSPMModule(moduleName: String) throws -> [SwiftDocs] {
        guard let docs = Module(spmName: moduleName)?.docs else {
            let message = "Error: Failed to generate documentation for SPM module '\(moduleName)'."
            throw SourceDocsError.internalError(message: message)
        }
        return docs
    }

    private func parseSwiftModule(moduleName: String, args: [String]) throws -> [SwiftDocs] {
        guard let docs = Module(xcodeBuildArguments: args, name: moduleName)?.docs else {
            let message = "Error: Failed to generate documentation for module '\(moduleName)'."
            throw SourceDocsError.internalError(message: message)
        }
        return docs
    }

    private func parseXcodeProject(args: [String]) throws -> [SwiftDocs] {
        guard let docs = Module(xcodeBuildArguments: args, name: nil)?.docs else {
            throw SourceDocsError.internalError(message: "Error: Failed to generate documentation.")
        }
        return docs
    }

    private func generateDocumentation(docs: [SwiftDocs], options: GenerateCommandOptions, module: String = "") throws {
        FileManager.default.changeCurrentDirectoryPath(initialPath)

        let relativeDocsPath = options.includeModuleNameInPath ? "\(options.outputDirectory)/\(module)" : options.outputDirectory
        let docsPath = NSString(string: relativeDocsPath).expandingTildeInPath

        if options.clean {
            try CleanCommand.removeReferenceDocs(docsPath: docsPath)
        }

        process(docs: docs, options: options)
        try markdownIndex.write(to: docsPath, contentsFileName: options.contentsFileName)
    }

    private func process(docs: [SwiftDocs], options: GenerateCommandOptions) {
        let dictionaries = docs.compactMap { $0.docsDictionary.bridge() as? SwiftDocDictionary }
        process(dictionaries: dictionaries, options: options)
    }

    private func process(dictionaries: [SwiftDocDictionary], options: GenerateCommandOptions) {
        dictionaries.forEach { process(dictionary: $0, options: options) }
    }

    private func process(dictionary: SwiftDocDictionary, options: GenerateCommandOptions) {
        let markdownOptions = MarkdownOptions(collapsibleBlocks: options.collapsibleBlocks,
                                              tableOfContents: options.tableOfContents)

        if let value: String = dictionary.get(.kind), let kind = SwiftDeclarationKind(rawValue: value) {
            if kind == .struct, let item = MarkdownObject(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.structs.append(item)
            } else if kind == .class, let item = MarkdownObject(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.classes.append(item)
            } else if let item = MarkdownExtension(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.extensions.append(item)
            } else if let item = MarkdownEnum(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.enums.append(item)
            } else if let item = MarkdownProtocol(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.protocols.append(item)
            } else if let item = MarkdownTypealias(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.typealiases.append(item)
            }
        }

        if let substructure = dictionary[SwiftDocKey.substructure.rawValue] as? [SwiftDocDictionary] {
            process(dictionaries: substructure, options: options)
        }
    }

}
