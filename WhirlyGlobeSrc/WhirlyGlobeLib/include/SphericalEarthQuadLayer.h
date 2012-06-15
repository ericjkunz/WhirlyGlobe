/*
 *  SphericalEarthQuadLayer.h
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

#import <math.h>
#import "WhirlyVector.h"
#import "TextureGroup.h"
#import "GlobeScene.h"
#import "DataLayer.h"
#import "RenderCache.h"
#import "LayerThread.h"
#import "TileQuadLoader.h"

/** The Spherical Earth Quad Layer is a convenience layer that
    reads the plist generated by ImageChopper and adaptively loads
    a simple hierarchy of images that covers the whole earth.
    This replaces SphericalEarthLayer with its paging version.
 */
@interface WhirlyGlobeSphericalEarthQuadLayer : WhirlyGlobeQuadDisplayLayer
{
}

@property (nonatomic,assign) int drawPriority;
@property (nonatomic,assign) int drawOffset;

/// Initialize with name of the plist the defines the image data set
- (id) initWithInfo:(NSString *)infoName renderer:(WhirlyKitSceneRendererES1 *)renderer;

@end
