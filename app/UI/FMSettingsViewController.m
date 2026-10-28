#import "FMSettingsViewController.h"
#import <math.h>

#import "FMCompatibilityViewController.h"
#import "FMDesignSystem.h"
#import "FMProfileWorkspace.h"
#import "../shared/FMMountTarget.h"

typedef NS_ENUM(NSInteger, FMSettingsSection) {
    FMSettingsSectionGeneral,
    FMSettingsSectionAutomation,
    FMSettingsSectionDevice,
    FMSettingsSectionAbout,
};

static UIView *FMSettingsSectionHeaderView(NSString *title) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = UIColor.clearColor;
    UILabel *label = FMLabel(UIFontTextStyleCaption1, UIFontWeightSemibold,
                             UIColor.secondaryLabelColor);
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = title;
    [view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:22],
        [label.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-20],
        [label.heightAnchor constraintEqualToConstant:16],
        [label.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-6],
    ]];
    return view;
}

@interface FMSettingsActionCell : UITableViewCell
@property(nonatomic, strong) UIView *card;
@property(nonatomic, strong) UIView *iconBackground;
@property(nonatomic, strong) UIImageView *iconView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *subtitleLabel;
@property(nonatomic, strong) UIImageView *chevron;
- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
                    symbol:(NSString *)symbol
                     color:(UIColor *)color
                disclosure:(BOOL)disclosure
               destructive:(BOOL)destructive;
@end

@implementation FMSettingsActionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
               reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self == nil) return nil;
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.isAccessibilityElement = YES;

    _card = FMCardView();
    _card.translatesAutoresizingMaskIntoConstraints = NO;
    _card.layer.cornerRadius = 26;
    [self.contentView addSubview:_card];

    _iconBackground = [[UIView alloc] initWithFrame:CGRectZero];
    _iconBackground.translatesAutoresizingMaskIntoConstraints = NO;
    _iconBackground.layer.cornerRadius = 18;
    _iconBackground.layer.cornerCurve = kCACornerCurveContinuous;
    [_card addSubview:_iconBackground];

    _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _iconView.translatesAutoresizingMaskIntoConstraints = NO;
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    [_iconBackground addSubview:_iconView];

    _titleLabel = FMLabel(UIFontTextStyleBody, UIFontWeightSemibold, UIColor.labelColor);
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.numberOfLines = 1;
    [_card addSubview:_titleLabel];

    _subtitleLabel = FMLabel(UIFontTextStyleFootnote, UIFontWeightRegular,
                             UIColor.secondaryLabelColor);
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subtitleLabel.numberOfLines = 2;
    [_card addSubview:_subtitleLabel];

    _chevron = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    _chevron.translatesAutoresizingMaskIntoConstraints = NO;
    _chevron.tintColor = UIColor.tertiaryLabelColor;
    _chevron.contentMode = UIViewContentModeScaleAspectFit;
    [_card addSubview:_chevron];

    [NSLayoutConstraint activateConstraints:@[
        [_card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [_card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [_card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [_card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],

        [_iconBackground.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:14],
        [_iconBackground.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_iconBackground.widthAnchor constraintEqualToConstant:36],
        [_iconBackground.heightAnchor constraintEqualToConstant:36],
        [_iconView.centerXAnchor constraintEqualToAnchor:_iconBackground.centerXAnchor],
        [_iconView.centerYAnchor constraintEqualToAnchor:_iconBackground.centerYAnchor],
        [_iconView.widthAnchor constraintEqualToConstant:21],
        [_iconView.heightAnchor constraintEqualToConstant:21],

        [_titleLabel.leadingAnchor constraintEqualToAnchor:_iconBackground.trailingAnchor
                                                   constant:13],
        [_titleLabel.topAnchor constraintEqualToAnchor:_card.topAnchor constant:13],
        [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_chevron.leadingAnchor
                                                               constant:-10],
        [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_chevron.leadingAnchor
                                                                  constant:-10],
        [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2],
        [_subtitleLabel.bottomAnchor constraintEqualToAnchor:_card.bottomAnchor constant:-12],
        [_card.heightAnchor constraintGreaterThanOrEqualToConstant:68],

        [_chevron.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-16],
        [_chevron.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_chevron.widthAnchor constraintEqualToConstant:9],
        [_chevron.heightAnchor constraintEqualToConstant:15],
    ]];
    return self;
}

- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
                    symbol:(NSString *)symbol
                     color:(UIColor *)color
                disclosure:(BOOL)disclosure
               destructive:(BOOL)destructive {
    self.titleLabel.text = title;
    self.titleLabel.textColor = destructive ? FMDangerColor() : UIColor.labelColor;
    self.subtitleLabel.text = subtitle;
    self.iconView.image = [UIImage systemImageNamed:symbol];
    self.iconView.tintColor = color;
    self.iconBackground.backgroundColor = FMTintedBackground(color);
    self.chevron.hidden = !disclosure;
    self.accessibilityTraits = disclosure ? UIAccessibilityTraitButton
                                          : UIAccessibilityTraitStaticText;
    self.accessibilityLabel = title;
    self.accessibilityValue = subtitle;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    NSTimeInterval duration = animated && !UIAccessibilityIsReduceMotionEnabled() ? 0.13 : 0.0;
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState |
                                UIViewAnimationOptionCurveEaseOut |
                                UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.card.transform = highlighted ? CGAffineTransformMakeScale(0.985, 0.985)
                                          : CGAffineTransformIdentity;
        self.card.alpha = highlighted ? 0.86 : 1.0;
    }
                     completion:nil];
}

@end

@interface FMSettingsToggleCell : FMSettingsActionCell
@property(nonatomic, strong) UISwitch *toggle;
- (void)configureAutomaticRespringEnabled:(BOOL)enabled
                                  loaded:(BOOL)loaded
                                 updating:(BOOL)updating
                                    target:(id)target
                                    action:(SEL)action;
@end

@implementation FMSettingsToggleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
               reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self == nil) return nil;
    self.isAccessibilityElement = NO;
    _toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
    _toggle.translatesAutoresizingMaskIntoConstraints = NO;
    _toggle.onTintColor = FMAccentColor();
    _toggle.accessibilityIdentifier = @"settings_auto_respring_switch";
    _toggle.accessibilityLabel = FMLocalized(@"自动 Respring");
    _toggle.accessibilityHint = FMLocalized(@"下次重新越狱后，字体挂载完成得较晚时自动刷新界面");
    [self.card addSubview:_toggle];
    [NSLayoutConstraint activateConstraints:@[
        [_toggle.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor
                                                constant:-16],
        [_toggle.centerYAnchor constraintEqualToAnchor:self.card.centerYAnchor],
        [self.titleLabel.trailingAnchor
            constraintLessThanOrEqualToAnchor:_toggle.leadingAnchor constant:-12],
        [self.subtitleLabel.trailingAnchor
            constraintLessThanOrEqualToAnchor:_toggle.leadingAnchor constant:-12],
    ]];
    return self;
}

- (void)configureAutomaticRespringEnabled:(BOOL)enabled
                                  loaded:(BOOL)loaded
                                 updating:(BOOL)updating
                                    target:(id)target
                                    action:(SEL)action {
    [self configureWithTitle:FMLocalized(@"自动 Respring")
                    subtitle:FMLocalized(@"下次重新越狱若字体挂载较晚，自动执行一次 Respring")
                      symbol:@"arrow.clockwise.circle.fill"
                       color:FMAccentColor()
                  disclosure:NO
                 destructive:NO];
    self.chevron.hidden = YES;
    [self.toggle removeTarget:nil action:NULL
              forControlEvents:UIControlEventValueChanged];
    [self.toggle setOn:enabled animated:NO];
    self.toggle.enabled = loaded && !updating;
    [self.toggle addTarget:target action:action
            forControlEvents:UIControlEventValueChanged];
    self.toggle.accessibilityValue = enabled ? FMLocalized(@"已开启") : FMLocalized(@"已关闭");
}

@end

@interface FMLanguageSelectionViewController : UITableViewController
@property(nonatomic, copy) NSArray<NSString *> *languagePreferences;
@end

@implementation FMLanguageSelectionViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self != nil) {
        _languagePreferences = @[ @"system", @"zh-Hans", @"en" ];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = FMLocalized(@"语言");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.view.backgroundColor = UIColor.clearColor;
    FMPageFrostView(self);
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 78;
    self.tableView.sectionHeaderHeight = 18;
    self.tableView.sectionFooterHeight = 8;
    self.tableView.accessibilityIdentifier = @"settings_language_options";
    [self.tableView registerClass:FMSettingsActionCell.class
           forCellReuseIdentifier:@"LanguageOptionCell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.languagePreferences.count;
}

- (FMSettingsActionCell *)tableView:(UITableView *)tableView
              cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *preference = self.languagePreferences[indexPath.row];
    BOOL selected = [preference isEqualToString:FMLanguagePreference()];
    NSString *subtitle = [preference isEqualToString:@"system"]
        ? FMLocalized(@"跟随设备的语言设置")
        : ([preference isEqualToString:@"zh-Hans"]
            ? FMLocalized(@"始终使用简体中文")
            : FMLocalized(@"始终使用英文"));
    NSString *symbol = [preference isEqualToString:@"system"]
        ? @"globe" : ([preference isEqualToString:@"zh-Hans"]
            ? @"character.book.closed.fill" : @"textformat");
    FMSettingsActionCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"LanguageOptionCell"
                                        forIndexPath:indexPath];
    [cell configureWithTitle:FMLanguagePreferenceDisplayName(preference)
                    subtitle:subtitle
                      symbol:symbol
                       color:FMAccentColor()
                  disclosure:YES
                 destructive:NO];
    cell.chevron.image = [UIImage systemImageNamed:@"checkmark"];
    cell.chevron.hidden = !selected;
    cell.accessibilityTraits = UIAccessibilityTraitButton |
        (selected ? UIAccessibilityTraitSelected : 0);
    cell.accessibilityHint = selected ? nil : FMLocalized(@"切换到此语言");
    cell.accessibilityIdentifier =
        [@"settings_language_" stringByAppendingString:preference];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *preference = self.languagePreferences[indexPath.row];
    if (!FMSetLanguagePreference(preference)) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

@end

static NSAttributedString *FMSettingsDisclaimerBodyText(
    NSArray<NSString *> *paragraphs) {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 4;
    style.paragraphSpacing = 10;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    return [[NSAttributedString alloc]
        initWithString:[paragraphs componentsJoinedByString:@"\n"]
            attributes:@{
                NSFontAttributeName :
                    [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                NSForegroundColorAttributeName : UIColor.secondaryLabelColor,
                NSParagraphStyleAttributeName : style,
            }];
}

static UIView *FMSettingsDisclaimerHeroView(void) {
    UIView *hero = FMCardView();
    hero.backgroundColor = [FMAccentColor() colorWithAlphaComponent:0.10];
    hero.layer.borderColor =
        [FMAccentColor() colorWithAlphaComponent:0.20].CGColor;

    UIView *iconBackground = [[UIView alloc] initWithFrame:CGRectZero];
    iconBackground.translatesAutoresizingMaskIntoConstraints = NO;
    iconBackground.backgroundColor = FMAccentColor();
    iconBackground.layer.cornerRadius = 16;
    iconBackground.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *icon = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:@"hand.raised.fill"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = UIColor.whiteColor;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [iconBackground addSubview:icon];

    UILabel *eyebrow = FMLabel(UIFontTextStyleCaption1, UIFontWeightSemibold,
                               FMAccentColor());
    eyebrow.text = FMLocalized(@"使用须知");

    UILabel *title = FMLabel(UIFontTextStyleTitle2, UIFontWeightBold,
                             UIColor.labelColor);
    title.text = FMLocalized(@"请确认字体授权");

    UILabel *subtitle = FMLabel(UIFontTextStyleSubheadline, UIFontWeightRegular,
                                UIColor.secondaryLabelColor);
    subtitle.text = FMLocalized(@"导入字体前，请先了解授权责任与使用风险。");

    UIStackView *labels = [[UIStackView alloc]
        initWithArrangedSubviews:@[ eyebrow, title, subtitle ]];
    labels.axis = UILayoutConstraintAxisVertical;
    labels.alignment = UIStackViewAlignmentFill;
    labels.spacing = 4;

    UIStackView *content = [[UIStackView alloc]
        initWithArrangedSubviews:@[ iconBackground, labels ]];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisHorizontal;
    content.alignment = UIStackViewAlignmentTop;
    content.spacing = 14;
    [hero addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [iconBackground.widthAnchor constraintEqualToConstant:48],
        [iconBackground.heightAnchor constraintEqualToConstant:48],
        [icon.centerXAnchor constraintEqualToAnchor:iconBackground.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:iconBackground.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:22],
        [icon.heightAnchor constraintEqualToConstant:22],
        [content.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:20],
        [content.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-20],
        [content.topAnchor constraintEqualToAnchor:hero.topAnchor constant:20],
        [content.bottomAnchor constraintEqualToAnchor:hero.bottomAnchor constant:-20],
    ]];
    return hero;
}

static UIView *FMSettingsDisclaimerSectionView(
    NSString *title,
    NSString *symbol,
    NSArray<NSString *> *paragraphs) {
    UIView *card = FMCardView();

    UIView *iconBackground = [[UIView alloc] initWithFrame:CGRectZero];
    iconBackground.translatesAutoresizingMaskIntoConstraints = NO;
    iconBackground.backgroundColor = FMTintedBackground(FMAccentColor());
    iconBackground.layer.cornerRadius = 11;
    iconBackground.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *icon = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:symbol]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = FMAccentColor();
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [iconBackground addSubview:icon];

    UILabel *heading = FMLabel(UIFontTextStyleHeadline, UIFontWeightSemibold,
                               UIColor.labelColor);
    heading.text = title;

    UIStackView *header = [[UIStackView alloc]
        initWithArrangedSubviews:@[ iconBackground, heading ]];
    header.axis = UILayoutConstraintAxisHorizontal;
    header.alignment = UIStackViewAlignmentCenter;
    header.spacing = 11;

    UIView *separator = [[UIView alloc] initWithFrame:CGRectZero];
    separator.backgroundColor = FMHairlineColor();

    UILabel *body = FMLabel(UIFontTextStyleBody, UIFontWeightRegular,
                            UIColor.secondaryLabelColor);
    body.attributedText = FMSettingsDisclaimerBodyText(paragraphs);

    UIStackView *content = [[UIStackView alloc]
        initWithArrangedSubviews:@[ header, separator, body ]];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 14;
    [card addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [iconBackground.widthAnchor constraintEqualToConstant:36],
        [iconBackground.heightAnchor constraintEqualToConstant:36],
        [icon.centerXAnchor constraintEqualToAnchor:iconBackground.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:iconBackground.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:17],
        [icon.heightAnchor constraintEqualToConstant:17],
        [separator.heightAnchor constraintEqualToConstant:
            1.0 / UIScreen.mainScreen.scale],
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:18],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20],
    ]];
    return card;
}

static UIView *FMSettingsDisclaimerReminderView(void) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [FMSuccessColor() colorWithAlphaComponent:0.10];
    view.layer.cornerRadius = 16;
    view.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *icon = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:@"checkmark.shield.fill"]];
    icon.tintColor = FMSuccessColor();
    icon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *label = FMLabel(UIFontTextStyleFootnote, UIFontWeightSemibold,
                             UIColor.secondaryLabelColor);
    label.text = FMLocalized(@"请仅导入和使用已获得必要授权的字体");

    UIStackView *content = [[UIStackView alloc]
        initWithArrangedSubviews:@[ icon, label ]];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisHorizontal;
    content.alignment = UIStackViewAlignmentCenter;
    content.spacing = 10;
    [view addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [icon.widthAnchor constraintEqualToConstant:20],
        [icon.heightAnchor constraintEqualToConstant:20],
        [content.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16],
        [content.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-16],
        [content.topAnchor constraintEqualToAnchor:view.topAnchor constant:14],
        [content.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-14],
    ]];
    return view;
}

@interface FMSettingsDisclaimerViewController : UIViewController
@end

@implementation FMSettingsDisclaimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = FMLocalized(@"免责声明");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.view.backgroundColor = UIColor.clearColor;
    FMPageFrostView(self);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.alwaysBounceVertical = YES;
    scrollView.accessibilityIdentifier = @"settings_disclaimer_page";
    [self.view addSubview:scrollView];

    UIView *fontRights = FMSettingsDisclaimerSectionView(
        FMLocalized(@"字体来源与授权"), @"textformat",
        @[
            FMLocalized(@"MarkFont 仅提供字体管理功能，不提供、销售、授权或分发任何第三方字体文件。"),
            FMLocalized(@"字体文件、字形设计、字体名称及相关内容可能受到版权、商标、字体许可或其他权利保护。"),
            FMLocalized(@"用户在导入、安装、使用、复制或分发任何字体前，应自行确认已取得必要授权，并遵守字体许可与适用法律。"),
        ]);
    UIView *responsibility = FMSettingsDisclaimerSectionView(
        FMLocalized(@"责任与风险"), @"shield.lefthalf.filled",
        @[
            FMLocalized(@"用户导入的字体由用户自行选择和获取，项目维护者与贡献者不审核其来源或授权状态。"),
            FMLocalized(@"在适用法律允许的最大范围内，项目维护者与贡献者不对用户未经授权或违法使用字体所引起的侵权主张、损失或其他责任负责，也不对字体兼容性或不当操作造成的设备异常、数据丢失或系统不稳定负责。"),
        ]);

    UIStackView *content = [[UIStackView alloc]
        initWithArrangedSubviews:@[
            FMSettingsDisclaimerHeroView(),
            fontRights,
            responsibility,
            FMSettingsDisclaimerReminderView(),
        ]];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 14;
    [scrollView addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor
                                              constant:16],
        [content.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor
                                               constant:-16],
        [content.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor
                                          constant:16],
        [content.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor
                                             constant:-28],
        [content.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor
                                            constant:-32],
    ]];
}

@end

@interface FMSettingsCreditsViewController : UITableViewController
@property(nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *credits;
@end

@implementation FMSettingsCreditsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self != nil) {
        _credits = @[
            @{
                @"title" : @"RootHide",
                @"subtitle" : FMLocalized(@"提供 RootHide 架构与兼容基础"),
                @"symbol" : @"shield.lefthalf.filled",
                @"url" : @"https://github.com/roothide/Developer",
            },
            @{
                @"title" : @"Theos",
                @"subtitle" : FMLocalized(@"提供 iOS 越狱开发与打包工具链"),
                @"symbol" : @"hammer.fill",
                @"url" : @"https://theos.dev/",
            },
            @{
                @"title" : @"Dopamine / libjailbreak",
                @"subtitle" : FMLocalized(@"提供挂载能力接口设计参考"),
                @"symbol" : @"arrow.triangle.2.circlepath",
                @"url" : @"https://github.com/opa334/Dopamine",
            },
            @{
                @"title" : @"Relaxin",
                @"subtitle" : FMLocalized(@"提供本项目当前适配与测试的越狱环境"),
                @"symbol" : @"sparkles",
                @"url" : @"https://relaxin.owngoal.dev/",
            },
        ];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = FMLocalized(@"致谢");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.view.backgroundColor = UIColor.clearColor;
    FMPageFrostView(self);
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 78;
    self.tableView.sectionHeaderHeight = 34;
    self.tableView.sectionHeaderTopPadding = 0;
    self.tableView.sectionFooterHeight = 8;
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.accessibilityIdentifier = @"settings_credits";
    [self.tableView registerClass:FMSettingsActionCell.class
           forCellReuseIdentifier:@"SettingsCreditCell"];

    UIView *footer = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 88)];
    UILabel *label = FMLabel(UIFontTextStyleCaption1, UIFontWeightMedium,
                             UIColor.tertiaryLabelColor);
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = FMLocalized(@"感谢这些项目及其贡献者\n让 MarkFont 得以构建与运行");
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    [footer addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor constant:24],
        [label.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor constant:-24],
        [label.topAnchor constraintEqualToAnchor:footer.topAnchor constant:14],
    ]];
    self.tableView.tableFooterView = footer;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.credits.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return FMLocalized(@"特别感谢");
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return FMSettingsSectionHeaderView(
        [self tableView:tableView titleForHeaderInSection:section]);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return 34;
}

- (FMSettingsActionCell *)tableView:(UITableView *)tableView
              cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FMSettingsActionCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"SettingsCreditCell"
                                        forIndexPath:indexPath];
    NSDictionary<NSString *, NSString *> *credit = self.credits[indexPath.row];
    [cell configureWithTitle:credit[@"title"]
                    subtitle:credit[@"subtitle"]
                      symbol:credit[@"symbol"]
                       color:FMAccentColor()
                  disclosure:YES
                 destructive:NO];
    cell.chevron.image = [UIImage systemImageNamed:@"arrow.up.right"];
    cell.accessibilityTraits = UIAccessibilityTraitLink;
    cell.accessibilityHint = FMLocalized(@"打开项目链接");
    cell.accessibilityIdentifier =
        [@"settings_credit_" stringByAppendingString:credit[@"title"].lowercaseString];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    (void)indexPath;
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *address = self.credits[indexPath.row][@"url"];
    NSURL *url = [NSURL URLWithString:address];
    if (url == nil) return;
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

@end

@interface FMMountPathListViewController : UITableViewController
@property(nonatomic, strong) id<FMProfileWorkspace> workspace;
@property(nonatomic, copy) NSArray<NSString *> *paths;
@property(nonatomic, copy) NSArray<NSString *> *mountedPaths;
@property(nonatomic, strong) UITextField *pathField;
@property(nonatomic) BOOL updating;
@end

@implementation FMMountPathListViewController

- (instancetype)initWithWorkspace:(id<FMProfileWorkspace>)workspace {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self != nil) {
        _workspace = workspace;
        _paths = @[];
        _mountedPaths = @[];
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.tableView.bounds.size.width;
    UIView *header = self.tableView.tableHeaderView;
    if (header != nil && fabs(header.frame.size.width - width) > 0.5) {
        CGRect frame = header.frame;
        frame.size.width = width;
        header.frame = frame;
        self.tableView.tableHeaderView = header;
    }
    UIView *footer = self.tableView.tableFooterView;
    if (footer != nil && fabs(footer.frame.size.width - width) > 0.5) {
        CGRect frame = footer.frame;
        frame.size.width = width;
        footer.frame = frame;
        self.tableView.tableFooterView = footer;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = FMLocalized(@"挂载");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
    self.tableView.sectionHeaderHeight = 34;
    self.tableView.sectionFooterHeight = 8;
    self.tableView.accessibilityIdentifier = @"settings_mount_paths";
    self.tableView.tableHeaderView = [self makeHeader];
    self.tableView.tableFooterView = [self makeFooter];
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.45;
    [self.tableView addGestureRecognizer:longPress];
    [self reloadPaths];
}

- (UIView *)makeHeader {
    UIView *header = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 96)];
    UILabel *label = FMLabel(UIFontTextStyleFootnote, UIFontWeightRegular,
                             UIColor.secondaryLabelColor);
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.text = FMLocalized(@"把这些系统目录映射到 jbroot 中对应的目录（可读写，写入只影响 jbroot 副本）。添加时会先复制当前系统目录到 jbroot（如果还没有）。不会改动 /System/Library/Fonts 的挂载。");
    [header addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:22],
        [label.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
        [label.topAnchor constraintEqualToAnchor:header.topAnchor constant:4],
    ]];
    return header;
}

- (UIView *)makeFooter {
    UIView *footer = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 240)];

    UITextField *pathField = [[UITextField alloc] initWithFrame:CGRectZero];
    pathField.translatesAutoresizingMaskIntoConstraints = NO;
    pathField.placeholder = @"/System/Library/PrivateFrameworks/...";
    pathField.font = [UIFont monospacedSystemFontOfSize:14.0
                                                 weight:UIFontWeightRegular];
    pathField.textColor = UIColor.labelColor;
    pathField.tintColor = FMAccentColor();
    pathField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.34];
    pathField.layer.cornerRadius = 16;
    pathField.layer.cornerCurve = kCACornerCurveContinuous;
    pathField.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    pathField.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.92].CGColor;
    pathField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    pathField.autocorrectionType = UITextAutocorrectionTypeNo;
    pathField.spellCheckingType = UITextSpellCheckingTypeNo;
    pathField.smartQuotesType = UITextSmartQuotesTypeNo;
    pathField.smartDashesType = UITextSmartDashesTypeNo;
    pathField.clearButtonMode = UITextFieldViewModeWhileEditing;
    pathField.returnKeyType = UIReturnKeyDone;
    pathField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 14)];
    pathField.leftViewMode = UITextFieldViewModeAlways;
    pathField.accessibilityIdentifier = @"settings_mount_path_field";
    pathField.accessibilityLabel = FMLocalized(@"挂载路径");
    self.pathField = pathField;

    UIButton *add = [UIButton buttonWithType:UIButtonTypeSystem];
    add.translatesAutoresizingMaskIntoConstraints = NO;
    UIButtonConfiguration *configuration =
        [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = FMLocalized(@"添加挂载路径");
    configuration.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    configuration.baseBackgroundColor = [FMAccentColor() colorWithAlphaComponent:0.55];
    configuration.baseForegroundColor = UIColor.whiteColor;
    add.configuration = configuration;
    add.accessibilityIdentifier = @"settings_mount_path_add";
    [add addTarget:self action:@selector(addPathTapped:)
  forControlEvents:UIControlEventTouchUpInside];

    UIButton *reset = [UIButton buttonWithType:UIButtonTypeSystem];
    reset.translatesAutoresizingMaskIntoConstraints = NO;
    UIButtonConfiguration *resetConfiguration =
        [UIButtonConfiguration plainButtonConfiguration];
    resetConfiguration.title = FMLocalized(@"全部移除");
    resetConfiguration.baseForegroundColor = FMDangerColor();
    reset.configuration = resetConfiguration;
    reset.accessibilityIdentifier = @"settings_mount_path_reset";
    [reset addTarget:self action:@selector(resetTapped:)
    forControlEvents:UIControlEventTouchUpInside];

    UILabel *hint = FMLabel(UIFontTextStyleCaption1, UIFontWeightRegular,
                            UIColor.tertiaryLabelColor);
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.numberOfLines = 0;
    hint.text = [NSString stringWithFormat:
        FMLocalized(@"路径必须已经存在，且不能是符号链接。映射源是 jbroot 中相同路径的目录，可读写。最多 %lu 个。"),
        (unsigned long)FMMountTargetsMaximumCount];

    [footer addSubview:pathField];
    [footer addSubview:add];
    [footer addSubview:reset];
    [footer addSubview:hint];
    [NSLayoutConstraint activateConstraints:@[
        [pathField.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor constant:20],
        [pathField.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor constant:-20],
        [pathField.topAnchor constraintEqualToAnchor:footer.topAnchor constant:12],
        [pathField.heightAnchor constraintEqualToConstant:46],
        [add.leadingAnchor constraintEqualToAnchor:pathField.leadingAnchor],
        [add.trailingAnchor constraintEqualToAnchor:pathField.trailingAnchor],
        [add.topAnchor constraintEqualToAnchor:pathField.bottomAnchor constant:10],
        [add.heightAnchor constraintEqualToConstant:50],
        [reset.centerXAnchor constraintEqualToAnchor:add.centerXAnchor],
        [reset.topAnchor constraintEqualToAnchor:add.bottomAnchor constant:6],
        [hint.leadingAnchor constraintEqualToAnchor:add.leadingAnchor],
        [hint.trailingAnchor constraintEqualToAnchor:add.trailingAnchor],
        [hint.topAnchor constraintEqualToAnchor:reset.bottomAnchor constant:8],
        [hint.bottomAnchor constraintEqualToAnchor:footer.bottomAnchor constant:-12],
    ]];
    return footer;
}

- (void)reloadPaths {
    id<FMProfileWorkspace> workspace = self.workspace;
    if (![workspace respondsToSelector:@selector(customMountPathsStatus:)]) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSDictionary<NSString *, id> *report =
            [workspace customMountPathsStatus:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (report == nil) {
                [self showError:error.localizedDescription ?:
                    FMLocalized(@"暂时无法读取挂载路径。")];
                return;
            }
            self.paths = report[@"paths"] ?: @[];
            self.mountedPaths = report[@"mounted"] ?: @[];
            [self.tableView reloadData];
        });
    });
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:FMLocalized(@"操作没有完成")
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:FMLocalized(@"好")
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    CGPoint point = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (indexPath == nil || self.paths.count == 0 ||
        indexPath.row >= (NSInteger)self.paths.count) {
        return;
    }
    NSString *target = self.paths[indexPath.row];
    NSString *source = FMMountTargetsSourceLogicalPath(target);
    UIAlertController *sheet = [UIAlertController
        alertControllerWithTitle:target
                         message:[NSString stringWithFormat:
                             FMLocalized(@"源目录：%@"), source]
                  preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:FMLocalized(@"复制源路径")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        (void)action;
        UIPasteboard.generalPasteboard.string = source;
        [weakSelf showError:FMLocalized(@"源路径已复制。")];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:FMLocalized(@"在 Filza 中打开")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        (void)action;
        NSURL *url = [NSURL URLWithString:
            [@"filza://" stringByAppendingString:source]];
        if (url == nil) {
            [weakSelf showError:source];
            return;
        }
        [UIApplication.sharedApplication openURL:url options:@{}
                                completionHandler:^(BOOL success) {
            if (!success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf showError:[NSString stringWithFormat:
                        FMLocalized(@"无法打开 Filza。源目录：%@"), source]];
                });
            }
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:FMLocalized(@"取消")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    sheet.popoverPresentationController.sourceView = self.tableView;
    sheet.popoverPresentationController.sourceRect =
        [self.tableView rectForRowAtIndexPath:indexPath];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)addPathTapped:(id)sender {
    (void)sender;
    NSString *raw = [self.pathField.text
        stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (raw.length == 0) {
        [self showError:FMLocalized(@"请先输入挂载路径。")];
        return;
    }
    if (![raw hasPrefix:@"/"]) {
        [self showError:FMLocalized(@"挂载路径必须是绝对路径，例如 /System/Library/PrivateFrameworks/。")];
        return;
    }
    [self.pathField resignFirstResponder];
    [self addPath:raw];
}

- (void)addPath:(NSString *)path {
    if (self.updating) return;
    self.updating = YES;
    id<FMProfileWorkspace> workspace = self.workspace;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSDictionary<NSString *, id> *report =
            [workspace addCustomMountPath:path error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updating = NO;
            if (report == nil) {
                NSString *reason = error.localizedDescription ?:
                    FMLocalized(@"无法添加这个挂载路径。");
                [self showError:[NSString stringWithFormat:@"%@\n\n%@: %@ (%lu)",
                    reason, FMLocalized(@"发送的路径"), path,
                    (unsigned long)path.length]];
                return;
            }
            self.pathField.text = nil;
            self.paths = report[@"paths"] ?: @[];
            self.mountedPaths = report[@"mounted"] ?: @[];
            [self.tableView reloadData];
            if ([report[@"changed"] boolValue] &&
                ![report[@"mountedNow"] boolValue]) {
                [self showError:FMLocalized(@"路径已保存，但当前没有挂载成功。下次自动挂载或重启后会重试。")];
            }
        });
    });
}

- (void)resetTapped:(id)sender {
    (void)sender;
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:FMLocalized(@"全部移除")
                         message:FMLocalized(@"这会取消所有附加挂载，不影响系统字体挂载。")
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:FMLocalized(@"取消")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:FMLocalized(@"全部移除")
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        (void)action;
        [weakSelf resetPaths];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetPaths {
    if (self.updating) return;
    self.updating = YES;
    id<FMProfileWorkspace> workspace = self.workspace;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSDictionary<NSString *, id> *report =
            [workspace resetCustomMountPaths:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updating = NO;
            if (report == nil) {
                [self showError:error.localizedDescription ?:
                    FMLocalized(@"无法移除附加挂载路径。")];
                return;
            }
            self.paths = report[@"paths"] ?: @[];
            self.mountedPaths = report[@"mounted"] ?: @[];
            [self.tableView reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.paths.count > 0 ? self.paths.count : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.paths.count > 0
        ? [NSString stringWithFormat:FMLocalized(@"附加路径 · %lu"), (unsigned long)self.paths.count]
        : FMLocalized(@"附加路径");
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = UIColor.clearColor;
    UILabel *label = FMLabel(UIFontTextStyleCaption1, UIFontWeightSemibold,
                             UIColor.secondaryLabelColor);
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    [view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:22],
        [label.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-20],
        [label.heightAnchor constraintEqualToConstant:16],
        [label.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-6],
    ]];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return 34;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.paths.count == 0) {
        UITableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"MountPathEmptyCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:@"MountPathEmptyCell"];
        }
        cell.textLabel.text = FMLocalized(@"尚未添加附加路径");
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        cell.textLabel.textColor = UIColor.tertiaryLabelColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = UIColor.clearColor;
        return cell;
    }
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"MountPathCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
          reuseIdentifier:@"MountPathCell"];
    }
    NSString *path = self.paths[indexPath.row];
    BOOL mounted = [self.mountedPaths containsObject:path];
    cell.textLabel.text = path;
    cell.textLabel.font = [UIFont monospacedSystemFontOfSize:14.0
                                                      weight:UIFontWeightRegular];
    cell.textLabel.numberOfLines = 2;
    cell.layoutMargins = UIEdgeInsetsMake(6, 20, 6, 20);
    cell.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(6, 20, 6, 20);
    cell.textLabel.textColor = UIColor.labelColor;
    cell.detailTextLabel.text = mounted
        ? FMLocalized(@"已挂载") : FMLocalized(@"未挂载");
    cell.detailTextLabel.textColor = mounted
        ? FMSuccessColor() : UIColor.secondaryLabelColor;
    cell.backgroundColor = UIColor.clearColor;
    if (cell.backgroundView == nil) {
        UIView *card = FMGlassCardView();
        card.layer.cornerRadius = 18;
        card.layer.shadowOpacity = 0.05;
        card.layer.shadowRadius = 8;
        cell.backgroundView = card;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessibilityIdentifier = [@"settings_mount_path_" stringByAppendingString:path];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    return self.paths.count > 0 && indexPath.row < (NSInteger)self.paths.count;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    NSString *path = self.paths[indexPath.row];
    id<FMProfileWorkspace> workspace = self.workspace;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSDictionary<NSString *, id> *report =
            [workspace removeCustomMountPath:path error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (report == nil) {
                [self showError:error.localizedDescription ?:
                    FMLocalized(@"无法移除这个挂载路径。")];
                return;
            }
            self.paths = report[@"paths"] ?: @[];
            self.mountedPaths = report[@"mounted"] ?: @[];
            [tableView reloadData];
        });
    });
}

@end

UIViewController *FMCreateMountPathsViewController(id<FMProfileWorkspace> workspace) {
    return [[FMMountPathListViewController alloc] initWithWorkspace:workspace];
}

@interface FMSettingsViewController ()
@property(nonatomic, strong) id<FMProfileWorkspace> workspace;
@property(nonatomic, copy) dispatch_block_t dismissalHandler;
@property(nonatomic) BOOL automaticRespringEnabled;
@property(nonatomic) BOOL automaticRespringPolicyLoaded;
@property(nonatomic) BOOL automaticRespringUpdateInFlight;
- (void)refreshAutomaticRespringCellIfVisible;
@end

@implementation FMSettingsViewController

- (instancetype)initWithWorkspace:(id<FMProfileWorkspace>)workspace
                  dismissalHandler:(dispatch_block_t)dismissalHandler {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self != nil) {
        _workspace = workspace;
        _dismissalHandler = [dismissalHandler copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = FMLocalized(@"设置");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    if (self.dismissalHandler != nil) {
        UIBarButtonItem *close =
            [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark"]
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(closeSettings:)];
        close.accessibilityLabel = FMLocalized(@"关闭设置");
        close.tintColor = FMAccentColor();
        self.navigationItem.rightBarButtonItem = close;
    }

    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 78;
    self.tableView.sectionHeaderHeight = 34;
    self.tableView.sectionHeaderTopPadding = 0;
    self.tableView.sectionFooterHeight = 8;
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.accessibilityIdentifier = @"settings";
    [self.tableView registerClass:FMSettingsActionCell.class
           forCellReuseIdentifier:@"SettingsActionCell"];
    [self.tableView registerClass:FMSettingsToggleCell.class
           forCellReuseIdentifier:@"SettingsToggleCell"];
    self.tableView.tableFooterView = [self makeAboutFooter];
    [self reloadAutomaticRespringPolicy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.tableView.bounds.size.width;
    UIView *header = self.tableView.tableHeaderView;
    if (header != nil && fabs(header.frame.size.width - width) > 0.5) {
        CGRect frame = header.frame;
        frame.size.width = width;
        header.frame = frame;
        self.tableView.tableHeaderView = header;
    }
    UIView *footer = self.tableView.tableFooterView;
    if (footer != nil && fabs(footer.frame.size.width - width) > 0.5) {
        CGRect frame = footer.frame;
        frame.size.width = width;
        footer.frame = frame;
        self.tableView.tableFooterView = footer;
    }
}

- (void)appearanceSwitchChanged:(UISwitch *)sender {
    FMSetFollowSystemAppearanceEnabled(sender.isOn);
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)refreshAutomaticRespringCellIfVisible {
    NSIndexPath *indexPath =
        [NSIndexPath indexPathForRow:0 inSection:FMSettingsSectionAutomation];
    FMSettingsToggleCell *cell = (FMSettingsToggleCell *)
        [self.tableView cellForRowAtIndexPath:indexPath];
    if (![cell isKindOfClass:FMSettingsToggleCell.class]) return;
    [cell configureAutomaticRespringEnabled:self.automaticRespringEnabled
                                     loaded:self.automaticRespringPolicyLoaded
                                   updating:self.automaticRespringUpdateInFlight
                                      target:self
                                      action:@selector(automaticRespringSwitchChanged:)];
}

- (void)reloadAutomaticRespringPolicy {
    id<FMProfileWorkspace> workspace = self.workspace;
    if (![workspace respondsToSelector:@selector(setAutomaticRespringEnabled:error:)]) {
        self.automaticRespringEnabled = NO;
        self.automaticRespringPolicyLoaded = NO;
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSDictionary<NSString *, id> *state = nil;
        if ([workspace respondsToSelector:@selector(environmentStatus:)]) {
            NSDictionary<NSString *, id> *status =
                [workspace environmentStatus:&error];
            state = [status[@"state"] isKindOfClass:NSDictionary.class]
                ? status[@"state"] : nil;
            if (![state[@"present"] boolValue] ||
                ![state[@"valid"] boolValue]) {
                state = nil;
            }
        } else if ([workspace prepareIfNeeded:&error]) {
            state = [workspace currentState:&error];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (state != nil) {
                self.automaticRespringEnabled =
                    [state[@"autoRespring"] boolValue];
                self.automaticRespringPolicyLoaded = YES;
            }
            [self refreshAutomaticRespringCellIfVisible];
        });
    });
}

- (void)automaticRespringSwitchChanged:(UISwitch *)sender {
    if (!self.automaticRespringPolicyLoaded ||
        self.automaticRespringUpdateInFlight ||
        ![self.workspace respondsToSelector:
            @selector(setAutomaticRespringEnabled:error:)]) {
        [sender setOn:self.automaticRespringEnabled animated:YES];
        return;
    }

    BOOL requestedEnabled = sender.isOn;
    self.automaticRespringUpdateInFlight = YES;
    sender.enabled = NO;
    id<FMProfileWorkspace> workspace = self.workspace;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        BOOL saved = [workspace setAutomaticRespringEnabled:requestedEnabled
                                                      error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.automaticRespringUpdateInFlight = NO;
            if (saved) {
                self.automaticRespringEnabled = requestedEnabled;
                [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
            } else {
                [sender setOn:self.automaticRespringEnabled animated:YES];
                UIAlertController *alert = [UIAlertController
                    alertControllerWithTitle:FMLocalized(@"设置没有保存")
                                     message:error.localizedDescription ?:
                                         FMLocalized(@"请稍后重试。")
                              preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:FMLocalized(@"好")
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            sender.enabled = self.automaticRespringPolicyLoaded;
            sender.accessibilityValue = self.automaticRespringEnabled
                ? FMLocalized(@"已开启") : FMLocalized(@"已关闭");
        });
    });
}

- (UIView *)makeAboutFooter {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 82)];
    UILabel *label = FMLabel(UIFontTextStyleCaption1, UIFontWeightMedium,
                             UIColor.tertiaryLabelColor);
    label.translatesAutoresizingMaskIntoConstraints = NO;
    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (version.length == 0) version = @"0.3.8";
    label.text = [NSString stringWithFormat:FMLocalized(@"MarkFont · 版本 %@\n由 Hmmzzz 设计与开发\nNing二改自用版"),
                                            version];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    [footer addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor constant:24],
        [label.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor constant:-24],
        [label.topAnchor constraintEqualToAnchor:footer.topAnchor constant:14],
    ]];
    return footer;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if (section == FMSettingsSectionAbout) return 3;
    if (section == FMSettingsSectionGeneral) return 3;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return @[ FMLocalized(@"通用"), FMLocalized(@"自动化"),
              FMLocalized(@"设备"), FMLocalized(@"关于") ][section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return FMSettingsSectionHeaderView(
        [self tableView:tableView titleForHeaderInSection:section]);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return 34;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == FMSettingsSectionAutomation ||
        (indexPath.section == FMSettingsSectionGeneral &&
         indexPath.row == 2)) {
        FMSettingsToggleCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"SettingsToggleCell"
                                            forIndexPath:indexPath];
        if (indexPath.section == FMSettingsSectionAutomation) {
            [cell configureAutomaticRespringEnabled:self.automaticRespringEnabled
                                             loaded:self.automaticRespringPolicyLoaded
                                           updating:self.automaticRespringUpdateInFlight
                                              target:self
                                              action:@selector(automaticRespringSwitchChanged:)];
            cell.accessibilityIdentifier = @"settings_auto_respring";
        } else {
            [cell configureWithTitle:FMLocalized(@"跟随系统深浅模式")
                            subtitle:FMLocalized(@"关闭后固定使用浅色外观")
                              symbol:@"circle.lefthalf.filled"
                               color:FMAccentColor()
                          disclosure:NO
                         destructive:NO];
            cell.chevron.hidden = YES;
            [cell.toggle removeTarget:nil action:NULL
                     forControlEvents:UIControlEventValueChanged];
            [cell.toggle setOn:FMFollowSystemAppearanceEnabled() animated:NO];
            [cell.toggle addTarget:self
                            action:@selector(appearanceSwitchChanged:)
                  forControlEvents:UIControlEventValueChanged];
            cell.toggle.accessibilityLabel = FMLocalized(@"跟随系统深浅模式");
            cell.accessibilityIdentifier = @"settings_follow_system_appearance";
        }
        return cell;
    }

    FMSettingsActionCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"SettingsActionCell"
                                        forIndexPath:indexPath];
    cell.chevron.image = [UIImage systemImageNamed:@"chevron.right"];
    cell.chevron.hidden = NO;
    cell.accessoryView = nil;
    cell.accessibilityHint = nil;
    if (indexPath.section == FMSettingsSectionGeneral &&
        indexPath.row == 0) {
        [cell configureWithTitle:FMLocalized(@"语言")
                        subtitle:FMLanguagePreferenceDisplayName(FMLanguagePreference())
                          symbol:@"globe"
                           color:FMAccentColor()
                      disclosure:YES
                     destructive:NO];
        cell.accessibilityHint = FMLocalized(@"选择 App 的显示语言");
        cell.accessibilityIdentifier = @"settings_language";
    } else if (indexPath.section == FMSettingsSectionGeneral &&
               indexPath.row == 1) {
        [cell configureWithTitle:FMLocalized(@"默认字体路径")
                        subtitle:@"/System/Library/Fonts"
                          symbol:@"folder"
                           color:FMAccentColor()
                      disclosure:NO
                     destructive:NO];
        cell.chevron.hidden = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessibilityIdentifier = @"settings_default_font_path";
    } else if (indexPath.section == FMSettingsSectionDevice) {
        [cell configureWithTitle:FMLocalized(@"运行环境")
                        subtitle:FMLocalized(@"查看组件、字体连接与恢复准备")
                          symbol:@"checkmark.shield.fill"
                           color:FMAccentColor()
                      disclosure:YES
                     destructive:NO];
        cell.accessibilityIdentifier = @"settings_environment";
    } else if (indexPath.row == 0) {
        [cell configureWithTitle:FMLocalized(@"作者")
                        subtitle:@"Hmmzzz"
                          symbol:@"person.crop.circle.fill"
                           color:FMAccentColor()
                      disclosure:NO
                     destructive:NO];
        cell.accessibilityIdentifier = @"settings_author";
    } else if (indexPath.row == 1) {
        [cell configureWithTitle:FMLocalized(@"免责声明")
                        subtitle:FMLocalized(@"字体授权、使用责任与风险说明")
                          symbol:@"hand.raised.fill"
                           color:FMAccentColor()
                      disclosure:YES
                     destructive:NO];
        cell.accessibilityHint = FMLocalized(@"查看免责声明");
        cell.accessibilityIdentifier = @"settings_disclaimer";
    } else {
        [cell configureWithTitle:FMLocalized(@"致谢")
                        subtitle:FMLocalized(@"感谢开源项目与社区贡献者")
                          symbol:@"heart.fill"
                           color:FMAccentColor()
                      disclosure:YES
                     destructive:NO];
        cell.accessibilityIdentifier = @"settings_acknowledgements";
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (indexPath.section == FMSettingsSectionGeneral) {
        return indexPath.row == 0;
    }
    return indexPath.section == FMSettingsSectionDevice ||
        (indexPath.section == FMSettingsSectionAbout && indexPath.row != 0);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == FMSettingsSectionAutomation) return;
    if (indexPath.section == FMSettingsSectionGeneral) {
        [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
        if (indexPath.row == 0) {
            FMLanguageSelectionViewController *languages =
                [[FMLanguageSelectionViewController alloc] init];
            [self.navigationController pushViewController:languages animated:YES];
        }
        return;
    }
    if (indexPath.section == FMSettingsSectionAbout) {
        if (indexPath.row == 1) {
            [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
            FMSettingsDisclaimerViewController *disclaimer =
                [[FMSettingsDisclaimerViewController alloc] init];
            [self.navigationController pushViewController:disclaimer animated:YES];
        } else if (indexPath.row == 2) {
            [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
            FMSettingsCreditsViewController *credits = [[FMSettingsCreditsViewController alloc] init];
            [self.navigationController pushViewController:credits animated:YES];
        }
        return;
    }
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
    id<FMProfileWorkspace> workspace = self.workspace;
    FMCompatibilityStatusLoader loader = ^(FMCompatibilityLoadCompletion completion) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSError *error = nil;
            NSDictionary *status = nil;
            if ([workspace respondsToSelector:@selector(environmentStatus:)]) {
                status = [workspace environmentStatus:&error];
            } else {
                error = [NSError errorWithDomain:@"com.hmmzzz.fontmanager.environment-ui"
                                             code:1
                                         userInfo:@{
                    NSLocalizedDescriptionKey : FMLocalized(@"当前版本无法读取运行环境。")
                }];
            }
            completion(status, error);
        });
    };
    FMCompatibilityViewController *environment =
        [[FMCompatibilityViewController alloc] initWithEnvironmentStatus:nil
                                                              statusLoader:loader];
    [self.navigationController pushViewController:environment animated:YES];
}

- (void)closeSettings:(id)sender {
    (void)sender;
    if (self.dismissalHandler != nil) self.dismissalHandler();
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
