/*
 Copyright 2015 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKAttachment.h"

#import "MXKMediaManager.h"
#import "MXKTools.h"

@implementation MXKAttachment

- (instancetype)initWithEvent:(MXEvent *)mxEvent andMatrixSession:(MXSession*)mxSession
{
    self = [super init];
    if (self) {
        // Make a copy as the data can be read at anytime later
        _event = mxEvent;
        
        // Set default thumbnail orientation
        _thumbnailOrientation = UIImageOrientationUp;
        
        NSString *msgtype =  _event.content[@"msgtype"];
        if ([msgtype isEqualToString:kMXMessageTypeImage])
        {
            [self handleImageMessage:_event withMatrixSession:mxSession];
        }
        else if ([msgtype isEqualToString:kMXMessageTypeAudio])
        {
            // Not supported yet
            //_type = MXKAttachmentTypeAudio;
            return nil;
        }
        else if ([msgtype isEqualToString:kMXMessageTypeVideo])
        {
            [self handleVideoMessage:_event withMatrixSession:mxSession];
        }
        else if ([msgtype isEqualToString:kMXMessageTypeLocation])
        {
            // Not supported yet
            // _type = MXKAttachmentTypeLocation;
            return nil;
        }
        else if ([msgtype isEqualToString:kMXMessageTypeFile])
        {
            [self handleFileMessage:_event withMatrixSession:mxSession];
        }
        else
        {
            return nil;
        }
        
    }
    return self;
}

#pragma mark -

- (void)handleImageMessage:(MXEvent*)event withMatrixSession:(MXSession*)mxSession
{
    _type = MXKAttachmentTypeImage;
    
    // Retrieve content url/info
    _contentURL = event.content[@"url"];
    
    // Check provided url (it may be a matrix content uri, we use SDK to build absoluteURL)
    _actualURL = [mxSession.matrixRestClient urlOfContent:_contentURL];
    if (nil == _actualURL)
    {
        // It was not a matrix content uri, we keep the provided url
        _actualURL = _contentURL;
    }
    
    NSString *mimetype = nil;
    if (event.content[@"info"])
    {
        mimetype = event.content[@"info"][@"mimetype"];
    }
    
    _cacheFilePath = [MXKMediaManager cachePathForMediaWithURL:_actualURL andType:mimetype inFolder:event.roomId];
    _contentInfo = event.content[@"info"];
    
    // Handle legacy thumbnail url/info (Not defined anymore in recent attachments)
    _thumbnailURL = event.content[@"thumbnail_url"];
    _thumbnailInfo = event.content[@"thumbnail_info"];
    
    if (!_thumbnailURL)
    {
        // Check whether the image has been uploaded with an orientation
        if (_contentInfo[@"rotation"])
        {
            // Currently the matrix content server provides thumbnails by ignoring the original image orientation.
            // We store here the actual orientation to apply it on downloaded thumbnail.
            _thumbnailOrientation = [MXKTools imageOrientationForRotationAngleInDegree:[_contentInfo[@"rotation"] integerValue]];
        }
    }
}

- (void)handleVideoMessage:(MXEvent*)event withMatrixSession:(MXSession*)mxSession
{
    _type = MXKAttachmentTypeVideo;
    
    // Retrieve content url/info
    _contentURL = event.content[@"url"];
    
    // Check provided url (it may be a matrix content uri, we use SDK to build absoluteURL)
    _actualURL = [mxSession.matrixRestClient urlOfContent:_contentURL];
    if (nil == _actualURL)
    {
        // It was not a matrix content uri, we keep the provided url
        _actualURL = _contentURL;
    }
    
    NSString *mimetype = nil;
    if (event.content[@"info"])
    {
        mimetype = event.content[@"info"][@"mimetype"];
    }
    
    _cacheFilePath = [MXKMediaManager cachePathForMediaWithURL:_actualURL andType:mimetype inFolder:event.roomId];
    _contentInfo = event.content[@"info"];
    
    if (_contentInfo)
    {
        // Get video thumbnail info
        _thumbnailURL = _contentInfo[@"thumbnail_url"];
        _thumbnailURL = [mxSession.matrixRestClient urlOfContent:_thumbnailURL];
        if (nil == _thumbnailURL)
        {
            _thumbnailURL = _contentInfo[@"thumbnail_url"];
        }
        
        _thumbnailInfo = _contentInfo[@"thumbnail_info"];
    }
}

- (void)handleFileMessage:(MXEvent*)event withMatrixSession:(MXSession*)mxSession
{
    _type = MXKAttachmentTypeFile;
    
    // Retrieve content url/info
    _contentURL = event.content[@"url"];
    // Check provided url (it may be a matrix content uri, we use SDK to build absoluteURL)
    _actualURL = [mxSession.matrixRestClient urlOfContent:_contentURL];
    if (nil == _actualURL)
    {
        // It was not a matrix content uri, we keep the provided url
        _actualURL = _contentURL;
    }
    
    NSString *mimetype = nil;
    if (event.content[@"info"])
    {
        mimetype = event.content[@"info"][@"mimetype"];
    }
    
    _cacheFilePath = [MXKMediaManager cachePathForMediaWithURL:_actualURL andType:mimetype inFolder:event.roomId];
    _contentInfo = event.content[@"info"];
}

@end
