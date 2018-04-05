public protocol SavedArticlesCollectionViewCellDelegate: NSObjectProtocol {
    func didSelect(_ tag: Tag)
}

class SavedArticlesCollectionViewCell: ArticleCollectionViewCell {
    private var bottomSeparator = UIView()
    private var topSeparator = UIView()
    
    private var singlePixelDimension: CGFloat = 0.5
    
    public var tags: (readingLists: [ReadingList], indexPath: IndexPath) = (readingLists: [], indexPath: IndexPath()) {
        didSet {
            configuredTags = []
            collectionView.reloadData()
            setNeedsLayout()
        }
    }
    
    private var configuredTags: [Tag] = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    private var isTagsViewHidden: Bool = true {
        didSet {
            collectionView.isHidden = isTagsViewHidden
            setNeedsLayout()
        }
    }
    
    override var alertType: ReadingListAlertType? {
        didSet {
            guard let alertType = alertType else {
                return
            }
            var alertLabelText: String? = nil
            switch alertType {
            case .listLimitExceeded:
                alertLabelText = WMFLocalizedString("reading-lists-article-not-synced-list-limit-exceeded", value: "List limit exceeded, unable to sync article", comment: "Text of the alert label informing the user that article couldn't be synced.")
            case .entryLimitExceeded:
                alertLabelText = WMFLocalizedString("reading-lists-article-not-synced-article-limit-exceeded", value: "Article limit exceeded, unable to sync article", comment: "Text of the alert label informing the user that article couldn't be synced.")
            case .genericNotSynced:
                alertLabelText = WMFLocalizedString("reading-lists-article-not-synced", value: "Not synced", comment: "Text of the alert label informing the user that article couldn't be synced.")
            case .downloading:
                alertLabelText = WMFLocalizedString("reading-lists-article-queued-to-be-downloaded", value: "Article queued to be downloaded", comment: "Text of the alert label informing the user that article is queued to be downloaded.")
            }
            
            alertLabel.text = alertLabelText

            if !isAlertIconHidden {
                alertIcon.image = UIImage(named: "error-icon")
            }
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TagCollectionViewCell.self, forCellWithReuseIdentifier: TagCollectionViewCell.identifier())
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    private lazy var collectionViewHeight: CGFloat = {
        guard let layout = layout else {
            return 0
        }
        return self.collectionView(collectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0)).height
    }()
    
    private lazy var layout: UICollectionViewFlowLayout? = {
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.scrollDirection = .horizontal
        layout?.sectionInset = UIEdgeInsets.zero
        return layout
    }()
    
    private lazy var placeholderCell: TagCollectionViewCell = {
        return TagCollectionViewCell()
    }()
    
    private var theme: Theme = Theme.standard // stored to theme TagCollectionViewCell
    
    weak public var delegate: SavedArticlesCollectionViewCellDelegate?
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
        configuredTags = []
        collectionView.reloadData()
    }
    
    override func setup() {
        imageView.layer.cornerRadius = 3
        bottomSeparator.isOpaque = true
        contentView.addSubview(bottomSeparator)
        topSeparator.isOpaque = true
        contentView.addSubview(topSeparator)
        contentView.addSubview(collectionView)
        contentView.addSubview(placeholderCell)
        
        wmf_configureSubviewsForDynamicType()
        placeholderCell.isHidden = true

        super.setup()
    }
    
    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        topSeparator.isHidden = true
        titleFontFamily = .system
        titleTextStyle = .body
        collectionViewAvailableWidth = 0
        configuredTags = []
        updateFonts(with: traitCollection)
    }
    
    private var collectionViewAvailableWidth: CGFloat = 0
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        
        let margins = self.layoutMargins
        let multipliers = self.layoutMarginsMultipliers
        let layoutMargins = UIEdgeInsets(top: round(margins.top * multipliers.top) + layoutMarginsAdditions.top, left: round(margins.left * multipliers.left) + layoutMarginsAdditions.left, bottom: round(margins.bottom * multipliers.bottom) + layoutMarginsAdditions.bottom, right: round(margins.right * multipliers.right) + layoutMarginsAdditions.right)
        
        var widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        let minHeightMinusMargins = minHeight - layoutMargins.top - layoutMargins.bottom
        
        let labelsAdditionalSpacing: CGFloat = 20
        if !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - spacing - imageViewDimension - labelsAdditionalSpacing
        }
        
        let titleLabelAvailableWidth: CGFloat
        
        if isStatusViewHidden {
            titleLabelAvailableWidth = widthMinusMargins
        } else if isImageViewHidden {
            titleLabelAvailableWidth = widthMinusMargins - statusViewDimension - spacing
        } else {
            titleLabelAvailableWidth = widthMinusMargins - statusViewDimension - 2 * spacing
        }
        
        var x = layoutMargins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: layoutMargins.top)
        
        
        if descriptionLabel.wmf_hasText || !isSaveButtonHidden || !isImageViewHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: titleLabelAvailableWidth, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
            
            if !isSaveButtonHidden {
                origin.y += spacing
                origin.y += saveButtonTopSpacing
                let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
                origin.y += saveButtonFrame.height - 2 * saveButton.verticalPadding
            }
        } else {
            let horizontalAlignment: HorizontalAlignment = isRTL ? .right : .left
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: CGPoint(x: layoutMargins.left, y: layoutMargins.top), maximumViewSize: CGSize(width: titleLabelAvailableWidth, height: UIViewNoIntrinsicMetric), minimumLayoutAreaSize: CGSize(width: UIViewNoIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: horizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
        }
        
        descriptionLabel.isHidden = !descriptionLabel.wmf_hasText
        
        if (apply && !isStatusViewHidden) {
            let x = isRTL ? titleLabel.frame.minX - spacing - statusViewDimension : titleLabel.frame.maxX + spacing
            let statusViewFrame = CGRect(x: x, y: (titleLabel.frame.midY - 0.5 * statusViewDimension), width: statusViewDimension, height: statusViewDimension)
            statusView.frame = statusViewFrame
            statusView.cornerRadius = 0.5 * statusViewDimension
        }

        origin.y += layoutMargins.bottom
        let height = max(origin.y, minHeight)
        
        let separatorXPositon: CGFloat = 0
        let separatorWidth = size.width
        
        if (apply) {
            if (!bottomSeparator.isHidden) {
                bottomSeparator.frame = CGRect(x: separatorXPositon, y: height - singlePixelDimension, width: separatorWidth, height: singlePixelDimension)
            }
            
            if (!topSeparator.isHidden) {
                topSeparator.frame = CGRect(x: separatorXPositon, y: 0, width: separatorWidth, height: singlePixelDimension)
            }
        }
        
        if (apply && !isImageViewHidden) {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - imageViewDimension
            }
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }
        
        if (apply && !isAlertIconHidden) {
            var x = origin.x
            if isRTL {
                x = size.width - alertIconDimension - layoutMargins.right
            }
            alertIcon.frame = CGRect(x: x, y: origin.y, width: alertIconDimension, height: alertIconDimension)
            origin.x += alertIconDimension + spacing
            origin.y += alertIcon.frame.layoutHeight(with: 0)
        }
        
        if (apply && !isAlertLabelHidden) {
            var xPosition = alertIcon.frame.maxX + spacing
            var yPosition = alertIcon.frame.midY - 0.5 * alertIconDimension
            var availableWidth = widthMinusMargins - alertIconDimension - spacing
            if isAlertIconHidden {
                xPosition = origin.x
                yPosition = origin.y
                availableWidth = widthMinusMargins
            }
            let alertLabelFrame = alertLabel.wmf_preferredFrame(at: CGPoint(x: xPosition, y: yPosition), fitting: availableWidth, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.x += alertLabelFrame.width + spacing
        }
        
        if (apply && !isTagsViewHidden) {
            collectionViewAvailableWidth = widthMinusMargins
            let positionY = isImageViewHidden ? origin.y : imageView.frame.maxY - layoutMargins.bottom - layoutMargins.top
            collectionView.frame = CGRect(x: origin.x, y: positionY, width: collectionViewAvailableWidth, height: collectionViewHeight)
            collectionView.semanticContentAttribute = articleSemanticContentAttribute
        }
        
        return CGSize(width: size.width, height: height)
    }
    
    func configureAlert(for entry: ReadingListEntry, in readingList: ReadingList?, listLimit: Int, entryLimit: Int, isInDefaultReadingList: Bool = false) {
        if let error = entry.APIError {
            switch error {
            case .entryLimit where isInDefaultReadingList:
                isAlertLabelHidden = false
                isAlertIconHidden = false
                alertType = .genericNotSynced
            case .entryLimit:
                isAlertLabelHidden = false
                isAlertIconHidden = false
                alertType = .entryLimitExceeded(limit: entryLimit)
            default:
                isAlertLabelHidden = true
                isAlertIconHidden = true
            }
        }
        
        if let error = readingList?.APIError {
            switch error {
            case .listLimit:
                isAlertLabelHidden = false
                isAlertIconHidden = false
                alertType = .listLimitExceeded(limit: listLimit)
            default:
                break
            }
        }
    }
    
    func configure(article: WMFArticle, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme, layoutOnly: Bool) {
        titleLabel.text = article.displayTitle
        descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth // 300 is used to distinguish between full-awidth images and thumbnails. Ultimately this (and other thumbnail requests) should be updated with code that checks all the available buckets for the width that best matches the size of the image view.
        if let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        let articleLanguage = article.url?.wmf_language
        titleLabel.accessibilityLanguage = articleLanguage
        descriptionLabel.accessibilityLanguage = articleLanguage
        extractLabel?.accessibilityLanguage = articleLanguage
        articleSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        isTagsViewHidden = tags.readingLists.count == 0
        
        isStatusViewHidden = article.isDownloaded
        if alertType == nil || alertType == .downloading {
            isAlertLabelHidden = article.isDownloaded
            alertType = .downloading
        }
        
        if shouldShowSeparators {
            topSeparator.isHidden = index > 0
            bottomSeparator.isHidden = false
        } else {
            bottomSeparator.isHidden = true
        }
        self.theme = theme
        apply(theme: theme)
        isSaveButtonHidden = true
        extractLabel?.text = nil
        imageViewDimension = 100
        
        if (shouldAdjustMargins) {
            adjustMargins(for: index, count: count)
        }
        setNeedsLayout()
    }
    
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        collectionView.visibleCells.forEach { ($0 as? TagCollectionViewCell)?.apply(theme: theme) }
        bottomSeparator.backgroundColor = theme.colors.border
        topSeparator.backgroundColor = theme.colors.border
    }
    
    private func tag(at indexPath: IndexPath) -> Tag? {
        guard tags.readingLists.indices.contains(indexPath.item) else {
            return nil
        }
        return Tag(readingList: tags.readingLists[indexPath.item], index: indexPath.item, indexPath: tags.indexPath)
    }
}

// MARK: - UICollectionViewDataSource

extension SavedArticlesCollectionViewCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.readingLists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.identifier(), for: indexPath)
        guard let tagCell = cell as? TagCollectionViewCell else {
            return cell
        }
        guard configuredTags.indices.contains(indexPath.item) else {
            return cell
        }
        tagCell.configure(with: configuredTags[indexPath.item], for: tags.readingLists.count, theme: theme)
        return tagCell
    }

}

// MARK: - UICollectionViewDelegate

extension SavedArticlesCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard configuredTags.indices.contains(indexPath.item) else {
            return
        }
        delegate?.didSelect(configuredTags[indexPath.item])
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension SavedArticlesCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard !isTagsViewHidden else {
            return .zero
        }
        
        guard var tagToConfigure = tag(at: indexPath) else {
            return .zero
        }

        if let lastConfiguredTag = configuredTags.last, lastConfiguredTag.isLast, tagToConfigure.index > lastConfiguredTag.index {
            tagToConfigure.isCollapsed = true
            return .zero
        }
        
        let tagsCount = tags.readingLists.count
        
        guard collectionViewAvailableWidth > 0 else {
            placeholderCell.configure(with: tagToConfigure, for: tagsCount, theme: theme)
            return placeholderCell.sizeThatFits(CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric))
        }
        
        guard collectionViewAvailableWidth - spacing >= 0 else {
            assertionFailure("collectionViewAvailableWidth - spacing will be: \(collectionViewAvailableWidth - spacing)")
            return .zero
        }
        
        collectionViewAvailableWidth -= spacing
        
        placeholderCell.configure(with: tagToConfigure, for: tagsCount, theme: theme)
        var placeholderCellSize = placeholderCell.sizeThatFits(CGSize(width: collectionViewAvailableWidth, height: UIViewNoIntrinsicMetric))
        
        let isLastTagToConfigure = tagToConfigure.index + 1 == tags.readingLists.count
        
        if collectionViewAvailableWidth - placeholderCellSize.width - spacing <= placeholderCell.minWidth, !isLastTagToConfigure {
            tagToConfigure.isLast = true
            placeholderCell.configure(with: tagToConfigure, for: tagsCount, theme: theme)
            placeholderCellSize = placeholderCell.sizeThatFits(CGSize(width: collectionViewAvailableWidth, height: UIViewNoIntrinsicMetric))
        }
        
        collectionViewAvailableWidth -= placeholderCellSize.width
        
        if !configuredTags.contains(where: { $0.readingList == tagToConfigure.readingList && $0.indexPath == tagToConfigure.indexPath }) {
            configuredTags.append(tagToConfigure)
        }
        return placeholderCellSize
    }
}

