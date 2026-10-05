#import <Foundation/NSURLComponents.h>
#import <Foundation/NSData.h>
#import <CoreFoundation/CFURL.h>

// ponytail: only the scheme and the host can be read or replaced, which is all the header
// declares. The other parts (user, port, path, query, fragment) pass through untouched from the
// URL the object was made from; add them here when a caller needs them.
@implementation NSURLComponents

@synthesize scheme = _scheme;
@synthesize host = _host;

- (instancetype)initWithURL:(NSURL *)url resolvingAgainstBaseURL:(BOOL)resolve
{
    if ((self = [super init])) {
        _base = [(resolve ? [url absoluteURL] : url) copy];
        if (_base == nil) {
            [self release];
            return nil;
        }
        _scheme = [[_base scheme] copy];
        _host = [[_base host] copy];
    }
    return self;
}

+ (instancetype)componentsWithURL:(NSURL *)url resolvingAgainstBaseURL:(BOOL)resolve
{
    return [[[self alloc] initWithURL:url resolvingAgainstBaseURL:resolve] autorelease];
}

- (void)dealloc
{
    [_base release];
    [_scheme release];
    [_host release];
    [super dealloc];
}

static void replaceComponent(NSMutableData *bytes, CFURLRef url, CFURLComponentType type, NSString *value)
{
    CFRange range = CFURLGetByteRangeForComponent(url, type, NULL);
    if (range.location == kCFNotFound || value == nil) {
        return;
    }
    NSData *replacement = [value dataUsingEncoding:NSUTF8StringEncoding];
    [bytes replaceBytesInRange:NSMakeRange(range.location, range.length)
                     withBytes:[replacement bytes]
                        length:[replacement length]];
}

- (NSURL *)URL
{
    CFURLRef url = (CFURLRef)_base;
    NSMutableData *bytes = [NSMutableData dataWithLength:CFURLGetBytes(url, NULL, 0)];
    CFURLGetBytes(url, [bytes mutableBytes], [bytes length]);
    // The host comes after the scheme, so replace it first: the scheme's range stays valid.
    replaceComponent(bytes, url, kCFURLComponentHost, _host);
    replaceComponent(bytes, url, kCFURLComponentScheme, _scheme);
    return [(NSURL *)CFURLCreateWithBytes(kCFAllocatorDefault, [bytes bytes], [bytes length],
                                          kCFStringEncodingUTF8, NULL) autorelease];
}

@end
