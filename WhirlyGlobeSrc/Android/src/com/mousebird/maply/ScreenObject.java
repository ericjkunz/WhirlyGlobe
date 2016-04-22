/*
 *  ScreenObject.java
 *  WhirlyGlobeLib
 *
 *  Created by jmnavarro
 *  Copyright 2011-2016 mousebird consulting
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
package com.mousebird.maply;

import android.graphics.Bitmap;

public class ScreenObject {

    public class BoundingBox {
        public Point2d ll = new Point2d();
        public Point2d ur = new Point2d();
    }

    public ScreenObject(){
        initialise();
    }

    public void finalise(){
        dispose();
    }

    public native void addPoly (SimplePoly poly);

    public native SimplePoly getPoly (int index);

    public native int getPolysSize();

    public native void addString (StringWrapper string);

    public native StringWrapper getString(int index);

    public native int getStringsSize();

    public native void addImage (Bitmap image, float [] color, int width, int height);

    public native void addScreenObject(ScreenObject screenObject);

    public BoundingBox getSize() {

        Mbr mbr = new Mbr();

        for (int ii = 0; ii < getPolysSize(); ii ++) {
            SimplePoly poly = getPoly(ii);
            for (int jj = 0; jj < poly.getPtsSize(); jj ++){
                Point2d pt = poly.getPt(jj);
                mbr.addPoint(pt);
            }
        }

        for (int ii = 0; ii < getStringsSize() ; ii++){
            StringWrapper str = getString(ii);
            Point3d p0 = str.getMat().multiply(new Point3d(0,0,1));
            Point3d p1 = str.getMat().multiply(new Point3d(str.getSize()[0], str.getSize()[1], 1));
            mbr.addPoint(new Point2d(p0.getX(), p0.getY()));
            mbr.addPoint(new Point2d(p1.getX(), p1.getY()));
        }

        BoundingBox boundingBox = new BoundingBox();
        boundingBox.ll = new Point2d(mbr.ll.getX(), mbr.ll.getY());
        boundingBox.ur = new Point2d(mbr.ur.getX(), mbr.ur.getY());

        return boundingBox;
    }

    public void scaleX(double x, double y){

        Matrix3d mat = Matrix3d.scaleX(x,y);

        for (int ii = 0; ii < getPolysSize(); ii++){
            SimplePoly poly = getPoly(ii);
            for (int jj = 0 ; jj < poly.getPtsSize(); jj++){
                Point2d pt = poly.getPt(jj);
                Point3d newPt = mat.multiply(new Point3d(pt.getX(), pt.getY(), 1.0));
                poly.setPt(jj, new Point2d( newPt.getX(), newPt.getY()));
            }
        }

        for (int ii = 0; ii < getStringsSize(); ii++){
            StringWrapper str = getString(ii);
            str.setMat(mat.multiply(str.getMat()));
        }
    }

    public void translateX(double x, double y) {

        for (int ii = 0; ii < getPolysSize(); ii++){
            SimplePoly poly = getPoly(ii);
            for (int jj = 0; jj < poly.getPtsSize(); jj++){
                Point2d pt = Matrix3d.multiplyTrasX(x, y, poly.getPt(jj));
                poly.setPt(ii, pt);
            }
        }

        Matrix3d mat = Matrix3d.traslateX(x,y);

        for (int ii = 0; ii < getStringsSize(); ii++){
            StringWrapper str = getString(ii);
            str.setMat(mat.multiply(str.getMat()));
        }
    }

    static
    {
        nativeInit();
    }
    private static native void nativeInit();
    native void initialise();
    native void dispose();

    private long nativeHandle;

}
