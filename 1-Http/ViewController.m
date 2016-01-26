//
//  ViewController.m
//  1-Http
//
//  Created by jameswatt on 16/1/18.
//  Copyright © 2016年 xuzhixiang. All rights reserved.
//

//图片下载的原理
//不可能每张图片都下载，不可能每张图片每次都下载。
//一般情况下，图片下载好，会保存到沙盒里面，只需要关注图片的名称，（url）名称.png,这样的方式来保存图片.下次去下载图片的时候，先去检测沙盒里面有没有这张图片，如果有直接拿来用，如果没有，就去下载.



#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic ,strong) NSMutableArray *dataSource;
@property (nonatomic ,strong) UITableView *tableView;

@property (nonatomic ,strong) UIRefreshControl *refresh;

@property (nonatomic ,strong) NSMutableDictionary *imageDatas;

@end

@implementation ViewController


// main 程序的主线程，所有的UI操作都在主线程。

//同步的请求 如果请求持续的时间比较长（耗时操作），会卡死界面.(在主线程里面执行)
//异步的请求 做耗时操作时，不会卡死界面。（因为没有在主线程里面运行）


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //创建数组
    _dataSource = [NSMutableArray new];
    //创建一个字典来存放 下载好的图片
    _imageDatas = [NSMutableDictionary new];
    
    //先去请求数据
    [self loadDataSource];
   
    //创建tableview
    [self createTableView];
}

- (void)loadDataSource {
    //发起一个同步请求
    
    //    http://10.0.8.8/sns/my/user_list.php
    
    // 用 NSURl  来表示一个URL
    NSURL *url = [NSURL URLWithString:@"http://10.0.8.8/sns/my/user_list.php?page=1&number=10"];
    
    //创建一个 http请求
    //第一个参数是NSURL
    //第二个参数是 缓存策略
    //    NSURLRequestUseProtocolCachePolicy = 0,//如果数据有更新，直接返回最新的数据，如果没有的话，就不用返回了(本地缓存的)
    //
    //    NSURLRequestReloadIgnoringLocalCacheData = 1,
    //Ignore 忽略本地数据，每次都返回最新的数据（不管你有没有更新）
    
    //    NSURLRequestReloadIgnoringLocalAndRemoteCacheData = 4, // Unimplemented
    //    NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData,
    //
    //    NSURLRequestReturnCacheDataElseLoad = 2,
    //    NSURLRequestReturnCacheDataDontLoad = 3,
    //
    //    NSURLRequestReloadRevalidatingCacheData = 5, //
    
    
    //第三个参数是 超时时间  移动网络下，超时时间 设置为60s
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    //发起请求
    
    //响应
    NSURLResponse *response = nil;
    //存放错误信息的
    NSError *error = nil;
    
    //发起请求   NSURLConnection   Syn 同步  Async 异步
//    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    //异步请求,NSURLConnection 在发起异步请求的时候，会重新建立一个线程去下载数据，所以不会卡UI
    //1.urlRequest
    //2.下载的代码块放在哪一个线程，UI线程（主线程） [NSOperationQueue mainQueue]// 获取主线程队列
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSLog(@"下载完成，得到二进制数据");
        
        
        //解析 数据
        NSDictionary * jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSLog(@"json解析数据 %@",jsonObj);
        //如果我们跟服务器人员交流的话，要要求他们返回什么样类型的数据
        NSNumber *count = jsonObj[@"count"];
        NSString *totalcount = jsonObj[@"totalcount"];
        NSArray *users = jsonObj[@"users"];
        
        NSLog(@"%ld",users.count);
        
        //加载数据源
        for (NSDictionary *dictItem in users) {
            UserModel *user = [UserModel new];
            user.username = dictItem[@"username"];
            user.headimage = dictItem [@"headimage"];
            user.uid = dictItem [@"uid"];
            [self.dataSource addObject:user];
        }

        //结束刷新
        [self.refresh endRefreshing];
        //刷新界面
        [self.tableView reloadData];
        
    }];
    
//    if (error != nil) {
//        NSLog(@"请求失败，错误信息 %@",error);
//    }else {
//        NSLog(@"请求成功 ,响应信息 %@",response);
//    }
    
    //如果是xcode7 会提示请求不安全  App Transport Security,苹果建议都用安全的https 请求。
    //http，安全的是https
    
    //解决方法
    //    1.    在Info.plist中添加NSAppTransportSecurity类型Dictionary。
    //    2.    在NSAppTransportSecurity下添加NSAllowsArbitraryLoads类型Boolean,值设为YES
    
   
}

//
- (void)createTableView {
    UITableView *tableVeiw = [[UITableView alloc]initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableVeiw.delegate = self;
    tableVeiw.dataSource = self;
    [self.view addSubview:tableVeiw];
    
    self.tableView = tableVeiw;
    
    //增加下拉刷新
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc]init];
    [refresh addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refresh];
    self.refresh = refresh;
    
    //加载更多
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, 200, 60);
    [btn setTitle:@"点击加载更多" forState:UIControlStateNormal];
    self.tableView.tableFooterView = btn;
}
- (void)refresh:(UIRefreshControl*)sender {
    //判断刷新控件的状态
    if (sender.isRefreshing) {
        //清空数据
        [self.dataSource removeAllObjects];
        //重新请求
        [self loadDataSource];

    }
    NSLog(@"下拉刷新");

    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"正在加载 %ld 行的数据  ",indexPath.row);
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    if (self.dataSource.count < indexPath.row) {
        //数组肯定会越界
        return cell;
    }
    //取出数据 model
    UserModel *user = self.dataSource[indexPath.row];
    
    //拼出图片的地址
    NSString *headImagUrlStr = [NSString stringWithFormat:@"http://10.0.8.8/sns%@",user.headimage];
    NSURL *url = [NSURL URLWithString:headImagUrlStr];
    NSURLRequest *reuqest = [NSURLRequest requestWithURL:url];
    //同步的请求
//    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:headImagUrlStr]];
    //如果字典里面有这个key ，说明图片已经被下载了
//    if ([[_imageDatas allKeys] containsObject:user.headimage]) {
//        //找到图片
//        UIImage *image = [_imageDatas objectForKey:user.headimage];
//        cell.imageView.image = image;
//        
//    }else {
//        //这张图片还没有被下载
//        [NSURLConnection sendAsynchronousRequest:reuqest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
//            
//            UIImage *image =[UIImage imageWithData:data];
//            NSLog(@"下载图片完成%ld",data.length/1024);
//            //下载完成得到图片以后存入字典里面
//            if (user.headimage != nil) {
//                [_imageDatas setObject:image forKey:user.headimage];
//
//            }
//            cell.imageView.image = image;
//            [self.tableView reloadData];
//            
//            
//        }];
//    }

    

    

    
    cell.textLabel.text = user.username;
    

    
    
    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
