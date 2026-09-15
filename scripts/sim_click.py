#!/usr/bin/env python3
import sys
import time
import subprocess
import ctypes

app_services = ctypes.cdll.LoadLibrary('/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices')

class CGPoint(ctypes.Structure):
    _fields_ = [('x', ctypes.c_double), ('y', ctypes.c_double)]

app_services.CGEventCreateMouseEvent.restype = ctypes.c_void_p
app_services.CGEventCreateMouseEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint32, CGPoint, ctypes.c_uint32]
app_services.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]
app_services.CFRelease.argtypes = [ctypes.c_void_p]

kCGEventLeftMouseDown = 1
kCGEventLeftMouseUp = 2
kCGMouseButtonLeft = 0
kCGHIDEventTap = 0

def get_sim_bounds():
    script = '''
    tell application "Simulator"
        activate
        delay 0.3
    end tell
    tell application "System Events"
        tell process "Simulator"
            set wList to (every window whose subrole is not "AXUnknown")
            if (count of wList) > 0 then
                set win to item 1 of wList
                set winPos to position of win
                set winSize to size of win
                return (item 1 of winPos as string) & "," & (item 2 of winPos as string) & "," & (item 1 of winSize as string) & "," & (item 2 of winSize as string)
            end if
        end tell
    end tell
    '''
    res = subprocess.check_output(['osascript', '-e', script]).decode().strip()
    x, y, w, h = map(float, res.split(','))
    return x, y, w, h

def click_sim(rel_x, rel_y):
    win_x, win_y, win_w, win_h = get_sim_bounds()
    title_offset = 28.0
    content_h = win_h - title_offset
    
    abs_x = win_x + (win_w * rel_x)
    abs_y = win_y + title_offset + (content_h * rel_y)
    
    pt = CGPoint(abs_x, abs_y)
    event_down = app_services.CGEventCreateMouseEvent(None, kCGEventLeftMouseDown, pt, kCGMouseButtonLeft)
    event_up = app_services.CGEventCreateMouseEvent(None, kCGEventLeftMouseUp, pt, kCGMouseButtonLeft)
    
    app_services.CGEventPost(kCGHIDEventTap, event_down)
    time.sleep(0.08)
    app_services.CGEventPost(kCGHIDEventTap, event_up)
    
    app_services.CFRelease(event_down)
    app_services.CFRelease(event_up)
    print(f"Clicked Simulator at ({abs_x:.1f}, {abs_y:.1f})")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: sim_click.py <rel_x> <rel_y>")
        sys.exit(1)
    click_sim(float(sys.argv[1]), float(sys.argv[2]))
