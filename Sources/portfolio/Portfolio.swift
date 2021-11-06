import Foundation

struct Portfolio: Decodable {
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
