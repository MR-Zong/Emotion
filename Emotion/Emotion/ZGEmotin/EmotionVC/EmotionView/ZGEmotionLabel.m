//
//  ZGEmotionLabel.m
//  TestEmotionUILabel
//
//  Created by Zong on 15/12/15.
//  Copyright © 2015年 Zong. All rights reserved.
//

#import "ZGEmotionLabel.h"
#import "EmojiBoardView.h"
#import <CoreText/CoreText.h>


static NSString *const facePrefix = @"[/";
static NSString *const faceSuffix = @"]";
static NSString *const faceSpace = @" ";
static NSString *const faceImageName = @"imageName";
static CGFloat const _maxFloat_ = 8388608.0;
static NSInteger  emotionImageWidth ; // 推荐24

#define _facePadding_ 3.0
#define _textPadding_ 5.0



@implementation ZGEmotionLabel
{
    NSAttributedString *_faceAttributeString;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        //        emotionImageWidth = [UIFont systemFontOfSize:self.font.pointSize -1].lineHeight;
        //        self.minLineHeight = [UIFont systemFontOfSize:self.font.pointSize -1].lineHeight;
        //        self.wordInset = 0.5;
        emotionImageWidth = self.font.lineHeight;
        self.minLineHeight = self.font.lineHeight;
        self.wordInset = 1.0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // 翻转坐标系
    CGContextRef contxt = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(contxt, CGAffineTransformIdentity);
    
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, self.bounds.size.height);
    CGContextConcatCTM(contxt, flipVertical);
    
    if(self.text == nil || [self.text isEqual:[NSNull null]]) return;

//    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self getAttributedTextFromString:self.text]];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:_faceAttributeString];

//    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:self.font.pointSize -1] range:NSMakeRange(0, [attributedString length])];
//     [attributedString addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, [attributedString length])];
    
    CTFramesetterRef ctFrameSetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)attributedString);
    CGMutablePathRef path = CGPathCreateMutable();

    CGRect bounds = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
//    NSStringDrawingOptions options =  NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
//     CGRect bounds = [self.text boundingRectWithSize:CGSizeMake(self.bounds.size.width, MAXFLOAT) options:options attributes:@{NSFontAttributeName: self.font} context:nil];

    
    CGPathAddRect(path, NULL, bounds);
    
    CTFrameRef ctFrame = CTFramesetterCreateFrame(ctFrameSetter, CFRangeMake(0, 0), path, NULL);
//    CGContextSetTextPosition(contxt, lineOrigin.x, lineOrigin.y-descent-self.font.descender);
    CTFrameDraw(ctFrame, contxt);
    
    // 开始画图片
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CGPoint lineOrigins [CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    
    for (int i = 0; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading;
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        for (int j = 0; j < CFArrayGetCount(runs); j++) {
            CGFloat runAscent;
            CGFloat runDescent;
            CGPoint lineOrigin = lineOrigins[i];
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            NSDictionary* attributes = (NSDictionary*)CTRunGetAttributes(run);
            CGRect runRect;
            runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
            
            runRect=CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y - runDescent, runRect.size.width, runAscent + runDescent);
            
            NSString *imageName = [attributes objectForKey:faceImageName];
            
            if (imageName)
            {
                UIImage *image = [UIImage imageNamed:imageName];
                if (image)
                {
                    CGRect imageDrawRect;
//                    imageDrawRect.size = image.size;
                    imageDrawRect.size = CGSizeMake(emotionImageWidth, emotionImageWidth);
                    imageDrawRect.origin.x = runRect.origin.x + lineOrigin.x;
                    imageDrawRect.origin.y = lineOrigin.y -5;//;+lineDescent+10;// 怎么精确计算
                    CGContextDrawImage(contxt, imageDrawRect, image.CGImage);
                }
            }
        }
    }
    
    
    CFRelease(ctFrame);
    CFRelease(path);
    CFRelease(ctFrameSetter);
}


#pragma mark - setText
- (void)setText:(NSString *)text
{
    [super setText: text];
    _faceAttributeString = [self getAttributedTextFromString:text];
}


#pragma mark-CTRunDelegateCallbacks

void RunDelegateDeallocCallback(void* refCon)
{
    
}

CGFloat RunDelegateGetAscentCallback(void* refCon)
{

    return 0;
}

CGFloat RunDelegateGetDescentCallback(void* refCon)
{
    return 5.0;
}

CGFloat RunDelegateGetWidthCallback(void* refCon)
{
//    return [UIImage imageNamed:(__bridge NSString *) refCon].size.width + _facePadding_;
    return emotionImageWidth;
}


#pragma mark-private method
- (NSAttributedString*)getAttributedTextFromString:(NSString*) string
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
    
    if(string == nil || [string isEqual:[NSNull null]] || string.length <= 0) return nil;
    
    //获取表情
    [self faceRangeFromStr:string withAttributedText:attributedText];
//    self.font
    
    CTFontRef font = CTFontCreateWithName((CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    [attributedText addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)font  range:NSMakeRange(0, attributedText.length)];
    [attributedText addAttribute:(NSString*)kCTKernAttributeName value:[NSNumber numberWithFloat:self.wordInset] range:NSMakeRange(0, attributedText.length)];
    [attributedText addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)self.textColor.CGColor range:NSMakeRange(0, attributedText.length)];
    

    CTParagraphStyleSetting lineBreadMode;
//    CTLineBreakMode linkBreak = kCTLineBreakByCharWrapping;
    CTLineBreakMode linkBreak = kCTLineBreakByCharWrapping;
    lineBreadMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreadMode.value = &linkBreak;
    lineBreadMode.valueSize = sizeof(CTLineBreakMode);
    
    
    CTParagraphStyleSetting minLineHeightMode;
    CGFloat minLineHeight = self.minLineHeight;
    minLineHeightMode.spec = kCTParagraphStyleSpecifierMinimumLineHeight;
    minLineHeightMode.value = &minLineHeight;
    minLineHeightMode.valueSize = sizeof(CGFloat);
    
//    CGFloat lineSpace= 4.0;
//    CTParagraphStyleSetting lineSpaceStyle;
//    lineSpaceStyle.spec=kCTParagraphStyleSpecifierLineSpacing;
//    lineSpaceStyle.valueSize=sizeof(lineSpace);
//    lineSpaceStyle.value=&lineSpace;
    
    
//    CTTextAlignment alignment = kCTJustifiedTextAlignment;
    CTTextAlignment alignment = kCTTextAlignmentLeft;
    CTParagraphStyleSetting alignmentStyle;
    alignmentStyle.spec=kCTParagraphStyleSpecifierAlignment;
    alignmentStyle.valueSize=sizeof(alignment);
    alignmentStyle.value=&alignment;
    
    
    CTParagraphStyleSetting setting[] = {lineBreadMode,minLineHeightMode,alignmentStyle};
    
    CTParagraphStyleRef style = CTParagraphStyleCreate(setting, 3);
    [attributedText addAttribute:(NSString*)kCTParagraphStyleAttributeName value:(id)style range:NSMakeRange(0, attributedText.length)];

    CFRelease(style);
    CFRelease(font);
    
    return attributedText;
}



#pragma mark-图片筛选
- (void)faceRangeFromStr:(NSString*) str withAttributedText:(NSMutableAttributedString*) attributedText
{
    if(str == nil || [str isEqual:[NSNull null]] || str.length <= 0)
        return;
    if (attributedText == nil || [attributedText isEqual:[NSNull null]])
        return;
    
    NSRange prefixRange = [str rangeOfString:facePrefix];
    NSRange suffixRange = [str rangeOfString:faceSuffix];
    
    if(prefixRange.location != NSNotFound && suffixRange.location != NSNotFound && suffixRange.location > prefixRange.location)
    {
        NSString *forwordStr = [str substringToIndex:prefixRange.location];
        if(forwordStr.length > 0)
        {
            NSAttributedString *text = [[NSAttributedString alloc] initWithString:forwordStr];
            [attributedText appendAttributedString:text];

        }
        
        NSRange faceRange = NSMakeRange(prefixRange.location, suffixRange.location - prefixRange.location + suffixRange.length);
        NSString *faceName = [str substringWithRange:faceRange];
        
        NSString *imageName = [self getImageNameFromStr:faceName];
        
      
        CTRunDelegateCallbacks imageCallBack;
        imageCallBack.version = kCTRunDelegateVersion1;
        imageCallBack.dealloc = RunDelegateDeallocCallback;
        imageCallBack.getAscent = RunDelegateGetAscentCallback;
        imageCallBack.getDescent = RunDelegateGetDescentCallback;
        imageCallBack.getWidth = RunDelegateGetWidthCallback;
        
        CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallBack, (__bridge void * _Nullable)(imageName));
        
        if(runDelegate != NULL)
        {
            //设定图片属性
            NSMutableAttributedString *image = [[NSMutableAttributedString alloc] initWithString:faceSpace];
            [image addAttribute:(NSString*)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:NSMakeRange(0, faceSpace.length)];
            [image addAttribute:faceImageName value:imageName range:NSMakeRange(0, faceSpace.length)];

            [attributedText appendAttributedString:image];
            
            CFRelease(runDelegate);
        }
        
        NSString *backStr = [str substringFromIndex:suffixRange.location + suffixRange.length];
        
        if(backStr.length > 0)
        {
            [self faceRangeFromStr:backStr withAttributedText:attributedText];
        }
    }
    else
    {
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:str];
        [attributedText appendAttributedString:text];

    }
}

// 获取表情图片名称
- (NSString*)getImageNameFromStr:(NSString*) str
{
    
    return [EmojiBoardView EmojiImageNameFromCoder:str] ? [EmojiBoardView EmojiImageNameFromCoder:str] : @"fanxing_m19.png";
}

+ (CGSize)getHeightFromAttributedText:(NSAttributedString *)attributeString contraintWidth:(CGFloat)width maxShowNumberOfLines:(int )maxShowNumberOfLines countOfLines:(int *)countOfLines maxShowHeight:(int *)maxShowHeight
{
    if (attributeString == nil || [attributeString isEqual:[NSNull null]] || attributeString.length <= 0) {
        *countOfLines = 0;
        *maxShowHeight = 0;
        return CGSizeZero;
    }
    
    CGFloat totalHeight = 0;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) attributeString);
    if(framesetter == NULL)
        return CGSizeZero;
    
    CGRect drawRect = CGRectMake(0, 0, width,_maxFloat_);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawRect);
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    if(frame == NULL)
    {
        CFRelease(framesetter);
        if(path != NULL)
            CFRelease(path);
        return CGSizeZero;
    }
    
    
    CFRelease(framesetter);
    CFRelease(path);
    
    //获取行数和没行的起点
    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger count = CFArrayGetCount(lines);
    *countOfLines = (int)count;
    CGPoint lineOrigins[count];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    
    CGPoint lastLineOrigin = lineOrigins[count - 1]; //获取最后一行的起始坐标
    CGPoint maxShowLineOrigin = lineOrigins[maxShowNumberOfLines - 1];
    
    CGFloat descent;
    
    CTLineRef lastLine = CFArrayGetValueAtIndex(lines, count - 1);
    CTLineRef firstLine = CFArrayGetValueAtIndex(lines, 0);
    
    CTLineGetTypographicBounds(lastLine, NULL, &descent, NULL);
    
    CGFloat totalWidth = width;
    if(count == 1)
    {
        totalWidth = CTLineGetTypographicBounds(firstLine, NULL, NULL, NULL);
    }
    
    totalHeight += CGRectGetMaxY(drawRect) - lastLineOrigin.y + descent + 1.0 ;
    if (maxShowNumberOfLines > count) {
        *maxShowHeight = totalHeight;
    }else {
        *maxShowHeight = CGRectGetMaxY(drawRect) - maxShowLineOrigin.y + descent + 1.0 ;
    }
    CFRelease(frame);
    
    return CGSizeMake(totalWidth, totalHeight);

}

@end
