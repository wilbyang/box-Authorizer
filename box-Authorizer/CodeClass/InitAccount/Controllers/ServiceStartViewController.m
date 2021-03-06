//
//  ServiceStartViewController.m
//  box-Authorizer
//
//  Created by Yu Huang on 2018/3/14.
//  Copyright © 2018年 2se. All rights reserved.
//

#import "ServiceStartViewController.h"
#import "HomepageViewController.h"
#import "ServiceStartCollectionViewCell.h"
#import "ServiceStartModel.h"
#import "HomepageViewController.h"
#import "LeftMenuViewController.h"

#define ServiceStartTitle  @"启动服务"
#define ServiceStartLaunchUnstart  @"未启动"
#define ServiceStartLaunchState  @"启动中"
#define ServiceStartLaunchStateSecceed  @"启动成功"
#define ServiceStartPassword  @"请输入备份密码"
#define ServiceStartRepassword  @"请再次输入备份密码"
#define ServiceStartCommitStart  @"同意启动"
#define ServiceStartCommitStartUse  @"开始使用"
#define ServiceStartAwaitBtn  @"已等待时间"
#define ServiceStartUse  @"开始使用"
#define ServiceStateTitle  @"启动成功"
#define ServiceStateDetail  @"继续等待下一位私钥App持有者启动服务"
#define ServiceStartAleartOne  @"请输入私钥密码"
#define ServiceStartAleartTwo  @"密码不一致"

#define CellReuseIdentifier  @"ServiceStart"

@interface ServiceStartViewController ()<UITextFieldDelegate,UIScrollViewDelegate,UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
    NSTimer *timeTimer;
    NSTimer *dataTimer;
}
//布局对象
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionFlowlayout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *sourceArray;
@property(nonatomic, strong)UIScrollView *contentView;
@property(nonatomic, strong)UIImageView *topImageView;
/** 启动状态 */
@property (nonatomic,strong)LYButton *launchState;
@property (nonatomic,strong)TBButton *oneStaff;
@property (nonatomic,strong)TBButton *twoStaff;
@property (nonatomic,strong)TBButton *threeStaff;
/** 输入并确认私钥密码 */
@property (nonatomic,strong)UIView *importView;
@property (nonatomic,strong)UITextField *passwordTf;
@property (nonatomic,strong)UITextField *rePasswordTf;
@property (nonatomic,strong)UIButton *commitStartBtn;
/** 启动状态 */
@property (nonatomic,strong)UIView *startStateView;
@property (nonatomic,strong)UILabel *awaitTimeLab;
@property (nonatomic,strong)UILabel *stateTitleLab;
@property (nonatomic,strong)UILabel *statedetailLab;
@property (nonatomic,strong)UIButton *stateUseBtn;
/** 计时 */
@property (nonatomic,assign) NSInteger currentTime;
@property(nonatomic, strong)DDRSAWrapper *aWrapper;

@end

@implementation ServiceStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.view.backgroundColor = RGB(240, 240, 240);
    self.title = ServiceStartTitle;
    /** 设置导航栏背景图片 */
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"image_nav"] forBarMetrics:UIBarMetricsDefault];
    /** 设置导航栏标题文字颜色 */
    NSDictionary *dic = @{
                           NSForegroundColorAttributeName : [UIColor whiteColor]
                           };
    [self.navigationController.navigationBar setTitleTextAttributes:dic];
    _aWrapper = [[DDRSAWrapper alloc] init];
    [self createView];
    _sourceArray = [[NSMutableArray alloc] init];
    
    timeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timeTimerAction:) userInfo:nil repeats:YES];
    [self requestData];
}

#pragma mark ----- scrollview取消弹簧效果 -----
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //scrollView.bounces = (scrollView.contentOffset.y <= 0) ? NO : YES;
}

-(void)createView
{
    _contentView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, kTopHeight - 64, SCREEN_WIDTH, SCREEN_HEIGHT - kTopHeight)];
    _contentView.delegate = self;
    //滚动的时候消失键盘
    _contentView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _contentView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), SCREEN_HEIGHT - kTopHeight + 5);
    _contentView.showsVerticalScrollIndicator = NO;
    _contentView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_contentView];
    
    _topImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,  SCREEN_WIDTH, 240)];
    _topImageView.image = [UIImage imageNamed:@"ServiceStartTopImg"];
    [_contentView addSubview:_topImageView];
    _topImageView.userInteractionEnabled = YES;
    
    _launchState = [LYButton buttonWithType:UIButtonTypeCustom];
    [_launchState setTitle:ServiceStartLaunchUnstart forState:UIControlStateNormal];
    [_launchState setTitleColor:[UIColor colorWithHexString:@"#ffffff"] forState:UIControlStateNormal];
    _launchState.titleLabel.font = Font(14);
    [_launchState setImage:[UIImage imageNamed:@"icon_plan"] forState:UIControlStateNormal];
    [_topImageView addSubview:_launchState];
    [_launchState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(10);
        make.left.offset(16);
        make.height.offset(25);
    }];
    
    _collectionFlowlayout = [UICollectionViewFlowLayout new];
    _collectionFlowlayout.itemSize = CGSizeMake(120, 100);
    _collectionFlowlayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionFlowlayout.minimumLineSpacing = 0;
    // 分区内容边间距（上，左， 下， 右）；
    _collectionFlowlayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    
    _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 65, self.view.frame.size.width ,100) collectionViewLayout:_collectionFlowlayout];
     _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.scrollsToTop = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    [_collectionView registerClass:[ServiceStartCollectionViewCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
    [_topImageView addSubview:_collectionView];

    //输入密码
    _importView = [[UIView alloc] init];
    _importView.backgroundColor = [UIColor colorWithHexString:@"#ffffff"];
    [_contentView addSubview:_importView];
    _importView.layer.masksToBounds = YES;
    _importView.layer.cornerRadius = 3.0f;
    [_importView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topImageView.mas_bottom).offset(-45);
        make.left.offset(10);
        make.width.offset(SCREEN_WIDTH - 20);
        make.height.offset(236);
    }];
    
    _passwordTf = [[UITextField alloc] init];
    _passwordTf.delegate = self;
    NSString *passwordText = ServiceStartPassword;
    NSMutableAttributedString *backupHolder = [[NSMutableAttributedString alloc] initWithString:passwordText];
    [backupHolder addAttribute:NSForegroundColorAttributeName
                         value:[UIColor colorWithHexString:@"#cccccc"]
                         range:NSMakeRange(0, passwordText.length)];
    [backupHolder addAttribute:NSFontAttributeName
                         value:Font(14)
                         range:NSMakeRange(0, passwordText.length)];
    _passwordTf.attributedPlaceholder = backupHolder;
    _passwordTf.keyboardType = UIKeyboardTypeAlphabet;
    _passwordTf.clearButtonMode=UITextFieldViewModeWhileEditing;
    _passwordTf.secureTextEntry = YES;
    [_importView addSubview:_passwordTf];
    [_passwordTf mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(13);
        make.left.offset(25);
        make.right.offset(-25);
        make.height.offset(55);
    }];
    
    UIView *lineOne = [[UIView alloc] init];
    lineOne.backgroundColor = [UIColor colorWithHexString:@"#e8e8e8"];
    [_importView addSubview:lineOne];
    [lineOne mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordTf.mas_bottom).offset(0);
        make.left.offset(25);
        make.right.offset(-25);
        make.height.offset(1);
    }];
    
    _rePasswordTf = [[UITextField alloc] init];
    _rePasswordTf.delegate = self;
    NSString *rePasswordText = ServiceStartRepassword;
    NSMutableAttributedString *reBackupHolder = [[NSMutableAttributedString alloc] initWithString:rePasswordText];
    [reBackupHolder addAttribute:NSForegroundColorAttributeName
                         value:[UIColor colorWithHexString:@"#cccccc"]
                         range:NSMakeRange(0, rePasswordText.length)];
    [reBackupHolder addAttribute:NSFontAttributeName
                         value:Font(14)
                         range:NSMakeRange(0, rePasswordText.length)];
    _rePasswordTf.clearButtonMode=UITextFieldViewModeWhileEditing;
    _rePasswordTf.attributedPlaceholder = reBackupHolder;
    _rePasswordTf.keyboardType = UIKeyboardTypeAlphabet;
    _rePasswordTf.secureTextEntry = YES;
    [_importView addSubview:_rePasswordTf];
    [_rePasswordTf mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineOne.mas_bottom).offset(0);
        make.left.offset(25);
        make.right.offset(-25);
        make.height.offset(55);
    }];
    
    UIView *lineTwo = [[UIView alloc] init];
    lineTwo.backgroundColor = [UIColor colorWithHexString:@"#eaeaea"];
    [_importView addSubview:lineTwo];
    [lineTwo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_rePasswordTf.mas_bottom).offset(0);
        make.left.offset(25);
        make.right.offset(-25);
        make.height.offset(1);
    }];
    
    _commitStartBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_commitStartBtn setTitle:ServiceStartCommitStart forState:UIControlStateNormal];
    [_commitStartBtn setTitleColor:[UIColor colorWithHexString:@"#ffffff"] forState:UIControlStateNormal];
    _commitStartBtn.backgroundColor = [UIColor colorWithHexString:@"#4c7afd"];
    _commitStartBtn.layer.masksToBounds = YES;
    _commitStartBtn.layer.cornerRadius = 2.0f;
    _commitStartBtn.titleLabel.font = Font(17);
    [_commitStartBtn addTarget:self action:@selector(commitStartAction:) forControlEvents:UIControlEventTouchUpInside];
    [_importView addSubview:_commitStartBtn];
    [_commitStartBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineTwo.mas_bottom).offset(75.0/2.0);
        make.left.offset(15);
        make.right.offset(-15);
        make.height.offset(46);
    }];
    
    _importView.hidden = NO;
    [self createStartStateView];
    
}

-(void)createStartStateView
{
    _startStateView = [[UIView alloc] init];
    _startStateView.backgroundColor = [UIColor colorWithHexString:@"#ffffff"];
    [_contentView addSubview:_startStateView];
    _startStateView.layer.masksToBounds = YES;
    _startStateView.layer.cornerRadius = 3.0f;
    [_startStateView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topImageView.mas_bottom).offset(-45);
        make.left.offset(10);
        make.width.offset(SCREEN_WIDTH - 20);
        make.height.offset(340);
    }];
    
    UIImageView *circleImg = [[UIImageView alloc] init];
    circleImg.image = [UIImage imageNamed:@"circleStateImg"];
    [_startStateView addSubview:circleImg];
    [circleImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(41);
        make.centerX.equalTo(_startStateView);
        make.width.offset(342.0/2.0);
        make.height.offset(342.0/2.0);
    }];
    
    _awaitTimeLab = [[UILabel alloc] init];
    _awaitTimeLab.text = @"00:00";
    _awaitTimeLab.textAlignment = NSTextAlignmentCenter;
    _awaitTimeLab.font = FontBold(32);
    _awaitTimeLab.textColor = kDarkGrayColor;
    [_startStateView addSubview:_awaitTimeLab];
    [_awaitTimeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(circleImg.mas_bottom).offset(-342.0/4.0 - 10);
        make.centerX.equalTo(circleImg);
        make.height.offset(40);
    }];

    _stateTitleLab = [[UILabel alloc] init];
    _stateTitleLab.text = ServiceStateTitle;
    _stateTitleLab.textAlignment = NSTextAlignmentCenter;
    _stateTitleLab.font = FontBold(17);
    _stateTitleLab.textColor = [UIColor colorWithHexString:@"#444444"];
    _stateTitleLab.numberOfLines = 1;
    [_startStateView addSubview:_stateTitleLab];
    [_stateTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(circleImg.mas_bottom).offset(10);
        make.left.offset(18);
        make.right.offset(-18);
        make.height.offset(24);
    }];
    
    _statedetailLab = [[UILabel alloc] init];
    _statedetailLab.text = ServiceStateDetail;
    _statedetailLab.textAlignment = NSTextAlignmentCenter;
    _statedetailLab.font = Font(13);
    _statedetailLab.textColor = [UIColor colorWithHexString:@"#666666"];
    _statedetailLab.numberOfLines = 1;
    [_startStateView addSubview:_statedetailLab];
    [_statedetailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_stateTitleLab.mas_bottom).offset(8);
        make.left.offset(18);
        make.right.offset(-18);
        make.height.offset(20);
    }];
    
    _stateUseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_stateUseBtn setTitle:ServiceStartCommitStartUse forState:UIControlStateNormal];
    [_stateUseBtn setTitleColor:[UIColor colorWithHexString:@"#ffffff"] forState:UIControlStateNormal];
    _stateUseBtn.backgroundColor = [UIColor colorWithHexString:@"#4c7afd"];
    _stateUseBtn.titleLabel.font = Font(16);
    _stateUseBtn.layer.cornerRadius = 2.0f;
    _stateUseBtn.layer.masksToBounds = YES;
    [_stateUseBtn addTarget:self action:@selector(startUseAction:) forControlEvents:UIControlEventTouchUpInside];
    [_startStateView addSubview:_stateUseBtn];
    [_stateUseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_stateTitleLab.mas_bottom).offset(20);
        make.left.offset(15);
        make.right.offset(-15);
        make.height.offset(46);
    }];
    _stateUseBtn.hidden = YES;
    _startStateView.hidden = YES;
}

#pragma mark ----- commitStar -----
-(void)commitStartAction:(UIButton *)btn
{
    if ([_passwordTf.text isEqualToString:@""]) {
        [WSProgressHUD showErrorWithStatus:ServiceStartAleartOne];
        return;
    }
    if (![_rePasswordTf.text isEqualToString:_passwordTf.text]) {
        [WSProgressHUD showErrorWithStatus:ServiceStartAleartTwo];
        return;
    }
    NSString *aesStr = [FSAES128 AES128EncryptStrig:_passwordTf.text keyStr:[BoxDataManager sharedManager].randomValue];
    NSString *signSHA256 = [_aWrapper PKCSSignBytesSHA256withRSA:aesStr privateStr:[BoxDataManager sharedManager].privateKeyBase64];
    //BOOL veryOK = [_aWrapper PKCSVerifyBytesSHA256withRSA:aesStr signature:signSHA256 publicStr:[BoxDataManager sharedManager].publicKeyBase64];
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc]init];
    [paramsDic setObject:aesStr forKey:@"password"];
    [paramsDic setObject:signSHA256 forKey:@"sign"];
    [paramsDic setObject:[BoxDataManager sharedManager].app_account_id forKey:@"applyerid"];
    [paramsDic setObject:@"3" forKey:@"type"];
    [[NetworkManager shareInstance] requestWithMethod:POST withUrl:@"/agent/operate" params:paramsDic success:^(id responseObject) {
        NSDictionary *dict = responseObject;
        NSInteger RspNo = [dict[@"RspNo"] integerValue];
        if ([dict[@"RspNo"] isEqualToString:@"0"]) {
            _importView.hidden = YES;
            _startStateView.hidden = NO;
            _currentTime = -1;
            dataTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(updateTimeAction:) userInfo:nil repeats:YES];            
        }else{
            [ProgressHUD showStatus:RspNo];
        }
    } fail:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

-(void)requestData
{
    [[NetworkManager shareInstance] requestWithMethod:GET withUrl:@"/agent/status" params:nil success:^(id responseObject) {
        NSDictionary *dict = responseObject;
        if ([dict[@"RspNo"] isEqualToString:@"0"]) {
            [_sourceArray removeAllObjects];
            NSInteger ServerStatus = [dict[@"Status"][@"ServerStatus"] integerValue];
            NSInteger Status = [dict[@"Status"][@"Status"] integerValue];
            NSInteger Total = [dict[@"Status"][@"Total"] integerValue];
            NSArray *NodesAuthorizedArr = dict[@"Status"][@"NodesAuthorized"];
            //输入私钥密码状态
            if (ServerStatus == 3 && Status == 0) {
                if (_currentTime != 0) {
                    return ;
                }
                [_launchState setTitle:ServiceStartLaunchUnstart forState:UIControlStateNormal];
                _importView.hidden = NO;
                _startStateView.hidden = YES;
                for (int i = 0; i < Total; i++) {
                    NSDictionary *dic = @{@"ApplyerId":@"", @"ApplyerName":@"",@"Authorized":@(NO)};
                    ServiceStartModel *model = [[ServiceStartModel alloc] initWithDict:dic];
                    [_sourceArray addObject:model];
                    [_collectionView reloadData];
                }
            }
            //等待下一位输入：1-自己还未输入 2-自己已经输入
            else if (ServerStatus == 3 && Status == 1 && NodesAuthorizedArr.count < Total){
                for (NSDictionary *NodesAuthorizedDic in NodesAuthorizedArr) {
                    ServiceStartModel *model = [[ServiceStartModel alloc] initWithDict:NodesAuthorizedDic];
                    if ([model.ApplyerId isEqualToString:[BoxDataManager sharedManager].app_account_id]) {
                        if (_currentTime != 0) {
                        }else{
                            _currentTime = -1;
                        }
                    }
                }
                if (_currentTime == 0) {
                    
                    for (NSDictionary *NodesAuthorizedDic in NodesAuthorizedArr) {
                        ServiceStartModel *model = [[ServiceStartModel alloc] initWithDict:NodesAuthorizedDic];
                        [_sourceArray addObject:model];
                        [_collectionView reloadData];
                    }
                    //进入输入私钥密码状态
                    _importView.hidden = NO;
                    _startStateView.hidden = YES;
                    [_launchState setTitle:ServiceStartLaunchState forState:UIControlStateNormal];
                }else{
                    _importView.hidden = YES;
                    _startStateView.hidden = NO;
                    _stateUseBtn.hidden = YES;
                    _statedetailLab.hidden = NO;
                    _stateTitleLab.hidden = NO;
                    [_launchState setTitle:ServiceStartLaunchState forState:UIControlStateNormal];
                    
                    for (NSDictionary *NodesAuthorizedDic in NodesAuthorizedArr) {
                        ServiceStartModel *model = [[ServiceStartModel alloc] initWithDict:NodesAuthorizedDic];
                        [_sourceArray addObject:model];
                        [_collectionView reloadData];
                        
                    }
                }
            }
            //重新输入私钥密码状态
            else if(ServerStatus == 3 && Status == 1 && NodesAuthorizedArr.count == Total){
                [WSProgressHUD showErrorWithStatus:@"启动服务失败，请重新启动"];
                _currentTime = 0;
                _importView.hidden = NO;
                _startStateView.hidden = YES;
                [dataTimer invalidate];
                dataTimer = nil;
                [_launchState setTitle:ServiceStartLaunchUnstart forState:UIControlStateNormal];
                for (int i = 0; i < Total; i++) {
                    NSDictionary *dic = @{@"ApplyerId":@"", @"ApplyerName":@"",@"Authorized":@(NO)};
                    ServiceStartModel *model = [[ServiceStartModel alloc] initWithDict:dic];
                    [_sourceArray addObject:model];
                    [_collectionView reloadData];
                }
            }else if(ServerStatus == 4 && Status == 0 && NodesAuthorizedArr.count == Total){
                [_launchState setTitle:ServiceStartLaunchStateSecceed forState:UIControlStateNormal];
                [dataTimer invalidate];
                dataTimer = nil;
                [timeTimer invalidate];
                timeTimer = nil;
                _importView.hidden = YES;
                _startStateView.hidden = NO;
                _stateUseBtn.hidden = NO;
                _statedetailLab.hidden = YES;
                _stateTitleLab.hidden = NO;
                _stateTitleLab.text = @"所有私钥App持有者都已启动服务";
                for (NSDictionary *NodesAuthorizedDic in NodesAuthorizedArr) {
                    ServiceStartModel *model = [[ServiceStartModel alloc] initWithDict:NodesAuthorizedDic];
                    [_sourceArray addObject:model];
                    [_collectionView reloadData];
                }
            }
            else if(Status == 2){
                [WSProgressHUD showErrorWithStatus:@"服务异常"];
            }
        }
    } fail:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

#pragma mark ----- getAgentStatus -----
-(void)updateTimeAction:(NSTimer *)timer
{
    [self requestData];
}

-(void)timeTimerAction:(NSTimer *)timer
{
    if (_currentTime != 0) {
        if (_currentTime < 0) {
            _currentTime = 0;
        }
        _currentTime += 1;
        _awaitTimeLab.text = [TimeManeger minutesFormatString:(int)_currentTime];
    }
}

#pragma mark ----- starUse -----
-(void)startUseAction:(UIButton *)btn
{
    [[BoxDataManager sharedManager] saveDataWithCoding:@"launchState" codeValue:@"3"];
    HomepageViewController *homepageVC = [[HomepageViewController alloc] init];
    LeftMenuViewController *leftMenuVC = [[LeftMenuViewController alloc] init];
    //侧滑栏
    JASidePanelController *panelVC = [[JASidePanelController alloc] init];
    UINavigationController *homepageNC = [[UINavigationController alloc]initWithRootViewController:homepageVC];
    UINavigationController *leftMenuNC = [[UINavigationController alloc]initWithRootViewController:leftMenuVC];
    leftMenuNC.navigationBar.hidden = YES;
    panelVC.leftPanel = leftMenuNC;
    panelVC.centerPanel = homepageNC;
    panelVC.recognizesPanGesture = YES;
    panelVC.leftGapPercentage = .71;
    [self presentViewController:panelVC animated:YES completion:nil];
}

#pragma mark  ----- UICollectionViewDataSource -----
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _sourceArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ServiceStartCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    ServiceStartModel *model = _sourceArray[indexPath.row];
    cell.model = model;
    [cell setDataWithModel:model];
    return cell;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
