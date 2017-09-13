import UIKit

class ShareAFactViewController: UIViewController {

//    @IBOutlet weak var articleTitleLabel: UILabel!
//    @IBOutlet weak var onWikiLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
//    @IBOutlet weak var separatorView: UIView!
//    @IBOutlet weak var textLabel: UILabel!
//    @IBOutlet weak var articleLicenseView: LicenseView!
//    @IBOutlet weak var imageLicenseView: LicenseView!
//    @IBOutlet weak var imageGradientView: WMFGradientView!

    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
//        let theme = Theme.standard //always use the standard theme for now
//        view.backgroundColor = theme.colors.paperBackground
//        articleTitleLabel.textColor = theme.colors.primaryText
//        onWikiLabel.textColor = theme.colors.secondaryText
//        separatorView.backgroundColor = theme.colors.border
//        textLabel.textColor = theme.colors.primaryText
//        licenseView.tintColor = theme.colors.secondaryText
    }
    
    public func update(with articleURL: URL, articleTitle: String?, text: String?, image: UIImage?) {
        view.semanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleURL.wmf_language)
        imageView.image = image
        isImageViewHidden = image == nil
//        articleTitleLabel.text = articleTitle
//        textLabel.text = text
//        licenseView.licenseCodes = ["cc", "by", "sa"]
    }
    
    var isImageViewHidden: Bool = false {
        didSet {
            imageViewTrailingConstraint.constant = isImageViewHidden ? imageViewWidthConstraint.constant : 0
        }
    }


}
