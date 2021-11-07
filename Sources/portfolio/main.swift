import Foundation
import ArgumentParser
import Stencil
import PathKit

struct PortfolioGen: ParsableCommand {

    @Argument(help: "folder containing portfolio.json and images")
    var sourceFolder: String

    mutating func run() throws {
        print("Run Portfolio sourceFolder = \(sourceFolder)")
        let portfolioFileName = "portfolio.json"
        let contents = try contentdOfDirectory(name: sourceFolder)
        
        guard contents.filter { $0.isDirectory }.count == 1 else {
            print("More folders are found, organize sequences with a single root folder.")
            return
        }
        
        let rootFolderURL = contents.first { $0.isDirectory }!
        let contentsOfRoot = try contentdOfDirectory(url: rootFolderURL)
        print("Contents of \(rootFolderURL):")
        var sequences:[Sequence] = []
        try contentsOfRoot.forEach { url in
            let name = url.absoluteURL.lastPathComponent
            if url.isDirectory {
                let directoryContents = try contentdOfDirectory(url: url)
                var urlImages: [String] = []
                directoryContents.forEach { url in
                    if url.isImage {
                        let range = url.absoluteString.range(of: rootFolderURL.lastPathComponent)
                        let urlImage = String(url.absoluteString.suffix(from: range!.lowerBound))
                        urlImages.append(urlImage)
                    }
                }
                let sequence = Sequence(
                    title: "\(url.lastPathComponent.replacingOccurrences(of: "_", with: " "))",
                    images: urlImages,
                    short: ""
                )
                print("Add sequence \(sequence)")
                sequences.append(sequence)
            }
        }
        let portfolio = Portfolio(title: rootFolderURL.lastPathComponent, sequences: sequences)
       
        

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
        let environment = Environment(loader: fs)
        return try environment.renderTemplate(
            name: "sequence.html",
            context: ["portfolio" : portfolio,
                      "sequence": sequence,
                      "menuItems": menuItems]
        )
    }

    private mutating func createFolder(name: String) throws -> URL? {
        let folder = URL(fileURLWithPath: "./\(name)")
        try FileManager.default.createDirectory(at: folder,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        return folder
    }

    private mutating func contentdOfDirectory(url: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
    
    private mutating func contentdOfDirectory(name: String) throws -> [URL] {
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
