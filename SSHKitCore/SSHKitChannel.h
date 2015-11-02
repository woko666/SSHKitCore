#import <SSHKitCore/SSHKitCoreCommon.h>

@protocol SSHKitChannelDelegate;
@class SSHKitSession;

// -----------------------------------------------------------------------------
#pragma mark -
// -----------------------------------------------------------------------------

/**
 SSHKitChannel provides functionality to work with SSH shells and SCP.
 */
@interface SSHKitChannel : NSObject

- (instancetype)initSFTPChannelWithSession:(SSHKitSession *)session delegate:(id<SSHKitChannelDelegate>)aDelegate;

+ (instancetype)shellChannelFromSession:(SSHKitSession *)session withTerminalType:(NSString *)terminalType columns:(NSInteger)columns rows:(NSInteger)rows delegate:(id<SSHKitChannelDelegate>)aDelegate;

+ (instancetype)directChannelFromSession:(SSHKitSession *)session withHost:(NSString *)host port:(NSUInteger)port delegate:(id<SSHKitChannelDelegate>)aDelegate;

+ (void)requestRemoteForwardOnSession:(SSHKitSession *)session withListenHost:(NSString *)host listenPort:(uint16_t)port completionHandler:(SSHKitRequestRemoteForwardCompletionBlock)completionHandler;

/** A valid SSHKitSession instance */
@property (nonatomic, weak, readonly) SSHKitSession *session;

/// ----------------------------------------------------------------------------
/// @name Setting the Delegate
/// ----------------------------------------------------------------------------

/**
 The receiver’s `delegate`.

 You can use the `delegate` to receive asynchronous read from a shell.
 */
@property (nonatomic, weak) id<SSHKitChannelDelegate> delegate;

/// ----------------------------------------------------------------------------
/// @name Initializer
/// ----------------------------------------------------------------------------

/** Current channel type */
@property (nonatomic, readonly) SSHKitChannelType type;

@property (nonatomic, readonly) SSHKitChannelStage stage;

/** direct-tcpip channel properties */
@property (readonly) NSString      *directHost;
@property (readonly) NSUInteger    directPort;

/** tcpip-forward channel properties */
@property (readonly) NSInteger forwardDestinationPort;

@property (readonly, nonatomic) NSInteger  shellColumns;
@property (readonly, nonatomic) NSInteger  shellRows;

/**
 A Boolean value indicating whether the channel is opened successfully
 (read-only).
 */
@property (nonatomic, readonly, getter = isOpened) BOOL opened;

- (void)close;
- (void)closeWithError:(NSError *)error;

- (void)writeData:(NSData *)data;
- (void)changePtySizeToColumns:(NSInteger)columns rows:(NSInteger)rows;

@end

/**
 Protocol for registering to receive messages from an active SSHKitChannel.
 */
@protocol SSHKitChannelDelegate <NSObject>

@optional

/**
 Called when a channel read new data on the socket.
 
 @param channel The channel that read the message
 @param data The bytes that the channel has read
 */
- (void)channel:(SSHKitChannel *)channel didReadStdoutData:(NSData *)data;

/**
 Called when a channel read new error on the socket.
 
 @param channel The channel that read the error
 @param error The error that the channel has read
 */
- (void)channel:(SSHKitChannel *)channel didReadStderrData:(NSData *)data;

/**
 * Called when a channel has completed writing the requested data. Not called if there is an error.
 **/
- (void)channelDidWriteData:(SSHKitChannel *)channel;

/**
 * Called when a channel closes with or without error.
 **/
- (void)channelDidClose:(SSHKitChannel *)channel withError:(NSError *)error;

- (void)channelDidOpen:(SSHKitChannel *)channel;

- (void)channel:(SSHKitChannel *)channel didChangePtySizeToColumns:(NSInteger)columns rows:(NSInteger)rows withError:(NSError *)error;

@end
