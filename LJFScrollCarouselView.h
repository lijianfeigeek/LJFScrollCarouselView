//
//  LJFScrollCarouselView.h
//  LJFScrollCarouselViewDemo
//
//  Created by lijianfei on 16/5/31.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import <UIKit/UIKit.h>

/*=====================*/
// 循环滚动tabelView视图 //
// 限制：要求cell高度一致 //
/*=====================*/

// 循环滚动TabelView视图 LJFScrollCarouselView 内的展示cell必须遵循此协议
@protocol LJFScrollCarouselViewCellPrt <NSObject>

@required

/**
 *  返回本类型cell的高度
 *
 *  @return 高度
 */
+ (CGFloat)cellClassHeight;


/**
 *  根据数据内容布局cell视图
 *
 *  @param data 数据内容
 */
- (void)configerCellWithData:(id)data;

@end

@protocol LJFScrollCarouselViewDelegate <NSObject>

// 返回点击的数据模型对象
- (void)callBackInArrayAllDataOfObject:(id)object;

@end

// LJFScrollCarouselView 的 cell 必须遵循协议 LJFScrollCarouselViewCellPrt
@interface LJFScrollCarouselView : UIView

@property (weak, nonatomic) id<LJFScrollCarouselViewDelegate> delegate;


/**
 *  根据数据计算高度
 *
 *  @param arrayAllData     数据内容
 *  @param pageContainCount 每页展示几个
 *  @param cellClassNameStr 展示cell的类名
 *
 *  @return 高度
 */
+ (CGFloat)heightWithArrayAllData:(NSArray *)arrayAllData
                 pageContainCount:(NSUInteger)pageContainCount
                 cellClassNameStr:(NSString *)cellClassNameStr;


/**
 *  自定义初始化方法
 *
 *  @param Origin           原点左边
 *  @param width            宽度
 *  @param arrayAllData     数据内容
 *  @param pageContainCount 每页展示几个
 *  @param cellClassNameStr 展示cell的类名
 *
 *  @return FScrollCarouselView 实例对象
 */
- (instancetype)initWithOrigin:(CGPoint)Origin
                         width:(CGFloat)width
                  arrayAllData:(NSArray *)arrayAllData
              pageContainCount:(NSUInteger)pageContainCount
              cellClassNameStr:(NSString *)cellClassNameStr;


/**
 *  刷新方法
 *
 *  @param arrayAllData     数据内容
 */
- (void)refreshWithArrayAllData:(NSArray *)arrayAllData;
@end
