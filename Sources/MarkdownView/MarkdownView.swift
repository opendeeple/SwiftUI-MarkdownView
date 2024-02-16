import SwiftUI

public struct MarkdownView: View {
    public var node: MarkdownASTNode
    public var fontSize: CGFloat = 16.0
    public var horizontalPadding: Double = 14
    public var verticalSpacing: Double = 12

    public init(node: MarkdownASTNode) {
        self.node = node
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            ForEach(Array(zip(node.children.indices, node.children)), id: \.0) { _, child in
                switch child.type {
                case .heading: MarkdownHeadingView(node: child as! MarkdownASTHeadingNode)
                case .paragraph: MarkdownParagraphView(node: child as! MarkdownASTParagraphNode)
                case .table: MarkdownTableView(node: child as! MarkdownASTTableNode)
                case .codeBlock: MarkdownCodeBlockView(node: child as! MarkdownASTCodeBlockNode)
                case .list: MarkdownListView(node: child as! MarkdownASTListNode)
                case .blockQuote: MarkdownBlockQuoteView(node: child)
                default: EmptyView()
                }
            }
        }
    }
}

public struct MarkdownHeadingView: View {
    public  var node: MarkdownASTHeadingNode
    private var mobileSizes: [CGFloat] = [24, 20, 18, 16, 16, 16]
    private var mobileLineHeights: [CGFloat] = [24, 22, 20, 18, 16, 16]
    private var letterSpacing: [CGFloat] = [-1, -0.8, -0.5, -0.4, -0.2, -0.1]
    private var tabletSizes: [CGFloat] = [34, 24, 20, 18, 16, 16]
    private var tabletLineHeights: [CGFloat] = [34, 26, 22, 20, 18, 16]
    public var horizontalPadding: Double = 14
    
    public init(node: MarkdownASTHeadingNode) {
        self.node = node
    }
    
    public var body: some View {
        var size: CGFloat
        var lineHeight: CGFloat
        let letterSpacing: CGFloat = letterSpacing[node.level - 1]
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            size = mobileSizes[node.level - 1]
            lineHeight = mobileLineHeights[node.level - 1]
        }
        else {
            size = tabletSizes[node.level - 1]
            lineHeight = tabletLineHeights[node.level - 1]
        }
        
        return VStack(alignment: .leading) {
            SwiftUIText(node.text)
                .font(.system(size: size))
                .fontWeight(.bold)
                .lineSpacing(lineHeight)
                .kerning(letterSpacing)
                .padding(.horizontal, horizontalPadding)
            Divider()
        }
    }
}

public struct MarkdownImageView: View {
    public var source: String
    public init(source: String) {
        self.source = source
    }
    public var body: some View {
        AsyncImage(url: URL(string: source)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .listRowInsets(EdgeInsets())
            default:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }
}

public struct MarkdownParagraphView: View {
    public var node: MarkdownASTParagraphNode
    public var fontSize = 16.0
    public var horizontalPadding: Double = 14
    
    public init(node: MarkdownASTParagraphNode, horizontalPadding: Double = 14) {
        self.node = node
        self.horizontalPadding = horizontalPadding
    }
    
    public var body: some View {
        var views: [AnyView] = []
        var string = AttributedString()
        for child in node.children {
            switch child.type {
            case .text: string.append(buildText(child as! MarkdownASTParagraphStringNode))
            case .strong: string.append(buildStrong(child as! MarkdownASTParagraphStringNode))
            case .italic: string.append(buildItalic(child as! MarkdownASTParagraphStringNode))
            case .strikethrough: string.append(buildStrikethrough(child as! MarkdownASTParagraphStringNode))
            case .link: string.append(buildLink(child as! MarkdownASTLinkNode))
            case .image:
                views.append(AnyView(
                    Text(string)
                        .font(.system(size: fontSize))
                        .padding(.horizontal, horizontalPadding)
                ))
                string = AttributedString()
                views.append(buildImage(child as! MarkdownASTImageNode))
            case .inlineCode: string.append(buildInlineCode(child as! MarkdownASTParagraphStringNode))
            default:
                continue
            }
        }
        views.append(AnyView(
            Text(string)
                .font(.system(size: fontSize))
                .padding(.horizontal, horizontalPadding)
        ))
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(zip(views.indices, views)), id: \.0) { _, view in
                view
            }
        }
    }
    
    private func buildText(_ string: MarkdownASTParagraphStringNode) -> AttributedString {
        var text = AttributedString(string.text)
        text.font = .systemFont(ofSize: fontSize)
        return text
    }
    
    private func buildStrong(_ string: MarkdownASTParagraphStringNode) -> AttributedString {
        var text = AttributedString(string.text)
        text.font = .systemFont(ofSize: fontSize, weight: .bold)
        return text
    }
    
    private func buildItalic(_ string: MarkdownASTParagraphStringNode) -> AttributedString {
        var text = AttributedString(string.text)
        text.font = .italicSystemFont(ofSize: fontSize)
        return text
    }
    
    private func buildStrikethrough(_ string: MarkdownASTParagraphStringNode) -> AttributedString {
        var text = AttributedString(string.text)
        text.strikethroughStyle = .single
        return text
    }
    
    private func buildLink(_ link: MarkdownASTLinkNode) -> AttributedString {
        var text = AttributedString(link.text)
        text.foregroundColor = Color.blue
        let destination = link.destination ?? link.text
        text.link = URL(string: destination)
        return text
    }
    
    private func buildInlineCode(_ string: MarkdownASTParagraphStringNode) -> AttributedString {
        var code = AttributedString(string.text)
        code.font = .monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
        code.foregroundColor = .systemGray
        return code
    }
    
    private func buildImage(_ child: MarkdownASTImageNode) -> AnyView {
        if let source = child.source {
            return AnyView(MarkdownImageView(source: source))
        }
        return AnyView(EmptyView())
    }
}

public struct MarkdownTableView: View {
    public var node: MarkdownASTTableNode
    public var fontSize = 16.0
    public var horizontalPadding: Double = 14
    public var verticalSpacing: Double = 12

    public var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing / 2) {
            Divider()
            ForEach(Array(zip(node.body.indices, node.body)), id: \.0) { _, row in
                buildListItem(row)
                    .padding(.horizontal, horizontalPadding)
                Divider()
            }
        }
    }
    
    private func buildListItem(_ row: [MarkdownASTParagraphNode]) -> some View {
        VStack(alignment: .leading, spacing: verticalSpacing / 2) {
            ForEach(Array(zip(row.indices, row)), id: \.0) { index, paragraph in
                HStack(alignment: .top) {
                    MarkdownParagraphView(node: node.headers[index], horizontalPadding: 0).fontWeight(.bold)
                    MarkdownParagraphView(node: paragraph, horizontalPadding: 0)
                }
            }
        }
    }
}

public struct MarkdownCodeBlockView: View {
    public var node: MarkdownASTCodeBlockNode
    public var fontSize: Double = 16.0
    public var horizontalPadding: Double = 14
    
    public var body: some View {
        var code = AttributedString(node.code)
        code.font = .monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
        code.foregroundColor = .systemGray
        return ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .padding(.horizontal, horizontalPadding)
        }
    }
}

public struct MarkdownListView: View {
    public var node: MarkdownASTListNode
    public var fontSize: Double = 16.0
    public var horizontalPadding: Double = 14
    public var verticalSpacing: Double = 12
    
    public var body: some View {
        var prefix = ""
        var depth = node.depth
        var views: [AnyView] = []
        while depth != 0 {
            prefix += "\t"
            depth -= 1
        }
        for (index, child) in node.children.enumerated() {
            if let child = child as? MarkdownASTListItemNode {
                var string = AttributedString(prefix)
                if node.listType == .ordered {
                    string.append(AttributedString("\(index + 1). "))
                }
                else {
                    string.append(AttributedString("• "))
                }
                views.append(AnyView(HStack(alignment: .top, spacing: 0) {
                    Text(string).font(.system(size: fontSize))
                    MarkdownParagraphView(node: child.paragraph, horizontalPadding: 0)
                }))
            }
            else if let child = child as? MarkdownASTListNode {
                views.append(AnyView(
                    MarkdownListView(node: child, horizontalPadding: 0)
                ))
            }
        }
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(zip(views.indices, views)), id: \.0) { _, view in
                view
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
}

public struct MarkdownBlockQuoteView: View {
    public var node: MarkdownASTNodeProtocol
    public var fontSize: Double = 16.0
    public var horizontalPadding: Double = 14
    public var verticalSpacing: Double = 12
    
    public var body: some View {
        HStack {
            Divider().frame(width: 6).background(Color.gray)
            MarkdownView(node: MarkdownASTNode(
                type: .root,
                children: node.children
            ))
            .padding(.vertical, verticalSpacing)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.3))
        .padding(.horizontal, horizontalPadding)
    }
}
