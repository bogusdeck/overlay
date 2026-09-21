#import "overlay.h"
#import "_cgo_export.h"
#import <Vision/Vision.h>

@interface HUDWindow : NSPanel <NSTextFieldDelegate>
@property (strong) NSTextView *textView;
@property (strong) NSScrollView *scrollView;
@property (strong) NSTextField *inputField;
@property (strong) NSView *inputContainer;
@property (strong) NSButton *pasteBtn;
@property (strong) NSButton *snapBtn;
@property (strong) NSButton *hideBtn;
@property (strong) NSTextField *indexLabel;
@property (strong) NSVisualEffectView *effectView;
@end

@implementation HUDWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (void)onInputSubmit:(id)sender {
    NSString *text = [self.inputField stringValue];
    if ([text length] > 0) {
        [self.inputField setStringValue:@""];
        goOnSubmitPrompt((char *)[text UTF8String]);
    }
}

- (void)onPasteClick:(id)sender {
    goHotkeyTranslate();
}

- (void)onSnapClick:(id)sender {
    PerformScreenCaptureOCR();
}

- (void)onHideClick:(id)sender {
    ToggleHUDVisibility();
}

@end

@interface HUDInputField : NSTextField
@end

@implementation HUDInputField
- (BOOL)acceptsFirstResponder {
    return YES;
}

- (NSCursor *)cursor {
    return [NSCursor arrowCursor];
}

- (void)resetCursorRects {
    [self discardCursorRects];
    [self addCursorRect:[self bounds] cursor:[NSCursor arrowCursor]];
}

- (void)cursorUpdate:(NSEvent *)event {
    [[NSCursor arrowCursor] set];
}

- (void)mouseMoved:(NSEvent *)event {
    [[NSCursor arrowCursor] set];
}

- (void)mouseDown:(NSEvent *)event {
    [[self window] makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [super mouseDown:event];
}
@end

@interface HUDTextView : NSTextView
@end

@implementation HUDTextView
- (NSCursor *)cursor {
    return [NSCursor arrowCursor];
}

- (void)resetCursorRects {
    [self discardCursorRects];
    [self addCursorRect:[self bounds] cursor:[NSCursor arrowCursor]];
}

- (void)cursorUpdate:(NSEvent *)event {
    [[NSCursor arrowCursor] set];
}

- (void)mouseMoved:(NSEvent *)event {
    [[NSCursor arrowCursor] set];
}
@end

@interface HUDCursorView : NSView
@end

@implementation HUDCursorView
- (NSCursor *)cursor {
    return [NSCursor arrowCursor];
}

- (void)resetCursorRects {
    [super resetCursorRects];
    [self discardCursorRects];
    [self addCursorRect:[self bounds] cursor:[NSCursor arrowCursor]];
}

- (void)cursorUpdate:(NSEvent *)event {
    [[NSCursor arrowCursor] set];
}

- (void)mouseMoved:(NSEvent *)event {
    [[NSCursor arrowCursor] set];
}

- (void)layout {
    [super layout];
    NSRect bounds = [self bounds];
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;

    if (self.window && [self.window isKindOfClass:[HUDWindow class]]) {
        HUDWindow *hud = (HUDWindow *)self.window;
        CGFloat topBarY = height - 29;

        if (hud.inputContainer) {
            CGFloat inputW = width - 156;
            if (inputW < 100) inputW = 100;
            [hud.inputContainer setFrame:NSMakeRect(8, topBarY, inputW, 24)];
        }
        if (hud.pasteBtn) {
            [hud.pasteBtn setFrame:NSMakeRect(width - 140, height - 28, 24, 22)];
        }
        if (hud.snapBtn) {
            [hud.snapBtn setFrame:NSMakeRect(width - 112, height - 28, 24, 22)];
        }
        if (hud.hideBtn) {
            [hud.hideBtn setFrame:NSMakeRect(width - 84, height - 28, 24, 22)];
        }
        if (hud.indexLabel) {
            [hud.indexLabel setFrame:NSMakeRect(width - 54, height - 27, 46, 18)];
        }
        if (hud.scrollView) {
            CGFloat scrollH = height - 44;
            if (scrollH < 10) scrollH = 10;
            [hud.scrollView setFrame:NSMakeRect(8, 8, width - 16, scrollH)];
        }
    }
}
@end

@interface VerticallyCenteredTextFieldCell : NSTextFieldCell
@end

@implementation VerticallyCenteredTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSFont *cellFont = [self font] ? [self font] : [NSFont systemFontOfSize:12.0];
    NSSize titleSize = [[self attributedStringValue] size];
    if (titleSize.height == 0) {
        titleSize = [@"A" sizeWithAttributes:@{NSFontAttributeName: cellFont}];
    }
    CGFloat delta = theRect.size.height - titleSize.height;
    if (delta > 0) {
        titleFrame.origin.y = theRect.origin.y + (delta / 2.0);
        titleFrame.size.height = titleSize.height;
    }
    titleFrame.origin.x += 4.0;
    titleFrame.size.width -= 8.0;
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [super drawInteriorWithFrame:titleRect inView:controlView];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    NSRect titleRect = [self titleRectForBounds:aRect];
    [super selectWithFrame:titleRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

@end

static HUDWindow *gHUDWindow = nil;
static float gHUDOpacity = 0.88;
static NSString *gHUDFontName = @"Menlo";
static float gHUDFontSize = 11.5;

void SetHUDOpacity(float opacityPercentage) {
    float alpha = opacityPercentage / 100.0;
    if (alpha < 0.1) alpha = 0.1;
    if (alpha > 1.0) alpha = 1.0;
    gHUDOpacity = alpha;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gHUDWindow) {
            [gHUDWindow setAlphaValue:gHUDOpacity];
            HUDCursorView *contentView = (HUDCursorView *)[gHUDWindow contentView];
            [contentView.layer setBackgroundColor:[[NSColor colorWithCalibratedWhite:0.10 alpha:gHUDOpacity] CGColor]];
        }
    });
}

void SetHUDFontConfig(const char* fontName, float fontSize) {
    if (fontName && strlen(fontName) > 0) {
        gHUDFontName = [NSString stringWithUTF8String:fontName];
    }
    if (fontSize >= 8.0 && fontSize <= 36.0) {
        gHUDFontSize = fontSize;
    }
}

static HUDWindow* createHUDWindow() {
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    CGFloat width = 360;
    CGFloat height = 34; // Ultra-compact top bar at start
    CGFloat x = screenFrame.origin.x + (screenFrame.size.width - width) / 2.0;
    CGFloat y = screenFrame.origin.y + screenFrame.size.height - height - 1;

    NSRect frame = NSMakeRect(x, y, width, height);
    HUDWindow *window = [[HUDWindow alloc] initWithContentRect:frame
                                                     styleMask:NSWindowStyleMaskNonactivatingPanel
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];

    [window setLevel:NSFloatingWindowLevel];
    [window setOpaque:NO];
    [window setAlphaValue:gHUDOpacity];
    [window setBackgroundColor:[NSColor clearColor]];
    [window setHasShadow:NO];
    [window setSharingType:NSWindowSharingNone];
    [window setMovableByWindowBackground:YES];
    [window setIgnoresMouseEvents:NO];
    [window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorIgnoresCycle];

    HUDCursorView *contentView = [[HUDCursorView alloc] initWithFrame:frame];
    [contentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [contentView setWantsLayer:YES];
    [contentView.layer setCornerRadius:10.0];
    [contentView.layer setMasksToBounds:YES];
    [contentView.layer setBackgroundColor:[[NSColor colorWithCalibratedWhite:0.10 alpha:gHUDOpacity] CGColor]];
    [contentView.layer setBorderColor:[[NSColor colorWithCalibratedWhite:1.0 alpha:0.15] CGColor]];
    [contentView.layer setBorderWidth:0.8];
    [window setContentView:contentView];

    // 1. Scrollable Response Area (Added FIRST so top bar controls render above it in Z-order)
    NSRect scrollFrame = NSMakeRect(8, 8, width - 16, height - 44);
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
    [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [scrollView setWantsLayer:YES];
    [scrollView.layer setMasksToBounds:YES];
    [scrollView setHasVerticalScroller:NO];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setDrawsBackground:NO];
    [scrollView setBorderType:NSNoBorder];

    HUDTextView *textView = [[HUDTextView alloc] initWithFrame:[scrollView bounds]];
    [textView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [textView setTextContainerInset:NSMakeSize(4, 6)];
    [[textView textContainer] setLineFragmentPadding:0.0];
    [textView setDrawsBackground:NO];
    [textView setEditable:NO];
    [textView setSelectable:YES];
    [textView setTextColor:[NSColor whiteColor]];
    [textView setFont:[NSFont userFixedPitchFontOfSize:11.5]];
    [scrollView setDocumentView:textView];
    [contentView addSubview:scrollView];
    window.textView = textView;
    window.scrollView = scrollView;

    // 2. Outer Rounded Container Pill for Input Field (Added AFTER scrollView)
    NSRect inputContainerFrame = NSMakeRect(8, height - 29, 205, 24);
    NSView *inputContainer = [[NSView alloc] initWithFrame:inputContainerFrame];
    [inputContainer setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    [inputContainer setWantsLayer:YES];
    [inputContainer.layer setCornerRadius:7.0];
    [inputContainer.layer setMasksToBounds:YES];
    [inputContainer.layer setBackgroundColor:[[NSColor colorWithCalibratedWhite:1.0 alpha:0.12] CGColor]];
    [inputContainer.layer setBorderColor:[[NSColor colorWithCalibratedWhite:1.0 alpha:0.20] CGColor]];
    [inputContainer.layer setBorderWidth:0.8];
    [contentView addSubview:inputContainer];
    window.inputContainer = inputContainer;

    // Input Field inside container with padding and key-focus activation
    NSRect inputFieldFrame = NSMakeRect(4, 0, inputContainerFrame.size.width - 8, inputContainerFrame.size.height);
    HUDInputField *inputField = [[HUDInputField alloc] initWithFrame:inputFieldFrame];
    [inputField setCell:[[VerticallyCenteredTextFieldCell alloc] initTextCell:@""]];
    [inputField setStringValue:@""];
    [inputField setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [inputField setPlaceholderString:@"Ask AI assistant..."];
    [inputField setBezeled:NO];
    [inputField setFocusRingType:NSFocusRingTypeNone];
    [inputField setDrawsBackground:NO];
    [inputField setEditable:YES];
    [inputField setSelectable:YES];
    [inputField setTextColor:[NSColor whiteColor]];
    [inputField setFont:[NSFont systemFontOfSize:12.0 weight:NSFontWeightMedium]];
    [inputField setTarget:window];
    [inputField setAction:@selector(onInputSubmit:)];
    [inputContainer addSubview:inputField];
    window.inputField = inputField;

    // Paste Icon Button (SF Symbol)
    NSButton *pasteBtn = [[NSButton alloc] initWithFrame:NSMakeRect(219, height - 28, 24, 22)];
    [pasteBtn setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [pasteBtn setImage:[NSImage imageWithSystemSymbolName:@"doc.on.clipboard" accessibilityDescription:@"Paste"]];
    [pasteBtn setImagePosition:NSImageOnly];
    [pasteBtn setBordered:NO];
    [pasteBtn setTarget:window];
    [pasteBtn setAction:@selector(onPasteClick:)];
    [contentView addSubview:pasteBtn];
    window.pasteBtn = pasteBtn;

    // Snap OCR Icon Button (SF Symbol)
    NSButton *snapBtn = [[NSButton alloc] initWithFrame:NSMakeRect(247, height - 28, 24, 22)];
    [snapBtn setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [snapBtn setImage:[NSImage imageWithSystemSymbolName:@"camera" accessibilityDescription:@"Snap"]];
    [snapBtn setImagePosition:NSImageOnly];
    [snapBtn setBordered:NO];
    [snapBtn setTarget:window];
    [snapBtn setAction:@selector(onSnapClick:)];
    [contentView addSubview:snapBtn];
    window.snapBtn = snapBtn;

    // Hide Icon Button (SF Symbol: Crisp xmark circle)
    NSButton *hideBtn = [[NSButton alloc] initWithFrame:NSMakeRect(275, height - 28, 24, 22)];
    [hideBtn setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [hideBtn setImage:[NSImage imageWithSystemSymbolName:@"xmark.circle.fill" accessibilityDescription:@"Hide"]];
    [hideBtn setImagePosition:NSImageOnly];
    [hideBtn setBordered:NO];
    [hideBtn setTarget:window];
    [hideBtn setAction:@selector(onHideClick:)];
    [contentView addSubview:hideBtn];
    window.hideBtn = hideBtn;

    // Index Counter Label (Tight placement right after icons)
    NSRect indexFrame = NSMakeRect(305, height - 27, 48, 18);
    NSTextField *indexLabel = [[NSTextField alloc] initWithFrame:indexFrame];
    [indexLabel setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [indexLabel setStringValue:@"[0/0]"];
    [indexLabel setBezeled:NO];
    [indexLabel setDrawsBackground:NO];
    [indexLabel setEditable:NO];
    [indexLabel setSelectable:NO];
    [indexLabel setTextColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
    [indexLabel setFont:[NSFont systemFontOfSize:11.0 weight:NSFontWeightMedium]];
    [contentView addSubview:indexLabel];
    window.indexLabel = indexLabel;

    return window;
}

void SetupHUDWindow(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!gHUDWindow) {
            gHUDWindow = createHUDWindow();
            [gHUDWindow orderFrontRegardless];
        }
    });
}

NSAttributedString *RenderMarkdownToAttributedString(NSString *markdownText) {
    if (!markdownText || [markdownText length] == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    NSArray *lines = [markdownText componentsSeparatedByString:@"\n"];
    BOOL inCodeBlock = NO;

    NSFont *baseFont = nil;
    if (gHUDFontName && ![gHUDFontName isEqualToString:@""] && ![gHUDFontName isEqualToString:@"system"]) {
        baseFont = [NSFont fontWithName:gHUDFontName size:gHUDFontSize];
    }
    if (!baseFont) {
        baseFont = [NSFont userFixedPitchFontOfSize:gHUDFontSize];
    }

    NSFont *codeFont = nil;
    if (gHUDFontName && ![gHUDFontName isEqualToString:@""] && ![gHUDFontName isEqualToString:@"system"]) {
        codeFont = [NSFont fontWithName:gHUDFontName size:gHUDFontSize - 0.5];
    }
    if (!codeFont) {
        codeFont = [NSFont userFixedPitchFontOfSize:gHUDFontSize - 0.5];
    }

    NSFont *headerFont = [NSFont systemFontOfSize:gHUDFontSize + 1.5 weight:NSFontWeightBold];
    NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:baseFont toHaveTrait:NSBoldFontMask];
    if (!boldFont) boldFont = baseFont;

    NSColor *baseColor = [NSColor colorWithCalibratedWhite:0.92 alpha:1.0];
    NSColor *headerColor = [NSColor colorWithCalibratedRed:0.35 green:0.78 blue:1.0 alpha:1.0];
    NSColor *keywordColor = [NSColor colorWithCalibratedRed:1.0 green:0.45 blue:0.65 alpha:1.0];
    NSColor *stringColor = [NSColor colorWithCalibratedRed:0.55 green:0.90 blue:0.50 alpha:1.0];
    NSColor *commentColor = [NSColor colorWithCalibratedWhite:0.55 alpha:1.0];
    NSColor *numberColor = [NSColor colorWithCalibratedRed:1.0 green:0.80 blue:0.35 alpha:1.0];
    NSColor *inlineCodeColor = [NSColor colorWithCalibratedRed:1.0 green:0.85 blue:0.40 alpha:1.0];
    NSColor *inlineCodeBg = [NSColor colorWithCalibratedWhite:0.20 alpha:0.8];
    NSColor *bulletColor = [NSColor colorWithCalibratedRed:0.40 green:0.80 blue:1.0 alpha:1.0];

    NSMutableParagraphStyle *defaultStyle = [[NSMutableParagraphStyle alloc] init];
    [defaultStyle setAlignment:NSTextAlignmentLeft];
    [defaultStyle setLineSpacing:2.0];

    for (NSInteger i = 0; i < [lines count]; i++) {
        NSString *line = lines[i];

        if ([line hasPrefix:@"```"]) {
            inCodeBlock = !inCodeBlock;
            continue;
        }

        if (inCodeBlock) {
            NSMutableAttributedString *codeLineAttr = [[NSMutableAttributedString alloc] initWithString:line attributes:@{
                NSFontAttributeName: codeFont,
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.88 green:0.92 blue:0.96 alpha:1.0],
                NSParagraphStyleAttributeName: defaultStyle
            }];

            // Comments
            NSRegularExpression *commentRegex = [NSRegularExpression regularExpressionWithPattern:@"(//.*|#.*)" options:0 error:nil];
            NSArray *commentMatches = [commentRegex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
            for (NSTextCheckingResult *match in commentMatches) {
                [codeLineAttr addAttribute:NSForegroundColorAttributeName value:commentColor range:match.range];
            }

            // Strings
            NSRegularExpression *stringRegex = [NSRegularExpression regularExpressionWithPattern:@"(\"[^\"]*\"|'[^']*')" options:0 error:nil];
            NSArray *stringMatches = [stringRegex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
            for (NSTextCheckingResult *match in stringMatches) {
                [codeLineAttr addAttribute:NSForegroundColorAttributeName value:stringColor range:match.range];
            }

            // Keywords
            NSRegularExpression *kwRegex = [NSRegularExpression regularExpressionWithPattern:@"\\b(def|class|return|if|else|elif|for|while|import|from|const|let|var|function|public|private|static|int|string|bool|void|true|false|null|nil|struct|switch|case|break|continue|new|try|catch|finally|throw|async|await|package|func|type)\\b" options:0 error:nil];
            NSArray *kwMatches = [kwRegex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
            for (NSTextCheckingResult *match in kwMatches) {
                [codeLineAttr addAttribute:NSForegroundColorAttributeName value:keywordColor range:match.range];
            }

            // Numbers
            NSRegularExpression *numRegex = [NSRegularExpression regularExpressionWithPattern:@"\\b[0-9]+\\b" options:0 error:nil];
            NSArray *numMatches = [numRegex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
            for (NSTextCheckingResult *match in numMatches) {
                [codeLineAttr addAttribute:NSForegroundColorAttributeName value:numberColor range:match.range];
            }

            [result appendAttributedString:codeLineAttr];
            if (i < [lines count] - 1) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            continue;
        }

        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        // Headers: #, ##, ###
        if ([trimmedLine hasPrefix:@"#"]) {
            NSRange firstSpace = [trimmedLine rangeOfString:@" "];
            NSString *headerText = (firstSpace.location != NSNotFound) ? [trimmedLine substringFromIndex:firstSpace.location + 1] : trimmedLine;
            
            NSMutableAttributedString *headerAttr = [[NSMutableAttributedString alloc] initWithString:headerText attributes:@{
                NSFontAttributeName: headerFont,
                NSForegroundColorAttributeName: headerColor,
                NSParagraphStyleAttributeName: defaultStyle
            }];
            [result appendAttributedString:headerAttr];
            if (i < [lines count] - 1) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            continue;
        }

        // Inline formatting: Bullets, **bold**, `inline code`
        NSMutableAttributedString *lineAttr = [[NSMutableAttributedString alloc] init];
        NSString *workLine = line;

        NSRegularExpression *bulletRegex = [NSRegularExpression regularExpressionWithPattern:@"^(\\s*)(-|\\*|\\d+\\.)(\\s+)" options:0 error:nil];
        NSTextCheckingResult *bulletMatch = [bulletRegex firstMatchInString:workLine options:0 range:NSMakeRange(0, [workLine length])];
        if (bulletMatch) {
            NSString *bulletSymbol = [workLine substringWithRange:bulletMatch.range];
            NSAttributedString *bulletAttr = [[NSAttributedString alloc] initWithString:bulletSymbol attributes:@{
                NSFontAttributeName: baseFont,
                NSForegroundColorAttributeName: bulletColor,
                NSParagraphStyleAttributeName: defaultStyle
            }];
            [lineAttr appendAttributedString:bulletAttr];
            workLine = [workLine substringFromIndex:NSMaxRange(bulletMatch.range)];
        }

        NSRegularExpression *inlineRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\*\\*|__)(.*?)\\1|`([^`]+)`" options:0 error:nil];
        NSArray *matches = [inlineRegex matchesInString:workLine options:0 range:NSMakeRange(0, [workLine length])];

        NSUInteger lastIdx = 0;
        for (NSTextCheckingResult *m in matches) {
            if (m.range.location > lastIdx) {
                NSString *plainChunk = [workLine substringWithRange:NSMakeRange(lastIdx, m.range.location - lastIdx)];
                [lineAttr appendAttributedString:[[NSAttributedString alloc] initWithString:plainChunk attributes:@{
                    NSFontAttributeName: baseFont,
                    NSForegroundColorAttributeName: baseColor,
                    NSParagraphStyleAttributeName: defaultStyle
                }]];
            }

            NSString *matchText = [workLine substringWithRange:m.range];
            if ([matchText hasPrefix:@"`"] && [matchText hasSuffix:@"`"] && [matchText length] >= 2) {
                NSString *codeText = [matchText substringWithRange:NSMakeRange(1, [matchText length] - 2)];
                [lineAttr appendAttributedString:[[NSAttributedString alloc] initWithString:codeText attributes:@{
                    NSFontAttributeName: codeFont,
                    NSForegroundColorAttributeName: inlineCodeColor,
                    NSBackgroundColorAttributeName: inlineCodeBg,
                    NSParagraphStyleAttributeName: defaultStyle
                }]];
            } else if (([matchText hasPrefix:@"**"] && [matchText hasSuffix:@"**"] && [matchText length] >= 4) ||
                       ([matchText hasPrefix:@"__"] && [matchText hasSuffix:@"__"] && [matchText length] >= 4)) {
                NSString *boldText = [matchText substringWithRange:NSMakeRange(2, [matchText length] - 4)];
                [lineAttr appendAttributedString:[[NSAttributedString alloc] initWithString:boldText attributes:@{
                    NSFontAttributeName: boldFont,
                    NSForegroundColorAttributeName: [NSColor whiteColor],
                    NSParagraphStyleAttributeName: defaultStyle
                }]];
            } else {
                [lineAttr appendAttributedString:[[NSAttributedString alloc] initWithString:matchText attributes:@{
                    NSFontAttributeName: baseFont,
                    NSForegroundColorAttributeName: baseColor,
                    NSParagraphStyleAttributeName: defaultStyle
                }]];
            }

            lastIdx = NSMaxRange(m.range);
        }

        if (lastIdx < [workLine length]) {
            NSString *tailChunk = [workLine substringFromIndex:lastIdx];
            [lineAttr appendAttributedString:[[NSAttributedString alloc] initWithString:tailChunk attributes:@{
                NSFontAttributeName: baseFont,
                NSForegroundColorAttributeName: baseColor,
                NSParagraphStyleAttributeName: defaultStyle
            }]];
        }

        [result appendAttributedString:lineAttr];
        if (i < [lines count] - 1) {
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
    }

    return result;
}

void ShowHUDText(const char* text) {
    NSString *nsText = [NSString stringWithUTF8String:text ? text : ""];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gHUDWindow) {
            [gHUDWindow setSharingType:NSWindowSharingNone];
            BOOL isLoading = [nsText hasSuffix:@"...)"] || [nsText containsString:@"Thinking"];

            if (isLoading) {
                NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
                [style setAlignment:NSTextAlignmentCenter];
                NSDictionary *attrs = @{
                    NSFontAttributeName: [NSFont systemFontOfSize:12.0 weight:NSFontWeightMedium],
                    NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.85 alpha:1.0],
                    NSParagraphStyleAttributeName: style
                };
                NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n\n\n%@", nsText] attributes:attrs];
                [[gHUDWindow.textView textStorage] setAttributedString:attrStr];
            } else {
                NSAttributedString *attrStr = RenderMarkdownToAttributedString(nsText);
                [[gHUDWindow.textView textStorage] setAttributedString:attrStr];
            }

            NSRect frame = [gHUDWindow frame];
            if (frame.size.height < 100 && [nsText length] > 0) {
                CGFloat targetWidth = 450;
                CGFloat targetHeight = 260;
                CGFloat dx = targetWidth - frame.size.width;
                CGFloat dy = targetHeight - frame.size.height;
                frame.origin.x -= (dx / 2.0);
                frame.origin.y -= dy;
                frame.size.width = targetWidth;
                frame.size.height = targetHeight;
                [gHUDWindow setFrame:frame display:YES animate:YES];
            }

            [gHUDWindow orderFrontRegardless];
        }
    });
}

void SetHUDIndexText(const char* text) {
    NSString *nsText = [NSString stringWithUTF8String:text ? text : ""];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gHUDWindow && gHUDWindow.indexLabel) {
            [gHUDWindow.indexLabel setStringValue:nsText];
        }
    });
}

void ToggleHUDVisibility(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gHUDWindow) {
            if ([gHUDWindow isVisible]) {
                [gHUDWindow orderOut:nil];
            } else {
                [gHUDWindow makeKeyAndOrderFront:nil];
                [NSApp activateIgnoringOtherApps:YES];
            }
        }
    });
}

void MoveHUDWindow(int dx, int dy) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gHUDWindow) {
            NSRect frame = [gHUDWindow frame];
            frame.origin.x += dx;
            frame.origin.y += dy;
            [gHUDWindow setFrame:frame display:YES animate:YES];
        }
    });
}

void ResizeHUDWindow(int dw, int dh) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gHUDWindow) {
            NSRect frame = [gHUDWindow frame];
            frame.size.width += dw;
            frame.size.height += dh;
            if (frame.size.width < 300) frame.size.width = 300;
            if (frame.size.height < 34) frame.size.height = 34;
            [gHUDWindow setFrame:frame display:YES animate:YES];
        }
    });
}

void SetHUDCursorStandard(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSCursor arrowCursor] set];
    });
}

static bool gReqCmd = true;
static bool gReqCtrl = true;
static bool gReqFn = true;
static bool gReqAlt = false;
static bool gReqShift = false;

void SetLeaderModifiers(bool cmd, bool ctrl, bool fn, bool alt, bool shift) {
    gReqCmd = cmd;
    gReqCtrl = ctrl;
    gReqFn = fn;
    gReqAlt = alt;
    gReqShift = shift;
}

bool CheckLeaderModifiers(CGEventFlags flags) {
    bool hasCmd = (flags & kCGEventFlagMaskCommand) != 0;
    bool hasCtrl = (flags & kCGEventFlagMaskControl) != 0;
    bool hasFn = (flags & kCGEventFlagMaskSecondaryFn) != 0;
    bool hasAlt = (flags & kCGEventFlagMaskAlternate) != 0;
    bool hasShift = (flags & kCGEventFlagMaskShift) != 0;

    if (gReqCmd && !hasCmd) return false;
    if (gReqCtrl && !hasCtrl) return false;
    if (gReqFn && !hasFn) return false;
    if (gReqAlt && !hasAlt) return false;
    if (gReqShift && !hasShift) return false;

    return true;
}

void PerformScreenCaptureOCR(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        system("screencapture -x /tmp/overlay_snap.png");

        NSData *imageData = [NSData dataWithContentsOfFile:@"/tmp/overlay_snap.png"];
        if (!imageData) return;

        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        if (!source) return;
        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
        if (!cgImage) return;

        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *req, NSError *error) {
            if (error) return;
            NSMutableString *extracted = [NSMutableString string];
            for (VNRecognizedTextObservation *obs in req.results) {
                VNRecognizedText *text = [[obs topCandidates:1] firstObject];
                if (text) {
                    [extracted appendString:text.string];
                    [extracted appendString:@"\n"];
                }
            }
            if ([extracted length] > 0) {
                goOnSubmitScreenCapture((char *)[extracted UTF8String]);
            }
        }];
        [request setRecognitionLevel:VNRequestTextRecognitionLevelAccurate];

        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
        [handler performRequests:@[request] error:nil];
        CGImageRelease(cgImage);
    });
}

static CFMachPortRef gEventTap = NULL;

static CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type == kCGEventKeyDown) {
        CGEventFlags flags = CGEventGetFlags(event);
        if (CheckLeaderModifiers(flags)) {
            int64_t keycode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
            switch (keycode) {
                case 35: // 'p'
                    goHotkeyTranslate();
                    return NULL;
                case 1: // 's' (Screen Capture & Vision OCR)
                    goHotkeySnapOCR();
                    return NULL;
                case 4: // 'h' (Toggle Hide/Show Overlay)
                    goHotkeyToggleOverlay();
                    return NULL;
                case 7: // 'x' (Kill / Stop Overlay Process completely)
                    goHotkeyKillApp();
                    return NULL;
                case 34: // 'i'
                    goHotkeyInstantAgy();
                    return NULL;
                case 47: // '.' (>)
                    goHotkeyNextCard();
                    return NULL;
                case 43: // ',' (<)
                    goHotkeyPrevCard();
                    return NULL;
                case 123: // Left Arrow
                case 115: // Home (Fn + Left Arrow)
                    goHotkeyMoveLeft();
                    return NULL;
                case 124: // Right Arrow
                case 119: // End (Fn + Right Arrow)
                    goHotkeyMoveRight();
                    return NULL;
                case 126: // Up Arrow
                case 116: // Page Up (Fn + Up Arrow)
                    goHotkeyMoveUp();
                    return NULL;
                case 125: // Down Arrow
                case 121: // Page Down (Fn + Down Arrow)
                    goHotkeyMoveDown();
                    return NULL;
                case 27: // '-'
                case 46: // 'm'
                    goHotkeyReduceSize();
                    return NULL;
                case 24: // '=' / '+'
                    goHotkeyExpandSize();
                    return NULL;
            }
        }
    }
    return event;
}

void StartGlobalHotkeys(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGEventMask mask = CGEventMaskBit(kCGEventKeyDown);
        gEventTap = CGEventTapCreate(
            kCGSessionEventTap,
            kCGHeadInsertEventTap,
            kCGEventTapOptionDefault,
            mask,
            eventTapCallback,
            NULL
        );

        if (!gEventTap) {
            NSLog(@"Failed to create CGEventTap. Please grant Accessibility permissions in System Settings.");
            return;
        }

        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, gEventTap, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CGEventTapEnable(gEventTap, true);
        CFRunLoopRun();
    });
}

void RunAppKitLoop(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    SetupHUDWindow();
    [NSApp run];
}
