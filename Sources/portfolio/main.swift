import Foundation
import ArgumentParser
import Stencil
import PathKit

struct PortfolioGen: ParsableCommand {
    
    @Argument(help: "folder containing portfolio folder with root folder")
    var sourceFolder: String
    
    @Option(help: "google analytics tracking code")
    var gatcode: String?
    
    mutating func run() throws {
        print("Run Portfolio sourceFolder = \(sourceFolder)")
        let contents = try contentOfDirectory(name: sourceFolder)
        guard contents.filter({ $0.isDirectory }).count == 1 else {
            print("More folde(s are found, organ)ize sequences with a single root folder.")
            return
        }
        
        let rootFolderURL = contents.first { $0.isDirectory }!
        let contentsOfRoot = try contentOfDirectory(url: rootFolderURL)
        print("Contents of \(rootFolderURL):")
        var sequences: [Sequence] = []
        try contentsOfRoot.forEach { url in
            if url.isDirectory {
                let directoryContents = try contentOfDirectory(url: url)
                var urlImages: [String] = []
                var description: String?
                try directoryContents.forEach { url in
                    if url.isImage {
                        let range = url.absoluteString.range(of: rootFolderURL.lastPathComponent)
                        let urlImage = String(url.absoluteString.suffix(from: range!.lowerBound))
                        urlImages.append(urlImage)
                    } else if url.lastPathComponent.hasSuffix("description.txt") {
                        description = try String(contentsOf: url, encoding: .utf8)
                    }
                }
                let sequence = Sequence(
                    title: url.lastPathComponent,
                    images: urlImages.sorted { $0 < $1 },
                    description: description ?? ""
                )
                print("Add sequence \(sequence)")
                sequences.append(sequence)
            }
        }
        let portfolio = Portfolio(title: rootFolderURL.lastPathComponent,
                                  sequences: sequences.sorted { $0.title < $1.title },
                                  googleAnalyticsTrackingCode: gatcode
        )
        
        let sourceFolderURL = URL(fileURLWithPath: sourceFolder)
        let menuItems = portfolio.sequences.menuItems()
        for (index, sequence) in portfolio.sequences.enumerated() {
            let filePageName = sequence.pageFilename(isIndex: index == 0)
            let filePath =  sourceFolderURL.appendingPathComponent(filePageName)
            let renderedSequence = try render(
                portfolio: portfolio,
                sequence: sequence,
                menuItems: menuItems
            )
            try renderedSequence.write(to: filePath, atomically: false, encoding: .utf8)
        }
        print("Portfolio generated.")
    }
    
    private func render(portfolio: Portfolio, sequence: Sequence, menuItems: [MenuItem]) throws -> String {
        let fs = FileSystemLoader(paths: [ Path("templates/") ])
        let ext = Extension()
        ext.registerFilter("parse") { (value: Any?, arguments: [Any?]) in
            let urlRegEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
            if let value = value as? String {
                let matches = value.match(urlRegEx)
                var decorated = value
                matches.forEach { url in
                    decorated = decorated.replacingOccurrences(
                        of: url,
                        with: "<a href=\"\(url)\">\(url)</a>")
                }
                return decorated
            }
            return value
        }
        
        let environment = Environment(loader: fs, extensions: [ext])
        return try environment.renderTemplate(
            name: "sequence.html",
            context: ["portfolio": portfolio,
                      "sequence": sequence,
                      "menuItems": menuItems.sorted { $0.title < $1.title }.map { $0.viewModel() } ]
        )
    }
    
    private mutating func createFolder(name: String) throws -> URL? {
        let folder = URL(fileURLWithPath: "./\(name)")
        try FileManager.default.createDirectory(at: folder,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        return folder
    }
    
    private mutating func contentOfDirectory(url: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
    
    private mutating func contentOfDirectory(name: String) throws -> [URL] {
        let folder = URL(fileURLWithPath: "./\(name)")
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
    }
}

PortfolioGen.main()

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    var isImage: Bool {
        lastPathComponent.hasSuffix(".jpg") ||
        lastPathComponent.hasSuffix(".png") ||
        lastPathComponent.hasSuffix(".jpeg")
    }
}

extension String {
    func match(_ regex: String) -> [String] {
        let nsString = self as NSString
        return (try? NSRegularExpression(pattern: regex, options: []))?.matches(
            in: self,
            options: [],
            range: NSMakeRange(0, nsString.length)
        ).map { match in
            return nsString.substring(with: match.range)
        } ?? []
    }
}
