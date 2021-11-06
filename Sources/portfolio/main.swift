import Foundation
import ArgumentParser
import Stencil
import PathKit

struct Portfolio: ParsableCommand {
    
    @Argument(help: "folder containing portfolio.json and images")
    var sourceFolder: String
    
    mutating func run() throws {
        print("Run Portfolio.")
        let portfolioFileName = "portfolio.json"
        let contents = try contentdOfDirectory(name: sourceFolder)
        contents.forEach {
            print("\($0.absoluteString)")
        }
        let portfolioURL = contents.first { $0.absoluteString.contains(portfolioFileName)}
        guard let url = portfolioURL else {
            print("\(portfolioFileName) cannot found.")
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            print("\(url) not found...")
            return
        }
        let decoder = JSONDecoder()
        guard let portfolio = try? decoder.decode(Port.self, from: data) else {
            print("Cannot decode \(url)")
            return
        }
        
        print("\(portfolio)")
        let sourceFolderURL = URL(fileURLWithPath: sourceFolder)
        let menuItems = portfolio.sequences.menuItems()
        for (index, sequence) in portfolio.sequences.enumerated() {
            let filePageName = sequence.pageFilename(isIndex: index == 0)
            let filePath =  sourceFolderURL.appendingPathComponent(filePageName)
            let renderedSequence = try render(sequence: sequence, menuItems: menuItems)
            try renderedSequence.write(to: filePath, atomically: false, encoding: .utf8)
        }
    }
    
    private func render(sequence: Sequence, menuItems: [MenuItem]) throws -> String {
        let fs = FileSystemLoader(paths: [ Path("templates/") ])
        let environment = Environment(loader: fs)
        return try environment.renderTemplate(
            name: "sequence.html",
            context: ["sequence" : sequence, "menuItems" : menuItems]
        )
    }
    
    private mutating func createFolder(name: String) throws -> URL? {
        let folder = URL(fileURLWithPath: "./\(name)")
        try FileManager.default.createDirectory(at: folder,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        return folder
    }
    
    private mutating func contentdOfDirectory(name: String) throws -> [URL] {
        let folder = URL(fileURLWithPath: "./\(name)")
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
    }
    
   
}

struct Port: Decodable {
    let title: String
    let sequences: [Sequence]
}

struct Sequence: Decodable {
    let title: String
    let images: [String]
}

extension Sequence {
    func pageFilename(isIndex: Bool = false) -> String {
        
        isIndex ? "index.html" : "\(title.replacingOccurrences(of: " ", with: "_")).html"
    }
    
    func menuItem(isIndex: Bool = false) -> MenuItem {
        return MenuItem(title: title, href: pageFilename(isIndex: isIndex))
    }
}

extension Array where Element == Sequence {
    func menuItems() -> [MenuItem] {
        return enumerated().map { $1.menuItem(isIndex: $0 == 0) }
    }
}

struct MenuItem {
    let title: String
    let href: String
}



Portfolio.main()

