# 循环滚动TabelView视图

# 需求点 
* 循环滚动TabelView视图
* 限制：要求cell高度一致

# 效果展示
![](http://7xraw1.com1.z0.glb.clouddn.com/ScrollCarouselView.gif)

# 技术点&思想
## 技术点
1. 深拷贝，不污染数据源；
2. Runtime 反射创建自定义对象；
3. RunLoop 合适的 source 切换数据，使视图滑动时不卡顿；

## 思想
1. 动态规划数组；
2. 协议解耦合，不关心具体业务；
3. 接口设计遵循开放和封闭原则；

# 优点
1. 整体复用率高；
2. 耦合度低；
3. 接口设计合理；