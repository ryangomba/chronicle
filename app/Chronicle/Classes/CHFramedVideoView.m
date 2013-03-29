#import "CHFramedVideoView.h"

// TODO move
#import <Photos/Photos.h>

#define kPlayIndicatorSize 20.0
#define kPlayIndicatorInset 22.0

@interface CHFramedVideoView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, assign) BOOL isRegisteredForPlayerObservation;

@property (nonatomic, strong) CAShapeLayer *playIndicator;

@end


@implementation CHFramedVideoView

- (void)dealloc {
    if (_isRegisteredForPlayerObservation) {
        [self.player removeObserver:self forKeyPath:@"rate"];
    }
    [self setPlayerItem:nil];
}

- (id)initWithPhoto:(id<CHPhoto>)photo {
    if (self = [super initWithPhoto:photo]) {
        [self.contentView.layer addSublayer:self.playerLayer];
        [self.layer addSublayer:self.playIndicator];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [tap addTarget:self action:@selector(onTap)];
        [self.contentView addGestureRecognizer:tap];
    }
    return self;
}

- (CAShapeLayer *)playIndicator {
    if (!_playIndicator) {
        _playIndicator = [[CAShapeLayer alloc] init];
        _playIndicator.frame = CGRectMake(0.0, 0.0, kPlayIndicatorSize, kPlayIndicatorSize);
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointZero];
        [path addLineToPoint:CGPointMake(kPlayIndicatorSize, kPlayIndicatorSize / 2.0)];
        [path addLineToPoint:CGPointMake(0.0, kPlayIndicatorSize)];
        [path closePath];
        _playIndicator.path = path.CGPath;
        
        _playIndicator.fillColor = [UIColor whiteColor].CGColor;
        
        _playIndicator.shadowPath = _playIndicator.path;
        _playIndicator.shadowColor = [UIColor blackColor].CGColor;
        _playIndicator.shadowOffset = CGSizeZero;
        _playIndicator.shadowOpacity = 0.5;
        _playIndicator.shadowRadius = 1.0;
    }
    return _playIndicator;
}

- (AVPlayer *)player {
    static AVPlayer *player;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[AVPlayer alloc] init];
    });
    return player;
}

- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _playerLayer.hidden = YES;
    }
    return _playerLayer;
}

- (void)setPhoto:(id<CHPhoto>)photo desiredImageSize:(CHPhotoImageSize)imageSize {
    [super setPhoto:photo desiredImageSize:imageSize];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHFetchResult *results =
        [PHAsset fetchAssetsWithLocalIdentifiers:@[photo.localIdentifier] options:nil];
        PHAsset *videoAsset = [results firstObject];
        [[PHImageManager defaultManager] requestAVAssetForVideo:videoAsset
                                                        options:nil
                                                  resultHandler:
         ^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
            });
        }];
    });
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    [_playerItem removeObserver:self forKeyPath:@"status"];
    
    _playerItem = playerItem;
    
    [_playerItem addObserver:self
                  forKeyPath:@"status"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (object == self.player) {
            BOOL isPlaying = self.player.currentItem == self.playerItem && self.player.rate > 0.0;
            self.playIndicator.hidden = isPlaying;
            self.playerLayer.hidden = !isPlaying;
            
        } else if (object == self.playerItem) {
            //
        }
    });
}

- (void)onTap {
    if (self.player.currentItem == self.playerItem && self.player.rate > 0.0) {
        [self pauseVideo];
    } else {
        [self playVideo];
    }
}

- (void)pauseVideo {
    self.playerLayer.hidden = YES;
    [self.player pause];
    if (_isRegisteredForPlayerObservation) {
        [self.player removeObserver:self forKeyPath:@"rate"];
        _isRegisteredForPlayerObservation = NO;
    }
}

- (void)playVideo {
    if (!_isRegisteredForPlayerObservation) {
        _isRegisteredForPlayerObservation = YES;
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    }
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat playIndicatorX = kPlayIndicatorInset;
    CGFloat playIndicatorY = self.bounds.size.height - kPlayIndicatorInset;
    self.playIndicator.position = CGPointMake(playIndicatorX, playIndicatorY);
    
    self.playerLayer.frame = self.contentView.bounds;
}

@end
