/*
 *  SphericalEarthQuadLayer.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 6/6/12.
 *  Copyright 2012 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "SphericalEarthQuadLayer.h"
#import "GlobeLayerViewWatcher.h"
#import "TileQuadLoader.h"

using namespace Eigen;
using namespace WhirlyKit;
using namespace WhirlyGlobe;

// Describes the structure of the image database
@interface WholeEarthStructure : NSObject<WhirlyGlobeQuadDataStructure>
{
    GeoCoordSystem coordSystem;
    int maxZoom;
    int pixelsSquare;
}
@end

@implementation WholeEarthStructure

- (id)initWithPixelsSquare:(int)inPixelsSquare maxZoom:(int)inMaxZoom
{
    self = [super init];
    if (self)
    {
        pixelsSquare = inPixelsSquare;
        maxZoom = inMaxZoom;
    }
    
    return self;
}

/// Return the coordinate system we're working in
- (WhirlyKit::CoordSystem *)coordSystem
{
    return &coordSystem;
}

/// Bounding box used to calculate quad tree nodes.  In local coordinate system.
- (WhirlyKit::Mbr)totalExtents
{
    return GeoMbr(GeoCoord::CoordFromDegrees(-180, -90),GeoCoord::CoordFromDegrees(180, 90));
}

/// Bounding box of data you actually want to display.  In local coordinate system.
/// Unless you're being clever, make this the same as totalExtents.
- (WhirlyKit::Mbr)validExtents
{
    return [self totalExtents];
}

/// Return the minimum quad tree zoom level (usually 0)
- (int)minZoom
{
    return 2;
}

/// Return the maximum quad tree zoom level.  Must be at least minZoom
- (int)maxZoom
{
    return maxZoom;
}

/// Return an importance value for the given tile
- (float)importanceForTile:(WhirlyKit::Quadtree::Identifier)ident mbr:(WhirlyKit::Mbr)tileMbr viewInfo:(WhirlyGlobeViewState * __unsafe_unretained) viewState frameSize:(WhirlyKit::Point2f)frameSize
{
    if (ident.level == [self minZoom])
        return MAXFLOAT;
    
    return ScreenImportance(viewState, frameSize, viewState->eyeVec, pixelsSquare, &coordSystem, tileMbr);
}

/// Called when the layer is shutting down.  Clean up any drawable data and clear out caches.
- (void)shutdown
{
}

@end

// Data source that serves individual images as requested
@interface ImageDataSource : NSObject<WhirlyGlobeQuadTileImageDataSource>
{
    NSString *basePath,*ext,*baseName;
    int maxZoom,pixelsSquare,borderPixels;
}

@property(nonatomic) NSString *basePath,*ext,*baseName;
@property(nonatomic,assign) int maxZoom,pixelsSquare,borderPixels;

@end

@implementation ImageDataSource

@synthesize basePath,ext,baseName;
@synthesize maxZoom,pixelsSquare,borderPixels;

- (id)initWithInfo:(NSString *)infoName
{
    self = [super init];

    if (self)
    {
        // This should be the info plist.  That has everything
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:infoName];
        if (!dict)
        {
            return nil;
        }
        // If the user specified a real path, as opposed to just
        //  the file, we'll hang on to that
        basePath=[infoName stringByDeletingLastPathComponent];
        ext = [dict objectForKey:@"format"];
        baseName = [dict objectForKey:@"baseName"];
        maxZoom = [[dict objectForKey:@"maxLevel"] intValue];
        pixelsSquare = [[dict objectForKey:@"pixelsSquare"] intValue];
        borderPixels = [[dict objectForKey:@"borderSize"] intValue];    
    }
    
    return self;
}

- (int)maxSimultaneousFetches
{
    return 1;
}

- (void)quadTileLoader:(WhirlyGlobeQuadTileLoader *)quadLoader startFetchForLevel:(int)level col:(int)col row:(int)row
{
    NSString *name = [NSString stringWithFormat:@"%@_%dx%dx%d.%@",baseName,level,col,row,ext];
	if (self.basePath)
		name = [self.basePath stringByAppendingPathComponent:name];
    
    NSData *imageData = [NSData dataWithContentsOfFile:name];
    
    bool isPvrtc = ![ext compare:@"pvrtc"];
    
    [quadLoader dataSource:self loadedImage:imageData pvrtcSize:(isPvrtc ? pixelsSquare : 0) forLevel:level col:col row:row];
}

@end


@interface WhirlyGlobeSphericalEarthQuadLayer()
{
    WholeEarthStructure *earthDataStructure;
    ImageDataSource *imageDataSource;
    WhirlyGlobeQuadTileLoader *quadTileLoader;
}
@end

@implementation WhirlyGlobeSphericalEarthQuadLayer

- (int)drawPriority
{
    return quadTileLoader.drawPriority;
}

- (void)setDrawPriority:(int)drawPriority
{
    quadTileLoader.drawPriority = drawPriority;
}

- (int)drawOffset
{
    return quadTileLoader.drawOffset;
}

- (void)setDrawOffset:(int)drawOffset
{
    quadTileLoader.drawOffset = drawOffset;
}

- (id) initWithInfo:(NSString *)infoName renderer:(WhirlyKitSceneRendererES1 *)inRenderer
{
    // Data source serves the tiles
    ImageDataSource *theDataSource = [[ImageDataSource alloc] initWithInfo:infoName];
    if (!theDataSource)
        return nil;
    
    // This describes the quad tree and extents
    WholeEarthStructure *theStructure = [[WholeEarthStructure alloc] initWithPixelsSquare:theDataSource.pixelsSquare maxZoom:theDataSource.maxZoom];
    
    // This handles the geometry and loading
    WhirlyGlobeQuadTileLoader *theLoader = [[WhirlyGlobeQuadTileLoader alloc] initWithDataSource:theDataSource];
    
    self = [super initWithDataSource:theStructure loader:theLoader renderer:inRenderer];
    if (self)
    {
        earthDataStructure = theStructure;
        imageDataSource = theDataSource;
        quadTileLoader = theLoader;
    }
	
	return self;    
}

- (void)shutdown
{
    [super shutdown];
    
    earthDataStructure = nil;
    imageDataSource = nil;
    quadTileLoader = nil;
}

@end
