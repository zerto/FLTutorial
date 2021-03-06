//
//  FLTutorialViewController.m
//  Pods
//
//  Created by Franck LETELLIER on 06/03/2016.
//
//

#import "FLTutorialViewController.h"
#import "FLTutorialPageData.h"
#import "FLTutorialTextView.h"

@interface FLTutorialViewController ()<UIScrollViewDelegate>

#pragma mark - Outlets
@property (nonatomic, weak) IBOutlet UIPageControl* pageControl;
@property (nonatomic, weak) IBOutlet UIScrollView* imageScrollView;
@property (nonatomic, weak) IBOutlet UIScrollView* textScrollView;
@property (nonatomic, weak) IBOutlet UIButton* leftButton;
@property (nonatomic, weak) IBOutlet UIButton* rightButton;
@property (nonatomic, weak) IBOutlet UIButton* exitButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* scrollViewWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* scrollMaxHeight;

@property (nonatomic, strong) UIImageView* imageVAbove;
@property (nonatomic, strong) UIImageView* imageVUnder;

#pragma mark - Private Properties
@property (nonatomic, strong) FLTutorialData* data;
@property (nonatomic) NSInteger lastIndex;

@end

@implementation FLTutorialViewController

+(instancetype) tutorialViewController
{
    NSString* nibName = NSStringFromClass([self class]);
    FLTutorialViewController* vc = [[self alloc] initWithNibName:nibName bundle:[NSBundle bundleForClass:[self class]]];
    return vc;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    //Setup hidden button
    self.leftButton.alpha = 0;
    self.exitButton.hidden = YES;
    
    FLTutorialPageData* imageUnderData = self.data.pages[0];
    self.scrollViewWidth.constant = imageUnderData.pageImage.size.width;
    self.scrollMaxHeight.constant = imageUnderData.pageImage.size.height;
    self.imageVUnder = [[UIImageView alloc] initWithImage:imageUnderData.pageImage];
    self.imageScrollView.contentSize =  self.imageVUnder.bounds.size;
    [self.imageScrollView addSubview:self.imageVUnder];
    
    self.imageVAbove = [[UIImageView alloc] initWithImage:self.data.startingImage];
    [self.imageScrollView addSubview:self.imageVAbove];
    
    
    self.pageControl.numberOfPages = self.data.pages.count;
    
    
    self.textScrollView.delegate = self;
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGSize contentSize = self.textScrollView.bounds.size;
    contentSize.width *= self.data.pages.count;
    self.textScrollView.contentSize = contentSize;
    
    //Add text tiles for help count
    for (int i = 0; i < self.data.pages.count; ++i)
    {
        FLTutorialTextView* view =[FLTutorialTextView tutorialTextView];
        [view setupWithHelpPage:self.data.pages[i]];
        view.frame = self.textScrollView.bounds;
        CGRect frame = view.frame;
        frame.origin.x = view.bounds.size.width * i;
        view.frame = frame;
        
        [self.textScrollView addSubview:view];
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [super viewWillDisappear:animated];
}

#pragma mark - Private methods
-(NSInteger) maxYValue
{
    return [@(self.imageScrollView.contentSize.height - self.imageScrollView.bounds.size.height) integerValue];
}

#pragma mark - Actions
-(IBAction)closeAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(tutorialViewControllerDidClose:)])
        [self.delegate tutorialViewControllerDidClose:self];
}

-(IBAction)nextAction:(id)sender
{
    CGFloat currentX = [@(self.textScrollView.contentOffset.x / self.textScrollView.frame.size.width) floatValue];
    CGFloat nextOffset = roundf((float)currentX+1.0f) * self.view.frame.size.width;
    [self.textScrollView setContentOffset:CGPointMake(nextOffset, 0) animated:YES];
}

-(IBAction)previousAction:(id)sender
{
    CGFloat currentX = [@(self.textScrollView.contentOffset.x / self.textScrollView.frame.size.width) floatValue];
    CGFloat previousOffet = roundf((float)currentX-1.0f) * self.view.frame.size.width;
    [self.textScrollView setContentOffset:CGPointMake(previousOffet, 0) animated:YES];
}

#pragma mark - UIScrollViewDelegate methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat currentX = [@(scrollView.contentOffset.x / scrollView.frame.size.width) floatValue];
    self.pageControl.currentPage = [@(round(currentX)) intValue];
    NSInteger previousPage = [@(floor(currentX)) intValue];
    NSInteger nextPage = [@(ceil(currentX)) intValue];
    
    CGFloat currentNormalized = currentX - previousPage;
    
    if (previousPage >= 0 && nextPage < self.pageControl.numberOfPages)
    {
        FLTutorialPageData* previousPageData = self.data.pages[previousPage];
        FLTutorialPageData* nextPageData = self.data.pages[nextPage];
        
        //Check if the scroll position is not too far off
        NSInteger maxYValue = self.maxYValue;
        NSInteger nextYOffset = nextPageData.yOffset > maxYValue ? maxYValue : nextPageData.yOffset;
        NSInteger previousYOffset = previousPageData.yOffset > maxYValue ? maxYValue : previousPageData.yOffset;
        
        CGFloat finalYPosition = @(previousYOffset + (nextYOffset - previousYOffset) * currentNormalized).floatValue;
        self.imageScrollView.contentOffset = CGPointMake(0, finalYPosition);
        
        self.imageVUnder.image = previousPageData.pageImage;
        self.imageVAbove.image = nextPageData.pageImage;
        self.imageVAbove.alpha = currentNormalized;
        
    }
    
    //Handle left button
    if (previousPage == 0)
    {
        self.leftButton.alpha = currentNormalized;
    }
    else if (previousPage > 0)
    {
        self.leftButton.alpha = 1;
    }
    else //before the slideshow
    {
        self.leftButton.alpha = 0;
    }
    
    //Handle Right button
    if (previousPage == self.pageControl.numberOfPages - 2)
    {
        self.rightButton.alpha = 1.0f - currentNormalized;
        self.exitButton.alpha = currentNormalized;
        self.exitButton.hidden = NO;
    }
    else if (previousPage < self.pageControl.numberOfPages - 2)
    {
        self.rightButton.alpha = 1.0f;
        self.exitButton.hidden = YES;
    }
    else // after the slideshow
    {
        self.exitButton.alpha = 1;
        self.rightButton.alpha = 0;
    }
    
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self checkIfChangedIndex:scrollView];

}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self checkIfChangedIndex:scrollView];
}

-(void)checkIfChangedIndex:(UIScrollView *)scrollView
{
    
    CGFloat currentX = [@(scrollView.contentOffset.x / scrollView.frame.size.width) floatValue];
    NSInteger currentPage = [@(round(currentX)) intValue];
    
    if (self.lastIndex != currentPage)
    {
        if ([self.delegate respondsToSelector:@selector(tutorialViewController:didArriveAtPage:)])
        {
            [self.delegate tutorialViewController:self didArriveAtPage:currentPage];
        }
        
        self.lastIndex = currentPage;
    }
}

@end
