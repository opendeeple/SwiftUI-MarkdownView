import SwiftUI
import Markdown

public enum MarkdownASTChildType {
    case root
    case singleLine
    case doubleLine
    case heading
    case paragraph
    case text
    case strong
    case italic
    case strikethrough
    case link
    case image
    case inlineCode
    case table
    case codeBlock
    case list
    case listItem
    case blockQuote
}

public protocol MarkdownASTNodeProtocol {
    var id: UUID { get }
    var type: MarkdownASTChildType { get }
    var children: [MarkdownASTNodeProtocol] { get set }
}

public struct MarkdownASTNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType
    public var children: [MarkdownASTNodeProtocol] = []
    
    public mutating func getFirst(of: MarkdownASTChildType) -> MarkdownASTNodeProtocol? {
        for child in children {
            if child.type == of {
                return child
            }
        }
        return nil
    }
    
    public mutating func removeFirst(of: MarkdownASTChildType) {
        for (index, child) in children.enumerated() {
            if child.type == of {
                remove(at: index)
                return
            }
        }

    }
    
    public mutating func remove(at: Int) {
        self.children.remove(at: at)
    }
    
    public mutating func getAll(of: MarkdownASTChildType) -> [MarkdownASTNodeProtocol] {
        var result: [MarkdownASTNodeProtocol] = []
        for child in children {
            if child.type == of {
                result.append(child)
            }
        }
        return result
    }
    
    public mutating func removeAll(of: MarkdownASTChildType) {
        children.removeAll { child in
            return child.type == of
        }
    }
    
    public mutating func clear() {
        children.removeAll()
    }
}

public struct MarkdownASTHeadingNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType = .heading
    public var children: [MarkdownASTNodeProtocol] = []
    public let level: Int
    public let text: String
}

public struct MarkdownASTParagraphNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType = .paragraph
    public var children: [MarkdownASTNodeProtocol] = []
}

public struct MarkdownASTParagraphStringNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType
    public var children: [MarkdownASTNodeProtocol] = []
    public let text: String
}

public struct MarkdownASTLinkNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType = .link
    public var children: [MarkdownASTNodeProtocol] = []
    public let text: String
    public let destination: String?
}

public struct MarkdownASTImageNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType = .image
    public var children: [MarkdownASTNodeProtocol] = []
    public let text: String
    public let source: String?
}

public struct MarkdownASTCodeBlockNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType = .codeBlock
    public var children: [MarkdownASTNodeProtocol] = []
    public let language: String?
    public let code: String
}

public enum MarkdownASTListModelListType {
    case ordered
    case unordered
}

public struct MarkdownASTListNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType = .list
    public var children: [MarkdownASTNodeProtocol] = []
    public let listType: MarkdownASTListModelListType
    public let depth: Int
}

public struct MarkdownASTListItemNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType = .listItem
    public var children: [MarkdownASTNodeProtocol] = []
    public var paragraph: MarkdownASTParagraphNode
}

public struct MarkdownASTTableNode: MarkdownASTNodeProtocol, Identifiable {
    public let id: UUID = UUID()
    public let type: MarkdownASTChildType = .table
    public var children: [MarkdownASTNodeProtocol] = []
    public var headers: [MarkdownASTParagraphNode] = []
    public var body: [[MarkdownASTParagraphNode]] = []
}

public struct MarkdownAST: MarkupVisitor {
    public var model: MarkdownASTNode = MarkdownASTNode(type: .root)
    
    public init() {}
    
    public mutating func defaultVisit(_ markup: Markup) {
        for child in markup.children {
            visit(child)
        }
    }
    
    public mutating func visitHeading(_ heading: Heading) {
        model.children.append(MarkdownASTHeadingNode(
            level: heading.level,
            text: heading.plainText
        ))
    }
    
    public mutating func visitParagraph(_ paragraph: Paragraph) {
        var ast = MarkdownParagraphAST()
        ast.defaultVisit(paragraph)
        model.children.append(MarkdownASTParagraphNode(
            children: ast.model.children
        ))
    }
    
    public mutating func visitTable(_ table: MarkdownTable) {
        var ast = MarkdownTableAST()
        ast.defaultVisit(table)
        model.children.append(MarkdownASTTableNode(
            children: ast.model.children,
            headers: ast.headers,
            body: ast.body
        ))
    }
    
    public mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let code = codeBlock.code
        var count = 0
        while count < code.count && code[code.index(code.startIndex, offsetBy: code.count - count - 1)] == " " {
            count += 1
        }
        model.children.append(MarkdownASTCodeBlockNode(
            language: codeBlock.language,
            code: String(code[..<code.index(code.startIndex, offsetBy: code.count - count - 1)])
        ))
    }
    
    public mutating func visitOrderedList(_ orderedList: OrderedList) {
        var ast = MarkdownListAST()
        ast.defaultVisit(orderedList)
        model.children.append(MarkdownASTListNode(
            children: ast.model.children,
            listType: .ordered,
            depth: 0
        ))
    }
    
    public mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        var ast = MarkdownListAST()
        ast.defaultVisit(unorderedList)
        model.children.append(MarkdownASTListNode(
            children: ast.model.children,
            listType: .unordered,
            depth: 0
        ))
    }
    
    public mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        var ast = MarkdownAST()
        ast.defaultVisit(blockQuote)
        model.children.append(MarkdownASTNode(
            type: .blockQuote,
            children: ast.model.children
        ))
    }
}

public struct MarkdownParagraphAST: MarkupVisitor {
    public var model: MarkdownASTNode = MarkdownASTNode(type: .paragraph)

    public mutating func defaultVisit(_ markup: Markup) {
        for child in markup.children {
            visit(child)
        }
    }
    
    public mutating func visitText(_ text: MarkdownText) {
        model.children.append(MarkdownASTParagraphStringNode(
            type: .text,
            text: text.plainText
        ))
    }
    
    public mutating func visitStrong(_ strong: Strong) {
        model.children.append(MarkdownASTParagraphStringNode(
            type: .strong,
            text: strong.plainText
        ))
    }
    
    public mutating func visitEmphasis(_ emphasis: Emphasis) {
        model.children.append(MarkdownASTParagraphStringNode(
            type: .italic,
            text: emphasis.plainText
        ))
    }
    
    public mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        var text = strikethrough.plainText
        if text[text.index(text.startIndex, offsetBy: 0)] == "~" {
            text = String(text[
                text.index(text.startIndex, offsetBy: 1) ..<
                text.index(text.endIndex, offsetBy: -1)
            ])
        }
        model.children.append(MarkdownASTParagraphStringNode(
            type: .strikethrough,
            text: text
        ))
    }
    
    public mutating func visitLink(_ link: MarkdownLink) {
        model.children.append(MarkdownASTLinkNode(
            text: link.plainText,
            destination: link.destination
        ))
    }
    
    public mutating func visitInlineCode(_ inlineCode: InlineCode) {
        model.children.append(MarkdownASTParagraphStringNode(
            type: .inlineCode,
            text: inlineCode.code
        ))
    }
    
    public mutating func visitImage(_ image: MarkdownImage) {
        model.children.append(MarkdownASTImageNode(
            text: image.title ?? image.plainText,
            source: image.source
        ))
    }
}

public struct MarkdownListAST: MarkupVisitor {
    public var depth: Int = 0
    public var model: MarkdownASTNode = MarkdownASTNode(type: .link)
    
    public mutating func defaultVisit(_ markup: Markup) {
        for child in markup.children {
            visit(child)
        }
    }
    
    public mutating func visitListItem(_ listItem: ListItem) {
        for child in listItem.blockChildren {
            if let child = child as? Paragraph {
                var ast = MarkdownParagraphAST()
                ast.defaultVisit(child)
                model.children.append(MarkdownASTListItemNode(
                    paragraph: MarkdownASTParagraphNode(
                        children: ast.model.children
                    )
                ))
            }
            else {
                visit(child)
            }
        }
    }
    
    public mutating func visitOrderedList(_ orderedList: OrderedList) {
        var ast = MarkdownListAST(depth: depth + 1)
        ast.defaultVisit(orderedList)
        model.children.append(MarkdownASTListNode(
            children: ast.model.children,
            listType: .ordered,
            depth: depth + 1
        ))
    }
    
    public mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        var ast = MarkdownListAST(depth: depth + 1)
        ast.defaultVisit(unorderedList)
        model.children.append(MarkdownASTListNode(
            children: ast.model.children,
            listType: .unordered,
            depth: depth + 1
        ))
    }
}

public struct MarkdownTableAST: MarkupVisitor {
    public var model: MarkdownASTNode = MarkdownASTNode(type: .table)
    public var headers: [MarkdownASTParagraphNode] = []
    public var body: [[MarkdownASTParagraphNode]] = []
    
    public mutating func defaultVisit(_ markup: Markup) {
        for child in markup.children {
            visit(child)
        }
    }
    
    public mutating func visitTableHead(_ tableHead: MarkdownTable.Head) {
        for child in tableHead.children {
            if let child = child as? MarkdownTable.Cell {
                var ast = MarkdownParagraphAST()
                ast.defaultVisit(child)
                headers.append(MarkdownASTParagraphNode(
                    children: ast.model.children
                ))
            }
        }
    }
    
    public mutating func visitTableRow(_ tableRow: MarkdownTable.Row) {
        body.append([])
        for child in tableRow.children {
            visit(child)
        }
    }
    
    public mutating func visitTableCell(_ tableCell: MarkdownTable.Cell) {
        var ast = MarkdownParagraphAST()
        ast.defaultVisit(tableCell)
        let value = MarkdownASTParagraphNode(
            children: ast.model.children
        )
        body[body.count - 1].append(value)
        model.children.append(value)
    }
}
