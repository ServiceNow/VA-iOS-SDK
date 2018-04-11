//
//  NOW_UIColor.h
//
// Modified from original source my Marc Attinasi on 4/10/2018

//  Created by James Lawton on 12/9/12.
//  Copyright (c) 2012 James Lawton. All rights reserved.
/*
 Copyright (c) 2012, James Lawton
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIKit.h>

/**
 * Extensions to read and write colors in the formats supported by CSS.
 * Emphasis has been given to parsing corrently formatted colors, rather
 * than rejecting technically invalid colors.
 */
@interface UIColor (HTMLColors)

/**
 * Reads a color from a string containing hex, RGB, HSL or X11 named color.
 * Returns `nil` on failure.
 */
+ (UIColor *)now_colorWithCSS:(NSString *)cssColor;

/**
 * Reads a color from a string containing a hex color, of the form
 * "#FFFFFF" or "#FFF".
 * Returns `nil` on failure.
 */
+ (UIColor *)now_colorWithHexString:(NSString *)hexColor;

/**
 * Reads a color from a string containing an RGB color, of the form
 * "rgb(255, 255, 255)" or "rgba(255, 255, 255, 1.0)". Supports components
 * represented as percentages.
 * Returns `nil` on failure.
 */
+ (UIColor *)now_colorWithRGBString:(NSString *)rgbColor;

/**
 * Reads a color from a string containing an HSL color, of the form
 * "hsl(359, 100%, 100%)" or "hsla(359, 100%, 100%, 1.0)".
 * Returns `nil` on failure.
 */
+ (UIColor *)now_colorWithHSLString:(NSString *)hslColor;

/**
 * Reads a color from a string containing a W3C named color.
 * Returns `nil` on failure.
 */
+ (UIColor *)now_colorWithW3CNamedColor:(NSString *)namedColor;

/**
 * Returns a representation of this color as a hex string, of the form "#FFFFFF".
 * Alpha information is not represented.
 */
- (NSString *)now_hexStringValue;

/**
 * Returns a representation of this color as an RGB string, of the form
 * "rgb(255, 255, 255)" or "rgba(255, 255, 255, 1.0)".
 * Returns `nil` on failure.
 */
- (NSString *)now_rgbStringValue;

/**
 * Returns a representation of this color as an RGB string, of the form
 * "hsl(359, 100%, 100%)" or "hsla(359, 100%, 100%, 1.0)".
 * Returns `nil` on failure.
 */
- (NSString *)now_hslStringValue;

/**
 * FOR DEBUGGING - All the supported W3C color names.
 */
+ (NSArray *)now_W3CColorNames;

@end


/**
 * Extensions to scan colors in the formats supported by CSS.
 */
@interface NSScanner (HTMLColors)

/**
 * Scan a color hex, RGB, HSL or X11 named color.
 */
- (BOOL)now_scanCSSColor:(UIColor **)color;

/**
 * Scan an RGB color ("rgb(255, 255, 255)", "rgba(255, 255, 255, 1.0)").
 */
- (BOOL)now_scanRGBColor:(UIColor **)color;

/**
 * Scan an HSL color ("hsl(359, 100%, 100%)", "hsla(359, 100%, 100%, 1.0)").
 */
- (BOOL)now_scanHSLColor:(UIColor **)color;

/**
 * Scan a hex color ("#FFFFFF", "#FFF").
 */
- (BOOL)now_scanHexColor:(UIColor **)color;

/**
 * Scan a CSS3/SVG named color. These are similar to the X11 named colors.
 * See: http://www.w3.org/TR/css3-color/#svg-color
 */
- (BOOL)now_scanW3CNamedColor:(UIColor **)color;

@end
