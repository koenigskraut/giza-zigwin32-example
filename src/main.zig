const std = @import("std");
const cairo = @import("cairo");

const WINAPI = @import("std").os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").system.system_services;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").graphics.gdi;
};
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const MSG = win32.MSG;
const HWND = win32.HWND;

const BORDER_WIDTH = 75;
const SNIPPET_WIDTH = 300;
const SNIPPET_HEIGHT = 300;
const FONT_SIZE = 24;

const WINDOW_STYLE: win32.WINDOW_STYLE = @enumFromInt(@intFromEnum(win32.WS_OVERLAPPEDWINDOW) &
    ~(@intFromEnum(win32.WS_MAXIMIZEBOX) | @intFromEnum(win32.WS_THICKFRAME)));

pub export fn main(hInstance: HINSTANCE, _: ?HINSTANCE, pCmdLine: [*:0]u16, nCmdShow: u32) callconv(WINAPI) c_int {
    _ = pCmdLine;
    std.debug.print("test\n", .{});

    const TITLE = L("Cairo test");

    const wc = win32.WNDCLASS{
        .style = win32.WNDCLASS_STYLES.initFlags(.{ .VREDRAW = 1, .HREDRAW = 1 }),
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = win32.LoadIconW(null, win32.IDI_APPLICATION),
        .hCursor = win32.LoadCursorW(null, win32.IDC_ARROW),
        .hbrBackground = win32.GetStockObject(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = TITLE,
    };
    _ = win32.RegisterClass(&wc);

    var rect = win32.RECT{
        .left = 0,
        .top = 0,
        .right = SNIPPET_WIDTH + 2 * BORDER_WIDTH,
        .bottom = SNIPPET_WIDTH + 2 * BORDER_WIDTH,
    };

    _ = win32.AdjustWindowRect(&rect, WINDOW_STYLE, win32.FALSE); // no menu

    var window = win32.CreateWindowExW(
        @enumFromInt(0),
        TITLE, // Class name
        TITLE, // Window name
        WINDOW_STYLE,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT, // initial position
        rect.right - rect.left,
        rect.bottom - rect.top, // initial size
        null, // Parent
        null, // Menu
        hInstance,
        null, // WM_CREATE lpParam
    );

    _ = win32.ShowWindow(window, @enumFromInt(nCmdShow));
    _ = win32.UpdateWindow(window);

    var message: win32.MSG = undefined;
    while (win32.GetMessage(&message, null, 0, 0) == win32.TRUE) {
        _ = win32.TranslateMessage(&message);
        _ = win32.DispatchMessage(&message);
    }

    return @intCast(message.wParam);
}

fn WndProc(window: HWND, message: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(WINAPI) win32.LRESULT {
    switch (message) {
        win32.WM_CHAR => {
            switch (wParam) {
                'q', 'Q' => {
                    win32.PostQuitMessage(0);
                    return 0;
                },
                else => {},
            }
        },
        win32.WM_PAINT => {
            var paint_struct: win32.PAINTSTRUCT = undefined;
            const dc = win32.BeginPaint(window, &paint_struct);
            onPaint(dc.?) catch {
                win32.PostQuitMessage(1);
                return 1;
            };
            _ = win32.EndPaint(window, &paint_struct);
            return 0;
        },
        win32.WM_DESTROY => {
            win32.PostQuitMessage(0);
            return 0;
        },
        else => {},
    }

    return win32.DefWindowProc(window, message, wParam, lParam);
}

fn onPaint(hdc: win32.HDC) !void {
    const surface = try cairo.Win32Surface.create(hdc);
    defer surface.destroy();
    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    const line_width = cr.getLineWidth();

    // Draw a box bordering the snippet
    cr.rectangle(.{
        .x = BORDER_WIDTH - line_width / 2,
        .y = BORDER_WIDTH - line_width / 2,
        .width = SNIPPET_WIDTH + line_width,
        .height = SNIPPET_WIDTH + line_width,
    });
    cr.stroke();

    // And some text
    cr.selectFontFace("Arial", .Normal, .Bold);
    cr.setFontSize(FONT_SIZE);
    const font_extents = cr.fontExtents();

    cr.moveTo(BORDER_WIDTH, BORDER_WIDTH + SNIPPET_WIDTH + font_extents.ascent);
    cr.showText("This is some example text!");
}
