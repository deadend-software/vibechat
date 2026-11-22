/* HexChat
 * Copyright (C) 2015 Patrick Griffis.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#ifdef HAVE_GTK_MAC
#include <gtkosxapplication.h>
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/* GTK 2's Quartz backend owns the native window and event routing. Keep
 * AppKit's native edge tracking, but never run GTK's event loop recursively
 * from a resize callback. All of this bridge runs on the main thread. */
@interface NSObject (VibeQuartzContentView)
- (GdkWindow *)gdkWindow;
@end

@interface VibeWindowResizeState : NSObject
@property(nonatomic) BOOL painting;
@property(nonatomic) BOOL tracking;
@property(nonatomic) NSUInteger edges;
@property(nonatomic) NSRect initialFrame;
@property(nonatomic) NSPoint initialPointer;
@end
@implementation VibeWindowResizeState
@end

static char resizeStateKey;
static IMP originalWindowDidResize;
#if __has_feature(objc_arc)
static __weak NSWindow *activeResizeWindow;
#else
static NSWindow *activeResizeWindow;
#endif

enum
{
	ResizeLeft = 1,
	ResizeRight = 2,
	ResizeBottom = 4,
	ResizeTop = 8
};

static VibeWindowResizeState *
resize_state (NSWindow *window)
{
	VibeWindowResizeState *state = objc_getAssociatedObject (window, &resizeStateKey);
	if (!state)
	{
		state = [[VibeWindowResizeState alloc] init];
		objc_setAssociatedObject (window, &resizeStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#if !__has_feature(objc_arc)
		[state release];
#endif
	}
	return state;
}

static GtkWidget *
resize_widget (NSWindow *window)
{
	NSView *view = [window contentView];
	if (![view respondsToSelector:@selector(gdkWindow)])
		return NULL;
	GdkWindow *gdkWindow = [view gdkWindow];
	if (!gdkWindow || gdk_window_is_destroyed (gdkWindow))
		return NULL;
	gpointer widget = NULL;
	gdk_window_get_user_data (gdkWindow, &widget);
	return widget && GTK_IS_WINDOW (widget) ? GTK_WIDGET (widget) : NULL;
}

static void
prepare_resize (NSWindow *window)
{
	[window setAlphaValue:1.0];
	[window setOpaque:YES];
	[window setBackgroundColor:[NSColor windowBackgroundColor]];
	/* Text wraps and controls move: no portion of the old image is reusable. */
	[window setPreservesContentDuringLiveResize:NO];
}

static void
paint_resize (NSWindow *window)
{
	VibeWindowResizeState *state = resize_state (window);
	GtkWidget *widget = resize_widget (window);
	if (state.painting || !widget || !gtk_widget_get_realized (widget))
		return;

	state.painting = YES;
	g_object_ref (widget);
	GdkWindow *gdkWindow = g_object_ref (gtk_widget_get_window (widget));
	@try
	{
		GtkRequisition requisition;
		GtkAllocation allocation;
		gtk_widget_size_request (widget, &requisition);
		if (!gdk_window_is_destroyed (gdkWindow) && gtk_widget_get_realized (widget))
		{
			gtk_widget_get_allocation (widget, &allocation);
			gdk_drawable_get_size (gdkWindow, &allocation.width, &allocation.height);
			allocation.width = MAX (1, allocation.width);
			allocation.height = MAX (1, allocation.height);
			gtk_widget_size_allocate (widget, &allocation);
			if (!gdk_window_is_destroyed (gdkWindow) && gtk_widget_get_realized (widget))
			{
				gdk_window_invalidate_rect (gdkWindow, NULL, TRUE);
				gdk_window_process_updates (gdkWindow, TRUE);
			}
		}
	}
	@finally
	{
		g_object_unref (gdkWindow);
		g_object_unref (widget);
		state.painting = NO;
	}
}

static void
native_window_did_resize (id self, SEL selector, NSNotification *notification)
{
	/* Quartz updates the GDK geometry before GTK allocates its children. */
	((void (*)(id, SEL, NSNotification *))originalWindowDidResize) (self, selector, notification);
	if ([(NSWindow *)self inLiveResize] || resize_state ((NSWindow *)self).tracking)
		paint_resize ((NSWindow *)self);
}

static void
finish_resize (NSWindow *window)
{
	if (!window)
		return;
	VibeWindowResizeState *state = resize_state (window);
	state.tracking = NO;
	state.edges = 0;
	if (activeResizeWindow == window)
		activeResizeWindow = nil;
	GtkWidget *widget = resize_widget (window);
	if (widget)
	{
		gdk_display_pointer_ungrab (gtk_widget_get_display (widget), GDK_CURRENT_TIME);
		gtk_widget_queue_draw (widget);
	}
	[[NSCursor arrowCursor] set];
}

static NSRect
drag_resize_frame (NSWindow *window, VibeWindowResizeState *state, NSPoint pointer)
{
	NSRect frame = state.initialFrame;
	CGFloat dx = pointer.x - state.initialPointer.x;
	CGFloat dy = pointer.y - state.initialPointer.y;
	NSRect content = [window contentRectForFrameRect:frame];
	NSSize minimum = [window contentMinSize];
	NSSize maximum = [window contentMaxSize];
	CGFloat borderWidth = frame.size.width - content.size.width;
	CGFloat borderHeight = frame.size.height - content.size.height;

	if (state.edges & (ResizeLeft | ResizeRight))
	{
		CGFloat width = frame.size.width + ((state.edges & ResizeLeft) ? -dx : dx);
		frame.size.width = MAX (minimum.width + borderWidth,
			MIN (maximum.width + borderWidth, width));
		if (state.edges & ResizeLeft)
			frame.origin.x = NSMaxX (state.initialFrame) - frame.size.width;
	}
	if (state.edges & (ResizeBottom | ResizeTop))
	{
		CGFloat height = frame.size.height + ((state.edges & ResizeBottom) ? -dy : dy);
		frame.size.height = MAX (minimum.height + borderHeight,
			MIN (maximum.height + borderHeight, height));
		if (state.edges & ResizeBottom)
			frame.origin.y = NSMaxY (state.initialFrame) - frame.size.height;
	}
	return frame;
}

/* Consume the native event without forwarding it into AppKit's nested resize
 * loop. A GDK_NOTHING event has no widget target and is ignored by GTK. */
static GdkFilterReturn
consume_resize_event (GdkEvent *event)
{
	event->type = GDK_NOTHING;
	event->any.window = NULL;
	return GDK_FILTER_TRANSLATE;
}

/* GTK's obsolete OS-version check disables edge routing on modern macOS.
 * Handle this compatibility drag one event at a time, on the ordinary GTK
 * loop. Network sources, painting and mouse-up keep making progress. */
static GdkFilterReturn
native_resize_edge_filter (GdkXEvent *nativeEvent, GdkEvent *event, gpointer data)
{
#if __has_feature(objc_arc)
	NSEvent *mouseEvent = (__bridge NSEvent *)nativeEvent;
#else
	NSEvent *mouseEvent = (NSEvent *)nativeEvent;
#endif
	NSEventType type = [mouseEvent type];
	NSWindow *window = activeResizeWindow;
	if (window)
	{
		if (type == NSEventTypeLeftMouseUp)
		{
			finish_resize (window);
			return consume_resize_event (event);
		}
		if (type == NSEventTypeLeftMouseDragged)
		{
			if (!resize_widget (window))
			{
				finish_resize (window);
				return consume_resize_event (event);
			}
			NSWindow *eventWindow = [mouseEvent window];
			NSPoint pointer = eventWindow ?
				[eventWindow convertPointToScreen:[mouseEvent locationInWindow]] :
				[NSEvent mouseLocation];
			[window setFrame:drag_resize_frame (window, resize_state (window), pointer) display:NO];
			[[window contentView] displayIfNeeded];
			return consume_resize_event (event);
		}
		/* Recover if a release was lost to another app or window. */
		if (type == NSEventTypeLeftMouseDown ||
			(type == NSEventTypeMouseMoved && ([NSEvent pressedMouseButtons] & 1) == 0))
			finish_resize (window);
	}

	if (type != NSEventTypeLeftMouseDown)
		return GDK_FILTER_CONTINUE;
	window = [mouseEvent window];
	if (!window || !resize_widget (window) ||
		([window styleMask] & NSWindowStyleMaskResizable) == 0)
		return GDK_FILTER_CONTINUE;

	NSPoint point = [mouseEvent locationInWindow];
	NSRect frame = [window frame];
	NSRect bounds = NSMakeRect (0, 0, frame.size.width, frame.size.height);
	const CGFloat border = 5.0;
	if (!NSPointInRect (point, NSInsetRect (bounds, -border, -border)))
		return GDK_FILTER_CONTINUE;
	NSUInteger edges = 0;
	/* Corners get a larger hit zone: modern macOS windows have rounded
	 * corners, so a 5pt square is too small to grab for a two-axis drag. */
	const CGFloat corner = 16.0;
	BOOL nearLeft = point.x < corner, nearRight = point.x >= bounds.size.width - corner;
	BOOL nearBottom = point.y < corner, nearTop = point.y >= bounds.size.height - corner;
	if ((nearLeft || nearRight) && (nearBottom || nearTop))
	{
		edges |= nearLeft ? ResizeLeft : ResizeRight;
		edges |= nearBottom ? ResizeBottom : ResizeTop;
	}
	else
	{
		if (point.x < border) edges |= ResizeLeft;
		else if (point.x >= bounds.size.width - border) edges |= ResizeRight;
		if (point.y < border) edges |= ResizeBottom;
		else if (point.y >= bounds.size.height - border) edges |= ResizeTop;
	}
	if (!edges)
		return GDK_FILTER_CONTINUE;

	VibeWindowResizeState *state = resize_state (window);
	state.initialFrame = frame;
	state.initialPointer = [window convertPointToScreen:point];
	state.edges = edges;
	state.tracking = YES;
	activeResizeWindow = window;
	prepare_resize (window);
	NSCursor *cursor = nil;
	if ((edges & (ResizeLeft | ResizeRight)) && (edges & (ResizeBottom | ResizeTop)))
	{
		/* Private AppKit diagonal cursors; fall back to a crosshair. */
		BOOL sameDiagonal = ((edges & ResizeLeft) != 0) == ((edges & ResizeBottom) != 0);
		SEL diagonal = sameDiagonal ?
			NSSelectorFromString (@"_windowResizeNorthEastSouthWestCursor") :
			NSSelectorFromString (@"_windowResizeNorthWestSouthEastCursor");
		if ([NSCursor respondsToSelector:diagonal])
			cursor = ((NSCursor *(*)(id, SEL))objc_msgSend) ([NSCursor class], diagonal);
		if (!cursor)
			cursor = [NSCursor crosshairCursor];
	}
	else if (edges & (ResizeLeft | ResizeRight))
		cursor = [NSCursor resizeLeftRightCursor];
	else
		cursor = [NSCursor resizeUpDownCursor];
	[cursor set];
	return consume_resize_event (event);
}

@interface VibeWindowResizeObserver : NSObject
@end
@implementation VibeWindowResizeObserver
- (void)windowClosed:(NSNotification *)notification
{
	if (activeResizeWindow == notification.object)
		finish_resize (activeResizeWindow);
}
- (void)applicationDeactivated:(NSNotification *)notification
{
	finish_resize (activeResizeWindow);
}
- (void)resizeStarted:(NSNotification *)notification
{
	NSWindow *window = notification.object;
	if (resize_widget (window))
		prepare_resize (window);
}
- (void)resizeEnded:(NSNotification *)notification
{
	NSWindow *window = notification.object;
	if (resize_widget (window))
	{
		paint_resize (window);
		/* Reconcile GTK's pending configure events on its normal main loop. */
		GtkWidget *widget = resize_widget (window);
		if (widget)
			gtk_widget_queue_resize (widget);
	}
}
@end

gboolean resize_regression_probe (gpointer data);

void
osx_setup_window_resizing (void)
{
	static VibeWindowResizeObserver *observer;
	if (observer)
		return;
	Class windowClass = NSClassFromString (@"GdkQuartzWindow");
	Method resizeMethod = class_getInstanceMethod (windowClass, @selector(windowDidResize:));
	if (!resizeMethod)
		return;

	originalWindowDidResize = method_getImplementation (resizeMethod);
	class_replaceMethod (windowClass, @selector(windowDidResize:),
		(IMP)native_window_did_resize, method_getTypeEncoding (resizeMethod));
	gdk_window_add_filter (NULL, native_resize_edge_filter, NULL);

	g_timeout_add (1000, resize_regression_probe, NULL);
	observer = [[VibeWindowResizeObserver alloc] init];
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:observer selector:@selector(windowClosed:)
		name:NSWindowWillCloseNotification object:nil];
	[center addObserver:observer selector:@selector(applicationDeactivated:)
		name:NSApplicationDidResignActiveNotification object:nil];
	[center addObserver:observer selector:@selector(resizeStarted:)
		name:NSWindowWillStartLiveResizeNotification object:nil];
	[center addObserver:observer selector:@selector(resizeEnded:)
		name:NSWindowDidEndLiveResizeNotification object:nil];
}


/* Temporary runtime regression probe; removed after verification. */
static NSString *resizeProbeResult;
gboolean
resize_regression_probe (gpointer data)
{
	GtkWidget *widget = gtk_window_new (GTK_WINDOW_TOPLEVEL);
	gtk_window_set_default_size (GTK_WINDOW (widget), 640, 400);
	gtk_container_add (GTK_CONTAINER (widget), gtk_label_new ("Resize regression test"));
	gtk_widget_show_all (widget);
	NSWindow *window = nil;
	for (NSWindow *candidate in [NSApp windows])
		if (resize_widget (candidate) == widget)
			window = candidate;
	int completed = 0;
	@try
	{
		g_assert (window != nil);
		for (int cycle = 0; cycle < 40; cycle++)
		{
			NSRect before = [window frame];
			CGFloat delta = cycle % 2 ? -20 : 20;
			int edge = (cycle / 2) % 4;
			NSPoint start = edge == 0 ? NSMakePoint (before.size.width - 1, 100) :
				(edge == 1 ? NSMakePoint (1, 100) :
				(edge == 2 ? NSMakePoint (100, 1) : NSMakePoint (100, before.size.height - 1)));
			for (int step = 0; step < 3; step++)
			{
				NSEventType type = step == 0 ? NSEventTypeLeftMouseDown :
					(step == 1 ? NSEventTypeLeftMouseDragged : NSEventTypeLeftMouseUp);
				NSEvent *event = [NSEvent mouseEventWithType:type
					location:NSMakePoint (start.x + (step && edge < 2 ? delta : 0),
						start.y + (step && edge >= 2 ? delta : 0))
					modifierFlags:0 timestamp:0 windowNumber:[window windowNumber]
					context:nil eventNumber:step + 1 clickCount:1 pressure:step == 2 ? 0 : 1];
				GdkEvent translated = {0};
				g_assert (native_resize_edge_filter ((__bridge void *)event, &translated, NULL) == GDK_FILTER_TRANSLATE);
			}
			g_assert (activeResizeWindow == nil);
			CGFloat change = (edge == 1 || edge == 2) ? -delta : delta;
			g_assert (fabs ((edge < 2 ? [window frame].size.width - before.size.width :
				[window frame].size.height - before.size.height) - change) < 0.1);
			g_assert ([NSCursor currentCursor] == [NSCursor arrowCursor]);
			completed++;
		}
		NSEvent *down = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
			location:NSMakePoint (1, 100) modifierFlags:0 timestamp:0
			windowNumber:[window windowNumber] context:nil eventNumber:1 clickCount:1 pressure:1];
		GdkEvent translated = {0};
		native_resize_edge_filter ((__bridge void *)down, &translated, NULL);
		VibeWindowResizeObserver *observer = [[VibeWindowResizeObserver alloc] init];
		[observer applicationDeactivated:nil];
		g_assert (activeResizeWindow == nil);
		native_resize_edge_filter ((__bridge void *)down, &translated, NULL);
		gtk_widget_destroy (widget);
		widget = NULL;
		g_assert (activeResizeWindow == nil);
		g_assert ([NSCursor currentCursor] == [NSCursor arrowCursor]);
		resizeProbeResult = [NSString stringWithFormat:@"PASS: %d drags on all four edges, release cursor, deactivate and close", completed];
	}
	@catch (NSException *exception)
	{
		resizeProbeResult = [NSString stringWithFormat:@"FAIL after %d: %@", completed, exception];
	}
	finish_resize (window);
	if (widget) gtk_widget_destroy (widget);
	return FALSE;
}

void
notification_backend_show (const char *title, const char *text)
{
	NSString *str_title = [[NSString alloc] initWithUTF8String:title];
	NSString *str_text = [[NSString alloc] initWithUTF8String:text];

	NSUserNotification *userNotification = [NSUserNotification new];
	userNotification.title = str_title;
	userNotification.informativeText = str_text;

	NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
	[center scheduleNotification:userNotification];

#if !__has_feature(objc_arc)
	[str_title release];
	[str_text release];
#endif
}
#pragma clang diagnostic pop

int
notification_backend_init (const char **error)
{
	return 1;
}

void
notification_backend_deinit (void)
{
}

int
notification_backend_supported (void)
{
#ifdef HAVE_GTK_MAC
	return gtkosx_application_get_bundle_id () != NULL;
#else
	return [[NSBundle mainBundle] bundleIdentifier] != nil;
#endif
}
