//
//  LJFScrollCarouselView.m
//  LJFScrollCarouselViewDemo
//
//  Created by lijianfei on 16/5/31.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import "LJFScrollCarouselView.h"

#define kDisplayViewCount   3
#define kPageControlHeight  44

// 内部延展
@interface LJFScrollCarouselView ()<UIScrollViewDelegate,UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) UIScrollView *scrV;
@property (strong, nonatomic) UIPageControl *pageC;

@property (strong, nonatomic) NSArray *arrAllData;                  //所有数据
@property (strong, nonatomic) NSMutableArray *arrSectionsOfAllData; //分组后的所有数据

@property (strong, nonatomic) UITableView *viewOnly;
@property (strong, nonatomic) NSMutableArray *arrRowsOfViewOnly;

@property (strong, nonatomic) UITableView *viewLeft;
@property (strong, nonatomic) NSMutableArray *arrRowsOfViewLeft;

@property (strong, nonatomic) UITableView *viewCenter;
@property (strong, nonatomic) NSMutableArray *arrRowsOfViewCenter;

@property (strong, nonatomic) UITableView *viewRight;
@property (strong, nonatomic) NSMutableArray *arrRowsOfViewRight;

@property (strong, nonatomic) NSString *cellClassNameStr;

@property (assign, nonatomic) NSUInteger pageContainCount;
@property (assign, nonatomic) NSUInteger currentDisplayIndex;
@property (assign, nonatomic) NSUInteger displayTotalCount;
@property (assign, nonatomic) CGFloat cellHeight;


@end

@implementation LJFScrollCarouselView

+ (CGFloat)heightWithArrayAllData:(NSArray *)arrayAllData
                 pageContainCount:(NSUInteger)pageContainCount
                 cellClassNameStr:(NSString *)cellClassNameStr
{
    // 使用断言提示开发者
    NSAssert(arrayAllData != nil,     @"arrayAllData 不能为空");
    NSAssert(pageContainCount > 0,    @"pageContainCount 必须大于0");
    NSAssert(cellClassNameStr != nil, @"cellClassNameStr 不能为空");
    
    CGFloat cellHeight = 0;
    
    // 根据传入cell类型反射创建cell
    Class cellClass = NSClassFromString(cellClassNameStr);
    
    if ([cellClass conformsToProtocol:@protocol(LJFScrollCarouselViewCellPrt)])
    {
        cellHeight = [cellClass cellClassHeight];
    }
    else
    {
        NSString *notice = [NSString stringWithFormat:@"%@ 必须遵循 FScrollCarouselViewCellPrt 协议",cellClassNameStr];
        NSAssert(NO,notice);
    }
    
    // 计算
    CGFloat height = 0;
    NSInteger x = arrayAllData.count;
    NSInteger y = pageContainCount;
    NSInteger displayTotalCount = 0;
    
    if (x == 0)
        return height;
    
    displayTotalCount = (x+(y-1))/y;
    
    if (displayTotalCount == 1)
    {
        height = arrayAllData.count * cellHeight;
    }
    else if (displayTotalCount > 1)
    {
        height = pageContainCount * cellHeight + kPageControlHeight;
    }
    
    return height;
}

- (void)refreshWithArrayAllData:(NSArray *)arrayAllData
{
    // 判断个数
    if (arrayAllData.count != _arrAllData.count)
    {
        // 当设置数据的时候，让其在 CFRunLoopDefaultMode 下进行。当滚动tableView的时候，RunLoop是在 UITrackingRunLoopMode 这个Mode下，就不会设置数据，当停止的时候，就会设置数据。
        [self performSelector:@selector(refreshInCFRunLoopDefaultModeWithArrayAllData:) withObject:arrayAllData afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
    }
    else
    {
        @autoreleasepool
        {
            // 两个数组个数相等
            for (id refreshItem in arrayAllData)
            {
                // 数组内的对象是否一样
                if (![_arrAllData containsObject:refreshItem])
                {
                    [self performSelector:@selector(refreshInCFRunLoopDefaultModeWithArrayAllData:) withObject:arrayAllData afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
                    
                    break;
                }
            }
        }
    }
}

- (void)refreshInCFRunLoopDefaultModeWithArrayAllData:(NSArray *)arrayAllData
{
    CGFloat height = [LJFScrollCarouselView heightWithArrayAllData:arrayAllData pageContainCount:_pageContainCount cellClassNameStr:_cellClassNameStr];
    
    // 数组深拷贝，数组内的对象地址是一样的。copy出的数组和原数组内存不一样。
    _arrAllData = [arrayAllData mutableCopy];
    
    [self layoutUIWithParentsFrmae:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height)];
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

- (instancetype)initWithOrigin:(CGPoint)Origin
                         width:(CGFloat)width
                  arrayAllData:(NSArray *)arrayAllData
              pageContainCount:(NSUInteger)pageContainCount
              cellClassNameStr:(NSString *)cellClassNameStr
{
    CGFloat height = [LJFScrollCarouselView heightWithArrayAllData:arrayAllData pageContainCount:pageContainCount cellClassNameStr:cellClassNameStr];
    
    // 根据传入cell类型反射创建cell 得知cell高度
    Class cellClass = NSClassFromString(cellClassNameStr);
    
    _cellHeight = [cellClass cellClassHeight];
    
    return [self initWithFrame:CGRectMake(Origin.x, Origin.y, width, height) arrayAllData:arrayAllData pageContainCount:pageContainCount cellClassNameStr:cellClassNameStr];
}

- (instancetype)initWithFrame:(CGRect)frame
                 arrayAllData:(NSArray *)arrayAllData
             pageContainCount:(NSUInteger)pageContainCount
             cellClassNameStr:(NSString *)cellClassNameStr
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
        
        // 数组深拷贝，数组内的对象地址是一样的。copy出的数组和原数组内存不一样。
        _arrAllData = [arrayAllData mutableCopy];
        _pageContainCount = pageContainCount;
        _cellClassNameStr = cellClassNameStr;
        // 加载数据
        [self layoutUIWithParentsFrmae:frame];
    }
    
    return self;
}

- (void)layoutUIWithParentsFrmae:(CGRect)frame
{
    // 动态规划页数
    [self dynamicCounter];
    
    // 根据动态规划结果创建子视图视图
    [self dynamicCreationContentViewWithParentsFrmae:frame];
}


// 动态规划页数
- (void)dynamicCounter
{
    // 初始化动态规划数组
    _arrSectionsOfAllData = [NSMutableArray array];
    NSInteger arrayAllDateCount = _arrAllData.count;
    
    // 动态规划：所有数据，每needPageCount个一组放进一个数组中，不足needPageCount个的也算一组，每一组是一页
    NSMutableArray *arraySection = nil;
    for (NSInteger i = 0; i < arrayAllDateCount; i++)
    {
        if (i % _pageContainCount == 0)
        {
            arraySection = [NSMutableArray array];
            [_arrSectionsOfAllData addObject:arraySection];
        }
        
        [arraySection addObject:_arrAllData[i]];
    }
    
    // 得到页数
    _displayTotalCount = _arrSectionsOfAllData.count;
}

- (void)dynamicCreationContentViewWithParentsFrmae:(CGRect)frame
{
    if (_displayTotalCount == 1)
    {
        // 初始化单页页的数据容器
        [self initArrRowsOfSimple];
        // 添加单页控件
        [self addOnlyTabelViewWithParentsFrmae:frame];
        // 设置单页默认信息
        [self setOnlyDefaultInfo];
        // 清空之前的数据
        [self restoreArrRowsOfComplex];
    }
    else if (_displayTotalCount >1)
    {
        // 初始化每页的数据容器
        [self initArrRowsOfComplex];
        // 添加滚动视图
        [self addScrollViewWithParentsFrmae:frame];
        // 添加分页控件
        [self addPageControlWithParentsFrmae:frame];
        // 设置默认信息
        [self setDefaultInfo];
        // 清空之前的数据
        [self restoreArrRowsOfSimple];
    }
}

// 清空数据
- (void)restoreArrRowsOfComplex
{
    if (_arrRowsOfViewLeft != nil)
    {
        [_arrRowsOfViewLeft removeAllObjects];
    }
    
    if (_arrRowsOfViewCenter != nil)
    {
        [_arrRowsOfViewCenter removeAllObjects];
    }
    
    if (_arrRowsOfViewRight != nil)
    {
        [_arrRowsOfViewRight removeAllObjects];
    }
    
    if (_scrV)
    {
        [_scrV setHidden:YES];
    }
    
    if (_pageC)
    {
        [_pageC setHidden:YES];
    }
}
// 清空数据
- (void)restoreArrRowsOfSimple
{
    if (_arrRowsOfViewOnly != nil)
    {
        [_arrRowsOfViewOnly removeAllObjects];
    }
    
    if (_viewOnly)
    {
        [_viewOnly setHidden:YES];
    }
}

// 初始化单页的数据容器
- (void)initArrRowsOfSimple
{
    if (_arrRowsOfViewOnly)
    {
        [_arrRowsOfViewOnly removeAllObjects];
    }
    else
    {
        _arrRowsOfViewOnly = [NSMutableArray array];
    }
}

// 添加单页控件
- (void)addOnlyTabelViewWithParentsFrmae:(CGRect)frame
{
    if (_viewOnly == nil)
    {
        _viewOnly = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _viewOnly.contentMode = UIViewContentModeScaleAspectFit;
        _viewOnly.rowHeight = _cellHeight;
        _viewOnly.delegate = self;
        _viewOnly.dataSource = self;
        _viewOnly.scrollEnabled = NO;
        _viewOnly.tableFooterView = [[UIView alloc] init];
//        [_viewOnly setSeparatorColor:[UIColor colorWithHex:0xf0f2f4 alpha:1.0]];
        [self addSubview:_viewOnly];
    }
    else
    {
        _viewOnly.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [_viewOnly setHidden:NO];
    }
}

- (void)setOnlyDefaultInfo
{
    _arrRowsOfViewOnly = _arrSectionsOfAllData[0];
    [_viewOnly reloadData];
}

// 初始化每页的数据
- (void)initArrRowsOfComplex
{
    if (_arrRowsOfViewLeft)
    {
        [_arrRowsOfViewLeft removeAllObjects];
    }
    else
    {
        _arrRowsOfViewLeft = [NSMutableArray array];
    }
    
    if (_arrRowsOfViewCenter)
    {
        [_arrRowsOfViewCenter removeAllObjects];
    }
    else
    {
        _arrRowsOfViewCenter = [NSMutableArray array];
    }
    
    if (_arrRowsOfViewRight)
    {
        [_arrRowsOfViewRight removeAllObjects];
    }
    else
    {
        _arrRowsOfViewRight = [NSMutableArray array];
    }
}

// 添加滚动视图
- (void)addScrollViewWithParentsFrmae:(CGRect)frame
{
    
    if (_scrV == nil)
    {
        _scrV = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - kPageControlHeight)];
        _scrV.contentSize = CGSizeMake(_scrV.bounds.size.width * kDisplayViewCount, _scrV.bounds.size.height);
        _scrV.contentOffset = CGPointMake(frame.size.width, 0.0);
        _scrV.pagingEnabled = YES;
        _scrV.showsHorizontalScrollIndicator = NO;
        _scrV.delegate = self;
        _scrV.bounces = NO;
        [self addSubview:_scrV];
    }
    else
    {
        [_scrV setHidden:NO];
    }
    
    [self addDisplayViewsToScrollViewWithParentsView:_scrV];
    
}

// 添加三个展示视图到滚动视图内
- (void)addDisplayViewsToScrollViewWithParentsView:(UIView *)parentsView
{
    CGRect frame = parentsView.bounds;
    
    if (_viewLeft == nil)
    {
        //图片视图；左边
        _viewLeft = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _viewLeft.contentMode = UIViewContentModeScaleAspectFit;
        _viewLeft.delegate = self;
        _viewLeft.dataSource = self;
        _viewLeft.scrollEnabled = NO;
        _viewLeft.tableFooterView = [[UIView alloc] init];
        _viewLeft.rowHeight = _cellHeight;
//        [_viewLeft setSeparatorColor:[UIColor colorWithHex:0xf0f2f4 alpha:1.0]];
        [parentsView addSubview:_viewLeft];
    }
    else
    {
        _viewLeft.hidden = NO;
    }
    
    if (_viewCenter == nil)
    {
        //图片视图；中间
        _viewCenter = [[UITableView alloc] initWithFrame:CGRectMake(frame.size.width, 0, frame.size.width, frame.size.height)];
        _viewCenter.contentMode = UIViewContentModeScaleAspectFit;
        _viewCenter.delegate = self;
        _viewCenter.dataSource = self;
        _viewCenter.scrollEnabled = NO;
        _viewCenter.tableFooterView = [[UIView alloc] init];
        _viewCenter.rowHeight = _cellHeight;
//        [_viewCenter setSeparatorColor:[UIColor colorWithHex:0xf0f2f4 alpha:1.0]];
        [parentsView addSubview:_viewCenter];
    }
    else
    {
        _viewCenter.hidden = NO;
    }
    
    if (_viewRight == nil)
    {
        //图片视图；右边
        _viewRight = [[UITableView alloc] initWithFrame:CGRectMake(frame.size.width * 2.0, 0, frame.size.width, frame.size.height)];
        _viewRight.contentMode = UIViewContentModeScaleAspectFit;
        _viewRight.delegate = self;
        _viewRight.dataSource = self;
        _viewRight.scrollEnabled = NO;
        _viewRight.tableFooterView = [[UIView alloc] init];
        _viewRight.rowHeight = _cellHeight;
//        [_viewRight setSeparatorColor:[UIColor colorWithHex:0xf0f2f4 alpha:1.0]];
        [parentsView addSubview:_viewRight];
    }
    else
    {
        _viewRight.hidden = NO;
    }
    
}

// 添加分页控件
- (void)addPageControlWithParentsFrmae:(CGRect)frame
{
    if (_pageC == nil)
    {
        _pageC = [UIPageControl new];
        CGSize size = [_pageC sizeForNumberOfPages:_displayTotalCount]; //根据页数返回 UIPageControl 合适的大小
        size.height = kPageControlHeight;
        _pageC.frame = CGRectMake(0, frame.size.height - size.height, size.width, size.height);
        _pageC.center = CGPointMake(frame.size.width / 2.0, _pageC.center.y);
        _pageC.numberOfPages = _displayTotalCount;
//        _pageC.pageIndicatorTintColor = [UIColor colorWithHex:0xe7e7e7 alpha:1.0];
//        _pageC.currentPageIndicatorTintColor = [UIColor qunarBlueColor];
        _pageC.userInteractionEnabled = NO; //设置是否允许用户交互；默认值为 YES，当为 YES 时，针对点击控件区域左（当前页索引减一，最小为0）右（当前页索引加一，最大为总数减一），可以编写 UIControlEventValueChanged 的事件处理方法
        [self addSubview:_pageC];
    }
    else
    {
        CGSize size = [_pageC sizeForNumberOfPages:_displayTotalCount]; //根据页数返回 UIPageControl 合适的大小
        size.height = kPageControlHeight;
        _pageC.frame = CGRectMake(0, frame.size.height - size.height, size.width, size.height);
        _pageC.center = CGPointMake(frame.size.width / 2.0, _pageC.center.y);
        _pageC.numberOfPages = _displayTotalCount;
        [_pageC setHidden:NO];
    }
}

// 设置默认信息
- (void)setDefaultInfo
{
    _currentDisplayIndex = 0;
    [self setInfoByCurrentDisplayIndex:_currentDisplayIndex];
}

// 装载数据
- (void)reloadDisplayData
{
    CGPoint contentOffset = [_scrV contentOffset];
    
    if (contentOffset.x > _scrV.frame.size.width)
    {
        //向左滑动
        _currentDisplayIndex = (_currentDisplayIndex + 1) % _displayTotalCount;
    }
    else if (contentOffset.x < _scrV.frame.size.width)
    {
        //向右滑动
        _currentDisplayIndex = (_currentDisplayIndex - 1 + _displayTotalCount) % _displayTotalCount;
    }
    
    [self setInfoByCurrentDisplayIndex:_currentDisplayIndex];
}

// 根据当前展示视图索引设置信息
- (void)setInfoByCurrentDisplayIndex:(NSUInteger)currentDisplayIndex
{
    // 取大数组中的第几个小数组
    
    //设置left视图数据
    NSInteger leftImageIndex = (_currentDisplayIndex - 1 + _displayTotalCount) % _displayTotalCount;
    _arrRowsOfViewLeft = _arrSectionsOfAllData[leftImageIndex];
    [_viewLeft reloadData];
    
    //设置center视图数据
    _arrRowsOfViewCenter = _arrSectionsOfAllData[currentDisplayIndex];
    [_viewCenter reloadData];
    
    //设置right视图数据
    NSInteger rightImageIndex = (_currentDisplayIndex + 1) % _displayTotalCount;
    _arrRowsOfViewRight = _arrSectionsOfAllData[rightImageIndex];
    [_viewRight reloadData];
    
    //设置page
    _pageC.currentPage = currentDisplayIndex;
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self reloadDisplayData];
    _scrV.contentOffset = CGPointMake(self.frame.size.width, 0.0);
    _pageC.currentPage = _currentDisplayIndex;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    NSInteger numberOfRows = 0;
    
    if (tableView == _viewOnly)
    {
        numberOfRows = _arrRowsOfViewOnly.count;
    }
    else if (tableView == _viewLeft)
    {
        numberOfRows = _arrRowsOfViewLeft.count;
    }
    else if (tableView == _viewCenter)
    {
        numberOfRows = _arrRowsOfViewCenter.count;
    }
    else if (tableView == _viewRight)
    {
        numberOfRows = _arrRowsOfViewRight.count;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    
    NSString *reusedIdentifier = @"LJFScrollCarouselViewCell";
    
    __kindof UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:reusedIdentifier];
    
    
    // 根据传入cell类型反射创建cell 定义基类
    Class cellClass = NSClassFromString(_cellClassNameStr);
    
    if (cell == nil)
    {
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reusedIdentifier];
    }
    
    // 重用布局
    if (tableView == _viewOnly)
    {
        [cell configerCellWithData:_arrRowsOfViewOnly[row]];
    }
    else if (tableView == _viewLeft)
    {
        [cell configerCellWithData:_arrRowsOfViewLeft[row]];
    }
    else if (tableView == _viewCenter)
    {
        [cell configerCellWithData:_arrRowsOfViewCenter[row]];
    }
    else if (tableView == _viewRight)
    {
        [cell configerCellWithData:_arrRowsOfViewRight[row]];
    }
    
    
    return cell;
}

#pragma mark - UITableViewDelegate

// 点击cell回调
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    // 提取相应数据返回
    NSUInteger row = [indexPath row];
    
    if (tableView == _viewOnly)
    {
        if ([_delegate respondsToSelector:@selector(callBackInArrayAllDataOfObject:)])
        {
            [_delegate callBackInArrayAllDataOfObject:_arrRowsOfViewOnly[row]];
        }
    }
    else if (tableView == _viewLeft)
    {
        if ([_delegate respondsToSelector:@selector(callBackInArrayAllDataOfObject:)])
        {
            [_delegate callBackInArrayAllDataOfObject:_arrRowsOfViewLeft[row]];
        }
    }
    else if (tableView == _viewCenter)
    {
        if ([_delegate respondsToSelector:@selector(callBackInArrayAllDataOfObject:)])
        {
            [_delegate callBackInArrayAllDataOfObject:_arrRowsOfViewCenter[row]];
        }
    }
    else if (tableView == _viewRight)
    {
        if ([_delegate respondsToSelector:@selector(callBackInArrayAllDataOfObject:)])
        {
            [_delegate callBackInArrayAllDataOfObject:_arrRowsOfViewRight[row]];
        }
    }
}


@end
